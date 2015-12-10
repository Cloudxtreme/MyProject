import vmware.base.base as base
import vmware.common.base_facade as base_facade

auto_resolve = base_facade.auto_resolve


class Group(base.Base):

    """
    This is base class for all components of Grouping Object type.
    e.g. IP Sets, MAC Sets, NS Groups, NS Services
    """

    display_name = None
    description = None

    def __init__(self, parent=None, id_=None):
        super(Group, self).__init__()
        self.parent = parent
