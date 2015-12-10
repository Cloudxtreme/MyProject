import vmware.base.inventory as inventory
import vmware.nsx.manager.nsxbase as nsxbase


class FabricVm(nsxbase.NSXBase, inventory.Inventory):

    def get_id(self):
        return self.id_