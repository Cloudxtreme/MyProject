import vmware.base.node as node
import vmware.nsx.manager.manager_client as manager_client


class TransportProfileAPIClient(node.Node, manager_client.NSXManagerAPIClient):
    def __init__(self, parent=None, id_=None):
        super(TransportProfileAPIClient, self).__init__(parent=parent, id_=id_)
        self.id_ = id_
