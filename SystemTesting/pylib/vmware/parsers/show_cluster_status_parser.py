import re
import vmware.common.global_config as global_config
pylogger = global_config.pylogger


class ShowClusterParser:

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
        nodes_in_cluster = re.findall("Number of nodes in management cluster: "
                                      "(\d+)", command_response)[0]
        node_list = re.findall("- (\d+.\d+.\d+.\d+)", command_response)
        node_1_ip = node_list[0]

        management_cluster_status = re.findall(
            "Management cluster status: (\w+)", command_response)

        control_cluster_status = re.findall(
            "Control cluster status: (\w+)", command_response)

        pydict.update({'node_1_ip': node_1_ip})
        pydict.update({'nodes_in_cluster': nodes_in_cluster})
        pydict.update({'management_cluster_status':
                       management_cluster_status[0].strip().lower()})
        pydict.update({'control_cluster_status':
                       control_cluster_status[0].strip().lower()})

        return pydict
