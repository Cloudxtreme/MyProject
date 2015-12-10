import vmware.nsx_api.manager.routing.updateroutingglobalconfig \
    as updateroutingglobalconfig
import vmware.nsx_api.manager.routing.schema.routing_schema as routing_schema
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseRUDImpl):

    _attribute_map = dict(
        routerid='router_id',
    )
    _client_class = updateroutingglobalconfig.UpdateRoutingGlobalConfig
    _schema_class = routing_schema.RoutingSchema
    _merge_flag_default = False

    @classmethod
    def get_sdk_client_object(cls, client_object, parent_id=None, **kwargs):
        return cls._client_class(
            connection_object=client_object.connection,
            url_prefix=cls._url_prefix,
            logicalrouter_id=parent_id)
