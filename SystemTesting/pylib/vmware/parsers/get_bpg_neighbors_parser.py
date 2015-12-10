import re


class GetBGPNeighbors(object):
    """
    To parse the show bgp neighbour <IP> command output

    >>> import pprint
    >>> sbgpn = GetBGPNeighbors()
    >>>
    >>> raw_data='''
    ... BGP neighbor is 192.168.50.2,   remote AS 200,
    ... BGP state = Established, up
    ... Hold time is 180, Keep alive interval is 60 seconds
    ... Neighbor capabilities:
    ...          Route refresh: advertised and received
    ...          Address family IPv4 Unicast:advertised and received
    ...          Graceful restart Capability:none
    ...                  Restart remain time: 0
    ... Received 96 messages, Sent 99 messages
    ... Default minimum time between advertisement runs is 30 seconds
    ... For Address family IPv4 Unicast:advertised and received
    ...          Index 1 Identifier 0x5fc5f6ec
    ...          Route refresh request:received 0 sent 0
    ...          Prefixes received 2 sent 2 advertised 2
    ... Connections established 3, dropped 62
    ... Local host: 192.168.50.1, Local port: 179
    ... Remote host: 192.168.50.2, Remote port: 47813
    ... '''
    DATA: ['BGP neighbor: 192.168.50.2', 'BGP state : Established, up', 'Hold time: 180', ' Keep alive interval: 60 seconds', 'Local host: 192.168.50.1', 'Local port': '179', Remote host: 192.168.50.2'] # noqa
    >>> pprint.pprint(py_dict)
    {'bgp_neighbor': '192.168.50.2',
     'bgp_state': 'established',
     'bgp_status': 'up',
     'hold_time': '180',
     'keep_alive_interval': '60',
     'local_host': '192.168.50.1',
     'local_port': '179',
     'remote_host': '192.168.50.2',
     'remote_port': '47813'
    }
    """

    def get_parsed_data(self, raw_data, delimiter=None):
        parsed_data = {}
        py_dicts = []
        py_dict = {}
        data = []

        lines = raw_data.strip().split("\n")
        if ((len(lines) > 0) and ((lines[0].upper().find("ERROR") > 0)
                                  or (lines[0].upper().find("NOT FOUND") > 0)
                                  or (len(lines) == 1 and lines[0] == ""))):
            return parsed_data

        expected_fields = ['BGP neighbor', 'BGP state', 'Hold time', 'Local host', 'Remote host']  # noqa
        for line in lines:
            for field in expected_fields:
                if re.search(field, line):
                    if field.find('BGP neighbor') == 0:
                        element = line.strip(',').split(',', 1)
                        data.append(element[0].replace(' is', ':'))
                    elif (field.find('Hold time') == 0) or \
                            (field.find('Local host') == 0) \
                            or (field.find('Remote host') == 0):
                        element = line.split(',', 1)
                        data.append(element[0].replace(' is', ':'))
                        data.append(element[1].replace(' is', ':'))
                    elif field.find('BGP state') == 0:
                        data.append(line.replace('=', ':'))
                    break

        index = count = 0

        for line in data:
            if line.find('BGP neighbor') == 0:
                index = count
                py_dict[index] = {}
                count = index + 1

            (key, value) = line.split(delimiter, 1)
            key = key.strip().lower().replace(' ', '_')
            value = value.strip().lower().replace(' seconds', '')

            if key == 'bgp_state':
                (bgp_status, status) = value.split(',', 1)
                value = bgp_status.strip()
                status = status.lstrip()
                py_dict[index].update({key: value})

                key = 'bgp_status'
                value = status[:2]
            py_dict[index].update({key: value})

        iterator = 0
        while iterator <= index:
            py_dicts.append(py_dict[iterator])
            iterator += 1

        parsed_data['table'] = py_dicts
        return parsed_data


if __name__ == '__main__':
    import doctest
    doctest.testmod()
