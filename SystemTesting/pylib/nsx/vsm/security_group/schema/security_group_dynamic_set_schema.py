import base_schema
from security_group_dynamic_criteria_schema import SecurityGroupDynamicCriteriaSchema


class SecurityGroupDynamicSetSchema(base_schema.BaseSchema):
    _schema_name = "dynamicSet"

    def __init__(self, py_dict=None):
        """ Constructor to create SecurityGroupDynamicSetSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(SecurityGroupDynamicSetSchema, self).__init__()
        self.set_data_type('xml')
        self.operator = None
        self.dynamicCriteria = [SecurityGroupDynamicCriteriaSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)