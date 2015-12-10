import vmware.nsx_api.manager.inventory.\
    listvirtualmachines as listvirtualmachines
import vmware.nsx_api.manager.inventory.schema.\
    virtualmachine_schema as virtualmachine_schema
import vmware.nsx_api.manager.inventory.schema.\
    virtualmachinelistresult_schema as\
    virtualmachinelistresult_schema
import vmware.nsx.manager.api.base_crud_impl as base_crud_impl


class NSX70CRUDImpl(base_crud_impl.BaseCRUDImpl):

    # Attribute map
    _attribute_map = {
        'id_': 'id',
        'name': 'display_name',
        'summary': 'description',
        'vm_type': 'type'
    }

    _client_class = listvirtualmachines.ListVirtualMachines
    _schema_class = virtualmachine_schema.VirtualMachineSchema
    _list_schema_class = virtualmachinelistresult_schema.\
        VirtualMachineListResultSchema