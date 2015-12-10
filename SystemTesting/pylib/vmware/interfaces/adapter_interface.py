class AdapterInterface(object):
    """Interface for adapter related operations."""

    @classmethod
    def list_vnic(cls, client_object, **kwargs):
        """Interface to list endpoint's vnics."""
        raise NotImplementedError

    @classmethod
    def list_pnic(cls, client_object, **kwargs):
        """Interface to list endpoint's pnics."""
        raise NotImplementedError

    @classmethod
    def remove_vnic(cls, client_object, name=None, **kwargs):
        """Interface to remove endpoint's vnic."""
        raise NotImplementedError

    @classmethod
    def update_vmk(cls, client_object, device=None, **kwargs):
        """Interface to update vmknic."""
        raise NotImplementedError

    @classmethod
    def add_virtual_interface(cls, client_object, **kwargs):
        """Adds a virtual interface."""
        raise NotImplementedError

    @classmethod
    def enable_vmotion(cls, client_object, enable=None, **kwargs):
        """Enables or disables vmotion"""
        raise NotImplementedError

    @classmethod
    def get_adapter_ip(cls, client_object, **kwargs):
        """Gets the IP of the adapter"""
        raise NotImplementedError

    @classmethod
    def set_adapter_ip(cls, client_object, adapter_ip=None, **kwargs):
        """Sets the IP of the adapter"""
        raise NotImplementedError

    @classmethod
    def set_network_info(cls, client_object, adapter_ip=None,
                         netmask=None, **kwargs):
        """Sets the network info of the adapter"""
        raise NotImplementedError

    @classmethod
    def discover_adapter(cls, client_object, **kwargs):
        """Discovers adapter by name"""
        raise NotImplementedError

    @classmethod
    def reset_adapter_ip(cls, client_object, **kwargs):
        """Resets the IP on the adapter"""
        raise NotImplementedError

    @classmethod
    def get_adapter_mac(cls, client_object, **kwargs):
        """Gets the MAC of the adapter"""
        raise NotImplementedError

    @classmethod
    def set_adapter_mtu(cls, client_object, mtu=None, **kwargs):
        """Sets the MTU of the adapter"""
        raise NotImplementedError

    @classmethod
    def get_adapter_mtu(cls, client_object, **kwargs):
        """Gets the MTU of the adapter"""
        raise NotImplementedError

    @classmethod
    def get_adapter_interface(cls, client_object, **kwargs):
        """Gets the interface name of the adapter"""

    @classmethod
    def get_device_name(cls, client_object, **kwargs):
        """Gets the adapter's name"""
        raise NotImplementedError

    @classmethod
    def delete_all_test_adapters(cls, client_object):
        """Deletes all test adapters"""
        raise NotImplementedError

    @classmethod
    def set_device_status(cls, client_object, status=None, **kwargs):
        """ set the device status for the adapter"""
        raise NotImplementedError

    @classmethod
    def get_device_status(cls, client_object, **kwargs):
        """ get the current adapter status"""
        pass

    @classmethod
    def show_interface(cls, client_object, **kwargs):
        """
        Interface to get the interface details from Edge VM
        """
        raise NotImplementedError

    @classmethod
    def get_adapter_netstack(cls, client_object, **kwargs):
        """
        Gets the netstack of the adapter.
        """
        raise NotImplementedError

    @classmethod
    def get_port(cls, client_object, **kwargs):
        """
        Gets the port of the adapter.
        """
        raise NotImplementedError

    @classmethod
    def get_dvport(cls, client_object, **kwargs):
        """
        Gets the dvport of the adapter.
        """
        raise NotImplementedError

    @classmethod
    def get_team_pnic(cls, client_object, execution_type=None,
                      get_team_pnic=None, **kwargs):
        """
        Interface to get the active pnic for vtep
        """
        raise NotImplementedError

    @classmethod
    def set_cap_vlan_tx(cls, client_object, execution_type=None, enable=None,
                        **kwargs):
        """
        Set the CAP_VLAN_TX hwCapabilities setting.
        """
        raise NotImplementedError

    @classmethod
    def get_assigned_interface_ip(cls, client_object, **kwargs):
        """
        Interface to get the interface details from Edge VM
        """
        raise NotImplementedError

    @classmethod
    def get_single_adapter_info(cls, client_object, adapter_ip=None,
                                adapter_name=None, **kwargs):
        """
        Discovers an adapter based on adapter's name or IP
        """
        raise NotImplementedError

    @classmethod
    def get_edge_interface_ip(cls, client_object, **kwargs):
        """
        Interface to get the interface details from Edge VM
        """
        raise NotImplementedError

    @classmethod
    def get_pnics(cls, client_object, **kwargs):
        """
        Returns the list of pnics on the client
        """
        raise NotImplementedError

    @classmethod
    def get_vtep_detail(cls, client_object, **kwargs):
        """Returns vxlan vtep detail list on hypervisor."""
        raise NotImplementedError

    @classmethod
    def renew_dhcp(cls, client_object, **kwargs):
        """
        Refresh vtep route through dhcp
        """
        raise NotImplementedError
