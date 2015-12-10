# All Horizontal data parseing classes go in this file

class TorEmulatorParser:
    """
    To parse the TOR emulator related cli output, like:

    root# vtep-ctl list tunnel
    _uuid               : b7e7aa4a-765f-4e74-a6d1-4cd57e563cd0
    bfd_config_local    : {bfd_dst_ip="169.254.1.0", bfd_dst_mac="00:23:20:00:00:01"}
    bfd_params          : {enable="true", forwarding_if_rx="true", min_rx="700"}
    bfd_config_remote   : {}
    bfd_status          : {diagnostic="No Diagnostic", enabled="true", forwarding="true", remote_diagnostic="No Diagnostic", remote_state=up, state=up}
    local               : ab4948af-7bdf-422e-ae6f-b4d8f3630d6a
    remote              : 57dc1813-dd99-4de2-adf4-8cc1d8ecb21d

    _uuid               : c7e7aa4a-765f-4e74-a6d1-4cd57e563cd0
    bfd_config_local    : {bfd_dst_ip="169.254.1.1", bfd_dst_mac="00:23:20:00:00:01"}
    bfd_params          : {enable="true", forwarding_if_rx="true", min_rx="700"}
    bfd_config_remote   : {}
    bfd_status          : {diagnostic="No Diagnostic", enabled="true", forwarding="true", remote_diagnostic="No Diagnostic", remote_state=up, state=up}
    local               : ab4948af-7bdf-422e-ae6f-b4d8f3630d6a
    remote              : 57dc1813-dd99-4de2-adf4-8cc1d8ecb21d
    """

    def get_parsed_data(self, input):
        '''
        calling the get_parsed_data function will return a hash array while
        each array entry is a hash, based on above sample, the return data will be:
        [
          {'bfd_status': {'state': 'up', 'remote_state': 'up', 'remote_diagnostic': '"No Diagnostic"', 'forwarding': '"true"', 'enabled': '"true"', 'diagnostic': '"No Diagnostic"'},
          'remote': '57dc1813-dd99-4de2-adf4-8cc1d8ecb21d',
          '_uuid': 'b7e7aa4a-765f-4e74-a6d1-4cd57e563cd0',
          'local': 'ab4948af-7bdf-422e-ae6f-b4d8f3630d6a',
          'bfd_config_local': {'bfd_dst_mac': '"00:23:20:00:00:01"', 'bfd_dst_ip': '"169.254.1.0"'},
          'bfd_params': {'forwarding_if_rx': '"true"', 'enable': '"true"', 'min_rx': '"700"'},
          'bfd_config_remote': '{}'},


          {'bfd_status': {'state': 'up', 'remote_state': 'up', 'remote_diagnostic': '"No Diagnostic"', 'forwarding': '"true"', 'enabled': '"true"', 'diagnostic': '"No Diagnostic"'},
           'remote': '57dc1813-dd99-4de2-adf4-8cc1d8ecb21d',
           '_uuid': 'c7e7aa4a-765f-4e74-a6d1-4cd57e563cd0',
           'local': 'ab4948af-7bdf-422e-ae6f-b4d8f3630d6a',
           'bfd_config_local': {'bfd_dst_mac': '"00:23:20:00:00:01"', 'bfd_dst_ip': '"169.254.1.1"'},
           'bfd_params': {'forwarding_if_rx': '"true"', 'enable': '"true"', 'min_rx': '"700"'},
           'bfd_config_remote': '{}'}
        ]
        @param input output from the CLi execution result
        '''
        output = []
        lines = input.strip().split("\n")
        if ((len(lines) > 0) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[0].upper().find("NOT FOUND") > 0) or
                                  (len(lines) == 1 and lines[0] == ""))):
            return output

        # append one extra empty line because we use empty line to
        # differentiate each element
        if (lines[-1] != ""):
            lines.append("")

        element = {}
        for line in lines:
            if (line.strip() == ""):
                if (element != {}):
                    output.append(element)
                element = {}
            else:
                key, value = line.split(":", 1)
                value = self.get_sub_element(value.strip())
                element.update({key.strip(): value})
        return output

    def get_sub_element(self, hash_str):
        """
        hash_str like {diagnostic="No Diagnostic", enabled="true",
        forwarding="true", remote_diagnostic="No Diagnostic",
        remote_state=up, state=up}
        """
        if (hash_str[0] == '{' and hash_str[1] != "}"):
            sub_element = {}
            hash_str = hash_str[1:-1]
            elements = hash_str.split(",")
            for element in elements:
                key, value = element.split("=", 1)
                sub_element.update({key.strip(): value.strip()})
            return sub_element
        else:
            return hash_str

if __name__ == '__main__':
    tor = TorEmulatorParser()
    input = """_uuid               : b7e7aa4a-765f-4e74-a6d1-4cd57e563cd0
    bfd_config_local    : {bfd_dst_ip="169.254.1.0", bfd_dst_mac="00:23:20:00:00:01"}
    bfd_params          : {enable="true", forwarding_if_rx="true", min_rx="700"}
    bfd_config_remote   : {}
    bfd_status          : {diagnostic="No Diagnostic", enabled="true", forwarding="true", remote_diagnostic="No Diagnostic", remote_state=up, state=up}
    local               : ab4948af-7bdf-422e-ae6f-b4d8f3630d6a
    remote              : 57dc1813-dd99-4de2-adf4-8cc1d8ecb21d

    _uuid               : c7e7aa4a-765f-4e74-a6d1-4cd57e563cd0
    bfd_config_local    : {bfd_dst_ip="169.254.1.1", bfd_dst_mac="00:23:20:00:00:01"}
    bfd_params          : {enable="true", forwarding_if_rx="true", min_rx="700"}
    bfd_config_remote   : {}
    bfd_status          : {diagnostic="No Diagnostic", enabled="true", forwarding="true", remote_diagnostic="No Diagnostic", remote_state=up, state=up}
    local               : ab4948af-7bdf-422e-ae6f-b4d8f3630d6a
    remote              : 57dc1813-dd99-4de2-adf4-8cc1d8ecb21d
    """
    print tor.get_parsed_data(input)
