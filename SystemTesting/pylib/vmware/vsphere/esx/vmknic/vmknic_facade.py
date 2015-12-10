import argparse

import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.vsphere.esx.vmknic.vmknic as vmknic
import vmware.vsphere.esx.vmknic.api.vmknic_api_client as vmknic_api_client


class VmknicFacade(vmknic.Vmknic, base_facade.BaseFacade):
    """Vmknic client class to initiate VM operations."""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, name=None):
        super(VmknicFacade, self).__init__(name, parent=parent)
        self.parent = parent
        # instantiate client objects
        api_client = vmknic_api_client.VmknicAPIClient(
            name, parent=parent.clients.get(constants.ExecutionType.API))
        # Maintain the dictionary of client objects.
        # This will later be used by initialize() to create
        # connection anchors
        self._clients = {constants.ExecutionType.API: api_client}


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
    import vmware.vsphere.esx.vmknic.vmknic_facade as vmknic_facade
    import vmware.common.global_config as global_config

    pylogger = global_config.pylogger
    args = GetArgs()
    password = args.password
    host = args.host
    username = args.username

    hc = esx_facade.ESXFacade(host, username, password)

    # hc = esx_facade.ESXFacade("10.144.139.194", "root", "ca$hc0w")

    vmknic = vmknic_facade.VmknicFacade(name="vmk0", parent=hc)

    result = vmknic.enable_vmotion()

    pylogger.info("Operation result= %r" % result)

if __name__ == "__main__":
    main()
