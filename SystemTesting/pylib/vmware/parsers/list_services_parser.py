class ListServicesParser:

    def get_parsed_data(self, input, delimiter=' '):
        data = []
        lines = input.strip().split("\n")
        if ((len(lines) > 0) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[0].upper().find("NOT FOUND") > 0) or
                                  (len(lines) == 1
                                   and lines[0].strip() == ""))):
            return {'failure': input}
        for line in lines:
            if line.strip() != "":
                data.append(line.strip())

        data = data[1:]
        data = data[:-1]
        pydicts = []
        pydict = dict()
        for line in data:
            line.split()
            (key, value) = line.split(delimiter, 1)
            key = key.strip()
            value = value.strip()
            if key == 'Service name':
                pydict.update({'service_name': value.strip()})
            else:
                pydict.update({'service_state': value.strip()})
                pydicts.append(pydict)
                pydict = dict()
        parsed_data = {'table': pydicts}
        return parsed_data