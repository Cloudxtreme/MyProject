import re
import vmware.common.global_config as global_config
pylogger = global_config.pylogger


class ShowInterfacesNSXParser:

    def get_parsed_data(self, command_response, vnic_name):
        data = []
        data = self.sanity_check(command_response)
        pydict = dict()
        pydicts = []
        if not data:
            pydict.update({'vnic_state': "Informative Error:"})
            pydict.update({'ipv4': "Command returned either "
                                   "ERROR NOT FOUND or no output"})
            pydicts.append(pydict)
            parsed_data = {'interfaces': pydicts}
            return parsed_data

        # IP Address Regex
        ipv4_regex = "\s+(\d+\.\d+\.\d+\.\d+)"
        match_ipv4 = re.findall(ipv4_regex, data, re.IGNORECASE)
        if len(match_ipv4) == 0:
            pylogger.warn("No IP address found in output. Using None")
            pydict.update({'vnic_state': "Informative Error:"})
            pydict.update({'ipv4': "No IP address found in output."})
            pydicts.append(pydict)
            parsed_data = {'interfaces': pydicts}
            return parsed_data
        # Interface Status Regex
        interface_status_regex = vnic_name + ".*is\s+(up|down),"
        match_state = re.findall(interface_status_regex, data, re.IGNORECASE)
        if len(match_state) == 0:
            pylogger.warn("No match found for vnic_state. Using None")
            pydict.update({'vnic_state': "Informative Error:"})
            pydict.update({'ipv4': "No match found for vnic_state."})
            pydicts.append(pydict)
            parsed_data = {'interfaces': pydicts}
            return parsed_data

        pydicts = []
        for i in range(0, len(match_ipv4)):
            pydict = dict()
            pydict.update({'ipv4': match_ipv4[i]})
            pydict.update({'vnic_state': match_state[i]})
            pydicts.append(pydict)
        parsed_data = {'interfaces': pydicts}
        return parsed_data

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
