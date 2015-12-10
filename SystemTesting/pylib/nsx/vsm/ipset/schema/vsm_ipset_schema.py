import base_schema
from type_schema import TypeSchema
from scope_schema import ScopeSchema

class IPSetSchema(base_schema.BaseSchema):
    _schema_name = "ipset"

    def __init__(self, py_dict=None):
        """ Constructor to create IPSet object

        @param py_dict : python dictionary to construct this object
        """
        super(IPSetSchema, self).__init__()
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