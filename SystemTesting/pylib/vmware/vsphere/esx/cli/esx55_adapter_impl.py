import vmware.interfaces.adapter_interface as adapter_interface
import vmware.common.global_config as global_config
import vmware.common.utilities as utilities
import vmware.parsers.horizontal_table_parser as horizontal_table_parser
import vmware.parsers.vertical_table_parser as vertical_table_parser
import vmware.schema.switch.vtep_table_schema as vtep_table_schema

pylogger = global_config.pylogger
horizontal_parser = horizontal_table_parser.HorizontalTableParser()
vertical_parser = vertical_table_parser.VerticalTableParser()


class ESX55AdapterImpl(adapter_interface.AdapterInterface):

    @classmethod
    def get_adapter_info(cls, client_object):
        """
        Returns parsed data as dictionary for all vmknic that exists on the
        host.
        """
        cmd = 'esxcfg-vmknic -l'
        header_keys = ['Interface', 'Port Group/DVPort', 'IP Family',
                       'IP Address', 'Netmask', 'Broadcast', 'MAC Address',
                       'MTU', 'TSO MSS', 'Enabled', 'Type']
        raw_data = client_object.connection.request(cmd).response_data
        horizontal_data = horizontal_parser.get_parsed_data(
            raw_data, expect_empty_fields=True,
            header_keys=header_keys)['table']

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

    @classmethod
    def get_vtep_detail(cls, client_object, **kwargs):
        """
        Returns parsed data as dictionary for all vtep(vxlan vmknic)
        information that exists on the host.
        """
        cmd = 'net-vdl2 -l'
        raw_data = client_object.connection.request(cmd).response_data
        vertical_data = vertical_parser.get_parsed_data(
            raw_data, delimiter=':\t', lowercase_data=False)['table']

        segmentid = None
        for key in vertical_data.keys():
            if 'vxlan vds' in key:
                segmentid = vertical_data.get(key)['Segment ID']
                break

        adapterinfo = cls.get_adapter_info(client_object)['table']
        merged_info = []
        for adpter in adapterinfo:
            if adpter['netstack'] == 'vxlan' and adpter['ip_family'] == 'IPv4':
                adpter.update({'segment_id': segmentid})
                merged_info.append(adpter)

        attribute_map = {
            'ip': 'adapter_ip',
            'mac': 'adapter_mac'
        }

        mapped_pydicts = []
        for info in merged_info:
            mapped_pydicts.append(utilities.map_attributes(attribute_map,
                                                           info))

        return vtep_table_schema.VtepTableSchema({'table': mapped_pydicts})