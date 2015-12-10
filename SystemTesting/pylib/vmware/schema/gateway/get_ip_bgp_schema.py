import vmware.common.base_schema_v2 as base_schema_v2


class GetIPBGPEntrySchema(base_schema_v2.BaseSchema):
    """
    Schema class for entries in edge vm's show ip bgp command table

    >>> py_dict= {
    ... 'origin': '?', 'network': '78.0.0.0/8', 'weight': '60', 'metric': '0', 'locprf': '100', 'nexthop': '192.168.80.2', 'scode': '>'}  # noqa
    >>> pyobj = GetIPBGPNeighborsEntrySchema(py_dict=py_dict)
    >>> py_dict == pyobj.get_py_dict_from_object()
    True
    """

    origin = None
    network = None
    weight = None
    metric = None
    locprf = None
    scode = None
    nexthop = None


class GetIPBGPSchema(base_schema_v2.BaseSchema):
    """
    Schema class for show ip bgp command table

    >>> py_dict = {'table': [{'origin': '?', 'network': '78.0.0.0/8', 'weight': '60', 'metric': '0', 'locprf': '100', 'nexthop': '192.168.80.2', 'scode': '>'}]}  # noqa
    >>> pyobj = GetIPBGPSchema(py_dict=py_dict)
    >>> py_dict == pyobj.get_py_dict_from_object()
    True
    """

    table = (GetIPBGPEntrySchema,)

if __name__ == '__main__':
    import doctest
    doctest.testmod()