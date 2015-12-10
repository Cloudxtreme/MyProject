import base_schema
from destination_schema import DestinationSchema

class DestinationsSchema(base_schema.BaseSchema):
    _schema_name = "destinations"

    def __init__(self, py_dict=None):
        """ Constructor to create DestinationsSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(DestinationsSchema, self).__init__()
        self.set_data_type("xml")
        self.destination = [DestinationSchema()]
        self._tag_excluded = None


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
