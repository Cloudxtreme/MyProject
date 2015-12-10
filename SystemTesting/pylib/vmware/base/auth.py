import vmware.base.base as base


class Auth(base.Base):

    display_name = None
    description = None

    def __init__(self, parent=None):
        super(Auth, self).__init__()
        self.parent = parent
