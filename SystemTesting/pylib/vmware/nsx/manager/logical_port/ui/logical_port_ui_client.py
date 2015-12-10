import vmware.base.port as port
import vmware.nsx.manager.manager_client as manager_client


class LogicalPortUIClient(port.Port, manager_client.NSXManagerUIClient):
    def __init__(self, parent=None, id_=None):
        super(LogicalPortUIClient, self).__init__(parent=parent)
        self.id_ = id_
