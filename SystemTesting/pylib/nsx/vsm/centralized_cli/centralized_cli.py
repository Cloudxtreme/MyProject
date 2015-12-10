import vsm_client
import connection
import result
import time
import re
import importlib
from vsm import VSM
from base_cli_client import BaseCLIClient
from expect_connection import ExpectConnection
import vmware.common as common


table_schema_map = {
    'vni-list': 'logicalswitch_list_schema.LogicalSwitchListSchema',
    'vni-hostlist': 'logicalswitch_hostlist_schema.LogicalSwitchHostListSchema',
    'arp-table': 'arp_table_schema.ARPTableSchema',
    'mac-table': 'mac_table_schema.MACTableSchema',
    'vtep-table': 'vtep_table_schema.VTEPTableSchema',
    'mac-table-host': 'mac_table_onhost_schema.MACTableOnHostSchema',
    'arp-table-host': 'arp_table_onhost_schema.ARPTableOnHostSchema',
    'vtep-table-host': 'vtep_table_onhost_schema.VTEPTableOnHostSchema',
    'vni-brief': 'vni_schema.VNISchema',
    'controller': 'controller_list_schema.ControllerListSchema',
    'connection': 'connection_table_schema.ConnectionTableSchema',
}

class CentralizedCli(vsm_client.VSMClient):
    def __init__(self, vsm=None, **kwargs):
        """ Constructor to create CentralizedCli managed object

        @param vsm object on which application object has to be configured
        """
        super(CentralizedCli, self).__init__()
        if vsm is not None:
            self.set_connection(vsm.get_connection())
        self.id = None
        self.username = None
        self.password = None
        self.expect_connection = None

    def get_expect_connection(self):
        if self.expect_connection is None:
            conn = ExpectConnection(self.get_connection().ip,
                                    self.get_connection().username,
                                    self.get_connection().password)
            self.expect_connection = conn

        return self.expect_connection

    def run_cli(self, command=None):
        """ Method to run assigned cli on nsxmanager

        @param command which to be executed
        """
        if command is None:
            return "FAILURE"

        conn_expect = self.get_expect_connection()
        expect = ['bytes*', '>']
        response = conn_expect.request("read_until_prompt",
                                       command,
                                       expect,
                                       None)
        if response is 'FAILURE':
            return 'FAILURE'

        return response

    def get_table(self, command, schema_name):
        """ Method to get all horizontal entries for this VNI from controller,
        like get logical switch table, arp table and so on
        jiaxinchen-vsm-2570157-1# show logical-switch  list all
        NAME          UUID           VNI   VdnScopeName         VdnScopeId
        3-switch-158  a4f71a12-e7... 9062  1-transportzone-1336 vdnscope-1
        2-switch-274  3066a8de-72... 9061  1-transportzone-1336 vdnscope-1

        """
        self.log.debug("command:%s, schema_name:%s" % (command, schema_name))
        if command is None:
            self.log.debug("No command provided: %s" % command)
            return common.status_codes.FAILURE

        response = self.run_cli(command)
        if response is common.status_codes.FAILURE:
            return response
        schema_class = self.get_cli_schema_class(schema_name)
        self.set_schema_class(schema_class)
        schema_object = self.get_schema_object()
        response = self.preprocess_response(response, schema_name)
        #skip the command in response
        n = response.index('\n')
        response = response[n:]
        schema_object.set_data_raw(response)

        return schema_object.table

    def preprocess_response(self, response, schema_name):
        string = None
        tmpstr = 'vm'
        if schema_name == 'mac-table-host':
            string = '        Inner MAC:'
        elif schema_name == 'arp-table-host':
            string = '        IP:'
        elif schema_name == 'vtep-table-host':
            string = '        Segment ID:'
        else:
            return response

        response = response.replace(string, '  ' + tmpstr + '\n' + string)
        insertsection = 'Index: '
        cnt = response.count(tmpstr)
        for i in range(0,cnt):
            response = response.replace(tmpstr, insertsection + str(i), 1)

        return response

    def get_cli_schema_class(self, schema_name):
        return table_schema_map[schema_name]