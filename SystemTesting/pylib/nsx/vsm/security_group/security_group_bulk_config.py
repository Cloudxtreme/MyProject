import vmware.common.logger as logger
import result
import base_client
from vsm import VSM
import security_group_schema
import vsm_security_group_lookup_ipaddress
import tasks

UNIVERSAL_SCOPE = 'universal'


class SecurityGroupBulkConfig(base_client.BaseClient):

    def __init__(self, vsm=None, scope=None):
        """ Constructor to create SecurityGroupBulkConfig object

        @param vsm object on which SecurityGroup has to be configured
        """
        super(SecurityGroupBulkConfig, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'security_group_schema.SecurityGroupSchema'
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.auth_type = "vsm"
        self.set_connection(vsm.get_connection())
        if UNIVERSAL_SCOPE == scope:
            self.set_create_endpoint('/services/securitygroup/bulk/universalroot-0')
        else:
            self.set_create_endpoint('/services/securitygroup/bulk/globalroot-0')
        self.set_read_endpoint('/services/securitygroup/')
        self.set_delete_endpoint('/services/securitygroup/')
        self.id = None
        self.update_as_post = False

    @tasks.thread_decorate
    def create(self, schema_object):
        """ Method to create SecurityGroup

        @param schema_object instance of class
        @return result object
        """

        self.response = self.request('POST', self.create_endpoint,
                                     schema_object.get_data_without_empty_tags(self.content_type))

        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        self.id = result_obj.response_data
        result_obj.set_is_result_object(False)

        return result_obj

    def get_id(self, response=None):
        if response is None:
            response = self.id
        return response

    def update(self, py_dict, override_merge=False):
        """ Client method to perform update operation
        overrides the update method in base_client.py

        @param py_dict dictionary object which contains schema attributes to be
        updated
        @param override_merge
        @return status http response status
        """
        self.log.debug("update input  = %s" % py_dict)
        update_object = self.get_schema_object(py_dict)
        schema_object = None

        if override_merge is False:
            schema_object = self.read()
            self.log.debug("schema_object after read:")
            schema_object.print_object()
            self.log.debug("schema_object from input:")
            update_object.print_object()
            try:
                self.merge_objects(schema_object, update_object)
            except:
                tb = traceback.format_exc()
                self.log.debug("tb %s" % tb)
        else:
            schema_object = update_object

        self.log.debug("schema object after merge:")
        schema_object.print_object()

        self.response = self.request('PUT', self.read_endpoint + "bulk" + "/" + self.id,
                                             schema_object.get_data_without_empty_tags(self.content_type))
        result_obj = result.Result()
        self.set_result(self.response, result_obj)

        return result_obj

    def compare_lookup_list(self, server_data, workload_parameters, user_data):
        """ Client method to find security groups via lookup of ip address

        @param server_data dict that has server data
        @param workload_parameters dict that has parameters passed at workload
        level
        @param user_data dict that has user data
        @return dict in format required for verification
        """
        if workload_parameters['lookup_entity'] != 'ipaddress':
            raise ValueError("Invalid entity passed for lookup, support only"
                             "for 'ipaddress'")

        ip_address_for_lookup = workload_parameters['lookup_value']
        lookup_client = vsm_security_group_lookup_ipaddress.SecurityGroupLookupIPAddress(
            self, ip_address_for_lookup)
        read_result = lookup_client.read().get_py_dict_from_object()

        object_id_list = []
        for security_group in read_result['securityGroups']:
            object_id_list.append({'objectId': security_group['objectId']})
        server_data['securityGroups'] = object_id_list
        result_dict = {'status': 'SUCCESS',
                       'response': server_data}
        return result_dict

if __name__ == '__main__':
    log = logger.setup_logging('Security Group - Test')
    vsm_obj = VSM("10.110.27.110", "admin", "default", "")
    security_group_client = SecurityGroupBulkConfig(vsm_obj)

    #Create Security Group
    py_dict = {'name': 'SG-2', 'description': 'Service Group - 2', 'objecttypename': 'SecurityGroup',
               'inheritanceallowed': 0, 'type': {'typename': 'SecurityGroup'},
               'scope': {'id': 'globalroot-0', 'objecttypename': 'GlobalRoot', 'name': 'Global'},
               'member': [{'objectid': 'datacenter-422', 'objecttypename': 'Datacenter'}],
               'excludemember': [{'objectid': 'domain-c427', 'objecttypename': 'ClusterComputeResource'}],
               'dynamicmemberdefinition': {'dynamicset': [{'operator': 'OR',
                                                          'dynamiccriteria': [{'operator': 'OR',
                                                                              'key': 'VM.GUEST_HOST_NAME',
                                                                              'criteria': 'contains',
                                                                              'value': 'Ubuntu',
                                                                              'isvalid': 'true'}],
                                                          }]
                                           },
               }

    sg_schema_object = security_group_client.get_schema_object(py_dict)
    sg_schema_object.print_object()
    result_obj_1 = security_group_client.create(sg_schema_object)
    print result_obj_1.status_code
    print security_group_client.id

    security_group_schema = security_group_client.read()
    security_group_schema.print_object()

    #Update Security Group
    py_dict_1 = {'name': 'SG-2', 'description': 'Service Group Description - 2', 'objecttypename': 'SecurityGroup',
                 'inheritanceallowed': 1}
    response_status = security_group_client.update(py_dict_1)
    print response_status.status_code

    #Delete Security Group
    response_status = security_group_client.delete()
    print response_status.status_code
