import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.nsx.manager.logical_router.logical_router as logical_router
import vmware.nsx.manager.logical_router.api.logical_router_api_client \
    as logical_router_api_client
import vmware.nsx.manager.logical_router.cli.logical_router_cli_client \
    as logical_router_cli_client
import vmware.nsx.manager.routing.static_routes.static_routes_facade \
    as static_routes_facade
import vmware.nsx.manager.routing.bgp.bgp_facade as bgp_facade
import vmware.nsx.manager.routing.redistribution.redistribution_facade \
    as redistribution_facade
import vmware.nsx.manager.routing.routing_config.routing_config_facade \
    as routing_config_facade
import vmware.nsx.manager.routing.route_advertisement.route_advertisement_facade \
    as route_advertisement_facade
import vmware.common.versions as versions
import vmware.nsx.manager.logical_router.ui.logical_router_ui_client \
    as logical_router_ui_client


class LogicalRouterFacade(logical_router.LogicalRouter,
                          base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE

    def __init__(self, parent=None, id_=None):
        super(LogicalRouterFacade, self).__init__(parent=parent, id_=id_)

        # instantiate client objects
        api_client = logical_router_api_client.LogicalRouterAPIClient(
            parent=parent.get_client(constants.ExecutionType.API) if
            parent else None, id_=id_)
        cli_client = logical_router_cli_client.LogicalRouterCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI) if
            parent else None, id_=id_)
        ui_client = logical_router_ui_client.LogicalRouterUIClient(
            parent=parent.get_client(constants.ExecutionType.UI) if
            parent else None, id_=id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client,
                         constants.ExecutionType.UI: ui_client}

    def _read_sub_component(self, facade_obj, schema=None, **kwargs):
        if isinstance(schema, list):
            # XXX(Krishna): Perl code passes a list of one schema instead of
            # schema itself, hacking to workaround the issue
            schema = schema[0]
        return facade_obj.read(parent_id=self.id_)

    def _update_sub_component(self, facade_obj, schema=None, **kwargs):
        if isinstance(schema, list):
            # XXX(Krishna): Perl code passes a list of one schema instead of
            # schema itself, hacking to workaround the issue
            schema = schema[0]
        if schema:
            return facade_obj.update(schema=schema, parent_id=self.id_)
        else:
            return facade_obj.delete(parent_id=self.id_)

    def get_static_routes(self, schema=None, **kwargs):
        facade_obj = static_routes_facade.StaticRoutesFacade(
            parent=self.parent)
        return self._read_sub_component(facade_obj, schema=schema, **kwargs)

    def update_bgp_neighbours(self, schema=None, **kwargs):
        facade_obj = bgp_facade.BGPFacade(parent=self.parent)
        return self._update_sub_component(facade_obj, schema=schema, **kwargs)

    def update_static_routes(self, schema=None, **kwargs):
        facade_obj = static_routes_facade.StaticRoutesFacade(
            parent=self.parent)
        return self._update_sub_component(facade_obj, schema=schema, **kwargs)

    def update_route_redistribution(self, schema=None, **kwargs):
        facade_obj = redistribution_facade.RedistributionFacade(
            parent=self.parent)
        return self._update_sub_component(facade_obj, schema=schema, **kwargs)

    def update_routing_config(self, schema=None, **kwargs):
        facade_obj = routing_config_facade.RoutingConfigFacade(
            parent=self.parent)
        return self._update_sub_component(facade_obj, schema=schema, **kwargs)

    def update_route_advertisement(self, schema=None, **kwargs):
        facade_obj = route_advertisement_facade.RouteAdvertisementFacade(
            parent=self.parent)
        return self._update_sub_component(facade_obj, schema=schema, **kwargs)


if __name__ == '__main__':
    import vmware.nsx.manager.logical_router.logical_router_facade \
        as logical_router_facade
    a = logical_router_facade.LogicalRouterFacade()
