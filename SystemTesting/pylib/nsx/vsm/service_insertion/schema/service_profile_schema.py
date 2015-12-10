import base_schema
from service_instance_object_id_schema import ServiceInstanceObjectIdSchema
from service_object_id_schema import ServiceObjectIdSchema
from service_profile_attribute_schema import ServiceProfileAttributeSchema
from vendor_attribute_schema import VendorAttributeSchema
from vendor_template_sp_schema import VendorTemplateSPSchema
from typed_attribute_schema import TypedAttributeSchema
from typed_attribute_table_schema import TypedAttributeTablesSchema
from vendor_section_schema import VendorSectionSchema

class ServiceProfileSchema(base_schema.BaseSchema):
    _schema_name = "serviceProfile"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceProfileSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ServiceProfileSchema, self).__init__()
        self.set_data_type('xml')
        self.name = None
        self.description = None
        self.objectId = None
        self.objectTypeName = None
        self.vsmUuid = None
        self.status = None
        self.service = ServiceObjectIdSchema()
        self.serviceInstance = ServiceInstanceObjectIdSchema()
        self.vendorTemplate = VendorTemplateSPSchema()
        self.profileAttributes = [ServiceProfileAttributeSchema()]
        self.vendorAttributes = [VendorAttributeSchema()]
        self.vendorTypedAttributes = [TypedAttributeSchema()]
        self.vendorTables = [TypedAttributeTablesSchema()]
        self.vendorSections = [VendorSectionSchema()]
        self._getserviceprofileflag = None
        self._serviceprofilename = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
