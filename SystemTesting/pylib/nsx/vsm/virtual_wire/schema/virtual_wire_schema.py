import base_schema
from type_schema import TypeSchema
from vds_context_with_backing_schema import VdsContextWithBackingSchema


class VirtualWireSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "virtualWire"
    def __init__(self, py_dict=None):
        """ Constructor to create VirtualWireSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(VirtualWireSchema, self).__init__()
        self.set_data_type('xml')
        self.objectId = None
        self.objectTypeName = None
        self.vsmUuid = None
        self.revision = None
        self.type = TypeSchema()
        self.name = None
        self.description = None
        self.extendedAttributes = None
        self.clientHandle = None
        self.tenantId = None
        self.vdnScopeId = None
        self.vdsContextWithBacking = VdsContextWithBackingSchema()
        self.vdnId = None
        self.multicastAddr = None
        self.controlPlaneMode = None
        self.isUniversal = None
        self.vsmUuid = None
        self.universalRevision = None
        self.ctrlLsUuid = None
