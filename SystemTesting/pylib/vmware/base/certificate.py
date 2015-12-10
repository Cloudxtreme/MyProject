import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.interfaces.labels as labels

auto_resolve = base_facade.auto_resolve


class Certificate(base.Base):

    def __init__(self, parent=None):
        super(Certificate, self).__init__()
        self.parent = parent

    @auto_resolve(labels.CRUD)
    def download(self, execution_type=None, **kwargs):
        pass

    def get_id(self, execution_type=None, **kwargs):
        return self.id_