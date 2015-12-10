import base_schema


class DhcpCliLoggingSchema(base_schema.BaseSchema):
    """"""
    _schema_name = "dhcpClilogging"
    def __init__(self, py_dict=None):
        """ Constructor to create DhcpLoggingSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(DhcpCliLoggingSchema, self).__init__()
        self.enable = None
        self.logLevel = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

