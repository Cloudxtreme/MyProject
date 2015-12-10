import base_schema


class ResourceLinkSchema(base_schema.BaseSchema):
    _schema_name = "resourceLink"

    def __init__(self, py_dict=None):
        """ Constructor to create ResourceLinkSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ResourceLinkSchema, self).__init__()
        self.href = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
