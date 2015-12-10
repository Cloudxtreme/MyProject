import vmware.base.inventory as inventory
import vmware.nsx.manager.manager_client as manager_client


class FabricVmAPIClient(inventory.Inventory,
                        manager_client.NSXManagerAPIClient):

        def __init__(self, parent=None, id_=None):
            super(FabricVmAPIClient, self).__init__(parent=parent)
            self.id_ = id_
