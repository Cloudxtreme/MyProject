import argparse

import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.vsphere.esx.vmnic.vmnic as vmnic
import vmware.vsphere.esx.vmnic.api.vmnic_api_client as vmnic_api_client
import vmware.vsphere.esx.vmnic.cli.vmnic_cli_client as vmnic_cli_client


class VmnicFacade(vmnic.Vmnic, base_facade.BaseFacade):
    """Vmnic client class to initiate VMNIC operations."""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.CLI

    def __init__(self, parent, name):
        super(VmnicFacade, self).__init__(name, parent=parent)
        self.parent = parent
        # instantiate client objects
        api_client = vmnic_api_client.VmnicAPIClient(
            name, parent=parent.clients.get(constants.ExecutionType.API))
        cli_client = vmnic_cli_client.VmnicCLIClient(
            name, parent=parent.clients.get(constants.ExecutionType.CLI))

        # Maintain the dictionary of client objects.
        # This will later be used by initialize() to create
        # connection anchors
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}


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
    args = parser.parse_args()
    return args


def main():

    import vmware.vsphere.esx.esx_facade as esx_facade
    import vmware.vsphere.esx.vmnic.vmnic_facade as vmnic_facade
    import vmware.common.global_config as global_config

    pylogger = global_config.pylogger
    args = GetArgs()
    password = args.password
    host = args.host
    username = args.username

    hc = esx_facade.ESXFacade(host, username, password)
    vmnic = vmnic_facade.VmnicFacade(parent=hc, name="vmnic1")
    result = vmnic.set_device_status(device_status="up")
    pylogger.info("Operation result= %r" % result)

if __name__ == "__main__":
    main()
