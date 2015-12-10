import vmware.common.global_config as global_config
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl
import vmware.nsx_api.appliance.node.schema.noderouteproperties_schema \
    as noderouteproperties_schema
import vmware.nsx_api.appliance.node.schema.noderoutepropertieslistresult_schema \
    as noderoutepropertieslistresult_schema
import vmware.nsx_api.appliance.node.noderoute as noderoute

pylogger = global_config.pylogger


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {
        'id_': 'route_id',
        'adapter_interface': 'interface_id',
        'destination_ip': 'destination',
        'protocol': 'proto'
    }
    _client_class = noderoute.NodeRoute
    _schema_class = noderouteproperties_schema.NodeRoutePropertiesSchema
    _list_schema_class = noderoutepropertieslistresult_schema.\
        NodeRoutePropertiesListResultSchema