import base_schema


class EdgeNATRuleSchema(base_schema.BaseSchema):
    _schema_name = "natRule"
    def __init__(self, py_dict=None):
        """ Constructor to create EdgeNATRuleSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(EdgeNATRuleSchema, self).__init__()
        self.set_data_type('xml')
        self.ruleId = None
        self.ruleTag = None
        self.ruleType = None
        self.action = None
        self.vnic = None
        self.originalAddress = None
        self.translatedAddress = None
        self.loggingEnabled = None
        self.enabled = None
        self.description = None
        self.protocol = None
        self.originalPort = None
        self.translatedPort = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)