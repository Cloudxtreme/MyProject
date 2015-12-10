import vmware.base.messaging as messaging
import vmware.nsx.manager.manager_client as manager_client


class RabbitmqMessagingCLIClient(messaging.Messaging,
                                 manager_client.NSXManagerCLIClient):

    def __init__(self, parent=None):
        super(RabbitmqMessagingCLIClient, self).__init__(parent=parent)
