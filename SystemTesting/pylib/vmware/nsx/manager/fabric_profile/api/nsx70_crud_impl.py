import vmware.nsx_api.manager.fabricprofile.fabricprofile as fabricprofile
import vmware.nsx_api.manager.common.fabricprofileclusterkeepalive_schema as \
    fabricprofileclusterkeepalive_schema

import vmware.nsx_api.manager.fabricprofile.schema. \
    fabricprofilelistresult_schema as fabricprofilelistresult_schema
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):
    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description'
    }

    _client_class = fabricprofile.FabricProfile
    _schema_class = fabricprofileclusterkeepalive_schema.\
        FabricProfileClusterKeepAliveSchema
    _list_schema_class = fabricprofilelistresult_schema.\
        FabricProfileListResultSchema