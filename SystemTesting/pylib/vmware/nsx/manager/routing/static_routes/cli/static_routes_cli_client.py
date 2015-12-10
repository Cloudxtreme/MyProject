import vmware.nsx.manager.routing.static_routes.static_routes as static_routes
import vmware.nsx.manager.manager_client as manager_client


class StaticRoutesCLIClient(static_routes.StaticRoutes,
                            manager_client.NSXManagerCLIClient):
    def __init__(self, parent=None, id_=None):
        super(StaticRoutesCLIClient, self).__init__(parent=parent)
        self.id_ = id_
