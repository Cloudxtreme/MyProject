class NetworkInterface(object):
    """Interface to implement network related operations."""

    @classmethod
    def list_networks(cls, client_object, **kwargs):
        """Lists the networks on the client."""
        raise NotImplementedError

    @classmethod
    def check_network_exists(cls, client_object, **kwargs):
        """Checks if the network exists."""
        raise NotImplementedError

    @classmethod
    def edit_traffic_shaping(cls, client_object, **kwargs):
        """Edits the traffic shaping policies on the network."""
        raise NotImplementedError

    @classmethod
    def edit_security_policy(cls, client_object, **kwargs):
        """Edits the security policies  of the network."""
        raise NotImplementedError

    @classmethod
    def set_access_vlan(cls, client_object, vlan=None, **kwargs):
        """Sets the access vlan on the network."""
        raise NotImplementedError

    @classmethod
    def set_vlan_trunking(cls, client_object, **kwargs):
        """Sets vlan trunking on the network."""
        raise NotImplementedError

    @classmethod
    def migrate_network(cls, client_object,
                        hostname=None, **kwargs):
        """Migrates the network."""
        raise NotImplementedError

    @classmethod
    def get_dvpg_id_from_name(cls, client_object,
                              dvs=None, dvpg=None, **kwargs):
        """Returns dvpg ID(key) for dvpg on the given dvs"""
        raise NotImplementedError
