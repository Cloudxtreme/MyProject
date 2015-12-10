import vmware.common.logger as logger
import edge
import result
import connection
import base_client
import vsm_client
import edge_schema
from vsm import VSM
class GlobalDistributedLogicalRouter(edge.Edge):
    def __init__(self, vsm, version='4.0'):
        """ Constructor to create edge managed object

        @param vsm object on which edge has to be configured
        """
        super(GlobalDistributedLogicalRouter, self).__init__(vsm)
        # TODO: Is this the right way to change apiHeader if URL
        # base is changing.
        # In case of edge it is api/4.0 and not api/2.0
        self.connection.api_header = '/api/%s' % version
        self.set_create_endpoint("/edges/?isUniversal=true")
        self.read_endpoint = "/edges/"
        if version == '4.0':
            self.schema_class = 'edge_schema.EdgeSchema'
        else:
            self.schema_class = 'nsx_edge_schema.NSXEdgeSchema'
        self.id = None
        self.location_header = None

    def delete(self, schema_object=None, url_parameters=None):
        """ Overriding base_client method for delete operation
        """
        self.set_delete_endpoint("/edges")
        return super(GlobalDistributedLogicalRouter, self).delete(schema_object)

if __name__ == '__main__':
    pass
