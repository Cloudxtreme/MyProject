import base_schema
from relay_agent_schema import RelayAgentSchema

class RelayAgentsSchema(base_schema.BaseSchema):
    _schema_name = "relayAgents"

    def __init__(self, py_dict=None):
        """ Constructor to create RelayAgentsSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(RelayAgentsSchema, self).__init__()
        self.set_data_type("xml")
        self.relayAgent = [RelayAgentSchema()]


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
