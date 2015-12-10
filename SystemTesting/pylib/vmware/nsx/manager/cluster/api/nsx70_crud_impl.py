import vmware.nsx_api.manager.clustermanagement.readclusterstatus as \
    read_cluster_status

import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {
        'id_': 'id'
    }

    @classmethod
    def status(cls, client_obj, **kwargs):
        client_class_obj = read_cluster_status.ReadClusterStatus(
            connection_object=client_obj.connection)

        status_schema_object = client_class_obj.read()
        status_schema_dict = status_schema_object.get_py_dict_from_object()

        result_dict = dict()
        result_dict['response'] = status_schema_dict
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = (
            client_class_obj.last_calls_status_code)
        return result_dict
