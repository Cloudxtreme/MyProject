import vmware.nsx_api.manager.logicalrouter.logicalrouter as logicalrouter
import vmware.nsx_api.manager.logicalrouter.schema.logicalrouter_schema \
    as logicalrouter_schema

import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    # TODO(Subbu/Amit): Fillup the remaining params
    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description',
        'cluster_id': 'edge_cluster_id'
    }

    _client_class = logicalrouter.LogicalRouter
    _schema_class = logicalrouter_schema.LogicalRouterSchema
    _url_prefix = "/uiauto/v1"

    def get_logical_router_id(self, client_object, **kwargs):
        return self.id_
