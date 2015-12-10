import vmware.base.base as base


class Service(base.Base):

    display_name = None
    description = None

    def __init__(self, parent=None):
        super(Service, self).__init__()
        self.parent = parent
