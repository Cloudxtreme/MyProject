class ListLogFilesParser:

    def get_parsed_data(self, input, delimiter=' '):
        data = []
        lines = input.strip().split("\n")

        if ((len(lines) > 0) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[0].upper().find("NOT FOUND") > 0) or
                                  (len(lines) == 1
                                   and lines[0].strip() == ""))):
            return data

        for line in lines:
            if line.strip() != "":
                data.append(line.strip())

        data = data[:-1]

        pydicts = []
        result_count = 0
        for line in data:
            pydict = dict()
            columns = line.split()
            pydict.update({'file_name': columns[0]})
            pydicts.append(pydict)
            result_count += 1

        parsed_data = {'file_count': result_count, 'files': pydicts}

        return parsed_data
