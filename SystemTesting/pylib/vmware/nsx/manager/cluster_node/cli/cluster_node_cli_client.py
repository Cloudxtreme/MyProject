import vmware.base.node as node
import vmware.nsx.manager.manager_client as manager_client


class ClusterNodeCLIClient(node.Node, manager_client.NSXManagerCLIClient):

    def __init__(self, parent=None, id_=None):
        super(ClusterNodeCLIClient, self).__init__(parent=parent)
        self.id_ = id_
