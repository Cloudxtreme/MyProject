import base_schema

class EdgeSummarySchema(base_schema.BaseSchema):
    _schema_name = "edgeSummary"
    def __init__(self, py_dict = None):
        """ Constructor to create EdgeSummary object

        @param py_dict : python dictionary to construct this object
        """
        super(EdgeSummarySchema, self).__init__()
        self.set_data_type('xml')
        self.name = None
        self.objectId = None
        self.edgeAssistId = None
        self.edgeAssistInstanceName = None

        if py_dict is not None:
           self.get_object_from_py_dict(py_dict)

