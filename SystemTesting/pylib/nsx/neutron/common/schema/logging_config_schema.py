import base_schema
import resource_link_schema

class LoggingConfigSchema(base_schema.BaseSchema):
    _schema_name = "loggingconfig"

    def __init__(self, py_dict=None):

        super(LoggingConfigSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.enable = None
        self.log_level = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.revision = None
        self.schema = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)