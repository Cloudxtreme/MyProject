import base_schema
from OSPF_area_schema import OSPFAreaSchema
from OSPF_interface_schema import OSPFInterfaceSchema
from redistribution_schema import RedistributionSchema


class OSPFSchema(base_schema.BaseSchema):
    _schema_name = "ospf"

    def __init__(self, py_dict=None):
        """ Constructor to create OspfSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(OSPFSchema, self).__init__()
        self.set_data_type("xml")
        self.gracefulRestart = None
        self.defaultOriginate = None
        self.ospfAreas = [OSPFAreaSchema()]
        self.enabled = None
        self.protocolAddress = None
        self.forwardingAddress = None
        self.ospfInterfaces = [OSPFInterfaceSchema()]
        self.redistribution = RedistributionSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
