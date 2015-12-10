import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.manager.transportprofile.transportprofile \
    as transportprofile
import vmware.nsx_api.manager.transportprofile.schema.transportprofile_schema \
    as transportprofile_schema
import vmware.nsx_api.manager.transportprofile.schema.transportprofilelistresult_schema \
    as transportprofilelistresult_schema

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'summary': 'description'
    }

    _client_class = transportprofile.TransportProfile
    _schema_class = transportprofile_schema.TransportProfileSchema
    _list_schema_class = \
        transportprofilelistresult_schema.TransportProfileListResultSchema
