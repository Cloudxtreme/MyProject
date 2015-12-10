import vmware.base.port as port
import vmware.nsx.manager.manager_client as manager_client


class LogicalPortAPIClient(port.Port, manager_client.NSXManagerAPIClient):
    def __init__(self, parent=None, id_=None):
        super(LogicalPortAPIClient, self).__init__(parent=parent)
        self.id_ = id_
