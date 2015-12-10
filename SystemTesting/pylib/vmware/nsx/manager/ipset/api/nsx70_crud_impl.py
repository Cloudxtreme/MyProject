import vmware.nsx_api.manager.ipset.ipset as ipset
import vmware.nsx_api.manager.ipset.schema.ipset_schema as ipset_schema

import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'ipaddresses': 'ip_addresses',
        'name': 'display_name'
    }
    _client_class = ipset.IPSet
    _schema_class = ipset_schema.IPSetSchema
