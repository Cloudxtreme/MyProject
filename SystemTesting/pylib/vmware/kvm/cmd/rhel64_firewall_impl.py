import re

import vmware.linux.cmd.linux_firewall_impl as linux_firewall_impl


class RHEL64FirewallImpl(linux_firewall_impl.LinuxFirewallImpl):

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
        get_status_cmd = 'service iptables status'
        out = client_object.connection.request(
            get_status_cmd, strict=strict).response_data
        return not bool(re.search('Firewall is not running.', out))

    @classmethod
    def enable_global_firewall(cls, client_object, strict=None):
        """
        Enables the firewall.

        @type client_object: BaseClient
        @param client_object: Client object used to pass commands to the host.
        @type strict: bool
        @param strict: Boolean to specify if an exception should be raised
            when/if the command execution fails.
        @rtype: result.Result
        @return: Returns the Result object.
        """
        start_cmd = 'service iptables start'
        return client_object.connection.request(start_cmd, strict=strict)

    @classmethod
    def disable_global_firewall(cls, client_object, strict=None):
        """
        Disables the firewall.

        @type client_object: BaseClient
        @param client_object: Client object used to pass commands to the host.
        @type strict: bool
        @param strict: Boolean to specify if an exception should be raised
            when/if the command execution fails.
        @rtype: result.Result
        @return: Returns the Result object.
        """
        disable_cmd = 'service iptables stop'
        return client_object.connection.request(disable_cmd, strict=strict)

    @classmethod
    def save_firewall_rule(cls, client_object, strict=None):
        """
        Saves the firewall to survive the reboot.

        @type client_object: BaseClient
        @param client_object: Client object used to pass commands to the host.
        @type strict: bool
        @param strict: Boolean to specify if an exception should be raised
            when/if the command execution fails.
        @rtype: result.Result
        @return: Returns the Result object.
        """
        start_cmd = 'service iptables save'
        return client_object.connection.request(start_cmd, strict=strict)
