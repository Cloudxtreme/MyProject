import vmware.nsx.manager.manager_client as manager_client
import vmware.nsx.edge.edge_cluster.edge_cluster as edge_cluster


class EdgeClusterCLIClient(edge_cluster.EdgeCluster,
                           manager_client.NSXManagerCLIClient):
    def __init__(self, parent=None, id_=None):
        super(EdgeClusterCLIClient, self).__init__(parent=parent)
        self.id_ = id_