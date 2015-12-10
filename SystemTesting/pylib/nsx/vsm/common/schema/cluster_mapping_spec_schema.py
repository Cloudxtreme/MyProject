import base_schema
from switch_schema import SwitchSchema

class ClusterMappingSpecSchema(base_schema.BaseSchema):
    _schema_name = "clusterMappingSpec"
    def __init__(self, py_dict = None):
        """Constructor"""
        super(ClusterMappingSpecSchema, self).__init__()
        self._attributeName = 'class'
        self._attributeValue = "clusterMappingSpec"
        self.set_data_type('xml')
        self.switch = SwitchSchema()
        self.vlanId  = None
        self.vmknicCount  = None
        self.ipPoolId  = None

        if py_dict != None:
           self.get_object_from_py_dict(py_dict)

