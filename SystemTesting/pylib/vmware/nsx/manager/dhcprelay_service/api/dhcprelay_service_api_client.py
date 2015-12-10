import vmware.nsx.manager.dhcprelay_service.dhcprelay_service as dhcprelay_service  # noqa
import vmware.nsx.manager.manager_client as manager_client


class DHCPRelayServiceAPIClient(dhcprelay_service.DHCPRelayService,
                                manager_client.NSXManagerAPIClient):
    def __init__(self, parent=None, id_=None):
        super(DHCPRelayServiceAPIClient, self).__init__(parent=parent)
        self.id_ = id_
