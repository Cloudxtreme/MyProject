import vmware.base.inventory as inventory
import vmware.nsx.manager.manager_client as manager_client


class HostNodeAPIClient(inventory.Inventory,
                        manager_client.NSXManagerAPIClient):

    def __init__(self, parent=None, id_=None):
        super(HostNodeAPIClient, self).__init__(parent=parent)
        self.id_ = id_
