import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.manager.transportnode.transportnode as transportnode
import vmware.nsx_api.manager.transportnode.schema.transportnode_schema \
    as transportnode_schema

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'summary': 'description',
        'switch_name': 'host_switch_name',
        'ippool_id': 'static_ip_pool_id',
        'uplinks': 'pnics',
        'adapter_id': 'device_id',
        'adapter_name': 'uplink_name',
        'transport_zone_endpoint': 'transport_zone_endpoints'
    }

    _client_class = transportnode.TransportNode
    _schema_class = transportnode_schema.TransportNodeSchema
    _id_name = "transport_node_id"
    _id_param = "transportnode_id"
