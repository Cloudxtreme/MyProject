import vmware.common.base_schema_v2 as base_schema_v2


class GetIPBGPNeighborsEntrySchema(base_schema_v2.BaseSchema):
    """
    Schema class for entries in edge vm's show ip bgp neighbors <ip> command

    >>> py_dict= {
    ... 'local_host': '192.168.50.1', 'local_port': '179', 'bgp_state': 'established', 'remote_host': '192.168.50.2', 'remote_port': '47813', 'bgp_neighbor': '192.168.50.2', 'keep_alive_interval': '60', 'hold_time': '180', 'bgp_status': 'up'}  # noqa
    >>> pyobj = GetIPBGPNeighborsEntrySchema(py_dict=py_dict)
    >>> py_dict == pyobj.get_py_dict_from_object()
    True
    """
    local_host = None
    local_port = None
    bgp_state = None
    remote_host = None
    remote_port = None
    bgp_neighbor = None
    keep_alive_interval = None
    hold_time = None
    bgp_status = None


class GetIPBGPNeighborsSchema(base_schema_v2.BaseSchema):
    """
    Schema class for entries in edge vm's show ip bgp neighbors <ip> command

    >>> py_dict = {'table':[{'local_host': '192.168.50.1',
    ...            'local_port': '179',
    ...            'bgp_state': 'established',
    ...            'remote_host': '192.168.50.2',
    ...            'remote_port' : '47813',
    ...            'bgp_neighbor': '192.168.50.2',
    ...            'keep_alive_interval': '60',
    ...            'hold_time': '180',
    ...            'bgp_status': 'up'}]}
    >>> pyobj = GetIPBGPNeighborsSchema(py_dict=py_dict)
    >>> py_dict == pyobj.get_py_dict_from_object()
    True
    """
    table = (GetIPBGPNeighborsEntrySchema,)

if __name__ == '__main__':
    import doctest
    doctest.testmod()