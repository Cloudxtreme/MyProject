import base_schema

class DatacenterScopeSchema(base_schema.BaseSchema):
    _schema_name = "scope"

    def __init__(self, py_dict=None):
        """ Constructor to create DatacenterScopeSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(DatacenterScopeSchema, self).__init__()
        self.set_data_type('xml')
        self.id = None
        self.objectTypeName = None
        self.name = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)