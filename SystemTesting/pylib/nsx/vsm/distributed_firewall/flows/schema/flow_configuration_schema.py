import base_schema
from flow_service_schema import ServiceSchema
from member_container_schema import MemberContainerSchema

class FlowConfigurationSchema(base_schema.BaseSchema):
    _schema_name = "FlowConfiguration"

    def __init__(self, py_dict=None):
        """ Constructor to create FlowConfigurationSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(FlowConfigurationSchema, self).__init__()
        self.set_data_type("xml")
        self.ignoreBlockedFlows = None
        self.service = [ServiceSchema()]
        self.sourceIPs = None
        self.ignoreLayer2Flows = None
        self.destinationPorts = None
        self.collectFlows = None
        self.sourceContainer = [MemberContainerSchema()]
        self.destinationContainer = [MemberContainerSchema()]
        self.destinationIPs = None


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
