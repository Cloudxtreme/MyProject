class NodeInterface(object):

    @classmethod
    def get_cluster_node(cls, client_object, **kwargs):
        """Interface to get CCP cluster node info from CLI"""
        raise NotImplementedError

    @classmethod
    def get_controller_vif(self, execution_type=None, **kwargs):
        """Interface to get vif data from CLI"""
        raise NotImplementedError
