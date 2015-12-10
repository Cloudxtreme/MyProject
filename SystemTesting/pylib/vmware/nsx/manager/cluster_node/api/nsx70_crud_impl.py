import vmware.nsx_api.manager.clustermanagement.addclusternode as addclusternode  # noqa
import vmware.nsx_api.manager.common.addclusternodespec_schema as addclusternodespec_schema  # noqa
import vmware.nsx_api.manager.clustermanagement.schema.clusternodeconfiglistresult_schema as clusternodeconfiglistresult_schema  # noqa
import vmware.nsx_api.manager.clustermanagement.schema.clusternodeconfig_schema as clusternodeconfig_schema  # noqa

import vmware.common.global_config as global_config
import vmware.common.constants as constants
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {
        'username': 'user_name',
        'cluster_node_type': 'type',
        'id_': 'id',
        'manager_ip': 'remote_address',
        'manager_thumbprint': 'cert_thumbprint',
        'node_type': 'type'
    }
    _client_class = addclusternode.AddClusterNode
    _schema_class = addclusternodespec_schema.AddClusterNodeSpecSchema
    _response_schema_class = clusternodeconfig_schema.ClusterNodeConfigSchema
    _list_schema_class = clusternodeconfiglistresult_schema.ClusterNodeConfigListResultSchema  # noqa

    @classmethod
    def get_url_parameters(cls, http_verb, **kwargs):
        url_parameters = None
        if http_verb == constants.HTTPVerb.POST:
            url_parameters = {"action": "add_cluster_node"}
        return url_parameters