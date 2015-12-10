import base_schema

class InterfaceOptionsSchema(base_schema.BaseSchema):
    _schema_name = "interfaceoptions"

    def __init__(self, py_dict=None):
        """ Constructor to create InterfaceOptionsSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(InterfaceOptionsSchema, self).__init__()
        self.enable_send_redirects = None
        self.enable_proxy_arp = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
