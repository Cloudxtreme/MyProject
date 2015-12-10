import os
from descriptors.rest_routine_descriptor import \
    RestRoutineDescriptor
from descriptors import lg as logger
import re

CLIENT_BASE_MODULE = "neutron_client"
CLIENT_BASE_CLASS = "neutron_client.NeutronClient"
CLIENT_BASE_CONN_OBJECT = "neutron"
BASE_SCHEMA_MODULE = "base_schema"
BASE_SCHEMA_CLASS = "base_schema.BaseSchema"


class ClientFile():
    def __init__(self, module_descriptor, rest_routine_descriptor, base_dir):
        """
        Class to create client file
        @param module_descriptor: descriptor from yaml file that represents module
        @param rest_routine_descriptor: descriptor from yaml file that represents rest routine
        @param base_dir: directory path that will be used to create client file
        @return:
        """
        self.module_descriptor = module_descriptor
        self.rest_routine_descriptor = rest_routine_descriptor
        self.base_dir = base_dir
        self.fd = None
        self.module_name = None
        self.referenced_classes = []
        logger.debug("Creating client file for %s" % module_descriptor.id)
        self.create_file()
        self.create_file_data()

    def add_imports(self):
        """
        Fn to add import statements in client file
        @return: code segment that has import statements
        """
        code = "import logger\n"
        code += "import " + CLIENT_BASE_MODULE + "\n"
        code += "import " + CLIENT_BASE_CONN_OBJECT + "\n"
        code += "\n\n"
        return code

    def get_module_name(self, descriptor):
        """
        Module name is extracted from the id of rest routing descriptor e.g. CreateLogicalSwitch
        The same is required for preparing list of objects required in clients __init__
        e.g. def __init__(self, logicalswitch=None):
        @param descriptor: whose id is returned
        @return:
        """
        module_name = descriptor.id
        module_name = re.sub("Create", "", module_name)
        return module_name

    def get_init_class(self):
        """
        Creates list of classes required in init statement e.g. def __init__(self, logicalswitch=None):
        This list is prepared from endpoint path
        @return:
        """
        if self.rest_routine_descriptor.path.find('<') == -1:
            self.referenced_classes.append(CLIENT_BASE_CONN_OBJECT)
        else:
            endpoint_mapper = EndpointDescriptorMapping()
            init_class_list = []
            search_path = path = self.rest_routine_descriptor.path
            end = len(path)
            init_class_list_index = 1
            search_path_index = 0
            while path.find('<') != -1:
                index = path.find('<', 0, end)
                search_path_index += index
                path_to_search = search_path[0:search_path_index - 1]  # -1 => to skip '/'
                descriptor = endpoint_mapper.get_descriptor(path_to_search)
                if descriptor is not None:
                    init_class_list.append(self.get_module_name(descriptor))
                else:
                    init_class_list.append("param_%s" % init_class_list_index)
                    logger.warning("Check create_endpoint for %s" % self.rest_routine_descriptor.id)
                path = path[index+1:len(path)]
                init_class_list_index += 1
            self.referenced_classes = init_class_list

    def get_schema_class_name(self, descriptor):
        """
        Generates schema class name required in
        "self.schema_class = 'logicalswitchport_schema.LogicalSwitchPortSchema'"
        @param descriptor: rest routine descriptor to extract object id
        @return: code fragment for client file that has above line
        """
        if descriptor.method == 'POST' or descriptor.method == 'PUT':
            return descriptor.request.body_type_id
        elif descriptor.method == 'GET':
            for response in descriptor.responses:
                if response.body_type_id is not None:
                    return response.body_type_id
        return None

    def add_class_contents(self):
        """
        Puts in following statements in client file
        "class IPSet(neutron_client.NeutronClient):
           def __init__(self, neutron=None):
           super(IPSet, self).__init__()
           self.log = logger.setup_logging(self.__class__.__name__)
           if neutron is not None:
               self.set_connection(neutron.get_connection())
           self.id = None
           self.schema_class = 'ipset_schema.IPSetSchema'"
        @return: code fragment for client file that has above line
        """
        self.get_init_class()
        init_classes = ""
        for c in self.referenced_classes:
            init_classes += c.lower() + "=None, "
        init_classes = init_classes[0:len(init_classes)-2]

        schema_class_name = self.get_schema_class_name(self.rest_routine_descriptor)

        code = "\n\nclass " + self.module_name + "(" + CLIENT_BASE_CLASS + "):\n"
        code += "\n    def __init__(self, " + init_classes + "):\n"
        code += "        super(" + self.module_name + ", self).__init__()\n"
        code += "        self.log = logger.setup_logging(self.__class__.__name__)\n"
        code += "        if " + CLIENT_BASE_CONN_OBJECT + " is not None:\n"
        code += "            self.set_connection(" + self.referenced_classes[0].lower() + ".get_connection())\n"
        code += "        self.id = None\n"
        if schema_class_name is not None and schema_class_name != 'None':
            code += "        self.schema_class = '" + schema_class_name.lower() + "_schema." \
                + schema_class_name + "Schema'\n"
        return code

    def generate_create_endpoint(self, descriptor):
        """
        Creates endpoint url including ids of parameters passed in __init__
        e.g. self.set_create_endpoint("/lswitches/" + logicalswitch.id + "/ports")
        @param descriptor:
        @return: endpoint url
        """
        search_path = path = descriptor.path
        start = 0
        end = len(path)
        endpoint = '"'
        ref_classes_index = 0
        while path.find('<') != -1:
            index = path.find('<', start, end)
            endpoint += path[start:index] + '"'
            endpoint += " + " + self.referenced_classes[ref_classes_index].lower() + ".id + " + '"'
            path = path[index+1:len(path)]
            index = path.find('>')
            path = path[index+1:len(path)]
            ref_classes_index += 1
        else:
            endpoint += path + '"'
        return endpoint

    def add_endpoints_in_client_class(self):
        """
        Puts in following statement in client file
        "self.set_create_endpoint('/groupings/ipsets')"
        @return: code fragment for client file that has above line
        """
        create_endpoint = self.generate_create_endpoint(self.rest_routine_descriptor)
        code = "        self.set_create_endpoint(" + create_endpoint + ")\n"
        if self.rest_routine_descriptor.path.find('<') != -1:
            logger.warning("Check create_endpoint path for %s" % self.rest_routine_descriptor.id)
        return code

    def create_file(self):
        """
        Creates client file
        """
        module_name = self.get_module_name(self.rest_routine_descriptor)
        file_path = self.base_dir + os.sep + module_name.lower() + '.py'
        self.module_name = module_name
        self.fd = open(file_path, 'w')

    def create_file_data(self):
        """
        Fn to collate all client file contents
        """
        code = self.add_imports()
        code += self.add_class_contents()
        code += self.add_endpoints_in_client_class()
        self.fd.write(code)
        self.fd.close()


class SchemaFile():
    def __init__(self, schema_file_descriptor, base_dir):
        """
        Class that creates schema file with its content
        @param schema_file_descriptor:
        @param base_dir:
        @return:
        """
        self.schema_file_descriptor = schema_file_descriptor
        self.base_dir = base_dir
        self.fd = None
        self.imports = ""
        logger.debug("Creating schema file for %s" % schema_file_descriptor.id)
        self.create_file()
        self.create_file_data()

    def create_file(self):
        """
        Creates schema file
        @return:
        """
        file_path = self.base_dir + os.sep + self.schema_file_descriptor.id.lower() \
                    + '_schema.py'
        self.fd = open(file_path, 'w')

    def add_imports(self):
        """
        Adds import statements to schema files
        @return: code fragment
        """
        code = "import " + BASE_SCHEMA_MODULE + "\n"
        if hasattr(self.schema_file_descriptor.meta_spec, "extends"):
            base_class = self.schema_file_descriptor.meta_spec.extends['$ref']
            code = "from " + base_class.lower() + "_schema import " + base_class + "\n"
        code += self.imports
        return code

    def add_class_contents(self):
        """
        Fn to put in below statements in schema class
        #class IPSetSchema(base_schema.BaseSchema):
        #    _schema_name = "ipset"
        #    def __init__(self, py_dict=None):
        #    super(IPSetSchema, self).__init__()
        @return: code fragment
        """
        code = "class " + self.schema_file_descriptor.id + \
               "Schema(" + BASE_SCHEMA_CLASS + "):\n"
        code += "    _schema_name = " + '"' + self.schema_file_descriptor.id.lower() + '"\n'
        code += "    def __init__(self, py_dict=None):\n"
        code += "        super(" + self.schema_file_descriptor.id + "Schema, self).__init__()\n"
        return code

    def add_object_attributes(self, descriptor):
        """

        @param descriptor:
        @return: code fragment
        """
        code = ""
        if 'properties' in descriptor.meta_spec:
            for key, value in descriptor.meta_spec['properties'].iteritems():
                if "type" in value:
                    if value['type'] != 'array':
                        code += "        self." + key + " = None\n"
                    elif value['type'] == 'array':
                        # Need to take referenced descriptors id since it is in CamelCase
                        if 'items' in value:
                            if '$ref' in value['items']:
                                referenced_descriptor = descriptor.descriptor_factory.descriptors[
                                    value['items']['$ref']]
                                code += "        self." + key + " = [" + referenced_descriptor.id + "Schema()]\n"
                                self.imports += "from " + referenced_descriptor.id.lower() + "_schema import " \
                                                + referenced_descriptor.id + "Schema\n"
                                # We want to generate this schema file in common dir if it is not
                                # already generated
                                if 'type' in referenced_descriptor.meta_spec:
                                    if referenced_descriptor.meta_spec['type'] == 'object':
                                        if not hasattr(referenced_descriptor, 'generated_schema'):
                                            referenced_descriptor.generated_schema = False
        return code

    def add_attributes(self, descriptor):
        """
        Fn to add attributes for this schema
        Recursively calls all descriptors from which this type is extended
        @param descriptor:
        @return: code fragment
        """
        code = ""
        logger.debug("Adding attributes of Type descriptor: %s" % descriptor.id)
        code += self.add_object_attributes(descriptor)
        if "extends" in descriptor.meta_spec:
            extended_object = descriptor.meta_spec['extends']['$ref']
            # If referenced object is present in the list of descriptors
            if extended_object in descriptor.descriptor_factory.descriptors:
                extended_object = descriptor.descriptor_factory.descriptors[extended_object]
                code += self.add_attributes(extended_object)
        return code

    def add_trailor(self):
        code = "\n        if py_dict is not None:\n"
        code += "            self.get_object_from_py_dict(py_dict)\n"
        return code

    def create_file_data(self):
        """
        fn collate all schema file contents
        @return: code fragment
        """
        code = self.add_class_contents()
        code += self.add_attributes(self.schema_file_descriptor)
        self.schema_file_descriptor.generated_schema = True
        code = self.add_imports() + code
        code += self.add_trailor()
        self.fd.write(code)
        self.fd.close()


def singleton(cls):
    """
    Singleton decorator
    @param cls:
    """
    instances = {}

    def get_instance():
        if cls not in instances:
            instances[cls] = cls()
        return instances[cls]

    return get_instance


@singleton
class EndpointDescriptorMapping():
    def __init__(self):
        """
        Class that maintains list of endpoint url and descriptor mapping
        @return:
        """
        self.list_of_mappings = []

    def add_mapping(self, path, descriptor):
        """
        Adds mapping of url path and descriptor
        @param path: endpoint url
        @param descriptor
        """
        self.list_of_mappings.append({path: descriptor})

    def get_descriptor(self, path):
        """
        Gets descriptor matching the passed endpoint
        @param path: endpoint url
        @return:
        """
        for i in self.list_of_mappings:
            for k, v in i.iteritems():
                if k == path:
                    return v
        return None

    def check_for_used_endpoint(self, path):
        """
        Checks if endpoint is already covered
        @param path: endpoint to be searched
        @return: true in case if endpoint is not present in any of the stored descriptors
        """
        for i in self.list_of_mappings:
            for k, v in i.iteritems():
                if path.find(k) != -1:
                    search_path = path[len(k):len(path)]
                    no_of_occurances = re.findall("/", search_path)
                    if len(no_of_occurances) > 1:
                        continue
                    return False
        return True

@singleton
class TypeIDsToSchemaFiles():
    def __init__(self):
        """
        Keeps mapping of !Type ids that are already covered to create schema files
        @return:
        """
        self.list_of_descriptors = []

    def add_type_descriptor(self, body_type_id):
        """
        Adds the !Type ID to the list
        @param body_type_id:
        @return:
        """
        self.list_of_descriptors.append(body_type_id)

    def check(self, body_type_id):
        """
        Checks whether the passed id is already covered
        @param body_type_id:
        @return:
        """
        for i in self.list_of_descriptors:
            if i == body_type_id:
                return True
        return False