import vmware.common.base_client as base_client
import vmware.torgateway.tor_switch.tor_switch as tor_switch


class TORSwitchAPIClient(tor_switch.TORSwitch,
                         base_client.BaseAPIClient):

    def __init__(self, parent=None, id_=None):
        super(TORSwitchAPIClient, self).__init__(parent=parent)
        self.id_ = id_
