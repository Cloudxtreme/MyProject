import vmware.nsx.manager.qos_profile.qos_profile as qos_profile
import vmware.nsx.manager.manager_client as manager_client


class QosProfileUIClient(qos_profile.QosProfile,
                         manager_client.NSXManagerUIClient):

    def __init__(self, id_=None, **kwargs):
        super(QosProfileUIClient, self).__init__(**kwargs)
        self.id_ = id_
