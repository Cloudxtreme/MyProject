import importlib

import base_schema
from config_spec_schema import ConfigSpecSchema

class ResourceConfigSchema(base_schema.BaseSchema):
    _schema_name = "resourceConfig"
    def __init__(self, py_dict = None, config_spec_class = None):
        """Constructor"""
        super(ResourceConfigSchema, self).__init__()
        self.set_data_type('xml')
        self.resourceId  = None
        self.configSpec  = None

        # TODO: get_object_from_py_dict() is broken for this case
        if py_dict != None:
            if 'resourceid' in py_dict: self.resourceId = py_dict['resourceid']
            if 'configspec' in py_dict:
                if config_spec_class is not None:
                    self.configSpec = ConfigSpecSchema(py_dict['configspec'],
				                       config_spec_class)
                else:
                    self.get_object_from_py_dict(py_dict)
