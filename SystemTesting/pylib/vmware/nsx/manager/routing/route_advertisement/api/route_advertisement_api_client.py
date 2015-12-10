import vmware.nsx.manager.routing.route_advertisement.route_advertisement \
    as route_advertisement
import vmware.nsx.manager.manager_client as manager_client


class RouteAdvertisementAPIClient(route_advertisement.RouteAdvertisement,
                                  manager_client.NSXManagerAPIClient):
    pass
