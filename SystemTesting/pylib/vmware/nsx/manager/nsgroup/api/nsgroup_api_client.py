import vmware.nsx.manager.nsgroup.nsgroup as nsgroup
import vmware.nsx.manager.manager_client as manager_client


class NSGroupAPIClient(nsgroup.NSGroup,
                       manager_client.NSXManagerAPIClient):
    pass
