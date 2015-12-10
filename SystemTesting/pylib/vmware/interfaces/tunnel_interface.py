class TunnelInterface(object):

    @classmethod
    def get_tunnels(cls, client_obj, **kwargs):
        """
        Get the tunnels from a component.
        """
        raise NotImplementedError
