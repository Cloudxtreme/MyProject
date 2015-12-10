import argparse
import atexit
import getpass
import sys
from pprint import pprint

import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.vsphere.vc.vdswitch.resourcepool.resourcepool as resourcepool
import vmware.vsphere.vc.vdswitch.resourcepool.api.resourcepool_api_client as resourcepool_api_client


class ResourcePoolFacade(resourcepool.ResourcePool, base_facade.BaseFacade):

    """ResourcePool client class to initiate ResourcePool operations."""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, name=None, parent=None):
        super(ResourcePoolFacade, self).__init__(name=None, parent=parent)
        self.parent = parent
        # instantiate client objects
        api_client = resourcepool_api_client.ResourcePoolAPIClient(
            name, parent=parent.clients.get(constants.ExecutionType.API))
        # Maintain the dictionary of client objects.
        # This will later be used by initialize() to create
        # connection anchors
        self._clients = {constants.ExecutionType.API: api_client}

    def get_impl_version(self, execution_type=None, interface=None):
        return "VC55"


def GetArgs():
    """
    Supresourcepools the command-line arguments listed below.
    """

    parser = argparse.ArgumentParser(description='ResourcePool Client')
    parser.add_argument('-s', '--host', required=True,
                        action='store', help='Remote host to connect to')
    parser.add_argument('-u', '--username', required=True,
                        action='store', help='Username for host')
    parser.add_argument('-p', '--password', required=False,
                        action='store', help='Password for host')
    parser.add_argument('-i', '--resourcepool_id', required=True,
                        action='store', help='id_ of ResourcePool to power on')
    args = parser.parse_args()
    return args


def main():

    import vmware.vsphere.vc.vc_facade as vc_facade
    import vmware.vsphere.vc.datacenter.datacenter_facade as datacenter_facade
    import vmware.vsphere.vc.vdswitch.vdswitch_facade as vdswitch_facade
    import vmware.common.global_config as global_config
    import vmware.vsphere.vc.vdswitch.resourcepool.resourcepool_facade as resourcepool_facade

    pylogger = global_config.pylogger

    v_c = vc_facade.VCFacade("10.144.138.57", "root", "vmware")

    dc = datacenter_facade.DatacenterFacade(name="Datacenter2", parent=v_c)

    vds = vdswitch_facade.VDSwitchFacade(name="DSwitch3", parent=dc)

    rp = resourcepool_facade.ResourcePoolFacade(name="TEST", parent=vds)

    result = rp.delete()
    pylogger.info("Operation result = %r" % result)

if __name__ == "__main__":
    main()
