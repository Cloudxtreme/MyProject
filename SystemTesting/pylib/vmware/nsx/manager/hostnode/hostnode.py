import vmware.base.hypervisor as hypervisor


class HostNode(hypervisor.Hypervisor):

    def __init__(self, parent=None, id_=None):
        super(HostNode, self).__init__(parent)
        if parent is not None:
            self.parent = parent
        if id_ is not None:
            self.id_ = id_

    def get_node_id(self):
        return self.id_

    def get_id(self):
        return self.id_
