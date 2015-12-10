import re
import vmware.common.global_config as global_config
pylogger = global_config.pylogger


class ShowInterfaceParser:
    """
    Class for parsing the data received from "show interface"
    command executed on NSX Edge VM
    >>> import pprint
    >>> show_interface = ShowInterfaceParser()
    >>> raw_data= '''vShield-edge-1-0> show interface vNic_7
    ... Interface vNic_7 is up, line protocol is down
    ...  index 12 metric 1 mtu 1500 <UP,BROADCAST,RUNNING,MULTICAST>
    ...  HWaddr: 00:50:56:a4:ca:ea
    ...  inet 172.16.55.1/24
    ...  inet 172.16.56.3/24
    ...  inet 127.0.0.1/24
    ...  inet6 fe80::250:56ff:fea4:ac/64
    ...  inet6 fe80::250:56ff:fea4:accf/64
    ...  proxy_arp: disabled
    ...  Auto-duplex (Full), Auto-speed (1399Mb/s)
    ...  input packets 0, bytes 0, dropped 0, multicast packets 0
    ...  input errors 0, length 0, overrun 0, CRC 0, frame 0, fifo 0, missed 0
    ...  output packets 6, bytes 492, dropped 0
    ...  output errors 0, aborted 0, carrier 0, fifo 0, heartbeat 0, window 0
    ...  collisions 0
    ... vShield-edge-1-0>'''
    >>> py_dict=show_interface.get_parsed_data(raw_data)
    >>> pprint.pprint(py_dict)
        {'hwaddr': '00:50:56:a4:ca:ea',
        'ip4': ['172.16.55.1', '172.16.56.3', '127.0.0.1'],
        'ip6': ['fe80::250:56ff:fea4:ac', 'fe80::250:56ff:fea4:accf'],
        'vnic_state': 'up'}
    """

    DEFAULT_DELIMITER = ' '
    IP4_KEY = 'ip4'
    IP6_KEY = 'ip6'
    MAC_ADDR_KEY = 'hwaddr'
    VNIC_STATE_KEY = 'vnic_state'

    def get_parsed_data(self, input, delimiter=None):
        '''
        @param raw_data output from the CLI execution result
        @param delimiter character to split the key and value

        @rtype: dict
        @return: calling the get_parsed_data function will return a hash
                 based on above sample, the return data
        will be:
            {'hwaddr': '00:50:56:a4:ca:ea',
            'ip4': ['172.16.55.1', '172.16.56.3', '127.0.0.1'],
            'ip6': ['fe80::250:56ff:fea4:ac', 'fe80::250:56ff:fea4:accf'],
            'vnic_state': 'up'}
        '''

        if delimiter is None:
            delimiter = self.DEFAULT_DELIMITER

        # TODO: Should be moving the regex to common regexutils library
        # tested 'inet%s' % regex_utils.ip but its not working
        ip4_regex = "inet\s+(\d+\.\d+\.\d+\.\d+)"
        list_of_ip4_ips = re.findall(ip4_regex, input, re.IGNORECASE)

        # TODO: Should be moving the regex to common regexutils library
        ip6_regex = "inet6\s+([\w+,':']*)"
        list_of_ip6_ips = re.findall(ip6_regex, input, re.IGNORECASE)

        # get mac address
        mac_regex = "HWaddr:\s+(([\w]{2}[:-]){5}([\w]{2}))"
        match = re.search(mac_regex, input, re.IGNORECASE)
        if match:
            mac = match.group(1)
        else:
            pylogger.warn("No match found for hwaddr address. Using None.")
            mac = None

        # Interface Status Regex
        interface_status_regex = "Interface.*is\s+(up|down),"
        match = re.search(interface_status_regex, input, re.IGNORECASE)
        if match:
            vnic_state = match.group(1)
        else:
            pylogger.warn("No match found for vnic_state. Using None.")
            vnic_state = None

        default_list_val = []
        default_str_val = ''
        py_dict = {}

        import vmware.common.utilities as utilities
        py_dict[self.IP4_KEY] = utilities.get_default(list_of_ip4_ips,
                                                      default_list_val)
        py_dict[self.IP6_KEY] = utilities.get_default(list_of_ip6_ips,
                                                      default_list_val)
        py_dict[self.MAC_ADDR_KEY] = utilities.get_default(mac,
                                                           default_str_val)
        py_dict[self.VNIC_STATE_KEY] = utilities.get_default(vnic_state,
                                                             default_str_val)

        return py_dict