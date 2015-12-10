import vmware.base.cluster as cluster
import vmware.nsx.manager.api.manager_api_client as manager_api_client


class ClusterAPIClient(cluster.Cluster, manager_api_client.ManagerAPIClient):

    def __init__(self, parent=None, id_=None):
        super(ClusterAPIClient, self).__init__(parent=parent)
        self.id_ = id_
