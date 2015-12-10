import argparse
import atexit
import getpass
import sys

import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.vsphere.vc.vdswitch.vdswitch as vdswitch
import vmware.vsphere.vc.vdswitch.api.vdswitch_api_client as vdswitch_api_client


class VDSwitchFacade(vdswitch.VDSwitch, base_facade.BaseFacade):
    """VDSwitch client class to initiate VDSwitch operations."""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, name, parent):
        super(VDSwitchFacade, self).__init__()
        self.parent = parent
        # instantiate client objects
        api_client = vdswitch_api_client.VDSwitchAPIClient(
            name, parent=parent.clients.get(constants.ExecutionType.API))
        # Maintain the dictionary of client objects.
        # This will later be used by initialize() to create
        # connection anchors
        self._clients = {constants.ExecutionType.API: api_client}

        api_client.get_vds_mor()

    def get_impl_version(self, execution_type=None, interface=None):
        return "VC55"


def GetArgs():
    """
    Supports the command-line arguments listed below.
    """

    parser = argparse.ArgumentParser(description='VDSwitch Client')
    parser.add_argument('-s', '--vc', required=True,
                        action='store', help='Remote host to connect to')
    parser.add_argument('-u', '--username', required=True,
                        action='store', help='Username for host')
    parser.add_argument('-p', '--password', required=False,
                        action='store', help='Password for host')
    parser.add_argument('-i', '--vdswitch_name', required=True,
                        action='store', help='id_ of VDSwitch to power on')
    args = parser.parse_args()
    return args


def main():

    import vmware.vsphere.vc.vc_facade as vc_facade
    import vmware.vsphere.vc.datacenter.datacenter_facade as datacenter_facade
    import vmware.vsphere.vc.vdswitch.vdswitch_facade as vdswitch_facade
    import vmware.common.global_config as global_config

    pylogger = global_config.pylogger

    v_c = vc_facade.VCFacade("10.144.138.57", "root", "vmware")

    dc = datacenter_facade.DatacenterFacade(name="Datacenter2", parent=v_c)

    vds = vdswitch_facade.VDSwitchFacade(name="DSwitch3", parent=dc)

    result = vds.list_networks()
    pylogger.info("Operation result = %r" % result)

if __name__ == "__main__":
    main()
