import base_schema
from servicemanager_object_schema import ServiceManagerObjectSchema
from service_attribute_schema import ServiceAttributeSchema
from service_functionality_schema import ServiceFunctionalitySchema
from service_implementation_schema import ServiceImplementationSchema
from service_transport_schema import ServiceTransportSchema

class ServiceSchema(base_schema.BaseSchema):
    _schema_name = "service"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ServiceSchema, self).__init__()
        self.set_data_type('xml')
        self.name = None
        self.description = None
        self.state = None
        self.status = None
        self.precedence = None
        self.internalService = None
        self.category = None
        self.serviceManager = ServiceManagerObjectSchema()
        self.functionalities = [ServiceFunctionalitySchema()]
        self.implementations = [ServiceImplementationSchema()]
        self.transports = [ServiceTransportSchema()]
        self.serviceAttributes = [ServiceAttributeSchema()]
        self.vendorTemplates = None
        self.usedBy = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)