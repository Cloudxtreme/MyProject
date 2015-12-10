import vmware.base.adapter as adapter


class VTEP(adapter.Adapter):
    DEFAULT_IMPLEMENTATION_VERSION = 'NSX70'

    def __init__(self, parent=None, id_=None):
        super(VTEP, self).__init__(parent=parent)
        self.id_ = id_

    def get_impl_version(self, execution_type=None, interface=None):
        return self.DEFAULT_IMPLEMENTATION_VERSION
