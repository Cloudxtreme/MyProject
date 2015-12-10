class ShowProcessMonitorParser:

    def get_parsed_data(self, input, delimiter=' '):
        pydict = dict()

        ''' raw_payload received from pexpect
        #
        # Tasks:^[(B^[[m^[[39;49m^[(B^[[m  97 ^[(B^[[m^[[39;49mtotal,^[(B^[[m^[
        # [39;49m^[(B^[[m   8 ^[(B^[[m^[[39;49mrunning,^[(B^[[m^[[39;49m^[(B^[[
        # m  89 ^[(B^[[m^[[39;49msleeping,^[(B^[[m^[[39;49m^[(B^[[m   0 ^[(B^[[
        # m^[[39;49mstopped,^[(B^[[m^[[39;49m^[(B^[[m   0 ^[(B^[[m^[[39;49mzomb
        # ie^[(B^[[m^[[39;49m^[[K
        # Cpu(s):^[(B^[[m^[[39;49m^[(B^[[m 91.9%^[(B^[[m^[[39;49mus,^[(B^[[m^[[
        # 39;49m^[(B^[[m  7.5%^[(B^[[m^[[39;49msy,^[(B^[[m^[[39;49m^[(B^[[m  0.
        # [(B^[[m^[[39;49m^[[K
        #
        '''

        # Removing special characters from raw_payload
        data = str.replace(input, '^[(B^[[m', '')
        data = str.replace(data, '^[[39;49m', '')
        data = str.replace(data, '^[[K', '')

        ''' raw_payload after removing special characters
        #
        # Tasks:  97 total,   8 running,  89 sleeping,   0 stopped,   0 zombie
        # Cpu(s): 92.0%us,  7.5%sy,  0.0%ni,  0.6%id,  0.0%wa,  0.0%hi,  0.0%si
        #   , 0.0%st
        # Mem:  12283912k total,  2354060k used,  9929852k free,   125444k
        #  buffers
        # Swap:  2097148k total,        0k used,  2097148k free,   205700k
        #  cached
        #
        '''

        lines = data.split("\n")
        if ((len(lines) > 0) and
                ((lines[0].upper().find("ERROR") > 0) or
                    (lines[0].upper().find("NOT FOUND") > 0) or
                    (len(lines) == 1 and lines[0].strip() == ""))):
            return pydict

        # Parsing 'Tasks' row
        tasks = lines[1].split(":")[1]
        pydict.update({'tasks': self._process_row(tasks)})

        # Parsing 'Cpu(s)' row
        cpus = lines[2].split(":")[1]
        pydict.update({'cpu': self._process_row(cpus, '%')})

        # Parsing 'mem' row
        mem = lines[3].split(":")[1]
        pydict.update({'mem': self._process_row(mem)})

        # Parsing 'swap' row
        swap = lines[4].split(":")[1]
        pydict.update({'swap': self._process_row(swap)})

        return pydict

    def _process_row(self, item, split_with=None):
        pydict = dict()
        item_list = item.split(",")
        for item in item_list:
            value, name = item.strip().split(split_with)
            pydict.update({name: value})
        return pydict
