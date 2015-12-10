import copy
import json
import inspect


class JsonParser(object):

    def __init__(self):
        pass

    def set_data(self, schema_object, payload):
        """Populates python objects with provided json string"""
        fields = dir(schema_object)
        attributes = []
        for field in fields:
            isVar = True
            if callable(getattr(schema_object, field)):
                isVar = False
            if field == '__doc__':
                isVar = False
            if field == '__module__':
                isVar = False
            if isVar == True:
                attributes.append(field)
        json_data = json.loads(payload)
        for attribute in attributes:
            members = inspect.getmembers(schema_object)
            for member in members:
                if attribute[0:1] == "_":
                    continue
                if attribute == str(member[0]):
                    try:
                        a = json_data[attribute]
                    except Exception, e:
                        if type(member[1]) is list and len(member[1]):
                            del member[1][0]
                        continue
                    at_array = [str, int, unicode, bool]
                    if type(member[1]) is list:
                        #parsing list of items
                        json_list = json_data[attribute]
                        if len(member[1]) > 0:
                            python_list = []
                            for json_object in json_list:
                                python_object = copy.deepcopy(member[1][0])
                                if type(json_object) in at_array:
                                    python_object = json_object
                                    python_list.append(python_object)
                                else:
                                    if hasattr(python_object, "set_data"):
                                        self.set_data(python_object, json.dumps(json_object))
                                        python_list.append(python_object)
                            setattr(schema_object, attribute, python_list)
                    else:
                        if member[1] is None:
                            setattr(schema_object, attribute, json_data[attribute])
                            continue
                        if type(member[1]) in at_array:
                            setattr(schema_object, attribute, json_data[attribute])
                        else:
                            #parsing nested object recursively
                            python_object = member[1]
                            self.set_data(python_object, json.dumps(json_data[attribute]))
                            setattr(schema_object, attribute, python_object)

    def get_data(self, schema_object):
        """Generates json string from python objects"""
        payload = '{'
        variables = vars(schema_object)
        fields = dir(schema_object)
        attributes = []
        for field in fields:
            isVar = True
            if callable(getattr(schema_object, field)):
                isVar = False
                if field == '__doc__':
                    isVar = False
                if field == '__module__':
                    isVar = False
                if isVar == True:
                    attributes.append(field)
        at_list = [str, unicode]
        at_list1 = [int, bool]
        for var in variables:
            if var[0:1] == "_":
                continue
            attribute = getattr(schema_object, var)

            if attribute is None:
                continue

            if type(attribute) is list:
                #parsing list of items
                json_list = ""
                python_list = attribute
                is_first = 0
                for python_object in python_list:
                    element = ""
                    if type(python_object) in at_list1:
                        element = str(python_object)
                    elif type(python_object) in at_list:
                        element = '"' + python_object + '"'
                    else:
                        element = self.get_data(python_object)
                    json_list = json_list + element + ","
                if len(json_list) > 0:
                    if json_list[len(json_list) - 1] == ',':
                        json_list = json_list[0:len(json_list) - 1]
                    payload = payload + '"' + var + '":[' + json_list + '],'
            else:
                if type(attribute) in at_list:
                    payload = payload + '"' + var + '":"' + str(attribute) + '",'
                else:
                    if type(attribute) in at_list1:
                        value = ""
                        if type(attribute) in [bool]:
                            if attribute is False:
                                attribute = "false"
                            if attribute:
                                attribute = "true"
                        payload = payload + '"' + var + '":' + str(attribute) + ','
                    else:
                        #parsing nested object recursively
                        python_object = attribute
                        json_object = self.get_data(python_object)
                        if var not in schema_object._ignore_list:
                            payload = payload + '"' + var + '":' + json_object + ','
        if payload[len(payload) - 1] == ',':
            payload = payload[0:len(payload) - 1]
        payload += '}'

        #If there are no members inside payload, return empty payload
        if payload == "{}":
            payload = ""
        return json.loads(json.dumps(payload))

    def get_data_without_empty_tags(self, schema_object):
        raise NotImplementedError