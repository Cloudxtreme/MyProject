import base_schema
from security_group_dynamic_criteria_object_schema import SecurityGroupDynamicCriteriaObjectSchema


class SecurityGroupDynamicCriteriaSchema(base_schema.BaseSchema):
    _schema_name = "dynamicCriteria"

    def __init__(self, py_dict=None):
        """ Constructor to create SecurityGroupDynamicCriteriaSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(SecurityGroupDynamicCriteriaSchema, self).__init__()
        self.set_data_type('xml')
        self.operator = None
        self.key = None
        self.criteria = None
        self.value = None
        self.isValid = None
        self.object = SecurityGroupDynamicCriteriaObjectSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)