import vmware.nsx_api.manager.certificatemanager.addcrl as addcrl
import vmware.nsx_api.manager.certificatemanager.schema.crl_schema\
    as crl_schema
import vmware.nsx_api.manager.certificatemanager.schema.crllist_schema\
    as crllist_schema

import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'name': 'display_name'
    }

    _client_class = addcrl.AddCrl
    _schema_class = crl_schema.CrlSchema
    _response_schema_class = crllist_schema.CrlListSchema
    _list_schema_class = crllist_schema.CrlListSchema

    @classmethod
    def update(cls, client_obj, id_=None, schema=None, **kwargs):
        cls._response_schema_class = crl_schema.CrlSchema
        cls.sanity_check()
        cls.assign_response_schema_class()

        payload = utilities.map_attributes(cls._attribute_map, schema)
        client_class_obj = cls._client_class(
            connection_object=client_obj.connection,
            url_prefix=cls._url_prefix)
        client_class_obj.set_endpoints("/trust-management/crls")
        client_class_obj.schema_class = (
            cls._response_schema_class.__module__ + '.' +
            cls._response_schema_class.__name__)
        merged_object = client_class_obj.update(payload, object_id=id_,
                                                **kwargs)

        result_dict = merged_object.get_py_dict_from_object()
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict

    @classmethod
    def delete(cls, client_obj, id_=None, **kwargs):
        cls.sanity_check()
        client_class_obj = cls._client_class(
            connection_object=client_obj.connection,
            url_prefix=cls._url_prefix)
        client_class_obj.set_endpoints("/trust-management/crls")
        client_class_obj.delete(id_)

        result_dict = {
            'response_data': {
                'status_code': client_class_obj.last_calls_status_code}}
        return result_dict

    @classmethod
    def read(cls, client_obj, id_=None, **kwargs):
        cls._response_schema_class = crl_schema.CrlSchema
        cls.sanity_check()
        cls.assign_response_schema_class()
        client_class_obj = cls._client_class(
            connection_object=client_obj.connection,
            url_prefix=cls._url_prefix)
        client_class_obj.schema_class = (
            cls._response_schema_class.__module__ + '.' +
            cls._response_schema_class.__name__)
        client_class_obj.set_endpoints("/trust-management/crls")
        schema_object = client_class_obj.read(id_)

        schema_dict = schema_object.get_py_dict_from_object()
        verification_form = utilities.map_attributes(
            cls._attribute_map, schema_dict, reverse_attribute_map=True)

        result_dict = verification_form
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict

    @classmethod
    def query(cls, client_obj, **kwargs):
        cls.sanity_check()
        if cls._list_schema_class is None:
            raise TypeError("List schema class is not defined for %s "
                            % cls.__name__)

        pylogger.info("%s.query" % cls.__name__)

        client_class_obj = cls._client_class(
            connection_object=client_obj.connection,
            url_prefix=cls._url_prefix)
        client_class_obj.set_endpoints("/trust-management/crls")

        list_schema_object = cls._list_schema_class()
        list_schema_object = client_class_obj.query(list_schema_object)

        list_schema_dict = list_schema_object.get_py_dict_from_object()

        verification_form = utilities.map_attributes(
            cls._attribute_map, list_schema_dict, reverse_attribute_map=True)

        result_dict = dict()
        result_dict['response'] = verification_form
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict
