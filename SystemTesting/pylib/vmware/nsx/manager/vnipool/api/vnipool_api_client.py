import vmware.base.pool as pool
import vmware.nsx.manager.manager_client as manager_client


class VNIPoolAPIClient(pool.Pool,
                       manager_client.NSXManagerAPIClient):
    def __init__(self, parent=None, id_=None):
        super(VNIPoolAPIClient, self).__init__(parent=parent)
        self.id_ = id_
