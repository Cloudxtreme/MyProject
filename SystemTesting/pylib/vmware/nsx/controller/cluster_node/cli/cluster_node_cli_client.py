import vmware.nsx.controller.cluster_node.cluster_node as cluster_node
import vmware.nsx.controller.cli.controller_cli_client as controller_cli_client


class ClusterNodeCLIClient(cluster_node.ClusterNode,
                           controller_cli_client.ControllerCLIClient):

    def __init__(self, parent=None, id_=None):
        super(ClusterNodeCLIClient, self).__init__(parent=parent)
        self.id_ = id_
        self.parent = parent

    def get_connection(self):
        return self.parent.get_connection()
