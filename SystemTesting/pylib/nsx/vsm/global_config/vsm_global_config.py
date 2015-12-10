import vsm_client
from vsm_global_config_schema import VSMGlobalConfigSchema


class VSMGlobalConfig(vsm_client.VSMClient):
    """ Class to store attributes and methods for VSM """

    def __init__(self, vsm=None):
        ''' Constructor to create an instanc of VSM class

        @param ip:  ip address of VSM
        @param user: user name to create connection
        @param password: password to create connection
        '''

        super(VSMGlobalConfig, self).__init__()
        self.schema_class = 'vsm_global_config_schema.VSMGlobalConfigSchema'

        self.set_connection(vsm.get_connection())
        self.set_create_endpoint("/global/config")
        self.id = None

if __name__=='__main__':
    from vsm import VSM
    py_dict = {'ipAddress' : '10.112.10.xxx', 'userName' : 'root', 'password' : 'vmware'}
    vsm_obj = VSM("10.115.175.197:443", "admin", "default")
    vsm_obj.init(py_dict)
