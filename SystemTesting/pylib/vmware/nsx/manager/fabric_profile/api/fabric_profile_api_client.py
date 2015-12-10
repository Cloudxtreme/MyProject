import vmware.base.profile as profile
import vmware.nsx.manager.manager_client as manager_client


class FabricProfileAPIClient(profile.Profile,
                             manager_client.NSXManagerAPIClient):
    def __init__(self, parent=None, id_=None):
        super(FabricProfileAPIClient, self).__init__(parent=parent)
        self.id_ = id_
