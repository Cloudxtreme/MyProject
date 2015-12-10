import vsm_client
from vsm import VSM


class IPAMAddressPool(vsm_client.VSMClient):
    def __init__(self, vsm):
        """ Constructor to create IPAMAddressPool managed object

        @param vsm object on which IPAM address pool has to be configured
        """
        super(IPAMAddressPool, self).__init__()
        self.schema_class = 'ipam_address_pool_schema.IPAMAddressPoolSchema'
        self.set_connection(vsm.get_connection())
        self.set_create_endpoint("/services/ipam/pools/scope/globalroot-0")
        self.set_read_endpoint("/services/ipam/pools")
        self.set_delete_endpoint("/services/ipam/pools")
        self.id = None

    def delete(self, schema_object=None, url_parameters=None):
        """When delete ippool, the scheam_obj should be set None."""
        self.log.debug("schema_object to delete call is %s,"
                       " url_parameters is %s" % (schema_object,
                                                  url_parameters))
        schema_object = None
        return super(IPAMAddressPool, self).delete(schema_object,
                                                   url_parameters)

if __name__ == '__main__':
    import base_client
    var = """
    <ipamAddressPool>
      <name>rest-ip-pool-1</name>
      <gateway>192.168.1.1</gateway>
      <prefixLength>23</prefixLength>
      <ipRanges>
         <ipRangeDto>
            <startAddress>192.168.1.2</startAddress>
            <endAddress>192.168.1.3</endAddress>
          </ipRangeDto>
      </ipRanges>
    </ipamAddressPool> """
    py_dict = {'ipAddress': '10.112.10.xxx', 'userName': 'root', 'password': 'vmware'}
    vsm_obj = VSM("10.110.28.44:443", "admin", "default")
    ipam_obj = IPAMAddressPool(vsm_obj)

    ipam_obj.set_id('ipaddresspool-1')
    ip = ipam_obj.read()

    py_dict = dict(name='ip-pool-30', gateway='192.168.1.1', prefixlength='8',
                   ipranges=[{'startaddress': '192.168.100.1', 'endaddress': '192.168.200.1'}])
    arrayOfIPAM = base_client.bulk_create(ipam_obj, [py_dict])
    ipam_obj.id = arrayOfIPAM[0].get_response()
    py_dict = dict(name='ip-pool-30', gateway='192.168.1.1', prefixlength='8',
                   ipranges=['192.168.200.1-192.168.201.1', ])
    ipam_obj.update(py_dict)
