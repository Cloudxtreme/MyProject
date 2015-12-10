from vsm_address_group_schema import AddressGroupSchema
import base_schema


class SubInterfaceSchema(base_schema.BaseSchema):
    """"""
    _schema_name = "subInterface"
    def __init__(self, py_dict=None):
        """ Constructor to create SubInterfaceSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(SubInterfaceSchema, self).__init__()
        self.index = None
        self.label = None
        self.vlanId = None
        self.tunnelId = None
        self.logicalSwitchId = None
        self.name = None
        self.mtu = None
        self.isConnected = None
        self.enableSendRedirects = None
        self.addressGroups = [AddressGroupSchema()]
        self.set_data_type("xml")

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
