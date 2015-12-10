import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.versions as versions
import vmware.nsx.manager.routing.route_advertisement.route_advertisement \
    as route_advertisement
import vmware.nsx.manager.routing.route_advertisement.api.\
    route_advertisement_api_client as route_advert_api_client
import vmware.nsx.manager.routing.route_advertisement.cli.\
    route_advertisement_cli_client as route_advert_cli_client


class RouteAdvertisementFacade(route_advertisement.RouteAdvertisement,
                               base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE

    def __init__(self, parent=None, id_=None):
        super(RouteAdvertisementFacade, self).__init__(parent=parent, id_=id_)

        # Instantiate client objects
        api_client = route_advert_api_client.RouteAdvertisementAPIClient(
            parent=parent.get_client(constants.ExecutionType.API)
            if parent else None)
        cli_client = route_advert_cli_client.RouteAdvertisementCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI)
            if parent else None)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}

if __name__ == '__main__':
    import vmware.nsx.manager.routing.route_advertisement.\
        route_advertisement_facade as route_advertisement_facade
    route_advertisement_facade.RouteAdvertisementFacade()
