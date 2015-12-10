import vmware.nsx.manager.logical_router_port.logical_router_port \
    as logical_router_port
import vmware.nsx.manager.manager_client as manager_client


class LogicalRouterPortCLIClient(logical_router_port.LogicalRouterPort,
                                 manager_client.NSXManagerCLIClient):
    pass
