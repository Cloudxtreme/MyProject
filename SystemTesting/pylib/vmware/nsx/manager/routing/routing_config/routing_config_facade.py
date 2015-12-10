import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.versions as versions
import vmware.nsx.manager.routing.routing_config.routing_config \
    as routing_config
import vmware.nsx.manager.routing.routing_config.api.routing_config_api_client \
    as routing_config_api_client
import vmware.nsx.manager.routing.routing_config.cli.routing_config_cli_client \
    as routing_config_cli_client


class RoutingConfigFacade(routing_config.RoutingConfig,
                          base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE

    def __init__(self, parent=None, id_=None):
        super(RoutingConfigFacade, self).__init__(parent=parent, id_=id_)

        # Instantiate client objects
        api_client = routing_config_api_client.RoutingConfigAPIClient(
            parent=parent.get_client(constants.ExecutionType.API)
            if parent else None)
        cli_client = routing_config_cli_client.RoutingConfigCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI)
            if parent else None)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}

if __name__ == '__main__':
    import vmware.nsx.manager.routing.routing_config.routing_config_facade \
        as routing_config_facade
    routing_config_facade.RoutingConfigFacade()
