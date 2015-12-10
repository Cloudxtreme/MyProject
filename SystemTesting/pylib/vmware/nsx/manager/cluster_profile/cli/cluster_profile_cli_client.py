import vmware.base.profile as profile
import vmware.nsx.manager.manager_client as manager_client


class ClusterProfileCLIClient(profile.Profile,
                              manager_client.NSXManagerCLIClient):
    def __init__(self, parent=None, id_=None):
        super(ClusterProfileCLIClient, self).__init__(parent=parent, id_=id_)
