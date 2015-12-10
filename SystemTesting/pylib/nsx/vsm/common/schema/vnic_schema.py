import base_schema
from vsm_address_group_schema import AddressGroupSchema

class VNICSchema(base_schema.BaseSchema):
    _schema_name = "vnic"
    def __init__(self, py_dict=None):
        """ Constructor to create VNICSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(VNICSchema, self).__init__()
        self.set_data_type('xml')
        self.label = None
        self.name = None
        self.addressGroups = [AddressGroupSchema()]
        self.mtu = None
        self.type = None
        self.isConnected = None
        self.index = None
        self.portgroupId = None
        self.portgroupName = None
        self.enableProxyArp = None
        self.enableSendRedirects = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)