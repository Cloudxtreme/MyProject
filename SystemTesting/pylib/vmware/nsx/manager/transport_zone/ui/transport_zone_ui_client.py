import vmware.base.node as node
import vmware.nsx.manager.manager_client as manager_client


class TransportZoneUIClient(node.Node, manager_client.NSXManagerUIClient):
    def __init__(self, parent=None, id_=None):
        super(TransportZoneUIClient, self).__init__(parent=parent)
        self.id_ = id_
