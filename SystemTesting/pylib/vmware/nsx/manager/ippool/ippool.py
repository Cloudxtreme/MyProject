import vmware.base.pool as pool


class IPPool(pool.Pool):

    def __init__(self, parent=None):
        super(IPPool, self).__init__()
        self.parent = parent

    def get_ippool_id(self):
        return self.id_