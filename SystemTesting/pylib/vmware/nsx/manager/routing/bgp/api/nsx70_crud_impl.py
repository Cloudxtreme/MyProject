import vmware.nsx_api.manager.routing.addbgpneighbor as addbgpneighbor
import vmware.nsx_api.manager.routing.schema.bgpneighbor_schema \
    as bgpneighbor_schema
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = dict(
        name='display_name',
        summary='description',
        ipaddress='neighbor_address',
        source='source_address',
        remoteas='remote_as',
        keepalivetimer='keep_alive_timer',
        holddowntimer='hold_down_timer',
        localas='as_number',
        bgpenabled='enabled',
        gracefulrestart='graceful_restart',
        ecmpenabled='ecmp',
        holduptimer='hold_up_timer',
        filter_in_prefixid='filter_in_ipprefixlist_id',
        filter_out_prefixid='filter_out_ipprefixlist_id',
        filter_in_routemapid='filter_in_route_map_id',
        filter_out_routemapid='filter_out_route_map_id'
    )
    _client_class = addbgpneighbor.AddBgpNeighbor
    _schema_class = bgpneighbor_schema.BgpNeighborSchema

    @classmethod
    def get_sdk_client_object(cls, client_object, parent_id=None, **kwargs):
        return cls._client_class(
            connection_object=client_object.connection,
            url_prefix=cls._url_prefix,
            logicalrouter_id=parent_id)

    @classmethod
    def create(cls, client_obj, schema=None, logical_router_id=None,
               sync=False, client_class=None, schema_class=None, id_=None):
        logical_router_id = client_obj.parent.get_logical_router_id()
        super(NSX70CRUDImpl, cls).create(client_obj,
                                         parent_id=logical_router_id,
                                         schema=schema)
