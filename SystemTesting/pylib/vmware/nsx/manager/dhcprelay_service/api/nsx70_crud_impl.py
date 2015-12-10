import vmware.nsx_api.manager.logicalservice.service as service
import vmware.nsx_api.manager.common.dhcprelayservice_schema as dhcp_relay_service_schema  # noqa

import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {
        'id_': 'id',
    }

    _client_class = service.Service
    _schema_class = dhcp_relay_service_schema.DhcpRelayServiceSchema
