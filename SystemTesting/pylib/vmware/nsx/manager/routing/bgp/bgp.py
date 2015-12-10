import vmware.nsx.manager.nsxbase as nsxbase


class BGP(nsxbase.NSXBase):
    def __init__(self, parent=None, id_=None):
        super(BGP, self).__init__(parent=parent, id_=id_)
