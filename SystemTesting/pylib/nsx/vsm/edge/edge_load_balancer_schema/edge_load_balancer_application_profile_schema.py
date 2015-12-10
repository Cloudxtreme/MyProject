import base_schema
from edge_load_balancer_persistence_schema import LoadBalancerPersistenceSchema
from edge_load_balancer_http_redirect_schema import LoadBalancerHttpRedirectSchema
from edge_load_balancer_clientssl_schema import LoadBalancerClientSslSchema
from edge_load_balancer_serverssl_schema import LoadBalancerServerSslSchema


class LoadBalancerApplicationProfileSchema(base_schema.BaseSchema):
    _schema_name = "applicationProfile"
    def __init__(self, py_dict=None):
        """ Constructor to create
        LoadBalancerApplicationProfileSchema object

        @param py_dict : python dictionary to construct this object
        """
        super(LoadBalancerApplicationProfileSchema, self).__init__()
        self.set_data_type('xml')
        self.applicationProfileId = None
        self.name = None
        self.insertXForwardedFor = None
        self.sslPassthrough = None
        self.persistence = LoadBalancerPersistenceSchema()
        self.httpRedirect = LoadBalancerHttpRedirectSchema()
        self.clientSsl = LoadBalancerClientSslSchema()
        self.serverSsl = LoadBalancerServerSslSchema()

        if py_dict is not None:
            self.get_object_from_py_dict(py_dict)