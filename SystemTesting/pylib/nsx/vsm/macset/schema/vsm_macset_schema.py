import base_schema
from type_schema import TypeSchema
from scope_schema import ScopeSchema

class MACSetSchema(base_schema.BaseSchema):
    _schema_name = "macset"

    def __init__(self, py_dict=None):
        """ Constructor to create MACSet object

        @param py_dict : python dictionary to construct this object
        """
        super(MACSetSchema, self).__init__()
        self.set_data_type('xml')
        self.name = None
        self.description = None
        self.inheritanceAllowed = None
        self.value = None
        self.revision = None
        self.objectId = None
        self.objectTypeName = None
        self.vsmUuid = None
        self.clientHandle = None
        self.extendedAttributes = None
        self.type = TypeSchema()
        self.scope = ScopeSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
