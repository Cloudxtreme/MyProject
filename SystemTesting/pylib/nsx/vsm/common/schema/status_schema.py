import base_schema

class StatusSchema(base_schema.BaseSchema):
    _schema_name = "status"
    def __init__(self, py_dict=None):
        """ Constructor to create StatusSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(StatusSchema, self).__init__()
        self.readiness = None

        if py_dict is not None:
           self.get_object_from_py_dict(py_dict)
