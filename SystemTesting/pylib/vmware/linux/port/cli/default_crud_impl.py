import vmware.common.global_config as global_config
import vmware.interfaces.crud_interface as crud_interface
import vmware.linux.ovs.ovs_helper as ovs_helper

OVS = ovs_helper.OVS
pylogger = global_config.pylogger


class DefaultCRUDImpl(crud_interface.CRUDInterface):

    @classmethod
    def get_uuid(cls, client_object):
        """
        Fetches the port's uuid.

        @type client_object: BaseClient
        @param client_object: CLI client object that is used to execute
            commands on the relevant host.
        @rtype: str
        @return: Returns the uuid.
        """
        return client_object.ovsdb.Port.get_one(
            search='name=%s' % client_object.name).uuid

    @classmethod
    def get_id(cls, client_object, schema=None):
        """
        Returns the name of the port after ascertaining the existence of
        passed in port name (as part of schema object) on the bridge.

        @type schema: dict
        @param schema: Dictionary containing the specifications of the port.
        """
        if 'name' not in schema:
            raise AssertionError('Yaml must specify the name of the port'
                                 'to create/acquire')
        name = None
        response_data = {'status_code': 404}
        ret = {'response_data': response_data}
        ports = client_object.ovsdb.Port.get_all()
        for port in ports:
            if schema['name'] == port.name:
                name = schema['name']
                ret['name'] = name
                ret['response_data']['status_code'] = 201
                pylogger.debug('Discovered id of the port on %r is %r' %
                               (client_object.connection.ip, name))
        if not name:
            pylogger.debug('Did not find any port with the name %r on %r' %
                           (schema['name'], client_object.name))
        return ret

    @classmethod
    def create(cls, client_object, schema=None):
        """
        Creates an instance of port on the switch.

        @type client_object: BaseClient
        @param client_object: A CLI client that is used to pass the calls to
            the relevant host.
        @type schema: dict
        @param schema: Dict containing the specifications of the port to be
            created. 'name' is a mandatory field for creating a port on the
            parent bridge.
        """
        if 'name' not in schema:
            raise AssertionError('Need to define the port name when '
                                 'creating the port!')
        discovered = cls.get_id(client_object, schema=schema)
        if discovered['response_data']['status_code'] == 201:
            return discovered
        pylogger.debug('Creating port with schema %r on %r' %
                       (schema, client_object.bridge_name))
        ret = {}
        name = schema['name']  # Bridges have unique names on KVM.
        ret['response_data'] = {}
        ret['response_data']['status_code'] = 201
        add_cmd = OVS.add_record(OVS.PORT, schema['name'],
                                 parent=client_object.bridge_name)
        result = client_object.connection.request(add_cmd)
        if result.status_code:
            ret['response_data']['status_code'] = result.status_code
            pylogger.error('Failed to create port with schema %r, received '
                           'error code %r: %r' % (schema, result.status_code,
                                                  result.error))
            name = None
        ret['name'] = name
        return ret

    @classmethod
    def read(cls, client_object):
        """
        Reads port's attribute.

        @type client_object: BaseClient
        @param client_object: A CLI client that is used to pass the calls to
            the relevant host.
        """
        raise NotImplementedError("STUB")

    @classmethod
    def update(cls, client_object, schema=None):
        """
        Updates a port on the bridge.

        @type client_object: BaseClient
        @param client_object: CLI client object that is used to execute
            commands on the relevant host.
        @type schema: TBD
        @param schema: TBD
        """
        raise NotImplementedError("STUB")

    @classmethod
    def delete(cls, client_object, name=None):
        """
        Deletes a port on a bridge on the host.

        @type client_object: BaseClient
        @param client_object: CLI client object that is used to execute
            commands on the relevant host.
        """
        ret = {}
        ret['response_data'] = {}
        ret['response_data']['status_code'] = 200
        delete_cmd = OVS.del_record(OVS.PORT, name,
                                    parent=client_object.bridge_name)
        result = client_object.connection.request(delete_cmd)
        if result.status_code:
            ret['response_data']['status_code'] = result.status_code
            pylogger.error('Failed to delete port with id %r, received '
                           'error code %r: %r' % (name, result.status_code,
                                                  result.error))
        return ret
