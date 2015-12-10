import base_schema
from service_attribute_schema import ServiceAttributeSchema

class RequiredProfileAttributesObjectSchema(base_schema.BaseSchema):
    _schema_name = "requiredProfileAttributes"

    def __init__(self, py_dict=None):
        """ Constructor to create RequiredServiceAttributesObjectSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(RequiredProfileAttributesObjectSchema, self).__init__()
        self.set_data_type('xml')
        self.id = None
        self.revision = None
        self.attribute = [ServiceAttributeSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)