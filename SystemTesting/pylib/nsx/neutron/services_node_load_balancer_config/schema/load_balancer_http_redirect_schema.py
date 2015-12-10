import base_schema
import resource_link_schema

class LoadBalancerHttpRedirectSchema(base_schema.BaseSchema):
    _schema_name = "loadbalancerhttpredirect"

    def __init__(self, py_dict=None):
        """ Constructor to create LoadBalancerHttpRedirectSchema object

        @param py_dict : python dictionary to construct this object
        """

        super(LoadBalancerHttpRedirectSchema, self).__init__()
        self._self = resource_link_schema.ResourceLinkSchema()
        self.schema = None
        self.revision = None
        self._links = [resource_link_schema.ResourceLinkSchema()]
        self.redirect_to = None

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)