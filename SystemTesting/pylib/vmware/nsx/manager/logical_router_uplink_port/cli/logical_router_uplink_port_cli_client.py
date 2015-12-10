import vmware.nsx.manager.logical_router_uplink_port.logical_router_uplink_port \
    as logical_router_uplink_port
import vmware.nsx.manager.manager_client as manager_client


class LogicalRouterUpLinkPortCLIClient(logical_router_uplink_port.
                                       LogicalRouterUpLinkPort,
                                       manager_client.NSXManagerCLIClient):
    def __init__(self, parent=None, id_=None):
        super(LogicalRouterUpLinkPortCLIClient, self).__init__(parent=parent)
        self.id_ = id_
