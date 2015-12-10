import vmware.base.base as base
import vmware.common.base_facade as base_facade
import vmware.interfaces.labels as labels

auto_resolve = base_facade.auto_resolve


class Switch(base.Base):

    def __init__(self, parent=None, name=None):
        super(Switch, self).__init__()
        self.parent = parent
        self.name = name

    @auto_resolve(labels.SWITCH)
    def configure_uplinks(self, execution_type=None, operation=None,
                          uplinks=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def get_arp_table(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def get_mac_table(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def get_connection_table(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def get_stats_table(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def get_ports(self, execution_type=None, **kwargs):
        pass

    def get_switch_id(self):
        return self.id_

    @auto_resolve(labels.CRUD)
    def delete(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.NETWORK)
    def check_network_exists(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def remove_component(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def set_mtu(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def configure_mirror_session(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.NETWORK)
    def list_networks(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def configure_discovery_protocol(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def get_discovery_protocol(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def configure_ipfix(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def add_pvlan_map(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def enable_network_resource_mgmt(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def edit_max_proxy_switchports(self, execution_type=None,
                                   maxports=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def set_nic_teaming(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def bind_pnic(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def remove_host(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def remove_hosts(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def remove_vspan_session(self, execution_type=None,
                             session_id=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def list_mirror_sessions(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.CRUD)
    def read(self, execution_type=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def remove_uplink(self, execution_type=None, uplink=None, **kwargs):
        pass

    @auto_resolve(labels.SWITCH)
    def read_switch_ccp_mapping(self, execution_type=None, endpoints=None,
                                switch_vni=None):
        pass

    @auto_resolve(labels.CRUD)
    def wait_for_realized_state(self, execution_type=None, id_=None, **kwargs):
        pass
