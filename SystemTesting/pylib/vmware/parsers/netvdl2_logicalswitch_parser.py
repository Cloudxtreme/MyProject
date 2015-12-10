import re


class Vdl2LogicalSwitchParser:
    """
    To parse the net-vdl2 table, and get the key logical switch information,
    like: ReplicationBit/ControllerIP/ControllerStatus(up/down)

    # net-vdl2 -l
    >>> import pprint
    >>> vdl2 = Vdl2LogicalSwitchParser()
    >>> raw_data = '''
    ... Global States:
    ...         Control Plane Out-Of-Sync:      No
    ...         VXLAN UDP Port: 8472
    ...         STT TCP Port:   7471
    ... NSX VDS:        nsxvswitch
    ...         VDS ID: b6 92 12 50 38 2c 99 5d-2a e4 56 c5 c6 fb e6 05
    ...         MTU:    9000
    ...         Segment ID:     172.21.0.0
    ...         Gateway IP:     172.21.0.1
    ...         Gateway MAC:    00:09:7b:dc:e8:00
    ...         VTEP Count:     1
    ...                 VTEP Interface: vmk10
    ...                         DVPort ID:      1411104164
    ...                         Switch Port ID: 50331652
    ...                         Endpoint ID:    0
    ...                         VLAN ID:        0
    ...                         Label:          679552
    ...                         IP:             172.21.143.176
    ...                         Netmask:        255.255.0.0
    ...                         Segment ID:     172.21.0.0
    ...                         IP Acquire Timeout:     0
    ...                         Multicast Group Count:  0
    ...         Network Count:  2
    ...                 Logical Network:        58120
    ...                         Multicast IP:   N/A (MTEP Unicast)
    ...                         Control Plane:  Enabled (Multicast Proxy)
    ...                         Controller:     10.24.20.130 (up)
    ...                         MAC Entry Count:        0
    ...                         ARP Entry Count:        0
    ...                         Port Count:     1
    ...                 Logical Network:        18056
    ...                         Multicast IP:   N/A (Source Unicast)
    ...                         Control Plane:  Enabled (Multicast Proxy)
    ...                         Controller:     10.24.20.130 (up)
    ...                         MAC Entry Count:        0
    ...                         ARP Entry Count:        0
    ...                         Port Count:     1
    ... '''
    >>> py_dict = vdl2.get_parsed_data(raw_data)
    >>> pprint.pprint(py_dict, width=78)
    {'table': [{'controller': '10.24.20.130',
                'controllerstatus': 'up',
                'logical network': '58120',
                'replication_mode': 'mtep'},
               {'controller': '10.24.20.130',
                'controllerstatus': 'up',
                'logical network': '18056',
                'replication_mode': 'source'}]}
    """

    def get_parsed_data(self, raw_data, delimiter=':'):
        '''
        @param raw_data output from the CLI execution result
        @param delimiter character to split the key and value

        @rtype: dict
        @return: calling the get_parsed_data function will return a hash
                 including array while
        each array entry is a hash, based on above sample, the return data
        will be:
        {
            {'table': [{'controller': '10.24.29.58',
                        'controllerstatus': 'up',
                        'logical network': '5469',
                        'replication_mode': 'mtep'},
                       {'controller': '10.24.29.59',
                        'controllerstatus': 'up',
                        'logical network': '5470',
                        'replication_mode': 'source'}]}
            ]
        }
        '''
        parsed_data = {}
        data = []
        lines = raw_data.strip().split("\n")
        if ((len(lines) > 0) and
            ((lines[0].upper().find("ERROR") > 0) or
             (lines[0].upper().find("NOT FOUND") > 0) or
             (len(lines) == 1 and lines[0].strip() == ""))):
            return parsed_data

        if not re.search('Logical Network', raw_data, flags=re.I):
            return parsed_data

        expectedFields = ['Logical Network', 'Multicast IP', 'Controller']
        for line in lines:
            for field in expectedFields:
                if (re.search(field, line)):
                    data.append(line.rstrip())
                    break

        py_dicts = []
        py_dict = {}
        for line in data:
            if (re.search('Logical Network', line)):
                if py_dict:
                    py_dicts.append(py_dict)
                py_dict = {}
            (key, value) = line.split(delimiter, 1)
            key = key.strip().lower()
            value = value.strip().lower()
            if (key == 'multicast ip'):
                key = 'replication_mode'
                if re.search('mtep', value, flags=re.I):
                    value = 'mtep'
                elif re.search('source', value, flags=re.I):
                    value = 'source'
            elif (key == 'controller'):
                (controller, status) = value.split('(', 1)
                value = controller.strip()
                py_dict.update({key: value})
                key = 'controllerstatus'
                value = status[:-1]
            py_dict.update({key: value})

        # append the last item
        py_dicts.append(py_dict)
        parsed_data = {'table': py_dicts}
        return parsed_data


if __name__ == '__main__':
    import doctest
    doctest.testmod()
