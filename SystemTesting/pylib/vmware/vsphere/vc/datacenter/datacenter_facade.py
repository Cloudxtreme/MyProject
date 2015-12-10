import argparse

import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.vsphere.vc.datacenter.datacenter as datacenter
import vmware.vsphere.vc.datacenter.api.datacenter_api_client as datacenter_api


class DatacenterFacade(datacenter.Datacenter, base_facade.BaseFacade):
    """Datacenter client class to initiate Datacenter operations."""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, name=None):
        super(DatacenterFacade, self).__init__(name, parent=parent)
        self.parent = parent
        # instantiate client objects
        api_client = datacenter_api.DatacenterAPIClient(
            name=name, parent=parent.clients.get(constants.ExecutionType.API))
        # Maintain the dictionary of client objects.
        # This will later be used by initialize() to create
        # connection anchors
        self._clients = {constants.ExecutionType.API: api_client}


def GetArgs():
    """
    Supports the command-line arguments listed below.
    """

    parser = argparse.ArgumentParser(description='Datacenter Client')
    parser.add_argument('-s', '--vc', required=True,
                        action='store', help='Remote vc to connect to')
    parser.add_argument('-u', '--username', required=True,
                        action='store', help='Username for vc')
    parser.add_argument('-p', '--password', required=False,
                        action='store', help='Password for vc')
    parser.add_argument('-i', '--datacenter_name', required=True,
                        action='store', help='id_ of Datacenter name')
    args = parser.parse_args()
    return args


def main():

    import vmware.vsphere.vc.vc_facade as vc_facade
    import vmware.vsphere.vc.datacenter.datacenter_facade as datacenter_facade
    import vmware.common.global_config as global_config

    pylogger = global_config.pylogger

    args = GetArgs()
    password = args.password
    vc = args.vc
    username = args.username
    id_ = args.datacenter_name

    v_c = vc_facade.VCFacade(vc, username, password)
    # v_c = vc_facade.VCFacade("10.144.138.57", "root", "vmware")

    dc = datacenter_facade.DatacenterFacade(parent=v_c, name=id_)

    result = dc.delete()
    pylogger.info("Operation result = %r" % result)

if __name__ == "__main__":
    main()
