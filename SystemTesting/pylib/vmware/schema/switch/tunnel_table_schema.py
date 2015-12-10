import vmware.common.base_schema_v2 as base_schema_v2


class TunnelTableEntrySchema(base_schema_v2.BaseSchema):
    """
    Schema class for returning tunnel ip and state.

    >>> import pprint
    >>> py_dict = {'remote_ip': '10.146.103.178','forwarding_state': 'true'}
    >>> pyobj = TunnelTableEntrySchema(py_dict=py_dict)
    >>> pprint.pprint(pyobj.get_py_dict_from_object())
    {'forwarding_state': 'true', 'remote_ip': '10.146.103.178'}
    """
    remote_ip = None
    forwarding_state = None


class TunnelTableSchema(base_schema_v2.BaseSchema):
    """
    Schema class for returning tunnel ip and state.

    >>> import pprint
    >>> py_dict = {
    ...     'table':[
    ...               {'remote_ip': '10.146.103.178',
    ...                'forwarding_state': 'true'},
    ...             ]
    ...           }
    >>> pyobj = TunnelTableSchema(py_dict=py_dict)
    >>> pprint.pprint(pyobj.get_py_dict_from_object())
    {'table': [{'forwarding_state': 'true', 'remote_ip': '10.146.103.178'}]}
    """
    table = (TunnelTableEntrySchema,)


if __name__ == '__main__':
    import doctest
    doctest.testmod()
