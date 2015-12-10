import base_schema

class SSLVPNConfigLayoutConfigurationSchema(base_schema.BaseSchema):
    _schema_name = "layoutConfiguration"
    def __init__(self, py_dict=None):
        """ Constructor to create
        SSLVPNConfigLayoutConfigurationSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(SSLVPNConfigLayoutConfigurationSchema, self).__init__()
        self.set_data_type('xml')
        self.portalTitle = None
        self.companyName = None
        self.logoExtention = None
        self.logoUri = None
        self.logoBackgroundColor = None
        self.titleColor = None
        self.topFrameColor = None
        self.menuBarColor = None
        self.rowAlternativeColor = None
        self.bodyColor = None
        self.rowColor = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)