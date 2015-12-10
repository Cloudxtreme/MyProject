import base_schema
from source_schema import SourceSchema

class SourcesSchema(base_schema.BaseSchema):
    _schema_name = "sources"

    def __init__(self, py_dict=None):
        """ Constructor to create SourcesSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(SourcesSchema, self).__init__()
        self.set_data_type("xml")
        self.source = [SourceSchema()]
        self._tag_excluded = None


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
