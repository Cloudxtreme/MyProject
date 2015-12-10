import vmware.base.network as network


class Portgroup(network.Network):

    def get_impl_version(self, execution_type=None, interface=None):
        return "ESX55"
