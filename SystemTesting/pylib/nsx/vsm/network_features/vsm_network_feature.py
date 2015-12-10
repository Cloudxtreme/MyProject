import vsm_client
from vsm_network_feature_config_schema import NetworkFeatureConfigSchema
from vsm import VSM


class NetworkFeature(vsm_client.VSMClient):
    def __init__(self, vsm, network):
        """ Constructor to create XVS managed object

        @param vsm : vsm object on which this managed object needs to be configured
        """
        super(NetworkFeature, self).__init__()
        self.schema_class = 'vsm_network_feature_config_schema.NetworkFeatureConfigSchema'
        self.set_connection(vsm.get_connection())
        conn = self.get_connection()
        self.set_create_endpoint("xvs/networks/%s/features" % (network))
        self.id = None

if __name__ == '__main__':
    import base_client
    vsm_obj = VSM("10.144.139.81:443", "admin", "default", "")
    network = "dvportgroup-60"
    network = NetworkFeature(vsm_obj, network)
    ip = {'enabled': 'true'}
    mac = {'enabled': 'true'}
    py_dict = {'ipDiscoveryConfig': ip,
               'macLearningConfig': mac}
    base_client.bulk_create(network, [py_dict])

