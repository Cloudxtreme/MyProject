import base_schema
from tor_schema import TORSchema

class TORGatewaysSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "TORGateways"
    def __init__(self, py_dict=None):
        """ Constructor to create TORGatewaysSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(TORGatewaysSchema, self).__init__()
        self.set_data_type('xml')
        self.tor = [TORSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
