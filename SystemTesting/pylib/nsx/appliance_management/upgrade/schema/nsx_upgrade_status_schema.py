import base_schema

class NSXUpgradeStatusSchema(base_schema.BaseSchema):
    _schema_name = "upgradeStatus"

    def __init__(self, py_dict=None):
        """ Constructor to create NSXUpgradeStatusSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(NSXUpgradeStatusSchema, self).__init__()
        self.set_data_type('xml')
        self.status = None
        self.existingBundleFileName = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
