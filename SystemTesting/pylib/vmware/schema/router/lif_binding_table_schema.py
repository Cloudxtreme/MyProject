import doctest

import vmware.common.base_schema_v2 as base_schema_v2


class LIFBindingTableEntrySchema(base_schema_v2.BaseSchema):
    """
    Schema Class for entries in LIF binding table.

    >>> import pprint
    >>> py_dict = {'dhcp_relay_servers': '192.168.1.3', 'name': 'LS_10_20'}
    >>> pprint.pprint(LIFBindingTableEntrySchema(
    ...     py_dict=py_dict).get_py_dict_from_object())
    {'dhcp_relay_servers': '192.168.1.3', 'name': 'LS_10_20'}
    """
    name = None
    dhcp_relay_servers = None


class LIFBindingTableSchema(base_schema_v2.BaseSchema):
    """
    Schema class for LIF binding Table.

    >>> import pprint
    >>> py_dict = {
    ...     'table': [{'name': 'LS_10_20',
    ...                'dhcp_relay_servers': '192.168.1.3'},
    ...                {'name': 'LS_10_21',
    ...                'dhcp_relay_servers': '192.168.2.3'}]}
    >>> pprint.pprint(LIFBindingTableSchema(
    ...     py_dict=py_dict).get_py_dict_from_object())
    {'table': [{'dhcp_relay_servers': '192.168.1.3', 'name': 'LS_10_20'},
               {'dhcp_relay_servers': '192.168.2.3', 'name': 'LS_10_21'}]}
    """
    table = (LIFBindingTableEntrySchema,)


if __name__ == '__main__':
    doctest.testmod()
