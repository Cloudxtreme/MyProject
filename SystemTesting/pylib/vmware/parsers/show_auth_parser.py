import vmware.common.global_config as global_config
pylogger = global_config.pylogger


class ShowAuthParser:

    def get_parsed_data(self, command_response, delimiter=' '):
        data = []
        data = self.sanity_check(command_response)
        pydict = dict()
        if not data:
            pylogger.warn("Command returned either ERROR or NOT FOUND"
                          "or no output")
            pydict.update({'authtype': ' '})
            return pydict
        authtype = data.split("\n")[0]
        pydict.update({'authtype': authtype})
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
