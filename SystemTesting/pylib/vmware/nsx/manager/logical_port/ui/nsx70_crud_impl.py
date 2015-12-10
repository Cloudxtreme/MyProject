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
        'switch_name': 'logical_switch_id',
        'admin_state': 'port_admin_state',
        'adapter_uuid': 'vif'
    }

    _client_class = logicalport.LogicalPort
    _schema_class = logicalport_schema.LogicalPortSchema
    _list_schema_class = logicalportlistresult_schema. \
        LogicalPortListResultSchema
    _url_prefix = "/uiauto/v1"
