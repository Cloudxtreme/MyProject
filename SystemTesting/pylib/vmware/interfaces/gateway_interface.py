"""Interface class to implement gateway operations associated with a client"""


class GatewayInterface(object):
    @classmethod
    def get_edge_node_id(cls, client_object, **kwargs):
        raise NotImplementedError