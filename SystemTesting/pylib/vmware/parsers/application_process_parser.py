class ApplicationProcessParser:

    def get_parsed_data(self, command_response, application_name):
        process_count = 0
        pydict = dict()
        lines = command_response.strip().split("\n")
        if ((len(lines) > 0) and ((lines[1].upper().find("ERROR") > 0) or
                                  (lines[1].upper().find("NOT FOUND") > 0) or
                                  (len(lines) == 1
                                   and lines[1].strip() == ""))):
            pydict.update({'application_name': "Informative Error:"})
            pydict.update({'process_count': "Command returned either ERROR "
                                            "NOT FOUND or no output"})
            return pydict
        process_count = lines[0]
        pydict.update({'application_name': application_name.strip()})
        pydict.update({'process_count': process_count})
        return pydict
