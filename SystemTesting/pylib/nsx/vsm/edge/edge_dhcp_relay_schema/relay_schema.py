import base_schema
from relay_server_schema import RelayServerSchema
from relay_agents_schema import RelayAgentsSchema
from relay_agent_schema import RelayAgentSchema

class RelaySchema(base_schema.BaseSchema):
    _schema_name = "relay"

    def __init__(self, py_dict=None):
        """ Constructor to create RelaySchema object
        @param py_dict : python dictionary to construct this object
        """
        super(RelaySchema, self).__init__()
        self.set_data_type("xml")
        self.relayServer = RelayServerSchema()
        self.relayAgents = [RelayAgentSchema()]


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
