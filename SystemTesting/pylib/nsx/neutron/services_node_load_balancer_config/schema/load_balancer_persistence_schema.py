import base_schema
import resource_link_schema

class LoadBalancerPersistenceSchema(base_schema.BaseSchema):
    _schema_name = "loadbalancerpersistence"

    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerPersistenceSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(LoadBalancerPersistenceSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.cookie_mode = None
        self.cookie_name = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.schema = None
        self.method = None
        self.revision = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)