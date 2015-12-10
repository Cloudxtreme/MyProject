import vmware.base.profile as profile
import vmware.nsx.manager.manager_client as manager_client


class FabricProfileUIClient(profile.Profile,
                            manager_client.NSXManagerUIClient):
    def __init__(self, parent=None, id_=None):
        super(FabricProfileUIClient, self).__init__(parent=parent)
        self.id_ = id_
