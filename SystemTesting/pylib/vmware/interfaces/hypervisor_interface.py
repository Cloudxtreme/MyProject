class HypervisorInterface(object):
    """Interface for hypervisor related operations."""

    @classmethod
    def update_pci_passthru(cls, client_object, config=None, **kwargs):
        """Interface to update host pci passthrough config."""
        raise NotImplementedError

    @classmethod
    def disconnect_host(cls, client_object, **kwargs):
        """Interface to disconnect host."""
        raise NotImplementedError

    @classmethod
    def get_host_uuid(cls, client_object, **kwargs):
        """Interface to get host uuid using nsxcli"""
        raise NotImplementedError
