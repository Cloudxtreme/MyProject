import vmware.nsx_api.manager.logicalswitch.logicalswitch as logicalswitch
import vmware.nsx_api.manager.logicalswitch.schema.logicalswitch_schema \
    as logicalswitch_schema

import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description',
        'admin_state': 'switch_admin_state'
    }

    _client_class = logicalswitch.LogicalSwitch
    _schema_class = logicalswitch_schema.LogicalSwitchSchema
    _url_prefix = "/uiauto/v1"
