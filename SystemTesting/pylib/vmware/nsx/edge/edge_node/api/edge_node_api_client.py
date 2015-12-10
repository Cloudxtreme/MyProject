import vmware.nsx.edge.edge_node.edge_node as edge_node
import vmware.nsx.manager.manager_client as manager_client


class EdgeNodeAPIClient(edge_node.EdgeNode,
                        manager_client.NSXManagerAPIClient):
    def __init__(self, parent=None, id_=None):
        super(EdgeNodeAPIClient, self).__init__(parent=parent)
        self.id_ = id_
