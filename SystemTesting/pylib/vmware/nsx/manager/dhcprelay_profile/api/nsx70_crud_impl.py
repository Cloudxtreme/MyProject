import vmware.nsx_api.manager.serviceprofile.serviceprofile as serviceprofile  # noqa
import vmware.nsx_api.manager.common.dhcprelayprofile_schema as serviceprofileschema  # noqa
import vmware.nsx_api.manager.serviceprofile.schema.serviceprofilelistresult_schema as serviceprofilelistresult_schema  # noqa
import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {
        'id_': 'id',
        'ipaddresses': 'server_addresses'
    }

    _client_class = serviceprofile.ServiceProfile
    _schema_class = serviceprofileschema.DhcpRelayProfileSchema
    _list_schema_class = serviceprofilelistresult_schema.ServiceProfileListResultSchema  # noqa
