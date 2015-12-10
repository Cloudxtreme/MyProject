import base_schema

class SystemEventSchema(base_schema.BaseSchema):
    _schema_name = "systemEvent"

    def __init__(self, py_dict=None):
        """ Constructor to create SystemEventSchema object
        @param py_dict : python dictionary to construct this object
        """
        super(SystemEventSchema, self).__init__()
        self.set_data_type("xml")
        self.eventId = None
        self.severity = None
        self.eventCode = None
        self.timestamp = None
        self.module = None
        self.eventMetadata = None
        self.eventSource = None
        self.reporterName = None
        self.message = None
        self.reporterType = None
        self.sourceType = None


        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
