import vmware.base.profile as profile
import vmware.nsx.manager.manager_client as manager_client


class TransportProfileUIClient(profile.Profile,
                               manager_client.NSXManagerUIClient):
    def __init__(self, parent=None, id_=None):
        super(TransportProfileUIClient, self).__init__(parent=parent, id_=id_)
        self.id_ = id_
