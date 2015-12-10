import vmware.interfaces.adapter_interface as adapter_interface


class ESX55AdapterImpl(adapter_interface.AdapterInterface):
    """Adapter related operations."""

    @classmethod
    def get_adapter_ip(cls, client_object):
        """
        Returns the IP address of the adapter.
        """
        return client_object.adapter_ip

    @classmethod
    def get_adapter_mac(cls, client_object):
        """
        Returns the MAC address of the adapter.
        """
        return client_object.adapter_mac

    @classmethod
    def get_adapter_interface(cls, client_object):
        """
        Returns the interface name of the adapter.
        """
        return client_object.adapter_interface