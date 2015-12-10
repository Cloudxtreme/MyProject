import vmware.base.base as base


class Key(base.Base):

    display_name = None
    description = None

    def __init__(self, parent=None):
        super(Key, self).__init__()
        self.parent = parent
