import base_schema
from typed_attribute_table_schema import TypedAttributeTablesSchema
from typed_attribute_schema import TypedAttributeSchema

class VendorSectionSchema(base_schema.BaseSchema):
    _schema_name = "vendorSection"

    def __init__(self, py_dict=None):
        """ Constructor to create VendorSectionSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(VendorSectionSchema, self).__init__()
        self.set_data_type('xml')
        self.name = None
        self.description = None
        self.typedAttributes = [TypedAttributeSchema()]
        self.typedAttributeTables = [TypedAttributeTablesSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)