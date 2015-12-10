import base_schema

class SysLogServerAddressesSchema(base_schema.BaseSchema):
    _schema_name = "serverAddresses"
    def __init__(self, py_dict=None):
        """ Constructor to create SysLogServerAddressesSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(SysLogServerAddressesSchema, self).__init__()
        self.set_data_type('xml')
        self.ipAddress = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)