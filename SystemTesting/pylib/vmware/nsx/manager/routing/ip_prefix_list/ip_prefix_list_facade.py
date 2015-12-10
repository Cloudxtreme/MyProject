import vmware.common.base_facade as base_facade
import vmware.common.constants as constants
import vmware.common.global_config as global_config
import vmware.nsx.manager.routing.ip_prefix_list.api.\
    ip_prefix_list_api_client as ip_prefix_list_api_client
import vmware.nsx.manager.routing.ip_prefix_list.ip_prefix_list\
    as ip_prefix_list

pylogger = global_config.pylogger


class IPPrefixListFacade(ip_prefix_list.IPPrefixList, base_facade.BaseFacade):
    DEFAULT_EXECUTION_TYPE = constants.ExecutionType.API

    def __init__(self, parent=None, id_=None):
        super(IPPrefixListFacade, self).__init__(parent=parent, id_=id_)

        # instantiate client objects
        api_client = ip_prefix_list_api_client.IPPrefixListAPIClient(
            parent=parent.get_client(constants.ExecutionType.API),
            id_=id_)

        # Maintain the list of client objects.
        self._clients = {constants.ExecutionType.API: api_client}