import time
import vmware.workarounds as workarounds
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.manager.edgeclusters.edgecluster as edgecluster
import vmware.nsx_api.manager.edgeclusters.schema.edgecluster_schema \
    as edgecluster_schema
import vmware.nsx_api.manager.edgeclusters.schema. \
    edgeclusterlistresult_schema as edgeclusterlistresult_schema


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):
    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description',
        'fabric_profile_id': 'profile_id'
    }
    _client_class = edgecluster.EdgeCluster
    _schema_class = edgecluster_schema.EdgeClusterSchema
    _list_schema_class = edgeclusterlistresult_schema.\
        EdgeClusterListResultSchema

    @classmethod
    def create(cls, client_obj, schema=None, parent_id=None, **kwargs):
        result_dict = super(NSX70CRUDImpl, cls).create(
            client_obj, schema, parent_id, **kwargs)
        if workarounds.edgecluster_api_workaround.enabled:
            time.sleep(60)
        return result_dict
