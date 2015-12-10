import base_schema

class VendorTemplateSPSchema(base_schema.BaseSchema):
    _schema_name = "vendorTemplate"

    def __init__(self, py_dict=None):
        """ Constructor to create VendorTemplateSPSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(VendorTemplateSPSchema, self).__init__()
        self.set_data_type('xml')
        self.id = None
        self.name = None
        self.description = None
        self.idFromVendor = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
