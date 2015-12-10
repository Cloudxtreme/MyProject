import vmware.base.pool as pool


class IPPoolAllocate(pool.Pool):

    def __init__(self, parent=None):
        super(IPPoolAllocate, self).__init__()
        self.parent = parent

    def get_id_(self):
        return self.id_