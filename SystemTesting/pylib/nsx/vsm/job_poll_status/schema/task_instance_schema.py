import base_schema


class TaskInstanceSchema(base_schema.BaseSchema):
    _schema_name = "taskInstance"
    def __init__(self, py_dict=None):
        """ Constructor to create TaskInstanceSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(TaskInstanceSchema, self).__init__()
        self.set_data_type('xml')
        self.id = None
        self.name = None
        self.startTimeMillis = None
        self.endTimeMillis = None
        self.taskStatus = None
        self.timeoutRetryCount = None
        self.failureRetryCount = None
        self.taskOutput = None
