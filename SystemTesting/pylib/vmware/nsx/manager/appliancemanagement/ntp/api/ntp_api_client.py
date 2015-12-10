import vmware.base.appmgmt as appmgmt
import vmware.nsx.manager.manager_client as manager_client


class NtpAPIClient(appmgmt.ApplianceManagement, manager_client.
                   NSXManagerAPIClient):

    def __init__(self, parent=None, id_=None):
        super(NtpAPIClient, self).__init__(parent=parent)
        self.id_ = id_