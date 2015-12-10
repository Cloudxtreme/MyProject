import vmware.common.logger as logger
import neutron
import neutron_client
import neutron_result


class NVPRegistration(neutron_client.NeutronClient):

    def __init__(self, neutron=None):
        super(NVPRegistration, self).__init__()
        self.log = logger.setup_logging(self.__class__.__name__)
        self.schema_class = 'nvp_registration_schema.NVPRegistration'

        if neutron is not None:
            self.set_connection(neutron.get_connection())

        self.set_create_endpoint('/element-managers/nvp')

    def create(self, r_schema):
        nvp_registration_schema = r_schema
        result_obj = super(NVPRegistration, self).create(nvp_registration_schema)
        if result_obj.status_code == int(403):
            result = neutron_result.Result()
            result.set_data(result_obj.get_response_data(), self.accept_type)
            if nvp_registration_schema.cert_thumbprint == '' or \
                    nvp_registration_schema.cert_thumbprint is None:
                nvp_registration_schema.cert_thumbprint = result.errorData.thumbprint
                result_obj = super(NVPRegistration, self).create(nvp_registration_schema)
        return result_obj


if __name__ == '__main__':
    import base_client

    nc = neutron.Neutron("10.24.115.115:8082", "root", "vmware")
    nvp_register = NVPRegistration(neutron=nc)
    py_dict = {'ipaddress': '192.168.2.3', 'username': 'admin', 'password':'admin', 'role': 'API_PROVIDER'}
    base_client.bulk_create(nvp_register, [py_dict])
