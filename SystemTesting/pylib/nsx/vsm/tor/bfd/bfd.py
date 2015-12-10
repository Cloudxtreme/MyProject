import vsm_client
import importlib
import result
from global_bfd_schema import GlobalBfdSchema
from vsm import VSM

class BFD(vsm_client.VSMClient):
    """ Class to create global BFD params"""

    def __init__(self, vsm_obj):
        """ Constructor to create global BFD params

        @param vsm_obj vsm object using which global BFD params will be created
        """
        super(BFD, self).__init__()
        self.schema_class = 'global_bfd_schema.GlobalBfdSchema'
        self.set_connection(vsm_obj.get_connection())
        self.connection.api_header = 'api/2.0'
        self.set_create_endpoint("vdn/hardwaregateway/bfd/config")
        self.create_as_put = True
        self.id = None

if __name__ == '__main__':
    pass
