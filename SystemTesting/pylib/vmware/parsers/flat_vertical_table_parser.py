PARSER_TYPE = 'raw/flatverticalTable'


class FlatVerticalTableParser(object):
    """
    To parse a flat non nested vertical table, like:

    ~ # net-vdr --lif <VDR_NAME> -l
    This will strip the header of the returned table data.
    >>> import pprint
    >>> flat_vertical_parser = FlatVerticalTableParser()
    >>> raw_data = '''
    ... VDR tlr-coke LIF Information :
    ...
    ... Name:                LS_10_20
    ... DHCP Relay:          Not enabled
    ...
    ... Name:                LS_10_10
    ... DHCP Relay:          Not enabled
    ... '''
    >>> pprint.pprint(flat_vertical_parser.get_parsed_data(raw_data), width=78)
    {'table': [{'dhcp relay': 'not enabled', 'name': 'ls_10_20'},
               {'dhcp relay': 'not enabled', 'name': 'ls_10_10'}]}
    """
    def get_parsed_data(self, raw_data, key_val_sep=None, key_sep=None,
                        info_sep=None):
        '''
        Parses the raw data table output where records are indented vertically.
        This will strip a row of the table if the key or the value is empty.
        @param raw_data: Output from the CLI execution result
        @type raw_data: str
        @param key_val_sep: Key value seperator. Default value is ":"
        @type key_val_sep: str
        @param key_sep: Seperator between individual rows of key data. Default
            value is "\n"
        @type key_sep: str
        @param info_sep: Seperator between group of data. Default is "".
            Use "" if the group of data is seperated by an empty line.
            Use the seperator between group of data as info_sep for all other
            cases.
        @type info_sep: str
        @rtype: list
        @return: Returns the list of dicts where each dict contains data for
            a record.

        Calling the get_parsed_data function will return a list of dicts with
        each dict containing the data corresponding to the record. e.g.
        {
            'table':
                [{'dhcp relay':'not enabled', 'name':'ls_10_20'},
                 {'dhcp relay':'not enabled', 'name':'ls_10_10'}]
        }
        '''
        if key_val_sep is None:
            key_val_sep = ":"
        if info_sep is None:
            info_sep = ""
        if key_sep is None:
            key_sep = "\n"
        parsed_data = {}
        py_dicts = []
        data = []
        lines = raw_data.strip().split(key_sep)
        if ((len(lines) > 0) and
            ((lines[0].upper().find("ERROR") > 0) or
             (lines[0].upper().find("NOT FOUND") > 0) or
             (len(lines) == 1 and lines[0].strip() == ""))):
            return parsed_data
        for line in lines:
            if (line.strip() == info_sep):
                data.append(info_sep)
            else:
                data.append(line.rstrip())

        py_dict = {}
        for line in data:
            if line == info_sep:
                if py_dict:
                    py_dicts.append(py_dict)
                    py_dict = {}
                continue
            if key_val_sep in line:
                (key, value) = line.split(key_val_sep, 1)
                key = key.strip().lower()
                value = value.strip().lower()
                if key != "" and value != "":
                    py_dict.update({key: value})
        py_dicts.append(py_dict)
        parsed_data = {'table': py_dicts}
        return parsed_data


class VniStatsVerticalTableParser(FlatVerticalTableParser):
    """
    >>> import pprint
    >>> vniparser = VniStatsVerticalTableParser()
    >>> import pprint
    >>> raw_data = '''
    ... update.member         4
    ... update.vtep           4
    ... update.mac            4
    ... update.mac.invalidate 0
    ... update.arp            2
    ... update.arp.duplicate  0
    ... query.mac             0
    ... query.mac.miss        0
    ... query.arp             2
    ... query.arp.miss        2
    ... '''
    >>> pprint.pprint(vniparser.get_parsed_data(raw_data), width=78)
    {'table': [{'query.arp': '2',
                'query.arp.miss': '2',
                'query.mac': '0',
                'query.mac.miss': '0',
                'update.arp': '2',
                'update.arp.duplicate': '0',
                'update.mac': '4',
                'update.mac.invalidate': '0',
                'update.member': '4',
                'update.vtep': '4'}]}
    """
    def get_parsed_data(self, raw_data):
        return (super(VniStatsVerticalTableParser, self).
                get_parsed_data(raw_data, key_val_sep=' '))

if __name__ == '__main__':
    import doctest
    doctest.testmod()
