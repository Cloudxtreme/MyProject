import base_schema


class TORSwitchSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "hardwaregatewayswitch"
    def __init__(self, py_dict=None):
        """ Constructor to create TORSwitchSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(TORSwitchSchema, self).__init__()
        self.set_data_type('xml')
        self.switchname = None
        self.description = None
        self.faults = None
