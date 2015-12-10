import vmware.base.adapter as adapter
import vmware.common.base_facade as base_facade
import vmware.common.versions as versions
import vmware.interfaces.labels as labels

auto_resolve = base_facade.auto_resolve


class VTEP(adapter.Adapter):
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE

    def get_impl_version(self, execution_type=None, interface=None):
        return self.DEFAULT_IMPLEMENTATION_VERSION

    def get_device_name(self):
        return self.name

    def get_adapter_name(self):
        return self.name

    @auto_resolve(labels.ADAPTER)
    def get_adaper_ip(self, execution_type=None):
        pass

    @auto_resolve(labels.ADAPTER)
    def get_ip_address(self, execution_type=None):
        pass

    @auto_resolve(labels.ADAPTER)
    def get_adaper_mac(self, execution_type=None):
        pass

    @auto_resolve(labels.ADAPTER)
    def set_adapter_mtu(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER)
    def renew_dhcp(self, execution_type=None, **kwargs):
        pass
