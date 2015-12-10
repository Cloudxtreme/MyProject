import vmware.nsx.manager.logical_router_link_port.logical_router_link_port \
    as logical_router_link_port
import vmware.nsx.manager.manager_client as manager_client


class LogicalRouterLinkPortCLIClient(logical_router_link_port.
                                     LogicalRouterLinkPort,
                                     manager_client.NSXManagerCLIClient):
    def __init__(self, parent=None, id_=None):
        super(LogicalRouterLinkPortCLIClient, self).__init__(parent=parent)
        self.id_ = id_
