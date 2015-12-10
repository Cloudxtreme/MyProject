import base_schema


class FirewallRuleDestinationSchema(base_schema.BaseSchema):
    _schema_name = "destination"
    def __init__(self, py_dict=None):
        """ Constructor to create FirewallRuleDestinationSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(FirewallRuleDestinationSchema, self).__init__()
        self.set_data_type('xml')
        self.vnicGroupId = None
        self.groupingObjectId = None
        self.ipAddress = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
