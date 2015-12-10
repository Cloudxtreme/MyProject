import vmware.nsx_api.manager.inventory.listvifs as listvifs
import vmware.nsx_api.manager.inventory.schema.\
    virtualnetworkinterface_schema as\
    virtualnetworkinterface_schema
import vmware.nsx_api.manager.inventory.schema.\
    virtualnetworkinterfacelistresult_schema as\
    virtualnetworkinterfacelistresult_schema
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {
        'id_': 'id',
        'adapter_mac': 'mac_address'
    }

    _client_class = listvifs.ListVifs
    _schema_class = \
        virtualnetworkinterface_schema. \
        VirtualNetworkInterfaceSchema
    _list_schema_class = \
        virtualnetworkinterfacelistresult_schema.\
        VirtualNetworkInterfaceListResultSchema