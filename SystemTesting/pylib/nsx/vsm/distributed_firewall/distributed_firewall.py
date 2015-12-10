import pylib
import re
import result
import base64
import vsm_client
import base_client
from vmware.common.global_config import pylogger
import firewall_configuration_schema
from datetime import datetime
from vsm import VSM

class DistributedFirewall(vsm_client.VSMClient):

    def __init__(self, vsm=None):
        """ Constructor to create EventThresholds object

        @param vsm object on which EventThresholds object has to be configured
        """
        super(DistributedFirewall, self).__init__()
        self.log = pylogger
        self.schema_class = 'firewall_configuration_schema.FirewallConfigurationSchema'
        self.set_connection(vsm.get_connection())
        self.set_create_endpoint("/firewall/globalroot-0/config")
        self.set_read_endpoint("/firewall/globalroot-0/config")
        self.set_delete_endpoint("/firewall/globalroot-0/config")

        self.update_as_post = False
        self.create_as_put = True


    def get_data(self, data_type):
        return self.get_data_without_empty_tags(data_type)

    def create(self, py_dict_array):
        time_start = datetime.now()
        result_array = []
        py_dict = py_dict_array[0]
        self.log.debug("py_dict = %s" % py_dict)

        # If py_dict is empty, revert to default rules
        if py_dict == {}:
            result_obj = super(DistributedFirewall,self).delete()
            result_array.append(result_obj)
        else:
            schema_obj = self.get_schema_object(py_dict)
            self.log.debug("------------------------------------------------")
            # Read current config
            temp_obj = self.read()
            self.if_match = temp_obj.generationNumber

            #Add new Layer3 redirect rules to config
            rule_array = []
            for rule in schema_obj.layer3RedirectSections.section[0].rule:
                if rule.sectionId == 'default' or rule.sectionId is None:
                    rule.sectionId = None
                    rule_array.append(rule)

            index = len(temp_obj.layer3RedirectSections.section) - 1
            temp_obj.layer3RedirectSections.section[index].rule[:0] = rule_array

            index = 0
            for section in temp_obj.layer3RedirectSections.section:
                rule_array = []
                for rule in schema_obj.layer3RedirectSections.section[0].rule:
                    if rule.sectionId == 'default' or rule.sectionId is None:
                        continue
                    (layer, sectionid) = re.split('_', rule.sectionId, 1)
                    if sectionid == section._tag_id:
                        rule.sectionId = None
                        rule_array.append(rule)

                temp_obj.layer3RedirectSections.section[index].rule[:0] = rule_array
                index += 1

            # Add new Layer3 rules to config
            rule_array = []
            for rule in schema_obj.layer3Sections.section[0].rule:
                if rule.sectionId == 'default' or rule.sectionId is None:
                    rule.sectionId = None
                    rule_array.append(rule)

            index = len(temp_obj.layer3Sections.section) - 1
            temp_obj.layer3Sections.section[index].rule[:0] = rule_array

            index = 0
            for section in temp_obj.layer3Sections.section:
                rule_array = []
                for rule in schema_obj.layer3Sections.section[0].rule:
                    if rule.sectionId == 'default' or rule.sectionId is None:
                        continue
                    (layer, sectionid) = re.split('_', rule.sectionId, 1)
                    if sectionid == section._tag_id:
                        rule.sectionId = None
                        rule_array.append(rule)

                temp_obj.layer3Sections.section[index].rule[:0] = rule_array
                index += 1

            # Add new Layer2 rules to config
            rule_array = []
            for rule in schema_obj.layer2Sections.section[0].rule:
                if rule.sectionId == 'default' or rule.sectionId is None:
                    rule.sectionId = None
                    rule_array.append(rule)

            index = len(temp_obj.layer2Sections.section) - 1
            temp_obj.layer2Sections.section[index].rule[:0] = rule_array

            index = 0
            for section in temp_obj.layer2Sections.section:
                rule_array = []
                for rule in schema_obj.layer2Sections.section[0].rule:
                    if rule.sectionId == 'default' or rule.sectionId is None:
                        continue
                    (layer, sectionid) = re.split('_', rule.sectionId, 1)
                    if sectionid == section._tag_id:
                        rule.sectionId = None
                        rule_array.append(rule)

                temp_obj.layer2Sections.section[index].rule[:0] = rule_array
                index += 1

            self.response = self.request('PUT', self.create_endpoint,
                                temp_obj.get_data_without_empty_tags(self.content_type))
            result_obj = result.Result()
            self.set_result(self.response, result_obj)
            if result_obj.status_code != 200:
                result_array.append(result_obj)
                return result_array
            # Extract rule ids from received xml
            payload = result_obj.get_response_data()
            schema_obj.set_data(payload,'xml')
            rule_id = {}
            for section in schema_obj.layer3RedirectSections.section:
                for rule in section.rule:
                    rule_id[rule.name] = "L3REDIRECT_%s_%s" % (section._tag_id, rule._tag_id)
            for section in schema_obj.layer3Sections.section:
                for rule in section.rule:
                    rule_id[rule.name] = "L3_%s_%s" % (section._tag_id, rule._tag_id)
            for section in schema_obj.layer2Sections.section:
                for rule in section.rule:
                    rule_id[rule.name] = "L2_%s_%s" % (section._tag_id, rule._tag_id)

            # Get rule order (as specified in TDS)
            rule_order = {}
            if 'layer3redirectsections' in py_dict:
                for section in py_dict['layer3redirectsections']['section']:
                    for rule in section['rule']:
                        rule_order[rule['index']] = rule_id[rule['name']]

            if 'layer3sections' in py_dict:
                for section in py_dict['layer3sections']['section']:
                    for rule in section['rule']:
                        rule_order[rule['index']] = rule_id[rule['name']]

            if 'layer2sections' in py_dict:
                for section in py_dict['layer2sections']['section']:
                    for rule in section['rule']:
                        rule_order[rule['index']] = rule_id[rule['name']]

            for index in sorted(rule_order):
                result_obj = result.Result()
                result_obj.set_status_code(200)
                result_obj.set_response_data(rule_order[index])
                result_array.append(result_obj)

            time_end = datetime.now()
            total_time = time_end - time_start
            self.log.debug("Attempt to create %s components " % len(py_dict_array))
            self.log.debug("Time taken to create components %s " % total_time.seconds)

        return result_array

    def delete(self, schema_object=None):
        """ Client method to perform DELETE operation """
        (sch_layer, section_id, rule_id) = re.split('_', self.id, 2)
        self.id = None

        temp_obj = self.read()

        if(sch_layer == "L3REDIRECT"):
            delete_endpoint = "/firewall/globalroot-0/config/layer3redirectsections/%s/rules/%s" % (section_id, rule_id)
            # Set the If-Match header
            for section in temp_obj.layer3RedirectSections.section:
                if section._tag_id == section_id:
                    self.if_match = section._tag_generationNumber
                    break

        elif(sch_layer == "L3"):
            delete_endpoint = "/firewall/globalroot-0/config/layer3sections/%s/rules/%s" % (section_id, rule_id)
            # Set the If-Match header
            for section in temp_obj.layer3Sections.section:
                if section._tag_id == section_id:
                    self.if_match = section._tag_generationNumber
                    break

        elif(sch_layer == "L2"):
            delete_endpoint = "/firewall/globalroot-0/config/layer2sections/%s/rules/%s" % (section_id, rule_id)
            # Set the If-Match header
            for section in temp_obj.layer2Sections.section:
                if section._tag_id == section_id:
                    self.if_match = section._tag_generationNumber
                    break

        self.log.debug("delete_endpoint is %s " % delete_endpoint)
        self.log.debug("endpoint id is %s " % self.id)

        self.response = self.request('DELETE', delete_endpoint, "")
        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        return result_obj


if __name__ == '__main__':

    vsm_obj = VSM("10.24.226.62:443", "admin", "default", "","4.0")
    df_client = DistributedFirewall(vsm_obj)

    py_dict = {
            'layer3sections' : {
                'section' : [{
                            'rule' : [{
                                '_tag_disabled' : 'false',
                                '_tag_logged' : 'true',
                                'name' : "User_rule-1",
                                'action' : "allow",
                                'sectionid' : "L3_1038",
                                'destinations' :{
                                    '_tag_excluded' : "false",
                                    'destination' : [{
                                        'type' : "VirtualMachine",
                                        'value' : "vm-246",
                                    }]
                                },
                                'sources' :{
                                    '_tag_excluded' : "false",
                                    'source' : [{
                                        'type' : "VirtualMachine",
                                        'value' : "vm-245",
                                    }]
                                },
                                'services' : {
                                    'service' : [{
                                        'protocolname' : "ICMP",
                                    }]
                                }
                            },
                            {
                                '_tag_disabled' : 'false',
                                '_tag_logged' : 'true',
                                'name' : "def_rule-1",
                                'action' : "allow",
                                'sectionid' : "default",
                            },
                            {
                                '_tag_disabled' : 'false',
                                '_tag_logged' : 'true',
                                'name' : "def_rule-2",
                                'action' : "allow",
                                'sectionid' : None,
                            },
                            ]
                }]
            },
          }

    schema_obj = firewall_configuration_schema.FirewallConfigurationSchema(py_dict)

    result_obj = df_client.create(schema_obj)
    print result_obj.get_response_data()
    print result_obj.get_response()

