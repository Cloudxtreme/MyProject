import vmware.nsx.manager.ipdiscovery_profile.ipdiscovery_profile as ipdiscovery_profile  # noqa
import vmware.nsx.manager.manager_client as manager_client


class IPDiscoveryProfileAPIClient(ipdiscovery_profile.IPDiscoveryProfile,
                                  manager_client.NSXManagerAPIClient):

    def __init__(self, id_=None, **kwargs):
        super(IPDiscoveryProfileAPIClient, self).__init__(**kwargs)
        self.id_ = id_
