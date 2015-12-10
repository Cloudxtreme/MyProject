import vmware.common.base_client as base_client
import vmware.nsx.controller.cluster_node.cluster_node as cluster_node


class ClusterNodeAPIClient(cluster_node.ClusterNode,
                           base_client.BaseAPIClient):

    def __init__(self, parent=None, id_=None):
        super(ClusterNodeAPIClient, self).__init__(parent=parent)
        self.id_ = id_
