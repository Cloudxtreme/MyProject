import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.interfaces.labels as labels

auto_resolve = base_facade.auto_resolve


class VC(base.Base):

    def __init__(self, ip=None, username=None, password=None, parent=None):
        super(VC, self).__init__()
        self.ip = ip
        self.username = username
        self.password = password
        self.parent = parent

    def get_impl_version(self, execution_type=None, interface=None):
                return "VC55"

    @auto_resolve(labels.DATACENTER)
    def check_datacenter_exists(self, execution_type=None,
                                name=None, **kwargs):
        """Checks if the datacenter exists on the VC"""
        pass

    @auto_resolve(labels.SWITCH)
    def check_DVS_exists(self, execution_type=None,
                         name=None, datacenter=None, **kwargs):
        """Checks if thre DVS exists in the datacenter"""
        pass

    @auto_resolve(labels.CRUD)
    def read(self, execution_type=None):
        """Reads the VC information"""
        pass
