import vmware.base.pool as pool


class ResourcePool(pool.Pool):

    def __init__(self, name=None, parent=None):
        super(ResourcePool, self).__init__(parent=parent)
