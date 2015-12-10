import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.interfaces.labels as labels

auto_resolve = base_facade.auto_resolve


class Pool(base.Base):

    """
    This is base class for all components of Pool type.
    e.g. IPPool, VNIPool
    """

    display_name = None
    description = None

    def __init__(self, parent=None):
        super(Pool, self).__init__()
        self.parent = parent

    @auto_resolve(labels.POOL)
    def configure_network_resource_pool(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def delete(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def read(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def get_allocations(self, execution_type=None, schema=None, **kwargs):
        pass

    def get_id_(self, execution_type=None, **kwargs):
        return self.id_