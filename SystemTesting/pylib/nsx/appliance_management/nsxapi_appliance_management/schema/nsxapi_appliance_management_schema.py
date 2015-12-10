import base_schema

class NSXAPIApplianceManagementSchema(base_schema.BaseSchema):
    _schema_name = "result"

    def __init__(self, py_dict=None):
        """ Constructor to create NSXAPIApplianceManagementSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(NSXAPIApplianceManagementSchema, self).__init__()
        self.set_data_type('xml')
        self.result = None
        self.operationStatus = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
