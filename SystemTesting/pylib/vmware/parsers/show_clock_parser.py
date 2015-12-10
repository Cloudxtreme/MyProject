import time


class ShowClockParser:

    def get_parsed_data(self, command_response, delimiter=' '):
        """
        >>> import pprint
        >>> parser = ShowClockParser()
        >>> sample_text = '''Thu Jul 02 2015 UTC 14:39:00.331
        ...
        ... nsxmanager'''
        >>> pprint.pprint(parser.get_parsed_data(sample_text))
        {'date': '02',
         'day': 'Thu',
         'hr_min_sec': '14:39:00',
         'month': '7',
         'timezone': 'UTC',
         'year': '2015'}
        """
        pydict = dict()

        lines = command_response.strip().split("\n")
        if ((len(lines) > 0) and
                ((lines[0].upper().find("ERROR") > 0) or
                    (lines[0].upper().find("NOT FOUND") > 0) or
                    (len(lines) == 1 and lines[0].strip() == ""))):
            return pydict

        ###
        # nsxmanager> show clock
        # 06:37:54.147 UTC Wed Nov 05 2014
        ###

        # Splitting show clock CLI output to update pydict
        show_clock_out = lines[0].split()
        nsxmgr_time = show_clock_out[-1].split('.')
        pydict.update({'hr_min_sec': nsxmgr_time[0]})
        pydict.update({'date': show_clock_out[2]})
        pydict.update({'day': show_clock_out[0]})
        pydict.update({'timezone': show_clock_out[4]})
        pydict.update({'year': str(show_clock_out[3])})

        # Converting abbreviated month name into numerical value
        pydict.update(
            {'month': str(time.strptime(show_clock_out[1], '%b').tm_mon)})

        return pydict

if __name__ == '__main__':
    import doctest
    doctest.testmod()