import re
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class ShowEdgeVersionParser():

    """
    Class for parsing the data received from "show version"
    command executed on NSX Edge VM
    >>> import pprint
    >>> showEdgeVersionParser = ShowEdgeVersionParser()
    >>> raw_data= '''
    ... Name: NSX Edge
    ... Version: 7.0.0.0.0
    ... Build Number: 2252106
    ... Kernel: 3.2.62'''
    >>> py_dict=showEdgeVersionParser.get_parsed_data(raw_data)
    >>> pprint.pprint(py_dict)
    {'build_number': '2252106',
     'kernel': '3.2.62',
     'name': 'NSX Edge',
     'version': '7.0.0.0.0'}
    """

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

        for l in lines:
            (key, value) = l.split(':')
            pydict[re.sub(" +", ' ', key.strip().lower().replace(" ", "_"))] = \
                value.strip()

        pylogger.info("Output of Show Version command after parsing")
        pylogger.info(pydict)

        return pydict

if __name__ == '__main__':
    import doctest
    doctest.testmod()
