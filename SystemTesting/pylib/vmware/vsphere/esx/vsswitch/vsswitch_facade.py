import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.vsphere.esx.vsswitch.vsswitch as vsswitch
import vmware.vsphere.esx.vsswitch.api.vsswitch_api_client as vsswitch_api_client  # noqa


class VSSwitchFacade(vsswitch.VSSwitch, base_facade.BaseFacade):
    """VSSwitch client class to initiate VSSwitch operations."""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, name=None):
        super(VSSwitchFacade, self).__init__()
        self.parent = parent
        # instantiate client objects
        api_client = vsswitch_api_client.VSSwitchAPIClient(
            name, parent=parent.clients.get(constants.ExecutionType.API))
        # Maintain the dictionary of client objects.
        # This will later be used by initialize() to create
        # connection anchors
        self._clients = {constants.ExecutionType.API: api_client}


def GetArgs():
    """
    Supports the command-line arguments listed below.
    """
    import argparse

    parser = argparse.ArgumentParser(description='VSSwitch Client')
    parser.add_argument('-s', '--esx', required=True,
                        action='store', help='Remote host to connect to')
    parser.add_argument('-u', '--username', required=True,
                        action='store', help='Username for host')
    parser.add_argument('-p', '--password', required=False,
                        action='store', help='Password for host')
    parser.add_argument('-i', '--vsswitch_name', required=True,
                        action='store', help='id_ of VSSwitch to power on')
    args = parser.parse_args()
    return args


def main():

    import vmware.vsphere.esx.esx_facade as esx_facade
    import vmware.vsphere.esx.vsswitch.vsswitch_facade as vsswitch_facade
    import vmware.common.global_config as global_config

    pylogger = global_config.pylogger

    hv = esx_facade.ESXFacade("10.144.138.189", "root", "ca$hc0w")

    vss = vsswitch_facade.VSSwitchFacade(name="vSwitch0", parent=hv)

    result = vss.read()
    pylogger.info("Operation result = %r" % result)

if __name__ == "__main__":
    main()
