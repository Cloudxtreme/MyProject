import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.interfaces.labels as labels

auto_resolve = base_facade.auto_resolve


class Port(base.Base):

    def __init__(self, name=None, parent=None):
        super(Port, self).__init__()
        self.name = name
        self.parent = parent

    @auto_resolve(labels.PORT)
    def get_status(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.PORT)
    def get_number(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.PORT)
    def get_attachment(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.PORT)
    def block(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.PORT)
    def get_arp_table(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.AGGREGATION)
    def get_statistics_summary(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.AGGREGATION)
    def get_statistics(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def create(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def update(self, execution_type=None, **kwargs):
        pass

    def get_id(self, execution_type=None, **kwargs):
        return self.id_

    def get_id_(self, execution_type=None, **kwargs):
        return self.get_id(execution_type=execution_type, **kwargs)
