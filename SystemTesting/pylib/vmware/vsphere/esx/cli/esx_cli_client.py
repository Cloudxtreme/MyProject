import vmware.common.constants as constants
import vmware.vsphere.esx.esx as esx
import vmware.vsphere.vsphere_client as vsphere_client
import vmware.common.connections.ssh_connection as ssh_connection


class ESXCLIClient(esx.ESX, vsphere_client.VSphereCLIClient):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def get_connection(self):
        return ssh_connection.SSHConnection(self.ip, self.username,
                                            self.password)
