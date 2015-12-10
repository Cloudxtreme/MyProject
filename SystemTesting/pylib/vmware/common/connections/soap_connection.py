import pyVim.connect as connect
import vmware.common.connection as connection
import vmware.common.constants as constants
import vmware.common.result as result
import vmware.vsphere.vc.vc_soap_util as vc_soap_util


class SOAPConnection(connection.Connection):

    def __init__(self, ip="", username="", password="",
                 connection_object=None):
        super(SOAPConnection, self).__init__(ip, username, password,
                                             connection_object)

    def create_connection(self):
        self.anchor = connect.SmartConnect(
            host=self.ip, user=self.username, pwd=self.password,
            port=constants.Network.Port.VIM_SOAP)

    def request(self, object, method, schema):
        x = getattr(object, method)
        args = schema.get_command_args()
        y = x(**args)
        res = result.Result()
        if str(method).find("_Task") != -1:
            y = vc_soap_util.wait_for_task_completion(y)
            if y.info.result is not None:

                res.response_data = y.info.result
            else:
                res.response_data = y.info.task
        else:
            res.response_data = y
        return res
