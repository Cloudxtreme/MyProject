import copy
import base_schema

class BaseCLISchema(base_schema.BaseSchema):

    def __init__(self):
        super(BaseCLISchema, self).__init__()


    def get_object_from_py_dict(self, py_dict):
        """ Method to fill the current schema object with values from a py_dict
            Its behavior is slightly different from parent in the sense that the py_dict
	    elements are not same as the schema class attributes but the py_dict elements
	    are same as the value of the schema class attributes

            @param py_dict   dict object to get values from
        """
        for attribute in self.__dict__:
            if type(attribute) not in [file, dict]:
                if type(getattr(self, attribute)) in [str, int, bool, type(None)]:
                   attribute_value = getattr(self, attribute)
                   if attribute_value in py_dict:
                        pydict_value = py_dict[attribute_value]
                        setattr(self, attribute, pydict_value)
                # if attribute is not in py_dict and is list we need to empty it
                elif type(getattr(self, attribute)) in [list]:
		    if not attribute.startswith("_"):
                        #Parsing array
                        #Using the first item in the array as a prototype
                        new_item = getattr(self, attribute)[0]
                        del getattr(self, attribute)[0]
                        for element in py_dict[attribute]:
                            if type(element) in [int, str, bool]:
                                getattr(self, attribute).append(element)
                            else:
                                new_item1 = copy.deepcopy(new_item)
                                new_item1.get_object_from_py_dict(element)
                                getattr(self, attribute).append(new_item1)

                else:
                    if type(getattr(self, attribute)) in [list]:
                        del getattr(self, attribute)[0]
