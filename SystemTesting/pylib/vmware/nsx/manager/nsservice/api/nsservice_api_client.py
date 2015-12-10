import vmware.nsx.manager.nsservice.nsservice as nsservice
import vmware.nsx.manager.manager_client as manager_client


class NSServiceAPIClient(nsservice.NSService,
                         manager_client.NSXManagerAPIClient):
    pass
