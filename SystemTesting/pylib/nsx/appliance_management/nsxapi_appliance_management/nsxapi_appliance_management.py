import sys
import time
import os

import build_utilities
import base_client
from connection import Connection
import vmware.common.logger as logger
from nsxapi_appliance_management_schema import NSXAPIApplianceManagementSchema
from nsx_upgrade import NSXUpgrade
from nsx_upgrade_schema import NSXUpgradeSchema
from controller_upgrade_schema import ControllerUpgradeSchema
from nsx_pre_upgrade_question_answer_schema import NSXPreUpgradeQuestionAnswerSchema
from vsm import VSM
from vxlan_controller import VXLANController
from controller_upgrade import ControllerUpgrade
from job_poll_status import JobPollStatus

class NSXAPIApplianceManagement(base_client.BaseClient):

    def __init__(self, vsm=None):
        """ Constructor to create NSXAPIApplianceManagement object

        @param vsm object on which NSXAPIApplianceManagement object has to be configured
        """
        super(NSXAPIApplianceManagement, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'nsxapi_appliance_management_schema.NSXAPIApplianceManagementSchema'
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.auth_type = "vsm"
        self.set_connection(vsm.get_connection())
        self.create_endpoint = 'appliance-management/components/component/NSXAPIMGMT/toggleStatus/START'
        self.read_endpoint = 'appliance-management/components/component/NSXAPIMGMT/status'
        self.stop_endpoint = 'appliance-management/components/component/NSXAPIMGMT/toggleStatus/STOP'
        self.clear_endpoint = 'appliance-management/components/component/NSXAPIMGMT?action=initialize'
        self.ssh_start_endpoint = 'appliance-management/components/component/SSH/toggleStatus/START'
        self.ssh_stop_endpoint = 'appliance-management/components/component/SSH/toggleStatus/STOP'
        self.id = None
        self.updateAsPost = False

    def get_connection(self, type="https"):
        """ This method allows us to handle different connection types in the same client

        @param type of connection to get
        """
        vsm_conn = super(NSXAPIApplianceManagement, self).get_connection()
        conn = Connection(vsm_conn.ip,
                          vsm_conn.username,
                          vsm_conn.password,
                          vsm_conn.api_header, type)
        return conn

    def get_vsm_service_status(self):
        """ This method is needed to get the vsm service status
        """

        self.read_endpoint = 'appliance-management/components/component/NSX/status'
        schema_object = self.read()
        self.read_endpoint = 'appliance-management/components/component/NSXAPIMGMT/status'
        return schema_object.result

    def set_connection(self, vsm_conn):
        """ This method is needed to set the correct api version on the connection object for this client

        @param connection object to set
        """
        vsm_v1 = VSM(vsm_conn.ip,
                     vsm_conn.username,
                     vsm_conn.password,
                     "", "1.0")
        vsm_v1_conn = vsm_v1.get_connection()
        super(NSXAPIApplianceManagement, self).set_connection(vsm_v1_conn)

    def clear(self):
        create_endpoint = self.create_endpoint
        self.create_endpoint = self.clear_endpoint
        appliance_schema = NSXAPIApplianceManagementSchema({})
        result = self.create(appliance_schema)
        self.create_endpoint = create_endpoint
        return result


    def stop(self):
        create_endpoint = self.create_endpoint
        self.create_endpoint = self.stop_endpoint
        appliance_schema = NSXAPIApplianceManagementSchema({})
        result = self.create(appliance_schema)
        self.create_endpoint = create_endpoint
        return result

    def ssh_start(self):
        create_endpoint = self.create_endpoint
        self.create_endpoint = self.ssh_start_endpoint
        appliance_schema = NSXAPIApplianceManagementSchema({})
        result = self.create(appliance_schema)
        self.create_endpoint = create_endpoint
        return result

    def ssh_stop(self):
        create_endpoint = self.create_endpoint
        self.create_endpoint = self.ssh_stop_endpoint
        appliance_schema = NSXAPIApplianceManagementSchema({})
        result = self.create(appliance_schema)
        self.create_endpoint = create_endpoint
        return result

    def change_password(self, anchor, password):
        anchor.sendline('passwd')
        time.sleep(5)
        # We are prompted here to enter new password. In case the password is
        # deemed to be too weak, we have enter it a third time, so just to be
        # sure we enter in 3 times.
        for i in [1,2,3]:
            anchor.sendline(password)
            time.sleep(5)

    def enable_root_access(self, engineering_password=None):
        """ This method uses expect to enable root ssh access on NSX appliance
            @param engineering_password is the password needed to get root
                   access through appliance
        """

        conn = self.get_connection("expect")
        anchor = conn.anchor.pexpectconn
        anchor.logfile= sys.stdout
        password = conn.password
        if engineering_password == None:
            engineering_password = password

        anchor.sendline('en')
        anchor.expect('Password')
        anchor.sendline(password)
        anchor.expect('#')
        anchor.sendline('st e')
        anchor.expect('Password:')
        anchor.sendline(engineering_password)
        index = anchor.expect(["#", "failure"])
        if index == 1:
            self.log.debug("Authentication failed! with password = %s" % engineering_password)
            return False
        else:
            time.sleep(5)
            self.change_password(anchor, password)
            anchor.sendline('sed -i \'s/PermitRootLogin no/PermitRootLogin yes/g\' /etc/ssh/sshd_config')
            time.sleep(5)
        return True

    def send_file(self, local_file, remote_file):
        conn  = self.get_connection("scp")
        anchor = conn.anchor
        anchor.put(local_file, remote_file)

        # Checking to see if file was received by server
        try:
            anchor.stat(remote_file)
        except:
            self.log.debug("file not found on server")
            return False
        return True

    def upgrade(self, py_dict):

        if (py_dict['build'] == "from_buildweb"):
            build = build_utilities.get_build_id(py_dict)
        else:
            build = py_dict['build']
        self.log.debug("starting upgrade for build %s" % build)

        # Downloading upgrade bundle from buildweb
        filename = build_utilities.get_deliverable(build, py_dict['name'])
        self.log.debug("upgrade bundle obtained for build %s" % build)
        file_path = '/tmp/' + filename
        # Enabling root ssh access on the appliance
        try:
           # try to connect to vsm by default password, tech password is the same
           if self.enable_root_access() == False:
               # try another tech password if cannot switch to 'st eng'
               # TODO: This password has to be stored somewhere
               if self.enable_root_access('IAmOnThePhoneWithTechSupport') == False:
                   os.remove(file_path)
                   return 'FAILURE'
        except:
            self.log.debug("enabling root ssh access threw expection")
            os.remove(file_path)
            return 'FAILURE'
        result_obj = self.ssh_stop()
        result_obj = self.ssh_start()
        self.log.debug("ssh root access enabled on Appliance")

        # Sending upgrade bundle file to the appliance
        self.log.debug("uploading upgrade bundle to appliance")

        if self.send_file(file_path, "/common/em/downloads/" + str(filename)) == False:
            os.remove(file_path)
            self.log.error("upload bundle %s to Appliance failed" % str(filename))
            return 'FAILURE'
        self.log.debug("upgrade bundle %s uploaded to Appliance" % str(filename))

        # Making the API call to start upgrade
        upgrade_obj = NSXUpgrade(self)
        qa_schema_obj = NSXPreUpgradeQuestionAnswerSchema()
        qa_schema_obj.questionId = "preUpgradeChecks1:Q1"
        qa_schema_obj.question = "Default password after migration ?"
        qa_schema_obj.questionAnserType = "PASSWORD"
        qa_schema_obj.answer = py_dict['root_password']
        upgrade_schema_obj = NSXUpgradeSchema()
        upgrade_schema_obj.preUpgradeQuestionsAnswerArray.append(qa_schema_obj)
        result_obj = upgrade_obj.create(upgrade_schema_obj)

        if str(result_obj.status_code) != '202':
            self.log.debug("upgrade fails with code: %s" % str(result_obj.status_code))
            os.remove(file_path)
            return 'FAILURE'

        # Polling to check upgrade status. Total polling time is 330 seconds.
        iter = 0
        failed = 1
        started_restart = 0
        time.sleep(30)
        while 1:
            if iter > 20:
                os.remove(file_path)
                return 'SUCCESS'
            result_obj = None
            try:
                result_obj = upgrade_obj.read()
            except:
                started_restart = 1
                self.log.debug("Appliance not up yet")
            if result_obj != None and started_restart:
                if str(result_obj.status) == "COMPLETE":
                    self.log.debug("NSX Upgrade successful!")
                    failed = 0
                    break
            iter = iter + 1
            time.sleep(30)
        os.remove(file_path)
        if failed == 0:
            return 'SUCCESS'

        return 'FAILURE'

    def upgrade_controller(self):
        upgrade_obj = ControllerUpgrade(self)
        result_obj = upgrade_obj.create(None)
        if result_obj.error is not None:
            self.log.error("create upgrade object failed with error %s" % str(result_obj.error))
            return 'FAILURE'

        timeout = 3200
        job_id = upgrade_obj.id
        job_status = JobPollStatus(upgrade_obj)
        job_status.set_job_id(job_id)
        self.log.debug("Waiting for task %s to complete in %d seconds" % (job_id, timeout))

        # timeout in seconds
        status = job_status.poll_jobs('COMPLETED|FAILED|UNKNOWN|FAILED_ABORT', timeout)
        self.log.debug("vxlan controller upgrade status %s" % status)
        if status == 'FAILURE':
           self.log.error("maximum upgrade timeout %d seconds meet" % timeout)
           return 'FAILURE'

        return 'SUCCESS'

    def query_controller_upgrade_capability(self):
        """
        query whether controllers support upgrade to new version or not
        return 'TRUE' or 'FALSE' to indicate whether support upgrade
        return 'FAILURE' in case of any error
        """
        upgrade_obj = ControllerUpgrade(self)
        result_obj = upgrade_obj.query_upgrade_capability()
        if result_obj != None:
           return result_obj.upgradeAvailable
        else:
           return 'FALIURE'


    def query_controller_cluster_upgrade_status(self):
        """
        query controllers cluster upgrade status
        """
        upgrade_obj = ControllerUpgrade(self)
        result_obj = upgrade_obj.query_controller_cluster_upgrade_status()
        if result_obj != None:
           return result_obj.status
        else:
           return 'FALIURE'

    def query_specific_controller_upgrade_status(self, controller_list):
        """
        query specific controllers upgrade status
        """
        statusList = []
        for controller in controller_list:
            status = controller.get_upgrade_status()
            if status != None:
               statusList.append(status)
            else:
               self.log.error("Cannot get " + controller.id + " upgrade status")
               return 'FALIURE'
        return statusList

    def query_specific_controller_divvy_num(self, controller_list):
        """
        query specific controllers delay divvy num
        """
        divvyList = []
        for controller in controller_list:
            divvy = controller.get_delay_divvy_num()
            if divvy != None:
               divvyList.append(divvy)
            else:
               self.log.error("Cannot get " + controller.id + " delay divvy num")
               return 'FALIURE'
        return divvyList

    def set_cmd_on_controller(self, controller_list, endpoint, value):
        """ Method to set command on  controller, like:
        nvp-controller # set control-cluster core cluster-param divvy_num_nodes_required 3
        """
        for controller in controller_list:
            result = controller.set_cmd_on_controller(endpoint, value)
            if result == 'FAILURE':
               self.log.error("set command on controller " + controller.id + " failed")
               return 'FALIURE'
        return 'SUCCESS'

    def restart(self):
        #save the base create endpoint
        create_endpoint = self.create_endpoint
        self.set_create_endpoint("appliance-management/system/restart")
        result_obj = super(NSXAPIApplianceManagement, self).create(None)
        #restore the base create endpoint
        self.set_create_endpoint(create_endpoint)
        # result.obj is as following
        # {'response_data': '',
        # 'status_code': 202,
        # 'reason': None,
        # 'response': <httplib.HTTPResponse instance at 0x94e77cc>,
        # 'error': None}
        if isinstance(result_obj, list):
            return result_obj[0]
        return result_obj

if __name__ == '__main__':
    #Unit testing
    import base_client
    log = logger.setup_logging('NSXAPIApplianceManagement')
    vsm_obj = VSM("10.144.139.99:443", "admin", "default","")
    appliance_management_client = NSXAPIApplianceManagement(vsm_obj)

    #Restart VSM
    result = appliance_management_client.restart()
    print result
