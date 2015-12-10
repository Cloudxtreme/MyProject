#!/usr/bin/env python
import vmware.common.base_client as base_client
import vmware.common.connections.ssh_connection as ssh_connection
import vmware.kvm.kvm as kvm


class KVMAPIClient(kvm.KVM, base_client.BaseAPIClient):

    def __init__(self, parent=None, **kwargs):
        super(KVMAPIClient, self).__init__(parent=parent, **kwargs)

    def get_connection(self):
        return ssh_connection.SSHConnection(
            self.ip, self.username, self.password)
