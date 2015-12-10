import vmware.common.base_client as base_client
import vmware.common.connections.ssh_connection as ssh_connection
import vmware.kvm.vm.vm as vm


class VMCMDClient(vm.VM, base_client.BaseCMDClient):

    def get_connection(self):
        return ssh_connection.SSHConnection(
            self.ip, self.username, self.password)
