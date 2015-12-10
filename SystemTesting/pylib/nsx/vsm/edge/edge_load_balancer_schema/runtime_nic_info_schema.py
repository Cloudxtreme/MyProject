import base_schema
from network_schema import NetworkSchema

class RuntimeNicInfoSchema(base_schema.BaseSchema):
    _schema_name = "runtimeNicInfo"
    def __init__(self, py_dict=None):
        """ Constructor to create RuntimeNicInfoSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(RuntimeNicInfoSchema, self).__init__()
        self.set_data_type('xml')
        self.index = None
        self.label = None
        self.network = NetworkSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
