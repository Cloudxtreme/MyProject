import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.interfaces.labels as labels

auto_resolve = base_facade.auto_resolve


class Algorithm(base.Base):

    display_name = None
    description = None

    def __init__(self, parent=None):
        super(Algorithm, self).__init__()
        self.parent = parent

    @auto_resolve(labels.CRUD)
    def get_key_sizes(self, execution_type=None, **kwargs):
        pass
