import vmware.base.base as base


class Inventory(base.Base):

    #
    #This is base class for all components Inventory Type.
    #e.g. virtualmachine, vif
    #
    display_name = None
    description = None

    def __init__(self, parent=None):
        super(Inventory, self).__init__()
        self.parent = parent
