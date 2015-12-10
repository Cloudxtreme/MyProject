import base_schema
from job_instance_schema import JobInstanceSchema


class JobInstancesSchema(base_schema.BaseSchema):
    _schema_name = "jobInstances"
    def __init__(self, py_dict=None):
        """ Constructor to create JobInstancesSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(JobInstancesSchema, self).__init__()
        self.set_data_type('xml')
        self.jobInstances = [JobInstanceSchema()]
