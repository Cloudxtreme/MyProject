import vmware.common.base_schema_v2 as base_schema_v2


class ConnectionTableEntrySchema(base_schema_v2.BaseSchema):
    """
    Schema Class for entries in the connection table of the controller.

    >>> import pprint
    >>> py_dict = {'adapter_ip': '10.145.120.12',
    ...            'port': '5341',
    ...            'id': '1324'}
    >>> pyobj = ConnectionTableEntrySchema(py_dict=py_dict)
    >>> pprint.pprint(pyobj.get_py_dict_from_object())
    {'adapter_ip': '10.145.120.12', 'id': '1324', 'port': '5341'}
    """
    adapter_ip = None
    port = None
    id_ = None


class ConnectionTableSchema(base_schema_v2.BaseSchema):
    """
    Schema class for connection table.

    >>> import pprint
    >>> py_dict = {'table': [{'adapter_ip': '10.146.121.45',
    ...                       'port': '5463',
    ...                       'id': '531'}]}
    >>> pyobj = ConnectionTableSchema(py_dict=py_dict)
    >>> pprint.pprint(pyobj.get_py_dict_from_object())
    {'table': [{'adapter_ip': '10.146.121.45', 'id': '531', 'port': '5463'}]}
    """
    table = (ConnectionTableEntrySchema,)

if __name__ == '__main__':
    import doctest
    doctest.testmod()
