import vmware.nsx.manager.manager_client as manager_client
import vmware.nsx.edge.edge_node.edge_node as edge_node


class EdgeNodeCLIClient(edge_node.EdgeNode,
                        manager_client.NSXManagerCLIClient):
    def __init__(self, parent=None, id_=None):
        super(EdgeNodeCLIClient, self).__init__(parent=parent)
        self.id_ = id_
