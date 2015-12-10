import vmware.base.switch as switch
import vmware.common.base_client as base_client


# This is a dummy client just to verify logical switch state information on the
# controllers and the transport nodes. This also means that we would want to
# override some attributes of the the base client to make this dummy client
# work.
class LogicalSwitchCMDClient(switch.Switch,
                             base_client.BaseCMDClient):
    def __init__(self, parent=None, id_=None):
        super(LogicalSwitchCMDClient, self).__init__(parent=parent)
        self.id_ = id_
