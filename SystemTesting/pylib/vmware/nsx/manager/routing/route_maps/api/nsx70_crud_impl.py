import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.manager.routing.addroutemap\
    as addroutemap
import vmware.nsx_api.manager.routing.schema.routemap_schema\
    as routemap_schema


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description',
        'route_map_sequence': 'sequences',
        'ip_prefix_id_list': 'ip_prefix_lists'
    }

    _client_class = addroutemap.AddRouteMap
    _schema_class = routemap_schema.RouteMapSchema

    @classmethod
    def get_sdk_client_object(cls, client_object, parent_id=None,
                              id_=None, **kwargs):
        logical_router_id = client_object.parent.get_logical_router_id()
        return cls._client_class(
            connection_object=client_object.connection,
            url_prefix=cls._url_prefix,
            logicalrouter_id=logical_router_id)