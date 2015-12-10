import base_schema
from required_instance_attributes_schema import RequiredInstanceAttributesSchema

class ServiceInstanceTemplateSchema(base_schema.BaseSchema):
    _schema_name = "serviceInstanceTemplate"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceInstanceTemplateSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ServiceInstanceTemplateSchema, self).__init__()
        self.set_data_type('xml')
        self.name = None
        self.description = None
        self.instanceTemplateId = None
        self.requiredInstanceAttributes = [RequiredInstanceAttributesSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
