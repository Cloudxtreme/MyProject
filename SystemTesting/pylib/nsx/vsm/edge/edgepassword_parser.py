# All Horizontal data parsing classes go in this file

class EdgePasswordParser:
    """
    Sample output dump: To parse the output, like:

    Edge root password:
        edge-32 -> NcoSBAE682@fg7
        edge-33 -> zQyHv41^BGFYt

    OR

    Edge root password:
       No Edge is deployed so far
    """

    # noinspection PyRedundantParentheses
    def get_parsed_data(self, input):
        '''
        calling the get_parsed_data function will return a hash array while
        each array entry is a hash, based on above sample, the return data will be:
        [
          {'password': 'NcoSBAE682@fg7', 'Edge': 'edge-32'},

          {'password': 'zQyHv41^BGFYt', 'Edge': 'edge-33'}
         ]
        @param input output from the CLi execution result
        '''
        data = []
        lines = input.strip().split("\n")

        if ((len(lines) > 0) and ((lines[1].find("No Edge is deployed so far") > 0))):
            return data

        for line in lines:
            line = line.replace(":", "")
            if (line.strip() != ""):
                elements = line.split()
                data.append(elements)

        table = data
        header = table[0]
        del table[0]
        pydicts = []
        for line in table:
            pydict = {}
            for i in range(0, len(header)):
                if i == 1:
                    continue
                pydict.update({header[i].lower(): line[i]})
            pydicts.append(pydict)
        return pydicts


if __name__ == '__main__':
    hor = EdgePasswordParser()

    input = """
            Edge root password:
                  No Edge is deployed so far.
            """
    print hor.get_parsed_data(input)

    input = """
            Edge root password:
                  edge-32 -> NcoSBAE682@fg7
                  edge-33 -> zQyHv41^BGFYt
            """
    print hor.get_parsed_data(input)






