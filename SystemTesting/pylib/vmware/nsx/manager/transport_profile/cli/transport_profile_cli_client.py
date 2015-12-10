import vmware.base.node as node
import vmware.nsx.manager.manager_client as manager_client


class TransportProfileCLIClient(node.Node, manager_client.NSXManagerCLIClient):
    def __init__(self, parent=None, id_=None):
        super(TransportProfileCLIClient, self).__init__(parent=parent, id_=id_)
        self.id_ = id_
