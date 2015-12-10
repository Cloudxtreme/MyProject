import vmware.base.port as port
import vmware.nsx.manager.manager_client as manager_client


class LogicalPortCLIClient(port.Port, manager_client.NSXManagerCLIClient):
    def __init__(self, parent=None, id_=None):
        super(LogicalPortCLIClient, self).__init__(parent=parent)
        self.id_ = id_
