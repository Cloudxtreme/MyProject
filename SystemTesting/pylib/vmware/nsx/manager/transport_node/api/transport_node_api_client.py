import vmware.base.node as node
import vmware.nsx.manager.manager_client as manager_client


class TransportNodeAPIClient(node.Node, manager_client.NSXManagerAPIClient):
    def __init__(self, parent=None, id_=None):
        super(TransportNodeAPIClient, self).__init__(parent=parent)
        self.id_ = id_
