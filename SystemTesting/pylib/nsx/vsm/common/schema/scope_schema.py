import base_schema


class ScopeSchema(base_schema.BaseSchema):
    """"""
    _schema_name = "scope"
    def __init__(self, py_dict=None):
        """ Constructor to create ScopeSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(ScopeSchema, self).__init__()
        self.set_data_type('xml')
        self.id = None
        self.objectTypeName = None
        self.name = None
