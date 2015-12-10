import vmware.nsx_api.manager.logicalswitch.logicalswitch as logicalswitch
import vmware.nsx_api.manager.logicalswitch.schema.logicalswitch_schema \
    as logicalswitch_schema
import vmware.nsx_api.manager.logicalswitch.schema.logicalswitchlistresult_schema as logicalswitchlistresult_schema  # noqa
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description',
        'switching_profile_value': 'value',
        'switching_profile_key': 'key'
    }

    _client_class = logicalswitch.LogicalSwitch
    _schema_class = logicalswitch_schema.LogicalSwitchSchema
    _list_schema_class = logicalswitchlistresult_schema.LogicalSwitchListResultSchema  # noqa
    _id_name = "logical_switch_id"
    _id_param = "logicalswitch_id"

    @classmethod
    def get_id_from_schema(cls, client_obj, schema=None, **kwargs):
        """
        Adds the support to discover transit logical switch by
        name "transit-{logical_router_id}".
        """
        if 'logical_router_id' in schema:
            schema['name'] = 'transit-' + str(schema['logical_router_id'])
            schema.pop('logical_router_id')

        return super(NSX70CRUDImpl, cls).get_id_from_schema(
            client_obj, schema, **kwargs)
