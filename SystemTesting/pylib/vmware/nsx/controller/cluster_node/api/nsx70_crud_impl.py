import vmware.nsx_api.manager.clustermanagement.addclusternode as addclusternode  # noqa
import vmware.nsx_api.manager.clustermanagement.schema.clusternodeconfig_schema as clusternodeconfig_schema  # noqa

import vmware.common.global_config as global_config
import vmware.interfaces.crud_interface as crud_interface


pylogger = global_config.pylogger


class NSX70CRUDImpl(crud_interface.CRUDInterface):
    #  Attribute map
    _attribute_map = {
        'id_': 'exporter_name',
    }

    _schema_class = clusternodeconfig_schema.ClusterNodeConfigSchema
    _client_class = addclusternode.AddClusterNode

    @classmethod
    def delete(self, client_obj, id_=None, **kwargs):
        pylogger.info("id = %s" % id_)

        client_class_obj = self._client_class(
            connection_object=client_obj.connection)
        client_class_obj.delete(id_)

        result_dict = {
            'response_data': {
                'status_code': client_class_obj.last_calls_status_code}}
        pylogger.info(" status is %s "
                      % client_class_obj.last_calls_status_code)
        return result_dict
