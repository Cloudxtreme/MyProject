import base_schema
from service_attribute_schema import ServiceAttributeSchema

class ImplemenationObjectSchema(base_schema.BaseSchema):
    _schema_name = "implementation"

    def __init__(self, py_dict=None):
        """ Constructor to create ImplemenationObjectSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ImplemenationObjectSchema, self).__init__()
        self.set_data_type('xml')
        self.hostBasedDeployment = None
        self.type = None
        self.requiredProfileAttributes = [ServiceAttributeSchema()]
        self.requiredServiceAttributes = [ServiceAttributeSchema()]

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)