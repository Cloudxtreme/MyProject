import base_schema

class CLISettingsSchema(base_schema.BaseSchema):
    _schema_name = "cliSettings"
    def __init__(self, py_dict=None):
        """ Constructor to create CLISettingsSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(CLISettingsSchema, self).__init__()
        self.set_data_type('xml')
        self.remoteAccess = None
        self.userName = None
        self.password = None
        self.sshLoginBannerText = None
        self.passwordExpiry = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)