import base_schema

class TagSchema(base_schema.BaseSchema):
    _schema_name = "tag"

    def __init__(self, py_dict=None):
        """ Constructor to create TagSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(TagSchema, self).__init__()
        self.scope = None
        self.tag = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)