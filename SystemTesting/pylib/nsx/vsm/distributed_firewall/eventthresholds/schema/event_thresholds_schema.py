import base_schema
from cpu_schema import CpuSchema
from memory_schema import MemorySchema
from cps_schema import CpsSchema

class EventThresholdsSchema(base_schema.BaseSchema):
    _schema_name = "eventThresholds"

    def __init__(self, py_dict=None):
        """ Constructor to create EventThresholdsSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(EventThresholdsSchema, self).__init__()
        self.set_data_type("xml")
        self.cpu = CpuSchema()
        self.memory = MemorySchema()
        self.connectionsPerSecond = CpsSchema()


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
