import base_schema
from security_group_schema import SecurityGroupSchema

class SecurityGroupsSchema(base_schema.BaseSchema):
    _schema_name = "securitygroups"

    def __init__(self, py_dict=None):
        """ Constructor to create SecurityGroupsSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(SecurityGroupsSchema, self).__init__()
        self.set_data_type('xml')
        self.securityGroups = [SecurityGroupSchema()]


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)