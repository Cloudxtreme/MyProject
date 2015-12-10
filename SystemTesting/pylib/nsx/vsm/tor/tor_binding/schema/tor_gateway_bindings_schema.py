import base_schema
from tor_binding_schema import TORBindingSchema


class TORGatewayBindingsSchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "torgatewaybindings"
    def __init__(self, py_dict=None):
        """ Constructor to create TORGatewayBindingsSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(TORGatewayBindingsSchema, self).__init__()
        self.set_data_type('xml')
        self.binding = [TORBindingSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
