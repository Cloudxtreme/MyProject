from vsm_address_group_schema import AddressGroupSchema
from subinterface_schema import SubInterfaceSchema
import base_schema


class VnicSchema(base_schema.BaseSchema):
    """"""
    _schema_name = "vnic"
    def __init__(self, py_dict=None):
        """ Constructor to create VnicSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(VnicSchema, self).__init__()
        self.type = None
        self.index = None
        self.label = None
        self.connectedToName = None
        self.name = None
        self.mtu = None
        self.isConnected = None
        self.portgroupId = None
        if py_dict and 'subinterfaces' in py_dict:
            self.subInterfaces = [SubInterfaceSchema()]
        self.addressGroups = [AddressGroupSchema()]
        self.set_data_type("xml")

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
