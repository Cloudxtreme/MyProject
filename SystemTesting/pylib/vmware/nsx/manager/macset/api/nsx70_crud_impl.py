import vmware.nsx_api.manager.macset.macset as macset
import vmware.nsx_api.manager.macset.schema.macset_schema as macset_schema

import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    """
    Below is a sample call to create a mac set.
    POST http://10.110.86.60/api/v1/mac-sets
      {
          "display_name":"testMACSet",
              "mac_addresses":["01:23:45:67:89:ab","00:14:22:01:23:45"]
                }
    """
    _attribute_map = {
        'id_': 'id',
        'macaddresses': 'mac_addresses',
        'name': 'display_name'
    }
    _client_class = macset.MACSet
    _schema_class = macset_schema.MACSetSchema
