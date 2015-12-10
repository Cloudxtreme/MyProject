import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.nsx.manager.routing.redistribution.redistribution \
    as redistribution
import vmware.nsx.manager.routing.redistribution.api.redistribution_api_client \
    as redistribution_api_client
import vmware.nsx.manager.routing.redistribution.cli.redistribution_cli_client \
    as redistribution_cli_client


class RedistributionFacade(redistribution.Redistribution,
                           base_facade.BaseFacade):

    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, id_=None):
        super(RedistributionFacade, self).__init__(parent=parent, id_=id_)

        # Instantiate client objects
        api_client = redistribution_api_client.RedistributionAPIClient(
            parent=parent.get_client(constants.ExecutionType.API)
            if parent else None)
        cli_client = redistribution_cli_client.RedistributionCLIClient(
            parent=parent.get_client(constants.ExecutionType.CLI)
            if parent else None)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client,
                         constants.ExecutionType.CLI: cli_client}

if __name__ == '__main__':
    import vmware.nsx.manager.routing.redistribution.redistribution_facade \
        as redistribution_facade
    redistribution_facade.RedistributionFacade()
