import base_schema


class TORBindingSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "hardwaregatewaybinding"
    def __init__(self, py_dict=None):
        """ Constructor to create TORBindingSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(TORBindingSchema, self).__init__()
        self.set_data_type('xml')
        self.hardwareGatewayId = 0
        self.virtualWire = None
        self.switchName = None
        self.portName = None
        self.vlan = None
        self.id = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
