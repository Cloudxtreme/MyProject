import collections
import re

import vmware.common.utilities as utilities
import vmware.interfaces.firewall_interface as firewall_interface


# TODO(Salman): Update doc strings.
class LinuxFirewallImpl(firewall_interface.FirewallInterface):
    """Firewall implementation class for linux."""
    # iptable tables
    IPTABLE_FILTER_TABLE = 'filter'
    # iptable chains
    IPTABLE_INPUT_CHAIN = 'INPUT'
    ENABLE = 'enable'
    DISABLE = 'disable'
    ADD = 'add'
    REMOVE = 'remove'
    SAVE = 'save'

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
        """
        status_to_func = {cls.ENABLE: cls.enable_global_firewall,
                          cls.DISABLE: cls.disable_global_firewall,
                          cls.SAVE: cls.save_firewall_rule}
        if firewall_status not in status_to_func:
            raise ValueError('Can only enable/disable/save firewall, got %r'
                             'as firewall_status' % firewall_status)
        return status_to_func[firewall_status](client_object, strict=strict)

    @classmethod
    def configure_firewall_rule(cls, client_object, rule_operation=None,
                                table=None, chain_action=None,
                                chain=None, new_chain=None, rule_num=None,
                                protocol=None, protocol_options=None,
                                source=None, destination_ip=None, action=None,
                                goto=None, in_interface=None,
                                out_interface=None, fragment=None,
                                set_counters=None, packets=None,
                                bytes_=None, match_extensions=None,
                                target=None, opts=None, strict=None):
        """
        Adds or removes a firewall rule as specified by rule_operation.

        @type client_object: BaseClient
        @param client_object: Client object used to pass commands to the host.
        @type table: str
        @param table: Name of the table in which to insert the rule (e.g
            'filter', 'nat', 'mangle', 'raw', 'security'). Defaults to
            'filter'.
        @type chain_action: str
        @param aciton: Defines the chain_action to be performed on a chain
            (e.g. '-P' for setting a policy on the chain or '-E' to rename a
            chain)
        @type chain: str
        @param chain: Name of the chain on which chain_action will be
            performed (e.g. 'INPUT', 'FORWARD' or 'OUTPUT'). Defaults to
            'INPUT'.
        @type new_chain: str
        @param new_chain: New name for the chain, if chain is being renamed.
        @type rule_num: str
        @param rule_num: Rule number
        @type protocol: str
        @param protocol: Protocol of the rule or packet to be checked.
        @type protocol_options: dict
        @param protocol_options: Map from opt to value that can be used to
            configure a rule (e.g. for tcp protocol, we can use
            {'--dport': 9999})
        @type source: str
        @param source: Source IP address/mask for the rule.
        @type destination_ip: str
        @param destination_ip: Destination IP address/mask for the rule.
        @type action: str
        @param action: Decision for a matching packet (e.g. 'ACCEPT'). It can
            also be a user defined chain.
        @type goto: str
        @param goto: Name of the chain in which the processing should take
            place.
        @type in_interface: str
        @param in_interface: Name of the interface on which packet is received.
        @type out_interface: str
        @param out_interface: Name of the interface via which packet will be
            sent out.
        @type fragment: bool
        @param fragment: Creates rules for second and further packets for a
            fragmented packets.
        @type set_counters: bool
        @param set_counters: Flags if we need to set the counters.
        @type packets: int
        @param packets: The number to which packet counter needs to be set.
        @type bytes_: int
        @param bytes_: The number to which the byte counter needs to be set.
        @type match_extensions: dict
        @param match_extensions: Map of map, where the outer dict is used to
            index the extension module to load. The inner dict contains the
            key-value pair of options pertaining to that match extension
            module (e.g. {'comment': {'--comment': 'Doctest rule'})
        @type target: str
        @param target: The policy target for a chain.
        @type opts: list
        @param opts: List of extra options that user wants to pass.
        @type strict: bool
        @param strict: Boolean to specify if an exception should be raised
            when/if the command execution fails.
        @rtype: str
        @return: Returns the stdout after running the command.
        """
        operation_to_func = {cls.ADD: cls.add_firewall_rule,
                             cls.REMOVE: cls.delete_firewall_rule}
        if rule_operation not in operation_to_func:
            raise ValueError('Can only add/remove a firewall rule, got %r as '
                             'rule_operation' % rule_operation)
        return operation_to_func[rule_operation](
            client_object, table=table, chain=chain, new_chain=new_chain,
            rule_num=rule_num, protocol=protocol,
            protocol_options=protocol_options,
            source=source, destination_ip=destination_ip, action=action,
            goto=goto, in_interface=in_interface, out_interface=out_interface,
            fragment=fragment, set_counters=set_counters, packets=packets,
            bytes_=bytes_, match_extensions=match_extensions, target=target,
            opts=opts, strict=strict)

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
        get_status_cmd = 'ufw status'
        out = client_object.connection.request(
            get_status_cmd, strict=strict).response_data
        return not bool(re.search('inactive.', out))

    @classmethod
    def enable_global_firewall(cls, client_object, strict=None):
        """
        Enables the firewall.

        @type client_object: BaseClient
        @param client_object: Client object used to pass commands to the host.
        @type strict: bool
        @param strict: Boolean to specify if an exception should be raised
            when/if the command execution fails.
        @rtype: str
        @return: Returns the stdout after running the command.
        """
        start_cmd = 'ufw enable'
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
        @rtype: str
        @return: Returns the stdout after running the command.
        """
        disable_cmd = 'ufw disable'
        return client_object.connection.request(disable_cmd, strict=strict)

    @classmethod
    def add_firewall_rule(cls, client_object, table=None, chain_action=None,
                          chain=None, new_chain=None, rule_num=None,
                          protocol=None, protocol_options=None, source=None,
                          destination_ip=None, action=None, goto=None,
                          in_interface=None, out_interface=None,
                          fragment=None, set_counters=None, packets=None,
                          bytes_=None, match_extensions=None, target=None,
                          opts=None, strict=None):
        """
        Inserts a rule to an iptable chain.

        @type client_object: BaseClient
        @param client_object: Client object used to pass commands to the host.
        @type table: str
        @param table: Name of the table in which to insert the rule (e.g
            'filter', 'nat', 'mangle', 'raw', 'security'). Defaults to
            'filter'.
        @type chain_action: str
        @param aciton: Defines the chain_action to be performed on a chain
            (e.g. '-P' for setting a policy on the chain or '-E' to rename a
            chain)
        @type chain: str
        @param chain: Name of the chain on which chain_action will be
            performed (e.g. 'INPUT', 'FORWARD' or 'OUTPUT'). Defaults to
            'INPUT'.
        @type new_chain: str
        @param new_chain: New name for the chain, if chain is being renamed.
        @type rule_num: str
        @param rule_num: Rule number
        @type protocol: str
        @param protocol: Protocol of the rule or packet to be checked.
        @type protocol_options: dict
        @param protocol_options: Map from opt to value that can be used to
            configure a rule (e.g. for tcp protocol, we can use
            {'--dport': 9999})
        @type source: str
        @param source: Source IP address/mask for the rule.
        @type destination_ip: str
        @param destination_ip: Destination IP address/mask for the rule.
        @type action: str
        @param action: Decision for a matching packet (e.g. 'ACCEPT'). It can
            also be a user defined chain.
        @type goto: str
        @param goto: Name of the chain in which the processing should take
            place.
        @type in_interface: str
        @param in_interface: Name of the interface on which packet is received.
        @type out_interface: str
        @param out_interface: Name of the interface via which packet will be
            sent out.
        @type fragment: bool
        @param fragment: Creates rules for second and further packets for a
            fragmented packets.
        @type set_counters: bool
        @param set_counters: Flags if we need to set the counters.
        @type packets: int
        @param packets: The number to which packet counter needs to be set.
        @type bytes_: int
        @param bytes_: The number to which the byte counter needs to be set.
        @type match_extensions: dict
        @param match_extensions: Map of map, where the outer dict is used to
            index the extension module to load. The inner dict contains the
            key-value pair of options pertaining to that match extension
            module (e.g. {'comment': {'--comment': 'Doctest rule'})
        @type target: str
        @param target: The policy target for a chain.
        @type opts: list
        @param opts: List of extra options that user wants to pass.
        @type strict: bool
        @param strict: Boolean to specify if an exception should be raised
            when/if the command execution fails.
        @rtype: str
        @return: Returns the stdout after running the command.
        """
        cmd = cls._get_iptable_cmd(
            table=table, chain_action='-I', chain=chain, new_chain=new_chain,
            rule_num=rule_num, protocol=protocol,
            protocol_options=protocol_options,
            source=source, destination_ip=destination_ip, action=action,
            goto=goto, in_interface=in_interface,  out_interface=out_interface,
            fragment=fragment, set_counters=set_counters, packets=packets,
            bytes_=bytes_, match_extensions=match_extensions, target=target,
            opts=opts)
        return client_object.connection.request(cmd, strict=strict)

    @classmethod
    def delete_firewall_rule(cls, client_object, table=None, chain_action=None,
                             chain=None, new_chain=None, rule_num=None,
                             protocol=None, protocol_options=None, source=None,
                             destination_ip=None, action=None, goto=None,
                             in_interface=None, out_interface=None,
                             fragment=None, set_counters=None, packets=None,
                             bytes_=None, match_extensions=None, target=None,
                             opts=None, strict=None):
        """
        Deletes an iptable rule based on rule specification or rule number.

        @type client_object: BaseClient
        @param client_object: Client object used to pass commands to the host.
        @type table: str
        @param table: Name of the table in which to insert the rule (e.g
            'filter', 'nat', 'mangle', 'raw', 'security'). Defaults to
            'filter'.
        @type chain_action: str
        @param aciton: Defines the chain_action to be performed on a chain
            (e.g. '-P' for setting a policy on the chain or '-E' to rename a
            chain)
        @type chain: str
        @param chain: Name of the chain on which chain_action will be performed
            (e.g. 'INPUT', 'FORWARD' or 'OUTPUT'). Defaults to 'INPUT'.
        @type new_chain: str
        @param new_chain: New name for the chain, if chain is being renamed.
        @type rule_num: str
        @param rule_num: Rule number
        @type protocol: str
        @param protocol: Protocol of the rule or packet to be checked.
        @type protocol_options: dict
        @param protocol_options: Map from opt to value that can be used to
            configure a rule (e.g. for tcp protocol, we can use
            {'--dport': 9999})
        @type source: str
        @param source: Source IP address/mask for the rule.
        @type destination_ip: str
        @param destination_ip: Destination IP address/mask for the rule.
        @type action: str
        @param action: Decision for a matching packet (e.g. 'ACCEPT'). It can
            also be a user defined chain.
        @type goto: str
        @param goto: Name of the chain in which the processing should take
            place.
        @type in_interface: str
        @param in_interface: Name of the interface on which packet is received.
        @type out_interface: str
        @param out_interface: Name of the interface via which packet will be
            sent out.
        @type fragment: bool
        @param fragment: Creates rules for second and further packets for a
            fragmented packets.
        @type set_counters: bool
        @param set_counters: Flags if we need to set the counters.
        @type packets: int
        @param packets: The number to which packet counter needs to be set.
        @type bytes_: int
        @param bytes_: The number to which the byte counter needs to be set.
        @type match_extensions: dict
        @param match_extensions: Map of map, where the outer dict is used to
            index the extension module to load. The inner dict contains the
            key-value pair of options pertaining to that match extension
            module (e.g. {'comment': {'--comment': 'Doctest rule'})
        @type target: str
        @param target: The policy target for a chain.
        @type opts: list
        @param opts: List of extra options that user wants to pass.
        @type strict: bool
        @param strict: Boolean to specify if an exception should be raised
            when/if the command execution fails.
        @rtype: str
        @return: Returns the stdout after running the command.
        """
        cmd = cls._get_iptable_cmd(
            table=table, chain_action='-D', chain=chain, new_chain=new_chain,
            rule_num=rule_num, protocol=protocol,
            protocol_options=protocol_options,
            source=source, destination_ip=destination_ip, action=action,
            goto=goto, in_interface=in_interface,  out_interface=out_interface,
            fragment=fragment, set_counters=set_counters, packets=packets,
            bytes_=bytes_, match_extensions=match_extensions, target=target,
            opts=opts)
        return client_object.connection.request(cmd, strict=strict)

    @classmethod
    def _get_iptable_cmd(cls, table=None, chain_action=None, chain=None,
                         new_chain=None, rule_num=None, protocol=None,
                         protocol_options=None, source=None,
                         destination_ip=None, action=None, goto=None,
                         in_interface=None, out_interface=None, fragment=None,
                         set_counters=None, packets=None, bytes_=None,
                         match_extensions=None, target=None, opts=None):
        """
        Helper to get the iptables command.

        Arguments Notes:
            All arguments can be mapped one-one in arguments listed with
            commands in iptables man page. The only special options that can
            subsume other options in it are protocol_options and
            match_extensions.

            protocol_options only works when a protocol is specified. It is a
            map from the option related to that protocol and the value e.g.
            for protocol='tcp', protocol_options={'--dport': 5900} is valid.

            match_extensions is a map of maps, the key of the outer dict
            is the match extension module name e.g. 'comment' and 'icmp' etc.
            The keys of the inner dicts are the opts pertinent to that module
            and the corresponding value is the list of arguments that opt
            accepts.

        Note: The caller is responsible for passing in sane parameters and
        checking for any errors that may arise when executing the returned
        command.

        @type table: str
        @param table: Name of the table in which to insert the rule (e.g
            'filter', 'nat', 'mangle', 'raw', 'security'). Defaults to
            'filter'.
        @type chain_action: str
        @param aciton: Defines the chain_action to be performed on a chain
            (e.g. '-P' for setting a policy on the chain or '-E' to rename a
            chain)
        @type chain: str
        @param chain: Name of the chain on which chain_action will be
            performed (e.g. 'INPUT', 'FORWARD' or 'OUTPUT'). Defaults to
            'INPUT'.
        @type new_chain: str
        @param new_chain: New name for the chain, if chain is being renamed.
        @type rule_num: str
        @param rule_num: Rule number
        @type protocol: str
        @param protocol: Protocol of the rule or packet to be checked.
        @type protocol_options: dict
        @param protocol_options: Map from opt to value that can be used to
            configure a rule (e.g. for tcp protocol, we can use
            {'--dport': 9999})
        @type source: str
        @param source: Source IP address/mask for the rule.
        @type destination_ip: str
        @param destination_ip: Destination IP address/mask for the rule.
        @type action: str
        @param action: Decision for a matching packet (e.g. 'ACCEPT'). It can
            also be a user defined chain.
        @type goto: str
        @param goto: Name of the chain in which the processing should take
            place.
        @type in_interface: str
        @param in_interface: Name of the interface on which packet is received.
        @type out_interface: str
        @param out_interface: Name of the interface via which packet will be
            sent out.
        @type fragment: bool
        @param fragment: Creates rules for second and further packets for a
            fragmented packets.
        @type set_counters: bool
        @param set_counters: Flags if we need to set the counters.
        @type packets: int
        @param packets: The number to which packet counter needs to be set.
        @type bytes_: int
        @param bytes_: The number to which the byte counter needs to be set.
        @type match_extensions: dict
        @param match_extensions: Map of map, where the outer dict is used to
            index the extension module to load. The inner dict contains the
            key-value pair of options pertaining to that match extension
            module (e.g. {'comment': {'--comment': 'Doctest rule'})
        @type target: str
        @param target: The policy target for a chain.
        @type opts: list
        @param opts: List of extra options that user wants to pass.
        @rtype: str
        @return: Returns the formatted iptables command.
        """
        # TODO(Salman): Add support for negating the parameters.
        chain_action = utilities.get_default(chain_action, '-L')
        # Sanity checking.
        chain_actions = ('-A', '-D', '-I', '-R', '-P', '-E')
        new_chain_actions = ('-E',)
        rule_num_actions = ('-R',)
        not_rule_num_actions = ('-A', '-L', '-S', '-F')
        rule_spec_actions = ('-A',)
        not_rule_spec_actions = ('-L', '-S', '-F', '-Z',  '-N', '-X', '-P',
                                 '-E')
        rule_num_or_rule_spec_actions = ('-D',)
        all_actions = set(chain_actions + new_chain_actions + rule_num_actions
                          + not_rule_num_actions + rule_spec_actions +
                          not_rule_spec_actions +
                          rule_num_or_rule_spec_actions)
        rule_specifications = (protocol, source, destination_ip, action, goto,
                               in_interface, out_interface, set_counters,
                               protocol_options, match_extensions, target)
        rule_specified = filter(None, rule_specifications)
        if chain_action not in all_actions:
            raise ValueError('%r is not a valid chain_action' % chain_action)
        if chain_action in chain_actions and not chain:
            raise ValueError('Need to define a chain name with %r' %
                             chain_action)
        if chain_action in rule_num_actions and not rule_num:
            raise ValueError('Need to define a rule number with %r' %
                             chain_action)
        if chain_action in rule_spec_actions and not rule_specified:
            raise ValueError('Need to specify a rule with %r' % chain_action)
        rulenum_or_rule = ((rule_num and not rule_specified) or
                           (rule_specified and not rule_num))
        if ((chain_action in rule_num_or_rule_spec_actions and not
             rulenum_or_rule)):
            raise ValueError('Need to specify a rule number or rule '
                             'specification, not both, with %r' % chain_action)
        if chain_action in not_rule_num_actions and rule_num:
            raise ValueError('%r command does not accept rule number' %
                             chain_action)
        if chain_action in not_rule_spec_actions and rule_specified:
            raise ValueError('%r does not accept any rule specification, rule '
                             'specification provided: %r' %
                             (chain_action, rule_specifications))
        table = utilities.get_default(table, cls.IPTABLE_FILTER_TABLE)
        chain = utilities.get_default(chain, cls.IPTABLE_INPUT_CHAIN)
        protocol_options = utilities.get_default(protocol_options, {})
        cmd = ['iptables -t %s %s %s' % (table, chain_action, chain)]
        # Handle special cases where the second argument to be used with the
        # command can be different from rulenum and rule specifications.
        if chain_action == '-P':
            cmd.append(target)
            cmd.extend(opts)
            return ' '.join(cmd)
        if chain_action == '-E':
            cmd.append(new_chain)
            cmd.extend(opts)
            return ' '.join(cmd)
        if opts:
            cmd.extend(opts)
        if rule_num:
            cmd.append('%d' % rule_num)
        if protocol:
            cmd.append('-p %s' % protocol)
        if protocol_options and not protocol:
            protocol_options = {}
        if protocol_options:
            for opt, val in protocol_options.iteritems():
                if opt == 'destination_port':
                    cmd.append('--dport %s' % val)
                elif opt == 'source_port':
                    cmd.append('--sport %s' % val)
                else:
                    cmd.append('--%s %s' % (opt, val))
        if match_extensions:
            for match_ext in match_extensions:
                if not match_ext.endswith('_match_ext'):
                    raise ValueError('Need the match extension module names '
                                     'to end with "_match_ext", got %r' %
                                     match_ext)
                ext = ['-m %s' % match_ext.split("_match_ext")[0]]
                opts_dict = match_extensions[match_ext]
                opts_vals = [
                    '--%s "%s"' % (opt, ' '.join(utilities.as_list(val)))
                    for opt, val in opts_dict.iteritems()]
                cmd.extend(ext + opts_vals)
        if source:
            cmd.append('-s %s' % source)
        if destination_ip:
            cmd.append('-d %s' % destination_ip)
        if action:
            cmd.append('-j %s' % action)
        if goto:
            cmd.append('-g %s' % goto)
        if in_interface:
            cmd.append('-i %s' % in_interface)
        if out_interface:
            cmd.append('-o %s' % out_interface)
        if fragment:
            cmd.append('-f')
        if set_counters:
            if None in (packets, bytes_):
                raise ValueError('set_counters is set but packets or bytes '
                                 'have not been provided')
            cmd.append('-c %s %s' % (packets, bytes_))
        return ' '.join(cmd)

    @classmethod
    def list_firewall_rules(cls, client_object, prot=None, opt=None, in_=None,
                            out=None, source=None, destination_ip=None,
                            other=None, target=None, strict=None):
        """
        Searches for the iptable rule as defined by kwargs. If matching
        rules are found in a chain then the map from chain name to matching
        rule number and rule is returned.

        @type client_object: BaseClient
        @param client_object: Client object used to pass commands to the host.
        @type prot: str
        @param prot: Name of the protocol to match.
        @type opt: str
        @param opt: Options to match.
        @type in_: str
        @param in_: Ingressing interface to match.
        @type out: str
        @param out: Egressing interface to match.
        @type source: str
        @param source: Source IP/mask to match.
        @type destination_ip: str
        @param desintaion: Destination IP/mask to match.
        @type other: str
        @param other: Other information to match (This information is not
            categorized under any column in the iptables output)
        @type strict: bool
        @param strict: Boolean to specify if an exception should be raised
            when/if the command execution fails.
        @rtype: dict
        @return: Returns a map from the chain name to the rule specification.
           Here the rule specification part is composed of tuple composed of
           the rule number and a map from rule attributes to values.
        """
        iptables = cls._get_iptables(client_object, strict=strict)
        search_keys = []
        if prot:
            search_keys.append('prot')
        if opt:
            search_keys.append('opt')
        if in_:
            search_keys.append('in')
        if out:
            search_keys.append('out')
        if source:
            search_keys.append('source')
        if destination_ip:
            search_keys.append('destination')
        if other:
            search_keys.append('other')
        if target:
            search_keys.append('target')
        matching_rules = collections.defaultdict(list)
        for chain in iptables:
            for rule_num, rule in enumerate(iptables[chain]):
                existing_keys = [key for key in rule if key in search_keys]
                if set(existing_keys) != set(search_keys):
                    continue
                match = all([True if rule[key] == locals()[key] else False
                             for key in existing_keys])
                if match:
                    matching_rules[chain].append([rule_num + 1, rule])
        return matching_rules

    @classmethod
    def _get_iptables(cls, client_object, strict=None):
        """
        Get firewall information (iptables) running on the host. Saves into a
        dictionary. Top-level keys are Chain names, which give a list of rules,
        where every rule is a dictionary.

        @type client_object: BaseClient
        @param client_object: Client object used to pass commands to the host.
        @type strict: bool
        @param strict: Boolean to specify if an exception should be raised
            when/if the command execution fails.
        @rtype: dict
        @return: Map from the chain name to a list of dicts, where each dict in
            the list contains key-value pairs of attributes of a specific rule
            in that chain.
        """
        # The options to iptables are List, verbose to give us interfaces,
        # numeric to give IP addresses rather than host-names, x so the
        # counters aren't approximated (1000 rather than 1K, e.g.) and
        # line-numbers, which correspond to ACL rule_numbers
        cmd = 'iptables -L -v -n -x --line-numbers'
        chains = client_object.connection.request(
            cmd, strict=strict).response_data.split('\n\n')
        iptables_dict = {}
        for chain in chains:
            chain_name, rule_list = cls._parse_iptables_chain(chain)
            iptables_dict[chain_name] = rule_list
        return iptables_dict

    @classmethod
    def _parse_iptables_chain(cls, chain_string):
        """
        Helper function for _get_iptables

        Given a string of newline-separated lines, consumes and parses enough
        input to define exactly one iptables Chain. Returns a tuple with first
        element chain_name and second element a list of iptables rules.

        @type chain_string: str
        @param chain_string: The raw output of the listed iptables rules.
        @rtype: dict
        @return: Map from the chain name to a list of dicts, where each dict in
            the list contains key-value pairs of attributes of a specific rule
            in that chain.
        """
        # TODO get the above doctest working (Scott Walls)

        FIELDS = ['num', 'pkts', 'bytes', 'target', 'prot', 'opt', 'in',
                  'out', 'source', 'destination', 'other']
        lines = chain_string.split('\n')
        # The first line always looks like: 'Chain chain_name (somestuff)'
        # In the case of chain_name = '(evil chain_name)', the naive regex
        # I can think of trips up and consumes chain_name, so I parse by hand
        chain_removed = lines[0].split(' ', 1)[1]
        # This should be just the chain_name, with the parenthetical removed
        chain_name = chain_removed.rsplit(' (', 1)[0]
        rules = []
        # The second line is always just the titles of the columns
        for line in lines[2:]:
            # Make a dictionary with above fields for keys, and the line's
            # contents as values. What follows is kind of kludgey because
            # iptables uses variable-number spaces for separation. Chain names
            # with spaces in them would break this test, but not NVP.
            field_vals = line.split(None, len(FIELDS) - 1)
            if not field_vals:
                continue
            # Here's the kludge. Target can be blank, which shifts the whole
            # thing over by one. So, see if target comes up as any of the
            # acceptable targets. Otherwise, set it to a blank string
            allowable_targets = set(['INPUT', 'FORWARD', 'OUTPUT', 'TEMPORARY',
                                     'USERINPUT', 'USEROUTPUT', 'ACCEPT',
                                     'DROP', 'QUEUE', 'RETURN'])
            target_index = FIELDS.index('target')
            if not field_vals[target_index] in allowable_targets:
                field_vals.insert(target_index, '')
                # This also means that, if there was supposed to be an 'other'
                # field, that we've accidentally split it. We should, in that
                # case, have an above-normal number of fields
                if len(FIELDS) < len(field_vals):
                    other_index = FIELDS.index('other')
                    field_vals[other_index] = ' '.join(
                        [field_vals[other_index],
                         field_vals[other_index + 1]]
                    )
            field_vals = [field_val.strip() for field_val in field_vals]
            rules.append(dict(zip(FIELDS, field_vals)))
        return (chain_name, rules)

    @classmethod
    def enable_firewall_ruleset(cls, client_object):
        raise NotImplementedError

    @classmethod
    def disable_firewall_ruleset(cls, client_object):
        raise NotImplementedError

    @classmethod
    def get_firewall_rule_status(cls, client_object):
        raise NotImplementedError
