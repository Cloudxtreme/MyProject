import vmware.interfaces.aggregation_interface as aggregation_interface
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.manager.aggsvclogicalrouterport.\
    getlogicalrouterportstatisticssummary as \
    getlogicalrouterportstatisticssummary
import vmware.nsx_api.manager.aggsvclogicalrouterport.\
    getlogicalrouterportstatistics as getlogicalrouterportstatistics
import vmware.nsx_api.manager.logicalrouterports.logicalrouterport as logicalrouterport  # noqa
import vmware.nsx_api.manager.common.logicalrouterdownlinkport_schema as logicalrouterdownlinkport_schema  # noqa


class NSX70AggregationImpl(aggregation_interface.AggregationInterface,
                           base_crud_impl.BaseCRUDImpl):

    _attribute_map = {}
    _client_class = logicalrouterport.LogicalRouterPort
    _schema_class = logicalrouterdownlinkport_schema.\
        LogicalRouterDownLinkPortSchema

    @classmethod
    def get_sdk_client_object(cls, client_object, client_class=None, **kwargs):
        return client_class(connection_object=client_object.connection,
                            logicalrouterport_id=client_object.id_)

    @classmethod
    def get_statistics_summary(cls, client_object,
                               get_statistics_summary=None):
        """
        Interface to get rx/tx statistics summary from a logical router port.

        @type client_object: LogicalRouterPortAPIClient
        @param client_object: Client object
        @type get_statistics_summary: List
        @param get_statistics_summary: A list of dicts. It is not used.
        @rtype: Dict
        @return: Dict having rx and tx statistics summary

        Endpoint:
        /logical-router-ports/<logical-router-port-id>/statistics/summary
        """
        client_class = getlogicalrouterportstatisticssummary.GetLogicalRouterPortStatisticsSummary  # noqa
        return super(NSX70AggregationImpl, cls).read(client_object,
                                                     client_class=client_class)

    @classmethod
    def get_statistics(cls, client_object, node_id=None,
                       get_statistics=None):
        """
        Interface to get rx/tx statistics of a transport node from a logical
        router port.

        @type client_object: LogicalRouterPortAPIClient
        @param client_object: Client object
        @type node_id: String
        @param node_id: Transport node id
        @type get_statistics: List
        @param get_statistics: A list of dicts. It is not used.
        @rtype: Dict
        @return: Dict having rx and tx statistics

        Endpoint:
        /logical-router-ports/<logical-router-port-id>/statistics
        """
        url_parameters = {'transport_node_id': node_id}
        client_class = getlogicalrouterportstatistics.GetLogicalRouterPortStatistics  # noqa
        return super(NSX70AggregationImpl, cls).read(client_object,
                                                     client_class=client_class,
                                                     query_params=url_parameters)  # noqa
