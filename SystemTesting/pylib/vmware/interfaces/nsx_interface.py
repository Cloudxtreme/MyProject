"""Interface class to implement NSX related operations"""


class NSXInterface(object):

    @classmethod
    def get_tunnel_ports_remote_ip(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_ipfix_config(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def set_log_level(cls, client_object, **kwargs):
        raise NotImplementedError
