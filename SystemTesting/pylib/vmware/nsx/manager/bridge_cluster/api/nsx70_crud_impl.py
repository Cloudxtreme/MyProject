import vmware.nsx_api.manager.bridgecluster.bridgecluster\
    as bridgecluster
import vmware.nsx_api.manager.bridgecluster.schema.bridgecluster_schema\
    as bridgecluster_schema

import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description',
        'node_id': 'transport_node_id'
    }

    _client_class = bridgecluster.BridgeCluster
    _schema_class = bridgecluster_schema.BridgeClusterSchema
