import vmware.nsx.manager.routing.static_routes.static_routes as static_routes
import vmware.nsx.manager.manager_client as manager_client


class StaticRoutesAPIClient(static_routes.StaticRoutes,
                            manager_client.NSXManagerAPIClient):
    pass
