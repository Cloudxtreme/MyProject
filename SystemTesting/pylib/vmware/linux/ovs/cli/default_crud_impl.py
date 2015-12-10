import os
import pprint

import vmware.common.global_config as global_config
import vmware.interfaces.crud_interface as crud_interface
import vmware.linux.ovs.ovs_helper as ovs_helper
import vmware.linux.linux_helper as linux_helper
import vmware.common.utilities as utilities

OVS = ovs_helper.OVS
Linux = linux_helper.Linux
pylogger = global_config.pylogger


class DefaultCRUDImpl(crud_interface.CRUDInterface):
    BRIDGE_PREFIX = 'br'
    NETWORK_SCRIPTS_PATH = '/etc/sysconfig/network-scripts'
    IFCFG_FILE = os.path.join(NETWORK_SCRIPTS_PATH, 'ifcfg-%s')

    @classmethod
    def get_id_from_schema(cls, client_object, schema=None):
        """
        Returns the name of the bridge after ascertaining the existence of
        passed in bridge name (as part of schema object) on the host.

        @type schema: dict
        @param schema: Dictionary containing the specifications of the adapter.
        """
        if 'name' not in schema:
            raise AssertionError('Yaml must specify the name of the bridge'
                                 'to create/acquire')
        name = None
        response_data = {'status_code': 404}
        ret = {'response_data': response_data}
        parsed_data = cls.get_adapter_info(client_object)
        pylogger.debug('Parsed ifconfig data:\n%s' %
                       pprint.pformat(parsed_data))
        for record in parsed_data['table']:
            if record['dev'] == schema['name']:
                name = record['dev']
                ret['name'] = name
                ret['response_data']['status_code'] = 201
                pylogger.debug('Discovered id of the bridge on %r is %r' %
                               (client_object.parent.ip, name))

                break
        if not name:
            pylogger.debug('Did not find any bridge with the name %r on %r' %
                           (schema['name'], client_object.parent.ip))
        return ret

    @classmethod
    def _write_ifcfg_bridge(cls, client_object, device, ovs_extra=None,
                            ovs_dhcp_interfaces=None, ovs_boot_proto=None):
        ovs_extra = utilities.get_default(ovs_extra, '')
        ovs_dhcp_interfaces = utilities.get_default(ovs_dhcp_interfaces, '')
        ovs_boot_proto = utilities.get_default(ovs_boot_proto, 'none')
        config_map = ovs_helper.IFCFG_BRIDGE_MAP
        config_map['DEVICE'] = device
        config_map['OVS_EXTRA'] = ovs_extra
        config_map['OVSBOOTPROTO'] = ovs_boot_proto
        config_map['OVSDHCPINTERFACES'] = ovs_dhcp_interfaces
        config = ['%s="%s"' % (key, val)
                  for key, val in config_map.iteritems()]
        return Linux.create_file(
            client_object, cls.IFCFG_FILE % device, content='\n'.join(config),
            overwrite=True)

    @classmethod
    def _write_ifcfg_port(cls, client_object, device, ovs_bridge):
        config_map = ovs_helper.IFCFG_PORT_MAP
        config_map['DEVICE'] = device
        config_map['OVS_BRIDGE'] = ovs_bridge
        config = ['%s="%s"' % (key, val)
                  for key, val in config_map.iteritems()]
        return Linux.create_file(
            client_object, cls.IFCFG_FILE % device, content='\n'.join(config),
            overwrite=True)

    @classmethod
    def get_adapter_info(cls, client_object):
        """
        Returns parsed data as dictionary for all vmknic that exists on the
        host.
        """
        cmd = 'ifconfig -a'
        raw_data = client_object.connection.request(cmd).response_data
        return {'table': utilities.parse_ifconfig_output(raw_data)}

    # TODO(salmanm): Inherit result.Result from BaseSchema to avoid copying the
    # attributes manually?
    @classmethod
    def create(cls, client_object, schema=None):
        """
        Creates an instance of OVS bridge on the host if it doesn't exist
        already otherwise returns with the id of the existing bridge.

        @type client_object: BaseClient
        @param client_object: A CLI client that is used to pass the calls to
            the relevant host.
        @type schema: dict
        @param schema: Dictionary containing the specifications of the bridge.
        """
        if 'name' not in schema:
            raise AssertionError('Need to define the bridge name when '
                                 'creating a bridge!')
        pylogger.debug('Creating bridge with schema %r on %r' %
                       (schema, client_object.ip))
        ret = {}
        name = schema['name']  # Bridges have unique names on KVM.
        ret['response_data'] = {}
        ret['response_data']['status_code'] = 201
        add_cmd = OVS.add_record(cls.BRIDGE_PREFIX, schema['name'],
                                 may_exist=True)
        result = client_object.connection.request(add_cmd)
        if result.status_code:
            ret['response_data']['status_code'] = result.status_code
            pylogger.error('Failed to create bridge with schema %r, '
                           'received error code %r: %r' %
                           (schema, result.status_code, result.error))
            name = None
        if 'adapter_interface' in schema:
            port = schema['adapter_interface']
            if name:
                add_cmd = OVS.add_record(OVS.PORT, port, parent=name,
                                         may_exist=True)
                result = client_object.connection.request(add_cmd)
                if result.status_code:
                    ret['response_data']['status_code'] = result.status_code
                    pylogger.error('Failed to add port %r to bridge %r, '
                                   'received error code %r: %r' %
                                   (port, name, result.status_code,
                                    result.error))
                ovs_extra = None
                ovs_boot_proto = None
                if 'switch_fail_mode' in schema:
                    ovs_extra = ('set Bridge %s fail_mode=%s' %
                                 (name, schema['switch_fail_mode']))
                if 'enable_dhcp' in schema and schema['enable_dhcp']:
                    ovs_boot_proto = 'dhcp'
                cls._write_ifcfg_bridge(
                    client_object, name, ovs_extra=ovs_extra,
                    ovs_dhcp_interfaces=port, ovs_boot_proto=ovs_boot_proto)
                cls._write_ifcfg_port(client_object, port, name)
                client_object.connection.request('ifconfig %s 0' % port)
                client_object.connection.request('ifup %s' % port)
            else:
                pylogger.error('Skipping the addition of port %r to a non '
                               'existing bridge' % schema['adapter_interface'])
        if 'switch_fail_mode' in schema:
            mode = schema['switch_fail_mode']
            if name:
                set_mode_cmd = ("ovs-vsctl set bridge %s fail_mode=%s" %
                                (name, mode))
                result = client_object.connection.request(set_mode_cmd)
                if result.status_code:
                    ret['response_data']['status_code'] = result.status_code
                    pylogger.error('Failed to set fail mode %r on bridge %r, '
                                   'received error code %r: %r' %
                                   (mode, name, result.status_code,
                                    result.error))
            else:
                pylogger.error('Skipping setting failover mode to %r on a non '
                               'existing bridge' % schema['mode'])
        ret['name'] = name
        return ret

    @classmethod
    def read(cls, client_object, name=None, **kwargs):
        """
        Read the OVS bridge information from host.

        @type client_object: BaseClient
        @param client_object: A CLI client that is used to pass the calls to
            the relevant host.
        @type name: str
        @param name: name of the bridge
        @rtype: dict
        @return: Dictionary containing information of the given OVS bridge.
        """
        if not name:
            raise AssertionError('Yaml must specify the name of the bridge'
                                 'to read.')
        # Initially set status code to 404 (Not Found).
        response_data = {'status_code': 404}
        ret = {'response_data': response_data}
        # Get adapter information.
        parsed_data = cls.get_adapter_info(client_object)
        pylogger.debug('Parsed ifconfig data:\n%s' %
                       pprint.pformat(parsed_data))
        # Parse gathered data.
        for record in parsed_data['table']:
            if record['dev'] == name:
                ret['name'] = record['dev']
                ret['ip'] = record['ip']
                ret['mac'] = record['mac']
                ret['response_data']['status_code'] = 201
                break
        if 'name' not in ret or not ret['name']:
            pylogger.debug('Did not find any bridge with the name %r on %r' %
                           (name, client_object.ip))
        return ret

    @classmethod
    def update(cls, client_object, schema=None, **kwargs):
        raise NotImplementedError

    @classmethod
    def delete(cls, client_object, name=None):
        """
        Deletes an instance of OVS bridge on the host.

        @type client_object: BaseClient
        @param client_object: A CLI client that is used to pass the calls to
            the relevant host.
        """
        ret = {}
        ret['response_data'] = {}
        ret['response_data']['status_code'] = 200
        delete_cmd = OVS.del_record(cls.BRIDGE_PREFIX, name)
        result = client_object.connection.request(delete_cmd)
        if result.status_code:
            ret['response_data']['status_code'] = result.status_code
            pylogger.error('Failed to delete bridge with id %r, received '
                           'error code %r: %r' % (name, result.status_code,
                                                  result.error))
        return ret
