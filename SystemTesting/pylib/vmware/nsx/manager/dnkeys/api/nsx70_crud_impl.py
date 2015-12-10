import vmware.nsx_api.manager.certificatemanager.getdnkeys as getdnkeys
import vmware.nsx_api.manager.certificatemanager.schema.stringlist_schema\
    as stringlist_schema

import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {}

    _client_class = getdnkeys.GetDNKeys
    _schema_class = stringlist_schema.StringListSchema
    _list_schema_class = stringlist_schema.StringListSchema
