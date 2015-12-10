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
        'cluster_id': 'edge_cluster_id',
        'configuration': 'config',
        'ha_mode': 'high_availability_mode',
        'gateway_cluster_member_index': 'preferred_edge_cluster_member_index'
    }

    _client_class = logicalrouter.LogicalRouter
    _schema_class = logicalrouter_schema.LogicalRouterSchema
