import vsm_client
import connection
from vsm import VSM
import time


class JobPollStatus(vsm_client.VSMClient):
    def __init__(self, vsm=None):
        """ Constructor to create JobPollStatus managed object

        @param vsm : vsm object on which job status has to be polled
        """
        super(JobPollStatus, self).__init__()
        self.schema_class = 'job_instances_schema.JobInstancesSchema'
        self.set_connection(vsm.get_connection())
        conn = self.get_connection()
        conn.set_api_header("/api/2.0")
        self.set_read_endpoint("/services/taskservice/job")
        self.id = None

    def set_job_id(self, job_id):
        self.id = job_id

    def poll_jobs(self, status, timeout):
        job_instances = self.read()
        start_time = time.time()
	status = status.replace(" ", "")
        statusList = status.split('|')
        while job_instances.jobInstances[0].status not in statusList:
            if round(time.time() - start_time) > timeout:
                return 'FAILURE'
            time.sleep(3)
            job_instances = self.read()
        return 'SUCCESS'


if __name__ == '__main__':
    import base_client
    vsm_obj = VSM("10.110.28.44:443", "admin", "default")
    jobStatus = JobPollStatus(vsm_obj)
    jobStatus.set_job_id('jobdata-11')
    status = jobStatus.poll_jobs('COMPLETED', 300)  # timeout in seconds
    print status
