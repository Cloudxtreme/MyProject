import importlib

import base_schema
from network_fabric_resource_status_schema import NetworkFabricResourceStatusSchema

class ResourceStatusesSchema(base_schema.BaseSchema):
    _schema_name = "resourceStatuses"
    def __init__(self, py_dict = None, config_spec_class = None):
        """Constructor"""
        super(ResourceStatusesSchema, self).__init__()
        self.set_data_type('xml')
        self.resourceStatus  = [NetworkFabricResourceStatusSchema()]

        if py_dict != None:
            self.get_object_from_py_dict(py_dict)
