import base_schema


class LoadBalancerApplicationRuleSchema(base_schema.BaseSchema):
    _schema_name = "applicationRule"
    def __init__(self, py_dict=None):
        """ Constructor to create
        LoadBalancerApplicationRuleSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(LoadBalancerApplicationRuleSchema, self).__init__()
        self.set_data_type('xml')
        self.applicationRuleId = None
        self.name = None
        self.script = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)