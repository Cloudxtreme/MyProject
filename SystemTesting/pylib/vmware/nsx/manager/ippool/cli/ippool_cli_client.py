import vmware.base.pool as pool
import vmware.nsx.manager.manager_client as manager_client


class IPPoolCLIClient(pool.Pool, manager_client.NSXManagerAPIClient):

    """
    Please don't copy paste, we have to create separate classes for each client.
    """

    def __init__(self, parent=None, id_=None):
        super(IPPoolCLIClient, self).__init__(parent=parent)
        self.id_ = id_
