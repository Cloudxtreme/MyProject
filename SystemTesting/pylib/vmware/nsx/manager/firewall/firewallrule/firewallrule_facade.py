import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.firewall.firewallrule.api.firewallrule_api_client as firewallrule_api_client  # noqa
import vmware.nsx.manager.firewall.firewallrule.firewallrule as firewallrule  # noqa


pylogger = global_config.pylogger


class FirewallRuleFacade(firewallrule.FirewallRule,
                         base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, id_=None):
        super(FirewallRuleFacade, self).__init__(parent=parent, id_=id_)

        # instantiate client objects
        api_client = firewallrule_api_client.FirewallRuleAPIClient(
            parent=parent.get_client(constants.ExecutionType.API),
            id_=id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client}
