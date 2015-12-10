import base_schema


class JobSchema(base_schema.BaseSchema):
    _schema_name = "job"
    def __init__(self, py_dict=None):
        """ Constructor to create JobSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(JobSchema, self).__init__()
        self.set_data_type('xml')
        self.id = None
        self.name = None
        self.description = None
        self.creationTimeMillis = None
        self.nextExecutionTimeMillis = None
        self.jobOwner = None
        self.scope = None
