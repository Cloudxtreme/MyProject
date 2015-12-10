import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.interfaces.labels as labels

auto_resolve = base_facade.auto_resolve


class Firewall(base.Base):

    display_name = None
    description = None

    def __init__(self, parent=None, id_=None):
        super(Firewall, self).__init__()
        self.parent = parent

    @auto_resolve(labels.CRUD)
    def create_section_with_rules(self, execution_type=None, schema=None,
                                  **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def update_section_with_rules(self, execution_type=None, schema=None,
                                  **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def get_section_with_rules(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def revise_rules(self, execution_type=None, schema=None,
                     **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def revise_section(self, execution_type=None, schema=None,
                       **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def revise_section_with_rules(self, execution_type=None, schema=None,
                                  **kwargs):
        pass
