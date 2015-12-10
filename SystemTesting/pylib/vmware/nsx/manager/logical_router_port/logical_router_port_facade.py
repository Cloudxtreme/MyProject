import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.nsx.manager.logical_router_port.logical_router_port \
    as logical_router_port
import vmware.nsx.manager.logical_router_port.api.logical_router_port_api_client \
    as logical_router_port_api_client
import vmware.nsx.manager.logical_router_port.cli.logical_router_port_cli_client \
    as logical_router_port_cli_client


class LogicalRouterPortFacade(logical_router_port.LogicalRouterPort,
                              base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = "NSX70"

    def __init__(self, parent=None, id_=None):
        super(LogicalRouterPortFacade, self).__init__(parent=parent, id_=id_)
        # instantiate client objects
        api_client = logical_router_port_api_client.LogicalRouterPortAPIClient(
            parent=parent.get_client(constants.ExecutionType.API)
            if parent else None, id_=self.id_)
        cli_client = logical_router_port_cli_client.LogicalRouterPortCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI)
            if parent else None, id_=self.id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}

if __name__ == '__main__':
    import optparse
    import vmware.nsx.manager.manager_client as manager_client
    import vmware.nsx.manager.logical_router_port.logical_router_port_facade \
        as logical_router_port_facade
    opt_parser = optparse.OptionParser()
    opt_parser.add_option('--manager-ip', action='store',
                          # default='10.146.108.43',
                          help='IP of NSX Manager')
    opt_parser.add_option('--user', action='store', default='admin',
                          help='user id of manager [%default*]')
    opt_parser.add_option('--password', action='store', default='default',
                          help='password for manager [%default*]')
    opt_parser.add_option('--lrport-id', action='store',
                          # default='99f8bcc0-8984-4394-ad50-ad50ca2b0a7a',
                          help='lrport id on nsx manager')
    options, args = opt_parser.parse_args()
    if not options.manager_ip:
        opt_parser.error('Manager IP not provided')
    if not options.lrport_id:
        opt_parser.error('lrport id not provided')
    mgr_obj = manager_client.NSXManagerFacade(
        ip=options.manager_ip, username=options.user,
        password=options.password)
    mgr_obj.get_node_id()
    lrp_facade = logical_router_port_facade.LogicalRouterPortFacade(
        id_=options.lrport_id, parent=mgr_obj)
    print lrp_facade.get_ip(), lrp_facade.get_netcidr()
