class AggregationInterface(object):

    @classmethod
    def get_aggregation_status(cls, client_obj, **kwargs):
        """
        Get status for a given component as reported by aggregation service.
        """
        raise NotImplementedError

    @classmethod
    def get_aggregation_transportnode_status_report(cls, client_obj, **kwargs):
        """
        Returns the summary of all transport nodes under MP in a csv file.
        """
        raise NotImplementedError

    @classmethod
    def get_aggregation_transportnode_status(cls, client_obj, **kwargs):
        """
        Get status summary of all transport nodes under MP.
        """
        raise NotImplementedError

    @classmethod
    def get_aggregation_remote_status(cls, client_obj, **kwargs):
        """
        Get status summary of all remote components of the given component, as
        reported by the aggregation service.
        """
        raise NotImplementedError

    @classmethod
    def get_statistics_summary(cls, client_object, **kwargs):
        """
        Get rx/tx statistics summary for a given component as reported by
        aggregation service.
        """
        raise NotImplementedError

    @classmethod
    def get_statistics(cls, client_object, **kwargs):
        """
        Get rx/tx statistics for a given component as reported by aggregation
        service.
        """
        raise NotImplementedError

    @classmethod
    def get_node_status(cls, client_object, **kwargs):
        """
        Get the status for a cluster/fabric node as reported by aggregation
        service.
        """
        raise NotImplementedError

    @classmethod
    def get_node_interfaces(cls, client_object, **kwargs):
        """
        Get the information of cluster/fabric node interfaces as reported by
        aggregation service.
        """
        raise NotImplementedError
