import vmware.common.base_schema_v2 as base_schema_v2


class ShowEdgeVersionSchema(base_schema_v2.BaseSchema):

    """
    Schema Class for show version command executed on Edge VM
    >>> import pprint
    >>> py_dict =  {'name': 'NSX Edge',
    ...             'version': '7.0.0.0.0',
    ...             'build_number': '2252106',
    ...             'kernel': '3.2.62'} #noqa
    >>> pyobj = ShowEdgeVersionSchema(py_dict=py_dict)
    >>> pyobj.get_py_dict_from_object()
    {'kernel': None, 'version': None, 'build_number': None, 'name': None}
    """

    name = None
    version = None
    build_number = None
    kernel = None

if __name__ == "__main__":
    import doctest
    doctest.testmod()
