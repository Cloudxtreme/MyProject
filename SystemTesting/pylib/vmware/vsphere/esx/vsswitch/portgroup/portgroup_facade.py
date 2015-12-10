import argparse
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.vsphere.esx.vsswitch.portgroup.portgroup as portgroup
import vmware.vsphere.esx.vsswitch.portgroup.api.portgroup_api_client as portgroup_api_client  # noqa


class PortgroupFacade(portgroup.Portgroup, base_facade.BaseFacade):

    """Portgroup client class to initiate Portgroup operations."""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, name=None):
        super(PortgroupFacade, self).__init__(name, parent=parent)
        self.parent = parent
        # instantiate client objects
        api_client = portgroup_api_client.PortgroupAPIClient(
            name, parent=parent.clients.get(constants.ExecutionType.API))
        # Maintain the dictionary of client objects.
        # This will later be used by initialize() to create
        # connection anchors
        self._clients = {constants.ExecutionType.API: api_client}


def GetArgs():
    """
    Supportgroups the command-line arguments listed below.
    """

    parser = argparse.ArgumentParser(description='Portgroup Client')
    parser.add_argument('-s', '--host', required=True,
                        action='store', help='Remote host to connect to')
    parser.add_argument('-u', '--username', required=True,
                        action='store', help='Username for host')
    parser.add_argument('-p', '--password', required=False,
                        action='store', help='Password for host')
    parser.add_argument('-i', '--portgroup_id', required=True,
                        action='store', help='id_ of Portgroup to power on')
    args = parser.parse_args()
    return args


def main():

    import vmware.vsphere.esx.esx_facade as esx_facade
    import vmware.vsphere.esx.vsswitch.vsswitch_facade as vsswitch_facade
    import vmware.common.global_config as global_config
    import vmware.vsphere.esx.vsswitch.portgroup.portgroup_facade as portgroup_facade  # noqa

    pylogger = global_config.pylogger

    hv = esx_facade.ESXFacade(ip="10.144.139.194",
                              username="root", password="ca$hc0w")

    vss = vsswitch_facade.VSSwitchFacade(name="vSwitch1", parent=hv)

    pg = portgroup_facade.PortgroupFacade(name="VM Network 2", parent=vss)

    result = pg.edit_traffic_shaping(enabled=True, avg_bandwidth=100000,
                                     peak_bandwidth=100000, burst_size=102400)
    pylogger.info("Operation result = %r" % result)

if __name__ == "__main__":
    main()
