import vmware.common.utilities as utilities
import vmware.interfaces.switch_interface as switch_interface
import vmware.parsers.horizontal_table_parser as horizontal_table_parser
import vmware.schema.switch.arp_table_schema as arp_table_schema
import vmware.schema.switch.logical_switch_schema as logical_switch_schema
import vmware.schema.switch.mac_table_schema as mac_table_schema
import vmware.schema.switch.vtep_table_schema as vtep_table_schema


# XXX(Salman): How will we differentiate between the overlay logical switches
# and VLAN backed logical switches?
class LinuxSwitchImpl(switch_interface.SwitchInterface):
    """
    Class for implementing query operations for overlay logical switches on
    the hosts.

    Note: This implementation is specific to logical switches backed by OVS.
    The output of the commands are documented at: http://goo.gl/SdI2oK
    """
    DEFAULT_SOCKET_DIR = '/var/run/openvswitch'
    CLI = 'ovs-appctl'
    HORIZONTAL_PARSER_TYPE = 'raw/horizontalTable'
    IP_ADDRESS = 'IP Address'
    REPLICATION_MODE = 'replication_mode'

    @classmethod
    def _get_nsxa_socket(cls, client_object):
        cmd = 'ls %s/nsxa*ctl' % cls.DEFAULT_SOCKET_DIR
        nsxa_socket = client_object.connection.request(
            cmd).response_data.strip()
        if nsxa_socket == '':
            raise AssertionError('Unable to locate the nsx agent socket file '
                                 'in: %r' % cls.DEFAULT_SOCKET_DIR)
        return nsxa_socket

    @classmethod
    def get_arp_table(cls, client_object, switch_vni=None):
        """
        Fetches the ARP table for the logical switch.

        @param switch_vni: VNI to identify the logical switch.
        @type switch_vni: int
        @return: Returns the ARPTableSchema object.
        @rtype: arp_table_schema.ARPTableSchema
        """
        attribute_map = {'mac address': 'adapter_mac',
                         'ip address': 'adapter_ip'}
        nsxa_socket = cls._get_nsxa_socket(client_object)
        cmd = ('%s -t %s vni/arp-table %s' %
               (cls.CLI, nsxa_socket, switch_vni))
        out = client_object.connection.request(cmd).response_data.split('\n')
        # Skip the VNI number in the output.
        raw_table_data = '\n'.join(out[1:])
        header_keys = ["IP Address", "Mac Address"]
        parser = horizontal_table_parser.HorizontalTableParser()
        parsed_data = parser.get_parsed_data(raw_table_data,
                                             header_keys=header_keys)
        mapped_pydict = utilities.map_attributes(attribute_map, parsed_data)
        return arp_table_schema.ARPTableSchema(py_dict=mapped_pydict)

    @classmethod
    def get_vtep_ip_by_label(cls, client_object, label=None):
        """
        Fetches VTEP IP provided the label of that VTEP.
        """
        nsxa_socket = cls._get_nsxa_socket(client_object)
        cmd = '%s -t %s vtep/ip %%s' % (cls.CLI, nsxa_socket)
        out = client_object.connection.request(
            cmd % label).response_data.strip()
        return utilities.parse_one_line_output(
            out, record_delim=',', key_val_delim=':')[cls.IP_ADDRESS]

    @classmethod
    def get_mac_table(cls, client_object, switch_vni=None):
        """
        Fetches the MAC table for the logical switch.

        @param switch_vni: VNI to identify the logical switch.
        @type switch_vni: int
        @return: Returns the MACTableSchema object.
        @rtype: mac_table_schema.MACTableSchema
        """
        header_keys = ['Mac Address', 'VTEP Label']
        nsxa_socket = cls._get_nsxa_socket(client_object)
        cmd = ('%s -t %s vni/mac-vtep-label %s' %
               (cls.CLI, nsxa_socket, switch_vni))
        out = client_object.connection.request(cmd).response_data
        horizontal_parser = horizontal_table_parser.HorizontalTableParser()
        # Skip the VNI number in the output.
        mac_to_vtep = horizontal_parser.get_parsed_data(
            out, header_keys=header_keys, skip_head=1)['table']
        py_dicts = []
        for mac_vtep in mac_to_vtep:
            py_dict = {}
            vm_mac = mac_vtep['mac address']
            vtep_label = mac_vtep['vtep label']
            vtep_ip = cls.get_vtep_ip_by_label(client_object, label=vtep_label)
            py_dict['adapter_mac'] = vm_mac
            py_dict['adapter_ip'] = vtep_ip
            py_dicts.append(py_dict)
        py_dict = {'table': py_dicts}
        return mac_table_schema.MACTableSchema(py_dict=py_dict)

    @classmethod
    def get_replication_mode(cls, client_object, switch_vni=None):
        """
        Fetches the replication mode of the switch.

        @param switch_vni: VNI to identify the logical switch.
        @type switch_vni: int
        @return: Returns the replication mode in use.
        @rtype: str
        """
        nsxa_socket = cls._get_nsxa_socket(client_object)
        cmd = ('%s -t %s vni/replication-mode %s' %
               (cls.CLI, nsxa_socket, switch_vni))
        out = client_object.connection.request(cmd).response_data.strip()
        return utilities.parse_one_line_output(
            out, record_delim=',', key_val_delim=':')[cls.REPLICATION_MODE]

    @classmethod
    def get_logical_switch(cls, client_object, get_logical_switch=None):
        """
        Fetches logical switch information.
        """
        _ = get_logical_switch
        header_keys = ['VNI', 'Controller IP Address', 'Link Status']
        attribute_map = {'vni': 'switch_vni',
                         'controller ip address': 'controller_ip',
                         'link status': 'controller_status'}
        nsxa_socket = cls._get_nsxa_socket(client_object)
        cmd = ('%s -t %s vni/list ' % (cls.CLI, nsxa_socket))
        out = client_object.connection.request(cmd).response_data
        horizontal_parser = horizontal_table_parser.HorizontalTableParser()
        switch_dicts = horizontal_parser.get_parsed_data(
            out, header_keys=header_keys)['table']
        for switch_dict in switch_dicts:
            replication_mode = cls.get_replication_mode(
                client_object, switch_vni=switch_dict['vni'])
            switch_dict['replication_mode'] = replication_mode
            for dict_key in switch_dict.keys():
                switch_dict[dict_key] = switch_dict[dict_key].lower()
        mapped_pydict = utilities.map_attributes(
            attribute_map, {'table': switch_dicts})
        return logical_switch_schema.LogicalSwitchSchema(py_dict=mapped_pydict)

    @classmethod
    def get_vtep_label(cls, client_object, switch_vni=None):
        """
        Fetches the VTEP labels for a given VNI.
        """
        header_keys = ['VTEP Label']
        nsxa_socket = cls._get_nsxa_socket(client_object)
        cmd = ('%s -t %s vni/vtep_list %s' %
               (cls.CLI, nsxa_socket, switch_vni))
        out = client_object.connection.request(cmd).response_data
        horizontal_parser = horizontal_table_parser.HorizontalTableParser()
        # Skip the VNI number in the output.
        return horizontal_parser.get_parsed_data(
            out, header_keys=header_keys, skip_head=1)

    @classmethod
    def get_vtep_table(cls, client_object, switch_vni=None,
                       host_switch_name=None):
        """
        Fetches the VTEP table i.e. the IP addresses of the VTEPs in this
        logical switch/VNI.
        """
        vtep_labels = cls.get_vtep_label(
            client_object, switch_vni=switch_vni)
        attribute_map = {'vtep label': 'adapter_ip'}
        for vtep_label in vtep_labels['table']:
            label = vtep_label['vtep label']
            vtep_label['vtep label'] = cls.get_vtep_ip_by_label(
                client_object, label=label)
        mapped_pydict = utilities.map_attributes(attribute_map, vtep_labels)
        return vtep_table_schema.VtepTableSchema(py_dict=mapped_pydict)

    @classmethod
    def get_vni_table(cls, client_object, switch_vni=None):
        raise NotImplementedError('Only Controller nodes are expected to have '
                                  'VNI table')

    @classmethod
    def get_ports(cls, client_object, switch_vni):
        raise NotImplementedError('STUB')

    @classmethod
    def is_master_for_vni(cls, client_object, switch_vni=None):
        raise NotImplementedError('Only CCP is expected to have knowledge '
                                  'about master controller of a VNI')

    @classmethod
    def list_portgroup(cls, client_object):
        raise NotImplementedError('Port groups do not exist on linux.')

    @classmethod
    def configure_uplinks(cls, client_object, uplinks=None):
        raise NotImplementedError('Can not configure uplinks on logical '
                                  'switches')
