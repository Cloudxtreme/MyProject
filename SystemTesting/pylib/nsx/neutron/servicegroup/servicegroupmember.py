import vmware.common.logger as logger
import result
import neutron_client

class ServiceGroupMember(neutron_client.NeutronClient):

    def __init__(self, servicegroup=None):
        """ Constructor to create ServiceGroupMember object

        @param servicegroup object in which member has to be added
        """
        super(ServiceGroupMember, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'service_group_member_schema.ServiceGroupMemberSchema'

        if servicegroup is not None:
            self.set_connection(servicegroup.get_connection())

        self.set_create_endpoint("/groupings/service-groups/%s" % servicegroup.id)
        self.set_delete_endpoint("/groupings/service-groups/%s/members" % servicegroup.id)

    def create(self, schema_object):
        self.create_endpoint = self.create_endpoint + "/members/" + schema_object._member_id
        self.response = self.request('POST', self.create_endpoint,
                                     schema_object.get_data(self.content_type))
        self.id = schema_object._member_id
        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        result_obj.set_response_data(schema_object._member_id)
        return result_obj

    def get_id(self, response=None):
        return response

if __name__ == '__main__':
    import neutron
    import base_client
    from service import Service
    from servicegroup import ServiceGroup

    log = logger.setup_logging('Neutron ServiceGroup Test')
    neutron_object = neutron.Neutron("10.112.11.7", "admin", "default")

    #Create Two Services for Service Group Testing
    service_client_1 = Service(neutron=neutron_object)
    py_dict = {'display_name': 'Service-1', 'value': '1234', \
               'application_protocol': 'TCP', 'source_port': '2345'}
    result_objs = base_client.bulk_create(service_client_1, [py_dict])
    print "Create Service Status code: %s" % result_objs[0].status_code
    print "Service id: %s" % service_client_1.id

    #Create composite service group for testing
    composite_service_group_client = ServiceGroup(neutron=neutron_object)
    py_dict = {'display_name': 'Composite Service Group - 1', 'description': 'SG Description'}
    result_objs = base_client.bulk_create(composite_service_group_client, [py_dict])
    print "Create ServiceGroup Status code: %s" % result_objs[0].status_code
    print "ServiceGroup id: %s" % composite_service_group_client.id

    #Add Service-1 to Composite Service Group
    service_group_member_1 = ServiceGroupMember(composite_service_group_client)
    py_dict = {'_member_id': service_client_1.id}
    result_objs = base_client.bulk_create(service_group_member_1, [py_dict])
    print "Add Service to Composite Service Group Status code: %s" % result_objs[0].status_code

    #Delete Service-1 from Composite Service Group
    response_status = service_group_member_1.delete()
    print "Delete service from CompositeServiceGroup result response: %s" % \
          response_status.status_code

    #Delete composite service group
    response_status = composite_service_group_client.delete()
    print "Delete Composite Service Group result response: %s" % response_status.status_code

    #Delete service-1
    response_status = service_client_1.delete()
    print "Delete service result response: %s" % response_status.status_code