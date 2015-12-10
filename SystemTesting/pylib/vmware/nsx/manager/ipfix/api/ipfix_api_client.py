import vmware.base.ipfix as ipfix
import vmware.nsx.manager.manager_client as manager_client


class IpfixAPIClient(ipfix.Ipfix, manager_client.NSXManagerAPIClient):

    def __init__(self, parent=None, id_=""):
        super(IpfixAPIClient, self).__init__(parent=parent)
        self.id_ = id_
