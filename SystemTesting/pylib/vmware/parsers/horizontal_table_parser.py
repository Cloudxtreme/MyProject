"""All Horizontal data parsing classes go in this file."""
import re
import vmware.common.global_config as global_config

pylogger = global_config.pylogger

PARSER_TYPE = 'raw/horizontalTable'


class HorizontalTableParser(object):
    """
    To parse the horizontal table:

    >>> import pprint
    >>> raw_data = '''
    ... VNI      IP              MAC               Connection-ID
    ... 6796     192.168.139.11  00:50:56:b2:30:6e 1
    ... 6796     192.168.138.131 00:50:56:b2:40:33 2
    ... 6796     192.168.139.201 00:50:56:b2:75:d1 3
    ... '''
    >>> horizontal_parser = HorizontalTableParser()
    >>> pprint.pprint(horizontal_parser.get_parsed_data(raw_data))
    {'table': [{'connection-id': '1',
                'ip': '192.168.139.11',
                'mac': '00:50:56:b2:30:6e',
                'vni': '6796'},
               {'connection-id': '2',
                'ip': '192.168.138.131',
                'mac': '00:50:56:b2:40:33',
                'vni': '6796'},
               {'connection-id': '3',
                'ip': '192.168.139.201',
                'mac': '00:50:56:b2:75:d1',
                'vni': '6796'}]}
    >>> raw_data = '''
    ... VNI: 12345
    ...     Mac Address             VTEP Label
    ...     ff:ff:ff:ff:ff:ff         1234567
    ...     aa:aa:aa:aa:aa:aa         1234562
    ... wdc-server1>
    ... '''
    >>> header_keys = ['Mac Address', 'VTEP Label']
    >>> pprint.pprint(horizontal_parser.get_parsed_data(
    ...     raw_data, header_keys=header_keys, skip_head=1, skip_tail=1))
    {'table': [{'mac address': 'ff:ff:ff:ff:ff:ff', 'vtep label': '1234567'},
               {'mac address': 'aa:aa:aa:aa:aa:aa', 'vtep label': '1234562'}]}
    >>> header_keys = ['Interface', 'Port Group/DVPort', 'IP Family',
    ...                'IP Address', 'Netmask', 'Broadcast', 'MAC Address',
    ...                'MTU', 'TSO MSS', 'Enabled', 'Type']
    >>> raw_data = (
    ... 'Interface  Port Group/DVPort   IP Family IP Address               Netmask         Broadcast       MAC Address       MTU     TSO MSS   Enabled Type\\n'  # noqa
    ... 'vmk0       Management Network  IPv4      10.144.139.7             255.255.252.0   10.144.139.255  00:50:56:a3:95:e5 1500    65535     true    DHCP\\n'  # noqa
    ... 'vmk0       Management Network  IPv6      fe80::250:56ff:fea3:95e5 64                              00:50:56:a3:95:e5 1500    65535     true    STATIC, PREFERRED\\n'  # noqa
    ... )
    >>> pprint.pprint(horizontal_parser.get_parsed_data(
    ...     raw_data, header_keys=header_keys, expect_empty_fields=True))
    {'table': [{'broadcast': '10.144.139.255',
                'enabled': 'true',
                'interface': 'vmk0',
                'ip address': '10.144.139.7',
                'ip family': 'IPv4',
                'mac address': '00:50:56:a3:95:e5',
                'mtu': '1500',
                'netmask': '255.255.252.0',
                'port group/dvport': 'Management Network',
                'tso mss': '65535',
                'type': 'DHCP'},
               {'broadcast': '',
                'enabled': 'true',
                'interface': 'vmk0',
                'ip address': 'fe80::250:56ff:fea3:95e5',
                'ip family': 'IPv6',
                'mac address': '00:50:56:a3:95:e5',
                'mtu': '1500',
                'netmask': '64',
                'port group/dvport': 'Management Network',
                'tso mss': '65535',
                'type': 'STATIC, PREFERRED'}]}
    >>> raw_data = '''
    ... '''
    >>> horizontal_parser.get_parsed_data(raw_data)
    {}
    >>> raw_data = '''
    ...
    ... '''
    >>> horizontal_parser.get_parsed_data(raw_data)
    {}
    >>> raw_data = '''
    ... Error: Not Found
    ... '''
    >>> horizontal_parser.get_parsed_data(raw_data)
    {}
    >>> header_keys = ['Prefix', 'Next Hop IP Address']
    >>> characters_to_remove = ['[', ']']
    >>> raw_data = '''
    ... VDR: cc967450-9206-46ab-a442-19603ed09678
    ...               Prefix           Next Hop IP Address
    ...     192.168.201.0/24              [ 192.168.2.11 ]
    ...     192.168.200.0/24              [ 192.168.1.10 ]
    ... '''
    >>> pprint.pprint(horizontal_parser.get_parsed_data(
    ...     raw_data, header_keys=header_keys, skip_head=1,
    ...     characters_to_remove=characters_to_remove))
    {'table': [{'next hop ip address': '192.168.2.11',
                'prefix': '192.168.201.0/24'},
               {'next hop ip address': '192.168.1.10',
                'prefix': '192.168.200.0/24'}]}
    """
    def get_parsed_data(self, raw_data, header_keys=None, skip_head=None,
                        skip_tail=None, expect_empty_fields=None,
                        characters_to_remove=None):
        '''
        Calling the get_parsed_data function will return a list of maps
        where each map corresponds to a raw in the horizontal table. Example
        output below:
        return data will be:
        {
            'table':
            [{VNI=6796, IP=192.168.139.11, MAC=00:50:...6e, Connection-ID=1},
             ...
            {VNI=6796, IP=192.168.139.201, MAC=00;50:..d1, Connection-ID=3}]
        }
        @type raw_data: str
        @param raw_data: Output from the CLI
        @type header_keys: list
        @param header_keys: List of column names to use as keys while parsing
            the raw_data. Note that in the returned map, all the column names
            are converted to lower case.
        @type skip_head: int
        @param skip_head: Specifies the number of lines to skip in the
            beginning of the raw data. It helps in the cases where the actual
            header starts after a certain number of lines in the raw data.
        @type skip_tail: int
        @param skip_tail: Specifies the number of lines to skip in the end of
            raw data. It helps in the cases where there are extra number of
            lines appending to the raw data.
        @type expect_empty_fields: bool
        @param expect_empty_fields: Flag to tell the parser whether/if records
            can have empty column entries. When set to true, parser uses the
            difference between starting points of the column names to extract
            the entry of the record of previous column. e.g. in the following
            CLI output:
            Interface    Netmask      Broadcast   Type
            vmk0         255.255.0.0  10.1.1.255  DHCP
            vmk1         64                       Static
            ^            ^            ^           ^     ^
            The text contained between two '^'s is used as value for the column
            name i.e. for 1st record Broadcast field will be 10.1.1.255 and for
            the second record it will be an empty string.

            Parsing based on fixed text widths is prefered for this case,
            rather than using split() method on record lines, where we can
            have empty entries as using split() based parsing would erroneously
            put 'Static' as value for 'Broadcast' column entry for the second
            record.
        @type characters_to_remove: dict
        @param characters_to_remove: List of characters to be removed from the
            raw data. Might be things like additional quotes, unwanted
            brackets, etc. which might cause issues in parsing.
            Example: Unwanted square brackets '[' and ']'
            CLI output:
            Prefix                        Next Hop IP Address
            192.168.200.0/24              [ 192.168.1.10 ]
                                          ^              ^
        @rtype: dict
        @return: Returns a dict that contains a dict indexed by key 'table',
            the value corresponding to 'table' is a list of dicts with each
            dict containing the parsed row indexed by the column name as the
            key.
        '''
        parsed_data = {}
        py_dicts = []
        lines = raw_data.strip().split("\n")
        if ((len(lines) > 0) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[0].upper().find("NOT FOUND") > 0) or
                                  (len(lines) == 1 and lines[0] == ""))):
            return parsed_data
        header_index = 0
        if skip_head:
            header_index = skip_head
        if header_index >= len(lines):
            pylogger.warning("Tried to get header of table at line number: "
                             "%s, but there are only %s lines. Returning "
                             "an empty table, but check your parsing logic."
                             % (header_index + 1, len(lines)))
            return {'table': []}
        header = lines[header_index].strip()
        tail_index = len(lines)
        if skip_tail:
            tail_index = tail_index - skip_tail
        if header_keys:
            header_match = re.search('.*'.join(header_keys), header)
            if not header_match:
                raise AssertionError('Header keys passed in do not match the '
                                     'column names in the raw data\nHeader '
                                     'keys passed: %r\nColumn names in raw '
                                     'data: %r' % (header_keys,
                                                   lines[header_index]))
        else:
            header_keys = lines[header_index].split()
        if expect_empty_fields:
            if characters_to_remove:
                raise NotImplementedError(
                    'Support to specify "expect_empty_fields" and '
                    '"characters_to_remove" together not implemented.')
            # Find the starting point of each column name.
            header_markers = [header.find(header_key) for header_key in
                              header_keys]
            for line in lines[header_index + 1:tail_index]:
                # For non-header data proceed parse the records based on header
                # keys.
                if (line.strip() != ""):
                    # If line contains some text.
                    record = {}
                    for header_key in header_keys:
                        # Determine the starting point of each entry in the
                        # record.
                        key_index = header_keys.index(header_key)
                        start = header_markers[key_index]
                        if not header_key == header_keys[-1]:
                            # If we are looking at the last column then the
                            # field will end where the line ends.
                            end = header_markers[key_index + 1]
                        else:
                            # If we are not looking at the last column then the
                            # field will end where the next column/header key
                            # starts.
                            end = len(line)
                        # Data between start and end is the field entry for
                        # that particular column.
                        record[header_key.lower()] = line[start:end].strip()
                    py_dicts.append(record)
        else:
            header_keys = [key.lower() for key in header_keys]
            for line in lines[header_index + 1:tail_index]:
                if (line.strip() != ""):
                    if characters_to_remove:
                        for character in characters_to_remove:
                            line = line.replace(character, '')
                    values = line.split()
                    py_dicts.append(dict(zip(header_keys, values)))
        parsed_data['table'] = py_dicts
        return parsed_data

    def insert_header_to_raw_data(self, raw_data, skip_head=None,
                                  header_keys=None):
        """
        @param raw_data: Input data where header string need to be inserted.
        @type skip_head: int
        @param skip_head: Specifies the number of lines to skip in the raw data.
            It helps in the cases where the actual header starts after a
            certain number of lines in the raw data.
            Header Line is inserted at this Index.
        @type header_keys: list
        @param header_keys: List of column names tobe used as Header Line.
        @rtype: str
        @return: Returns a str with Header line added to the provided input
                 string.

        >>> hz = HorizontalTableParser()
        >>> header_keys = ['Code', 'Network', 'AdminDist_Metric', 'Via', 'NextHop']
        >>> raw_data='''
        ...     Codes: O - OSPF derived, i - IS-IS derived, B - BGP derived,
        ...     C - connected, S - static, L1 - IS-IS level-1, L2 - IS-IS level-2,
        ...     IA - OSPF inter area, E1 - OSPF external type 1, E2 - OSPF external type 2
        ...
        ...     S 0.0.0.0/0     [1/1]  via 10.117.83.253
        ...     B 80.80.80.0/24 [20/0] via 20.20.20.1
        ...     B 80.80.80.0/24 [20/0] via 70.70.70.1
        ... '''
        >>>
        >>> mod_raw_data = hz.insert_header_to_raw_data(raw_data, header_keys=header_keys, skip_head=4) # noqa
        >>> print mod_raw_data
        Codes: O - OSPF derived, i - IS-IS derived, B - BGP derived,
            C - connected, S - static, L1 - IS-IS level-1, L2 - IS-IS level-2,
            IA - OSPF inter area, E1 - OSPF external type 1, E2 - OSPF external type 2  #noqa
        Code Network AdminDist_Metric Via NextHop
            S 0.0.0.0/0     [1/1]  via 10.117.83.253
            B 80.80.80.0/24 [20/0] via 20.20.20.1
            B 80.80.80.0/24 [20/0] via 70.70.70.1
        """

        lines = raw_data.strip().split("\n")

        header_index = 0
        if skip_head:
            header_index = skip_head

        # Header Line
        header_line = ' '.join(header_keys)

        # Insert the header line
        lines.insert(header_index, header_line)

        mod_raw_data = '\n'. join(lines)

        return mod_raw_data

    def marshal_raw_data(cls, raw_data, search_string, replace_string):
        """
        @param raw_data: Input data which is the output of command.
        @param search_string: Specify the string that should be replaced.
        @param replace_string: Specify the replace string.
        @return: Returns a str with marshalled output data.

        This is used specifically for marshalling output
        of show ip forwarding command:

        Actual Output:

          Codes: C - connected, R - remote,
          > - selected route, * - FIB route

          R>* 0.0.0.0/0 via 10.24.31.253, vNic_3
          C>* 10.24.28.0/22 is directly connected, vNic_3

        Marshalled Output:
           Codes: C - connected R - remote
           > - selected route * - FIB route

           R>* 0.0.0.0/0 via 10.24.31.253 vNic_3
           C>* 10.24.28.0/22 isdirectlyconnected NULL vNic_3   -> note the difference # noqa

        In order to map the output with the Header String
        we need to perform this operation

        Header String: Code Network T1 NextHop VnicName
        So the Output now gets mapped as:
          {'table': [
                     {'nexthop': '10.24.31.253',
                      'vnicname': 'vNic_3',
                      'code': 'R>*',
                      'network': '0.0.0.0/0',
                      'via': 'via'},
                     {'nexthop': 'NULL',     <--- Note the difference
                      'vnicname': 'vNic_3',
                      'code': 'C>*',
                      'network': '10.24.28.0/22',
                      'via': 'isdirectlyconnected'}]} <--- Note the difference

        """

        lines = raw_data.strip().splitlines()

        newlines = []

        # Process the data so as to handle the following:
        # R>* 192.168.40.0/24
        #     via 192.168.50.100, vNic_1
        #     via 192.168.50.101, vNic_1

        headlinefound = False
        for i, line in enumerate(lines):
            line = line.strip()
            if line.startswith("via"):
                if headlinefound:
                    pass
                else:
                    new_head = lines[i-1]
                    headlinefound = True

                newline = new_head + " " + line
                newlines.append(newline)
            elif line.__contains__("via") or line.__contains__("directly"):
                headlinefound = False
                newlines.append(line)
            else:
                newlines.append(line)

        if newlines:
            lines = newlines

        # Process the data so as to map the following fields:
        # is directly connected, : isdirectlyconnected NULL

        newlines = []
        for line in lines:
            if line.find(search_string) != -1:
                newline = line.replace(search_string, replace_string)
                newlines.append(newline)
            elif line.find(',') != -1:
                newline = line.replace(',', '')
                newlines.append(newline)
            else:
                newlines.append(line)

        marshaled_raw_data = '\n'.join(newlines)

        return marshaled_raw_data

if __name__ == '__main__':
    import doctest
    doctest.testmod()
