import vmware.nsx_api.manager.certificatemanager.getcryptoalgorithms\
    as getcryptoalgorithms
import vmware.nsx_api.manager.certificatemanager.getkeysizes\
    as getkeysizes
import vmware.nsx_api.manager.certificatemanager.schema.intlist_schema\
    as intlist_schema
import vmware.nsx_api.manager.certificatemanager.schema.stringlist_schema\
    as stringlist_schema

import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {}

    _client_class = getcryptoalgorithms.GetCryptoAlgorithms
    _schema_class = stringlist_schema.StringListSchema
    _list_schema_class = stringlist_schema.StringListSchema

    @classmethod
    def get_key_sizes(cls, client_obj, **kwargs):
        cls._client_class = getkeysizes.GetKeySizes
        cls._schema_class = intlist_schema.IntListSchema
        cls._list_schema_class = intlist_schema.IntListSchema
        cls.sanity_check()
        if cls._list_schema_class is None:
            raise TypeError("List schema class is not defined for %s "
                            % cls.__name__)

        pylogger.info("%s.get_key_sizes" % cls.__name__)

        client_class_obj = cls._client_class(
            connection_object=client_obj.connection,
            param_1_id=client_obj.id_)

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
