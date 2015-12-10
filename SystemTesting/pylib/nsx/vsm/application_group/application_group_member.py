import vmware.common.logger as logger
import result
import vsm_client
import tasks

class ApplicationGroupMember(vsm_client.VSMClient):

    def __init__(self, applicationgroup=None):
        """ Constructor to create ApplicationGroupMember object

        @param applicationgroup object in which member has to be added
        """
        super(ApplicationGroupMember, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'application_group_member_schema.ApplicationGroupMemberSchema'

        if applicationgroup is not None:
            self.set_connection(applicationgroup.get_connection())

        self.set_create_endpoint("/services/applicationgroup/%s" % applicationgroup.id)
        self.set_delete_endpoint("/services/applicationgroup/%s/members" % applicationgroup.id)

    @tasks.thread_decorate
    def create(self, schema_object):
        # Save the base endpoint
        temp_create_endpoint = self.create_endpoint
        self.create_endpoint = self.create_endpoint + "/members/" + schema_object._member_id
        # This is a product design bug for using PUT to add a member to applicationgroup
        self.response = self.request('PUT', self.create_endpoint,
                                     schema_object.get_data(self.content_type))
        self.id = schema_object._member_id
        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        result_obj.set_response_data(schema_object._member_id)
        # Restore the base endpoint
        self.create_endpoint = temp_create_endpoint
        return result_obj

