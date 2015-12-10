import vmware.common.global_config as global_config
import vmware.interfaces.router_interface as router_interface
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.manager.aggsvclogicalrouter.\
    getlogicalrouternatrulestatistics as getlogicalrouternatrulestatistics
import vmware.nsx_api.manager.aggsvclogicalrouter.\
    getlogicalrouterroutetable as getlogicalrouterroutetable
import vmware.nsx_api.manager.aggsvclogicalrouter.\
    getlogicalrouterstatus as getlogicalrouterstatus
import vmware.nsx_api.manager.logicalrouter.logicalrouter as logicalrouter
import vmware.nsx_api.manager.logicalrouter.schema.logicalrouter_schema \
    as logicalrouter_schema


pylogger = global_config.pylogger


class NSX70RouterImpl(router_interface.RouterInterface,
                      base_crud_impl.BaseCRUDImpl):

    _attribute_map = {}
    _client_class = logicalrouter.LogicalRouter
    _schema_class = logicalrouter_schema.LogicalRouterSchema

    @classmethod
    def get_sdk_client_object(cls, client_object, client_class=None, **kwargs):
        return client_class(connection_object=client_object.connection,
                            logicalrouter_id=client_object.id_)

    @classmethod
    def get_logical_router_id(cls, client_object):
        return client_object.id_

    @classmethod
    def get_nat_rules_statistics(cls, client_object, rule_id=None,
                                 get_nat_rules_statistics=None):
        """
        Returns the summation of statistics from all nodes for the Specified
        Logical Router NAT Rule.

        @type client_object: LogicalRouterAPIClient
        @param client_object: Client object
        @type rule_id: string
        @param rule_id: NAT Rule id
        @type get_nat_rules_statistics: List
        @param get_nat_rules_statistics: A list of dicts. It is not used.
        @rtype: dict
        @return: Dict having active sessions, logical router id, rule id,
         rule invoked times, total bytes and total packets.
        Endpoint:
        /logical-routers/<logical-router-id>/nat-rules/statistics
        """
        url_parameters = {'rule_id': rule_id}
        client_class = getlogicalrouternatrulestatistics.GetLogicalRouterNatRuleStatistics  # noqa
        return super(NSX70RouterImpl, cls).read(client_object,
                                                client_class=client_class,
                                                query_params=url_parameters)

    @classmethod
    def get_route_table(cls, client_object, node_id=None,
                        get_route_table=None):
        """
        Returns the route table for the logical router on a node of the given
        transport node id

        @type client_object: LogicalRouterAPIClient
        @param client_object: Client object
        @type node_id: string
        @param node_id: Transport Node id
        @type get_route_table: List
        @param get_route_table: A list of dicts. It is not used.
        @rtype: dict
        @return: Dict having route table
        Endpoint:
        /logical-routers/<logical-router-id>/routing/route-table
        """
        url_parameters = {'transport_node_id': node_id}
        client_class = getlogicalrouterroutetable.GetLogicalRouterRouteTable
        return super(NSX70RouterImpl, cls).read(client_object,
                                                client_class=client_class,
                                                query_params=url_parameters)

    @classmethod
    def get_status(cls, client_object, get_status=None):
        """
        Returns status for the Logical Router of the given id showing SR
        HA status (ACTIVE/PASSIVE), id of the SR and TN where the status
        is retrived. Empty if the LR does not have a SR.

        @type client_object: LogicalRouterAPIClient
        @param client_object: Client object
        @type get_status: List
        @param get_status: A list of dicts. It is not used.
        @rtype: dict
        @return: Dict having last-update timestamp, logical router id,
         array of LogicalRouterStatusPerNode(which constains SR HA status,
         SR id and TN id).

        Endpoint:
        /logical-routers/<logical-router-id>/status
        """
        client_class = getlogicalrouterstatus.GetLogicalRouterStatus
        return super(NSX70RouterImpl, cls).read(client_object,
                                                client_class=client_class)
