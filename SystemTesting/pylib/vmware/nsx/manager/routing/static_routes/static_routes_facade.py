import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.nsx.manager.routing.static_routes.static_routes as static_routes
import vmware.nsx.manager.routing.static_routes.api.static_routes_api_client \
    as static_routes_api_client
import vmware.nsx.manager.routing.static_routes.cli.static_routes_cli_client \
    as static_routes_cli_client


class StaticRoutesFacade(static_routes.StaticRoutes, base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, id_=None):
        super(StaticRoutesFacade, self).__init__(id_=id_, parent=parent)

        # instantiate client objects
        api_client = static_routes_api_client.StaticRoutesAPIClient(
            parent=parent.get_client(constants.ExecutionType.API)
            if parent else None)
        cli_client = static_routes_cli_client.StaticRoutesCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI)
            if parent else None)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}

if __name__ == '__main__':
    import vmware.nsx.manager.routing.static_routes.static_routes_facade \
        as static_routes_facade
    a = static_routes_facade.StaticRoutesFacade()
