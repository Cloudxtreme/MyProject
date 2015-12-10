import vmware.base.profile as profile
import vmware.nsx.manager.manager_client as manager_client


class UplinkProfileCLIClient(profile.Profile,
                             manager_client.NSXManagerCLIClient):
    def __init__(self, parent=None, id_=None):
        super(UplinkProfileCLIClient, self).__init__(parent=parent)
        self.id_ = id_
