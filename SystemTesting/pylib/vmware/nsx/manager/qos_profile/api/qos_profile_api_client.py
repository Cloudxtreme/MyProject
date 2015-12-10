import vmware.nsx.manager.qos_profile.qos_profile as qos_profile
import vmware.nsx.manager.manager_client as manager_client


class QosProfileAPIClient(qos_profile.QosProfile,
                          manager_client.NSXManagerAPIClient):

    def __init__(self, id_=None, **kwargs):
        super(QosProfileAPIClient, self).__init__(**kwargs)
        self.id_ = id_
