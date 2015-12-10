import base_schema
from resource_link_schema import ResourceLinkSchema

class ResourceSchema(base_schema.BaseSchema):
    _schema_name = "resource"

    def __init__(self, py_dict=None):
        """ Constructor to create ResourceSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ResourceSchema, self).__init__()
        self._self = ResourceLinkSchema()
        self.schema = None
        self._links = [ResourceLinkSchema()]
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)