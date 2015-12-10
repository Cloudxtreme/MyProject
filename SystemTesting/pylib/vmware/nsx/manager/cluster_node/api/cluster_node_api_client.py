import vmware.nsx.manager.cluster_node.cluster_node as cluster_node
import vmware.nsx.manager.api.manager_api_client as manager_api_client


class ClusterNodeAPIClient(cluster_node.ClusterNode,
                           manager_api_client.ManagerAPIClient):

    def __init__(self, parent=None, id_=None):
        super(ClusterNodeAPIClient, self).__init__(parent=parent, id_=id_)
