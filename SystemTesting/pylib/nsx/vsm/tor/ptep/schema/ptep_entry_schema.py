import base_schema

class PTEPEntrySchema(base_schema.BaseSchema):
    """This schema is not used for configuration
    This will be filled in during GET calls
    """
    _schema_name = "basicinfo"
    def __init__(self, py_dict=None):
        """ Constructor to create PTEPEntrySchema object

        @param py_dict : python dictionary to construct this object
        """
        super(PTEPEntrySchema, self).__init__()
        self.set_data_type('xml')
        self.objectId = None
