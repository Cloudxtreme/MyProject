import vmware.nsx_api.manager.basehostswitchprofile.hostswitchprofile\
    as uplinkprofile
import vmware.nsx_api.manager.common.uplinkhostswitchprofile_schema\
    as uplinkprofile_schema

import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'summary': 'description',
        'vlan': 'transport_vlan',
        'active': 'active_list',
        'standby': 'standby_list',
        'adapter_type': 'uplink_type',
        'adapter_name': 'uplink_name',
        'load_balance': 'load_balance_algorithm',
    }

    _client_class = uplinkprofile.HostSwitchProfile
    _schema_class = uplinkprofile_schema.UplinkHostSwitchProfileSchema
