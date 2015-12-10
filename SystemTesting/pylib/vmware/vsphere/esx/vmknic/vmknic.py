import vmware.base.adapter as adapter
import vmware.common.base_facade as base_facade
import vmware.interfaces.labels as labels

auto_resolve = base_facade.auto_resolve


class Vmknic(adapter.Adapter):

    def get_impl_version(self, execution_type=None, interface=None):
        return "ESX55"

    @auto_resolve(labels.ADAPTER)
    def get_external_id(self, execution_type=None, **kwargs):
        pass
