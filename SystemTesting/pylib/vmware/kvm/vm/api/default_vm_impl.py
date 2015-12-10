import vmware.interfaces.vm_interface as vm_interface


class DefaultVMImpl(vm_interface.VMInterface):
    """Impl class for Vm related operation."""

    @classmethod
    def get_name(cls, client_object):
        vm = client_object.vm
        return vm.unique_name
