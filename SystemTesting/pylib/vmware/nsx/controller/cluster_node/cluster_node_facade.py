import vmware.nsx.controller.cluster_node.cluster_node as cluster_node
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.controller.cluster_node.cli.cluster_node_cli_client as \
    cluster_node_cli_client
import vmware.nsx.controller.cluster_node.api.cluster_node_api_client as \
    cluster_node_api_client
import vmware.interfaces.labels as labels

pylogger = global_config.pylogger
auto_resolve = base_facade.auto_resolve


class ClusterNodeFacade(cluster_node.ClusterNode, base_facade.BaseFacade):
    """Cluster Node facade class to perform join/un-join CCP clustering"""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.CLI

    def __init__(self, parent=None, id_=None):
        super(ClusterNodeFacade, self).__init__(parent=parent, id_=id_)
        # instantiate client objects.
        cli_client = cluster_node_cli_client.ClusterNodeCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))
        api_client = cluster_node_api_client.ClusterNodeAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))
        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.CLI: cli_client,
                         constants.ExecutionType.API: api_client}

    @auto_resolve(labels.CRUD, execution_type=constants.ExecutionType.API)
    def delete(self, execution_type=constants.ExecutionType.API, obj_id=None,
               **kwargs):
        pass
