import vmware.base.appmgmt as appmgmt
import vmware.nsx.manager.manager_client as manager_client


class NtpCLIClient(appmgmt.ApplianceManagement,
                   manager_client.NSXManagerAPIClient):

    """
    NtpCLIClient.
    """

    def __init__(self, parent=None, id_=None):
        super(NtpCLIClient, self).__init__(parent=parent)
        self.id_ = id_