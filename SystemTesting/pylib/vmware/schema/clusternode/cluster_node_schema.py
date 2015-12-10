import vmware.common.base_schema as base_schema


class ClusterNodesSchema(base_schema.BaseSchema):
    """
    Schema Class for entries in the cluster node status of CCP node.

    >>> import pprint
    >>> py_dict = {'cluster_nodes': [
                        {'status': 'active',
                        'id_': 'b4e3c4c0-300f-4d03-8df7-9ab871c42346',
                        'controller_ip': '10.144.138.213'},
                        {'status': 'active',
                        'id_': '2bb27469-5025-4675-941b-b213b009b5b6',
                        'controller_ip': '10.144.139.127'},
                        {'status': 'active',
                        'id_': 'f803224c-8fb2-4b43-8f7c-e1cf469cf5fa',
                        'controller_ip': '10.144.139.7'}],
                    'is master': 'true',
                    'in majority': 'true'}
    >>> pyobj = ClusterNodesSchema(py_dict=py_dict)
    >>> pprint.pprint(pyobj.get_py_dict_from_object())
    {'cluster_nodes': [{'status': 'active',
                       'id_': 'b4e3c4c0-300f-4d03-8df7-9ab871c42346',
                       'controller_ip': '10.144.138.213'},
                       {'status': 'active',
                       'id_': '2bb27469-5025-4675-941b-b213b009b5b6',
                       'controller_ip': '10.144.139.127'},
                       {'status': 'active',
                       'id_': 'f803224c-8fb2-4b43-8f7c-e1cf469cf5fa',
                       'controller_ip': '10.144.139.7'}],
                       'is master': 'true',
                       'uuid': '2bb27469-5025-4675-941b-b213b009b5b6',
                       'in majority': 'true'}
    """
    _schema_name = "ClusterNodesSchema"

    def __init__(self, py_dict=None):

        super(ClusterNodesSchema, self).__init__()
        self.is_master = None
        self.in_majority = None
        self.cluster_nodes = [ClusterNodeEntrySchema()]
        if py_dict:
            self.get_object_from_py_dict(py_dict)


class ClusterNodeEntrySchema(base_schema.BaseSchema):
    """
    Schema Class for entries in cluster nodes.

    >>> import pprint
    >>> py_dict = {'cluster_nodes': [
                      {'status': 'active',
                      'id_': 'b4e3c4c0-300f-4d03-8df7-9ab871c42346',
                      'controller_ip': '10.144.138.213'},
                      {'status': 'active',
                      'id_': '2bb27469-5025-4675-941b-b213b009b5b6',
                      'controller_ip': '10.144.139.127'},
                      {'status': 'active',
                      'id_': 'f803224c-8fb2-4b43-8f7c-e1cf469cf5fa',
                      'controller_ip': '10.144.139.7'}]}
    >>> pprint.pprint(ClusterNodeEntrySchema(
    ...     py_dict=py_dict).get_py_dict_from_object(), width=78)
    {'status': 'active', 'controller_ip': '10.144.138.213',
    'id_': 'f803224c-8fb2-4b43-8f7c-e1cf469cf5fa'}
    """
    _schema_name = "ClusterNodeEntrySchema"

    def __init__(self, py_dict=None):
        """
        Initializes the ClusterNodeEntrySchema object attributes.

        @type py_dict: dict
        @param py_dict: Dictionary containing information for ccp node info
            entry as key-value.
        """
        super(ClusterNodeEntrySchema, self).__init__()
        self.controller_ip = None
        self.id_ = None
        self.status = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class ClusterNodeVIFsSchema(base_schema.BaseSchema):
    """
    Schema Class for entries in the cluster node status of CCP node.

    >>> import pprint
    >>> py_dict = {'table': [
                   {'vif_id': '209199cd-53b0-46cf-a5d3-2f57528f8055',
                    'port_id': '209199cd-53b0-46cf-a5d3-2f57528f8055',
                    'transportnode_id': '53ce9afc-7c31-442e-bafd-4594aa55845a',
                    'transportnode_ip': '10.24.20.22'},
                   {'vif_id': '72524586-3d1f-4d73-8f21-ab5f408645fe',
                    'port_id': '209199cd-53b0-46cf-a5d3-2f57528f8055',
                    'transportnode_id': 'f8dcac9a-f142-41d3-9ed6-15982856bf02',
                    'transportnode_ip': '10.24.20.23'}]}
    >>> pyobj = ClusterNodeVIFsSchema(py_dict=py_dict)
    >>> pprint.pprint(pyobj.get_py_dict_from_object())
    {'table': [{'vif_id': '209199cd-53b0-46cf-a5d3-2f57528f8055',
                'port_id': '209199cd-53b0-46cf-a5d3-2f57528f8055',
                'transportnode_id': '53ce9afc-7c31-442e-bafd-4594aa55845a',
                'transportnode_ip': '10.24.20.22'},
               {'vif_id': '72524586-3d1f-4d73-8f21-ab5f408645fe',
                'port_id': '0ef79f27-9220-4495-b058-82fd9582174b',
                'transportnode_id': 'f8dcac9a-f142-41d3-9ed6-15982856bf02',
                'transportnode_ip': '10.24.20.23'}]}
    """
    _schema_name = "ClusterNodeVIFsSchema"

    def __init__(self, py_dict=None):

        super(ClusterNodeVIFsSchema, self).__init__()
        self.table = [ClusterNodeVIFEntrySchema()]
        if py_dict:
            self.get_object_from_py_dict(py_dict)


class ClusterNodeVIFEntrySchema(base_schema.BaseSchema):
    """
    Schema Class for entries in cluster nodes.

    >>> import pprint
    >>> py_dict = {'table': [
                   {'vif_id': '72524586-3d1f-4d73-8f21-ab5f408645fe',
                    'port_id': '0ef79f27-9220-4495-b058-82fd9582174b',
                    'transportnode_id': 'f8dcac9a-f142-41d3-9ed6-15982856bf02',
                    'transportnode_ip': '10.24.20.23'}]}
    >>> pprint.pprint(ClusterNodeVIFEntrySchema(
    ...     py_dict=py_dict).get_py_dict_from_object(), width=78)
    {'vif_id': '72524586-3d1f-4d73-8f21-ab5f408645fe',
     'port_id': '0ef79f27-9220-4495-b058-82fd9582174b',
     'transportnode_id': 'f8dcac9a-f142-41d3-9ed6-15982856bf02',
     'transportnode_ip': '10.24.20.23'}
    """
    _schema_name = "ClusterNodeEntrySchema"

    def __init__(self, py_dict=None):
        """
        Initializes the ClusterNodeVIFEntrySchema object attributes.

        @type py_dict: dict
        @param py_dict: Dictionary containing information for ccp node info
            entry as key-value.
        """
        super(ClusterNodeVIFEntrySchema, self).__init__()
        self.vif_id = None
        self.port_id = None
        self.transportnode_id = None
        self.transportnode_ip = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class LogicalSwitchPortsSchema(base_schema.BaseSchema):
    """
    Schema Class for entries in the cluster node status of CCP node.

    >>> import pprint
    >>> py_dict = {'table': [
                   {'vif_id': '209199cd-53b0-46cf-a5d3-2f57528f8055',
                    'switch_id': '209199cd-53b0-46cf-a5d3-2f57528f8055',
                    'port_id': '53ce9afc-7c31-442e-bafd-4594aa55845a'
                   },
                   {'vif_id': '72524586-3d1f-4d73-8f21-ab5f408645fe',
                    'witch_id': '209199cd-53b0-46cf-a5d3-2f57528f8055',
                    'port_id': 'f8dcac9a-f142-41d3-9ed6-15982856bf02'
                   }]}
    >>> pyobj = LogicalSwitchPortsSchema(py_dict=py_dict)
    >>> pprint.pprint(pyobj.get_py_dict_from_object())
    {'table': [{'vif_id': '209199cd-53b0-46cf-a5d3-2f57528f8055',
                'switch_id': '209199cd-53b0-46cf-a5d3-2f57528f8055',
                'port_id': '53ce9afc-7c31-442e-bafd-4594aa55845a'
               },
               {'vif_id': '72524586-3d1f-4d73-8f21-ab5f408645fe',
                'switch_id': '0ef79f27-9220-4495-b058-82fd9582174b',
                'port_id': 'f8dcac9a-f142-41d3-9ed6-15982856bf02'
               }]}
    """
    _schema_name = "LogicalSwitchPortsSchema"

    def __init__(self, py_dict=None):

        super(LogicalSwitchPortsSchema, self).__init__()
        self.table = [LogicalSwitchPortEntrySchema()]
        if py_dict:
            self.get_object_from_py_dict(py_dict)


class LogicalSwitchPortEntrySchema(base_schema.BaseSchema):
    """
    Schema Class for entries in cluster nodes.

    >>> import pprint
    >>> py_dict = {'table': [
                   {'vif_id': '72524586-3d1f-4d73-8f21-ab5f408645fe',
                    'switch_id': '0ef79f27-9220-4495-b058-82fd9582174b',
                    'port_id': 'f8dcac9a-f142-41d3-9ed6-15982856bf02'
                   }]}
    >>> pprint.pprint(LogicalSwitchPortEntrySchema(
    ...     py_dict=py_dict).get_py_dict_from_object(), width=78)
    {'vif_id': '72524586-3d1f-4d73-8f21-ab5f408645fe',
     'switch_id': '0ef79f27-9220-4495-b058-82fd9582174b',
     'port_id': 'f8dcac9a-f142-41d3-9ed6-15982856bf02'}
    """
    _schema_name = "LogicalSwitchPortEntrySchema"

    def __init__(self, py_dict=None):
        """
        Initializes the LogicalSwitchPortEntrySchema object attributes.

        @type py_dict: dict
        @param py_dict: Dictionary containing information for ccp node info
            entry as key-value.
        """
        super(LogicalSwitchPortEntrySchema, self).__init__()
        self.vif_id = None
        self.switch_id = None
        self.port_id = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class ClusterIPEntrySchema(base_schema.BaseSchema):
    _schema_name = "ClusterIPEntrySchema"

    def __init__(self, py_dict=None):
        super(ClusterIPEntrySchema, self).__init__()
        self.controller_ip = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class ClusterStartupNodesSchema(base_schema.BaseSchema):
    _schema_name = "ClusterStartupNodesSchema"

    def __init__(self, py_dict=None):
        super(ClusterStartupNodesSchema, self).__init__()
        self.table = [ClusterIPEntrySchema()]

        if py_dict:
            self.get_object_from_py_dict(py_dict)


class ClusterManagerEntrySchema(base_schema.BaseSchema):
    _schema_name = "ClusterManagerEntrySchema"

    def __init__(self, py_dict=None):
        super(ClusterManagerEntrySchema, self).__init__()
        self.ip = None
        self.port = None
        self.thumbprint = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


class ClusterManagerNodesSchema(base_schema.BaseSchema):
    _schema_name = "ClusterManagerNodesSchema"

    def __init__(self, py_dict=None):
        super(ClusterManagerNodesSchema, self).__init__()
        self.table = [ClusterManagerEntrySchema()]

        if py_dict:
            self.get_object_from_py_dict(py_dict)


if __name__ == '__main__':
    import doctest
    doctest.testmod()
