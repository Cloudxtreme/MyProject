#!/usr/bin/env python

import vmware.nsx.controller.controller as controller
import vmware.common.base_client as base_client
import vmware.common.connections.expect_connection as expect_connection

SHELL_ACCESS = " : debug os-shell"


class ControllerCMDClient(controller.Controller, base_client.BaseCMDClient):

    def get_connection(self):
        return expect_connection.ExpectConnection(
            ip=self.ip, username=self.username, password=self.password)

    @property
    def connection(self):
        if self._connection:
            return self._connection
        self._connection = self.get_connection()
        self._connection.create_connection()
        self._connection.default_prompt(
            command=SHELL_ACCESS, expect=['Password:'])
        self._connection.default_prompt(
            command=self.cmd_password, expect=['#'])
        return self._connection
