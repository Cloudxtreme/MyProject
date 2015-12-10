import yaml
import os
import sys
PATH_YAML_WORKLOADS = "/mts/home4/prabuddh/public_html/yaml/"
PATH_YAML_DESCRIPTORS = "/mts/home4/prabuddh/public_html/yaml/descriptors/"
import re

class Module(yaml.YAMLObject):
    yaml_tag = u'!Module'
    def __init__(self, module):
        self.organization = 'VDNet'
        self.id = module

class Type(yaml.YAMLObject):
    yaml_tag = u'!Type'
    def __init__(self, workload, key):
        self.id = key;
        self.properties = {}
        if 'linkedworkload' in  workload[key]:
            self.type = 'object'
            #self.payload = workload[key]['format']
        else:
            self.type = 'string'
        if 'format' in workload[key]:
            dict_format = workload[key]['format']
            if type(dict_format) is dict:
                paramArray = dict_format.keys()
                for paramkey in paramArray:
                    self.properties[paramkey] = {}
                    self.properties[paramkey]['description'] = workload[paramkey]['description']
                    self.properties[paramkey]['title'] = paramkey
                    self.properties[paramkey]['required'] = True
                    format = workload[paramkey]['format']
                    if type(format) is str:
                        self.properties[paramkey]['type'] = 'string'
                    if type(format) is dict:
                        self.properties[paramkey]['type'] = 'object'
                        self.properties[paramkey]['ref'] = paramkey
                    if type(format) is list:
                        ''' Array of string'''
                        self.properties[paramkey]['items'] = {}
                        element = format[0]
                        element = element.replace('ref:', '')
                        element = element.replace(' ', '')
                        print "element" + element;
                        if element in workload:
                            if  workload[element]['format'] == 'string':
                                self.properties[paramkey]['items']['type'] = 'string'
                            ''' Array of objects'''
                            if type(workload[element]['format']) is dict:
                                self.properties[paramkey]['items']['ref'] = {}
                                self.properties[paramkey]['items']['ref'] = element
                        else:
                            self.properties[paramkey]['items']['type'] = 'string'

def GetAllYamlWorkloads():
    list_of_yaml_workloads = []
    for file in os.listdir(PATH_YAML_WORKLOADS):
        if file.endswith(".yml"):
            list_of_yaml_workloads = list_of_yaml_workloads + [file]
    return list_of_yaml_workloads

def ConstructDescriptorUsingKeysDatabase(workload, module):
    descriptor = []
    header = Module(module)
    descriptor = descriptor + [header]
    for key in workload:
        if workload[key]['type'] != 'action':
            continue
        if key == 'reconfigure' or key == 'checkifexists':
            continue
        key_descriptor = Type(workload, key)
        descriptor = descriptor + [key_descriptor]
    return descriptor

if __name__ == "__main__":
    list_of_yaml_workloads = []
    list_of_yaml_workloads = GetAllYamlWorkloads()
    for yaml_workload in list_of_yaml_workloads:
        if yaml_workload != 'TestInventoryWorkload.yml':
            continue
        print "Process for " + yaml_workload
        location = PATH_YAML_WORKLOADS + yaml_workload
        stream = open(location, "r")
        workload = yaml.load(stream)
        workload_name = yaml_workload[:-4]
        descriptor_name = yaml_workload[:-12] + 'Descriptor.yml'
        yaml_descriptor = ConstructDescriptorUsingKeysDatabase(workload, workload_name)
        store_path = PATH_YAML_DESCRIPTORS + descriptor_name
        print "stored at =" + store_path;
        with open(store_path, 'w') as outfile:
            outfile.write(yaml.dump(yaml_descriptor, default_flow_style=False, allow_unicode=True))

