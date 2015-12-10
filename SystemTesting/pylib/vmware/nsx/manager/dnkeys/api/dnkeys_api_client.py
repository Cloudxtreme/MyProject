import vmware.base.key as key
import vmware.nsx.manager.manager_client as manager_client


class DNKeysAPIClient(key.Key, manager_client.NSXManagerAPIClient):

    def __init__(self, parent=None, id_=None):
        super(DNKeysAPIClient, self).__init__(parent=parent)
        self.id_ = id_
