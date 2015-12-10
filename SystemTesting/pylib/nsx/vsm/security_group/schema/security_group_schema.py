import base_schema
from type_schema import TypeSchema
from scope_schema import ScopeSchema
from security_group_member_schema import SecurityGroupMemberSchema
from security_group_excluded_member_schema import SecurityGroupExcludedMemberSchema
from security_group_dynamic_member_definition_schema import SecurityGroupDynamicMemberDefinitionSchema


class SecurityGroupSchema(base_schema.BaseSchema):
    _schema_name = "securitygroup"

    def __init__(self, py_dict=None):
        """ Constructor to create SecurityGroupSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(SecurityGroupSchema, self).__init__()
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
        self.inheritanceAllowed = None
        self.member = [SecurityGroupMemberSchema()]
        self.excludeMember = [SecurityGroupExcludedMemberSchema()]
        self.dynamicMemberDefinition = SecurityGroupDynamicMemberDefinitionSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)