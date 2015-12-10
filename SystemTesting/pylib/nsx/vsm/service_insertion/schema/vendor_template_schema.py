import base_schema
from vendor_attribute_schema import VendorAttributeSchema
from service_functionality_schema import ServiceFunctionalitySchema
from typed_attribute_schema import TypedAttributeSchema
from typed_attribute_table_schema import TypedAttributeTablesSchema
from vendor_section_schema import VendorSectionSchema

class VendorTemplateSchema(base_schema.BaseSchema):
    _schema_name = "vendorTemplate"

    def __init__(self, py_dict=None):
        """ Constructor to create VendorTemplateSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(VendorTemplateSchema, self).__init__()
        self.set_data_type('xml')
        self.name = None
        self.description = None
        self.idFromVendor = None
        self._partial_endpoint = None
        self.functionalities = [ServiceFunctionalitySchema()]
        self.vendorAttributes = [VendorAttributeSchema()]
        self.typedAttributes = [TypedAttributeSchema()]
        self.typedAttributeTables = [TypedAttributeTablesSchema()]
        self.vendorSections = [VendorSectionSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
