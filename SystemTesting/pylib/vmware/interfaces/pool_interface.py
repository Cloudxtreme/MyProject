class PoolInterface(object):
    """Interface for pool operations."""

    @classmethod
    def configure_network_resource_pool(cls, client_object, **kwargs):
        """Interface to configure network resource pool."""
        raise NotImplementedError
