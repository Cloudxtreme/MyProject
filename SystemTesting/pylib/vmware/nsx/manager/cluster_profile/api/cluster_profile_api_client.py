import vmware.base.profile as profile
import vmware.nsx.manager.manager_client as manager_client


class ClusterProfileAPIClient(profile.Profile,
                              manager_client.NSXManagerAPIClient):
    def __init__(self, parent=None, id_=None):
        super(ClusterProfileAPIClient, self).__init__(parent=parent, id_=id_)
