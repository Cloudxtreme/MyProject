import base_schema
from resource_link_schema import ResourceLinkSchema
from tag_schema import TagSchema
from resource_schema import ResourceSchema

class ServiceGroupSchema(base_schema.BaseSchema):
    _schema_name = "servicegroup"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceGroupSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ServiceGroupSchema, self).__init__()
        self._self = ResourceLinkSchema()
        self.display_name = None
        self.description = None
        self._create_user = None
        self.tags = [TagSchema()]
        self._create_time = None
        self._links = [ResourceLinkSchema()]
        self.members = [ResourceSchema()]
        self._last_modified_time = None
        self.schema = None
        self._last_modified_user = None
        self.id = None
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)