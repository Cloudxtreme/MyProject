import vmware.nsx_api.manager.logicalport.logicalport as logicalport
import vmware.nsx_api.manager.logicalport.schema.logicalport_schema \
    as logicalport_schema
import vmware.nsx_api.manager.logicalport.schema.logicalportlistresult_schema \
    as logicalportlistresult_schema
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description',
        'switch_id': 'logical_switch_id',
        'switching_profile_value': 'value',
        'switching_profile_key': 'key'
    }

    _client_class = logicalport.LogicalPort
    _schema_class = logicalport_schema.LogicalPortSchema
    _list_schema_class = logicalportlistresult_schema. \
        LogicalPortListResultSchema
