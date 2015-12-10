import base_schema
from config_object_schema import ConfigObjectSchema
from service_object_schema import ServiceObjectSchema
from type_object_schema import TypeObjectSchema

class ServiceInstanceSchema(base_schema.BaseSchema):
    _schema_name = "serviceInstance"

    def __init__(self, py_dict=None):
        """ Constructor to create ServiceInstanceSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(ServiceInstanceSchema, self).__init__()
        self.set_data_type('xml')
        self.objectId = None
        self.objectTypeName = None
        self.vsmUuid = None
        self.revision = None
        self.type = TypeObjectSchema()
        self.name = None
        self.clientHandle = None
        self.extendedAttributes = None
        self.config = ConfigObjectSchema()
        self.service = ServiceObjectSchema()
        self.serviceProfileCount = None
        self._serviceid = None
        self.description = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
