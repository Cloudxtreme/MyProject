class SnmpInterface(object):
    """Interface for SNMP fetch MIBs operations."""

    @classmethod
    def get_system_mib(cls, client_object, manager_ip=None, **kwargs):
        """Interface to fetch snmp system MIBS from NSX MP node."""
        raise NotImplementedError

    @classmethod
    def get_hostresources_mib(cls, client_object, manager_ip=None, **kwargs):
        """Interface to fetch snmp host resources MIBS from NSX MP node."""
        raise NotImplementedError

    @classmethod
    def get_interfaces_mib(cls, client_object, manager_ip=None, **kwargs):
        """Interface to fetch snmp interfaces MIBS from NSX MP node."""
        raise NotImplementedError
