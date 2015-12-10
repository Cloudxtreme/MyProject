import vmware.nsx.manager.dhcprelay_profile.dhcprelay_profile as dhcprelay_profile  # noqa
import vmware.nsx.manager.manager_client as manager_client


class DHCPRelayProfileAPIClient(dhcprelay_profile.DHCPRelayProfile,
                                manager_client.NSXManagerAPIClient):
    def __init__(self, parent=None, id_=None):
        super(DHCPRelayProfileAPIClient, self).__init__(parent=parent)
        self.id_ = id_