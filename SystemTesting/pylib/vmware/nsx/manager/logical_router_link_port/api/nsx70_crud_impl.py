import vmware.nsx_api.manager.logicalrouterports.logicalrouterport as logicalrouterport     # noqa
import vmware.nsx_api.manager.common.logicalrouterlinkport_schema as logicalrouterlinkport_schema   # noqa
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):
    # TODO: Fillup the remaining params once the API's are available
    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description',
        'macaddress': 'mac_address',
        'binding': 'service_profile_bindings',
        'prefixlen': 'prefix_length',
        'linked_router_port_id': 'linked_logical_router_port_id',
        'gateway_cluster_member_index': 'edge_cluster_member_index'
    }

    _client_class = logicalrouterport.LogicalRouterPort
    _schema_class = logicalrouterlinkport_schema.LogicalRouterLinkPortSchema
