import vmware.base.switch as switch
import vmware.nsx.manager.manager_client as manager_client


# This is a dummy client just to verify logical switch state information on the
# controllers and the transport nodes. This also means that we would want to
# override some attributes of the the base client to make this dummy client
# work.
class LogicalSwitchCLIClient(switch.Switch,
                             manager_client.NSXManagerCLIClient):
    def __init__(self, parent=None, id_=None):
        super(LogicalSwitchCLIClient, self).__init__(parent=parent)
        self.id_ = id_
