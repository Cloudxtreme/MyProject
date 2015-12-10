class ListProcessesParser:

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

        data = data[2:]
        data = data[:-1]

        pydicts = []
        result_count = 0
        for line in data:
            pydict = dict()
            columns = line.split()
            pydict.update({'pid': columns[0]})
            pydict.update({'runtime': columns[1]})
            pydict.update({'tty': columns[2]})
            pydict.update({'process_name': columns[3]})
            pydicts.append(pydict)
            result_count += 1

        parsed_data = {'result_count': result_count, 'results': pydicts}

        return parsed_data
