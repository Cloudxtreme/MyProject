import base64
import result
import re
import tasks
import pylib
from vmware.common.global_config import pylogger
import rule_schema
import section_schema
import si_profile_schema
from vsm import VSM
import vsm_client

UNIVERSAL_SCOPE = "universal"

class DFWSections(vsm_client.VSMClient):

    def __init__(self, vsm=None, section_scope=None):
        """ Constructor to create DFWSections object

        @param vsm object on which DFWSections object has to be configured
        """
        super(DFWSections, self).__init__()
        self.log = pylogger
        self.schema_class = 'section_schema.SectionSchema'
        self.set_connection(vsm.get_connection())
        self.scope = section_scope
        self.update_as_post = False
        self.create_as_put = False

    def get_tag_id(self):
        sec_schema_obj = self.read()
        return sec_schema_obj._tag_id

    def get_tag_name(self):
        sec_schema_obj = self.read()
        return sec_schema_obj._tag_name

    def get_tag_type(self):
        sec_schema_obj = self.read()
        return sec_schema_obj._tag_type

    def get_tag_generationNumber(self):
        sec_schema_obj = self.read()
        return sec_schema_obj._tag_generationNumber

    def get_tag_managedBy(self):
        sec_schema_obj = self.read()
        return sec_schema_obj._tag_managedBy

    def read(self):
        """ Overriding the base_client read method to perform READ operation """
        store_id = self.id
        (sch_layer, self.id) = re.split('_', self.id, 1)

        if(sch_layer == "L3REDIRECT"):
            self.set_read_endpoint("/firewall/globalroot-0/config/layer3redirectsections/" + self.id)
        elif(sch_layer == "L3" and self.scope == None):
            self.set_read_endpoint("/firewall/globalroot-0/config/layer3sections/" + self.id)
        elif(sch_layer == "L3" or sch_layer == "L2" and self.scope == UNIVERSAL_SCOPE):
            self.set_read_endpoint("/firewall/config/sections/" + self.id)
        elif(sch_layer == "L2" and self.scope == None):
            self.set_read_endpoint("/firewall/globalroot-0/config/layer2sections/" + self.id)

        schema_object = self.get_schema_object()

        self.response = self.request('GET', self.read_endpoint, "")
        self.log.debug(self.response.status)
        payload_schema = self.response.read()
        self.log.debug("Overriding base_client read %s" % payload_schema)
        self.id = store_id
        if payload_schema != None and payload_schema != "":
            schema_object.set_data(payload_schema, self.accept_type)
        else:
            return None
        return schema_object

    def get_response_dict(self):
        sch_obj = self.read()
        return sch_obj.get_py_dict_from_object()

    def get_data(self, data_type):
        return self.get_data_without_empty_tags(data_type)

    @tasks.thread_decorate
    def create(self, schema_obj):
        (sch_layer, sch_name) = re.split('_', schema_obj._tag_name, 1)
        schema_obj._tag_name = sch_name
        action_type = 'allow'

        if(sch_layer == "L3REDIRECT"):
            #Create a Layer 3 redirect section
            self.set_create_endpoint("/firewall/globalroot-0/config/layer3redirectsections")
            action_type = 'REDIRECT'
            si_profile_dict = {
               'objectid' : 'serviceprofile-1',
            }
            si_profile_obj = si_profile_schema.SiProfileSchema(si_profile_dict)
        elif(sch_layer == "L3" and self.scope == None):
            #Create a Layer 3 section
            self.set_create_endpoint("/firewall/globalroot-0/config/layer3sections")
        elif((sch_layer == "L3" or sch_layer == "L2") and self.scope == UNIVERSAL_SCOPE):
            #Create a Layer-3 or Layer-2 Global section
            self.set_create_endpoint("/firewall/config/sections")
        elif(sch_layer == "L2" and self.scope == None):
            #Create a Layer 2 section
            self.set_create_endpoint("/firewall/globalroot-0/config/layer2sections")

        # Workaround to create empty section
        # creating section with a temporary rule and deleting it
        # PR 1258499
        rule_dict = {
            'name' : 'TempRule',
            '_tag_disabled' : 'false',
            'action' : action_type,
        }
        rule_obj = rule_schema.RuleSchema(rule_dict)
        if(sch_layer == "L3REDIRECT"):
            rule_obj.siProfile = si_profile_obj
        schema_obj.rule.append(rule_obj)

        self.response = self.request('POST', self.create_endpoint,
                            schema_obj.get_data_without_empty_tags(self.content_type))
        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        if result_obj.status_code != 201:
            return result_obj

        res_data = result_obj.get_response_data()
        # Set the If-Match header
        self.if_match = re.findall(r'generationNumber="\d+"' , res_data)[0].split(r'"')[1]
        # Get the id of temporary from response
        rule_id = re.findall(r'rule id="\d+"' , res_data)[0].split(r'"')[1]
        # Get section id from response
        section_id = re.findall(r'section id="[a-zA-Z0-9-]+"' , res_data)[0].split(r'"')[1]

        # Delete temp rule
        temp_del_endpoint = self.get_create_endpoint() + "/" + section_id + "/rules/" + rule_id
        temp_response = self.request('DELETE', temp_del_endpoint, "")

        self.id = sch_layer + '_' + section_id
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

        (sch_layer, self.id) = re.split('_', self.id, 1)
        self.set_generation_number(sch_layer, self.id)
        self.log.debug("Generation Number from GET Section %s" % self.if_match)

        self.response = self.request('PUT', self.read_endpoint + "/" + self.id,
                                             schema_object.get_data_without_empty_tags(self.content_type))
        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        if result_obj.status_code != 200:
            return result_obj

        res_data = result_obj.get_response_data()
        # Set the If-Match header
        self.if_match = re.findall(r'generationNumber="\d+"' , res_data)[0].split(r'"')[1]
        # Get section id from response
        section_id = re.findall(r'section id="[a-zA-Z0-9-]+"' , res_data)[0].split(r'"')[1]

        self.id = sch_layer + '_' + section_id
        result_obj.response_data = self.id
        return result_obj


    def delete(self, schema_object=None):
        """ Client method to perform DELETE operation """

        (sch_layer, self.id) = re.split('_', self.id, 1)

        if(sch_layer == "L3REDIRECT"):
            self.set_delete_endpoint("/firewall/globalroot-0/config/layer3redirectsections/" + self.id)
        elif(sch_layer == "L3" and self.scope == None):
            self.set_delete_endpoint("/firewall/globalroot-0/config/layer3sections/" + self.id)
        elif((sch_layer == "L3" or sch_layer == "L2") and self.scope == UNIVERSAL_SCOPE):
            self.set_delete_endpoint("/firewall/config/sections/" + self.id)
        elif(sch_layer == "L2" and self.scope == None):
            self.set_delete_endpoint("/firewall/globalroot-0/config/layer2sections/" + self.id)

        self.set_generation_number(sch_layer, self.id)
        self.log.debug("delete_endpoint is %s " % self.delete_endpoint)
        self.log.debug("endpoint id is %s " % self.id)
        self.log.debug("schema_object to delete call is %s " % schema_object)

        self.response = self.request('DELETE', self.delete_endpoint, "")
        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        return result_obj


    def set_generation_number(self, layer, section_id):
        if(layer == "L3REDIRECT"):
            self.set_read_endpoint("/firewall/globalroot-0/config/layer3redirectsections/")
        elif(layer == "L3"):
            self.set_read_endpoint("/firewall/globalroot-0/config/layer3sections/")
        elif(layer == "L2"):
            self.set_read_endpoint("/firewall/globalroot-0/config/layer2sections/")
        elif(layer == "L3" or layer == "L2" and self.scope == UNIVERSAL_SCOPE):
            self.set_read_endpoint("/firewall/config/sections/")

        #Read current config
        temp_obj = super(DFWSections, self).read()
        self.if_match = temp_obj._tag_generationNumber


if __name__ == '__main__':

    vsm_obj = VSM("10.24.226.247:443", "admin", "default", "","4.0")
    import pdb
    pdb.set_trace()
    df_client = DFWSections(vsm_obj,section_scope='universal')

    py_dict = {
        '_tag_name' : 'L2_Section1',
        '_tag_managedby' : 'universalroot-0',
        '_tag_type' : 'LAYER2',
        }

    schema_obj = section_schema.SectionSchema(py_dict)
    result_obj = df_client.create(schema_obj)
    print "++++++ Section ID: " + str(result_obj.get_response_data())
    print "++++++ Response Output: " + str(result_obj.get_response().__dict__)

    from time import sleep
    sleep(2)

    py_dict_1 = {
        '_tag_name' : 'L2_Section1_changed',
        }
    result_obj = df_client.update(py_dict_1)

    result_obj = df_client.delete()
    print result_obj.get_response_data()
    print result_obj.get_response()

