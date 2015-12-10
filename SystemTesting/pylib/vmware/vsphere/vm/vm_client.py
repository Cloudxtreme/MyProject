import argparse

import vmware.base.vm as vm
import vmware.common.constants as constants
import vmware.vsphere.vsphere_client as vsphere_client


class VMFacade(vm.VM):
    """VM client class to initiate VM operations."""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, vm_id, parent):
        super(VMFacade, self).__init__(vm_id, parent=parent)
        self.parent = parent
        # instantiate client objects
        api_client = VMAPIClient(
            vm_id, parent=parent.clients.get(constants.ExecutionType.API))
        # Maintain the dictionary of client objects.
        # This will later be used by initialize() to create
        # connection anchors
        self._clients = {constants.ExecutionType.API: api_client}


class VMAPIClient(vsphere_client.VSphereAPIClient):

    _parent = None

    def __init__(self, vm_id, parent=None):
        super(VMAPIClient, self).__init__(parent=parent)
        self.id_ = vm_id
        self.query_command_api = constants.VimApiQuery.VM
        self.path_array.append(parent.get_current_path_element())
        self.path_array.extend(parent.path_array)


def GetArgs():
    """
    Supports the command-line arguments listed below.
    """

    parser = argparse.ArgumentParser(description='Arguments for VM Client')
    parser.add_argument('-s', '--host', required=True,
                        action='store', help='Remote host to connect to')
    parser.add_argument('-u', '--username', required=True,
                        action='store', help='Username for host')
    parser.add_argument('-p', '--password', required=False,
                        action='store', help='Password for host')
    parser.add_argument('-i', '--vm_id', required=True,
                        action='store', help='id_ of VM to power on')
    args = parser.parse_args()
    return args


def main():

    import vmware.vsphere.esx.esx_client as esx_client
    import vmware.vsphere.vm.vm_client as vm_client
    import vmware.common.global_config as global_config

    pylogger = global_config.pylogger

    args = GetArgs()
    password = args.password
    host = args.host
    username = args.username
    id_ = args.vm_id

    # $ python vm_client.py -s 10.144.138.189 -u root -p ca\$hc0w -i 3
    hc = esx_client.ESXFacade(host, username, password)

    # hc = esx_client.ESX("10.144.138.189", "root", "ca$hc0w")

    # XXX(Shashank): Since vm creation hasn't been implemented we are setting
    # id to an existing vm's id in the host inventory.
    vm = vm_client.VMFacade(id_, parent=hc)

    result = vm.get_vm_hardware_info()

    pylogger.info("Operation result= %r" % result)

if __name__ == "__main__":
    main()
