import vsm_client
import vmware.common.logger as logger
import service_profile_schema
import service_profiles_schema
from vsm import VSM
import result
import tasks

class ServiceProfile(vsm_client.VSMClient):
    def __init__(self, vsm=None):
        """ Constructor to create ServiceProfile object
        @param vsm object on which ServiceProfile has to be configured
        """
        super(ServiceProfile, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'service_profile_schema.ServiceProfileSchema'
        self.set_connection(vsm.get_connection())
        self.set_create_endpoint("/si/serviceprofile")
        self.set_read_endpoint("/si/serviceprofiles")
        self.id = None
        self.update_as_post = False

    # Overriding read function in the base_client.py
    def read(self):
        """ Client method to perform READ operation """
        self.schema_class = 'service_profiles_schema.ServiceProfilesSchema'
        schema_object = super(ServiceProfile, self).read()
        self.schema_class = 'service_profile_schema.ServiceProfileSchema'
        return schema_object

    @tasks.thread_decorate
    # Overriding create function in the base_client.py
    def create(self, r_schema):
        # Check for flag to get service profile. It its set then find
        # service profile id of the respective service profile name
        # If it is not set, create new service profile
        if r_schema._getserviceprofileflag == 'true':
            service_profile_response = self.read()
            service_profiles_array = service_profile_response.serviceProfileArray
            required_service_profile_name = ""
            found_profile = False
            for p in service_profiles_array:
                if r_schema._serviceprofilename == p.name:
                    self.log.debug("Service Profile is %s" % p.objectId)
                    found_profile = True
                    required_service_profile_name = p.objectId
            result_obj = result.Result()
            if found_profile == False:
                self.log.error("Unable to find default service profile")
                result_obj.set_response_data(None)
                result_obj.set_status_code(404)
            else:
                result_obj.set_response_data(required_service_profile_name)
                result_obj.set_status_code(200)
            return result_obj
        else:
            self.schema_class = 'service_profile_schema.ServiceProfileSchema'
            self.log.debug("Make POST call to create service profile")
            result_obj = super(ServiceProfile, self).create(r_schema)
            return result_obj[0] 
