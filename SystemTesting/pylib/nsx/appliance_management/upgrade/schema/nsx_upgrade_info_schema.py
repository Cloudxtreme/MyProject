import base_schema

class NSXUpgradeInfoSchema(base_schema.BaseSchema):
    _schema_name = "upgradeInformation"

    def __init__(self, py_dict=None):
        """ Constructor to create NSX Upgrade Information Schema object

        @param py_dict : python dictionary to construct this object
        """
        super(NSXUpgradeInfoSchema, self).__init__()
        self.set_data_type('xml')
        self.fromVersion = None
        self.toVersion = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
