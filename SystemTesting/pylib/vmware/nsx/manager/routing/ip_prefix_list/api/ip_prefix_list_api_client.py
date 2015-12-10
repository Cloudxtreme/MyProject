import vmware.nsx.manager.routing.ip_prefix_list.ip_prefix_list \
    as ip_prefix_list
import vmware.nsx.manager.manager_client as manager_client


class IPPrefixListAPIClient(ip_prefix_list.IPPrefixList,
                            manager_client.NSXManagerAPIClient):
    pass