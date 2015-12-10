import vmware.nsx_api.manager.baseswitchingprofile.switchingprofile\
    as switchingprofile
import vmware.nsx_api.manager.common.switchsecurityswitchingprofile_schema\
    as switchsecurity_schema

import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'summary': 'description',
        'name': 'display_name',
        'server_block': 'server_block_enabled',
        'client_block': 'client_block_enabled',
        'macaddresses': 'white_list'
    }

    _client_class = switchingprofile.SwitchingProfile
    _schema_class = switchsecurity_schema.SwitchSecuritySwitchingProfileSchema
