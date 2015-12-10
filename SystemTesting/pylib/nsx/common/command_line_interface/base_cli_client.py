from base_client import BaseClient
from vmware.common.global_config import pylogger
import result

class BaseCLIClient(BaseClient):
    """ Class to execute commands using CLI
        change connection dynamically to connect to different devices;
        By setting the end_point user can set a detailed cli command for execution,
        should also set a schema class to specify the detailed data structure
        and fetch data.
    """

    def __init__(self):
        """ Constructor to create an instance of CLI class
        """
        super(BaseCLIClient, self).__init__()
        self.client_type  = "cli"
        self.set_content_type('raw')
        self.set_accept_type('raw')
        self.execution_type = "sync"


    def set_schema_class(self, schema):
        """ set a schema class to specify the detailed data structure
            @param schema E.g. horizontal schema class
        """
        self.schema_class = schema


    def set_execution_type(self, type):
        """ Set the execution type for this particular call
            @param type of execution, sync or async
        """
        self.execution_type = type


    def request(self, method="", endpoint="", payload=""):
        """ Execute the command using the connection, connection can be ssh, expect etc
	    and make sure the response looks the httplib response

        @param Comply with parent method signature by returning response object as
        parent query() read() etc will use this request method
        @return cli response object which is stdout object obtained from exec_command()
        """
        pylogger.info("executing command %s " % self.create_endpoint)
        stdin, stdout, stderr = self.connection.request(self.create_endpoint)
        # This is to save the state of the stdout and stderr without reading them
        # as reading them is a blocking call thus we defer reading in case we are in async mode
        response = stdout
        response.stderr = stderr
        # Need this if condition to comply with parent's interface like read() query() etc
        if self.execution_type == "sync":
            # Below line is to make the cli stdout look like httplib response obj
            # This is blocking call so do it only in sync mode
            response.status = stdout.channel.recv_exit_status()
        return response


    def create(self):
        """ Overriding parent's create to fit CLI needs

        @param extra params needed to be passed to create call
        @return result object
        """
        response = self.request()
        result_obj = result.Result()
        result_obj.response = response

        self.set_result(result_obj, self.execution_type)
        if self.execution_type == "async":
            # We set the execution status to 0 as there is no way of knowing the
            # status of async call. Only while reading the response data we will set
            # the actual status code in the result object
            result_obj.set_status_code(int(0))
        return result_obj


    def read_response(self, result_obj):
        """ Read response and convert it into schema object
        1) It does not make any REST/CLI call, just fetches data from an already executed
        create call
        2) It always return schema_object irrespective of command execution failure or data
        parsing failure (because tools like ./dt give out "" stdout when successfully executed)
        3) In case of async call it sets the result object before setting the schema object

        @param result_obj
        @return schema obj
        """
        response = result_obj.response
        if self.execution_type == "async":
            response.status = response.channel.recv_exit_status()
            result_obj.set_status_code(response.status)
            self.set_result(result_obj, "sync")
        schema_object = self.get_schema_object()
        pylogger.debug("response status is %s " % response.status)
        # response.read() actually polls the stdout and reads the data, thus exec_command is used
        # as sync call, while response.read() is used as the blocking call to read the output
        payload = response.read()
        pylogger.debug("response data is %s " % payload)
        if payload != None:
            schema_object.set_data(payload, self.accept_type)
        else:
            return schema_object
        return schema_object


    def set_result(self, result_obj, execution_type):
        """ Read response and convert it into schema object
        1) It does not make any REST/CLI call, just fetches data from an already executed
        create call
        2) It always return schema_object irrespective of command execution failure or data
        parsing failure (because tools like ./dt give out "" stdout when successfully executed)
        3) In case of async call it sets the result object before setting the schema object

        @param result_obj
        @return schema obj
        """
        response = result_obj.response
        if execution_type == "sync":
            # For sync call we make a blocking call to read all stdout and stderr
            # values and set all attributes in the result obj
            result_obj.status_code = response.status
            if result_obj.status_code != int(0):
                result_obj.reason = response.stderr.read()
                result_obj.response_data = response.read()
                pylogger.error('cli command failed: Error: %s', result_obj.error)
                pylogger.error('cli command failed: Status Code: %s', result_obj.status_code)
                pylogger.error('cli command failed: response data: %s', result_obj.response_data)
                pylogger.error('cli command failed: Reason: %s', result_obj.reason)
                result_obj.set_error(result_obj.response_data, result_obj.reason)

    def read(self):
        """ Client method to perform READ operation """
        schema_object = self.get_schema_object()
        if self.id is not None:
            self.response = self.request('GET', self.read_endpoint + "/"
                                        + str(self.id), "")

        else:
            self.response = self.request('GET', self.read_endpoint, "")
        self.log.debug(self.response.status)
        payload_schema = self.response.read()
        if payload_schema != None and payload_schema != "":
            schema_object.set_data(payload_schema, self.accept_type)
        else:
            return None
        return schema_object