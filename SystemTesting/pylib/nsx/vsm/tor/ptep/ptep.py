import vsm_client
import importlib
import result
from ptep_cluster_schema import PTEPClusterSchema
from vsm import VSM

class PTEP(vsm_client.VSMClient):
    """ Class to create Physical Tunnel End Point"""

    def __init__(self, vsm_obj):
        """ Constructor to create Physical Tunnel End Point managed object

        @param vsm_obj vsm object using which Physical Tunnel End Point will be created
        """
        super(PTEP, self).__init__()
        self.schema_class = 'ptep_cluster_schema.PTEPClusterSchema'
        self.set_connection(vsm_obj.get_connection())
        self.connection.api_header = 'api/2.0'
        self.set_create_endpoint("vdn/hardwaregateways/replicationcluster")
        self.set_read_endpoint("vdn/hardwaregateways/replicationcluster")
        self.create_as_put = True
        self.id = None

    def read(self,type = "xml"):
        tor = PTEPClusterSchema()
        self.set_query_endpoint(self.read_endpoint)
        data = self.base_query()
        tor.set_data(data,type)
        return tor

    def get_ptep_cluster(self):
        ptep_cluster = PTEPClusterSchema()
        ptep_cluster.set_data(self.base_query(), self.accept_type)
        self.log.debug("ptep_cluster from GET:")
        ptep_cluster.print_object()
        return ptep_cluster.hosts

if __name__ == '__main__':
    pass
