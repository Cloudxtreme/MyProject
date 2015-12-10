import optparse

import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.manager as manager
import vmware.nsx.manager.api.manager_api_client as manager_api_client
import vmware.nsx.manager.cli.manager_cli_client as manager_cli_client
import vmware.nsx.manager.ui.manager_ui_client as manager_ui_client


pylogger = global_config.pylogger
NSXManagerAPIClient = manager_api_client.ManagerAPIClient
NSXManagerCLIClient = manager_cli_client.ManagerCLIClient
NSXManagerUIClient = manager_ui_client.ManagerUIClient


class NSXManagerFacade(manager.Manager, base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, ip=None, username=None, password=None,
                 root_password=None, cert_thumbprint=None, build=None,
                 ui_ip=None):
        if root_password is None:
            root_password = constants.ManagerCredential.PASSWORD
            pylogger.warning("Root Password for NSX Manager not set "
                             "in testbed yaml. "
                             "Setting it to %s" % root_password)
        super(NSXManagerFacade, self).__init__(
            ip=ip, username=username, password=password,
            root_password=root_password, cert_thumbprint=cert_thumbprint,
            build=build)

        # instantiate client objects
        api_client = NSXManagerAPIClient(
            ip=self.ip, username=self.username, password=self.password)
        cli_client = NSXManagerCLIClient(
            ip=self.ip, username=self.username, password=self.password,
            root_password=root_password)
        ui_client = NSXManagerUIClient(
            ip=ui_ip, username=self.username, password=self.password)
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client,
                         constants.ExecutionType.UI: ui_client}

    def get_manager_ip(self):
        return self.ip

    def get_version(self):
        # TODO(prashants) : Hardcoded string "7.0.0.0.0" need to be changed
        # based on release version
        if "-" in self.build:
            version = "7.0.0.0.0." + self.build.split("-")[1]
        else:
            version = self.build
        return version


if __name__ == '__main__':
    import vmware.nsx.manager.manager_client as manager_client
    opt_parser = optparse.OptionParser()
    opt_parser.add_option('--manager-ip', action='store',
                          help='IP of NSX Manager')
    opt_parser.add_option('--user', action='store', default='admin',
                          help='user id of manager [%default*]')
    opt_parser.add_option('--password', action='store', default='default',
                          help='password for manager [%default*]')
    options, args = opt_parser.parse_args()
    if not options.manager_ip:
        opt_parser.error('Manager IP not provided')
    mgr_obj = manager_client.NSXManagerFacade(options.manager_ip,
                                              options.user,
                                              options.password)
    mgr_obj.get_node_id()
    thumbprint = mgr_obj.get_manager_thumbprint()
    pylogger.info("Thumbprint for %r is %r" % (options.manager_ip,
                                               thumbprint))
    mgr_obj.node_network_partitioning(
        manager_ip=options.manager_ip,
        operation='set',
        execution_type=constants.ExecutionType.CLI)
