class ClusterInterface(object):
    """Interface for edge_cluster status information."""

    @classmethod
    def get_cluster_status(cls, client_object, **kwargs):
        """Interface to show the edge cluster status"""
        raise NotImplementedError

    @classmethod
    def get_member_index(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def wait_for_required_cluster_status(cls, client_obj, **kwargs):
        raise NotImplementedError

    @classmethod
    def get_cluster_history_resource(cls, client_object, **kwargs):
        """Interface to show the edge cluster history resource"""
        raise NotImplementedError

    @classmethod
    def get_cluster_history_state(cls, client_object, **kwargs):
        """Interface to show the edge cluster history state"""
        raise NotImplementedError

    @classmethod
    def revoke_cluster_node(cls, client_object, **kwargs):
        raise NotImplementedError
