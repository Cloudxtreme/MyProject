import importlib
import inspect

import base_schema

class ConfigSpecSchema(base_schema.BaseSchema):
    _schema_name = "configSpec"
    def __init__(self, py_dict = None, childClass = None):
       super(ConfigSpecSchema, self).__init__()
       self._attributeName = 'class'
       if childClass == 'VDSContext':
          self._attributeName = 'class'
          self._attributeValue = "vdsContext"
          somemodule = importlib.import_module('vds_context_schema')

       elif childClass == 'ClusterMappingSpec':
          self._attributeValue = "clusterMappingSpec"
          somemodule = importlib.import_module('cluster_mapping_spec_schema')

       className = childClass + 'Schema'
       classType = getattr(somemodule, className)
       childObj = classType(py_dict)
       fields = inspect.getmembers(childObj)
       for field in fields:
          if not callable(field[1]) and not field[0].startswith('_'):
             setattr(self, field[0], getattr(childObj, field[0]))


