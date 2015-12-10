class ShowVersionParser:

    def get_parsed_data(self, input, delimiter=' '):
        pydict = dict()
        lines = input.strip().split("\n")
        if ((len(lines) > 0) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[0].upper().find("NOT FOUND") > 0) or
                                  (len(lines) == 1
                                   and lines[0].strip() == ""))):
            pydict.update({'tag': "Informative Error:"})
            pydict.update({'version': "Command returned either ERROR "
                                      "NOT FOUND or no output"})
            return pydict
        data = lines[:-4][0]
        (key, value) = data.split(',', 2)[1].split()
        pydict.update({'tag': key.strip()})
        pydict.update({'version': value.strip()})
        return pydict