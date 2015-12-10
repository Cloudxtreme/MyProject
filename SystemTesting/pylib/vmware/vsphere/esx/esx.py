import vmware.base.hypervisor as hypervisor


class ESX(hypervisor.Hypervisor):
    DEFAULT_IMPLEMENTATION_VERSION = 'ESX55'

    def get_ip_addresses(self):
        # TODO(gjayavelu): returning tuple isn't working
        # where it gets converted into string at workloads.
        # Using list for now.
        return [self.ip]

    def get_account_name(self):
        # TODO(gjayavelu): Find what is the right account name
        # on ESX. For now, using ip address
        return 'esx-%s' % self.ip.replace('.', '-')

    def get_impl_version(self, execution_type=None, interface=None):
        return self.DEFAULT_IMPLEMENTATION_VERSION

    def get_mgmt_ip(self):
        return self.ip