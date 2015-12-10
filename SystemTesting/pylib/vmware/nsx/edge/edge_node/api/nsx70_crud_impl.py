import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.manager.fabricnode.addnode as addnode
import vmware.nsx_api.manager.fabricnode.schema.node_schema as node_schema
import vmware.nsx_api.manager.fabricnode.schema.nodelistresult_schema \
    as nodelistresult_schema


pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):
    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description',
        'ipaddresses': 'ip_addresses'
    }

    _client_class = addnode.AddNode
    _schema_class = node_schema.NodeSchema
    _list_schema_class = nodelistresult_schema.NodeListResultSchema

    @classmethod
    def query(cls, client_obj, **kwargs):
        cls.sanity_check()
        if cls._list_schema_class is None:
            raise TypeError("List schema class is not defined for %s "
                            % cls.__name__)

        pylogger.info("%s.query(kwargs=%s)" %
                      (cls.__name__, kwargs))

        if kwargs['node_type'] is None:
            raise ValueError('node_type parameter is missing')

        node_type = kwargs['node_type']

        node_type_client_class_obj = cls._client_class(
            connection_object=client_obj.connection)

        node_type_list_schema_object = cls._list_schema_class()

        node_type_list_schema_object = node_type_client_class_obj.query(
            node_type_list_schema_object,
            url_parameters={'node_type': node_type})

        node_type_list_schema_dict = node_type_list_schema_object.\
            get_py_dict_from_object()

        verification_form = utilities.map_attributes(
            cls._attribute_map, node_type_list_schema_dict,
            reverse_attribute_map=True)

        result_dict = dict()
        result_dict['response'] = verification_form
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            node_type_client_class_obj.last_calls_status_code)
        return result_dict