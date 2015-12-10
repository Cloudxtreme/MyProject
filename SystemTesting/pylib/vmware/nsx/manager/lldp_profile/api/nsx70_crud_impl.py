import vmware.nsx_api.manager.basehostswitchprofile.hostswitchprofile\
    as lldp_profile
import vmware.nsx_api.manager.common.lldphostswitchprofile_schema\
    as lldphostswitchprofile_schema

import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description'
    }

    _client_class = lldp_profile.HostSwitchProfile
    _schema_class = lldphostswitchprofile_schema.LldpHostSwitchProfileSchema