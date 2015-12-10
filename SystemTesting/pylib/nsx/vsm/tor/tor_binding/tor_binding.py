import vsm_client
import importlib
import result
from tor_binding_schema import TORBindingSchema
from tor_gateway_bindings_schema import TORGatewayBindingsSchema
from vsm import VSM

class TORBinding(vsm_client.VSMClient):
    """ Class to create Top Of Rack Switch Binding"""

    def __init__(self, vsm_obj):
        """ Constructor to create Top Of Rack Switch Binding managed object

        @param vsm_obj vsm object using which Top Of Rack Switch Binding will be created
        """
        super(TORBinding, self).__init__()
        self.schema_class = 'tor_binding_schema.TORBindingSchema'
        self.set_connection(vsm_obj.get_connection())
        self.connection.api_header = 'api/2.0'
        self.set_create_endpoint("vdn/hardwaregateway/bindings")
        self.set_delete_endpoint("vdn/hardwaregateway/bindings")
        self.set_read_endpoint("vdn/hardwaregateway/bindings")
        self.id = None

    def read(self,type = "xml"):
        tor = TORBindingSchema()
        self.set_query_endpoint(self.read_endpoint + "/" + str(self.id))
        tor.set_data(self.base_query(),type)
        return tor

    def get_tor_binding(self):
        tor_binding = TORGatewayBindingsSchema()
        tor_binding.set_data(self.base_query(), self.accept_type)
        return tor_binding.binding

    def create(self, schema_objects=None):
        results = super(vsm_client.VSMClient, self).create(schema_objects)

        for result in results:
            obj = TORBindingSchema()
            obj.set_data(result.get_response_data(), "xml")
            result.set_response_data(obj.id)
        return results

if __name__ == '__main__':
    pass
