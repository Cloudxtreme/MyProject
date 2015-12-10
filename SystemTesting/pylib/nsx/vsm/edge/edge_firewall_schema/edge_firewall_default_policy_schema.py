import base_schema


class FirewallDefaultPolicySchema(base_schema.BaseSchema):
    _schema_name = "defaultPolicy"
    def __init__(self, py_dict=None):
        """ Constructor to create FirewallDefaultPolicySchema object

        @param py_dict : python dictionary to construct this object
        """
        super(FirewallDefaultPolicySchema, self).__init__()
        self.set_data_type('xml')
        self.action = None
        self.loggingEnabled = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)