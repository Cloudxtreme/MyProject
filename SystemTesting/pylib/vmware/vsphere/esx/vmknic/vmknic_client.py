import argparse
import atexit
import getpass
import sys

import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.vsphere.esx.vmknic.vmknic as vmknic
import vmware.vsphere.esx.vmknic.api.vmknic_api_client as vmknic_api_client

class VmknicFacade(vmknic.Vmknic, base_facade.BaseFacade):
    """Vmknic client class to initiate VM operations."""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, name, parent):
        super(VmknicFacade, self).__init__(name, parent=parent)
        self.parent = parent
        # instantiate client objects
        api_client = vmknic_api_client.VmknicAPIClient(
            name, parent=parent.clients.get(constants.ExecutionType.API))
        # Maintain the dictionary of client objects.
        # This will later be used by initialize() to create
        # connection anchors
        self._clients = {constants.ExecutionType.API: api_client}

    def get_impl_version(self, execution_type=None, interface=None):
        return "ESX55"


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
    parser.add_argument('-i', '--vmknic_name', required=True,
                        action='store', help='id_ of VM to power on')
    args = parser.parse_args()
    return args


def main():

    import vmware.vsphere.esx.esx_client as esx_client
    import vmware.vsphere.esx.vmknic.vmknic_client as vmknic_client
    import vmware.common.global_config as global_config

    pylogger = global_config.pylogger

    #hc = esx_client.ESXFacade(host, username, password)

    hc = esx_client.ESXFacade("10.144.139.194", "root", "ca$hc0w")

    vmknic = vmknic_client.VmknicFacade(name="vmk0", parent=hc)

    result = vmknic.update_vmk()

    pylogger.info("Operation result= %r" % result)

if __name__ == "__main__":
    main()
