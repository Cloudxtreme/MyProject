import vmware.base.switch as switch
import vmware.nsx.manager.manager_client as manager_client


class LogicalSwitchAPIClient(switch.Switch, manager_client.NSXManagerAPIClient):
    def __init__(self, parent=None, id_=None):
        super(LogicalSwitchAPIClient, self).__init__(parent=parent)
        self.id_ = id_
