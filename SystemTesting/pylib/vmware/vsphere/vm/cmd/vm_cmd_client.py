import vmware.common.connections.ssh_connection as ssh_connection
import vmware.vsphere.vm.vm as vm
import vmware.vsphere.vsphere_client as vsphere_client


class VMCMDClient(vm.VM, vsphere_client.VSphereCMDClient):

    def get_connection(self):
        return ssh_connection.SSHConnection(self.ip, self.username,
                                            self.password)
