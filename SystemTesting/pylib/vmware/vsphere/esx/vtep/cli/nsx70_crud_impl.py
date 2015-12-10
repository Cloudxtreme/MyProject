import pprint
import vmware.common.constants as constants
import vmware.common.utilities as utilities
import vmware.common.global_config as global_config
import vmware.interfaces.crud_interface as crud_interface
import vmware.parsers.horizontal_table_parser as horizontal_table_parser
import vmware.parsers.vertical_table_parser as vertical_table_parser

pylogger = global_config.pylogger


class NSX70CRUDImpl(crud_interface.CRUDInterface):

    @classmethod
    def get_id_from_schema(cls, client_object, schema=None):
        """
        Returns the name of the vmknic after ascertaining the existence of
        passed in vtep name (as part of schema object) on the host.

        @type schema: dict
        @param schema: Dictionary containing the specifications of the adapter.
        """
        if 'name' not in schema:
            raise AssertionError('Yaml must specify the name of the VTEP '
                                 'to acquire')
        name = None
        response_data = {'status_code': 404}
        ret = {'response_data': response_data}
        parsed_data = cls.get_adapter_info(client_object)
        pylogger.debug('Parsed vmknic data:\n%s' % pprint.pformat(parsed_data))
        for record in parsed_data['table']:
            if record['interface'] == schema['name']:
                name = record['interface']
                ret['name'] = name
                ret['response_data']['status_code'] = 201
                break
        pylogger.debug('Discovered id of the vtep on %r is %r' %
                       (client_object.ip, name))
        if not name:
            pylogger.warning('Did not find any VTEP with the name %r on %r' %
                             (schema['name'], client_object.ip))
        return ret

    @classmethod
    def delete(cls, client_object, name=None):
        """
        Deletes the vmknic from the host.
        """
        connection = client_object.connection
        # TODO(gjayavelu): remove the following line after VTEP deletion
        # becomes part of transport node deletion
        response_data = {'status_code': 200}
        result = {'response_data': response_data}
        command = '/automation/scripts/clear-vtep'
        connection.request(command)
        return result

    @classmethod
    def read(cls, client_object, name=None, **kwargs):
        """
        Read the vmknic info from the host.
        """
        pydict = cls.get_adapter_info(client_object)
        result_dict = None
        for entry in pydict['table']:
            if entry['interface'] == name:
                result_dict = entry
                break
        if (not result_dict):
            pylogger.error('Failed to read vtep information for %r' % name)
            return constants.Result.FAILURE.upper()
        result_dict['response_data'] = dict()
        result_dict['response_data']['status_code'] = 200
        return result_dict

    @classmethod
    def get_adapter_info(cls, client_object):
        """
        Returns parsed data as dictionary for all vmknic that exists on the
        host.
        """
        horizontal_parser = horizontal_table_parser.HorizontalTableParser()
        cmd = 'esxcfg-vmknic -l'
        header_keys = ['Interface', 'Port Group/DVPort', 'IP Family',
                       'IP Address', 'Netmask', 'Broadcast', 'MAC Address',
                       'MTU', 'TSO MSS', 'Enabled', 'Type']
        raw_data = client_object.connection.request(cmd).response_data
        horizontal_data = horizontal_parser.get_parsed_data(
            raw_data, expect_empty_fields=True,
            header_keys=header_keys)['table']
        vertical_parser = vertical_table_parser.VerticalTableParser()
        cmd = 'esxcli network ip interface list'
        raw_data = client_object.connection.request(cmd).response_data
        vertical_data = vertical_parser.get_parsed_data(
            raw_data, lowercase_data=False)['table']
        merged_info = []
        for horizontal_info in horizontal_data:
            for key in vertical_data:
                if horizontal_info['interface'] == key:
                    horizontal_info.update(vertical_data[key])
                    merged_info.append(horizontal_info)
        attribute_map = {
            'port group/dvport': 'dvport',
            'ip family': 'ip_family',
            'ip address': 'ip',
            'mac address': 'mac',
            'tso mss': 'tso_mss',
            'Netstack Instance': 'netstack'
        }
        mapped_pydicts = []
        for info in merged_info:
            mapped_pydicts.append(utilities.map_attributes(
                attribute_map, info))
        return {'table': mapped_pydicts}
