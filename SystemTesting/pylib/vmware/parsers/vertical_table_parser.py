# All Vertical data parsing classes go in this file


class VerticalTableParser:
    """
    To parse the vertical table, like:

    ~ # net-vdl2 -M arp -s <DVS_NAME> -n <VNI>
    >>> import pprint
    >>> vertical_parser = VerticalTableParser()

    >>> raw_data = '''
    ... ARP c: 2
    ...     l:  91
    ...            IP: 192.168.0.100
    ...            MAC: f:f:f:f:f:f
    ...            Flags: F
    ...
    ...     l:  08
    ...            IP: 192.168.0.101
    ...            MAC: 0:5:5:67:9:a
    ...            Flags: 9
    ... '''
    >>> pprint.pprint(vertical_parser.get_parsed_data(raw_data), width=70)
    {'table': {('arp c', '2'): {('l', '08'): {'flags': '9',
                                              'ip': '192.168.0.101',
                                              'mac': '0:5:5:67:9:a'},
                                ('l', '91'): {'flags': 'f',
                                              'ip': '192.168.0.100',
                                              'mac': 'f:f:f:f:f:f'}}}}

    # net-vdl2 -l
    >>> vertical_parser = VerticalTableParser()
    >>> import pprint

    >>> raw_data = '''
    ... GStates:
    ...    Control Plane Out-Of-Sync:  No
    ...    VXLAN UDP Port: 8472
    ...    STT TCP Port:   7471
    ... N:    n
    ...    VDS ID: 18 66 06 c8 9f 12 41
    ...    MTU:    9000
    ...    Segment ID: 192.162.0.0
    ...    G-IP: 192.162.1.1
    ...    G-MAC:    00:50:56:b0:c2:28
    ...    C: 1
    ...        V: v
    ...            DVP ID:  10
    ...            SPort ID: 503
    ...            E ID:    0
    ...            VLAN ID:    0
    ...            Label:      980352
    ...            IP:     1.2.3
    ...            Netmask:    24
    ...            S-ID: 192.162.0.0
    ...            IP Timeout: 0
    ...            Mcast-GCount:  0
    ...    D:  1
    ...        L:    1
    ...            M-IP:   N/A
    ...            CPlane:  Enabled
    ...            Cont: 1.1.1.1
    ...            M-Count:    0
    ...            A-Count:    0
    ...            P-Count: 1
    ... '''
    >>> pprint.pprint(vertical_parser.get_parsed_data(raw_data), width=78)
    {'table': {'gstates:': {'control plane out-of-sync': 'no',
                            'stt tcp port': '7471',
                            'vxlan udp port': '8472'},
               ('n', 'n'): {'g-ip': '192.162.1.1',
                            'g-mac': '00:50:56:b0:c2:28',
                            'mtu': '9000',
                            'segment id': '192.162.0.0',
                            'vds id': '18 66 06 c8 9f 12 41',
                            ('c', '1'): {('v', 'v'): {'dvp id': '10',
                                                      'e id': '0',
                                                      'ip': '1.2.3',
                                                      'ip timeout': '0',
                                                      'label': '980352',
                                                      'mcast-gcount': '0',
                                                      'netmask': '24',
                                                      's-id': '192.162.0.0',
                                                      'sport id': '503',
                                                      'vlan id': '0'}},
                            ('d', '1'): {('l', '1'): {'a-count': '0',
                                                      'cont': '1.1.1.1',
                                                      'cplane': 'enabled',
                                                      'm-count': '0',
                                                      'm-ip': 'n/a',
                                                      'p-count': '1'}}}}}

    # esxcli network ip interface list
    >>> raw_data = '''
    ... vmk0
    ...    Name: vmk0
    ...    MAC Address: 00:50:56:b0:c8:f3
    ...    Enabled: true
    ...    Portset: vSwitch0
    ...    Portgroup: Management Network
    ...    Netstack Instance: defaultTcpipStack
    ...    VDS Name: N/A
    ...    VDS UUID: N/A
    ...    VDS Port: N/A
    ...    VDS Connection: -1
    ...    MTU: 1500
    ...    TSO MSS: 65535
    ...    Port ID: 33554436
    ...
    ... vmk10
    ...    Name: vmk10
    ...    MAC Address: 00:50:56:65:4a:24
    ...    Enabled: true
    ...    Portset: DvsPortset-0
    ...    Portgroup: N/A
    ...    Netstack Instance: vxlan
    ...    VDS Name: nsxvswitch
    ...    VDS UUID: 18 66 06 c8 9f 12 41 94-bc
    ...    VDS Port: 10
    ...    VDS Connection: 10
    ...    MTU: 1600
    ...    TSO MSS: 65535
    ...    Port ID: 50331652
    ... '''
    >>> pprint.pprint(vertical_parser.get_parsed_data(raw_data), width=78)
    {'table': {'vmk0': {'enabled': 'true',
                        'mac address': '00:50:56:b0:c8:f3',
                        'mtu': '1500',
                        'name': 'vmk0',
                        'netstack instance': 'defaulttcpipstack',
                        'port id': '33554436',
                        'portgroup': 'management network',
                        'portset': 'vswitch0',
                        'tso mss': '65535',
                        'vds connection': '-1',
                        'vds name': 'n/a',
                        'vds port': 'n/a',
                        'vds uuid': 'n/a'},
               'vmk10': {'enabled': 'true',
                         'mac address': '00:50:56:65:4a:24',
                         'mtu': '1600',
                         'name': 'vmk10',
                         'netstack instance': 'vxlan',
                         'port id': '50331652',
                         'portgroup': 'n/a',
                         'portset': 'dvsportset-0',
                         'tso mss': '65535',
                         'vds connection': '10',
                         'vds name': 'nsxvswitch',
                         'vds port': '10',
                         'vds uuid': '18 66 06 c8 9f 12 41 94-bc'}}}
    >>> raw_data = '''
    ... BAAH
    ...     foo1: bar1
    ...     foo2: bar2
    ...       foo3: bar3
    ... '''
    >>> pprint.pprint(vertical_parser.get_parsed_data(raw_data), width=60)
    {'table': {'baah': {'foo1': 'bar1',
                        ('foo2', 'bar2'): {'foo3': 'bar3'}}}}

    >>> raw_data = '''
    ... Cisco NetFlow/IPFIX
    ...     Version: 10
    ...     Length: 64
    ...     TS: Date
    ...         ETime: 14
    ...     FS: 3
    ...     ODI: 123
    ...     Set 1
    ...         DataRec1: 256
    ...         DataRec2: 48
    ...         Flow 1
    ...             OPI: 456
    ... '''
    >>> pprint.pprint(vertical_parser.get_parsed_data(raw_data), width=79)
    {'table': {'cisco netflow/ipfix': {'fs': '3',
                                       'length': '64',
                                       'odi': '123',
                                       'set 1': {'datarec1': '256',
                                                 'datarec2': '48',
                                                 'flow 1': {'opi': '456'}},
                                       'version': '10',
                                       ('ts', 'date'): {'etime': '14'}}}}

    >>> raw_data = '''
    ... NFlow
    ...     Version: 10
    ...     Length: 64
    ...     Timestamp: T
    ...         ExportTime: 1415037481
    ...     FlowSequence: 3
    ...     Observation Domain Id: 123
    ...     Set 1
    ...         D1: 256
    ...         D2: 48
    ...         F 1
    ...             OPI: 456
    ...             SMac: M1
    ...             DMac: M2
    ...              T2
    ...              T3
    ...             [D: 0 s]
    ...                 ST: 0
    ...                 ET: 0
    ...             Packets: 2
    ...              T4
    ...             Flow End Reason: 2
    ... '''
    >>> pprint.pprint(vertical_parser.get_parsed_data(raw_data), width=70)
    {'table': {'nflow': {'flowsequence': '3',
                         'length': '64',
                         'observation domain id': '123',
                         'set 1': {'d1': '256',
                                   'd2': '48',
                                   'f 1': {'flow end reason': '2',
                                           'opi': '456',
                                           'smac': 'm1',
                                           ('[d', '0 s]'): {'et': '0',
                                                            'st': '0'},
                                           ('dmac', 'm2'): {'T2': None,
                                                            'T3': None},
                                           ('packets', '2'): {'T4': None}}},
                         'version': '10',
                         ('timestamp', 't'): {'exporttime': '1415037481'}}}}
    """
    def get_parsed_data(self, raw_data, delimiter=': ', overwrite=None,
                        lowercase_data=True):
        '''
        Parses the raw data table output where records are indented vertically.

        @param raw_data: Output from the CLI execution result
        @type raw_data: str
        @param overwrite: When True, overwrites the duplicate key with the
            parsed data when/if duplicate keys exist in the data wit the same
            indent.
        @type overwrite: Bool
        @param lowercase_data: When True, converts all keys/data to lowercase,
            else returns them as is.
        @type lowercase_data: Bool
        @rtype: list
        @return: Returns the list of dicts where each dict contains data for
            a record.
        '''
        if overwrite is None:
            overwrite = False
        parsed_data = {}
        data = []
        lines = raw_data.strip().split("\n")
        if ((len(lines) > 0) and
            ((lines[0].upper().find("ERROR") > 0) or
             (lines[0].upper().find("NOT FOUND") > 0) or
             (len(lines) == 1 and lines[0].strip() == ""))):
            return parsed_data
        for line in lines:
            if (line.strip() != ""):
                data.append(line.rstrip())
        indentation_levels = [self._get_indent(line) for line in data]
        return {'table': self.parse_indented_data(
            data, delimiter, indentation_levels, overwrite,
            lowercase_data=lowercase_data)}

    def parse_indented_data(self, data, sep, indentation_levels, overwrite,
                            lowercase_data=True):
        """
        Recursively parses the data based on indentation.

        @type data: list
        @param data: list of lines
        @type sep: str
        @param sep: delimiter to use for parsing
        @type indentation_levels: list
        @param indentation_levels: list containing indentation level for each
            line in data.
        @param lowercase_data: When True, converts all keys/data to lowercase,
            else returns them as is.
        @type lowercase_data: Bool
        """
        # Base Cases where the indentation level is same for the data block
        # being parsed.
        if (len(data) != len(indentation_levels)):
            raise AssertionError("The array of indentation values should be "
                                 "equal to the number of lines in the data")
        if self._are_all_equal(indentation_levels):
            return self.parse_same_indent_data(
                data, sep, overwrite,
                lowercase_data=lowercase_data)
        # Recursive case where there are multiple indentation levels in the
        # data to be parsed.
        lowest_indentation = indentation_levels[0]
        matching_indices = self._find_all_indices(
            indentation_levels, lowest_indentation)
        ret = {}
        if len(matching_indices) > 1:
            for ind, cur_index in enumerate(matching_indices[:-1]):
                if matching_indices[ind + 1] - cur_index > 1:
                    key = data[cur_index].strip().lower()
                    if sep in key:
                        key = tuple([elem.strip() for elem in key.split(sep)])
                    sub_block = slice(cur_index + 1, matching_indices[ind + 1])
                    rec = {key: self.parse_indented_data(
                        data[sub_block], sep, indentation_levels[sub_block],
                        overwrite,
                        lowercase_data=lowercase_data)}
                    ret = self._merge_dicts(ret, rec, overwrite)
                else:
                    rec = self.parse_same_indent_data(
                        data[cur_index], sep, overwrite,
                        lowercase_data=lowercase_data)
                    ret = self._merge_dicts(ret, rec, overwrite)
            if matching_indices[-1] == len(data) - 1:
                # Last line in the data
                rec = self.parse_same_indent_data(
                    data[-1], sep, overwrite,
                    lowercase_data=lowercase_data)
                ret = self._merge_dicts(ret, rec, overwrite)
            else:
                cur_index = matching_indices[-1]
                key = data[cur_index].strip().lower()
                if sep in key:
                    key = tuple([elem.strip() for elem in key.split(sep)])
                sub_block = slice(cur_index + 1, len(data))
                rec = {key: self.parse_indented_data(
                    data[sub_block], sep, indentation_levels[sub_block],
                    overwrite, lowercase_data=lowercase_data)}
                ret = self._merge_dicts(ret, rec, overwrite)
        else:
            key = data[0].strip().lower()
            if sep in key:
                key = tuple([elem.strip() for elem in key.split(sep)])
            rec = {key: self.parse_indented_data(
                data[1:], sep, indentation_levels[1:], overwrite)}
            ret = self._merge_dicts(ret, rec, overwrite)
        return ret

    def parse_same_indent_data(self, data, sep, overwrite,
                               lowercase_data=True):
        """
        Parses the data based on the provided separator.

        @type data: list
        @param data: list of lines containing the data.
        @type sep: str
        @param sep: Delimiter for splitting the keys from values.
        @param lowercase_data: When True, converts all keys/data to lowercase,
            else returns them as is.
        @type lowercase_data: Bool
        @rtype: dict
        @return: Dictionary containing parsed key value pairs.
        """
        ret = {}
        data = self._as_list(data)
        for line in data:
            if sep in line:
                k, v = line.split(sep)
                if lowercase_data:
                    rec = {k.strip().lower(): v.strip().lower()}
                else:
                    rec = {k.strip(): v.strip()}
                ret = self._merge_dicts(ret, rec, overwrite)
            else:
                rec = {line.strip(): None}
                ret = self._merge_dicts(ret, rec, overwrite)
        return ret

    def _merge_dicts(self, dict1, dict2, overwrite):
        """
        Helper to merge the two dicts.

        @param overwrite: If set to true, duplicate keys will be overwritten
            else an error will be raised if the two dicts have the same keys.
        @type overwrite: Bool
        @param dict1: First dictionary to merge.
        @type dict1: dict
        @param dict2: Second dictionary to merge.
        @type dict1: dict
        """
        if overwrite:
            dict1.update(dict2)
            return dict1
        else:
            keys_1 = set(dict1.keys())
            keys_2 = set(dict2.keys())
            common_keys = keys_1.intersection(keys_2)
            if common_keys:
                raise ValueError("Dictionaries contain duplicate keys: %r" %
                                 common_keys)
            dict1.update(dict2)
            return dict1

    def _get_indent(self, string):
        subStr = string.lstrip()
        return string.find(subStr)

    # XXX(salmanm): Duplicated from utilities as the doc tests were failing
    # when trying to import utilities.
    def _as_list(self, obj):
        """
        Helper for making the object iterable as a list.

        @type obj: Any
        @param obj: Object that needs to be converted to a list.
        @rtype: list
        @return: Passed in object as a list (if it is not already a list).
        """
        if not hasattr(obj, '__iter__'):
            obj = [obj]
        return obj

    def _are_all_equal(self, values):
        """
        Takes a list of values and returns True if all are equal otherwise
        False.

        @type values: list
        @param values: List containing the data.
        """
        values = self._as_list(values)
        if not values:
            return True
        first_val = values[0]
        return all([value == first_val for value in values])

    def _find_all_indices(self, values, match):
        """
        Takes a list of values and returns all the indicies matching the
        provided element. List will be empty if no match is found.
        """
        values = self._as_list(values)
        matched_indices = []
        for index, value in enumerate(values):
            if value == match:
                matched_indices.append(index)
        return matched_indices


if __name__ == '__main__':
    import doctest
    doctest.testmod()
