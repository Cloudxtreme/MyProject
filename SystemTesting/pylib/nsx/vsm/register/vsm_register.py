import vsm_client
import vmware.common.logger as logger
from vsm import VSM


class VSMRegister(vsm_client.VSMClient):
    def __init__(self, vsm=None):
        """ Constructor to create IPSet object

        @param vsm object on which IPSet has to be configured
        """
        super(VSMRegister, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'vsm_nsx_manager_info_schema.NSXManagerInfoSchema'
        self.set_connection(vsm.get_connection())
        self.set_create_endpoint(
            "universalsync/configuration/nsxmanagers")
        self.id = None
        self.update_as_post = False
        self.location_header = None

    def create(self, schema_object):
       result_obj = super(VSMRegister, self).create(schema_object)
       location_header = self.location_header
       if location_header is not None:
           self.id = location_header.split('/')[-1]
           result_obj[0].set_response_data(self.id)
       return result_obj

if __name__ == '__main__':
    import base_client
    var = """
    <nsxManagerInfo>
        <nsxManagerIp>10.110.9.131</nsxManagerIp>
        <nsxManagerUsername>admin</nsxManagerUsername>
        <nsxManagerPassword>default</nsxManagerPassword>
        <certificateThumbprint>EA:63:7C:C8:61:80:D9:C8:D4:E7:CB:AA:85:BC:C1:7D:94:8E:6E:14</certificateThumbprint>
        <isPrimary>true</isPrimary>
    </nsxManagerInfo>
    """
    log = logger.setup_logging('IPSet-Test')
    vsm_obj = VSM("10.144.137.131", "admin", "default", "")
    register_client = Register(vsm_obj)

    #Create IPSet
    py_dict1 = {'nsxmanagerip': '10.112.11.38',
                'nsxmanagerusername': 'admin',
                'nsxmanagerpassword': 'default',
                'certificatethumbprint': '0F:5E:D7:D4:DA:E4:B3:AC:FA:1F:FA:1C:11:CB:FC:49:8E:A5:5F:40',
                'isprimary': 'true'}
    result_objs = base_client.bulk_create(register_client, [py_dict1])
    print result_objs[0].status_code
    print register_client.id


    #Delete IPSet
    response_status = register_client.delete()
    print response_status.status_code
