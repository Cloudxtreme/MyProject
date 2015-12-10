import base_schema
from typed_attribute_schema import TypedAttributeSchema
from typed_attributes_schema import TypedAttributesSchema

class TypedAttributeTablesSchema(base_schema.BaseSchema):
    _schema_name = "typedAttributeTable"

    def __init__(self, py_dict=None):
        """ Constructor to create TypedAttributeTablesSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(TypedAttributeTablesSchema, self).__init__()
        self.set_data_type('xml')
        self.name = None
        self.description = None
        self.key = None
        self.header = [TypedAttributeSchema()]
        self.rows = [TypedAttributesSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
