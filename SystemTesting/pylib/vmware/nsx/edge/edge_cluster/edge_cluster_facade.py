import vmware.common.base_facade as base_facade
import vmware.common.constants as constants

import vmware.nsx.edge.edge_cluster.edge_cluster as edge_cluster
import vmware.nsx.edge.edge_cluster.api.edge_cluster_api_client \
    as edge_cluster_api_client
import vmware.nsx.edge.edge_cluster.cli.edge_cluster_cli_client \
    as edge_cluster_cli_client
import vmware.nsx.edge.edge_cluster.ui.edge_cluster_ui_client \
    as edge_cluster_ui_client


class EdgeClusterFacade(edge_cluster.EdgeCluster, base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, id_=None):
        super(EdgeClusterFacade, self).__init__(parent=parent)
        self.nsx_manager_obj = parent

        # instantiate client objects
        api_client = edge_cluster_api_client.EdgeClusterAPIClient(
            parent=parent.get_client(constants.ExecutionType.API), id_=id_)
        cli_client = edge_cluster_cli_client.EdgeClusterCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI), id_=id_)
        ui_client = edge_cluster_ui_client.EdgeClusterUIClient(
            parent=parent.get_client(constants.ExecutionType.UI), id_=id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client,
                         constants.ExecutionType.UI: ui_client}
