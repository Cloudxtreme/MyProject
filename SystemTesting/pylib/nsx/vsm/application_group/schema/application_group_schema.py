import base_schema
from type_schema import TypeSchema
from scope_schema import ScopeSchema
from application_schema import ApplicationSchema
from extended_attribute_schema import ExtendedAttributeSchema

class ApplicationGroupSchema(base_schema.BaseSchema):
    _schema_name = "applicationGroup"

    def __init__(self, py_dict=None):
        """ Constructor to create ApplicationGroupSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ApplicationGroupSchema, self).__init__()
        self.set_data_type('xml')
        self.name = None
        self.description = None
        self.inheritanceAllowed = None
        self.revision = None
        self.objectId = None
        self.objectTypeName = None
        self.vsmUuid = None
        self.clientHandle = None
        self.extendedAttributes = [ExtendedAttributeSchema()]
        self.type = TypeSchema()
        self.scope = ScopeSchema()
        self.member = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)