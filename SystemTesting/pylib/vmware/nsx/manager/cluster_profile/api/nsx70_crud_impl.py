import vmware.nsx_api.manager.clusterprofile.clusterprofile as clusterprofile
import vmware.nsx_api.manager.clusterprofile.schema.clusterprofile_schema as clusterprofile_schema  # noqa
import vmware.nsx_api.manager.clusterprofile.schema.clusterprofilelistresult_schema as clusterprofilelistresult_schema  # noqa

import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):
    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description'
    }

    _client_class = clusterprofile.ClusterProfile
    _schema_class = clusterprofile_schema.EdgeHighAvailabilityProfileSchema
    _list_schema_class = \
        clusterprofilelistresult_schema.ClusterProfileListResultSchema
