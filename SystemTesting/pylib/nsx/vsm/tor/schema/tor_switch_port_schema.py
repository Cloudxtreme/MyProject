import base_schema


class TORSwitchPortSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "hardwaregatewayswitchport"
    def __init__(self, py_dict=None):
        """ Constructor to create TORSwitchPortSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(TORSwitchPortSchema, self).__init__()
        self.set_data_type('xml')
        self.portname = None
        self.description = None
        self.faults = None
