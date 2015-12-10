import re


class Vdl2TableParser(object):
    def __init__(self, delimiter_title, expected_keys, field_delimiter=":"):
        '''
        @type delimiter_title: str
        @param delimiter_title: a title to seperate the records
        @type expected_keys: list
        @param expected_keys: a list of keys of the record
        @type field_delimiter: str
        @param field_delimiter: a charactor to seperate the value from key
               for each field
        '''
        self.delimiter_title = delimiter_title
        self.expected_keys = expected_keys
        self.field_delimiter = field_delimiter

    def get_parsed_data(self, raw_data):
        '''
        @type raw_data: str
        @param raw_data: output from the net-vdl2 CLI execution result

        @rtype: dict
        @return: return a hash including array while each array entry is a hash
        '''
        data = []
        lines = raw_data.strip().split("\n")
        if (len(lines) > 0 and
            ((lines[0].upper().find("ERROR") > 0) or
             (lines[0].upper().find("NOT FOUND") > 0) or
             (len(lines) == 1 and lines[0].strip() == ""))):
            return {'table': data}

        if not re.search(self.delimiter_title, raw_data):
            return {'table': data}

        for line in lines:
            for key in self.expected_keys:
                if re.search(key, line):
                    data.append(line.rstrip())
                    break

        py_dicts = []
        py_dict = {}
        for line in data:
            if re.search(self.expected_keys[0], line):
                if py_dict:
                    py_dicts.append(py_dict)
                py_dict = {}
            (key, value) = line.split(self.field_delimiter, 1)
            key = key.strip().lower()
            value = value.strip().lower()
            py_dict.update({key: value})

        # append the last item
        py_dicts.append(py_dict)
        parsed_data = {'table': py_dicts}
        return parsed_data


class Vdl2VtepTableParser(Vdl2TableParser):
    """
    To parse the net-vdl2 Vtep table

    # net-vdl2 -M vtep -s nsxvswitch -n switch_vni
    >>> import pprint
    >>> raw_data = '''
    ... VTEP Count:     1
    ...         Segment ID:     172.22.0.0
    ...         VTEP IP:        172.22.142.197
    ...         Is MTEP:        No
    ... '''
    >>> vdl2 = Vdl2VtepTableParser()
    >>> py_dict = vdl2.get_parsed_data(raw_data)
    >>> pprint.pprint(py_dict, width=78)
    {'table': [{'is mtep': 'no',
                'segment id': '172.22.0.0',
                'vtep ip': '172.22.142.197'}]}
    """
    def __init__(self):
        delimiter_title = "VTEP Count"
        expected_keys = ['Segment ID', 'VTEP IP', 'Is MTEP']
        super(Vdl2VtepTableParser, self).\
            __init__(delimiter_title=delimiter_title,
                     expected_keys=expected_keys)


class Vdl2MacTableParser(Vdl2TableParser):
    """
    To parse the net-vdl2 mac table

    # net-vdl2 -M mac -s nsxvswitch -n switch_vni
    >>> import pprint
    >>> vdl2 = Vdl2MacTableParser()
    >>> raw_data = '''
    ... MAC Entry Count:\t1
    ... \tInner MAC:\t00:0c:29:5a:ca:f5
    ... \tOuter MAC:\t00:50:56:66:b2:5e
    ... \tOuter IP:\t172.22.142.198
    ... \tFlags:\t\tF
    ... '''
    >>> py_dict = vdl2.get_parsed_data(raw_data)
    >>> pprint.pprint(py_dict, width=78)
    {'table': [{'flags': 'f',
                'inner mac': '00:0c:29:5a:ca:f5',
                'outer ip': '172.22.142.198',
                'outer mac': '00:50:56:66:b2:5e'}]}
    """
    def __init__(self):
        delimiter_title = "MAC Entry Count"
        expected_keys = ['Inner MAC', 'Outer MAC',
                         'Outer IP', 'Flags']
        super(Vdl2MacTableParser, self).\
            __init__(delimiter_title=delimiter_title,
                     expected_keys=expected_keys)


class Vdl2ArpTableParser(Vdl2TableParser):
    """
    To parse the net-vdl2 Arp table

    # net-vdl2 -M arp -s nsxvswitch -n switch_vni
    >>> import pprint
    >>> raw_data = '''
    ... ARP Entry Count:        1
    ...         IP:             192.168.139.127
    ...         MAC:            ff:ff:ff:ff:ff:ff
    ...         Flags:          3
    ... '''
    >>> vdl2 = Vdl2ArpTableParser()
    >>> py_dict = vdl2.get_parsed_data(raw_data)
    >>> pprint.pprint(py_dict, width=78)
    {'table': [{'flags': '3',
                'ip': '192.168.139.127',
                'mac': 'ff:ff:ff:ff:ff:ff'}]}
    """
    def __init__(self):
        delimiter_title = 'ARP Entry Count'
        expected_keys = ['IP', 'MAC', 'Flags']
        super(Vdl2ArpTableParser, self).\
            __init__(delimiter_title=delimiter_title,
                     expected_keys=expected_keys)
if __name__ == '__main__':
    import doctest
    doctest.testmod()
