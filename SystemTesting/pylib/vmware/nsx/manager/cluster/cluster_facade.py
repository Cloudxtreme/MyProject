import vmware.base.cluster as cluster
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.cluster.api.cluster_api_client as \
    cluster_node_api_client

pylogger = global_config.pylogger


class ClusterFacade(cluster.Cluster, base_facade.BaseFacade):
    """Cluster Node facade class to perform CRUDAQ"""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(ClusterFacade, self).__init__(parent=parent)
        self.parent = parent

        # instantiate client objects.
        api_client = cluster_node_api_client.ClusterAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client}
