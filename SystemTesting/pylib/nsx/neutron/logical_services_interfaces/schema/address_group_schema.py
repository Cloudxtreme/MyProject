import base_schema

class AddressGroupSchema(base_schema.BaseSchema):
    _schema_name = "addressgroup"

    def __init__(self, py_dict=None):
        """ Constructor to create AddressGroup object

        @param py_dict : python dictionary to construct this object
        """
        super(AddressGroupSchema, self).__init__()
        self.primary_ip_address = None
        self.subnet = None
        self.secondary_ip_addresses = [str]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
