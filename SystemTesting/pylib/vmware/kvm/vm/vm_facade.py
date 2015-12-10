import optparse

import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.interfaces.labels as labels
import vmware.kvm.vm.api.vm_api_client as vm_api_client
import vmware.kvm.vm.cli.vm_cli_client as vm_cli_client
import vmware.kvm.vm.cmd.vm_cmd_client as vm_cmd_client
import vmware.kvm.vm.vm as vm


class VMFacade(vm.VM, base_facade.BaseFacade):
    """
    Client class for KVM based VMs.

    @type parent: BaseFacade
    @param parent: To instantiate a VM client object, pass in the parent
        entity (in this case KVM client object) which can perform
        operations on the VM.
    @type name: str
    @param name: Name of this VM.
    """
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, name=None, username=None,
                 password=None, ip=None):
        super(VMFacade, self).__init__(
            parent=parent, name=name, password=password, username=username,
            ip=ip)
        cli_client = vm_cli_client.VMCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI),
            name=name, password=password, username=username)
        api_client = vm_api_client.VMAPIClient(
            parent=parent.get_client(constants.ExecutionType.API),
            name=name, password=password, username=username)
        cmd_client = vm_cmd_client.VMCMDClient(
            ip=self.ip, name=name, password=password, username=username)
        self._clients = {constants.ExecutionType.CLI: cli_client,
                         constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CMD: cmd_client}

    @base_facade.auto_resolve(labels.ADAPTER,
                              execution_type=constants.ExecutionType.API)
    def get_ip(self, execution_type=None, **kwargs):
        pass


if __name__ == "__main__":
    opt_parser = optparse.OptionParser()
    opt_parser.add_option('--kvm-ip', action='store', default='10.145.161.225',
                          help='IP of KVM hypervisor [%default*]')
    opt_parser.add_option('--kvm-user', action='store', default='root',
                          help='Username for logging into KVM [%default*]')
    opt_parser.add_option('--kvm-pass', action='store', default='default',
                          help='Password for logging into KVM [%default*]')
    opt_parser.add_option('--vm', action='store', default='default',
                          help='Name of the VM to create/destroy [%default*]')
    options, args = opt_parser.parse_args()
    if None in (options.kvm_ip, options.kvm_user, options.kvm_pass,
                options.vm):
        opt_parser.error('Missing KVM IP or usr or pass or VM name.')
    import vmware.kvm.kvm_facade as kvm_facade
    import vmware.kvm.vm.vm_facade as vm_facade
    kvm_facade_obj = kvm_facade.KVMFacade(ip=options.kvm_ip,
                                          username=options.kvm_user,
                                          password=options.kvm_pass)
    kvm_facade_obj.initialize()
    vm = vm_facade.VMFacade(name=options.vm, parent=kvm_facade_obj)
    vm.initialize()
    vm.off()
    # Negative Test.
    vm.shutdown()
    vm.on()
