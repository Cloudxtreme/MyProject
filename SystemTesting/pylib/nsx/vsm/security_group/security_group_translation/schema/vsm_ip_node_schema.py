import base_schema
from vsm_ip_addresses_schema import IPAddressesSchema

class IPNodeSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "ipNode"
    def __init__(self, py_dict=None):
        """ Constructor to create IPNodeSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(IPNodeSchema, self).__init__()
        self.set_data_type('xml')
        self.ipAddresses = [IPAddressesSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)


