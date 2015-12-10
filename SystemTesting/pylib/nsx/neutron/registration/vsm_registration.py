import vmware.common.logger as logger
import neutron
import neutron_client
import neutron_result


class VSMRegistration(neutron_client.NeutronClient):

    def __init__(self, neutron=None):
        super(VSMRegistration, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'registration_schema.Registration'

        if neutron is not None:
            self.set_connection(neutron.get_connection())

        self.set_create_endpoint('/element-managers/vcns')

    def create(self, r_schema):
        vsm_registration_schema = r_schema
        result_obj = super(VSMRegistration, self).create(vsm_registration_schema)
        if result_obj.status_code == int(403):
            result = neutron_result.Result()
            result.set_data(result_obj.get_response_data(), self.accept_type)
            if vsm_registration_schema.cert_thumbprint == '' or \
                    vsm_registration_schema.cert_thumbprint is None:
                vsm_registration_schema.cert_thumbprint = result.errorData.thumbprint
                result_obj = super(VSMRegistration, self).create(vsm_registration_schema)
        return result_obj

if __name__ == '__main__':
    import base_client

    nc = neutron.Neutron("10.110.27.77:443", "localadmin", "default")
    vsm_register = VSMRegistration(neutron=nc)
    #vsm_register_schema = registration_schema.Registration()
    #vsm_register_schema.set_data_json('{"name":"10.110.28.190","vsmUuid":"uuid-2","ipaddress":"10.110.28.190"}')
    py_dict = {'schema': '/v1/schema/VSMConfig', 'display_name': 'vsm-3',
               'address': '10.110.27.60', 'user': 'admin,',
               'password': 'default', 'cert_thumbprint': ''}
    base_client.bulk_create(vsm_register, [py_dict])
    #print vsm_register_schema.ipaddress
    #print 'Status code: ' + str(vsm_register.result.status_code)
