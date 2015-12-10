import base_schema
from resource_link_schema import ResourceLinkSchema
from tag_schema import TagSchema

class LogicalPipelineStageSchema(base_schema.BaseSchema):
    _schema_name = "logicalpipelinestage"

    def __init__(self, py_dict=None):
        """ Constructor to create LogicalPipelineStageSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(LogicalPipelineStageSchema, self).__init__()
        self._self = ResourceLinkSchema()
        self.display_name = None
        self.uuid = None
        self.tags = [TagSchema()]
        self._links = [ResourceLinkSchema()]
        self.revision = None
        self.schema = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)