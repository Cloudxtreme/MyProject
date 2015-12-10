import vmware.base.adapter as adapter


class Vmnic(adapter.Adapter):

    def get_impl_version(self, execution_type=None, interface=None):
        return "ESX55"

    def get_name(self):
        return self.name
