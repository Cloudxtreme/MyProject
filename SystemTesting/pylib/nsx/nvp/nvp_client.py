from base_client import BaseClient
import json

class NVPClient(BaseClient):
    """ Class to store attributes and methods for Neutron """

    def __init__(self):
        """ Constructor to create an instance of NVP class
        """
        super(NVPClient, self).__init__()
        self.set_content_type('application/json')
        self.set_accept_type('application/json')
        #TODO: Remove client type
        self.client_type = "nvp"

    def get_id(self, response=None):
        if response is None or response == "":
            self.log.debug("Response is empty or not defined")
            return response
        response_object = json.loads(response)
        self.log.debug("id from response: %s" % response_object["uuid"])
        return response_object["uuid"]

    def create(self, schema_object):
        result_obj = super(NVPClient, self).create(schema_object)

        if result_obj[0].error is not None:
            return result_obj

        response_data = result_obj[0].get_response_data()
        schema_object.set_data(response_data, self.accept_type)
        self.id = schema_object.uuid
        self.log.debug("uuid from server: %s" % str(schema_object.uuid))
        self.log.debug("Stored id %s" % self.id)
        return result_obj

    def nvp_get_ids_from_result(self, instance_dump):
        results_obj = json.loads(instance_dump)
        results_array = results_obj['results']
        id_array = []
        for result in results_array:
            href = result['_href']
            href_array = href.split("/")
            id_instance = href_array[len(href_array)-1]
            id_array.append(id_instance)
        return id_array

    def nvp_bulk_delete(self):
        """ Method to delete all instances on this endpoint
        """
        instance_dump = self.query()
        id_array = self.nvp_get_ids_from_result(instance_dump)
        temp_id = self.id
        for id_instance in id_array:
            self.id = id_instance
            self.delete()
        self.id = temp_id

if __name__=='__main__':
    pass
