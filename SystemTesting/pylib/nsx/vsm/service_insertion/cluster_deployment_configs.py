import vsm_client
import cluster_deployment_configs_schema
import vmware.common.logger as logger
import result

class ClusterDeploymentConfigs(vsm_client.VSMClient):
    def __init__(self, service=None):
        """ Constructor to create ClusterDeploymentConfigs object
        @param vsm object on which ClusterDeploymentConfigs has to be configured
        """
        super(ClusterDeploymentConfigs, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'cluster_deployment_configs_schema.ClusterDeploymentConfigsSchema'
        self.set_connection(service.get_connection())
        self.create_endpoint = 'si/deploy'
        self.delete_endpoint = 'si/deploy/' + 'service/' + str(service.id)
        self.id = None
        self.update_as_post = False

    def delete(self, schema_object=None):
        """ Over riding delete method to perform DELETE operation """
        self.delete_endpoint = self.delete_endpoint + '?clusters=' + str(schema_object)
        self.log.debug("delete_endpoint is %s " % self.delete_endpoint)
        self.log.debug("endpoint id is %s " % self.id)
        self.log.debug("schema_object to delete call is %s "  % schema_object)
        end_point_uri = self.delete_endpoint
        self.response = self.request('DELETE', end_point_uri, "")
        result_obj = result.Result()
        self.set_result(self.response, result_obj)
        return result_obj