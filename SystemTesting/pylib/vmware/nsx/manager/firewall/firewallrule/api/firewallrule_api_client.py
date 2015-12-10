import vmware.nsx.manager.firewall.firewallrule.firewallrule as firewallrule  # noqa
import vmware.nsx.manager.manager_client as manager_client


class FirewallRuleAPIClient(firewallrule.FirewallRule,
                            manager_client.NSXManagerAPIClient):
    pass