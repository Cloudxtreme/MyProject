import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl

pylogger = global_config.pylogger


class AppMgmtCRUDImpl(base_crud_impl.BaseCRUDImpl):

    @classmethod
    def read_with_param_id(cls, client_obj, param_id='', **kwargs):
        cls.sanity_check()
        pylogger.info("%s.read_with_param_id" % cls.__name__)
        client_class_obj = cls._client_class(client_obj.connection,
                                             '/api/v1', param_id)
        client_class_obj.schema_class = (cls._schema_class.__module__ + '.' +
                                         cls._schema_class.__name__)
        schema_object = client_class_obj.read()
        schema_dict = schema_object.get_py_dict_from_object()
        verification_form = utilities.map_attributes(
            cls._attribute_map, schema_dict, reverse_attribute_map=True)

        result_dict = verification_form
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict

    @classmethod
    def update_with_param_id(cls, client_obj, param_id='', schema=None,
                             **kwargs):
        cls.sanity_check()
        pylogger.info("%s.update_with_param_id" % cls.__name__)
        payload = utilities.map_attributes(cls._attribute_map, schema)
        client_class_obj = cls._client_class(client_obj.connection,
                                             '/api/v1', param_id)
        client_class_obj.schema_class = (cls._schema_class.__module__ + '.' +
                                         cls._schema_class.__name__)
        merged_object = client_class_obj.update(payload, **kwargs)
        result_dict = merged_object.get_py_dict_from_object()
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict

    @classmethod
    def query_with_param_id(cls, client_obj, param_id='', **kwargs):
        if cls._list_schema_class is None:
            raise TypeError("List schema class is not defined for %s "
                            % cls.__name__)
        pylogger.info("%s.query_with_param_id" % cls.__name__)
        client_class_obj = cls._client_class(client_obj.connection,
                                             '/api/v1', param_id)

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