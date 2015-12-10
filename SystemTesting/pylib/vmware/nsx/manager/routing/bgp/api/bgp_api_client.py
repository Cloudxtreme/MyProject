import vmware.nsx.manager.routing.bgp.bgp as bgp
import vmware.nsx.manager.manager_client as manager_client


class BGPAPIClient(bgp.BGP, manager_client.NSXManagerAPIClient):
    pass
