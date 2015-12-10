"""Interface class to implement firewall related operations."""


class FirewallInterface(object):

    @classmethod
    def configure_firewall(cls, client_object, firewall_status=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def configure_firewall_rule(csl, client_object, rule_operation=None,
                                **kwargs):
        raise NotImplementedError

    @classmethod
    def get_global_firewall_status(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def enable_global_firewall(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def disable_global_firewall(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def add_firewall_rule(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def delete_firewall_rule(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def list_firewall_rules(cls, client_object, **kwargs):
        raise NotImplementedError

    # XXX ESX Only
    @classmethod
    def enable_firewall_ruleset(cls, client_object, **kwargs):
        raise NotImplementedError

    # XXX ESX Only
    @classmethod
    def disable_firewall_ruleset(cls, client_object, **kwargs):
        raise NotImplementedError

    # XXX ESX Only
    @classmethod
    def get_firewall_ruleset_status(cls, client_object, **kwargs):
        raise NotImplementedError

    @classmethod
    def network_partitioning(cls, client_object, **kwargs):
        """ Isolate target ip from current device """
        raise NotImplementedError
