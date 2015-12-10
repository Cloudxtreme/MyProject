import vmware.nsx_api.manager.ccpstatesync.readstatesynchandlenode as\
    readstatesynchandlenode
import vmware.nsx_api.manager.ccpstatesync.schema.statesyncnode_schema as\
    statesyncnode_schema

import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'state_synch_node_id': 'cluster_node_id',
        'ipaddress': 'api_listen_ip'
    }
    _client_class = readstatesynchandlenode.ReadStateSyncHandleNode
    _schema_class = statesyncnode_schema.StateSyncNodeSchema
    _response_schema_class = statesyncnode_schema.StateSyncNodeSchema
    _list_schema_class = statesyncnode_schema.StateSyncNodeSchema
