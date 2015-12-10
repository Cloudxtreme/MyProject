import base_schema

class DNSSettingsSchema(base_schema.BaseSchema):
    _schema_name = "dnssettings"

    def __init__(self, py_dict=None):
        """ Constructor to create DNSSettingsSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(DNSSettingsSchema, self).__init__()
        self.domain_name = None
        self.primary_dns = None
        self.secondary_dns = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
