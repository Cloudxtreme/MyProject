import base_schema
from configuration_state_element_schema import ConfigurationStateElementSchema

class ConfigurationStateSchema(base_schema.BaseSchema):
    _schema_name = "configurationstate"

    def __init__(self, py_dict=None):
        """ Constructor to create ConfigurationStateSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ConfigurationStateSchema, self).__init__()
        self.state = None
        self.error_message = None
        self.error_code = None
        self.details = [ConfigurationStateElementSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)