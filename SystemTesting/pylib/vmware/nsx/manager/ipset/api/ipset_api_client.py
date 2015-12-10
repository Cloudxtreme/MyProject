import vmware.nsx.manager.ipset.ipset as ipset
import vmware.nsx.manager.manager_client as manager_client


class IPSetAPIClient(ipset.IPSet,
                     manager_client.NSXManagerAPIClient):
    pass
