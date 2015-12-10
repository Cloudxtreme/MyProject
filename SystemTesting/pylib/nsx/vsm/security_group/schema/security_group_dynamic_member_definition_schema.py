import base_schema
from security_group_dynamic_set_schema import SecurityGroupDynamicSetSchema


class SecurityGroupDynamicMemberDefinitionSchema(base_schema.BaseSchema):
    _schema_name = "dynamicMemberDefinition"

    def __init__(self, py_dict=None):
        """ Constructor to create SecurityGroupDynamicMemberDefinitionSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(SecurityGroupDynamicMemberDefinitionSchema, self).__init__()
        self.set_data_type('xml')
        self.dynamicSet = [SecurityGroupDynamicSetSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)