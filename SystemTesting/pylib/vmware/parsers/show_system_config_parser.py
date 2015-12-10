import re
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class ShowSystemConfig:
    def get_parsed_data(self, command_response, system_parameter):
        """
        >>> import pprint
        >>> parser = ShowSystemConfig()
        >>> sample_text = '''17:21:11 up 10 days,  1:59,  1 user,  load average: 0.24, 0.06, 0.06'''    # noqa
        >>> pprint.pprint(parser.get_parsed_data(sample_text, "uptime"))
        {'time_update': ['10', '1', '59']}
        """

        pydict = dict()
        lines = command_response.strip().split("\n")
        if ((len(lines) > 0) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[0].upper().find("NOT FOUND") > 0) or
                                  (len(lines) == 1
                                   and lines[0].strip() == ""))):
            pylogger.warn('Command returned either ERROR or NOT FOUND '
                          'or no output')
            raise Exception('Command returned either ERROR or NOT FOUND '
                            'or no output')

        if system_parameter == "cpu-stats":
            total_cpus = len(re.findall("processor\s+:\s\d+",
                                        command_response))
            pydict.update({'total_cpus': total_cpus})

        elif system_parameter == "memory-stats":
            memory_total_value = long(re.findall(
                "MemTotal:\s+(\d+)", command_response)[0]) / 1000000
            swap_total_value = long(re.findall("SwapTotal:\s+(\d+)",
                                               command_response)[0]) / 1000000
            pydict.update({'memory_total': memory_total_value})
            pydict.update({'swap_total': swap_total_value})

        elif system_parameter == "network-stats":
            packets_received = long(re.findall("(\d+) total packets received",
                                               command_response)[0])
            packets_sent = long(re.findall("(\d+) requests sent out",
                                           command_response)[0])
            pydict.update({'packets_received': packets_received})
            pydict.update({'packets_sent': packets_sent})

        elif system_parameter == "filesystem-stats":
            root_size = re.findall("/dev/mapper/nsx-root\s+(\d\.?\d*)G",
                                   command_response)[0]
            confbak_size = \
                re.findall("/dev/mapper/nsx-config__bak\s+(\d\.?\d*)G",
                           command_response)[0]
            config_size = re.findall("/dev/mapper/nsx-config\s+(\d\.?\d*)G",
                                     command_response)[0]
            image_size = re.findall("/dev/mapper/nsx-image\s+(\d\.?\d*)G",
                                    command_response)[0]

            pydict.update({'root_size': root_size})
            pydict.update({'confbak_size': confbak_size})
            pydict.update({'config_size': config_size})
            pydict.update({'image_size': image_size})

        elif system_parameter == "controller_storage":
            nsx_root = re.findall("/dev/mapper/nsx-root\s+(\d\.?\d*)G",
                                  command_response)[0]
            nsx_backup = re.findall("/dev/mapper/nsx-backup\s+(\d\.?\d*)G",
                                    command_response)[0]
            nsx_config = re.findall("/dev/mapper/nsx-config\s+(\d\.?\d*)G",
                                    command_response)[0]
            nsx_image = re.findall("/dev/mapper/nsx-image\s+(\d\.?\d*)G",
                                   command_response)[0]
            nsx_var = re.findall("/dev/mapper/nsx-var\s+(\d\.?\d*)G",
                                 command_response)[0]

            pydict.update({'nsx_root': nsx_root})
            pydict.update({'nsx_backup': nsx_backup})
            pydict.update({'nsx_config': nsx_config})
            pydict.update({'nsx_image': nsx_image})
            pydict.update({'nsx_var': nsx_var})

        elif system_parameter == "uptime":
            time_string = re.findall(".+ up([ *\d*:*\d*\,* *]*[a-z]*[\,]*"
                                     "[ *\d*:*\d*\,* *]*)\d+ user",
                                     command_response)[0].strip()
            time_update = re.findall("(\d+)", time_string)

            pydict.update({'time_update': time_update})

        return pydict

if __name__ == '__main__':
    import doctest
    doctest.testmod()
