# All Horizontal data parseing classes go in this file

class HorizontalTableParser:
    """
    To parse the horizontal table, like:

        VNI      IP              MAC               Connection-ID
        6796     192.168.139.11  00:50:56:b2:30:6e 1
        6796     192.168.138.131 00:50:56:b2:40:33 2
        6796     192.168.139.201 00:50:56:b2:75:d1 3
    """

    def get_parsed_data(self, input, skip_head=None, skip_tail=None,
                        header_keys=None):
        '''
        calling the get_parsed_data function will return a hash array while
        each array entry is a hash, based on above sample, the return data will be:
        [
          {VNI=6796, IP=192.168.139.11, MAC=00:50:...6e, Connection-ID=1},
          ...
          {VNI=6796, IP=192.168.139.201, MAC=00;50:..d1, Connection-ID=3}
        ]
        @param input output from the CLi execution result
        '''
        data = []
        lines = input.strip().split("\n")
        if ((len(lines) > 0) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[0].upper().find("NOT FOUND") > 0) or
                                  (len(lines) == 1 and lines[0] == ""))):
            return data

        header_index = 0
        if skip_head:
            header_index = skip_head
        if header_index >= len(lines):
            pylogger.warning("Tried to get header of table at line number: "
                             "%s, but there are only %s lines. Returning "
                             "an empty table, but check your parsing logic."
                             % (header_index + 1, len(lines)))
            return data

        tail_index = len(lines)
        if skip_tail:
            tail_index = tail_index - skip_tail

        for line in lines[header_index:tail_index]:
            if (line.strip() != ""):
                elements = line.split()
                data.append(elements)

        table  = data

        if header_keys:
            header = header_keys
        else:
            header = table[0]
            del table[0]

        pydicts = []
        for line in table:
            pydict = {}
            for i in range(0, len(header)):
                pydict.update({header[i]:line[i]})
            pydicts.append(pydict)
        return pydicts

if __name__ == '__main__':
    hor = HorizontalTableParser()
    input = """
        VNI      IP              MAC               Connection-ID
        6796     192.168.139.11  00:50:56:b2:30:6e 1
        6796     192.168.138.131 00:50:56:b2:40:33 2
        6796     192.168.139.201 00:50:56:b2:75:d1 3
    """
    print hor.get_parsed_data(input)
    input = """
            """
    print hor.get_parsed_data(input)
    input = """

            """
    print hor.get_parsed_data(input)
    input = """
            Error: Not found
            """
    print hor.get_parsed_data(input)
