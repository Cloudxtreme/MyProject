import vmware.base.gateway as gateway


class Edge(gateway.Gateway):

    DEFAULT_IMPLEMENTATION_VERSION = "Edge70"

    def get_impl_version(self, execution_type=None, interface=None):
        return self.DEFAULT_IMPLEMENTATION_VERSION

    def get_management_ip(self):
        return self.ip

    def get_ip_addresses(self):
        return [self.ip]
