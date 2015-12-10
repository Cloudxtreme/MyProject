import vmware.nsx_api.manager.routing.updaterouteadvertisement \
    as updaterouteadvertisement
import vmware.nsx_api.manager.routing.schema.advertisementroutes_schema \
    as advertisementroutes_schema
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseRUDImpl):

    _attribute_map = dict(
        name='display_name',
        summary='description',
        network='networks',
        enableadvertisement='enabled',
    )
    _client_class = updaterouteadvertisement.UpdateRouteAdvertisement
    _schema_class = advertisementroutes_schema.AdvertisementRoutesSchema
    _merge_flag_default = False

    @classmethod
    def get_sdk_client_object(cls, client_object, parent_id=None, **kwargs):
        return cls._client_class(
            connection_object=client_object.connection,
            url_prefix=cls._url_prefix,
            logicalrouter_id=parent_id)
