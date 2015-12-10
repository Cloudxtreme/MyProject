import vmware.common.base_schema_v2 as base_schema_v2


class GetIPRouteEntrySchema(base_schema_v2.BaseSchema):
    """
    Schema class for entries in edge vm's show ip route table.

    >>> py_dict= {
    ... 'via': 'via', 'nexthop': '10.117.83.253', 'code': 'S', 'network': '0.0.0.0/0', 'admindist_metric': '[1/1]'} # noqa
    >>> pyobj = GetIPRouteEntrySchema(py_dict=py_dict)
    >>> py_dict == pyobj.get_py_dict_from_object()
    True
    """

    code = None
    network = None
    admindist_metric = None
    via = None
    nexthop = None


class GetIPRouteSchema(base_schema_v2.BaseSchema):
    """
    Schema class for edge vm's show ip route table.

    >>> py_dict = {'table': [{'via': 'via', 'nexthop': '10.117.83.253', 'code': 'S', 'network': '0.0.0.0/0', 'admindist_metric': '[1/1]'}]} # noqa
    >>> pyobj = GetIPRouteSchema(py_dict=py_dict)
    >>> py_dict == pyobj.get_py_dict_from_object()
    True
    """

    table = (GetIPRouteEntrySchema,)

if __name__ == '__main__':
    import doctest
    doctest.testmod()
