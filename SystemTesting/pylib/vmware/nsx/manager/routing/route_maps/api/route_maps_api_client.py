import vmware.nsx.manager.routing.route_maps.route_maps\
    as route_maps
import vmware.nsx.manager.manager_client as manager_client


class RouteMapsAPIClient(route_maps.RouteMaps,
                         manager_client.NSXManagerAPIClient):
    pass