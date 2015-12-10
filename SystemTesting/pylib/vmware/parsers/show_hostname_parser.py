import vmware.common.global_config as global_config
pylogger = global_config.pylogger


class ShowHostnameParser:

    def get_parsed_data(self, command_response, delimiter=' '):
        data = []
        data = self.sanity_check(command_response)
        pydict = dict()
        if not data:
            pylogger.warn("Command return either ERROR or NOT FOUND "
                          "or no output")
            pydict.update({'hostname': ' '})
            return pydict
        hostname = data.split("\n")[0]
        pydict.update({'hostname': hostname})
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