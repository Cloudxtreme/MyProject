import vmware.nsx.manager.routing.redistribution.redistribution \
    as redistribution
import vmware.nsx.manager.manager_client as manager_client


class RedistributionCLIClient(redistribution.Redistribution,
                              manager_client.NSXManagerCLIClient):
    pass
