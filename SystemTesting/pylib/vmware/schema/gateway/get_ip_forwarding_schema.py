import vmware.common.base_schema_v2 as base_schema_v2


class GetIPForwardingEntrySchema(base_schema_v2.BaseSchema):
    """
    Schema class for entries in edge vm's ip forwarding table.

    >>> py_dict = {
    ... 'nexthop': 'NULL',
    ... 'vnicname': 'vNic_3',
    ... 'code': 'C>*',
    ... 'network': '10.24.28.0/22',
    ... 'via': 'isdirectlyconnected'}
    >>> pyobj = GetIPForwardingEntrySchema(py_dict=py_dict)
    >>> py_dict == pyobj.get_py_dict_from_object()
    True
    """

    code = None
    network = None
    via = None
    vnicname = None
    nexthop = None


class GetIPForwardingSchema(base_schema_v2.BaseSchema):
    """
    Schema class for edge vm's ip forwarding table.

    >>> py_dict = {'table': [{
    ...     'nexthop': 'NULL',
    ...     'vnicname': 'vNic_3',
    ...     'code': 'C>*',
    ...     'network': '10.24.28.0/22',
    ...     'via': 'isdirectlyconnected'}]}
    >>> pyobj = GetIPForwardingSchema(py_dict=py_dict)
    >>> py_dict == pyobj.get_py_dict_from_object()
    True
    """

    table = (GetIPForwardingEntrySchema,)


if __name__ == '__main__':
    import doctest
    doctest.testmod()
