import base_schema
from task_instance_schema import TaskInstanceSchema


class JobInstanceSchema(base_schema.BaseSchema):
    _schema_name = "jobInstance"
    def __init__(self, py_dict=None):
        """ Constructor to create JobInstanceSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(JobInstanceSchema, self).__init__()
        self.id = None
        self.name = None
        self.taskInstances = [TaskInstanceSchema()]
        self.startTimeMillis = None
        self.endTimeMillis = None
        self.status = None
        self.timeoutRetryCount = None
        self.failureRetryCount = None
        self.jobOutput = None
