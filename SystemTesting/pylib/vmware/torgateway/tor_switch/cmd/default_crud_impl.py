import vmware.common.global_config as global_config
import vmware.interfaces.crud_interface as crud_interface

pylogger = global_config.pylogger


class DefaultCRUDImpl(crud_interface.CRUDInterface):

    @classmethod
    def create(cls, client_object, schema):
        """
        Creates an instance of tor switch.

        @type client_object: BaseClient
        @param client_object: A CMD client that is used to pass the calls to
            the relevant host.
        @type schema: dict
        @param schema: Dict containing the specifications of the swotch to be
            created. 'name' is a mandatory field for creating a switch on the
            parent tor gateway.
        """

        if 'name' not in schema:
            raise AssertionError('Need to define the switch name when '
                                 'creating the switch!')
        ret = {}
        name = schema['name']
        ret['response_data'] = {}
        ret['response_data']['status_code'] = 201
        ovs_cmd = "ovs-vsctl add-br " + schema['name']
        result = client_object.connection.request(ovs_cmd)
        if result.status_code:
            ret['response_data']['status_code'] = result.status_code
            pylogger.error('Failed to create bridge with schema %r, received '
                           'error code %r: %r' % (schema, result.status_code,
                                                  result.error))
            name = None
        ret['id'] = name

        vtep_cmd = "vtep-ctl add-ps " + schema['name']
        result = client_object.connection.request(vtep_cmd)
        if result.status_code:
            ret['response_data']['status_code'] = result.status_code
            pylogger.error('Failed to create tor switch with schema %r, '
                           'received error code %r: %r' % (schema,
                                                           result.status_code,
                                                           result.error))
            name = None
        ret['id'] = name

        return ret

    @classmethod
    def delete(cls, client_object, id=None):

        ret = {}
        ret['response_data'] = {}
        ret['response_data']['status_code'] = 200
        vtep_cmd = "vtep-ctl del-ps " + str(id)
        result = client_object.connection.request(vtep_cmd)
        if result.status_code:
            ret['response_data']['status_code'] = result.status_code
            pylogger.error('Failed to delete tor switch with name %r,'
                           'received error code %r: %r' % (id,
                                                           result.status_code,
                                                           result.error))

        ret = {}
        ret['response_data'] = {}
        ret['response_data']['status_code'] = 200
        ovs_cmd = "ovs-vsctl del-br " + str(id)
        result = client_object.connection.request(ovs_cmd)
        if result.status_code:
            ret['response_data']['status_code'] = result.status_code
            pylogger.error('Failed to delete bridge with name %r, received '
                           'error code %r: %r' % (id, result.status_code,
                                                  result.error))

        return ret

    @classmethod
    def get_id(cls, client_object):
        return client_object.id
