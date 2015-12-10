import base_schema
from implementation_object_schema import ImplemenationObjectSchema
from transport_object_schema import TransportObjectSchema
from service_attribute_schema import ServiceAttributeSchema
from typed_attribute_schema import TypedAttributeSchema

class ConfigObjectSchema(base_schema.BaseSchema):
    _schema_name = "config"

    def __init__(self, py_dict=None):
        """ Constructor to create ConfigObjectSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(ConfigObjectSchema, self).__init__()
        self.set_data_type('xml')
        self.id = None
        self.revision = None
        self.precedence = None
        self.serviceInstanceAttributes = [ServiceAttributeSchema()]
        self.implementation = ImplemenationObjectSchema()
        self.implementationAttributes = [ServiceAttributeSchema()]
        self.transport = TransportObjectSchema()
        self.transportAttributes = [ServiceAttributeSchema()]
        self.instanceTemplateAttributes = [ServiceAttributeSchema()]
        self.instanceTemplateTypedAttributes = [TypedAttributeSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)