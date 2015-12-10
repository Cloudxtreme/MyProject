import vmware.base.auth as auth
import vmware.nsx.manager.manager_client as manager_client


class AAAAPIClient(auth.Auth, manager_client.NSXManagerAPIClient):

    def __init__(self, parent=None, id_=None):
        super(AAAAPIClient, self).__init__(parent=parent)
        self.id_ = id_
