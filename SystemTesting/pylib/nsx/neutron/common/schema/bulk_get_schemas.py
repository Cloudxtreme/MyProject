import base_schema

class BulkGetSchemas(base_schema.BaseSchema):
    _schema_name = "tag"

    def __init__(self, entity_object=None):
        """ Constructor to create BulkGetSchemas object

        @param py_dict : python dictionary to construct this object
        """
        super(BulkGetSchemas, self).__init__()
        self.result_count = None
        self.schema = None
        self.results = []
        self.results.append(entity_object)

