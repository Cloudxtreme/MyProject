import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.manager.baseswitchingprofile.schema.switchingprofileslistresult_schema as switchingprofileslistresult_schema  # noqa
import vmware.nsx_api.manager.baseswitchingprofile.switchingprofile as switchingprofile  # noqa
import vmware.nsx_api.manager.common.ipdiscoveryswitchingprofile_schema as ipdiscoveryswitchingprofile_schema  # noqa


pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        "id_": "id",
        "name": "display_name",
    }

    _client_class = switchingprofile.SwitchingProfile
    _schema_class = ipdiscoveryswitchingprofile_schema.IpDiscoverySwitchingProfileSchema  # noqa
    _list_schema_class = switchingprofileslistresult_schema.SwitchingProfilesListResultSchema  # noqa
