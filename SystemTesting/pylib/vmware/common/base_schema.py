import copy
import inspect


class BaseSchema(object):

    def get_object_from_py_dict(self, py_dict):
        """
        Method to fill the current schema object with values from a py_dict
        @param py_dict   dict object to get values from
        @return: a schema object that fill in by py_dict
        """
        for attribute in self.__dict__:
            if attribute.lower() in py_dict:
                if type(getattr(self, attribute)) in [str, int, bool,
                                                      type(None)]:
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
                    getattr(self, attribute).get_object_from_py_dict(
                        py_dict[attribute.lower()])
            else:
                if type(getattr(self, attribute)) in [list]:
                    del getattr(self, attribute)[0]

    def get_py_dict_from_object(self):
        """
        Returns pydict containing object attributes as keys.

        @rtype: dict
        @return: Returns dictionary containing the attributes of the schema
            object as keys and the attribute values as values. If the schema
            object's attribute contains a list of schema objects then those
            schema objects are also converted into a dict.
        """
        ret = {attr: getattr(self, attr) for attr in self.__dict__}
        for key, val in ret.iteritems():
            new_val = None
            if isinstance(val, BaseSchema):
                new_val = val.get_py_dict_from_object()
            elif isinstance(val, list):
                new_val = []
                for elem in val:
                    if isinstance(elem, BaseSchema):
                        new_val.append(elem.get_py_dict_from_object())
                    else:
                        new_val.append(elem)
            elif hasattr(val, '__iter__'):
                raise AssertionError('Unable to convert iterable schema '
                                     'attribute-vals to pydict, was expecting '
                                     'a list, got %r corresponding to schema '
                                     'attribute %r' % (key, val))
            else:
                new_val = val
            ret[key] = new_val
        return ret
