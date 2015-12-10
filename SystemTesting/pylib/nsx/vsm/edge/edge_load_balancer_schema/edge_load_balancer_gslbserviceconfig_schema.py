import base_schema
from edge_load_balancer_persistentcache_schema import LoadBalancerPersistentCacheSchema


class LoadBalancergslbServiceConfigSchema(base_schema.BaseSchema):
    _schema_name = "gslbServiceConfig"
    def __init__(self, py_dict=None):
        """ Constructor to create
        LoadBalancergslbServiceConfigSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(LoadBalancergslbServiceConfigSchema, self).__init__()
        self.set_data_type('xml')
        self.serviceTimeout = None
        self.queryPort = None
        self.persistentCache = LoadBalancerPersistentCacheSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)