import vmware.common.base_facade as base_facade
import vmware.common.global_config as global_config
import vmware.nsx.edge.cli.edge_cli_client as edge_cli_client
import vmware.nsx.edge.edge as edge
import vmware.common.constants as constants

pylogger = global_config.pylogger


class EdgeFacade(edge.Edge, base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.CLI

    def __init__(self, ip=None, username=None, password=None,
                 build=None, parent=None):

        super(EdgeFacade, self).__init__(ip=ip,
                                         username=username,
                                         password=password,
                                         build=build,
                                         parent=parent)

        cli_client = edge_cli_client.EdgeCLIClient(ip=self.ip,
                                                   username=self.username,
                                                   password=self.password)

        self._clients = {constants.ExecutionType.CLI: cli_client}

    def get_build_number(self):

        # based on release version
        if "-" in self.build:
            build_number = self.build.split("-")[1]
        else:
            build_number = self.build
        return build_number

if __name__ == "__main__":
    import vmware.nsx.edge.edge_facade as edge_facade

    ev = edge_facade.EdgeFacade("10.110.63.117", 'admin', 'default')
    pylogger.info("client object %s" % ev.get_client(
        constants.ExecutionType.CLI).connection)

    ev.register_nsx_edge_node(execution_type=constants.ExecutionType.CLI,
                              manager_ip='10.110.62.150',
                              manager_thumbprint='435143a1b5fc8bb70a3aa9b15d',
                              manager_username='admin',
                              manager_password='default')

    ev.query_show_interface(execution_type=constants.ExecutionType.CLI)
    print "Execution complete"
