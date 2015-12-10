import base_schema
from vsm_mac_learning_config_schema import MACLearningConfigSchema
from vsm_ip_discovery_config_schema import IPDiscoveryConfigSchema

class NetworkFeatureConfigSchema(base_schema.BaseSchema):
    _schema_name = "networkFeatureConfig"
    def __init__(self, py_dict=None):
        """ Constructor to create NetworkFeatureConfig object

        @param py_dict : python dictionary to construct this object
        """
        super(NetworkFeatureConfigSchema, self).__init__()
        self.set_data_type('xml')
        self.ipDiscoveryConfig = IPDiscoveryConfigSchema()
        self.macLearningConfig = MACLearningConfigSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)
            if 'ipDiscoveryConfig' in py_dict:
               self.ipDiscoveryConfig = IPDiscoveryConfigSchema(py_dict['ipDiscoveryConfig'])
            if 'macLearningConfig' in py_dict:
                self.macLearningConfig = MACLearningConfigSchema(py_dict['macLearningConfig'])

