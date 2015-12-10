import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.interfaces.labels as labels

auto_resolve = base_facade.auto_resolve


class Adapter(base.Base):

    def __init__(self, name=None, parent=None):
        super(Adapter, self).__init__()
        self.name = name
        self.parent = parent

    @auto_resolve(labels.CRUD)
    def update(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def get_id(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def get_adapter_info(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER)
    def get_adapter_ip(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER)
    def get_adapter_mac(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER)
    def set_adapter_mtu(self, execution_type=None, mtu=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER)
    def get_adapter_mtu(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER)
    def get_adapter_interface(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER)
    def enable_vmotion(self, execution_type=None, enable=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER)
    def set_device_status(self, execution_type=None, status=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER)
    def get_device_status(self, execution_type=None, status=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER)
    def get_adapter_netstack(self, execution_type=None, status=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER)
    def get_port(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER)
    def get_dvport(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER)
    def get_team_pnic(self, execution_type=None,
                      get_team_pnic=None, **kwargs):
        pass

    @auto_resolve(labels.ADAPTER)
    def set_cap_vlan_tx(self, execution_type=None, enable=None, **kwargs):
        pass
