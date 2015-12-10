import vmware.torgateway.tor_switch.tor_switch as tor_switch
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.torgateway.tor_switch.cmd.tor_switch_cmd_client as \
    tor_switch_cmd_client

pylogger = global_config.pylogger
auto_resolve = base_facade.auto_resolve


class TORSwitchFacade(tor_switch.TORSwitch, base_facade.BaseFacade):
    """TOR Switch facade class"""

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.CMD

    def __init__(self, parent=None, id=None):
        super(TORSwitchFacade, self).__init__(parent=parent, name=id)
        self.parent = parent
        self.id = id

        # instantiate client objects.
        cmd_client = tor_switch_cmd_client.TORSwitchCMDClient(
            parent=parent.get_client(constants.ExecutionType.CMD), id=id)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.CMD: cmd_client}

    def get_switch_name(self):
        return self.id

    def get_name(self):
        return self.id
