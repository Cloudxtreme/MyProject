import vmware.nsx.manager.logical_router_port.logical_router_port \
    as logical_router_port
import vmware.nsx.manager.manager_client as manager_client


class LogicalRouterPortAPIClient(logical_router_port.LogicalRouterPort,
                                 manager_client.NSXManagerAPIClient):
    def __init__(self, parent=None, id_=None):
        super(LogicalRouterPortAPIClient, self).__init__(parent=parent,
                                                         id_=id_)
