import base_schema
from resource_config_schema import ResourceConfigSchema

class NwFabricFeatureConfigSchema(base_schema.BaseSchema):
    _schema_name = "nwFabricFeatureConfig"
    def __init__(self, py_dict = None):
        """Constructor"""
        super(NwFabricFeatureConfigSchema, self).__init__()
        self.featureId = None
        self.resourceConfig = []
        # TODO: get_object_from_py_dict() is broken for this case
        # (factory class)
        #if py_dict != None:
        #    self.get_object_from_py_dict(py_dict)
        if py_dict != None:
           if 'featureid' in py_dict: self.featureId = py_dict['featureid']
           if 'resourceconfig' in py_dict:
              for config in py_dict['resourceconfig']:
                 if 'configspecclass' in config:
                      self.resourceConfig.append(ResourceConfigSchema(config,
                                                                 config['configspecclass']))
                 else:
                      self.resourceConfig.append(ResourceConfigSchema(config))


if __name__=='__main__':
   switch = {'objectId': 'switch-1'}
   py_dict = {'featureid': 'com.vmware.vshield.vsm.vxlan',
             'resourceconfig': [{'resourceId': 'vds-7', 'configspec': {'switch'
             : {'objectid': 'switch-1'}, 'mtu' : '1600'}, 'configspecclass' : "VDSContext"}, \
             {'resourceid' : 'cluster-1', 'configspec' : {'switch' : switch, 'vlanid' : '100',
             'vmkniccount' : '1'}, 'configspecclass' : 'ClusterMappingSpec'}]}
   testObj = NwFabricFeatureConfigSchema(py_dict)
   print "xml %s" % testObj.getData_xml()
