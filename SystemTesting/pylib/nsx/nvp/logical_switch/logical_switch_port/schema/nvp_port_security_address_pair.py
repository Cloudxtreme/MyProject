import base_schema

class PortSecurityAddressPairSchema(base_schema.BaseSchema):
    _schema_name = "portsecurityaddresspair"

    def __init__(self, py_dict=None):
        """ Constructor to create LogicalSwitchPortSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(PortSecurityAddressPairSchema, self).__init__()
        self.ip_address = None
        self.mac_address = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
