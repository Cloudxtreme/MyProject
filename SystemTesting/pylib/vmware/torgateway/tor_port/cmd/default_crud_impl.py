import vmware.common.global_config as global_config
import vmware.interfaces.crud_interface as crud_interface

pylogger = global_config.pylogger


class DefaultCRUDImpl(crud_interface.CRUDInterface):

    @classmethod
    def create(cls, client_object, schema):
        """
        Creates an instance of tor switch port.

        @type client_object: BaseClient
        @param client_object: A CMD client that is used to pass the calls to
            the relevant host.
        @type schema: dict
        @param schema: Dict containing the specifications of the port to be
            created. 'name' is a mandatory field for creating a port on the
            parent tor switch.
        """

        if 'phy_port_name' not in schema:
            raise AssertionError('Need to define the port name when '
                                 'creating the port!')
        pylogger.debug('Creating port with schema %r on %r' %
                       (schema, client_object.parent.id))
        ret = {}
        name = schema['phy_port_name']
        ret['response_data'] = {}
        ret['response_data']['status_code'] = 201
        ovs_cmd = "ovs-vsctl add-port "
        ovs_cmd = ovs_cmd + client_object.parent.id + " " + name
        if 'vlan' in schema:
            ovs_cmd = ovs_cmd + " tag=" + str(schema['vlan'])
        if 'attachment_type' in schema:
            if schema['attachment_type'] == 'internal':
                ovs_cmd = ovs_cmd + " -- set interface " + name
                ovs_cmd = ovs_cmd + " type=internal"
        pylogger.debug('Creating port with command: %s' % ovs_cmd)
        result = client_object.connection.request(ovs_cmd)
        if result.status_code:
            ret['response_data']['status_code'] = result.status_code
            pylogger.error('Failed to create port with name %r, received '
                           'error code %r: %r' % (name, result.status_code,
                                                  result.error))
        ret['name'] = name
        ret['id'] = name

        return ret

    @classmethod
    def delete(cls, client_object, id=None):
        ret = {}
        ret['response_data'] = {}
        ret['response_data']['status_code'] = 200

        if id is None:
            raise AssertionError('Only a port with a defined name can be '
                                 'deleted !')
        ovs_cmd = "ovs-vsctl del-port " + str(id)
        result = client_object.connection.request(ovs_cmd)
        if result.status_code:
            ret['response_data']['status_code'] = result.status_code
            pylogger.error('Failed to delete port with name %r, received '
                           'error code %r: %r' % (id, result.status_code,
                                                  result.error))

        return ret
