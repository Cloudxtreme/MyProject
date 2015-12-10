import vmware.base.profile as profile
import vmware.nsx.manager.manager_client as manager_client


class ServiceProfileCLIClient(profile.Profile,
                              manager_client.NSXManagerCLIClient):
    def __init__(self, parent=None, id_=None):
        super(ServiceProfileCLIClient, self).__init__(parent=parent)
        self.id_ = id_