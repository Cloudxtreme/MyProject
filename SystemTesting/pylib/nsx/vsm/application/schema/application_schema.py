import base_schema
from type_schema import TypeSchema
from scope_schema import ScopeSchema
from element_schema import ElementSchema
from extended_attribute_schema import ExtendedAttributeSchema

class ApplicationSchema(base_schema.BaseSchema):
    _schema_name = "application"

    def __init__(self, py_dict=None):
        """ Constructor to create ApplicationSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ApplicationSchema, self).__init__()
        self.set_data_type('xml')
        self.name = None
        self.revision = None
        self.objectId = None
        self.objectTypeName = None
        self.vsmUuid = None
        self.clientHandle = None
        self.extendedAttributes = [ExtendedAttributeSchema()]
        self.type = TypeSchema()
        self.scope = ScopeSchema()
        self.element = ElementSchema()
        self.description = None
        self.inheritanceAllowed = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)