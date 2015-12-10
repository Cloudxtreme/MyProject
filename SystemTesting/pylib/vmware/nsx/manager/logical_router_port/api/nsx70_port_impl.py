import vmware.interfaces.port_interface as port_interface
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.manager.aggsvclogicalrouterport.\
    getlogicalrouterportarptable as getlogicalrouterportarptable
import vmware.nsx_api.manager.logicalrouterports.logicalrouterport as logicalrouterport  # noqa
import vmware.nsx_api.manager.common.logicalrouterdownlinkport_schema as logicalrouterdownlinkport_schema  # noqa


class NSX70PortImpl(port_interface.PortInterface, base_crud_impl.BaseCRUDImpl):

    _attribute_map = {}
    _client_class = logicalrouterport.LogicalRouterPort
    _schema_class = logicalrouterdownlinkport_schema.\
        LogicalRouterDownLinkPortSchema

    @classmethod
    def get_sdk_client_object(cls, client_object, client_class=None, **kwargs):
        return client_class(connection_object=client_object.connection,
                            logicalrouterport_id=client_object.id_)

    @classmethod
    def get_arp_table(cls, client_object, node_id=None, get_arp_table=None):
        """
        Interface to get arp table from a port.

        @type client_object: LogicalRouterPortAPIClient
        @param client_object: Client object
        @type node_id: String
        @param node_id: Transport node id
        @type get_arp_table: List
        @param get_arp_table: A list of dicts. It is not used.
        @rtype: Dict
        @return: Dict having arp_table

        Endpoint:
        /logical-router-ports/<logical-router-port-id>/arp-table
        """
        url_parameters = {'transport_node_id': node_id}
        client_class = getlogicalrouterportarptable.GetLogicalRouterPortArpTable  # noqa
        return super(NSX70PortImpl, cls).read(client_object,
                                              client_class=client_class,
                                              query_params=url_parameters)
