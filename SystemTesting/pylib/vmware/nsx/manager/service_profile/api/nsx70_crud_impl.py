import vmware.nsx_api.manager.serviceprofiles.serviceprofile \
    as serviceprofile
import vmware.nsx_api.manager.common.serviceprofiledhcprelay_schema \
    as serviceprofileschema

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
    _schema_class = serviceprofileschema.ServiceProfileDhcpRelaySchema