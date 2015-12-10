import vsm_client
import connection
import result
import time
import re
import importlib
from vsm import VSM
from vxlan_controller_spec_schema import VXLANControllerSpecSchema
from base_cli_client import BaseCLIClient
from job_poll_status import JobPollStatus
from vxlan_controllers_schema import VXLANControllersSchema
from vxlan_controller_credential_schema import VXLANControllerCredentialSchema


class VXLANController(vsm_client.VSMClient):
    def __init__(self, vsm=None, **kwargs):
        """ Constructor to create VXLANController managed object

        @param vsm object on which vxlan controller has to be configured
        """
        super(VXLANController, self).__init__()
        self.schema_class = 'vxlan_controller_spec_schema.VXLANControllerSpecSchema'

        if vsm is not None:
            self.set_connection(vsm.get_connection())
        self.set_create_endpoint("/vdn/controller")
        self.id = None
        self.username = None
        self.password = None
        self.ssh_connection = None
        self.location_header = None

    def create(self, schema_object):
        """ Creates vxlan controller with specified parameters

      @param schema_object which has the parameters to deploy
      vxlan controller like host, datastore etc.
      """
        vxlan_self = self
        result_obj = super(VXLANController, self).create(schema_object)
        job_id = self.get_id()
        job_status = JobPollStatus(self)
        job_status.set_job_id(job_id)
        self.log.debug("Waiting for task %s to complete in 1800s" % job_id)
        # timeout in seconds
        status = job_status.poll_jobs('COMPLETED', 1800)
        self.log.debug("vxlan controller create status %s" % status)
        if status == 'FAILURE':
            #Temp status code until we standardize it
            location_header = vxlan_self.location_header
            self.log.debug("location header is %s" % location_header)
            if location_header is not None:
                self.log.debug("*** Sleeping for 300 to free ip, FAILED vxlan controller cleanup takes time***")
                time.sleep(300)
            result_obj[0].set_status_code('400')
            return result_obj
        location_header = vxlan_self.location_header
        if location_header is not None:
            self.id = location_header.split('/')[-1]
            result_obj[0].set_response_data(self.id)
        return result_obj

    def query(self):
        """ Populates the all vxlan controller information.

      @param None
      """
        controllers = VXLANControllersSchema()
        controllers.set_data(self.base_query(), self.accept_type)
        return controllers

    def delete(self, py_dict):
        end_point_uri = self.delete_endpoint + '/' + str(self.id) + '?forceRemoval=true'
        self.response = self.request('DELETE', end_point_uri, "")
        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        self.log.debug(
            "*** Sleeping for 120 sec due to PR 1043761 Takes time to free ip from pool after deleting controller***")
        time.sleep(120)
        return result_obj

    def get_ip(self):
        controllerClientArray = self.query().controller
        for controller in controllerClientArray:
            if(controller.id == self.id):
               controllerIP = controller.ipAddress
               return controllerIP

    def get_name(self):
        controllerClientArray = self.query().controller
        for controller in controllerClientArray:
            if(controller.id == self.id):
               return controller.name

    def get_upgrade_status(self):
        controllerClientArray = self.query().controller
        for controller in controllerClientArray:
            if(controller.id == self.id):
               return controller.upgradeStatus

    def get_delay_divvy_num(self):
        """ Method to get delay divvy num on  controller
        nvp-controller # show control-cluster core cluster-param divvy_num_nodes_required
        divvy_num_nodes_required: 1

        """
        cli = BaseCLIClient()
        cli.set_schema_class('divvy_num_schema.DivvyNumSchema')
        cli.set_create_endpoint("show control-cluster core cluster-param divvy_num_nodes_required")
        ssh = self.get_ssh_connection()
        cli.set_connection(ssh)
        cli_data = cli.read()
        divvy_num_entry_list = cli_data.table
        ssh.close()
        if (len(divvy_num_entry_list) == 0):
            return "FAILURE"
        divvy_num = divvy_num_entry_list[0].divvy
        return divvy_num

    def set_cmd_on_controller(self, endpoint, value):
        """ Method to set command on  controller, like:
        nvp-controller # set control-cluster core cluster-param divvy_num_nodes_required 3
        while "set control-cluster core cluster-param divvy_num_nodes_required" is the endpoint,
        '3' is the value"
        """
        cli = BaseCLIClient()
        cli.set_schema_class('no_stdout_schema.NoStdOutSchema')
        cli.set_create_endpoint(endpoint + " " + str(value))
        ssh = self.get_ssh_connection()
        cli.set_connection(ssh)
        result_obj = cli.create()
        schema_obj = cli.read_response(result_obj)
        ssh.close()
        if result_obj.status_code != int(0):
            if schema_object.stdout != '':
                self.log.info("set command on controller failed, output is not empty")
                return "FAILURE"
        return "SUCCESS"

    """
    paramiko library may have issue if have multiple ssh connections(already fixed in latest version.
    We cannot reuse the existing ssh connection since the connection has the timeout issue, so developers
       need to close the ssh connection actively each time after you use it.
    """
    def get_ssh_connection(self):
        ip = self.get_ip()
        ssh_connection = connection.Connection(ip,self.username,self.password,"None","ssh")
        self.ssh_connection = ssh_connection.anchor
        return(self.ssh_connection)

    def vxlan_controller_service(self,pyDict):
        operation = pyDict['vxlancontrollerservice']
        if (operation.lower() == "stop" ):
           result = self.stop_controller_service()
           if (result == "FAILURE"):
               return 'FAILURE'
        if (operation.lower() == "restart" ):
           result = self.restart_controller_service()
           if (result == "FAILURE"):
               return 'FAILURE'
        return 'SUCCESS'

    def stop_controller_service(self):
        ssh = self.get_ssh_connection()
        command = "shutdown controller"
        stdin, stdout, stderr = ssh.request(command)
        output = stdout.read().strip()
        expectedstring = "Stopping /etc/init.d/nicira-nvp-controller"
        m = re.search(expectedstring,output)
        if m:
            self.log.info("Stop controller service succssfully")
            self.log.debug("shutdown controller command output %s" % output)
            ssh.close()
            return 'SUCCESS'
        else:
            self.log.error("Stop controller service failed")
            self.log.debug("shutdown controller command output %s" % output)
            ssh.close()
            return 'FAILURE'

    def restart_controller_service(self):
        ssh = self.get_ssh_connection()
        command = "restart controller"
        stdin, stdout, stderr = ssh.request(command)
        output = stdout.read().strip()
        expectedstring = "Join complete"
        m = re.search(expectedstring,output)
        if m:
            self.log.info("Restart controller service successfully")
            self.log.debug("restart controller command output %s" % output)
            ssh.close()
            return 'SUCCESS'
        else:
            self.log.error("Restart controller service failed")
            self.log.debug("restart controller command output %s" % output)
            ssh.close()
            return 'FAILURE'

    def change_controller_password(self, password):
        pyDict = {'apipassword': password}
        schema_class = 'vxlan_controller_credential_schema.VXLANControllerCredentialSchema'
        module, class_name = schema_class.split(".")
        some_module = importlib.import_module(module)
        loaded_schema_class = getattr(some_module, class_name)
        # creating an instance of schema class
        schema_object = loaded_schema_class(pyDict)

        read_endpoint = "vdn/controller/credential"
        self.response = self.request('PUT',read_endpoint,
                            schema_object.get_data(self.content_type))
        result_obj = result.Result()
        self.set_result(self.response, result_obj)

        return result_obj

    def set_controller_ssl(self,pyDict):
        schema_class = 'vxlan_controller_config_schema.VXLANControllerConfigSchema'
        module, class_name = schema_class.split(".")
        some_module = importlib.import_module(module)
        loaded_schema_class = getattr(some_module, class_name)
        # creating an instance of schema class
        schema_object = loaded_schema_class(pyDict)
        read_endpoint = "/vdn/controller/cluster"
        self.response = self.request('PUT',read_endpoint,
                           schema_object.get_data(self.content_type))
        result_obj = result.Result()
        self.set_result(self.response, result_obj)

        return result_obj

if __name__ == '__main__':
    import base_client
    vsm_obj = VSM("10.115.173.194:443", "admin", "default")
    controller = VXLANController(vsm_obj)
    py_dict = {'deploytype': 'small', 'name': 'vm-1-12769', 'firstnodeofcluster': 'true', 'hostid': 'host-89',
               'resourcepoolid': 'resgroup-104', 'ippoolid': 'ipaddresspool-1', 'datastoreid': 'datastore-92'}
    base_client.bulk_create(controller, [py_dict])
    py_dict = {'firstNodeofCluster': 'true'}
    controller.delete()
