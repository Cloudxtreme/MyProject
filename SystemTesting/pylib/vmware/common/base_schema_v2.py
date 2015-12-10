import vmware.common.global_config as global_config
import vmware.common.utilities as utilities

pylogger = global_config.pylogger


class BaseSchema(object):
    SPECIAL_MARKER = '_'

    @classmethod
    def get_schema_attrs(cls):
        """
        Returns the schema attribues defined in the class, all attributes
        starting with SPECIAL_MARKER are considered to be internal
        @rtype: tuple
        @return: tuple of attributes that are defined for this class
        """
        return (attr for attr in cls.__dict__
                if not attr.startswith(cls.SPECIAL_MARKER))

    @classmethod
    def attr_to_key(cls, attr):
        """
        Returns the corresponding key for the attribute, that will be used as
        key in the py_dict, SPECIAL_MARKER at the end are assumed for collision
        with python keywords like type_ for type and id_ for id
        @rtype: str
        @return: key as str to filled in py_dict
        """
        return attr.lower().rstrip(cls.SPECIAL_MARKER)

    def __init__(self, py_dict=None):
        """
        Constructs a schema object by taking the values in py_dict as input
        @type py_dict: dict
        @param py_dict: dict object to fill up values in schema object
        """
        super(BaseSchema, self).__init__()
        if py_dict is None:
            py_dict = {}
        self.get_object_from_py_dict(py_dict=py_dict)
        cls = self.__class__
        for attr in cls.get_schema_attrs():
            cls_val = getattr(cls, attr)
            if ((type(cls_val) in utilities.LIST_ATTR_TYPES and
                 len(cls_val) != 1)):
                raise RuntimeError("Doesn't support attributes with"
                                   "invalid sample values for %s=%s" %
                                   (attr, cls_val))

    def get_object_from_py_dict(self, py_dict):
        """
        Method to fill the current schema object with values from a py_dict
        @type py_dict:  dict
        @param py_dict: dict object to fill up values in schema object
        @rtype:  subclass of BaseSchema
        @return: schema object thats filled in by py_dict
        """
        cls = self.__class__
        for attr in cls.get_schema_attrs():
            key = cls.attr_to_key(attr)
            cls_val = getattr(cls, attr)
            if key in py_dict and py_dict[key] is not None:
                value = py_dict[key]
                if type(cls_val) in utilities.LIST_ATTR_TYPES:
                    # Using the first item in the array as class
                    if ((len(cls_val) == 1 and
                         type(value) in utilities.LIST_ATTR_TYPES)):
                        item_cls = getattr(cls, attr)[0]
                        lst = []
                        for element in value:
                            if type(element) in utilities.IMMUTABLE_NOT_NONE:
                                lst.append(element)
                            else:
                                lst.append(item_cls(py_dict=element))
                        inst_val = lst
                    else:
                        raise RuntimeError("%s: Invalid value=%s for attr=%s" %
                                           (cls.__name__, value, attr))
                elif (type(cls_val) not in utilities.IMMUTABLE_ATTR_TYPES and
                      issubclass(cls_val, BaseSchema)):
                    inst_val = cls_val(py_dict=value)
                else:
                    inst_val = value
                setattr(self, attr, inst_val)
            else:
                if type(cls_val) in utilities.LIST_ATTR_TYPES:
                    pylogger.warn("Attribute %s not found or is None, "
                                  " Defaulting to []" % attr)
                    setattr(self, attr, [])
                elif (type(cls_val) not in utilities.IMMUTABLE_ATTR_TYPES and
                      issubclass(cls_val, BaseSchema)):
                    pylogger.warn("Attribute %s not found or is None, "
                                  "Defaulting to None" % attr)
                    setattr(self, attr, None)
                else:
                    pylogger.warn("Attribute %s not found or is None, "
                                  "Defaulting to class value" % attr)
        return self

    def get_py_dict_from_object(self):
        """
        Returns pydict containing object schema attributes as keys.

        @rtype: dict
        @return: Returns dictionary containing the attributes of the schema
            object as keys and the attribute values as values. If the schema
            object's attribute contains a list of schema objects then those
            schema objects are also converted into a dict.
        """
        ret = {}
        cls = self.__class__
        for attr in cls.get_schema_attrs():
            inst_val = getattr(self, attr)
            key = cls.attr_to_key(attr)
            if type(inst_val) in utilities.IMMUTABLE_ATTR_TYPES:
                dict_val = inst_val
            elif type(inst_val) in utilities.LIST_ATTR_TYPES:
                lst = []
                for element in inst_val:
                    if type(element) in utilities.IMMUTABLE_ATTR_TYPES:
                        lst.append(element)
                    elif isinstance(element, BaseSchema):
                        lst.append(element.get_py_dict_from_object())
                    elif hasattr(element, "get_py_dict_from_object"):
                        lst.append(element.get_py_dict_from_object())
                    else:
                        lst.append(element)
                dict_val = lst
            elif isinstance(inst_val, BaseSchema):
                dict_val = inst_val.get_py_dict_from_object()
            else:
                dict_val = inst_val
            ret[key] = dict_val
        return ret
