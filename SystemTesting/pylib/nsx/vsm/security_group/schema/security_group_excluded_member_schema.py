import base_schema
from type_schema import TypeSchema
from scope_schema import ScopeSchema


class SecurityGroupExcludedMemberSchema(base_schema.BaseSchema):
    _schema_name = "excludeMember"

    def __init__(self, py_dict=None):
        """ Constructor to create SecurityGroupExcludedMemberSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(SecurityGroupExcludedMemberSchema, self).__init__()
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