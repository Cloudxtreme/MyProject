import base_schema
from tor_switch_schema import TORSwitchSchema

class TORGatewaySwitchesSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "hardwaregatewayswitches"
    def __init__(self, py_dict=None):
        """ Constructor to create TORGatewaySwitchesSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(TORGatewaySwitchesSchema, self).__init__()
        self.set_data_type('xml')
        self.torswitch = [TORSwitchSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
