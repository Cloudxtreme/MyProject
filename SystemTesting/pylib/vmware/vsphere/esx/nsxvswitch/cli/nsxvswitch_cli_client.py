import vmware.common.base_client as base_client
import vmware.common.global_config as global_config
import vmware.vsphere.esx.nsxvswitch.nsxvswitch as nsxvswitch
import vmware.vsphere.esx.esx_client as esx_cli_client

class NSXVSwitchCLIClient(nsxvswitch.NSXVSwitch, esx_cli_client.ESXCLIClient):

    def __init__(self, parent=None, **kwargs):
        super(NSXVSwitchCLIClient, self).__init__(parent=parent)

