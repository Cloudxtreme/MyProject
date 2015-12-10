import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.versions as versions
import vmware.nsx.manager.routing.bgp.bgp as bgp
import vmware.nsx.manager.routing.bgp.api.bgp_api_client as bgp_api_client
import vmware.nsx.manager.routing.bgp.cli.bgp_cli_client as bgp_cli_client


class BGPFacade(bgp.BGP, base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API
    DEFAULT_IMPLEMENTATION_VERSION = versions.NSXTransformers.AVALANCHE

    def __init__(self, parent=None, id_=None):
        super(BGPFacade, self).__init__(parent=parent, id_=id_)

        # Instantiate client objects
        api_client = bgp_api_client.BGPAPIClient(
            parent=parent.get_client(constants.ExecutionType.API)
            if parent else None, id_=id_)
        cli_client = bgp_cli_client.BGPCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI)
            if parent else None, id_=id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}

if __name__ == '__main__':
    import vmware.nsx.manager.routing.bgp.bgp_facade as bgp_facade
    bgp_facade.BGPFacade()
