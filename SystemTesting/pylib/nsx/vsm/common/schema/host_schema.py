import base_schema
from type_schema import TypeSchema
from scope_schema import ScopeSchema

class HostSchema(base_schema.BaseSchema):
    _schema_name = "host"
    def __init__(self, py_dict=None):
        """ Constructor to create HostSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(HostSchema, self).__init__()
        self.objectId = None
        self.objectTypeName = None
        self.vsmUuid = None
        self.revision = None
        self.type = TypeSchema()
        self.name = None
        self.scope = ScopeSchema()
        self.clientHandle = None
        self.extendedAttributes = None

        if py_dict is not None:
           self.get_object_from_py_dict(py_dict)

