import vmware.base.gateway as gateway


class EdgeNode(gateway.Gateway):

    def __init__(self, parent=None):
        super(EdgeNode, self).__init__()
        self.parent = parent
        self.id_ = None

    def get_edge_node_id(self):
        return self.id_

    def get_id_(self):
        return self.id_
