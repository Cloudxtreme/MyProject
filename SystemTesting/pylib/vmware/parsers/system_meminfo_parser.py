class SystemMeminfoParser:

    def get_parsed_data(self, input, delimiter=' '):
        pydict = dict()

        lines = input.strip().split("\n")
        if ((len(lines) > 0) and
                ((lines[0].upper().find("ERROR") > 0) or
                    (lines[0].upper().find("NOT FOUND") > 0) or
                    (len(lines) == 1 and lines[0].strip() == ""))):
            return pydict

        '''
        vdnet-nsxmanager> st e
        Password:
        [root@vdnet-nsxmanager ~]# cat /proc/meminfo
        MemTotal:       12283912 kB
        MemFree:         9288140 kB
        .
        SwapTotal:       2097148 kB
        SwapFree:        2097148 kB
        .
        '''

        # Removing last line
        lines = lines[:-1]
        for line in lines:
            data, value = line.strip().split(':')
            if value.lower().find("kb") > 0:
                value = value.strip().split()[0] + 'k'
            pydict.update({data.lower(): value})

        return pydict