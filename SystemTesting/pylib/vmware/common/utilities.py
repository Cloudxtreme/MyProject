# Copyright (C) 2014 VMware, Inc. All rights reserved.
""" LogicalRouterSchema for cli output from ESX net-vdr command """
import datetime
import os
import pprint
import random
import re
import types
import socket
import fcntl
import struct


import vmware.common.global_config as global_config
import vmware.common.regex_utils as regex_utils
from vmware.parsers.utilities import get_data_parser

pylogger = global_config.pylogger
LIST_ATTR_TYPES = (types.ListType, types.TupleType)
IMMUTABLE_ATTR_TYPES = (
    types.StringType, types.BooleanType, types.UnicodeType,
    types.IntType, types.FloatType, types.LongType, types.NoneType,
)
IMMUTABLE_NOT_NONE = (
    types.StringType, types.BooleanType, types.UnicodeType,
    types.IntType, types.FloatType, types.LongType,
)
STATUS = 'status'
DOWN = 'DOWN'


def is_true(value):
    """
    Method to convert acceptable strings to True/False.

    @type value: str/bool/None
    @param value: Input to be converted to boolean.
    @rtype: None/bool
    @return: Returns None if input is None; True/False if it is able to
             recognize acceptable inputs, else raises ValueError.

    >>> is_true(None)
    >>>
    >>> is_true('yes')
    True
    >>> is_true('no')
    False
    >>> is_true(True)
    True
    >>> is_true(False)
    False
    >>> is_true('foo')
    Traceback (most recent call last):
        ...
    ValueError: Input foo not supported.
    """
    if value is None:
        return value
    elif str(value).lower() in ('yes', 'true', 'on'):
        return True
    elif str(value).lower() in ('no', 'false', 'off'):
        return False
    else:
        raise ValueError("Input %s not supported." % value)


def parse_one_line_output(out, record_delim=None, key_val_delim=None):
    """
    Helper for parsing one line output that contains multiple records on the
    same line.

    @type out: str
    @param out: Raw data output
    @type record_delim: str
    @param record_delim: Delimiter used to separate out records
    @type key_val_delim: str
    @param key_val_delim: Delimiter of key value that is contained within a
        record.
    @rtype: dict
    @return: Returns a key value pair corresponding to each record.
    >>> data = "VTEP Label: 12345677, IP Address: 192.168.0.1"
    >>> pprint.pprint(parse_one_line_output(data, record_delim=',',
    ...               key_val_delim=':'))
    {'IP Address': '192.168.0.1', 'VTEP Label': '12345677'}
    >>> data = "VNI: 12345, replication_mode: mtep"
    >>> pprint.pprint(parse_one_line_output(data, record_delim=',',
    ...               key_val_delim=':'))
    {'VNI': '12345', 'replication_mode': 'mtep'}
    """
    py_dict = {}
    for key_val in out.split(record_delim):
        key, val = key_val.split(key_val_delim)
        py_dict[key.strip()] = val.strip()
    return py_dict


def parse_ifconfig_output(output):
    """
    Parses the output of ifconfig and returns it as list of dictionary
    where each dictionary is cotains data for each interface. Currently
    only IPv4 related data is parsed.

    @param output: Ifconfig output as retrieved from the CLI.
    @type output: str
    >>> out = (
    ... "eth0      Link encap:Ethernet  HWaddr fa:16:3e:9c:5b:8f\\n"
    ... "          inet addr:192.168.0.3  Bcast:192.168.0.255 Mask:255.255.255.0\\n"  # noqa
    ... "          inet6 addr: fe80::f816:3eff:fe9c:5b8f/64 Scope:Link\\n"
    ... "          UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1\\n"
    ... "          RX packets:8931156 errors:0 dropped:0 overruns:0 frame:0\\n"  # noqa
    ... "          TX packets:7012355 errors:0 dropped:0 overruns:0 carrier:0\\n"  # noqa
    ... "          collisions:0 txqueuelen:1000\\n"
    ... "          RX bytes:4213282295 (4.2 GB)  TX bytes:4745062621 (4.7 GB)\\n\\n"  # noqa
    ... "lo        Link encap:Local Loopback\\n"
    ... "          inet addr:127.0.0.1  Mask:255.0.0.0\\n"
    ... "          inet6 addr: ::1/128 Scope:Host\\n"
    ... "          UP LOOPBACK RUNNING  MTU:16436  Metric:1\\n"
    ... "          RX packets:100869 errors:0 dropped:0 overruns:0 frame:0\\n"  # noqa
    ... "          TX packets:100869 errors:0 dropped:0 overruns:0 carrier:0\\n"  # noqa
    ... "          collisions:0 txqueuelen:0\\n"
    ... "          RX bytes:33498307 (33.4 MB)  TX bytes:33498307 (33.4 MB)\\n\\n"  # noqa
    ... "virbr0    Link encap:Ethernet  HWaddr c2:41:be:ea:1d:6a\\n"
    ... "          inet addr:192.168.122.1  Bcast:192.168.122.255 Mask:255.255.255.0\\n"  # noqa
    ... "          BROADCAST MULTICAST  MTU:1500  Metric:1\\n"
    ... "          RX packets:0 errors:0 dropped:0 overruns:0 frame:0\\n"
    ... "          TX packets:0 errors:0 dropped:0 overruns:0 carrier:0\\n"
    ... "          collisions:0 txqueuelen:0\\n"
    ... "          RX bytes:0 (0.0 B)  TX bytes:0 (0.0 B)\\n")
    >>> import pprint
    >>> pprint.pprint(parse_ifconfig_output(out))
    [{'bcast': '192.168.0.255',
      'collisions': 0,
      'dev': 'eth0',
      'ip': '192.168.0.3',
      'mac': 'fa:16:3e:9c:5b:8f',
      'metric': 1,
      'mtu': 1500,
      'netmask': '255.255.255.0',
      'rx_bytes': 4213282295L,
      'rx_dropped': 0,
      'rx_errors': 0,
      'rx_frame_err': 0,
      'rx_over_err': 0,
      'rx_packets': 8931156,
      'status': 'UP',
      'tx_bytes': 4745062621L,
      'tx_carrier_err': 0,
      'tx_dropped': 0,
      'tx_errors': 0,
      'tx_over_err': 0,
      'tx_packets': 7012355,
      'txquelen': 1000},
     {'bcast': None,
      'collisions': 0,
      'dev': 'lo',
      'ip': '127.0.0.1',
      'mac': None,
      'metric': 1,
      'mtu': 16436,
      'netmask': '255.0.0.0',
      'rx_bytes': 33498307,
      'rx_dropped': 0,
      'rx_errors': 0,
      'rx_frame_err': 0,
      'rx_over_err': 0,
      'rx_packets': 100869,
      'status': 'UP',
      'tx_bytes': 33498307,
      'tx_carrier_err': 0,
      'tx_dropped': 0,
      'tx_errors': 0,
      'tx_over_err': 0,
      'tx_packets': 100869,
      'txquelen': 0},
     {'bcast': '192.168.122.255',
      'collisions': 0,
      'dev': 'virbr0',
      'ip': '192.168.122.1',
      'mac': 'c2:41:be:ea:1d:6a',
      'metric': 1,
      'mtu': 1500,
      'netmask': '255.255.255.0',
      'rx_bytes': 0,
      'rx_dropped': 0,
      'rx_errors': 0,
      'rx_frame_err': 0,
      'rx_over_err': 0,
      'rx_packets': 0,
      'status': 'DOWN',
      'tx_bytes': 0,
      'tx_carrier_err': 0,
      'tx_dropped': 0,
      'tx_errors': 0,
      'tx_over_err': 0,
      'tx_packets': 0,
      'txquelen': 0}]
    """
    ifconfig_table = []
    blocks = output.split('\n\n')
    regex = ("\n*\s*(?P<dev>\S+).*?((\s*)|(?P<mac>(%s)))\s*\n"
             "\s*(inet addr:(?P<ip>%s)\s+(Bcast:(?P<bcast>(%s)))?\s+"
             "Mask:(?P<netmask>%s)\s*\n)?(.*\n)*(?P<status>.*UP(?=("
             "BROADCAST|MULTICAST|LOOPBACK|RUNNING| )+))?.*MTU:"
             "(?P<mtu>[0-9]+).*Metric:(?P<metric>[0-9]+)\s*\n.*RX packets:"
             "(?P<rx_packets>[0-9]+) errors:(?P<rx_errors>[0-9]+) "
             "dropped:(?P<rx_dropped>[0-9]+) overruns:"
             "(?P<rx_over_err>[0-9]+) frame:(?P<rx_frame_err>[0-9]+)\s*\n"
             ".*TX packets:(?P<tx_packets>[0-9]+) errors:"
             "(?P<tx_errors>[0-9]+) dropped:(?P<tx_dropped>[0-9]+) "
             "overruns:(?P<tx_over_err>[0-9]+) carrier:"
             "(?P<tx_carrier_err>[0-9]+)\s*\n.*collisions:(?P<collisions>"
             "[0-9]+) txqueuelen:(?P<txquelen>[0-9]+).*\n.*RX bytes:"
             "(?P<rx_bytes>[0-9]+) \([0-9\.]+ [a-zA-Z]+\).*TX bytes:"
             "(?P<tx_bytes>[0-9]+) \([0-9\.]+ [a-zA-Z]+\)")
    int_keys = ['mtu', 'metric', 'rx_packets', 'rx_errors', 'rx_dropped',
                'rx_over_err', 'rx_frame_err', 'tx_packets', 'tx_errors',
                'tx_dropped', 'tx_over_err', 'tx_carrier_err',
                'collisions', 'txquelen', 'rx_bytes', 'tx_bytes']
    regex = regex % (regex_utils.mac, regex_utils.ip, regex_utils.ip,
                     regex_utils.ip)
    compiled_regex = re.compile(regex)
    # Stripping of the empty string at the end
    if not blocks[-1]:
        blocks = blocks[:-1]
    for block in blocks:
        match = compiled_regex.match(block)
        if not match:
            pylogger.warning("regex didn't match against ifconfig block, "
                             "regex:\n%r\nifconfig block:\n%r" %
                             (regex, block))
            continue
        iface_dict = match.groupdict()
        for key, val in iface_dict.iteritems():
            if val:
                iface_dict[key] = iface_dict[key].strip()
                if key in int_keys:
                    iface_dict[key] = int(iface_dict[key])
        if not iface_dict[STATUS]:
            iface_dict[STATUS] = DOWN
        ifconfig_table.append(iface_dict)
    return ifconfig_table


def current_date_time():
    """
    Method for returning current data and time as a string.

    @rtype: str
    @return: Date (Year, month, day) and Time (Hour, Minutes,
        Seconds) concatenated.
    """
    return datetime.datetime.now().strftime('%Y%m%d_%H_%M_%S%s')


def map_attributes(attribute_map, py_dict, reverse_attribute_map=False):
    """ Method to convert user dictionary to product expected form
        OR
        product dictionary to user dictionary
        using attribute_map and reverse_attribute_map parameters

        @type attribute_map: dict
        @param attribute_map: Map of attributes to convert dictionary
            in product expected form. attribute_map parameter is a plane hash
            because we want to replace all the occurrences of an attribute in
            py_dict.
        @type py_dict: dict
        @param py_dict: Dictionary from which attributes will be replaced using
            attribute_map and reverse_attribute_map parameters.
        @type reverse_attribute_map: bool
        @param reverse_attribute_map: if this attribute is true then
            attribute_map will be reversed i.e. keys will become values and
            values will become keys.
        @rtype: dict
        @return: Result dictionary in expected form.

    For example:
    >>> py_dict = {'bfd_admin_down_count': 0, 'bfd_up_count': 1, 'bfd_down_count': 0, 'bfd_init_count': 0}  # noqa
    >>> attribute_map = {'bfd_admin_down_count': 'admin_down', 'bfd_up_count': 'up', 'bfd_down_count': 'down', 'bfd_init_count': 'init'}  # noqa
    >>> map_attributes(attribute_map, py_dict)
    {'admin_down': 0, 'up': 1, 'down': 0, 'init': 0}
    """

    # if attribute_map is None
    if attribute_map is None or py_dict is None:
        return py_dict

    # Reversing attribute map
    if reverse_attribute_map:
        attribute_map = dict((value, key)
                             for key, value in attribute_map.items())
    for attribute in py_dict.keys():

        if py_dict.get(attribute, None) is not None:

            if attribute in attribute_map:
                # If we are here we have mapping for attribute in dict
                new_attribute = attribute_map[attribute]
                py_dict[new_attribute] = py_dict[attribute]
                if new_attribute != attribute:
                    del py_dict[attribute]
                    attribute = new_attribute
            if isinstance(py_dict[attribute], list):
                # If we are here we have a list
                for element in py_dict[attribute]:
                    if type(element) in IMMUTABLE_ATTR_TYPES:
                        pass
                    elif isinstance(element, dict):
                        # If we are here we have a nested dict
                        map_attributes(attribute_map, element)
                    else:
                        pylogger.error("Attribute type %s for %s not handled!"
                                       % (type(element), element))
            elif isinstance(py_dict[attribute], dict):
                # If we are here we have a nested dict
                element = py_dict[attribute]
                map_attributes(attribute_map, element)
            elif type(py_dict[attribute]) in IMMUTABLE_ATTR_TYPES:
                # Do nothing if attribute falls in above data types.
                pass
            else:
                # If we are here, attribute type has not been considered.
                pylogger.error("Attribute type %s for %s not handled!" %
                               (type(py_dict[attribute]), py_dict[attribute]))
    # Return dict with replaced attributes
    return py_dict


def get_mapped_pydict_for_expect(connection, endpoint, parser, expect,
                                 regex_lookup_key,
                                 attributes_mapping_table=None):
    # step 1, get the raw data output from endpoint
    raw_payload = connection.request(endpoint, expect).response_data

    # step 2, get the parsed pydict based on corresponding data parser
    data_parser = get_data_parser(parser)
    py_dict = data_parser.get_parsed_data(raw_payload, regex_lookup_key)

    # step 3, get the mapped pydict based on attribute mapping
    mapped_pydict = map_attributes(attributes_mapping_table, py_dict)
    return mapped_pydict


def parse_data_map_attributes(raw_data, parser_type, attribute_map,
                              reverse_attribute_map=None, skip_records=None,
                              **parser_kwargs):
    """
    Gets raw data and parses it based on the parser type provided.

    @type raw_data: str
    @param raw_data: Raw data that needs to be parsed
    @type parser_type: str
    @param parser_type: Specifies the parser to use for parsing the raw_data.
    @type attribute_map: dict
    @param attribute_map: Specifies how the keys in the parsed records should
        be mapped to the new keys.
    @type reverse_attribute_map: bool
    @param reverse_attribute_map: if this attribute is true then
        attribute_map will be reversed i.e. keys will become values and
        values will become keys.
    @type skip_records: int
    @param skip_records: This attribute contains the number of records which
        need to be skipped from the mapped py_dict. This can be used when
        parsed data contains records which have special values like column
        decorators ('------') which are not part of actual data.
    @rtype: list
    @return: Result list that holds the mapped py_dict for each parsed record
        in the raw_data.

    >>> raw_data = '''
    ... VNI      IP              MAC               Connection-ID
    ... 6796     192.168.139.11  00:50:56:b2:30:6e 1
    ... 6796     192.168.138.131 00:50:56:b2:40:33 2
    ... 6796     192.168.139.201 00:50:56:b2:75:d1 3
    ... '''
    >>> attribute_map = {'connection-id': 'connection_id'}
    >>> horizontal_parser = 'raw/horizontalTable'
    >>> pprint.pprint(parse_data_map_attributes(
    ...     raw_data, horizontal_parser, attribute_map))
    {'table': [{'connection_id': '1',
                'ip': '192.168.139.11',
                'mac': '00:50:56:b2:30:6e',
                'vni': '6796'},
               {'connection_id': '2',
                'ip': '192.168.138.131',
                'mac': '00:50:56:b2:40:33',
                'vni': '6796'},
               {'connection_id': '3',
                'ip': '192.168.139.201',
                'mac': '00:50:56:b2:75:d1',
                'vni': '6796'}]}
    >>> raw_data = '''
    ... ARP entry count: 2
    ...     label:  9123213
    ...            IP: 192.168.0.100
    ...            MAC: ff:ff:ff:ff:ff:ff
    ...            Flags: F
    ...
    ...    label:  0887973
    ...            IP: 192.168.0.101
    ...            MAC: 00:50:56:67:9e:ae
    ...            Flags: 9
    ... '''
    >>> vertical_parser = 'raw/verticalTable'
    >>> pprint.pprint(
    ...     parse_data_map_attributes(raw_data, vertical_parser, {}), width=78)
    {'table': [{'flags': '9',
                'ip': '192.168.0.101',
                'mac': '00:50:56:67:9e:ae'}]}
    """
    # Get the parsed data based on corresponding data parser.
    data_parser = get_data_parser(parser_type)
    py_dict = data_parser.get_parsed_data(raw_data, **parser_kwargs)
    if skip_records:
        py_dict['table'] = py_dict['table'][skip_records:]
    # Get the mapped py_dict based on attribute map.
    return map_attributes(
        attribute_map, py_dict, reverse_attribute_map=reverse_attribute_map)


def as_list(obj):
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


def procinfo_to_dict(info, sep=":"):
    """
    Returns a dict for /proc kind of formatted data
    Distributor ID: Ubuntu
    Description:    Ubuntu 12.04 LTS
    Release:        12.04
    Codename:       precise
    """
    lines = info.split("\n")
    inf = {}
    for line in lines:
        kv = line.split(sep)[:]
        if len(kv) < 2:
            kv.append("")
        if len(kv) > 2:
            kv = [kv[0], ':'.join(kv[1:])]
        (k, v) = kv[:]
        k = k.strip()
        v = v.strip()
        inf[k] = v
    return inf


def validate_list(obj):
    """
    Helper for ascertaining that the user passed in a list.

    @type obj: Any
    @param obj: Object to be validated as list.
    """
    if not isinstance(obj, list):
        raise ValueError("Expected a list , got %r" % obj)


def py_call_method_kwargs(obj, method, py_dict):
    """ Routine to call given method by converting
    the given dictionary into kwargs
    @param obj: reference to python object
    @param method: name of the method to call
    @param py_dict: arguments for method as dictionary
    @return the return value from method as it is
    """
    if py_dict is None:
        py_dict = {}
    random.seed('%s' % os.urandom(64))
    name = getattr(obj, 'name', None)
    if name is None:
        name = obj.__class__.__name__
    pylogger.debug(">>> IN %s.%s with kwargs:\n%s" %
                   (name, method, pprint.pformat(py_dict)))
    try:
        resolved_method = getattr(obj, method)
        res = resolved_method(**py_dict)
        pylogger.debug("<<< OUT %s.%s returned:\n%s" %
                       (name, method, pprint.pformat(res)))
        return res
    except Exception, e:
        # When exception is thrown, perl catches stack trace
        # as a string. It becomes very difficult to extract
        # information from that stack trace so in order for perl
        # layer to understand all the messages, we return the
        # a result hash which has values form exception object
        resultHash = dict(
            status_code=str(getattr(e, 'status_code', '')),
            response_data=str(getattr(e, 'response_data', '')),
            reason=str(getattr(e, 'reason', '')),
            exc=str(getattr(e, 'exc', e))
        )
        pylogger.exception("<<< ERR %s.%s errored, returning:\n%s" %
                           (name, method, pprint.pformat(resultHash)))
        return resultHash


def get_default(val, default):
    """
    Checks if val is None, if it is, returns default. Otherwise returns val.

    @type val: Any
    @param val: Variable value (can be None if it is not set already)
    @type default: Any
    @param default: Default value to be set if the variable is set to None.
    @rtype: Any
    @return: Returns the default value or the value of the variable if it was
        already set.
    >>> val = None
    >>> val = get_default(val, 'Default')
    >>> print val
    Default
    >>> val = 'SetAlready'
    >>> val = get_default(val, 'Default')
    >>> print val
    SetAlready
    """
    return val if val is not None else default


def compare_schema(user_schema, product_schema):
    """ Method to compare user_schema and product_schema

    @type user_schema: dict
    @param user_schema: schema sent by user
    @type product_schema: dict
    @param product_schema: schema retrieved from product
    @rtype: bool
    @return: True if user_schema and product_schema are matching otherwise
             False
    """
    result = True
    for attribute in user_schema:
        if attribute[0] != "_" and type(attribute) not in [file, dict]:
            if type(user_schema[attribute]) in IMMUTABLE_NOT_NONE:
                if (unicode(user_schema[attribute]) != unicode(
                        product_schema[attribute])):
                    return False
            elif isinstance(user_schema[attribute], list):
                # If length of list is not equal verification fails
                if (len(user_schema[attribute]) != len(
                        product_schema[attribute])):
                    return False

                for i in range(len(user_schema[attribute])):
                    element = user_schema[attribute][i]

                    if type(element) in IMMUTABLE_NOT_NONE:
                        if (unicode(element) != unicode(
                                product_schema[attribute][i])):
                            return False
                    else:
                        # Find whether each element in the list is present in
                        # product_schema.
                        for j in range(len(product_schema[attribute])):
                            result = compare_schema(
                                element, product_schema[attribute][j])
                            if result:
                                break
                        if not result:
                            return False
            elif isinstance(user_schema[attribute], dict):
                result = compare_schema(user_schema[attribute],
                                        product_schema[attribute])
            else:
                pylogger.error("Attribute type %s for %s not handled!" %
                               (type(user_schema[attribute]),
                                user_schema[attribute]))
                if not result:
                    return result
    return result


def get_launcher_ip(ifname):
    """ Method to get launcher IP using interface name i.e. eth0 etc.

    @param ifname: interface name
    @return: IP address
    """
    sock = socket.socket(socket.AF_INET,        # Internet
                         socket.SOCK_DGRAM)     # UDP
    ip_addr = socket.inet_ntoa(
        fcntl.ioctl(sock.fileno(), 0x8915, struct.pack('256s', ifname[:15]))
        [20:24])
    return ip_addr


def get_random_name(prefix=None):
    if prefix is None:
        prefix = "random"
    random_name = "%s_%s_%04d" % (prefix, current_date_time(),
                                  random.randint(0, 9999))
    return random_name


if __name__ == '__main__':
    import doctest
    doctest.testmod()
