import base_schema


class TORCreateSpecSchema(base_schema.BaseSchema):
    _schema_name = 'HardwareGatewaySpec'
    def __init__(self, py_dict=None):
        """ Constructor to create TORCreateSpecSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(TORCreateSpecSchema, self).__init__()
        self.set_data_type('xml')
        self.name = None
        self.certificate = None
        self.bfdEnabled = None
        self.id = None
        self.description = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
