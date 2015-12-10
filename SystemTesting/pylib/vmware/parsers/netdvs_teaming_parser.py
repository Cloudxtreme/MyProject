import re


class TeamingParser(object):
    """Parse net-dvs table and get logical port information."""

    @staticmethod
    def get_parsed_data(raw_data):
        r"""
        @param raw_data output from the CLI execution result

        @rtype: dict
        @return: a map of teaming data
        """

        PORT = "port"
        PORT_RE = r"\s+port (\S+):.*"
        TEAMING = "teaming"
        TEAMING_RE = r"\s+com.vmware.etherswitch.port.teaming:"
        LOAD_BALANCING = "load_balancing"
        LOAD_BALANCING_RE = r"\s+load balancing = (.*)"
        LINK_SELECTION = "link_selection"
        LINK_SELECTION_RE = r"\s+link selection = (.*)"
        LINK_BEHAVIOR = "link_behavior"
        LINK_BEHAVIOR_RE = r"\s+link behavior = (.*)"
        ACTIVE = "active"
        ACTIVE_RE = r"\s+active = (.*)"
        STANDBY = "standby"
        STANDBY_RE = r"\s+standby = (.*)"
        PROPTYPE_RE = r"\s+propType = (.*)"

        parsed_data = {}
        lines = raw_data.strip().split("\n")

        port_dicts = []
        port_dict = None
        port = None  # current record during parse
        state = PORT
        for line in lines:
            # Ignore all global, host, and other non-port properties. Include
            # all ports regardless of switch association.
            m = re.match(PORT_RE, line)
            if m:
                # New port match found, create new record.
                port = m.group(1)
                if port_dict:
                    port_dicts.append(port_dict)
                port_dict = {}
                port_dict[PORT] = port
                state = PORT
                continue
            # No port found, keep looking.
            if not port:
                continue
            if state == PORT:
                m = re.match(TEAMING_RE, line)
                if m:
                    state = TEAMING
                    continue
            elif state == TEAMING:
                m = re.match(LOAD_BALANCING_RE, line)
                if m:
                    port_dict[LOAD_BALANCING] = m.group(1)
                    continue
                m = re.match(LINK_SELECTION_RE, line)
                if m:
                    port_dict[LINK_SELECTION] = m.group(1)
                    continue
                m = re.match(LINK_BEHAVIOR_RE, line)
                if m:
                    port_dict[LINK_BEHAVIOR] = m.group(1)
                    continue
                m = re.match(ACTIVE_RE, line)
                if m:
                    port_dict[ACTIVE] = m.group(1)
                    continue
                m = re.match(STANDBY_RE, line)
                if m:
                    port_dict[STANDBY] = m.group(1)
                    continue
                m = re.match(PROPTYPE_RE, line)
                if m:
                    state = PORT
                    continue
        if port_dict:
            port_dicts.append(port_dict)

        parsed_data = {'table': port_dicts}
        return parsed_data

if __name__ == '__main__':
    import doctest
    doctest_opts = (doctest.ELLIPSIS | doctest.NORMALIZE_WHITESPACE)
    doctest.testmod(optionflags=doctest_opts)
