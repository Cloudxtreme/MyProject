import vmware.nsx_api.manager.nsservice.nsservice as nsservice
import vmware.nsx_api.manager.nsservice.schema.nsservice_schema as nsservice_schema  # noqa

import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    """
    Below is a sample request to create a nsservice.
    POST https://10.110.86.60/api/v1/ns-services
     {
        "display_name":"testNSService",
        "nsservice_element":{"ether_type": 0x0800, "resource_type": "EtherTypeNSService"}  # noqa
     }
    """
    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'members': 'nsservice_element',
    }
    _client_class = nsservice.NSService
    _schema_class = nsservice_schema.NSServiceSchema
