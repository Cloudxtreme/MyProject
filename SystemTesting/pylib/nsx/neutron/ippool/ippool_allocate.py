import neutron_client
import vmware.common.logger as logger

class IPPoolAllocate(neutron_client.NeutronClient):

    def __init__(self, ippool=None):
        """ Constructor to create IPPool object

        @param neutron object on which IPPool object has to be configured
        """
        super(IPPoolAllocate, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'pool_allocated_resource_schema.PoolAllocatedResourceSchema'
        self.id = None
        if ippool is not None:
            self.set_connection(ippool.get_connection())

        self.set_create_endpoint('/pools/ip-pools/%s?action=allocate' % ippool.id)
        self.set_read_endpoint('/v1/pools/ip-pools/%s/allocations' % ippool.id)
        self.set_delete_endpoint('/pools/ip-pools/%s/allocations' % ippool.id)



if __name__ == '__main__':
    import base_client
    from neutron import Neutron
    from ip_pool_schema import IpPoolSchema
    from ippool import IPPool
    nu = Neutron('10.110.30.9', 'admin', 'default')
    ip_pool_client = IPPool(nu)
    py_dict = {'subnets':
                   [{'static_routes': [{'next_hop': '192.168.10.5', 'destination_cidr': '192.168.10.0/24'}],
                     'allocation_ranges': [{'start': '192.168.1.2', 'end': '192.168.1.6'}, {'start': '192.168.1.10', 'end': '192.168.1.100'}],
                     'dns_nameservers': ['10.10.10.11', '10.10.10.12'],
                     'gateway_ip': '192.168.1.1',
                     'ip_version': 4,
                     'cidr': '192.168.1.0/24'},
                    {'cidr': '192.175.1.0/24'}],
               'display_name': 'TestIPPool-1-2091'}
    json_string = '{"revision":0,"id":"ippool-35977717-0169-4d89-afd9-8d1b7cb81539","display_name":"TestIPPool-1-2091","subnets":[{"static_routes":[{"destination_cidr":"192.168.10.0/24","next_hop":"192.168.10.5"}],"dns_nameservers":["10.10.10.11","10.10.10.12"],"allocation_ranges":[{"start":"192.168.1.10","end":"192.168.1.100"},{"start":"192.168.1.2","end":"192.168.1.6"}],"gateway_ip":"192.168.1.1","ip_version":"4","cidr":"192.168.1.0/24"},{"static_routes":[],"dns_nameservers":[],"allocation_ranges":[],"ip_version":"4","cidr":"192.175.1.0/24"}]}'
    ip_pool = IpPoolSchema(py_dict)
    ip_pool_client.id = 'ippool-c15a8a02-443a-4d38-86dc-3cf3664764cf'
    conf_ip_pool = IpPoolSchema()
    conf_ip_pool.set_data(json_string, ip_pool_client.accept_type)
    print ip_pool.verify(conf_ip_pool)
    #Create IPPool with correct name
    py_dict = {"schema" : "/v1/schema/IpPool",
      "display_name" : "IpPool-1",
      "subnets" : [ {
        "static_routes" : [ {
          "destination_cidr" : "192.175.10.0/24",
          "next_hop" : "192.175.10.5"
        } ],
        "allocation_ranges" : [{
          "start" : "192.175.1.2",
          "end" : "192.175.1.6"}],
        "cidr" : "192.175.1.0/24"
      }]
    }
    result_objs = base_client.bulk_create(ip_pool_client, [py_dict])
    print "Create IPPool Status code: %s" % result_objs[0].status_code
    print "Create result response: %s" % result_objs[0].response_data
    print "IPPool id: %s" % ip_pool_client.id

    ip_pool_allocate = IPPoolAllocate(ip_pool_client)
    py_dict = {'schema': '/v1/schema/PoolAllocatedResource'}
    result_objs = base_client.bulk_create(ip_pool_allocate, [py_dict])
    print "IPPool allocate Status code: %s" % result_objs[0].status_code
    print "Create result response: %s" % result_objs[0].response_data

    ip_pool_allocate.delete()
    print "IPPool allocate Status code: %s" % result_objs[0].status_code
    print "Create result response: %s" % result_objs[0].response_data

    #Delete IPPool
    result_obj = ip_pool_client.delete()
    print "Delete status code: %s" % result_obj.status_code

