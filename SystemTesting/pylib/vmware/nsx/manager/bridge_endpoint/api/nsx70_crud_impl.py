import vmware.nsx_api.manager.bridgeendpoint.bridgeendpoint\
    as bridgeendpoint
import vmware.nsx_api.manager.bridgeendpoint.schema.bridgeendpoint_schema\
    as bridgeendpoint_schema

import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description',
        'guest_vlan': 'guest_vlan_tag',
        'node_id': 'bridge_cluster_id',
        'vlan_id': 'vlan',
        'ha': 'ha_enable'
    }

    _client_class = bridgeendpoint.BridgeEndpoint
    _schema_class = bridgeendpoint_schema.BridgeEndpointSchema
