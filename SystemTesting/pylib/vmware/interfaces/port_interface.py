"""Interface class to implement port operations associated with a client"""


class PortInterface(object):

    @classmethod
    def get_status(cls, client_object, port=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_number(cls, client_object, port=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_attachment(cls, client_object, port=None, **kwargs):
        raise NotImplementedError

    def block(cls, client, port, **kwargs):
        """Interface to block a port."""
        raise NotImplementedError

    @classmethod
    def get_port_id(cls, client_object, **kwargs):
        """Interface to returns port id."""
        raise NotImplementedError

    @classmethod
    def get_port_qos_info(cls, client_object, **kwargs):
        """
        Interface to get configuration from a host for a port's traffic
        shaping and marking configuration.
        """
        raise NotImplementedError

    @classmethod
    def get_port_teaming_info(cls, client_object, **kwargs):
        """
        Interface to get configuration from a host for a port's
        teaming configuration.
        """
        raise NotImplementedError

    @classmethod
    def get_arp_table(cls, client_object, **kwargs):
        """
        Interface to get arp table from a port.
        """
        raise NotImplementedError
