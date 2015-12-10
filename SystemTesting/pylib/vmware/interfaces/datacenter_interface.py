class DatacenterInterface(object):

    @classmethod
    def create_datacenter(cls, client_object, **kwargs):
        """Interface to create a datacenter."""
        raise NotImplementedError

    @classmethod
    def remove_datacenter(cls, client_object, **kwargs):
        """Interface to remove a datacenter."""
        raise NotImplementedError

    @classmethod
    def check_datacenter_exists(cls, client_object, name=None, **kwargs):
        """Interface to check if datacenter exists."""
        raise NotImplementedError
