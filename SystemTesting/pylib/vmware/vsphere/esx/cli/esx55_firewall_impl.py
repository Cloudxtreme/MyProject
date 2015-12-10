import re

import vmware.interfaces.firewall_interface as firewall_interface


class ESX55FirewallImpl(firewall_interface.FirewallInterface):
    """Firewall implementation class for ESX."""

    ENABLE = 'enable'
    DISABLE = 'disable'

    @classmethod
    def configure_firewall(cls, client_object, firewall_status=None,
                           strict=None):
        """
        Enables/Disables the firewall.

        @type firewall_status: str
        @param firewall_status: Specifices whether to enable or disable the
            firewall.
        @type strict: bool
        @param strict: Boolean to specify if an exception should be raised
            when/if the command execution fails.
        @rtype: bool
        @return: Returns True if the operation is successful else False.
        """
        status_to_func = {cls.ENABLE: cls.enable_global_firewall,
                          cls.DISABLE: cls.disable_global_firewall}
        if firewall_status not in status_to_func:
            raise ValueError('Can only enable/disable firewall, got %r as '
                             'firewall_status' % firewall_status)
        return status_to_func[firewall_status](client_object, strict=strict)

    @classmethod
    def configure_firewall_rule(cls, client_object, rule_operation=None,
                                ruleset=None, strict=None):
        """
        Enable or diable a firewall ruleset as specified by rule_operation.

        @type client_object: BaseClient
        @param client_object: Client object used to pass commands to the host.
        @type strict: bool
        @param strict: Boolean to specify if an exception should be raised
            when/if the command execution fails.
        @rtype: bool
        @return: Returns True if the operation is successful else False.
        """
        operation_to_func = {cls.ENABLE: cls.enable_firewall_ruleset,
                             cls.DISABLE: cls.disable_firewall_ruleset}
        if rule_operation not in operation_to_func:
            raise ValueError('Can only enable/disable a firewall ruleset, '
                             'got %r as rule_operation' % rule_operation)

        return operation_to_func[rule_operation](client_object,
                                                 ruleset=ruleset,
                                                 strict=strict)

    @classmethod
    def get_global_firewall_status(cls, client_object, strict=None):
        """
        Gets the status of the firewall.

        @type client_object: BaseClient
        @param client_object: Client object used to pass commands to the host.
        @type strict: bool
        @param strict: Boolean to specify if an exception should be raised
            when/if the command execution fails.
        @rtype: bool
        @return: Returns True if firewall is active else False.
        """
        get_status_cmd = 'esxcli network firewall get'
        out = client_object.connection.request(get_status_cmd, strict=strict)
        return bool(re.search(r'(?im)Enabled: true', out.response_data))

    @classmethod
    def enable_global_firewall(cls, client_object, strict=None):
        """
        Enables the firewall.

        @type client_object: BaseClient
        @param client_object: Client object used to pass commands to the host.
        @type strict: bool
        @param strict: Boolean to specify if an exception should be raised
            when/if the command execution fails.
        @rtype: bool
        @return: Returns True if firewall is enabled else False.
        """
        enable_cmd = 'esxcli network firewall set -e true'
        client_object.connection.request(enable_cmd, strict=strict)
        return cls.get_global_firewall_status(client_object, strict=strict)

    @classmethod
    def disable_global_firewall(cls, client_object, strict=None):
        """
        Disables the firewall.

        @type client_object: BaseClient
        @param client_object: Client object used to pass commands to the host.
        @type strict: bool
        @param strict: Boolean to specify if an exception should be raised
            when/if the command execution fails.
        @rtype: bool
        @return: Returns True if firewall is disabled else False.
        """
        disable_cmd = 'esxcli network firewall set -e false'
        client_object.connection.request(disable_cmd, strict=strict)
        return not cls.get_global_firewall_status(client_object, strict=strict)

    @classmethod
    def enable_firewall_ruleset(cls, client_object, ruleset=None, strict=None):
        """
        Enable a ruleset on the ESX.
        @type client_object: BaseClient
        @param client_object: Client object used to pass commands to the host.
        @type ruleset: str
        @param ruleset: Name of the ruleset (e.g 'netCP', 'rabbitmqproxy')
        @type strict: bool
        @param strict: Boolean to specify if an exception should be raised
            when/if the command execution fails.
        @rtype: bool
        @return: Returns True if ruleset is enabled else False.
        """
        enable_cmd = 'esxcli network firewall ruleset \
                       set -e true -r %s' % ruleset
        client_object.connection.request(enable_cmd, strict=strict)
        return cls.get_firewall_ruleset_status(client_object, ruleset=ruleset,
                                               strict=strict)

    @classmethod
    def disable_firewall_ruleset(cls, client_object, ruleset=None,
                                 strict=None):
        """
        Disable a ruleset on the ESX.
        @type client_object: BaseClient
        @param client_object: Client object used to pass commands to the host.
        @type ruleset: str
        @param ruleset: Name of the ruleset (e.g 'netCP', 'rabbitmqproxy')
        @type strict: bool
        @param strict: Boolean to specify if an exception should be raised
            when/if the command execution fails.
        @rtype: bool
        @return: Returns True if ruleset is disabled else False.
        """
        disable_cmd = 'esxcli network firewall ruleset \
                        set -e false -r %s' % ruleset
        client_object.connection.request(disable_cmd, strict=strict)
        return not cls.get_firewall_ruleset_status(
            client_object, ruleset=ruleset, strict=strict)

    @classmethod
    def get_firewall_ruleset_status(cls, client_object, ruleset=None,
                                    strict=None):
        """
        Get status of a ruleset on the ESX.
        @type client_object: BaseClient
        @param client_object: Client object used to pass commands to the host.
        @type ruleset: str
        @param ruleset: Name of the ruleset (e.g 'netCP', 'rabbitmqproxy')
        @type strict: bool
        @param strict: Boolean to specify if an exception should be raised
            when/if the command execution fails.
        @rtype: bool
        @return: True if ruleset is enabled else False.
        """
        get_status_cmd = \
            'esxcli network firewall ruleset list | grep %s' % ruleset
        out = client_object.connection.request(get_status_cmd, strict=strict)
        return bool(re.search(r'true', out.response_data))
