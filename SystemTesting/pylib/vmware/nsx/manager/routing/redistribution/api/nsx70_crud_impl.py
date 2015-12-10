import vmware.nsx_api.manager.routing.updateredistributionconfig \
    as updateredistributionconfig
import vmware.nsx_api.manager.routing.schema.redistributionconfig_schema \
    as redistributionconfig_schema
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseRUDImpl):

    _attribute_map = dict(
        name='display_name',
        summary='description',
        fromprotocol='sources',
        toprotocol='destination',
        redistributionenabled='enabled',
    )
    _client_class = updateredistributionconfig.UpdateRedistributionConfig
    _schema_class = redistributionconfig_schema.RedistributionConfigSchema
    _merge_flag_default = False

    @classmethod
    def get_sdk_client_object(cls, client_object, parent_id=None, **kwargs):
        return cls._client_class(
            connection_object=client_object.connection,
            url_prefix=cls._url_prefix,
            logicalrouter_id=parent_id)
