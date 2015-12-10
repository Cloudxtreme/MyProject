import vmware.base.vm as vm


class VM(vm.VM):

    def get_impl_version(self, execution_type=None, interface=None):
        # Need to fix this code to return the right version based on the VM OS
        if execution_type == 'api':
            return "VM10"
        return "Default"
