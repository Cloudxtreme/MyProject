import vmware.common.logger as logger
import result
import edge_schema
from vsm import VSM
import vsm_client
from edge_schema import EdgeSchema
from nsx_edge_schema import NSXEdgeSchema
from paged_edge_list import PagedEdgeListSchema
import tasks

class DistributedRouterEdge(vsm_client.VSMClient):
    def __init__(self, vsm, version='4.0'):
        """ Constructor to create edge managed object

        @param vsm object on which edge has to be configured
        """
        super(DistributedRouterEdge, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.set_connection(vsm.get_connection())
        # TODO: Is this the right way to change apiHeader if URL
        # base is changing.
        # In case of edge it is api/4.0 and not api/2.0
        self.connection.api_header = '/api/%s' % version
        self.set_create_endpoint("/edges")
        if version == '4.0':
            self.schema_class = 'edge_schema.EdgeSchema'
        else:
            self.schema_class = 'nsx_edge_schema.NSXEdgeSchema'
        self.id = None
        self.location_header = None

    def upgrade(self):
        """ Method to upgrade VSE
        """
        temp_ep = self.create_endpoint
        temp_id = self.id
        temp_header = self.connection.api_header
        self.connection.api_header = '/api/3.0'
        self.create_endpoint = "/edges/" + str(temp_id) + "?action=upgrade"
        schema_object = EdgeSchema()
        result_obj = super(DistributedRouterEdge, self).create(schema_object)
        self.id = temp_id
        self.create_endpoint = temp_ep
        self.connection.api_header = temp_header
        return result_obj

    @tasks.thread_decorate
    def create(self, schema_object):
        self.response = self.request('POST', self.create_endpoint,
                                     schema_object.get_data_without_empty_tags(self.content_type))
        result_obj = result.Result()
        self.set_result(self.response, result_obj)

        response = result_obj.get_response()
        location = response.getheader("Location")
        self.log.debug("Location header is %s" % location)
        self.location_header = location

        if location is not None:
            self.id = location.split('/')[-1]
            result_obj.set_response_data(self.id)
        return result_obj

    def query(self):
        edges = PagedEdgeListSchema()
        edges.set_data(self.base_query(), self.accept_type)
        return edges

    def get_ip(self):
        edge_p = self.read()
        print "type %s %s " % (edge_p.type, edge_p)
        if isinstance(edge_p, NSXEdgeSchema):
            edge_ip = edge_p.vnics[0].addressGroups[0].primaryAddress
        else:
            edge_ip = edge_p.mgmtInterface.addressGroups[0].primaryAddress
        return edge_ip


if __name__ == '__main__':
    import base_client

    var = '''
    <edge>
        <appliances>
            <applianceSize>compact</applianceSize>
            <appliance>
                <resourcePoolId>domain-c427</resourcePoolId>
                <datastoreId>datastore-433</datastoreId>
            </appliance>
        </appliances>
        <datacenterMoid>datacenter-422</datacenterMoid>
        <mgmtInterface>
            <connectedToId>network-438</connectedToId>
        </mgmtInterface>
        <type>distributedrouter</type>
    </edge>
    '''

    vsm_obj = VSM("10.110.27.110", "admin", "default", "")

    py_dict = {
        'datacentermoid': 'datacenter-422',
        'type': 'distributedrouter',
        'appliances': {
            'appliancesize': 'compact',
            'appliance': [
                {
                    'resourcepoolid': 'domain-c427',
                    'datastoreid': 'datastore-433'
                }
            ]
        },
        'mgmtinterface': {
            'connectedtoid': 'dvportgroup-445'
        },
    }

    #Create Distributed Router Edge
    edge_client = DistributedRouterEdge(vsm_obj)
    edge_schema_object = edge_client.get_schema_object(py_dict)
    print edge_schema_object.get_data('xml')
    result_obj_1 = edge_client.create(edge_schema_object)
    print result_obj_1.status_code

    edge_schema = edge_client.read()
    edge_schema.print_object()

    #Delete Distributed Router Edge
    response_status = edge_client.delete()
    print response_status.status_code
