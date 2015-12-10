import copy
import inspect
import types
import json_parser
import xml_parser
import vmware.common.global_config as global_config

class BaseSchema(object):
    """ Base class to marshal/unmarsharl python objects into/from json/xml"""

    #Hashmap of data-parsers
    _data_parsers = {'application/json': json_parser.JsonParser,
                   'application/xml': xml_parser.XmlParser,
                   'json': json_parser.JsonParser,
                   'xml': xml_parser.XmlParser}

    def __init__(self, dataType="json"):
        self._data_type = dataType
        self._attribute_metadata = {}
        self._ignore_list = []
        self._is_abstract = False

    def validator_value_replacer(self, test_type, field_type):
        pass

    def validator_payload_engine(self, test_type):
        pass

    def get_default_value_payloads(self):
        fields = inspect.getmembers(self)
        default_payloads = []
        for field in fields:
            if not callable(field[1]) and not field[0].startswith('_'):
                meta_field = getattr(self, '_' + str(field[0]) + '_meta')
                print meta_field
                if meta_field['type'] == 'object':
                    recursive_default_payloads = \
                        getattr(self,field[0]).get_default_value_payloads()
                    for recursive_default_payload in recursive_default_payloads:
                        default_field_object = self.get_clone()
                        setattr(default_field_object,
                                field[0],
                                recursive_default_payload['object'])
                        temp_field = field[0] + ';' + \
                                            recursive_default_payload['field']
                        default_payload = {'object':default_field_object,
                                           'field':temp_field}
                        default_payloads.append(default_payload)
                elif meta_field['type'] == 'array':
                    recursive_default_payloads = \
                        getattr(self,field[0])[0].get_default_value_payloads()
                    for recursive_default_payload in recursive_default_payloads:
                        default_field_object = self.get_clone()
                        getattr(default_field_object, field[0]).\
                                append(recursive_default_payload['object'])
                        print default_field_object.get_data()
                        temp_field = field[0] + ';' + \
                                        recursive_default_payload['field']
                        default_payload = {'object':default_field_object,
                                                        'field':temp_field}
                        default_payloads.append(default_payload)
                else:
                    if 'default' in meta_field:
                        print 'has default value'
                        default_field_object = self.get_clone()
                        setattr(default_field_object, field[0], None)
                        default_payload = {'object':default_field_object,
                                                        'field':field[0]}
                        default_payloads.append(default_payload)
        return default_payloads

    def get_required_value_payloads(self):
        pass

    def get_type_value_paylaods(self):
        pass

    def get_length_payloads(self):
        pass

    def get_clone(self):
        return copy.deepcopy(self)

    def set_data_type(self, data_type):
        """ To set data type as one of json [neutron, NVP] or xml [VSM]

        @param data_type It can be set as xml or json
        """
        self._data_type = data_type

    def get_data_type(self):
        return self._data_type

    def set_data(self, payload, data_type):
        """ To set python object attributes from xml/json string

        @param payload String containing xml/json representation of python objects
        """
        if "raw" in data_type:
            self.set_data_raw(payload)
        else:
            data_parser = self._data_parsers[data_type]()
            data_parser.set_data(self, payload)

    def get_data(self, data_type):
        """ To get xml/json string from python objects
        """
        data_parser = self._data_parsers[data_type]()
        return data_parser.get_data(self)

    def get_data_without_empty_tags(self, data_type):
        """ To get xml string with no empty tags from python objects
        """
        data_parser = self._data_parsers[data_type]()
        return data_parser.get_data_without_empty_tags(self)

    def get_py_dict_from_object(self):
        """ Method to get a py_dict with values from current schema object

        """

        py_dict = {}
        for attribute in self.__dict__:
            # Skipping py_dict elements that are not related to object
            # attributes, do not skip _tag_ attributes needed for distributed firewall
            if type(getattr(self,attribute)) in [file, dict] or \
                attribute.startswith('_') and not attribute.startswith('_tag_'):
                continue
            # Populating leaf attibutes of the py dict with object attributes
            if type(getattr(self, attribute)) in [str, int, bool, type(None)]:
                py_dict[str(attribute)] = str(getattr(self, attribute))
            # Poplulating a list inside a py dict with array of objects
            elif type(getattr(self, attribute)) in [list]:
                val_list = []

                for element in getattr(self, attribute):
                    if type(element) in [int, str, bool]:
                        val_list.append(element)
                    else:
                        val_list.append(element.get_py_dict_from_object())
                py_dict[str(attribute)] = val_list
            # Adding a py dict as an attribute to a py dict
            else:
                 py_dict[str(attribute)] = getattr(self, attribute).get_py_dict_from_object()

        return py_dict


    def get_object_from_py_dict(self, py_dict):
        """ Method to fill the current schema object with values from a py_dict

            @param py_dict   dict object to get values from
        """

        for attribute in self.__dict__:
            if type(attribute) not in [file, dict]:
                if attribute.lower() in py_dict:
                    if type(getattr(self, attribute)) in [str, int, bool, type(None)]:
                        value = py_dict[attribute.lower()]
                        setattr(self, attribute, value)
                    elif type(getattr(self, attribute)) in [list]:
                        #Parsing array
                        #Using the first item in the array as a prototype
                        new_item = getattr(self, attribute)[0]
                        del getattr(self, attribute)[0]
                        for element in py_dict[attribute.lower()]:
                            if type(element) in [int, str, bool]:
                                getattr(self, attribute).append(element)
                            else:
                                new_item1 = copy.deepcopy(new_item)
                                new_item1.get_object_from_py_dict(element)
                                getattr(self, attribute).append(new_item1)
                    else:
                        #If we are here we have a nested object
                        getattr(self, attribute).get_object_from_py_dict(py_dict[attribute.lower()])
                # if attribute is not in py_dict and is list we need to empty it
                else:
                    self._ignore_list.append(attribute)
                    if type(getattr(self, attribute)) in [list]:
                        del getattr(self, attribute)[0]

    def factory(self, payload=""):
        """ Method to get a new object of the type of involing class or of a derived class

            @param payload  data to populate new object with
        """

        new_item = {}

        if payload == "":
            new_item = copy.deepcopy(self)
        else:
            if type(payload) == type({}):
                if self._is_abstract == False:
                    self.get_object_from_py_dict(payload)
                    new_item = copy.deepcopy(self)
                else:
                    new_item = self.abstract_factory(payload)

        return new_item

    def abstract_factory(self, payload):
        pass

    def verify(self, configured_object):
        """ Call this routine using schema object that is populated
        through py_dict and pass schema object that is populated
        through READ REST api

        @param configured_object  schema object of same type
            populated through READ REST api
        """
        result = True
        for attribute in self.__dict__:
            if attribute[0] != "_" and type(attribute) not in [file, dict] and \
                    type(getattr(self, attribute)) is not types.NoneType:
                if type(getattr(self, attribute)) in [bool, int, str, unicode]:
                    if unicode(getattr(self, attribute)) != unicode(getattr(configured_object, attribute)):
                        return False
                elif type(getattr(self, attribute)) in [list]:
                    # If length of list is not equal verification fails
                    if len(getattr(self, attribute)) != len(getattr(configured_object, attribute)):
                        return False
                    for i in range(len(getattr(self, attribute))):
                        element = getattr(self, attribute)[i]
                        if type(element) in [int, str, bool, unicode]:
                            if element != getattr(configured_object, attribute)[i]:
                                return False
                        else:
                            # Find whether each element in the list is present in configured_object
                            for j in range(len(getattr(configured_object, attribute))):
                                result = element.verify(getattr(configured_object, attribute)[j])
                                if result:
                                    break
                            if not result:
                                return False
                else:
                    result = getattr(self, attribute).verify(getattr(configured_object, attribute))
                    if not result:
                        return result
        return result

    def print_object(self, format_string=""):
        """ Method to print object
        """
        log = global_config.pylogger
        if hasattr(self, '_schema_name'):
            log.debug("%s%s:" % (format_string, self._schema_name))
        format_string += "\t"
        for attribute in self.__dict__:
            if attribute[0] != "_" and self.__dict__[attribute] is not None:
                if type(self.__dict__[attribute]) in [bool, int, str, unicode]:
                    log.debug("%s%s: %s" % (format_string, attribute, self.__dict__[attribute]))
                else:
                    if type(self.__dict__[attribute]) in [list]:
                        for element in self.__dict__[attribute]:
                            if element is not None:
                                if type(element) in [str, bool, int, unicode]:
                                    log.debug("%s%s: %s" % (format_string, attribute, element))
                                else:
                                    element.print_object(format_string)
                    else:
                        if type(self.__dict__[attribute]) not in [file, dict]:
                            element = self.__dict__[attribute]
                            element.print_object(format_string)

if __name__ == '__main__':
    pass
