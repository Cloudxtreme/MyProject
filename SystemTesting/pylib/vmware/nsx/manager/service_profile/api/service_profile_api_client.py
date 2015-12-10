import vmware.base.profile as profile
import vmware.nsx.manager.manager_client as manager_client


class ServiceProfileAPIClient(profile.Profile,
                              manager_client.NSXManagerAPIClient):
    def __init__(self, parent=None, id_=None):
        super(ServiceProfileAPIClient, self).__init__(parent=parent)
        self.id_ = id_