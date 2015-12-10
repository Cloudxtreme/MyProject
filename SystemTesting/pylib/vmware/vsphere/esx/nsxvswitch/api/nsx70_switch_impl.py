import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.common.result as result
from vmware.interfaces.switch_interface import SwitchInterface

pylogger = global_config.pylogger


class SwitchAPIImpl(SwitchInterface):

    @classmethod
    def configure_uplinks(cls, operation=None, uplinks=None):
        # This is where the implementation will reside
        raise NotImplementedError("STUB")
