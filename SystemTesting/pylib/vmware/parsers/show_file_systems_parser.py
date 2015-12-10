import re
import vmware.common.global_config as global_config
pylogger = global_config.pylogger


class ShowFileSystemsParser:

    def get_parsed_data(self, command_response, delimiter=' '):

        lines = command_response.strip().split("\n")
        if ((len(lines) > 0) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[0].upper().find("NOT FOUND") > 0) or
                                  (len(lines) == 1
                                   and lines[0].strip() == ""))):
            pylogger.warn('Command returned either ERROR or NOT FOUND '
                          'or no output')
            raise Exception('Command returned either ERROR or NOT FOUND '
                            'or no output')

        pydict = dict()
        sda2_size = str(long(re.findall("(\d+) +\d+ +disk +rw +/dev/sda2",
                                        command_response)[0])/1000000000)+"GB"
        tmpfs_size = str(long(re.findall("(\d+) +\d+ +disk +rw +tmpfs",
                                         command_response)[0])/1000000000)+"GB"
        sda6_size = str(long(re.findall("(\d+) +\d+ +disk +rw +/dev/sda6",
                                        command_response)[0])/1000000000)+"GB"
        sda8_size = str(long(re.findall("(\d+) +\d+ +disk +rw +/dev/sda8",
                                        command_response)[0])/1000000000)+"GB"

        pydict.update({'sda2_size': sda2_size})
        pydict.update({'tmpfs_size': tmpfs_size})
        pydict.update({'sda6_size': sda6_size})
        pydict.update({'sda8_size': sda8_size})

        return pydict
