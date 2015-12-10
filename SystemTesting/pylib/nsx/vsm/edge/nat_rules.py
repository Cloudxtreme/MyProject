import connection
import result
import tasks

import base_client
from edge import Edge
import edge_nat_rules_schema
import vmware.common.logger as logger
import vmware.common.global_config as global_config
from vsm import VSM
pylogger = global_config.pylogger

class NATRules(vsm_client.VSMClient):
    def __init__(self, edge=None, version=None):
        """ Constructor to create NATRules object

        @param edge object
        on which NATRules has to be configured
        """
        super(NATRules, self).__init__()
        self.schema_class = \
            'edge_nat_rules_schema.EdgeNATRulesSchema'
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        self.auth_type = "vsm"
        if edge is not None:
            self.set_connection(edge.get_connection())
        if version == None or version == "":
            self.connection.api_header = '/api/4.0'
        else:
            self.connection.api_header = '/api/'+str(version)
        self.set_create_endpoint("/edges/" + edge.id + "/nat/config/rules")
        self.create_as_put = False
        self.id = None



    @tasks.thread_decorate
    def create(self, schema_object):
        self.response = self.request('POST', self.create_endpoint,
                                     schema_object.get_data_without_empty_tags(self.content_type))

        result_obj = result.Result()
        self.set_result(self.response, result_obj)

        response = result_obj.get_response()
        location = response.getheader("Location")
        self.log.debug("Location header is %s" % location)
        self.location_header = location

        #NAT rule ID is fetched from the Location Header
        if location is not None:
            self.id = location.split('/')[-1]
            result_obj.set_response_data(self.id)
        else:
            pylogger.error("Error in getting location from HTTP Response Header")

        return result_obj
