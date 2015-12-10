import base_schema
from type_schema import TypeSchema
from scope_schema import ScopeSchema


class SecurityGroupDynamicCriteriaObjectSchema(base_schema.BaseSchema):
    _schema_name = "object"

    def __init__(self, py_dict=None):
        """ Constructor to create SecurityGroupDynamicCriteriaObjectSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(SecurityGroupDynamicCriteriaObjectSchema, self).__init__()
        self.set_data_type('xml')
        self.objectId = None
        self.objectTypeName = None
        self.vsmUuid = None
        self.name = None
        self.description = None
        self.revision = None
        self.type = TypeSchema()
        self.scope = ScopeSchema()
        self.clientHandle = None
        self.extendedAttributes = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)