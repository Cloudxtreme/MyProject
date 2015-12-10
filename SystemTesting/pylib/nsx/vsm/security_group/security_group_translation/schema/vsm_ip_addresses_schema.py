import base_schema


class IPAddressesSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "ipAddresses"
    def __init__(self, py_dict=None):
        """ Constructor to create IPAddressesSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(IPAddressesSchema, self).__init__()
        self.string = [str]
        self.set_data_type('xml')

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)

