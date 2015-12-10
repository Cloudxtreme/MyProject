import vmware.nsx_api.manager.vnim.listvnipools as vnipool
import vmware.nsx_api.manager.vnim.schema.vnipool_schema as vnipool_schema
import vmware.nsx_api.manager.vnim.schema.vnipoollistresult_schema as\
    vnipoollistresult_schema

import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description',
        'begin': 'start',
        'is_system_generated': 'is_system'
    }

    _client_class = vnipool.ListVNIPools
    _schema_class = vnipool_schema.VniPoolSchema
    _list_schema_class = vnipoollistresult_schema.VniPoolListResultSchema
