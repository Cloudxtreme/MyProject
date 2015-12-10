import vmware.common.base_client as base_client
import vmware.common.constants as constants
import vmware.common.path as path
import vmware.base.switch as switch
import vmware.vsphere.esx.nsxvswitch.cli.nsxvswitch_cli_client as nsxvswitch_cli_client
import vmware.common.base_facade as base_facade
import vmware.interfaces.labels as labels
import vmware.common.global_config as global_config


pylogger = global_config.pylogger
auto_resolve = base_facade.auto_resolve

CLI = constants.ExecutionType.CLI

class NSXVSwitchFacade(switch.Switch, base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.CLI
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(NSXVSwitchFacade, self).__init__()
        # NSX Switch may have different version
        # as compared to ESX, becuase ESX version
        # is tied to VSPHERE. The version for NSX
        # and ESX are asynced
        cli_client = nsxvswitch_cli_client.NSXVSwitchCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))
        self._clients = {constants.ExecutionType.CLI: cli_client}

    @auto_resolve(labels.SWITCH)
    def configure_uplinks(self, operation=None, uplink=None):
        execution_type=constants.ExecutionType.API
        pass
