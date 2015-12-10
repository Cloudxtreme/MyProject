import base_schema


class FirewallRuleApplicationServiceSchema(base_schema.BaseSchema):
    _schema_name = "service"
    def __init__(self, py_dict=None):
        """ Constructor to create FirewallRuleApplicationServiceSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(FirewallRuleApplicationServiceSchema, self).__init__()
        self.set_data_type('xml')
        self.protocol = None
        self.port = None
        self.sourcePort = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)