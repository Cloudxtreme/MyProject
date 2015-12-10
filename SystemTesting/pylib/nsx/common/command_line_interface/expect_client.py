from base_client import BaseClient
from vmware.common.global_config import pylogger
import result

class ExpectClient(BaseClient):
    """ Class to execute commands using CLI
        change connection dynamically to connect to different devices;
        By setting the end_point user can set a detailed cli command for execution,
        should also set a schema class to specify the detailed data structure
        and fetch data.
    """
    expect_prompt_lookup_method = {
        'READ_UNTIL_PROMPT': 'read_until_prompt',
        'DEFAULT_PROMPT': 'default_prompt'
    }

    def __init__(self):
        """ Constructor to create an instance of CLI class
        """
        super(ExpectClient, self).__init__()
        self.client_type = "expect"
        self.set_content_type('raw')
        self.set_accept_type('raw')
        self.execution_type = "sync"
        self.expect_prompt = None

    def set_execution_type(self, type):
        """ Set the execution type for this particular call
            @param type of execution, sync or async
        """
        self.execution_type = type

    def set_expect_prompt(self, expect_prompt):
        """
        Set the expect prompt
        """
        self.expect_prompt = expect_prompt

    def read(self, prompt_method_key=None):
        """ Client method to perform READ operation """
        schema_object = self.get_schema_object()

        if prompt_method_key == None:
            method = self.expect_prompt_lookup_method['DEFAULT_PROMPT']
        else:
            method = self.expect_prompt_lookup_method[prompt_method_key]

        if self.id is not None:
            self.response = self.request(method, self.read_endpoint + "/" + self.id, "")
        else:
            self.response = self.request(method, self.read_endpoint, "")

        payload_schema = self.response
        if payload_schema != None and payload_schema != "":
            schema_object.set_data(payload_schema, self.accept_type)
        else:
            return None
        return schema_object

    def request(self, method="", endpoint="", payload=""):
        """ Execute the command using the connection, connection can be ssh, expect etc
        and make sure the response looks the httplib response
        @param Comply with parent method signature by returning response object as
        parent query() read() etc will use this request method
        @return cli response object which is stdout object obtained from exec_command()
        """
        pylogger.info("executing command %s " % endpoint)
        response = self.connection.anchor.request(method, endpoint, self.expect_prompt, "")
        return response