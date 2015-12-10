from base_cli_client import BaseCLIClient
import connection
from vmware.common.global_config import pylogger
from node import Node


class BaseDiskIOSession(object):
    def __init__(self, py_dict):
        """ Constructor for BaseDiskIOSession

        @param py_dict containing testdisk which is a py_dict of node attributes
        @return obj of BaseDiskIOSession
        """
        self.id = None
        self.test_disk = None
        self.schema_class = ""
        self.call_type = "sync"
        self.end_point = None
        pylogger.debug("user sent py_dict %s" % py_dict)
        if 'testdisk' in py_dict.keys():
            self.test_disk = Node(py_dict['testdisk'])
        else:
            pylogger.debug("testdisk missing in BaseDiskIOSession constructor")
        pylogger.debug("testdisk %s" % self.test_disk)
        self.initialize_session(py_dict)


    def initialize_session(self, py_dict):
        """ Initialize session by building tool command,  tool options
        setting it as endpoint for the cli client, setting call type etc

        @param py_dict containing all testoptions to run the tool with
        """
        pylogger.debug("Initializing session ...")
        tool_command = self.build_tool_command()

        # Now get the options
        pylogger.debug("tool_command: %s" % tool_command)
        tool_options = self.append_test_options(py_dict)
        pylogger.debug("tool_options: %s" % tool_options)
        self.end_point = '%s%s' % (tool_command, tool_options)
        if 'executiontype' in py_dict and py_dict['executiontype'] == "async":
            self.call_type = "async"



    def start_session(self, cli_client):
        """ Start session by calling the cli client to execute params

        @param cli_client:
        @return result obj
        """

        pylogger.debug("Starting session in %s mode" % self.call_type)
        # We use create because create is a async call, we can read
        # the data later, thus create provides flexibility
        self.result_obj = cli_client.create()
        if self.call_type == 'sync':
            if self.result_obj.status_code != int(0):
                # command execution failed
                pylogger.info("command execution failed with reason:%s" % self.result_obj.reason)
                return self.result_obj
            else:
                return self.get_session_result(cli_client)
        else:
            # Return the result obj to calling layer as there is no schema object obtained
            # at this point in async mode
            return self.result_obj


    def stop_session(self):
        """ Stop session by calling the cli client to execute kill command

        """
        pylogger.debug("stop_session Not yet Implemented")


    def get_session_result(self, cli_client):
        """ get_session_result returns schema object for that client

        @param cli_client:
        @return schema object
        """
        pylogger.debug("Getting session Result")
        schema_obj = cli_client.read_response(self.result_obj)
        if self.result_obj.status_code != int(0):
            # command execution failed
            pylogger.info("command execution failed with reason:%s" % self.result_obj.reason)
            return self.result_obj
        return schema_obj


    def call_session(self, py_dict):
        """ Wrapper method for startsession, stopsession, getsession result

        @param py_dict containing all keywords controller the tool behavior
        @return result obj or schema object
        """
        pylogger.debug("Called DiskIO session with operation {0:s}" . format(py_dict))
        operation = py_dict['operation']
        cli_client = self.create_cli_client()
        if (operation.lower() == "startsession"):
            ssh_connection = connection.Connection(self.test_disk.controlip,
                                                        self.test_disk.username,
                                                        self.test_disk.password,
                                                        "None",
                                                        "ssh")
            pylogger.debug("Created new ssh_connection %s" % ssh_connection)
            cli_client.set_connection(ssh_connection.anchor)
            return self.start_session(cli_client)
        if (operation.lower() == "stopsession"):
            return self.stop_session(cli_client)
        if (operation.lower() == "getsessionresult"):
            return self.get_session_result(cli_client)


    def build_tool_command(self):
        """ Build tool command using path and tool binary

        @return tool command string
        """
        tool_binary = self.get_tool_binary()
        pylogger.debug("tool_binary:%s" % tool_binary)
        tool_path = self.get_tool_path()
        pylogger.debug("tool_path:%s" % tool_path)
        return '%s%s' % (tool_path, tool_binary)


    def append_test_options(self):
        """ Loop through all the testoptions (i.e. keys of IOWorkload)
        and create a string of testoptions

        """
        pylogger.debug("Append test options")


    def get_tool_path(self):
        """return tool path based on the os type

        @param None
        @return tool path string
        """
        arch = self.test_disk.arch.lower()
        os = self.test_disk.os.lower()
        if os == "linux":
           return  '%s%s%s%s%s' %  ('/automation/bin/', arch, '/', os, '/')
        if os == "win":
           return '%s%s%s%s%s' % ('m:\\\\bin\\\\', arch, '\\\\', os, '\\\\')


    def get_tool_schema(self):
        """ Returns the schema class for the tool

        @param None
        @return schema class string
        """
        return self.schema_class


    def create_cli_client(self):
        """ Create a new cli client obj and sets all attributes in it

        @param None
        @return BaseCLIClient object
        """

        base_cli_client = BaseCLIClient()
        base_cli_client.set_create_endpoint(self.end_point)
        base_cli_client.set_execution_type(self.call_type)
        base_cli_client.set_schema_class(self.get_tool_schema())
        return base_cli_client
