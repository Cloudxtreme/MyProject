import vmware.common.base_client as base_client
import vmware.torgateway.tor_port.tor_port as tor_port


class TORPortAPIClient(tor_port.TORPort,
                       base_client.BaseAPIClient):

    def __init__(self, parent=None, id_=None):
        super(TORPortAPIClient, self).__init__(parent=parent)
        self.id_ = id_
