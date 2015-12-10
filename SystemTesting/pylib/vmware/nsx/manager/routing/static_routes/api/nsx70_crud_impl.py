import vmware.nsx_api.manager.routing.updatestaticroutes as updatestaticroutes
import vmware.nsx_api.manager.routing.schema.staticroutes_schema \
    as staticroutes_schema
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseRUDImpl):

    _attribute_map = dict(
        name='display_name',
        summary='description',
        staticroutes='routes',
        lr_port_id='logical_router_port_id',
    )
    _client_class = updatestaticroutes.UpdateStaticRoutes
    _schema_class = staticroutes_schema.StaticRoutesSchema
    _merge_flag_default = False

    @classmethod
    def get_sdk_client_object(cls, client_object, parent_id=None, **kwargs):
        return cls._client_class(
            connection_object=client_object.connection,
            url_prefix=cls._url_prefix,
            logicalrouter_id=parent_id)
