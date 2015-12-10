import vmware.common.global_config as global_config
import re
pylogger = global_config.pylogger


class ShowIpRouteParser:

    def get_parsed_data(self, command_response, delimiter=' '):

        lines = command_response.strip().split("\n")
        pydicts = []

        if ((len(lines) > 0) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[0].upper().find("NOT FOUND") > 0) or
                                  (len(lines) == 1
                                   and lines[0].strip() == ""))):
            pylogger.warn('Command returned either ERROR or NOT FOUND '
                          'or no output')
            raise Exception('Command returned either ERROR or NOT FOUND '
                            'or no output')

        matches = re.findall("(\d+.\d+.\d+.\d+/\d+|\w+) via "
                             "(\d+.\d+.\d+.\d+) \w+", command_response)

        for item in matches:
            pydict = dict()
            pydict.update({'cidr': item[0]})
            pydict.update({'ip': item[1]})
            pydicts.append(pydict)

        return {'table': pydicts}
