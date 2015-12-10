import vmware.torgateway.tor_switch.tor_switch as tor_switch
import vmware.common.base_client as base_client


class TORSwitchCLIClient(tor_switch.TORSwitch, base_client.BaseCLIClient):

    def __init__(self, parent=None, id_=None):
        super(TORSwitchCLIClient, self).__init__(parent=parent)
        self.id_ = id_
        self.parent = parent

    def get_connection(self):
        return self.parent.get_connection()
