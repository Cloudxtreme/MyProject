import vmware.base.auth as auth
import vmware.nsx.manager.manager_client as manager_client


class AAACLIClient(auth.Auth, manager_client.NSXManagerCLIClient):

    def __init__(self, parent=None, id_=None):
        super(AAACLIClient, self).__init__(parent=parent)
        self.id_ = id_
