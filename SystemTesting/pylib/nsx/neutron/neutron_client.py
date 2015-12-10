from base_client import BaseClient
import json

class NeutronClient(BaseClient):
    """ Class to store attributes and methods for Neutron """

    def __init__(self):
        """ Constructor to create an instance of Neutron client class
        """
        super(NeutronClient, self).__init__()
        self.set_content_type('application/json')
        self.set_accept_type('application/json')
        #TODO: Remove client type
        self.client_type = "neutron"

    def get_id(self, response=None):
        if response is None or response == "":
            return response

        self.log.debug("response: %s" % response)
        response_object = json.loads(response)
        self.log.debug("id from response: %s" % response_object["id"])
        return response_object["id"]

    def create(self, schema_object):
        result_obj = super(NeutronClient, self).create(schema_object)

        if result_obj.error is not None:
            return result_obj

        response_data = result_obj.get_response_data()
        if response_data is None or response_data == '':
            return result_obj

        schema_object.set_data(response_data, self.accept_type)
        self.id = schema_object.id
        self.log.debug("id from server: %s" % str(schema_object.id))
        self.log.debug("Stored id %s" % self.id)
        return result_obj

if __name__=='__main__':
    pass
