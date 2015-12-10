import base_diskio_session
from vmware.common.global_config import pylogger
import inspect

class DTTool(base_diskio_session.BaseDiskIOSession):

    def __init__(self, py_dict):
        ''' Constructor for DTTool

        @param py_dict containing all options to test on a node using dt tool
        '''
        super(DTTool, self).__init__(py_dict)
        # dt tool doesn't give any stdout on successful run
        self.schema_class = "no_stdout_schema.NoStdOutSchema"


    def get_session_result(self, cli_client):
        ''' Get the Session result, first call parent's get_session_result
        if the schema object is string it means its FAILURE otherwise it should
        be schema object we are expecting

        @param cli_client
        @return result object
        '''
        schema_object = super(DTTool, self).get_session_result(cli_client)
        if self.result_obj.status_code != int(0):
            if schema_object.stdout != '':
                pylogger.info("end result is failure, output not as expected")
                # Need to decide on CLI status codes to communicate with VDNet Perl layer
                self.result_obj.set_status_code(int(255))
        return self.result_obj


    def get_tool_binary(self):
        '''return tool binary based on the os

        @return string containg tool binary
        '''
        os = self.test_disk.os
        if os.lower() == 'linux':
           return 'dt'
        if os.lower == 'win':
           return 'NOT IMPLEMENTED YET'


    def append_test_options(self, py_dict):
        '''Loop through all the testoptions (i.e. keys of IOWorkload)
        and create a string of testoptions

        @param py_dict:
        @return string containg tool test options
        '''
        pylogger.debug("User sent test options %s:" % py_dict)

        if 'testduration' in py_dict:
            testoptions = "runtime=%s " % (py_dict['testduration'])
        else:
            testoptions = "%s%s " % ("runtime=", "600")

        testoptions = " of=/tmp/dt_noprog_workfile-fsync " + \
               "limit=1g " + \
               "oncerr=abort " + \
               "disable=pstats " + \
               "enable=fsync " + \
               "flags=direct " + \
               "oflags=trunc " + \
               "errors=1 " + \
               "dispose=keep " + \
               "pattern=10 " + \
               "iotype=sequential " + \
               "enable=noprog " + \
               "noprogt=15s " + \
               "noprogtt=1800s " + \
               "alarm=3s " + \
               "trigger=cmd\:dt_noprog_script.bash " + \
               "log=/tmp/dt-fsync.log " + \
               "history=3 " + \
               "enable=syslog " + \
               testoptions
        return testoptions



if __name__ == '__main__':


    py_dict1 = {'testduration': '20',
                'toolname': 'dt',
                'testdisk': {'username': 'root',
                             'testip': None,
                             'arch': 'x86_32',
                             'controlip': '10.24.20.150',
                             'password': 'ca$hc0w',
                             'os': u'Linux'}}

    py_dict2 ={
               'operation': 'startsession',
               }

    py_dict3 = {
                'operation': 'getsessionresult',
               }

    dt_obj = DTTool(py_dict1)

    dt_obj.call_session(py_dict2)

