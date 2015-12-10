import base_schema
from typed_attribute_schema import TypedAttributeSchema

class TypedAttributesSchema(base_schema.BaseSchema):
    _schema_name = "typedAttributes"

    def __init__(self, py_dict=None):
        """ Constructor to create TypedAttributesSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(TypedAttributesSchema, self).__init__()
        self.set_data_type('xml')
        self.typedAttributes = [TypedAttributeSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)