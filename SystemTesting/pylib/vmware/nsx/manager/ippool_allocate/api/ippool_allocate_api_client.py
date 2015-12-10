import vmware.base.pool as pool
import vmware.nsx.manager.manager_client as manager_client


class IPPoolAllocateAPIClient(pool.Pool, manager_client.NSXManagerAPIClient):

    def __init__(self, parent=None, id_=None):
        super(IPPoolAllocateAPIClient, self).__init__(parent=parent)
        self.id_ = id_
