# All Vertical data parseing classes go in this file
import copy

class VerticalTableParser:
    """
    To parse the vertical table, like:
        nvp-controller # show control-cluster core cluster-param divvy_num_nodes_required
        divvy_num_nodes_required: 1

    or ~ # net-vdl2 -l
    VXLAN Global States:
            Control plane Out-Of-Sync:      No
            UDP port:       8472

    VXLAN VDS:      1-vds-425
            VDS ID: 70 74 03 50 34 64 09 f6-1c b7 b0 5f 05 39 57 b9
            MTU:    1600
            Segment ID:     172.19.0.0
            Gateway IP:     172.19.0.1
            Gateway MAC:    00:09:7b:dc:e8:00
            Vmknic count:   2
                    VXLAN vmknic:   vmk1
                            VDS port ID:    4
                            Switch port ID: 50331655
                            Endpoint ID:    0
                            VLAN ID:        19
                            IP:             172.19.185.186
                            Netmask:        255.255.0.0
                            Segment ID:     172.19.0.0
                            IP acquire timeout:     0
                            Multicast group count:  0
                    VXLAN vmknic:   vmk2
                            VDS port ID:    5
                            Switch port ID: 60331655
                            Endpoint ID:    0
                            VLAN ID:        29
                            IP:             172.19.185.187
                            Netmask:        255.255.0.0
                            Segment ID:     172.19.0.0
                            IP acquire timeout:     0
                            Multicast group count:  0
            Network count:  3
                    VXLAN network:  5469
                            Multicast IP:   N/A (headend replication)
                            Control plane:  Enabled (multicast proxy,ARP proxy)
                            Controller:     10.24.29.58 (up)
                            MAC entry count:        0
                            ARP entry count:        0
                            Port count:     2
                    VXLAN network:  5470
                            Multicast IP:   239.0.0.102
                            Control plane:  Enabled (ARP proxy)
                            Controller:     10.24.29.58 (up)
                            MAC entry count:        0
                            ARP entry count:        0
                            Port count:     2
                    VXLAN network:  5468
                            Multicast IP:   239.0.0.101
                            Control plane:  Disabled
                            MAC entry count:        0
                            ARP entry count:        0
                            Port count:     2

    VXLAN VDS:      2-vds-725
            VDS ID: 70 74 03 50 34 64 09 f6-1c b7 b0 5f 05 39 57 b9
            MTU:    1600
            ...
    """

    def get_parsed_data(self, input, delimiter=':'):
        '''
        @param input output from the CLi execution result

        calling the get_parsed_data function will return array including hash
        why using array as the top structure, reason:
            1. compatible with HorizontalTableParser which use the array
            2. Some key maybe duplicated, like following 'VXLAN VDS'

        after prase, the parsed result will be the following structure:
        [
            {'VXLAN Global States':
                [
                    {'Control plane Out-Of-Sync': 'No'},
                    {'UDP port': '8472'}
                ]
            },
            {'VXLAN VDS':
                [
                    {'VXLAN VDS': '1-vds-425'},
                    {'VDS ID': '70 74 03 50 34 64 09 f6-1c b7 b0 5f 05 39 57 b9'},
                    {'MTU': '1600'},
                    {'Segment ID': '172.19.0.0'},
                    {'Gateway IP': '172.19.0.1'},
                    {'Gateway MAC': '00:09:7b:dc:e8:00'},
                    {'Vmknic count':
                        [
                            {'Vmknic count': '2'},
                            {'VXLAN vmknic':
                                [
                                    {'VXLAN vmknic': 'vmk1'},
                                    {'VDS port ID': '4'},
                                    {'Switch port ID': '50331655'},
                                    {'Endpoint ID': '0'},
                                    {'VLAN ID': '19'},
                                    {'IP': '172.19.185.186'},
                                    {'Netmask': '255.255.0.0'},
                                    {'Segment ID': '172.19.0.0'},
                                    {'IP acquire timeout': '0'},
                                    {'Multicast group count': '0'}
                                ]
                            },
                            {'VXLAN vmknic':
                                [
                                    {'VXLAN vmknic': 'vmk2'},
                                    {'VDS port ID': '5'},
                                    {'Switch port ID': '60331655'},
                                    {'Endpoint ID': '0'},
                                    {'VLAN ID': '29'},
                                    {'IP': '172.19.185.187'},
                                    {'Netmask': '255.255.0.0'},
                                    {'Segment ID': '172.19.0.0'},
                                    {'IP acquire timeout': '0'},
                                    {'Multicast group count': '0'}
                                ]
                            }
                        ]
                    },
                    {'Network count':
                        [
                            {'Network count': '3'},
                            {'VXLAN network':
                                [
                                    {'VXLAN network': '5469'},
                                    {'Multicast IP': 'N/A (headend replication)'},
                                    {'Control plane': 'Enabled (multicast proxy,ARP proxy)'},
                                    {'Controller': '10.24.29.58 (up)'},
                                    {'MAC entry count': '0'},
                                    {'ARP entry count': '0'},
                                    {'Port count': '2'}
                                ]
                            },
                            {'VXLAN network':
                                [
                                    {'VXLAN network': '5470'},
                                    {'Multicast IP': '239.0.0.102'},
                                    {'Control plane': 'Enabled (ARP proxy)'},
                                    {'Controller': '10.24.29.58 (up)'},
                                    {'MAC entry count': '0'},
                                    {'ARP entry count': '0'},
                                    {'Port count': '2'}
                                ]
                            },
                            {'VXLAN network':
                                [
                                    {'VXLAN network': '5468'},
                                    {'Multicast IP': '239.0.0.101'},
                                    {'Control plane': 'Disabled'},
                                    {'MAC entry count': '0'},
                                    {'ARP entry count': '0'},
                                    {'Port count': '2'}
                                ]
                            }
                        ]
                    }
                ]
            }
            {'VXLAN VDS':
                [
                    {'VXLAN VDS': '2-vds-725'},
                    ...
        ]
        '''
        data = []
        lines = input.strip().split("\n")
        if ((len(lines) > 0) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[0].upper().find("NOT FOUND") > 0) or
                                  (len(lines) == 1 and lines[0].strip() == ""))):
            return data
        for line in lines:
            if (line.strip() != ""):
                data.append(line.rstrip())
        """
        To compatible with horizontal parser, vertical parser also return a array with
        the hash. Thus the base_cli_schema need no change to apply for both horizontal
        py_dict and vertical py_dict
        """

        pydicts = self.recurse_vertical_data_parser(data, delimiter)
        return pydicts

    def recurse_vertical_data_parser(self, input, delimiter=':'):
        data = []
        currentBlockIndent = self.get_indent(input[0])
        index = 0
        while index < len(input):
            if (index + 1 != len(input) and (self.get_indent(input[index + 1]) > currentBlockIndent)): #new block

                pydict = {}
                (key, value) = input[index].split(delimiter)

                newInput = []
                index = index + 1
                while index != len(input) and self.get_indent(input[index]) > currentBlockIndent:
                    newInput.append(input[index])
                    index = index + 1
                newBlockHash = self.recurse_vertical_data_parser(newInput, delimiter)
                if value.strip() != '':
                    newBlockHash.insert(0, {key.strip():value.strip()})
                pydict.update({key.strip():copy.deepcopy(newBlockHash)})
                data.append({key.strip():newBlockHash})
            else:
                pydict = {}
                (key, value) = input[index].split(delimiter, 1)
                pydict.update({key.strip():value.strip()})
                data.append(pydict)
                index = index + 1
        return data

    def get_indent(self, str):
        subStr = str.lstrip()
        return str.find(subStr)

if __name__ == '__main__':
    ver = VerticalTableParser()
    input = """
        divvy_num_nodes_required: 1

    """
    print ver.get_parsed_data(input)
    print ver.get_parsed_data(input, delimiter=':')
    input = """
    VXLAN Global States:
            Control plane Out-Of-Sync:      No
            UDP port:       8472

    VXLAN VDS:      1-vds-425
            VDS ID: 70 74 03 50 34 64 09 f6-1c b7 b0 5f 05 39 57 b9
            MTU:    1600
            Segment ID:     172.19.0.0
            Gateway IP:     172.19.0.1
            Gateway MAC:    00:09:7b:dc:e8:00
            Vmknic count:   2
                    VXLAN vmknic:   vmk1
                            VDS port ID:    4
                            Switch port ID: 50331655
                            Endpoint ID:    0
                            VLAN ID:        19
                            IP:             172.19.185.186
                            Netmask:        255.255.0.0
                            Segment ID:     172.19.0.0
                            IP acquire timeout:     0
                            Multicast group count:  0
                    VXLAN vmknic:   vmk2
                            VDS port ID:    5
                            Switch port ID: 60331655
                            Endpoint ID:    0
                            VLAN ID:        29
                            IP:             172.19.185.187
                            Netmask:        255.255.0.0
                            Segment ID:     172.19.0.0
                            IP acquire timeout:     0
                            Multicast group count:  0
            Network count:  3
                    VXLAN network:  5469
                            Multicast IP:   N/A (headend replication)
                            Control plane:  Enabled (multicast proxy,ARP proxy)
                            Controller:     10.24.29.58 (up)
                            MAC entry count:        0
                            ARP entry count:        0
                            Port count:     2
                    VXLAN network:  5470
                            Multicast IP:   239.0.0.102
                            Control plane:  Enabled (ARP proxy)
                            Controller:     10.24.29.58 (up)
                            MAC entry count:        0
                            ARP entry count:        0
                            Port count:     2
                    VXLAN network:  5468
                            Multicast IP:   239.0.0.101
                            Control plane:  Disabled
                            MAC entry count:        0
                            ARP entry count:        0
                            Port count:     2
        """
    print ver.get_parsed_data(input)
