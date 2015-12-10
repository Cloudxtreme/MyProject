import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl\
    as base_crud_impl
import vmware.nsx_api.manager.fabricnode.addnode\
    as addnode
import vmware.nsx_api.manager.fabricnode.schema.node_schema\
    as node_schema
import vmware.nsx_api.manager.fabricnode.schema.nodelistresult_schema\
    as nodelistresult_schema


pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description',
        'host_msg_client_info': 'msg_client_info'
    }
    _client_class = addnode.AddNode
    _schema_class = node_schema.HostNodeSchema
    _list_schema_class = nodelistresult_schema.NodeListResultSchema

    @classmethod
    def get_url_parameters(cls, http_verb, **kwargs):
        url_params = super(NSX70CRUDImpl, cls).get_url_parameters(
            http_verb, **kwargs)
        if 'node_type' not in url_params:
            url_params['node_type'] = 'HostNode'
        return url_params
