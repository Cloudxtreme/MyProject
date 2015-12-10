import re
import vmware.common.global_config as global_config
pylogger = global_config.pylogger


class ShowFilePresenceParser:

    def get_parsed_data(self, command_response, file_name):

        lines = command_response.strip().splitlines()
        if ((len(lines) > 0) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[0].upper().find("NOT FOUND") > 0) or
                                  (len(lines) == 1
                                   and lines[0].strip() == ""))):
            pylogger.debug('Command returned either ERROR or NOT FOUND '
                           'or no output')
            raise Exception('Command returned either ERROR or NOT FOUND '
                            'or no output')

        if((not re.search("No such file", command_response)) and
                (re.search(file_name, command_response))):
            file_present = "True"
        else:
            file_present = "False"
        pydict = dict(file_present=file_present)
        return pydict
