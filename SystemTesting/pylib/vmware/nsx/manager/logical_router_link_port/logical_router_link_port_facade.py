import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.nsx.manager.logical_router_link_port.logical_router_link_port \
    as logical_router_link_port
import vmware.nsx.manager.logical_router_link_port.api.logical_router_link_port_api_client \
    as logical_router_link_port_api_client
import vmware.nsx.manager.logical_router_link_port.cli.logical_router_link_port_cli_client \
    as logical_router_link_port_cli_client


class LogicalRouterLinkPortFacade(logical_router_link_port.
                                  LogicalRouterLinkPort,
                                  base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(LogicalRouterLinkPortFacade, self).__init__(parent=parent)
        # instantiate client objects
        api_client = logical_router_link_port_api_client.\
            LogicalRouterLinkPortAPIClient(parent=parent.get_client(
                constants.ExecutionType.API) if parent else None)
        cli_client = logical_router_link_port_cli_client.\
            LogicalRouterLinkPortCLIClient(parent=parent.get_client(
                constants.ExecutionType.CLI) if parent else None)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}