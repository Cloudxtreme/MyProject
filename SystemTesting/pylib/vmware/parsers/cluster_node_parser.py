import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class ClusterNodeParser(object):
    """
    To parse command get control-cluster status output, like:

    ~ # get control-cluster status
    This will strip the header of the returned table data.
    >>> import pprint
    >>> flat_vertical_parser = ClusterNodeParser()
    >>> raw_data = '''
    ...get control-cluster status
    ...-----------------------------------------------------------------------
    ...is master:     True
    ...in majority:   True
    ...uuid                                 address           status
    ...b4e3c4c0-300f-4d03-8df7-9ab871c42346 10.144.138.213    active
    ...2bb27469-5025-4675-941b-b213b009b5b6 10.144.139.127    active
    ...f803224c-8fb2-4b43-8f7c-e1cf469cf5fa 10.144.139.7      active
    ...------------------------------------------------------------------------
    ...
    ...wdc-vsphere-cf-fvt-139-dhcp127(config)
    ... '''
    >>> pprint.pprint(flat_vertical_parser.get_parsed_data(raw_data), width=78)
     {'cluster_nodes': [{'status': 'active',
                        'id_': 'b4e3c4c0-300f-4d03-8df7-9ab871c42346',
                        'controller_ip': '10.144.138.213'},
                        {'status': 'active',
                        'id_': '2bb27469-5025-4675-941b-b213b009b5b6',
                        'controller_ip': '10.144.139.127'},
                        {'status': 'active',
                        'id_': 'f803224c-8fb2-4b43-8f7c-e1cf469cf5fa',
                        'controller_ip': '10.144.139.7'}],
      'is master': 'true',
      'in majority': 'true'}
    """
    def get_parsed_data(self, raw_data, key_val_sep=None, key_sep=None):
        '''
        Parses the raw data table output where records are indented vertically.
        This will strip a row of the table if the key or the value is empty.
        @param raw_data: Output from the CLI execution result
        @type raw_data: str
        @param key_val_sep: Key value seperator. Default value is ":"
        @type key_val_sep: str
        @param key_sep: Seperator between individual rows of key data. Default
            value is "\n"
        @type key_sep: str
        @rtype: list
        @return: Returns the list of dicts where each dict contains data for
            a record.

        Calling the get_parsed_data function will return a list of dicts with
        each dict containing the data corresponding to the record. e.g.
        {'cluster_nodes': [
                           {'status': 'active',
                           'id_': 'b4e3c4c0-300f-4d03-8df7-9ab871c42346',
                           'controller_ip': '10.144.138.213'},
                           {'status': 'active',
                           'id_': '2bb27469-5025-4675-941b-b213b009b5b6',
                           'controller_ip': '10.144.139.127'},
                           {'status': 'active',
                           'id_': 'f803224c-8fb2-4b43-8f7c-e1cf469cf5fa',
                           'controller_ip': '10.144.139.7'}],
          'is master': 'true',
          'in majority': 'true'}
        }
        '''
        if key_val_sep is None:
            key_val_sep = ":"
        if key_sep is None:
            key_sep = "\n"
        parsed_data = {}
        original_data = []
        lines = raw_data.strip().replace('not ', 'not_').split(key_sep)
        if ((len(lines) > 0) and
            ((lines[0].upper().find("ERROR") > 0) or
             (lines[0].upper().find("NOT FOUND") > 0) or
             (len(lines) == 1 and lines[0].strip() == ""))):
            return parsed_data
        for line in lines:
            original_data.append(line.rstrip())

        py_dict = {}
        py_dict_node = {}
        node_data = []
        data = original_data[0:2]
        for line in data:
            if key_val_sep in line:
                (key, value) = line.split(key_val_sep, 1)
                key = key.strip().lower()
                value = value.strip().lower()
                if key != "" and value != "":
                    py_dict.update({key: value})
        data = original_data[3:-2]
        for line in data:
            (uuid, ip, status) = line.rstrip().split()
            status = status.replace('not_', 'not ')
            py_dict_node = {"id_": uuid,
                            "controller_ip": ip,
                            "status": status}
            node_data.append(py_dict_node)

        py_dict.update({"cluster_nodes": node_data})
        return py_dict

if __name__ == '__main__':
    import doctest
    doctest.testmod()
