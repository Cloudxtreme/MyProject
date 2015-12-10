import vmware.base.driver as driver
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.ui_driver.ui.ui_driver_ui_client\
    as ui_driver_ui_client

pylogger = global_config.pylogger


class UIDriverFacade(driver.Driver, base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.UI
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, ip=None, username=None, password=None,
                 build=None):
        super(UIDriverFacade, self).__init__(parent)
        self.nsx_manager_obj = parent
        self.ip = ip
        self.username = username
        self.password = password
        self.build = build

        # instantiate client objects
        if parent:
            ui_client = ui_driver_ui_client.UIDriverUIClient(
                parent=parent.get_client(constants.ExecutionType.UI))

            # Maintain the list of client objects.
            self._clients = {constants.ExecutionType.UI: ui_client}

    def get_ip(self):
        return self.ip
