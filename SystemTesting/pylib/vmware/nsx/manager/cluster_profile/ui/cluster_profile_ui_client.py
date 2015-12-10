import vmware.base.profile as profile
import vmware.nsx.manager.manager_client as manager_client


class ClusterProfileUIClient(profile.Profile,
                             manager_client.NSXManagerUIClient):
    def __init__(self, parent=None, id_=None):
        super(ClusterProfileUIClient, self).__init__(parent=parent, id_=id_)
