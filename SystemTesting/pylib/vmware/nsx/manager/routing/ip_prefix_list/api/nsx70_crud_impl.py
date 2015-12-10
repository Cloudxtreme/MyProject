import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.manager.routing.addipprefixlist\
    as addipprefixlist
import vmware.nsx_api.manager.routing.schema.ipprefixlist_schema\
    as ipprefixlist_schema


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description',
        'ge': 'greaterthan_equalto',
        'le': 'lessthan_equalto'
    }

    _client_class = addipprefixlist.AddIPPrefixList
    _schema_class = ipprefixlist_schema.IPPrefixListSchema

    @classmethod
    def get_sdk_client_object(cls, client_object, parent_id=None,
                              id_=None, **kwargs):
        return cls._client_class(
            connection_object=client_object.connection,
            url_prefix=cls._url_prefix,
            logicalrouter_id=parent_id)

    @classmethod
    def create(cls, client_obj, schema=None, logical_router_id=None,
               sync=False, client_class=None, schema_class=None, id_=None):
        logical_router_id = client_obj.parent.get_logical_router_id()
        return super(NSX70CRUDImpl, cls).create(client_obj,
                                                parent_id=logical_router_id,
                                                schema=schema)

    @classmethod
    def update(cls, client_obj, schema=None, logical_router_id=None,
               sync=False, client_class=None, schema_class=None, id_=None):
        logical_router_id = client_obj.parent.get_logical_router_id()
        prefix_list_id = client_obj.id_

        return super(NSX70CRUDImpl, cls).update(client_obj,
                                                parent_id=logical_router_id,
                                                schema=schema,
                                                id_=prefix_list_id,
                                                client_class=cls._client_class)

    @classmethod
    def delete(cls, client_obj, schema=None, logical_router_id=None,
               sync=False, client_class=None, schema_class=None, id_=None):
        logical_router_id = client_obj.parent.get_logical_router_id()
        prefix_list_id = client_obj.id_

        return super(NSX70CRUDImpl, cls).delete(client_obj,
                                                parent_id=logical_router_id,
                                                schema=schema,
                                                id_=prefix_list_id,
                                                client_class=cls._client_class)