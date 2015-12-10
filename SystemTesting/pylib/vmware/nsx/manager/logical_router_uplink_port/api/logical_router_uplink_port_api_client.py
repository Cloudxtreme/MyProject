import vmware.nsx.manager.logical_router_uplink_port.logical_router_uplink_port \
    as logical_router_uplink_port
import vmware.nsx.manager.manager_client as manager_client


class LogicalRouterUpLinkPortAPIClient(logical_router_uplink_port.
                                       LogicalRouterUpLinkPort,
                                       manager_client.NSXManagerAPIClient):
    def __init__(self, parent=None, id_=None):
        super(LogicalRouterUpLinkPortAPIClient, self).__init__(parent=parent)
        self.id_ = id_
