import vmware.base.messaging as messaging
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.rabbitmq.cli.rabbitmq_messaging_cli_client\
    as rabbitmq_messaging_cli_client
pylogger = global_config.pylogger


class RabbitmqMessagingFacade(messaging.Messaging, base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.CLI
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None):
        super(RabbitmqMessagingFacade, self).__init__(parent)
        self.nsx_manager_obj = parent

        cli_client = rabbitmq_messaging_cli_client.RabbitmqMessagingCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI))

        self._clients = {constants.ExecutionType.CLI: cli_client}