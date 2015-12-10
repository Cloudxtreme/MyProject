#!/usr/bin/env python

import vmware.nsx.controller.controller as controller
import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.controller.cli.controller_cli_client as controller_cli_client
import vmware.nsx.controller.cmd.controller_cmd_client as controller_cmd_client
import vmware.nsx.controller.api.controller_api_client as controller_api_client

pylogger = global_config.pylogger


# Create client facade class for every inventory
# item in a product/project. This class inherits
# from the base abstract class. For example,
# ESXClientFacade inherits from hypervisor class.
class ControllerFacade(controller.Controller, base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.CLI

    def __init__(self, ip=None, username=None, password=None,
                 cmd_username='root', cmd_password='vmware',
                 cert_thumbprint=None, build=None):
        super(ControllerFacade, self).\
            __init__(ip=ip, username=username,
                     password=password, cmd_username=cmd_username,
                     cmd_password=cmd_password,
                     cert_thumbprint=cert_thumbprint, build=build)
        self.ip = ip
        self.username = username
        self.password = password
        self.cmd_username = cmd_username
        self.cmd_password = cmd_password
        self.cert_thumbprint = cert_thumbprint
        self.build = build
        cli_client = controller_cli_client.ControllerCLIClient(
            ip=self.ip, username=self.username, password=self.password)
        cmd_client = controller_cmd_client.ControllerCMDClient(
            ip=self.ip, username=self.username, password=self.password,
            cmd_password=self.cmd_password)
        api_client = controller_api_client.ControllerAPIClient(
            ip=self.ip, username=self.cmd_username,
            password=self.cmd_password)

        # Maintain the list of client objects.
        # This will later be used by initialize() to create
        # connection anchors
        self._clients = {constants.ExecutionType.CLI: cli_client,
                         constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CMD: cmd_client}

if __name__ == "__main__":
    import optparse
    opt_parser = optparse.OptionParser()
    opt_parser.add_option(
        '--manager-ip', action='store', help='IP of NSX Manager')
    opt_parser.add_option(
        '--manager-thumbprint', action='store',
        help='Certificate thumbprint of Manager')
    opt_parser.add_option(
        '--controller-ip', action='store', help='IP of NSX Controller')
    opt_parser.add_option(
        '--controller-user', action='store', default=None,
        help='NSX Controller login username')
    opt_parser.add_option(
        '--controller-password', action='store', default=None,
        help='NSX Controller login password')
    opt_parser.add_option(
        '--controller-cmd-user', action='store', default=None,
        help='NSX Controller cmd login username')
    opt_parser.add_option(
        '--controller-cmd-password', action='store', default=None,
        help='NSX Controller cmd login password')
    options, args = opt_parser.parse_args()

    for (desc, opt) in [("Manager IP", options.manager_ip),
                        ("Manager Cert Thumbprint",
                         options.manager_thumbprint),
                        ("Controller IP", options.controller_ip)]:
        if opt is None:
            opt_parser.error("%s is missing." % desc)
    for (desc, opt) in [("Controller username", options.controller_user),
                        ("Controller password", options.controller_password)]:
        if opt is None:
            pylogger.debug("%s not provided, using the default." % desc)

    for (desc, opt) in [("Controller cmd username",
                         options.controller_cmd_user),
                        ("Controller cmd password",
                         options.controller_cmd_password)]:
        if opt is None:
            pylogger.debug("%s not provided, using the default." % desc)

    import vmware.nsx.controller.controller_facade as controller_facade
    controller_facade = controller_facade.ControllerFacade(
        ip=options.controller_ip, username=options.controller_user,
        password=options.controller_password,
        cmd_username=options.controller_cmd_user,
        cmd_password=options.controller_cmd_password)
    controller_facade.set_nsx_registration(
        execution_type=constants.ExecutionType.CLI,
        manager_ip=options.manager_ip,
        manager_thumbprint=options.manager_thumbprint)
