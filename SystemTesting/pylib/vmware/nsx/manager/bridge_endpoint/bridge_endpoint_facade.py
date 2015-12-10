import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.bridge_endpoint.api.bridge_endpoint_api_client\
    as bridge_endpoint_api_client
import vmware.nsx.manager.bridge_endpoint.cli.bridge_endpoint_cli_client\
    as bridge_endpoint_cli_client

import vmware.nsx.manager.bridge_endpoint.bridge_endpoint\
    as bridge_endpoint

pylogger = global_config.pylogger


class BridgeEndpointFacade(bridge_endpoint.BridgeEndpoint,
                           base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, id_=None):
        super(BridgeEndpointFacade, self).__init__(parent=parent, id_=id_)

        # instantiate client objects
        api_client = bridge_endpoint_api_client.BridgeEndpointAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))
        cli_client = bridge_endpoint_cli_client.BridgeEndpointCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
