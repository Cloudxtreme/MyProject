import vmware.base.vm as vm


class VM(vm.VM):

    def get_impl_version(self, execution_type=None, interface=None):
        return "Default"
