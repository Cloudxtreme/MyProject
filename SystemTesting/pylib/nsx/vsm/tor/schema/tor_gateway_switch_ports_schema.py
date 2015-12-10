import base_schema
from tor_switch_port_schema import TORSwitchPortSchema

class TORGatewaySwitchPortsSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "hardwaregatewayports"
    def __init__(self, py_dict=None):
        """ Constructor to create TORGatewaySwitchPortsSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(TORGatewaySwitchPortsSchema, self).__init__()
        self.set_data_type('xml')
        self.torswitchport = [TORSwitchPortSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
