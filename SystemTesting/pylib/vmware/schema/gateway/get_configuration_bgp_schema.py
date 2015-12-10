import vmware.common.base_schema_v2 as base_schema_v2


class BGPNeighboursSchema(base_schema_v2.BaseSchema):

    filters = None
    forwardingaddress = None
    holddowntimer = None
    ipaddress = None
    keepalivetimer = None
    name = None
    password = None
    protocoladdress = None
    remoteas = None
    srcipaddress = None
    weight = None


class BGPRedistributeRuleSchema(base_schema_v2.BaseSchema):

    action = None
    fromospf = None
    fromisis = None
    frombgp = None
    fromstatic = None
    fromconnected = None
    id_ = None
    prefix = None


class BGPRedistributeSchema(base_schema_v2.BaseSchema):
    enabled = None
    rules = (BGPRedistributeRuleSchema,)


class BGPConfigureSchema(base_schema_v2.BaseSchema):

    defaultoriginate = None
    enabled = None
    gracefulrestart = None
    localas = None
    neighbors = (BGPNeighboursSchema,)
    redistribute = BGPRedistributeSchema


class GetConfigurationBGPSchema(base_schema_v2.BaseSchema):

    """
    >>> py_dict={
    ... 'bgp': {
    ...     'gracefulrestart': True,
    ...     'redistribute': {
    ...        'rules': [{'fromospf': False, 'fromisis': False, 'fromconnected': True, 'action': 'permit', 'prefix': None, 'frombgp': False, 'fromstatic': False, 'id': 0}], # noqa
    ...        'enabled': True},
    ...     'defaultoriginate': False,
    ...     'localas': 700,
    ...     'enabled': True,
    ...     'neighbors': [
    ...        {'name': 'Neighbour 1', 'holddowntimer': 180, 'weight': 60, 'remoteas': 800, 'protocoladdress': None, 'filters': [], 'forwardingaddress': None, 'password': None, 'ipaddress': '192.168.77.8', 'srcipaddress': '192.168.50.1', 'keepalivetimer': 60}, # noqa
    ...        {'name': 'Neighbour 2', 'holddowntimer': 180, 'weight': 60, 'remoteas': 400, 'protocoladdress': None, 'filters': [], 'forwardingaddress': None, 'password': None, 'ipaddress': '192.168.76.2', 'srcipaddress': '192.168.50.2','keepalivetimer': 60}   # noqa
    ...        ]
    ...     }
    ... }
    >>>
    >>> pyobj = GetConfigurationBGPSchema(py_dict=py_dict)
    >>> py_dict == pyobj.get_py_dict_from_object()
    True
    """
    bgp = BGPConfigureSchema


if __name__ == '__main__':
    import doctest
    doctest.testmod()
