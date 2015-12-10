import base_schema
import resource_link_schema

class LoadBalancerGlobalIpPersistenceSchema(base_schema.BaseSchema):
    _schema_name = "loadbalancerglobalippersistence"

    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerGlobalIpPersistenceSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(LoadBalancerGlobalIpPersistenceSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.enabled = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.ttl = None
        self.revision = None
        self.schema = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)