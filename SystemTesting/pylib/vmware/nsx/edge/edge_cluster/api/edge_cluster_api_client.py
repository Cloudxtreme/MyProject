import vmware.nsx.edge.edge_cluster.edge_cluster as edge_cluster
import vmware.nsx.manager.manager_client as manager_client


class EdgeClusterAPIClient(edge_cluster.EdgeCluster,
                           manager_client.NSXManagerAPIClient):
    def __init__(self, parent=None, id_=None):
        super(EdgeClusterAPIClient, self).__init__(parent=parent)
        self.id_ = id_