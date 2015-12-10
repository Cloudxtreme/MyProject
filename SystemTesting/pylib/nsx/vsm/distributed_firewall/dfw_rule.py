import base64
import result
import re
import tasks
import pylib
from vmware.common.global_config import pylogger
import rule_schema
import section_schema
from vsm import VSM
import vsm_client

UNIVERSAL_SCOPE = "universal"

class DFWRule(vsm_client.VSMClient):

    def __init__(self, vsm=None, rule_scope=None):
        """ Constructor to create DFW Rule object

        @param vsm object on which DFWRuleobject has to be configured
        """
        super(DFWRule, self).__init__()
        self.log = pylogger
        self.schema_class = 'rule_schema.RuleSchema'
        self.set_connection(vsm.get_connection())
        self.scope = rule_scope
        self.update_as_post = False
        self.create_as_put = False


    @tasks.thread_decorate
    def create(self, schema_obj):
        """ Overriding the base_client create method to perform CREATE operation """
        (sec_layer, section_id) = re.split('_', schema_obj.sectionId, 1)
        schema_obj.sectionId = section_id
        self.id = section_id
        if((sec_layer == "L3" or sec_layer == "L2") and self.scope == UNIVERSAL_SCOPE):
            section_get_endpoint = "/firewall/config/sections/" + section_id

        self.response = self.request('GET', section_get_endpoint)
        payload_schema = self.response.read()
        if payload_schema != None and payload_schema != "":
            sec_schema_obj = section_schema.SectionSchema()
            sec_schema_obj.set_data(payload_schema, self.accept_type)
        else:
            self.log.debug("GET Section failed for %s" % section_id)
            return None
        self.if_match = sec_schema_obj._tag_generationNumber
        self.log.debug("Generation Number from GET Section %s" % self.if_match)

        if((sec_layer == "L3" or sec_layer == "L2") and self.scope == UNIVERSAL_SCOPE):
            self.set_create_endpoint("/firewall/config/sections/" + section_id + "/rules")

        self.response = self.request('POST', self.create_endpoint,
                            schema_obj.get_data_without_empty_tags(self.content_type))
        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        if result_obj.status_code != 201:
            return result_obj
        res_data = result_obj.get_response_data()
        rule_id = re.findall(r'rule id="\d+"' , res_data)[0].split(r'"')[1]
        self.log.debug("Rule Id %s successfully created for section %s" % (rule_id,section_id))

        self.id = sec_layer + '_' + section_id + '_' + rule_id
        result_obj.response_data = self.id
        return result_obj


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

        (sec_layer, section_id, rule_id) = re.split('_', self.id, 2)
        section_get_endpoint = "/firewall/config/sections/" + section_id

        self.response = self.request('GET', section_get_endpoint)
        payload_schema = self.response.read()
        if payload_schema != None and payload_schema != "":
            sec_schema_obj = section_schema.SectionSchema()
            sec_schema_obj.set_data(payload_schema, self.accept_type)
        else:
            self.log.debug("GET Section failed for %s" % section_id)
            return None
        self.if_match = sec_schema_obj._tag_generationNumber
        self.log.debug("Generation Number from GET Section %s" % self.if_match)

        self.response = self.request('PUT', self.read_endpoint + "/" + rule_id,
                                             schema_object.get_data_without_empty_tags(self.content_type))
        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        if result_obj.status_code != 200:
            return result_obj
        res_data = result_obj.get_response_data()
        rule_id = re.findall(r'rule id="\d+"' , res_data)[0].split(r'"')[1]
        self.log.debug("Rule Id %s successfully created for section %s" % (rule_id,section_id))

        self.id = sec_layer + '_' + section_id + '_' + rule_id
        result_obj.response_data = self.id
        return result_obj


    def delete(self, schema_object=None):
        """ Overriding the base_client delete method to perform DELETE operation """
        (sec_layer, section_id, rule_id) = re.split('_', self.id, 2)

        if(sec_layer == "L3" or sec_layer == "L2" and self.scope == UNIVERSAL_SCOPE):
            section_get_endpoint = "/firewall/config/sections/" + section_id

        self.response = self.request('GET', section_get_endpoint)
        payload_schema = self.response.read()
        if payload_schema != None and payload_schema != "":
            sec_schema_obj = section_schema.SectionSchema()
            sec_schema_obj.set_data(payload_schema, self.accept_type)
        else:
            self.log.debug("GET Section failed for %s" % section_id)
            return None
        self.if_match = sec_schema_obj._tag_generationNumber
        self.log.debug("Generation Number from GET Section %s" % self.if_match)

        if((sec_layer == "L3" or sec_layer == "L2") and self.scope == UNIVERSAL_SCOPE):
            delete_endpoint = "/firewall/config/sections/%s/rules/%s" % (section_id, rule_id)

        self.log.debug("delete_endpoint is %s " % delete_endpoint)
        self.log.debug("endpoint id is %s " % self.id)

        self.response = self.request('DELETE', delete_endpoint, "")
        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        return result_obj


    def read(self, schema_object=None):
        """ Overriding the base_client read method to perform READ operation """
        (sec_layer, section_id, rule_id) = re.split('_', self.id, 2)
        store_id = self.id
        self.id = rule_id

        if((sec_layer == "L3" or sec_layer == "L2") and self.scope == UNIVERSAL_SCOPE):
            self.set_read_endpoint("/firewall/config/sections/%s/rules" % section_id)

        result_obj = super(DFWRule, self).read()
        self.id = store_id
        return result_obj


    def get_response_dict(self):
        sch_obj = self.read()
        return sch_obj.get_py_dict_from_object()

    def get_tag_id(self):
        rule_schema_obj = self.read()
        return rule_schema_obj._tag_id

    def get_name(self):
        rule_schema_obj = self.read()
        return rule_schema_obj.name

    def get_tag_managedBy(self):
        rule_schema_obj = self.read()
        return rule_schema_obj._tag_managedBy

    def get_tag_disabled(self):
        rule_schema_obj = self.read()
        return rule_schema_obj._tag_disabled

    def get_tag_logged(self):
        rule_schema_obj = self.read()
        return rule_schema_obj._tag_logged

if __name__ == '__main__':

    vsm_obj = VSM("10.24.226.247:443", "admin", "default", "","4.0")
    df_client = DFWRule(vsm_obj,rule_scope="universal")

    py_dict = {
                  '_tag_disabled' : 'false',
                  '_tag_logged' : 'true',
                  'name' : "User_rule-1",
                  'action' : "allow",
                  'sectionid' : "L3_af2fd00d-f033-4920-a4f4-aa3ce74ec3d9",
                  'destinations' :{
                       '_tag_excluded' : "false",
                       'destination' : [{
                          'type' : "IPSet",
                          'value' : "ipset-0e2cfc2a-657c-4872-8684-8e7a1570a51c",
                        }]
                   },
                   'sources' :{
                       '_tag_excluded' : "false",
                       'source' : [{
                            'type' : "SecurityGroup",
                            'value' : "securitygroup-edc48e4b-2fcf-4e86-b74b-c1d566630c2b",
                            }]
                   },
                   'services' : {
                       'service' : [{
                           'protocolname' : "ICMP",
                           'protocol' : "2",
                           }]
                   },
     }

    schema_obj = rule_schema.RuleSchema(py_dict)
    import pdb
    pdb.set_trace()
    result_obj = df_client.create(schema_obj)
    print result_obj.get_response_data()
    print result_obj.get_response()

    from time import sleep
    sleep(2)

    result_obj = df_client.read()
    py_dict_1 = {
                  '_tag_logged' : 'false',
                  'name' : "User_rule-1-MODI",
                  'action' : "deny",
                  'sources' :{
                       '_tag_excluded' : "false",
                       'source' : [{
                          'type' : "IPSet",
                          'value' : "ipset-0e2cfc2a-657c-4872-8684-8e7a1570a51c",
                        }]
                   },
                   'destinations' :{
                       '_tag_excluded' : "true",
                       'destination' : [{
                            'type' : "SecurityGroup",
                            'value' : "securitygroup-edc48e4b-2fcf-4e86-b74b-c1d566630c2b",
                            }]
                   },
    }
    result_obj = df_client.update(py_dict_1)
    result_obj = df_client.delete()
    print result_obj.status_code
    print result_obj.get_response_data()

