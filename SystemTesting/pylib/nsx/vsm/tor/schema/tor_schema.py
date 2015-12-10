import base_schema


class TORSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "HardwareGateway"
    def __init__(self, py_dict=None):
        """ Constructor to create TORSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(TORSchema, self).__init__()
        self.set_data_type('xml')
        self.objectId = None
        self.name = None
        self.thumbprint = None
        self.description = None
        self.managementIp = None
        self.status = None
        self.bfdEnabled = None
