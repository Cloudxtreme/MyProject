import vmware.common.base_schema_v2 as base_schema_v2


class ShowEdgeClusterStatusSchema(base_schema_v2.BaseSchema):

    """
    Schema Class for show edge-cluster status command executed on Edge VM
     >>> py_dict= {'healthcheck_status_channel': 'Up', 'ha_unit_state': \
     'Up', 'sessions': [{'status': 'up', 'from_ip': '10.110.62.255', \
     'to  _ip': '10.110.63.67'}, {'status': 'up', 'from_ip': \
     '169.255.255.242', 'to_ip': '169.255.255.241'}], 'ha_admin_state': \
     'Up', 'healthcheck_config_channel': 'Up', 'routing_status': 'Up', \
     'frequency': '1', 'deadtime': '15', 'ha_status': 'Active', \
     'routing_status_channel': 'Up'}
     >>> pyobj = ShowEdgeClusterStatusSchema(py_dict=py_dict)
     >>> py_dict ==  pyobj.get_py_dict_from_object()
     True
     """

    ha_status = None
    ha_unit_state = None
    ha_admin_state = None
    frequency = None
    deadtime = None
    routing_status_channel = None
    routing_status = None
    healthcheck_config_channel = None
    healthcheck_status_channel = None
    sessions = None

if __name__ == '__main__':
    import doctest
    doctest.testmod()
