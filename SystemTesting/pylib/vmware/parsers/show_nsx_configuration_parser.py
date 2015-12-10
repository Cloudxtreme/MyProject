import re
import vmware.common.global_config as global_config
pylogger = global_config.pylogger


class ShowNSXConfigurationParser:
    """
    Class for parsing the data received from "show configuration"
    command executed on NSX Controller VM
    >>> import pprint
    >>> show_nsx_configuration = ShowNSXConfigurationParser()
    >>> raw_data= '''localhost> show configuration
    ... !
    ... hostname localhost.localdom
    ... ip route 0.0.0.0/0 10.10.3.1
    ... ntp server 0.ubuntu.pool.ntp.org
    ... ntp server 1.ubuntu.pool.ntp.org
    ... ntp server 2.ubuntu.pool.ntp.org
    ... ntp server 3.ubuntu.pool.ntp.org
    ... ntp server ntp.ubuntu.com
    ... !
    ... !
    ... ip aaddress 10.10.3.4/24
    ... localhost>'''
    >>> py_dict=show_nsx_configuration.get_parsed_data(raw_data)
    >>> pprint.pprint(py_dict)
        {'ipv4': '10.10.3.4'],
        'ntp_server': 'ntp.ubuntu.com'}
    """

    def get_parsed_data(self, command_response, delimiter=' '):
        data = []
        data = self.sanity_check(command_response)
        pydict = dict()

        if not data:
            pydict.update({'ntp_server': "Informative Error:"})
            pydict.update({'ipv4': "Command returned either "
                                   "ERROR NOT FOUND or no output"})
            return pydict

        # IP Address Regex
        ipv4_regex = "\s+(\d+\.\d+\.\d+\.\d+)"
        match_ipv4 = re.findall(ipv4_regex, data, re.IGNORECASE)
        if len(match_ipv4) == 0:
            pylogger.warn("No IP address found in output. Using None")
            pydict.update({'ipv4': "No IP address found in output."})
            pydict.update({'ntp_server': "Informative Error:"})
            return pydict
        else:
            ipv4 = match_ipv4[2]

        # NTP server Regex
        ntp_server_regex = "\s(\w+\.\w+\.\w+)\n"
        match_state = re.search(ntp_server_regex, data, re.IGNORECASE)
        if match_state:
            ntp_server = match_state.group(1)
        else:
            pylogger.warn("No IP address found in output. Using None")
            pydict.update({'ipv4': "No IP address found in output."})
            pydict.update({'ntp_server': "Informative Error:"})
            return pydict

        # Update values in pydict
        pydict.update({'ipv4': ipv4})
        pydict.update({'ntp_server': ntp_server})
        return pydict

    def sanity_check(self, command_response):
        data = []
        lines = command_response.strip().split("\n")
        if ((len(lines) > 0) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[0].upper().find("NOT FOUND") > 0) or
                                  (len(lines) == 1
                                   and lines[0].strip() == ""))):
            return data
        data = command_response
        return data
