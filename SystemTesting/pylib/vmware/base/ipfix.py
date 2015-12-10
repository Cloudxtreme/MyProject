import vmware.base.base as base


class Ipfix(base.Base):

    display_name = None
    description = None

    def __init__(self, parent=None, id_=None):
        super(Ipfix, self).__init__()
        self.parent = parent
        self.id_ = id_
