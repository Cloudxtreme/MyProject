import base_schema

class QueryDaemonSchema(base_schema.BaseSchema):
    _schema_name = "queryDaemon"
    def __init__(self, py_dict=None):
        """ Constructor to create QueryDaemonSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(QueryDaemonSchema, self).__init__()
        self.set_data_type('xml')
        self.enabled = None
        self.port = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)