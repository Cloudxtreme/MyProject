import vmware.nsx.manager.logical_router.logical_router as logical_router
import vmware.nsx.manager.manager_client as manager_client


class LogicalRouterAPIClient(logical_router.LogicalRouter,
                             manager_client.NSXManagerAPIClient):
    def __init__(self, parent=None, id_=None):
        super(LogicalRouterAPIClient, self).__init__(parent=parent, id_=id_)
