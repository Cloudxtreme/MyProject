import vmware.nsx.manager.qos_profile.qos_profile as qos_profile
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.common.versions as versions
import vmware.nsx.manager.qos_profile.api.qos_profile_api_client as qos_profile_api_client  # noqa
import vmware.nsx.manager.qos_profile.ui.qos_profile_ui_client as qos_profile_ui_client  # noqa


pylogger = global_config.pylogger


class QosProfileFacade(qos_profile.QosProfile, base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE

    def __init__(self, parent=None):
        super(QosProfileFacade, self).__init__(parent=parent)
        self.nsx_manager_obj = parent

        api_client = qos_profile_api_client.QosProfileAPIClient(
            parent=parent.get_client(constants.ExecutionType.API))

        ui_client = qos_profile_ui_client.QosProfileUIClient(
            parent=parent.get_client(constants.ExecutionType.UI))

        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.UI: ui_client}
