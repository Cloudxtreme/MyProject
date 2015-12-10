import httplib
import importlib
import os
import pickle
import re
import pprint
import uuid

import vmware.common as common
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.errors as errors
import vmware.common.global_config as global_config
import vmware.common.timeouts as timeouts
import vmware.common.utilities as utilities
import vmware.interfaces.crud_interface as crud_interface

auto_resolve = base_facade.auto_resolve
pylogger = global_config.pylogger
MOCK_PREFIX = 'MOCK'
MOCK_CACHE_DIR = '/tmp/vdnet'
MOCK_CACHE_FILE = 'mock.cache'
mock_cache_path = os.sep.join((MOCK_CACHE_DIR, MOCK_CACHE_FILE))


def load_cache_from_file(filename):
    cache = None
    try:
        cache = pickle.load(open(filename, 'rb'))
    except IOError:
        pylogger.debug('File %s not found, return empty mock cache' %
                       filename)
    if cache is None:
        cache = {}
    pylogger.info('Loaded cache: %s' % cache)
    return cache


def write_cache_to_file(filename, value, update=True):
    if update:
        cache = load_cache_from_file(filename)
    else:
        cache = {}
    cache.update(value)
    pickle.dump(cache, open(filename, 'wb'))
    pylogger.info('Dumped cache: %s' % cache)


class Mock(object):
    """
    Adds the ability to set/get/clear cache schemas by pickling objects to a
    file by id_. Return data can be update with respoonse_data if required
    status code is passed as part of set/get/clear calls.
    >>> Mock.set_mock_cache(1, {'foo': 'bar'})
    {'id_': 1, 'foo': 'bar'}
    >>> Mock.get_mock_cache(2)
    {}
    >>> Mock.get_mock_cache(1)
    {'id_': 1, 'foo': 'bar'}
    >>> Mock.clear_mock_cache(1)
    {'id_': 1}
    >>> Mock.get_mock_cache(1)
    {}
    >>> Mock.set_mock_cache(2, {'foo': 'bar'}, status_code=201)
    {'id_': 2, 'foo': 'bar', 'response_data': {'status_code': 201}}
    >>> Mock.get_mock_cache(2, status_code=200)
    {'id_': 2, 'foo': 'bar', 'response_data': {'status_code': 200}}
    >>> Mock.clear_mock_cache(2, status_code=200)
    {'id_': 2, 'response_data': {'status_code': 200}}
    >>> Mock.set_mock_cache(1, {'foo': 'bar'})
    {'id_': 1, 'foo': 'bar'}
    >>> Mock.reset_mock_cache()
    >>> Mock.get_mock_cache(1)
    {}
    """

    # TODO(Krishna): This doesn't support multithreading/multiprocess as the
    # file on the disk need to locked to handle these cases
    @classmethod
    def update_schema_with_response(cls, schema, status_code):
        if status_code is not None:
            schema['response_data'] = {'status_code': status_code}

    @classmethod
    def clear_mock_cache(cls, id_, status_code=None):
        cache = load_cache_from_file(mock_cache_path)
        if id_ in cache:
            schema = cache[id_]
            del cache[id_]
        else:
            schema = {}
        write_cache_to_file(mock_cache_path, cache, update=False)

        schema = {}   # Avoid returning full cache for clear?
        schema['id_'] = id_
        cls.update_schema_with_response(schema, status_code)
        pylogger.info('%s schema for %s cleared' %
                      (cls.__name__, id_))
        return schema

    @classmethod
    def get_mock_cache(cls, id_, status_code=None):
        schema = load_cache_from_file(mock_cache_path).get(id_, {})
        if schema:
            schema['id_'] = id_
            cls.update_schema_with_response(schema, status_code)
        pylogger.info('%s schema for %s is %s' %
                      (cls.__name__, id_, schema))
        return schema

    @classmethod
    def set_mock_cache(cls, id_, schema, status_code=None):
        if type(schema) is not dict:
            raise ValueError('%s schema needs to be dict, but passed %s' %
                             (cls.__name__, schema))
        if id_ is None:
            id_ = str(uuid.uuid4())
            id_ = MOCK_PREFIX + id_[4:]

        schema['id_'] = id_
        cls.update_schema_with_response(schema, status_code)
        write_cache_to_file(mock_cache_path, {id_: schema})
        pylogger.info('%s schema for %s updated to %s' %
                      (cls.__name__, id_, schema))
        return schema

    @classmethod
    def reset_mock_cache(cls):
        write_cache_to_file(mock_cache_path, {}, update=False)


class BaseRUImpl(crud_interface.CRUDInterface):

    _attribute_map = None
    _client_class = None
    _list_schema_class = None
    _schema_class = None
    _response_schema_class = None
    _url_prefix = None
    _merge_flag_default = True

    @classmethod
    def create(cls, client_obj, id_=None, schema=None, **kwargs):
        return cls.update(client_obj, id_=id_, schema=schema, **kwargs)

    @classmethod
    def sanity_check(cls):
        if cls._client_class is None:
            raise TypeError("Client class is not defined for %s " %
                            cls.__name__)
        if cls._schema_class is None:
            raise TypeError("Schema class is not defined for %s " %
                            cls.__name__)
        if cls._attribute_map is None:
            raise TypeError("Attribute map is not defined for %s " %
                            cls.__name__)

    @classmethod
    def assign_response_schema_class(cls):
        if cls._response_schema_class is None:
            cls._response_schema_class = cls._schema_class

    @classmethod
    def get_url_parameters(cls, http_verb, **kwargs):
        """
        Returns URL query parameters as a dictionary. Consumes 'query_params'
        from **kwargs dict.

        @type query_params: dict
        @param query_params: Key-value map of URL query parameters.
        @rtype: dict
        @return: A key-value map with all keys and values stringified.
        """
        query_params = utilities.get_default(kwargs.pop('query_params', None),
                                             {})
        return {str(k): str(v) for k, v in query_params.iteritems()}

    @classmethod
    def get_sdk_client_object(cls, client_obj, parent_id=None,
                              client_class=None, schema_class=None,
                              **kwargs):
        if parent_id is not None:
            raise NotImplementedError("parent_id is defined, sub-class needs "
                                      "to override get_sdk_client_object")
        client_class = client_class if client_class else cls._client_class
        obj = client_class(connection_object=client_obj.connection,
                           url_prefix=cls._url_prefix)

        # In case the schema class is derived from a base schema and not
        # in a 1-to-1 association with the client class, set the client's
        # schema class to ensure correct data mapping. See also
        # BaseCRUD.create().
        # TODO(akulkarni, jschmidt): If testing sdk behavior changes this
        # override of the schema_class may need adjustment.
        response_schema_class = (
            schema_class if schema_class else cls._response_schema_class)
        if response_schema_class is not None:
            obj.schema_class = (
                response_schema_class.__module__ + '.' +
                response_schema_class.__name__)
        return obj

    @classmethod
    def read(cls, client_obj, id_=None, parent_id=None,
             client_class=None, schema_class=None, **kwargs):
        cls.sanity_check()
        cls.assign_response_schema_class()

        client_class_obj = cls.get_sdk_client_object(
            client_obj, parent_id=parent_id, client_class=client_class,
            schema_class=schema_class, **kwargs)
        url_parameters = cls.get_url_parameters(constants.HTTPVerb.GET,
                                                **kwargs)

        schema_object = client_class_obj.read(object_id=id_,
                                              url_parameters=url_parameters)
        schema_dict = schema_object.get_py_dict_from_object()
        verification_form = utilities.map_attributes(
            cls._attribute_map, schema_dict, reverse_attribute_map=True)

        result_dict = verification_form
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict

    @classmethod
    def update(cls, client_obj, id_=None, schema=None, parent_id=None,
               merge=None, client_class=None, schema_class=None, **kwargs):
        cls.sanity_check()
        cls.assign_response_schema_class()

        if merge is None:
            merge = cls._merge_flag_default
        payload = utilities.map_attributes(cls._attribute_map, schema)
        client_class_obj = cls.get_sdk_client_object(
            client_obj, parent_id=parent_id, client_class=client_class,
            schema_class=schema_class, id_=id_)
        url_parameters = cls.get_url_parameters(constants.HTTPVerb.PUT,
                                                **kwargs)
        _ = kwargs.pop('query_params', None)
        merged_object = client_class_obj.update(py_dict=payload,
                                                object_id=id_,
                                                merge=merge,
                                                url_parameters=url_parameters,
                                                **kwargs)

        result_dict = merged_object.get_py_dict_from_object()
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict

    @classmethod
    def delete(cls, client_obj, **kwargs):
        cls.sanity_check()
        raise NotImplementedError


class MockRUImpl(BaseRUImpl, Mock):

    @classmethod
    def read(cls, client_obj, id_=None, **kwargs):
        return cls.get_mock_cache(id_, status_code=httplib.OK)

    @classmethod
    def update(cls, client_obj, id_=None, schema=None, **kwargs):
        return cls.set_mock_cache(id_, schema, status_code=httplib.OK)


class BaseRUDImpl(BaseRUImpl):
    _SUCCESS = common.status_codes.SUCCESS.lower()
    _REQUIRED_STATE_ATTRS = ('_id_name', '_id_param')
    _entity_type = None
    _id_name = None
    _id_param = None

    @classmethod
    def delete(cls, client_obj, id_=None, parent_id=None, sync=False,
               timeout=None, client_class=None, schema_class=None, **kwargs):
        if id_ is None:
            # XXX(Krishna): Check with Ashutosh why nsx-sdk doesn't support
            # deletion of objects like BGP using id_=None, we need to send
            # explicitly id_='' to make this work
            id_ = ''
        cls.sanity_check()

        client_class_obj = cls.get_sdk_client_object(
            client_obj, parent_id=parent_id, client_class=client_class,
            schema_class=schema_class)
        url_parameters = cls.get_url_parameters(constants.HTTPVerb.DELETE,
                                                **kwargs)
        client_class_obj.delete(
            object_id=id_, url_parameters=url_parameters)
        result_dict = {
            'id_': id_,
            'response_data': {
                'status_code': client_class_obj.last_calls_status_code}}
        if sync:
            cls.wait_for_realized_state(client_obj, id_=result_dict['id_'],
                                        empty_on_success=True, timeout=timeout)
        return result_dict

    @classmethod
    def _get_state_class(cls):
        """
        Gets the state class instance to query the /state endpoint.

        The name of the state class is inferred using the _client_class class
        attribute.
        """
        module_name = ".".join(cls._client_class.__module__.split(".")[:-1])
        client_class_str = str(cls._client_class)
        matched_class_name = re.match("<class '(.*)'>", client_class_str)
        if not matched_class_name:
            raise Exception("Regex not able to find state class name in %r" %
                            client_class_str)
        client_class = matched_class_name.groups()[0].split(".")[-1]
        state_module_name = "%s.get%sstate" % (module_name,
                                               client_class.lower())
        state_class = "Get%sState" % client_class
        try:
            state_module = importlib.import_module(state_module_name)
        except ImportError:
            pylogger.error("Error in loading state check module %s" %
                           state_module_name)
            raise
        if hasattr(state_module, state_class):
            return getattr(state_module, state_class)
        raise RuntimeError("State module %r does not have state class "
                           "definition %r" % (state_module, state_class))

    @classmethod
    def wait_for_realized_state(cls, client_obj, id_=None, timeout=None,
                                desired_state=None,
                                **get_realized_state_kwargs):
        if id_ is None:
            if client_obj.id_ is None:
                raise ValueError("UUID of %r is not provided, can't poll the "
                                 "realized state")
            else:
                id_ = client_obj.id_
        for required_attr in cls._REQUIRED_STATE_ATTRS:
            if not getattr(cls, required_attr):
                raise RuntimeError("%r is not defined in %r" %
                                   (required_attr, cls))
        pylogger.debug("Checking for %r %r realization ..." %
                       (cls._client_class, id_))
        if desired_state is None:
            desired_state = cls._SUCCESS

        def _realized_logical_state_checker(result_dict):
            return (result_dict["response"]["state"] == desired_state)

        def _state_checker_exc_handler(exc):
            pylogger.debug("%s state checker returned "
                           "exception: %r" % (cls._client_class, exc))

        result = timeouts.logical_component_realization_timeout.wait_until(
            cls.get_realized_state, args=[client_obj, cls._get_state_class(),
                                          cls._id_param, id_],
            kwargs=get_realized_state_kwargs, timeout=timeout,
            checker=_realized_logical_state_checker,
            exc_handler=_state_checker_exc_handler, logger=pylogger)
        if 'state' not in result['response']:
            pylogger.debug("No state found in result: %s" %
                           pprint.pformat(result))
            reason = "No state found in result object"
            raise errors.Error(status_code=common.status_codes.FAILURE,
                               reason=reason)
        if result['response']['state'] != desired_state:
            reason = ("%r %r state realization failed: %s" %
                      (cls._client_class, id_,
                       pprint.pformat(result['response'])))
            raise errors.Error(status_code=common.status_codes.FAILURE,
                               reason=reason)

    @classmethod
    def get_realized_state(cls, client_obj, state_class, id_param,
                           id_value, empty_on_success=None):
        if empty_on_success is None:
            empty_on_success = False
        id_kwargs = {id_param: id_value}
        client_class_obj = state_class(
            connection_object=client_obj.connection, **id_kwargs)
        status_schema_object = client_class_obj.read()
        result_dict = dict()
        if status_schema_object is None and empty_on_success:
            result_dict['response'] = {'state': cls._SUCCESS}
            return result_dict
        status_schema_dict = status_schema_object.get_py_dict_from_object()
        result_dict['response'] = status_schema_dict
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        pylogger.debug("%r %r state is: %r" %
                       (id_value, cls._client_class,
                        result_dict['response']['state']))
        return result_dict


class BaseCRUDImpl(BaseRUDImpl):

    @classmethod
    def create(cls, client_obj, schema=None, parent_id=None, sync=False,
               timeout=None, client_class=None, schema_class=None, id_=None,
               **kwargs):
        cls.sanity_check()
        cls.assign_response_schema_class()

        pylogger.info("%s.create(schema=%s, kwargs=%s)" %
                      (cls.__name__, schema, kwargs))
        client_class_obj = cls.get_sdk_client_object(
            client_obj, parent_id=parent_id, client_class=client_class,
            schema_class=schema_class, id_=id_)
        url_parameters = cls.get_url_parameters(constants.HTTPVerb.POST,
                                                **kwargs)
        payload = utilities.map_attributes(cls._attribute_map, schema)
        pylogger.debug("Payload: %s" % payload)
        schema_class = (schema_class if schema_class else cls._schema_class)
        schema_class_obj = schema_class(payload)
        schema_object = client_class_obj.create(schema_object=schema_class_obj,
                                                url_parameters=url_parameters)

        schema_dict = schema_object.get_py_dict_from_object()
        verification_form = utilities.map_attributes(
            cls._attribute_map, schema_dict, reverse_attribute_map=True)

        result_dict = verification_form
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        if sync:
            cls.wait_for_realized_state(
                client_obj, id_=result_dict['id_'], timeout=timeout)
        return result_dict

    @classmethod
    def get_id_from_schema(cls, client_obj, schema=None, parent_id=None,
                           **kwargs):
        cls.sanity_check()
        if cls._list_schema_class is None:
            raise TypeError("List schema class is not defined for %s "
                            % cls.__name__)
        else:
            pylogger.debug("Getting ID with _list_schema_class: %r" %
                           cls._list_schema_class)

        pylogger.info("%s.get_id_from_schema(name=%s)" %
                      (cls.__name__, schema))
        user_schema = utilities.map_attributes(cls._attribute_map, schema)
        client_class_obj = cls.get_sdk_client_object(
            client_obj, parent_id=parent_id)

        #
        # Creating list_schema_object of client and
        # sending it to query method. Query method will
        # fill this list_schema_object and return it back
        #
        list_schema_object = cls._list_schema_class()
        url_parameters = cls.get_url_parameters(constants.HTTPVerb.GET,
                                                **kwargs)
        list_schema_object = client_class_obj.query(
            schema_object=list_schema_object,
            url_parameters=url_parameters)

        list_schema_dict = list_schema_object.get_py_dict_from_object()

        #
        # Iterating through dictionary to match user_schema
        # with product_schema and get corresponding id
        #
        id_ = None
        for attribute in list_schema_dict:
            if type(list_schema_dict[attribute]) in [list]:
                for element in list_schema_dict[attribute]:
                    result = utilities.compare_schema(user_schema, element)
                    if result:
                        id_ = element['id']
                        pylogger.info('Id of matching object %s, %s'
                                      % (cls.__name__, id_))
                        break
        if id_ is None:
            pylogger.debug(
                "Failed to get ID from schema: %r\nlist_schema_dict:\n%s" %
                (list_schema_object, pprint.pformat(list_schema_dict)))
            raise errors.APIError(status_code=common.status_codes.NOT_FOUND)

        result_dict = dict()
        result_dict['id_'] = id_
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] =\
            client_class_obj.last_calls_status_code
        return result_dict

    @classmethod
    def query(cls, client_obj, parent_id=None, **kwargs):
        cls.sanity_check()
        if cls._list_schema_class is None:
            raise TypeError("List schema class is not defined for %s "
                            % cls.__name__)

        pylogger.info("%s.query" % cls.__name__)

        client_class_obj = cls.get_sdk_client_object(
            client_obj, parent_id=parent_id)

        list_schema_object = cls._list_schema_class()
        url_parameters = cls.get_url_parameters(constants.HTTPVerb.GET,
                                                **kwargs)
        list_schema_object = client_class_obj.query(
            schema_object=list_schema_object,
            url_parameters=url_parameters)

        list_schema_dict = list_schema_object.get_py_dict_from_object()

        verification_form = utilities.map_attributes(
            cls._attribute_map, list_schema_dict, reverse_attribute_map=True)

        result_dict = dict()
        result_dict['response'] = verification_form
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict


class MockCRUDImpl(BaseCRUDImpl, Mock):

    @classmethod
    def create(cls, client_obj, schema=None, **kwargs):
        return cls.set_mock_cache(
            None, schema, status_code=httplib.CREATED)

    @classmethod
    def read(cls, client_obj, id_=None, **kwargs):
        return cls.get_mock_cache(id_, status_code=httplib.OK)

    @classmethod
    def update(cls, client_obj, id_=None, schema=None, **kwargs):
        return cls.set_mock_cache(id_, schema, status_code=httplib.OK)

    @classmethod
    def delete(cls, client_obj, id_=None, **kwargs):
        return cls.clear_mock_cache(id_, status_code=httplib.OK)


if __name__ == '__main__':
    import doctest
    doctest.testmod(optionflags=(
        doctest.ELLIPSIS | doctest.NORMALIZE_WHITESPACE))
