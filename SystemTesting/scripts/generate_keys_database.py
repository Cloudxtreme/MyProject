import argparse
import logging
import sys
import yaml

from auto_gen_helper import *
from descriptor_factory import DescriptorFactory
from descriptors.module_descriptor import ModuleDescriptor
from descriptors.type_descriptor import TypeDescriptor
import vmware.common.global_config as global_config



logger = global_config.pylogger


# Parameters with which this script needs to be run
# This will create NSXWorkload.yaml file in given code_path

# --resource_descriptor_path api_spec\controller_node.yml
# --resource_settings_path python\management_api\napi\settings.yml
# --code_path ./

keys_database = []
def main():
    """
    Main function to be called from command line
    """
    global gen_code_path
    global keys_database_file

    config = get_config()
    gen_code_path = config.code_path
    fmt = "%(asctime)s %(name)s %(levelname)s %(message)s"
    logging.basicConfig(stream=sys.stdout, format=fmt)
    logging.getLogger().setLevel(logging.DEBUG)
    keys_database_file = KeysDatabaseFile()

    descriptor_factory = DescriptorFactory(config.resource_descriptor_path, config.resource_settings_path)
    logger.debug("Iterate through all modules for creating keys database")

    # First we need to parse all POST commands
    # all type-ids referenced in post commands are created with preprocess and postprocess tags in
    # keys database file
    for component in descriptor_factory.components:
        for descriptor in component['descriptors']:
                if isinstance(descriptor, RestRoutineDescriptor):
                    if descriptor.method == "POST":
                        body_type_id = descriptor.request.body_type_id
                        generate_keys(body_type_id, descriptor)

    # All those type-ids that are getting referenced from GET calls are then parsed
    # Only the ones that have not been used to generate keys database are considered
    for component in descriptor_factory.components:
        for descriptor in component['descriptors']:
                if isinstance(descriptor, RestRoutineDescriptor):
                    if descriptor.method == "GET":
                        for response in descriptor.responses:
                            body_type_id = response.body_type_id
                            generate_keys(body_type_id, descriptor)

def generate_keys(body_type_id, descriptor):
    """
    Function that gives call to generate the keys
    It first gets the type descriptor referenced in the rest routing descriptor
    And if the type descriptor is valid asks for creating keys database
    @param body_type_id: Referenced type descriptor
    @param descriptor: Rest routing descriptor
    @return:
    """
    if body_type_id is not None and body_type_id != 'None':
        log_string = "Found Rest Routine descriptor '{}' using '{}'"\
            .format(descriptor.id, body_type_id)
        logger.info(log_string)
        type_descriptor = find_descriptor(body_type_id, descriptor)
        if type_descriptor is not None:
            keys_database_file.generate_code(type_descriptor, descriptor)

def find_descriptor(body_type_id, descriptor):
    """
    Finds whether type descriptor is present in the database of descriptors
    Then finds whether the type descriptor is already used for creating keys
    @param body_type_id: type descriptor getting used in the rest routine
    @param descriptor: Rest routine descriptor
    @return: none or type descriptor
    """
    desc = descriptor.descriptor_factory.descriptors[body_type_id]
    if hasattr(desc, "keys_database_created"):
        log_string = "Descriptor '{}' already covered".format(desc.id)
        logger.info(log_string)
        return None
    desc.keys_database_created = True
    log_string = "Descriptor '{}' getting referenced from descriptor '{}'".format(desc.id, descriptor.id)
    logger.info(log_string)
    return desc

def get_config():
    """
    Parsing command line args
    @return: args
    """
    parser = argparse.ArgumentParser(description='AUTOGENCLIENTSCHEMA')
    parser.add_argument("--resource_descriptor_path")
    parser.add_argument("--resource_settings_path")
    parser.add_argument("--code_path")
    args = parser.parse_args()
    return args


class KeysDatabaseFile(object):
    """
    Single entry point for creating keys database file and all keys within
    """
    def __init__(self):
        file_name = 'NSXWorkload.yaml'
        self.fd = open(file_name, 'w')
        self.keys_dict = {}

    def generate_code(self, type_descriptor, rest_routine_descriptor):
        """
        Creates object of KeyAsDescriptor and generates code for it
        @param type_descriptor: descriptor that represents object that carries all params for the
        rest routine
        @param rest_routine_descriptor: it carries all info about the rest routine
        @return:
        """
        key_as_descriptor = KeyAsDescriptor(type_descriptor, rest_routine_descriptor)
        py_dict = key_as_descriptor.generate_key_code()
        self.fd.write(yaml.dump(py_dict, default_flow_style=False))
        return


class KeyAsProperty(object):
    """
    This is the attribute in one of the type descriptors
    This key is atleast second level parameter in the TDS and is not getting
    directly referenced from and rest routine
    """
    def __init__(self, property_name, property_value):
        self.property_name = property_name
        keys_database.append(self.property_name.lower())
        self.property_value = property_value
        log_string = "Generating keys for Property '{}'".format(self.property_name)
        logger.info(log_string)

    def generate_key_code(self):
        """
        Generate key code
        @return code for the key
        """
        py_dict = {'type': 'parameter',
                   'format': '',
                   'derived_components': '',
                   'sample': ''}
        code = self.property_name.lower() + ":\n"
        if 'description' in self.property_value.keys():
            py_dict['description'] = self.property_value['description']
        elif 'title' in self.property_value.keys():
            py_dict['description'] = self.property_value['title']
        return {self.property_name.lower(): py_dict}


class KeyAsDescriptor(object):
    """
    Descriptor name forms the key in the database with preprocess, postprocess and method params
    This key is the top level key in the TDS
    """
    def __init__(self, type_descriptor, rest_routine_descriptor):
        self.type_descriptor = type_descriptor
        self.rest_routine_descriptor = rest_routine_descriptor
        log_string = "Generating keys for descriptor '{}'".format(self.type_descriptor.id)
        logger.info(log_string)

    def write_key(self):
        """
        Writes key name in the database file
        @return: code to that has key name
        """
        code = self.type_descriptor.id.lower()
        keys_database.append(self.type_descriptor.id.lower())
        return code

    def write_parameters_for_key(self):
        """
        Puts in the keys parameters
        Also puts in preprocess, postprocess and method if the rest routing descriptor is POST
        @return: code for the key
        """
        py_dict = {'format': '',
                   'description': '',
                   'derived_components': ['nsx'],
                   'sample': '',
                   'params': [self.type_descriptor.id.lower()]}
        if self.rest_routine_descriptor is not None and \
                self.rest_routine_descriptor.method == "POST":
            py_dict['preprocess'] = 'PreProcessNSXSubComponent'
            py_dict['postprocess'] = 'StoreSubComponentObjects'
            py_dict['method'] = 'CreateAndVerifyComponent'
            py_dict['type'] = 'component'
        else:
            py_dict['type'] = 'parameter'
        return py_dict

    def write_properties_of_descriptor(self):
        """
        Iterates through all the properties in the type descriptor
        and calls for code generation
        @return: code for keys
        """
        py_dict = {}
        if 'properties' in self.type_descriptor.meta_spec:
            for key, value in self.type_descriptor.meta_spec['properties'].iteritems():
                if "type" in value:
                    if value['type'] == 'string':
                        if key.lower() not in keys_database:
                            property_key = KeyAsProperty(key, value)
                            py_dict.update(property_key.generate_key_code())
                        else:
                            log_string = "Key '{}' already covered".format(key)
                            logger.info(log_string)
                    elif value['type'] == 'array':
                        if 'items' in value.keys():
                            if '$ref' in value['items'].keys():
                                desc = find_descriptor(value['items']['$ref'], self.type_descriptor)
                                if desc is not None:
                                    property_key = KeyAsDescriptor(desc, None)
                                    py_dict.update(property_key.generate_key_code())
                            else:
                                if key.lower() not in keys_database:
                                    property_key = KeyAsProperty(key, value)
                                    py_dict.update(property_key.generate_key_code())
                                else:
                                    log_string = "Key '{}' already covered".format(key)
                                    logger.info(log_string)
                    elif value['type'] == 'object':
                        if 'enum' in value.keys():
                            for objs in value['enum']:
                                if '$ref' in objs.keys():
                                    desc = find_descriptor(objs['$ref'], self.type_descriptor)
                                    if desc is not None:
                                        property_key = KeyAsDescriptor(desc, None)
                                        py_dict.update(property_key.generate_key_code())
                                else:
                                    if key.lower() not in keys_database:
                                        property_key = KeyAsProperty(key, value)
                                        py_dict.update(property_key.generate_key_code())
                                    else:
                                        log_string = "Key '{}' already covered".format(key)
                                        logger.info(log_string)
        return py_dict

    def generate_key_code(self):
        """
        Calls on different items to be filled in for the key
        @return:
        """
        py_dict = {}
        key = self.write_key()
        py_dict[key] = self.write_parameters_for_key()
        py_dict.update(self.write_properties_of_descriptor())
        return py_dict


if __name__ == "__main__":
    main()

