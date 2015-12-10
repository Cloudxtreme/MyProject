import vmware.base.appmgmt as appmgmt
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.appliancemanagement.route.api.\
    route_api_client as route_api_client
import vmware.nsx.manager.appliancemanagement.route.cli.\
    route_cli_client as route_cli_client

pylogger = global_config.pylogger


class RouteFacade(appmgmt.ApplianceManagement, base_facade.BaseFacade):
    """
    RouteFacade class to perform CRUDAQ
    """

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(RouteFacade, self).__init__(parent)
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = route_api_client.RouteAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))
        cli_client = route_cli_client.RouteCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
