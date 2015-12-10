import vmware.nsx.manager.routing.routing_config.routing_config \
    as routing_config
import vmware.nsx.manager.manager_client as manager_client


class RoutingConfigCLIClient(routing_config.RoutingConfig,
                             manager_client.NSXManagerCLIClient):
    pass
