import vmware.base.node as node
import vmware.nsx.manager.manager_client as manager_client


class TransportZoneCLIClient(node.Node, manager_client.NSXManagerCLIClient):
    def __init__(self, parent=None, id_=None):
        super(TransportZoneCLIClient, self).__init__(parent=parent)
        self.id_ = id_
