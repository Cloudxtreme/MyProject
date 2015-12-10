import vmware.nsx.manager.firewall.firewallsection.firewallsection as firewallsection  # noqa
import vmware.nsx.manager.manager_client as manager_client


class FirewallSectionAPIClient(firewallsection.FirewallSection,
                               manager_client.NSXManagerAPIClient):
    pass