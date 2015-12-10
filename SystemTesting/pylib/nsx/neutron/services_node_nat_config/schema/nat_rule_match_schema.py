import base_schema

class NatRuleMatchSchema(base_schema.BaseSchema):
    _schema_name = "natrulematch"

    def __init__(self, py_dict=None):
        """ Constructor to create NatRuleMatchSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(NatRuleMatchSchema, self).__init__()
        self.protocol = None
        self.ethertype = None
        self.logging_enabled = None
        self.enabled = None
        self.source_ip_addresses = None
        self.destination_ip_addresses = None
        self.source_port = None
        self.destination_port = None
        self.icmp_type = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)