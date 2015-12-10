import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.routing.route_maps.api.\
    route_maps_api_client as route_maps_api_client
import vmware.nsx.manager.routing.route_maps.route_maps\
    as route_maps

pylogger = global_config.pylogger


class RouteMapsFacade(route_maps.RouteMaps, base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, id_=None):
        super(RouteMapsFacade, self).__init__(parent=parent, id_=id_)

        # instantiate client objects
        api_client = route_maps_api_client.RouteMapsAPIClient(
            parent=parent.get_client(constants.ExecutionType.API),
            id_=id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client}