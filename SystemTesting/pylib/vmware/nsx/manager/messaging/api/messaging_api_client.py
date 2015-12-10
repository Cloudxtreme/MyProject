import vmware.base.messaging as messaging
import vmware.nsx.manager.manager_client as manager_client


class MessagingAPIClient(messaging.Messaging,
                         manager_client.NSXManagerAPIClient):

    def __init__(self, parent=None, id_=None):
        super(MessagingAPIClient, self).__init__(parent=parent)
        self.id_ = id_