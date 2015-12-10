import argparse
from descriptor_factory import DescriptorFactory
from descriptors.module_descriptor import ModuleDescriptor
from descriptors.type_descriptor import TypeDescriptor
from descriptors.rest_routine_descriptor import \
    RestRoutineDescriptor
import logging
import sys
from descriptors import lg as logger
from auto_gen_helper import *

gen_code_path = ""


def main():
    global gen_code_path
    config = get_config()
    gen_code_path = config.code_path
    fmt = "%(asctime)s %(name)s %(levelname)s %(message)s"
    logging.basicConfig(stream=sys.stdout, format=fmt)
    logging.getLogger().setLevel(logging.DEBUG)

    descriptor_factory = DescriptorFactory(config.resource_descriptor_path, config.resource_settings_path)
    build_endpoint_to_client_object_mapping(descriptor_factory)
    endpoint_mapper = EndpointDescriptorMapping()
    type_ids_used = TypeIDsToSchemaFiles()

    logger.debug("Iterate through all modules for creating client and schema files")
    for component in descriptor_factory.components:
        create_module_files = False
        module_descriptor = None
        for descriptor in component['descriptors']:
            if isinstance(descriptor, ModuleDescriptor):
                if descriptor.id != 'ControllerNode' and \
                        descriptor.id != 'MetaModule':
                    create_module_files = True
                    module_descriptor = descriptor
        if create_module_files:
            logger.debug("ID for module: %s" % module_descriptor.id)
            # Per !Module tag in yaml files we create one endpoint dir
            client_dir_path = create_endpoint_dir(module_descriptor)
            # Per POST call in each !Module we create one client file
            post_descriptor_found = False
            put_descriptor_found = False
            for descriptor in component['descriptors']:
                if isinstance(descriptor, RestRoutineDescriptor):
                    if descriptor.method == "POST":
                        ClientFile(module_descriptor, descriptor, client_dir_path)
                        create_schema_files(module_descriptor, descriptor, component)
                        post_descriptor_found = True
            # If the endpoint in PUT call is not used till now we would create new
            # client file. This is to handle conditions where there are multiple PUT
            # calls with different endpoints in single !Module
            for descriptor in component['descriptors']:
                if isinstance(descriptor, RestRoutineDescriptor):
                    if descriptor.method == "PUT" and endpoint_mapper.check_for_used_endpoint(descriptor.path):
                        endpoint_mapper.add_mapping(descriptor.path, descriptor)
                        ClientFile(module_descriptor, descriptor, client_dir_path)
                        create_schema_files(module_descriptor, descriptor, component)
                        put_descriptor_found = True

            # If we havent got any PUT or POST calls in entire !Module but
            # have any GET call then we need to have client file
            if not put_descriptor_found and not post_descriptor_found:
                for descriptor in component['descriptors']:
                    if isinstance(descriptor, RestRoutineDescriptor):
                        if descriptor.method == "GET":
                            ClientFile(module_descriptor, descriptor, client_dir_path)
                            create_schema_files(module_descriptor, descriptor, component)
            # Check whether any schema file needs to be generated
            # This will ensure that all referenced schema files are generated even if
            # some endpoints are missing from client files
            put_command = 0
            for descriptor in component['descriptors']:
                if isinstance(descriptor, RestRoutineDescriptor):
                    if descriptor.method == "PUT":
                        put_command += 1
                    if descriptor.method == "POST" or descriptor.method == "PUT":
                        body_type_id = descriptor.request.body_type_id
                        if body_type_id is not None and body_type_id != 'None' and not \
                                type_ids_used.check(body_type_id):
                            schema_file_descriptor = descriptor.descriptor_factory.descriptors[body_type_id]
                            type_ids_used.add_type_descriptor(body_type_id)
                            dir_path = create_schema_dir(module_descriptor)
                            SchemaFile(schema_file_descriptor, dir_path)
                    if descriptor.method == "GET":
                        for response in descriptor.responses:
                            body_type_id = response.body_type_id
                            if body_type_id is not None and body_type_id != 'None' and not \
                                    type_ids_used.check(body_type_id):
                                schema_file_descriptor = descriptor.descriptor_factory.descriptors[body_type_id]
                                type_ids_used.add_type_descriptor(body_type_id)
                                dir_path = create_schema_dir(module_descriptor)
                                SchemaFile(schema_file_descriptor, dir_path)
            if put_command > 1:
                logger.warning("PUT command appeared more than once in %s" % module_descriptor.id)

    # Create common schema files
    common_dir_path = create_common_dir()

    # Need to go through entire list until all referenced schemas are generated
    schema_defn_incomplete = True
    while schema_defn_incomplete:
        schema_defn_incomplete = False
        for component in descriptor_factory.components:
            for descriptor in component['descriptors']:
                if isinstance(descriptor, TypeDescriptor):
                    if hasattr(descriptor, 'generated_schema') and \
                            descriptor.generated_schema is False:
                        # Generate schema file if this descriptor is referenced in already
                        # generated schema file
                        SchemaFile(descriptor, common_dir_path)
                        descriptor.generated_schema = True
                        schema_defn_incomplete = True

# Create directory for each !Module item in yml files
def create_endpoint_dir(module_descriptor):
    global gen_code_path
    dir_path = gen_code_path + os.sep + module_descriptor.id.lower()
    if not os.path.exists(dir_path):
        os.makedirs(dir_path)
    return dir_path

# Create common dir to accomodate all referenced schema files
def create_common_dir():
    global gen_code_path
    dir_path = gen_code_path + os.sep + 'common'
    if not os.path.exists(dir_path):
        os.makedirs(dir_path)
    return dir_path


def create_schema_dir(module_descriptor):
    global gen_code_path
    dir_path = gen_code_path + os.sep + module_descriptor.id.lower() \
                + os.sep + "schema"
    if not os.path.exists(dir_path):
        os.makedirs(dir_path)
    return dir_path

# Schema files are created from !Type objects which are directly mentioned
# in RestRoutines
def create_schema_files(module_descriptor, descriptor, component):
    body_type_id = None
    type_ids_used = TypeIDsToSchemaFiles()
    if descriptor.method == "POST" or descriptor.method == "PUT":
        body_type_id = descriptor.request.body_type_id
    if descriptor.method == "GET":
        for response in descriptor.responses:
            body_type_id = response.body_type_id
            if body_type_id is not None:
                body_type_id = response.body_type_id
    if body_type_id != 'None' and body_type_id is not None:
        schema_file_descriptor = descriptor.descriptor_factory.descriptors[body_type_id]
        type_ids_used.add_type_descriptor(body_type_id)
        dir_path = create_schema_dir(module_descriptor)
        SchemaFile(schema_file_descriptor, dir_path)
    return

# Mapping that maintains endpoint vs descriptors
def build_endpoint_to_client_object_mapping(descriptor_factory):
    endpoint_mapper = EndpointDescriptorMapping()

    for component in descriptor_factory.components:
        for descriptor in component['descriptors']:
            if isinstance(descriptor, RestRoutineDescriptor):
                if descriptor.method == "POST":
                    endpoint_mapper.add_mapping(descriptor.path, descriptor)

def get_config():
    parser = argparse.ArgumentParser(description='AUTOGENCLIENTSCHEMA')
    parser.add_argument("--resource_descriptor_path")
    parser.add_argument("--resource_settings_path")
    parser.add_argument("--code_path")
    args = parser.parse_args()

    return args

if __name__ == "__main__":
    main()
