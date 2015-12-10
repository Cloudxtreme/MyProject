import vmware.base.base as base


class NSXBase(base.Base):
    parent = None
    id_ = None

    def __init__(self, parent=None, id_=None):
        super(NSXBase, self).__init__()
        if parent is not None:
            self.parent = parent
        if id_ is not None:
            self.id_ = id_

    @property
    def nsx_manager_obj(self):
        return self.parent

    def get_id(self):
        return self.id_
