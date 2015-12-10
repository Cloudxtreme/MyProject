import base_schema


class LoadBalancerPoolMemberSchema(base_schema.BaseSchema):
    _schema_name = "member"
    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerPoolMemberSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(LoadBalancerPoolMemberSchema, self).__init__()
        self.set_data_type('xml')
        self.memberId = None
        self.ipAddress = None
        self.weight = None
        self.port = None
        self.minConn = None
        self.maxConn = None
        self.name = None
        self.monitorPort = None
        self.condition = None
        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)