import vmware.base.inventory as inventory


class FabricVif(inventory.Inventory):

    def __init__(self, parent=None):
        super(FabricVif, self).__init__()
        self.parent = parent

    def get_id(self):
        return self.id_