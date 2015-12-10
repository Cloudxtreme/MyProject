import neutron_client
import vmware.common.logger as logger
from neutron_tasks_response_schema import NeutronTasksResponseSchema

class NeutronTasksResponse(neutron_client.NeutronClient):

    def __init__(self, neutron_tasks=None):
        """ Constructor to create LogicalSwitchPort object

        @param LogicalSwitch object on which LogicalSwitchPort object has to be configured
        """
        super(NeutronTasksResponse, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'neutron_tasks_response_schema.NeutronTasksResponseSchema'
        self.set_content_type('application/json')
        self.set_accept_type('application/json')
        self.auth_type = "neutron"
        self.client_type = "neutron"

        if neutron_tasks is not None:
            self.set_connection(neutron_tasks.get_connection())

        self.set_create_endpoint("/tasks/" + str(neutron_tasks.id) +"/response")
        self.id = None
        self.update_as_post = False

if __name__ == '__main__':
    pass
