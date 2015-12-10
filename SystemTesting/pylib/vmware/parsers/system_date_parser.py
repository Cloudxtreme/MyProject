import time


class SystemDateParser:

    def get_parsed_data(self, input, delimiter=' '):
        pydict = dict()

        lines = input.strip().split("\n")
        if ((len(lines) > 0) and
                ((lines[0].upper().find("ERROR") > 0) or
                    (lines[0].upper().find("NOT FOUND") > 0) or
                    (len(lines) == 1 and lines[0].strip() == ""))):
            return pydict

        ###
        # [root@nsxmanager ~]# date
        # Wed Nov  5 06:51:03 UTC 2014
        ###

        # Splitting date cmd output to update pydict
        sys_date_out = lines[0].split()
        sys_time = sys_date_out[3].split('.')
        pydict.update({'hr_min_sec': sys_time[0]})
        pydict.update({'date': sys_date_out[2]})
        pydict.update({'day': sys_date_out[0]})
        pydict.update({'timezone': sys_date_out[4]})
        pydict.update({'year': str(sys_date_out[5])})

        # Converting abbreviated month name into numerical value
        pydict.update(
            {'month': str(time.strptime(sys_date_out[1], '%b').tm_mon)})

        return pydict