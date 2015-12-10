import argparse
import atexit
import getpass
import sys
from pprint import pprint

import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.vsphere.vc.vdswitch.dvport.dvport as dvport
import vmware.vsphere.vc.vdswitch.dvport.api.dvport_api_client as dvport_api_client


class DVPortFacade(dvport.DVPort, base_facade.BaseFacade):

    """DVPort client class to initiate DVPort operations."""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, name=None, parent=None):
        super(DVPortFacade, self).__init__(name=name, parent=parent)
        self.parent = parent
        # instantiate client objects
        api_client = dvport_api_client.DVPortAPIClient(
            name, parent=parent.clients.get(constants.ExecutionType.API))
        # Maintain the dictionary of client objects.
        # This will later be used by initialize() to create
        # connection anchors
        self._clients = {constants.ExecutionType.API: api_client}

    def get_impl_version(self, execution_type=None, interface=None):
        return "VC55"


def GetArgs():
    """
    Supdvports the command-line arguments listed below.
    """

    parser = argparse.ArgumentParser(description='Arguments for DVPort Client')
    parser.add_argument('-s', '--host', required=True,
                        action='store', help='Remote host to connect to')
    parser.add_argument('-u', '--username', required=True,
                        action='store', help='Username for host')
    parser.add_argument('-p', '--password', required=False,
                        action='store', help='Password for host')
    parser.add_argument('-i', '--dvport_id', required=True,
                        action='store', help='id_ of DVPort to power on')
    args = parser.parse_args()
    return args


def main():

    import vmware.vsphere.vc.vc_facade as vc_facade
    import vmware.vsphere.vc.datacenter.datacenter_facade as datacenter_facade
    import vmware.vsphere.vc.vdswitch.vdswitch_facade as vdswitch_facade
    import vmware.vsphere.vc.vdswitch.dvportgroup.dvportgroup_facade as dvportgroup_facade
    import vmware.common.global_config as global_config
    import vmware.vsphere.vc.vdswitch.dvport.dvport_facade as dvport_facade
    import vmware.schema.switch.vdswitch.dvport_schema as dvport_schema

    pylogger = global_config.pylogger

    v_c = vc_facade.VCFacade("10.144.138.57", "root", "vmware")

    dc = datacenter_facade.DatacenterFacade(name="Datacenter2", parent=v_c)

    vds = vdswitch_facade.VDSwitchFacade(name="DSwitch4", parent=dc)

    dvpg = dvportgroup_facade.DVPortgroupFacade(name="DPortGroup4", parent=vds)

    schema_object = dvport_schema.DVPortSchema(forged_transmits=True)
    dvp = dvport_facade.DVPortFacade(name="0", parent=dvpg)

    result = dvp.create()
    pylogger.info("Operation result = %r" % result)

if __name__ == "__main__":
    main()
