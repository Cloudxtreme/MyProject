import base_schema


class LoadBalancerPersistentCacheSchema(base_schema.BaseSchema):
    _schema_name = "persistentCache"
    def __init__(self, py_dict=None):
        """ Constructor to create
        LoadBalancerPersistentCacheSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(LoadBalancerPersistentCacheSchema, self).__init__()
        self.set_data_type('xml')
        self.maxSize = None
        self.ttl = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)