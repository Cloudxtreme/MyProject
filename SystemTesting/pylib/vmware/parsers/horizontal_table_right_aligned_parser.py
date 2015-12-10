"""All Horizontal data parsing classes go in this file."""
import re
import vmware.common.global_config as global_config

pylogger = global_config.pylogger

PARSER_TYPE = 'raw/horizontalTable'


class HorizontalTableRightAlignedParser(object):
    """
    To parse the horizontal table:

    >>> import pprint
    >>> raw_data = '''
    ...                   Time      State                 Event      Reason
    ... ====================== ========== ====================== ==========
    ... 2015-01-19 18:06:49.22     Active    Node State Changed          Up
    ... 2015-01-19 18:04:47.19    Standby        Config Updated      Config
    ... 2015-01-19 18:04:47.19    Offline        Config Updated      Config
    ... 2015-01-19 18:00:55.68   Disabled                  Init        Init
    ...'''
    >>> header_keys = ['Time', 'State', 'Event', 'Reason']
    >>> pprint.pprint(horizontal_parser.get_parsed_data(
    ...     raw_data, header_keys=header_keys, skip_head=1, skip_tail=1))
    {}
    """
    def get_parsed_data(self, raw_data, header_keys=None, skip_head=None,
                        skip_tail=None, expect_empty_fields=None):
        '''
        Calling the get_parsed_data function will return a list of maps
        where each map corresponds to a raw in the horizontal table. Example
        output below:
        return data will be:
        {
            'table':
            [{'reason': 'Reason', 'state': 'State', 'event': 'Event',
                'time': 'Time'},
             {'reason': 'Up', 'state': 'Active', 'event': 'Node State
                Changed', 'time': '2015-01-19 18:06:57.77'},
             {'reason': 'Config', 'state': 'Standby', 'event': 'Config
                Updated', 'time': '2015-01-19 18:04:24.76'},
             {'reason': 'Config', 'state': 'Offline', 'event': 'Config
                Updated', 'time': '2015-01-19 18:04:24.75'},
             {'reason': 'Init', 'state': 'Disabled', 'event': 'Init',
                'time': '2015-01-19 18:00:55.17'}]
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
            NSXEdge> show edge-cluster history state
                              Time      State                 Event      Reason
            ====================== ========== ====================== ==========
            2015-01-19 18:06:49.22     Active    Node State Changed          Up
            2015-01-19 18:04:47.19    Standby        Config Updated      Config
            2015-01-19 18:04:47.19    Offline        Config Updated      Config
            2015-01-19 18:00:55.68   Disabled                  Init        Init
            ^                     ^            ^                  ^           ^
            The text contained between two '^'s is used as value for the column
            name i.e. for 1st record Broadcast field will be 10.1.1.255 and for
            the second record it will be an empty string.

            Parsing based on fixed text widths is preferred for this case,
            rather than using split() method on record lines, where we can
            have empty entries as using split() based parsing would erroneously
            put 'Static' as value for 'Broadcast' column entry for the second
            record.
        @rtype: dict
        @return: Returns a dict that contains a dict indexed by key 'table',
            the value corresponding to 'table' is a list of dicts with each
            dict containing the parsed row indexed by the column name as the
            key.
        '''
        parsed_data = {}
        py_dicts = []
        lines = raw_data.split("\n")
        for line in lines:
            if line.startswith("======================"):
                lines.remove(line)
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
        header = lines[header_index]
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
            # Find the starting point of each column name.
            header_markers = [header.find(header_key) + len(header_key)
                              for header_key in header_keys]
            for line in lines:
                # For non-header data proceed parse the records based on header
                # keys.
                if (line.strip() != ""):
                    # If line contains some text.
                    record = {}
                    for header_key in header_keys:
                        # Determine the ending point of each entry in the
                        # record.
                        key_index = header_keys.index(header_key)
                        end = header_markers[key_index]
                        if header_key == header_keys[0]:
                            # If we are looking at the first column then the
                            # field will start at position 0
                            start = 0
                        else:
                            # If we are not looking at the first column then
                            # the field will start where previous column/
                            # header ends.
                            start = header_markers[key_index - 1] + 1
                        # Data between start and end is the field entry for
                        # that particular column.
                        record[header_key.lower()] = line[start:end].strip()
                    py_dicts.append(record)
        else:
            header_keys = [key.lower() for key in header_keys]
            for line in lines[header_index + 1:tail_index]:
                if (line.strip() != ""):
                    values = line.split()
                    py_dicts.append(dict(zip(header_keys, values)))
        parsed_data['table'] = py_dicts
        return parsed_data

if __name__ == '__main__':
    import doctest
    doctest.testmod()
