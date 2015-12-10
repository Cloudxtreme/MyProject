import re
import vmware.common.global_config as global_config
pylogger = global_config.pylogger


class ShowInterfaceNSXParser:

    def get_parsed_data(self, command_response, vnic_name):
        data = []
        data = self.sanity_check(command_response)
        pydict = dict()
        if not data:
            pydict.update({'vnic_state': "Informative Error:"})
            pydict.update({'ipv4': "Command returned either "
                                   "ERROR NOT FOUND or no output"})
            return pydict

        # IP Address Regex
        ipv4_regex = "\s+(\d+\.\d+\.\d+\.\d+)"
        match_ipv4 = re.search(ipv4_regex, data, re.IGNORECASE)
        if match_ipv4:
            ipv4_ip = match_ipv4.group(1)
        else:
            pylogger.warn("No IP address found in output. Using None")
            ipv4_ip = None
        # Interface Status Regex
        interface_status_regex = vnic_name + ".*is\s+(up|down),"
        match = re.search(interface_status_regex, data, re.IGNORECASE)
        if match:
            vnic_state = match.group(1)
        else:
            pylogger.warn("No match found for vnic_state. Using None.")
            vnic_state = None

        pydict.update({'vnic_state': vnic_state})
        pydict.update({'ip4': ipv4_ip})
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