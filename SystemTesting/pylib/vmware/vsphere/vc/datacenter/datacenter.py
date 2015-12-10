import vmware.base.datacenter as datacenter


class Datacenter(datacenter.Datacenter):
    pass

    def get_impl_version(self, execution_type=None, interface=None):
                return "VC55"
