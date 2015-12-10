import importlib

import base_schema

class NetworkFabricResourceStatusSchema(base_schema.BaseSchema):
    _schema_name = "nwFabricFeatureStatus"
    def __init__(self, py_dict = None, config_spec_class = None):
        """Constructor"""
        super(NetworkFabricResourceStatusSchema, self).__init__()
        self.set_data_type('xml')
        self.featureId = None
        self.featureVersion = None
        self.updateAvailable = None
        self.status = None
        self.message = None
        self.installed = None
        self.enabled = None

        if py_dict != None:
            self.get_object_from_py_dict(py_dict)
