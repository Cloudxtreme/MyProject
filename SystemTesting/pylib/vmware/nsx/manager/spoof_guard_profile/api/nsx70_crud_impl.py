import vmware.nsx_api.manager.baseswitchingprofile.switchingprofile\
    as switchingprofile
import vmware.nsx_api.manager.common.spoofguardswitchingprofile_schema\
    as spoofguard_schema

import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'summary': 'description',
        'name': 'display_name',
        'white_list': 'white_list_providers'
    }

    _client_class = switchingprofile.SwitchingProfile
    _schema_class = spoofguard_schema.SpoofGuardSwitchingProfileSchema
