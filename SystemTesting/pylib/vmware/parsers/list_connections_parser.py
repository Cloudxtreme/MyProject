class ListConnectionsParser:

    def get_parsed_data(self, input, delimiter=' '):
        data = []
        lines = input.strip().split("\n")
        if ((len(lines) > 0) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[0].upper().find("NOT FOUND") > 0) or
                                  (len(lines) == 1 and lines[0].strip() == ""))):
            return data
        for line in lines:
            if (line.strip() != ""):
                data.append(line)

        data = data[2:]
        data = data[:-2]

        pydicts = []
        for line in data:
            pydict = dict()
            value = line.split()
            pydict.update({'user':value[0]})
            pydict.update({'peer_host':value[1]})
            pydict.update({'peer_port':value[2]})
            pydict.update({'state':value[3]})
            pydicts.append(pydict)
        parsed_data = {'table': pydicts}
        return parsed_data