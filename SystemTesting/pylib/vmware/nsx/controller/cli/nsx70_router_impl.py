import vmware.interfaces.router_interface as router_interface
import vmware.schema.router.logical_router_schema as logical_router_schema
import vmware.schema.router.route_table_schema as route_table_schema


class NSX70RouterImpl(router_interface.RouterInterface):
    HORIZONTAL_PARSER_TYPE = "raw/horizontalTable"

    @classmethod
    def get_logical_routers(cls, client_object):
        cmd = "get control-clusters logical-routers instance all"
        logical_router_attributes_map = {
            'LR-Id': 'lr_id',
            'LR-Name': 'lr_name',
            'Hosts[]': 'lr_hosts',
            'Edge-Connection': 'edge_active',
            'Service-Controller': 'controller_ip'
        }
        return client_object.execute_cmd_get_schema(
            cmd, logical_router_attributes_map, cls.HORIZONTAL_PARSER_TYPE,
            logical_router_schema.LogicalRouterSchema)

    @classmethod
    def is_master_for_lr(cls, client_object, logical_router_id=None):
        """Check if a controller is the master controller for a given LR"""
        raise NotImplementedError("Needs implementation")

    @classmethod
    def get_logical_router_ports(cls, client_object, logical_router_id=None):
        """Get info for all the LIFs for a given LR instance"""
        raise NotImplementedError("Needs implementation")

    @classmethod
    def get_route_table(cls, client_object, logical_router_id=None):
        """Get routing table for a given LR instance"""
        cmd = ("get logical-router %s ip route" % logical_router_id)
        route_table_attributes_map = {
        }
        return client_object.execute_cmd_get_schema(
            cmd, route_table_attributes_map, cls.HORIZONTAL_PARSER_TYPE,
            route_table_schema.RouteTableSchema)

    @classmethod
    def get_logical_router_port_info(cls, client_object,
                                     logical_router_id=None,
                                     port_id=None):
        """Get info for a given LIF of a given LR instance"""
        raise NotImplementedError("Needs implementation")
