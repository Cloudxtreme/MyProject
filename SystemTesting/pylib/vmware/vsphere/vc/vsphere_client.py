#!/usr/bin/env python
import inspect
import pprint

import vmware.common.base_client as base_client
import vmware.common.constants as constants
import vmware.common.connections.soap_connection as soap_connection
import vmware.common.global_config as global_config
import vc_soap_util

pylogger = global_config.pylogger


class VSphereClient(base_client.BaseClient):
    DEFAULT_EXECUTION_TYPE = constants.ConnectionType.API

    def __init__(self, parent=None):
        super(VSphereClient, self).__init__(constants.ConnectionType.SOAP)
        if parent:
            self.parent = parent

    def prepare_to_serialize(self):
        self.api_connection_object.prepare_to_serialize()

    def set_connection_info(self, ip, username, password, options=None):
        self.api_connection_object = soap_connection.SOAPConnection(
            ip, username, password)

    def get_parent(self):
#        elements = self.path.split('.')

        temp = self.api_connection_object.anchor.RetrieveContent()
        # XXX(Salman): Delete the following?
        pylogger.debug('Methods found in anchor are \n%s:' %
                       pprint.pformat(inspect.getmembers(self.path_array)))
        for element in reversed(self.path_array):
            if element.type == constants.PathType.ATTRIBUTE:
                temp = getattr(temp, element.value)
            elif element.type == constants.PathType.ENTITY:
                temp = getattr(temp, element.value)
                for entity in temp:
                    if str(entity._moId) == element.args:
                        temp = entity
                        break

        return temp

    def create_api(self, schema=None, command=None):
        parent = self.get_parent()
        request = self.api_connection_object.request(
            parent, self.create_command_api, schema)
        id_string = request.response_data
        self.populate_id(id_string, schema, command)
        return id_string

    def populate_id(self, response, schema=None, command=None):
        self.id = str(response).split(':')[1]
        self.id = self.id.replace('\'', "").split(',')[0]

    def read_api(self, schema=None, command=None):
        pass

    def get_api(self, schema=None, command=None):
        parent = self.get_parent()
        x = getattr(parent, self.query_command_api)
        entity_list = x
        for entity in entity_list:
            id = entity._moId
            if str(self.id) == str(id):
                return entity

    def update_api(self, schema=None, command=None):
        pass

    def delete_api(self, schema=None, command=None):
        entity = self.get()
        x = getattr(entity, self.delete_command_api)
        y = x()
        if str(self.create_command_api).find("_Task") != -1:
            vc_soap_util.wait_for_task_completion(y)
        self.id = None

    def action_api(self, action_name, schema=None, client=None):
        method = getattr(self, action_name)
        args = {"client": client}
        if schema:
            args = {args.items(), schema.get_command_args().items()}
        method(**args)

    def query_api(self, schema=None, command=None):
        return getattr(self.parent, self.query_command_api)

    def get_current_path_element(self):
        return ""

if __name__ == "__main__":
    pass
