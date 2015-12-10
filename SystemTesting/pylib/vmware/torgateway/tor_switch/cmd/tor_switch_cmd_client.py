#!/usr/bin/env python

import vmware.torgateway.tor_switch.tor_switch as torswitch
import vmware.common.base_client as base_client
import vmware.common.connections.ssh_connection as ssh_connection


class TORSwitchCMDClient(torswitch.TORSwitch, base_client.BaseCMDClient):

    def __init__(self, parent=None, id=None):
        super(TORSwitchCMDClient, self).__init__(parent=parent)
        self.id = id

    def get_connection(self):
        return ssh_connection.SSHConnection(
            ip=self.ip, username=self.username, password=self.password)
