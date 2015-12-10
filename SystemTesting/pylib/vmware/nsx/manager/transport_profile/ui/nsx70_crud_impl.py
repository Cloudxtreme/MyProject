import vmware.nsx_api.manager.transportprofile.transportprofile \
    as transportprofile
import vmware.nsx_api.manager.transportprofile.schema.transportprofile_schema \
    as transportprofile_schema
import vmware.nsx_api.manager.transportprofile.schema.transportprofilelistresult_schema \
    as transportprofilelistresult_schema

import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):
    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description'
    }

    _client_class = transportprofile.TransportProfile
    _schema_class = transportprofile_schema.TransportProfileSchema
    _list_schema_class = \
        transportprofilelistresult_schema.TransportProfileListResultSchema
    _url_prefix = "/uiauto/v1"
