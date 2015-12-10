import base_schema
from resource_link_schema import ResourceLinkSchema
from tag_schema import TagSchema

class PoolAllocatedResourceSchema(base_schema.BaseSchema):
    _schema_name = "poolallocatedresource"

    def __init__(self, py_dict=None):
        """ Constructor to create PoolAllocatedResourceSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(PoolAllocatedResourceSchema, self).__init__()
        self._self = ResourceLinkSchema()
        self.tags = [TagSchema()]
        self._links = [ResourceLinkSchema()]
        self.schema = None
        self.id = None
        self.revision = None
        self.allocation_time = None
        self.allocation_token = None
        self.allocation_user = None
        self.comment = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)