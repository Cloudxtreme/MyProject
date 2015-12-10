import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.bridge_cluster.api.bridge_cluster_api_client\
    as bridge_cluster_api_client
import vmware.nsx.manager.bridge_cluster.cli.bridge_cluster_cli_client\
    as bridge_cluster_cli_client

import vmware.nsx.manager.bridge_cluster.bridge_cluster\
    as bridge_cluster

pylogger = global_config.pylogger


class BridgeClusterFacade(bridge_cluster.BridgeCluster,
                          base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, id_=None):
        super(BridgeClusterFacade, self).__init__(parent=parent, id_=id_)

        # instantiate client objects
        api_client = bridge_cluster_api_client.BridgeClusterAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))
        cli_client = bridge_cluster_cli_client.BridgeClusterCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}
