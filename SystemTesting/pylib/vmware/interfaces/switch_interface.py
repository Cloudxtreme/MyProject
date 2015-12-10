class SwitchInterface(object):

    @classmethod
    def configure_uplinks(cls, client_object, uplinks=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_ports(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_arp_table(cls, client_object, **kwargs):
        """Interface to get arp table data from CLI"""
        raise NotImplementedError

    @classmethod
    def get_mac_table(cls, client_object, **kwargs):
        """Interface to get mac table data from CLI"""
        raise NotImplementedError

    @classmethod
    def get_vtep_table(cls, client_object, switch_vni=None,
                       host_switch_name=None, **kwargs):
        """Interface to get vtep table data from CLI"""
        raise NotImplementedError

    @classmethod
    def get_vni_table(cls, client_object, switch_vni=None, **kwargs):
        """Interface to get vni table data from CLI"""
        raise NotImplementedError

    @classmethod
    def get_stats_table(cls, client_object, switch_vni=None, **kwargs):
        """Interface to get stats table data from CLI"""
        raise NotImplementedError

    @classmethod
    def is_master_for_vni(cls, client_object, switch_vni=None, **kwargs):
        """Interface to determine if a controller is responsbile for a VNI."""
        raise NotImplementedError

    @classmethod
    def list_portgroup(cls, client_object, **kwargs):
        """Lists the port groups on the client."""
        raise NotImplementedError

    @classmethod
    def get_logical_switch(cls, client_object, **kwargs):
        """Fetches information about logical switches."""
        raise NotImplementedError

    @classmethod
    def remove_component(cls, client_object, **kwargs):
        """Removes the specified component from the switch."""
        raise NotImplementedError

    @classmethod
    def set_mtu(cls, client_object, **kwargs):
        """Sets the max mtu on the switch."""
        pass

    @classmethod
    def configure_mirror_session(cls, client_object, **kwargs):
        """Create a mirror session on the switch."""
        pass

    @classmethod
    def configure_discovery_protocol(cls, client_object, **kwargs):
        """Configures Link Discovery Protocol on the switch."""
        pass

    @classmethod
    def get_discovery_protocol(cls, client_object, **kwargs):
        """Returns the Link Discovery Protocol on the switch."""
        pass

    @classmethod
    def configure_ipfix(cls, client_object, **kwargs):
        """Configures ipfix monitoring of switch traffic."""
        pass

    @classmethod
    def add_pvlan_map(cls, client_object, **kwargs):
        """Adds pvlan map for the switch."""
        pass

    @classmethod
    def enable_network_resource_mgmt(cls, client_object, **kwargs):
        """Enables network I/O control on the switch."""
        pass

    @classmethod
    def edit_max_proxy_switchports(cls, client_object,
                                   maxports=None, **kwargs):
        """Edits the max ports allowed in the host proxy switch."""
        pass

    @classmethod
    def set_nic_teaming(cls, client_object, **kwargs):
        """Configures nic teaming policy on the switch."""
        pass

    @classmethod
    def bind_pnic(cls, client_object, **kwargs):
        """Binds the physical nic to the switch."""
        pass

    @classmethod
    def remove_host(cls, client_object, **kwargs):
        """Removes host from the switch."""
        pass

    @classmethod
    def remove_hosts(cls, client_object, **kwargs):
        """Removes the specified hosts from the switch."""
        pass

    @classmethod
    def remove_vspan_session(cls, client_object, session_id=None, **kwargs):
        """Removes the vspan session from the switch."""
        pass

    @classmethod
    def list_mirror_sessions(cls, client_object, **kwargs):
        """Lists the names of the mirror sessions on the switch."""
        pass

    @classmethod
    def read(cls, client_object, **kwargs):
        """Returns the switch schema object."""
        pass

    @classmethod
    def remove_uplink(cls, client_object, uplink=None, **kwargs):
        """Removes the uplink from the switch."""
        pass

    @classmethod
    def check_DVS_exists(cls, client_object, name=None, **kwargs):
        """Checks if the DVS exists in the given datacenter"""
        pass

    @classmethod
    def set_switch_mtu(cls, client_object, value=None, vmnic_name=None,
                       **kwargs):
        """Configures mtu on the switch."""
        pass

    @classmethod
    def get_switch_mtu(cls, client_object, vmnic_name=None, **kwargs):
        """Get mtu on the switch."""
        pass

    @classmethod
    def get_switch_ports(cls, client_object, **kwargs):
        """Get ports on the switch."""
        pass

    @classmethod
    def read_switch_ccp_mapping(cls, client_obj, endpoints=None,
                                switch_vni=None):
        raise NotImplementedError

    @classmethod
    def get_logical_switches(cls, client_obj, switches=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_entry_count(cls, client_obj, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_full_sync_count(cls, client_obj, **kwargs):
        raise NotImplementedError
