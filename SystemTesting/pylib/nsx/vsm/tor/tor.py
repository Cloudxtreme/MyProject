import vsm_client
import importlib
import result
from tor_schema import TORSchema
from tor_gateways_schema import TORGatewaysSchema
from tor_gateway_switches_schema import TORGatewaySwitchesSchema
from tor_gateway_switch_ports_schema import TORGatewaySwitchPortsSchema
from tor_create_spec_schema import TORCreateSpecSchema
from vsm import VSM

class TOR(vsm_client.VSMClient):
    """ Class to create Top Of Rack Switch"""

    def __init__(self, vsm_obj):
        """ Constructor to create Top Of Rack Switch managed object

        @param vsm_obj vsm object using which Top Of Rack Switch will be created
        """
        super(TOR, self).__init__()
        self.schema_class = 'tor_create_spec_schema.TORCreateSpecSchema'
        self.set_connection(vsm_obj.get_connection())
        self.connection.api_header = 'api/2.0'
        self.set_create_endpoint("vdn/hardwaregateways")
        self.set_delete_endpoint("vdn/hardwaregateways")
        self.set_read_endpoint("vdn/hardwaregateways")
        self.id = None

    def read(self,type = "xml"):
        tor = TORSchema()
        self.set_query_endpoint(self.read_endpoint + "/" + str(self.id))
        tor.set_data(self.base_query(),type)
        return tor

    def get_tor_id(self):
        return self.id

    def get_tor_instance(self):
        tor_instance = TORGatewaysSchema()
        tor_instance.set_data(self.base_query(), self.accept_type)
        return tor_instance.tor

    def create(self, schema_objects=None):
        # Processing certs from a yaml
        new_schema_objects = []
        for schema_object in schema_objects:
            cert = schema_object['certificate']
            cert = cert.replace(" ", "\n")
            cert = cert.replace("BEGIN\nCERTIFICATE", "BEGIN CERTIFICATE")
            cert = cert.replace("END\nCERTIFICATE", "END CERTIFICATE")
            schema_object['certificate'] = cert
            new_schema_objects.append(schema_object)

        results = super(vsm_client.VSMClient, self).create(new_schema_objects)
        for result in results:
            obj = TORSchema()
            obj.set_data(result.get_response_data(), "xml")
            result.set_response_data(obj.objectId)
        return results

    def update(self, py_dict, url_parameters=None):
        """ Client method to perform update operation

        @param py_dict dictionary object which contains schema attributes to be
        updated
        @return status http response status
        """
        self.log.debug("update input = %s" % py_dict)
        update_object = self.get_schema_object(py_dict)
        schema_object = None

        schema_object = self.read()
        self.log.debug("schema_object after read:")
        schema_object.print_object()
        self.log.debug("schema_object from input:")
        update_object.print_object()

        if not update_object.name:
            update_object.name = schema_object.name
        self.log.debug("schema object for update operation")
        update_object.print_object()

        if self.update_as_post:
                self.response = self.request('POST', self.create_endpoint,
                                             update_object.get_data(self.content_type),
                                             url_parameters=url_parameters)
        else:
            if self.id is None:
                self.response = self.request('PUT', self.read_endpoint,
                                             update_object.get_data(self.content_type),
                                             url_parameters=url_parameters)
            else:
                self.response = self.request('PUT',
                                             self.read_endpoint + "/" + str(self.id),
                                             update_object.get_data(self.content_type),
                                             url_parameters=url_parameters)
        result_obj = result.Result()
        self.set_result(self.response, result_obj)

        return result_obj

    def get_tor_switch(self):
        self.set_query_endpoint(self.read_endpoint + "/"
                                + str(self.id) + "/switches")
        tor_switch = TORGatewaySwitchesSchema()
        tor_switch.set_data(self.base_query(), self.accept_type)
        return tor_switch.torswitch

    def get_tor_switch_port(self, switch_name=None):
        self.set_query_endpoint(self.read_endpoint + "/" + str(self.id)
                                + "/switches/" + str(switch_name)
                                + "/switchports")
        tor_switch_ports = TORGatewaySwitchPortsSchema()
        tor_switch_ports.set_data(self.base_query(), self.accept_type)
        return tor_switch_ports.torswitchport

if __name__ == '__main__':
    pass
