import vmware.vsphere.vm.vm as vm
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.interfaces.labels as labels
import vmware.vsphere.vm.api.vm_api_client as vm_api_client
import vmware.vsphere.vm.cmd.vm_cmd_client as vm_cmd_client


class VMFacade(vm.VM, base_facade.BaseFacade):
    """VM client class to initiate VM operations."""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, id_, parent, host_ip=None, ip=None, username=None,
                 password=None):
        # Pass host_ip if VC is the parent object for VM.
        super(VMFacade, self).__init__(id_, parent=parent)
        self.parent = parent
        # instantiate client objects
        api_client = vm_api_client.VMAPIClient(
            id_, parent=parent.clients.get(constants.ExecutionType.API),
            host_ip=host_ip)
        cmd_client = vm_cmd_client.VMCMDClient(
            ip=ip, username=username, password=password)
        # Maintain the dictionary of client objects.
        # This will later be used by initialize() to create
        # connection anchors
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CMD: cmd_client}

    @base_facade.auto_resolve(labels.VM,
                              execution_type=constants.ExecutionType.API)
    def get_ip(self, execution_type=None, **kwargs):
        pass
