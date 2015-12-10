#!/usr/bin/env python
import vmware.common.base_client as base_client
import vmware.common.global_config as global_config
import vmware.common.connections.ssh_connection as ssh_connection
import vmware.kvm.kvm as kvm

pylogger = global_config.pylogger


class KVMCLIClient(kvm.KVM, base_client.BaseCLIClient):

    def get_connection(self):
        return ssh_connection.SSHConnection(
            self.ip, self.username, self.password)
