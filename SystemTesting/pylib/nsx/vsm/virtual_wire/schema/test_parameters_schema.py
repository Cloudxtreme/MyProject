import base_schema
from source_host_schema import SourceHostSchema
from destination_host_schema import DestinationHostSchema

class TestParametersSchema(base_schema.BaseSchema):
    _schema_name = "testParameters"
    """"""
    def __init__(self, py_dict = None):
        """ Constructor to create TestParameters object

        @param py_dict : python dictionary to construct this object
        """
        super(TestParametersSchema, self).__init__()
        self.set_data_type('xml')
        self.sourceHost = SourceHostSchema()
        self.destinationHost = DestinationHostSchema()
        self.gateway = None
        self.packetSize = None

        if py_dict is not None:
           self.get_object_from_py_dict(py_dict)
