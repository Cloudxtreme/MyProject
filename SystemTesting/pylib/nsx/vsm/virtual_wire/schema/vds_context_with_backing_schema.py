import base_schema
from switch_schema import SwitchSchema


class VdsContextWithBackingSchema(base_schema.BaseSchema):
    _schema_name = "vdsContextWithBacking"
    """"""
    def __init__(self, py_dict=None):
        """ Constructor to create VdsContextWithBackingSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(VdsContextWithBackingSchema, self).__init__()
        self.set_data_type('xml')
        self.switch = SwitchSchema()
        self.mtu = None
        self.promiscuousMode = None
        self.backingType = None
        self.backingValue = None
