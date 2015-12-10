import base_schema
from ip_range_dto_schema import IPRangeDtoSchema
from scope_schema import ScopeSchema
from type_schema import TypeSchema


class IPAMAddressPoolSchema(base_schema.BaseSchema):
    _schema_name = "ipamAddressPool"
    def __init__(self, py_dict=None):
        """ Constructor to create IPAMAddressPoolSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(IPAMAddressPoolSchema, self).__init__()
        self.set_data_type('xml')
        self.name = None
        self.gateway = None
        self.prefixLength = None
        self.ipRanges = [IPRangeDtoSchema()]
        self.objectId = None
        self.objectTypeName = None
        self.vsmUuid = None
        self.revision = None
        self.type = TypeSchema()
        self.scope = ScopeSchema()
        self.clientHandle = None
        self.extendedAttributes = None
        self.totalAddressCount = None
        self.usedAddressCount = None
        self.usedPercentage = None
        self.ipPoolType = None
        self.subnetId = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
