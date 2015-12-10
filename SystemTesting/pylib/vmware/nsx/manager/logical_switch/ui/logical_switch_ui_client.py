import vmware.base.switch as switch
import vmware.nsx.manager.manager_client as manager_client


class LogicalSwitchUIClient(switch.Switch, manager_client.NSXManagerUIClient):
    def __init__(self, parent=None, id_=None):
        super(LogicalSwitchUIClient, self).__init__(parent=parent)
        self.id_ = id_
