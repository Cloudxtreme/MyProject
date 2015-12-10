import vmware.kvm.vm.vm as vm
import vmware.common.base_client as base_client


class VMCLIClient(vm.VM, base_client.BaseCLIClient):
    pass
