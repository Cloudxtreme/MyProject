import re
import vmware.common.global_config as global_config
pylogger = global_config.pylogger


class ShowCertThumbprintParser:

    def get_parsed_data(self, command_response, thumbprint):
        data = []
        data = self.sanity_check(command_response)
        pydict = dict()
        if not data:
            pylogger.warn("Command return either ERROR or NOT FOUND "
                          "or no output")
            return pydict
        if thumbprint != 'thumbprint':
            regex = re.compile('^.*(BEGIN\sCERTIFICATE)((.*\n)+\-*)'
                               '(END\sCERTIFICATE)')
            match = regex.findall(data)
            if 'BEGIN CERTIFICATE' in match[0] and 'END CERTIFICATE' in \
                    match[0]:
                pydict.update({'cert_found': 'True'})
            else:
                pylogger.warn("Valid certificate not found. Returning False.")
                pydict.update({'cert_found': 'False'})
        else:
            regex = re.compile('[a-z0-9]*')
            match = regex.findall(data)[0]
            if match:
                pydict.update({'thumbprint_found': 'True'})
            else:
                pylogger.warn("Valid thumbprint not found. Returning False.")
                pydict.update({'thumbprint_found': 'False'})
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