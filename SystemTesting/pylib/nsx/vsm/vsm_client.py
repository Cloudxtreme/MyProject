from base_client import BaseClient
import connection


class VSMClient(BaseClient):
    ''' Class to store attributes and methods for VSM '''

    def __init__(self):
        ''' Constructor to create an instanc of VSM class

        @param ip:  ip address of VSM
        @param user: user name to create connection
        @param password: password to create connection
        '''

        super(VSMClient, self).__init__()
        self.set_content_type('application/xml')
        self.set_accept_type('application/xml')
        #TODO: Remove client type
        self.client_type = "vsm"

    def create(self, schema_object):
        result_obj = super(VSMClient, self).create(schema_object)

        if result_obj[0].error is not None:
            return result_obj

        response_data = result_obj[0].get_response_data()
        response = result_obj[0].get_response()
        location = response.getheader("Location")
        self.log.debug("Location header is %s" % location)
        self.location_header = location

        if response_data is not None and response_data != "":
            self.id = response_data

        result_obj[0].set_is_result_object(False)
        return result_obj

    def get_id(self, response=None):
        if response is not None:
            return response
        else:
            return self.id


if __name__=='__main__':
    from vsm import VSM
    py_dict = {'ipAddress': '10.112.10.xxx', 'userName': 'root', 'password': 'vmware'}
    vsm_obj = VSM("10.115.175.197:443", "admin", "default")
