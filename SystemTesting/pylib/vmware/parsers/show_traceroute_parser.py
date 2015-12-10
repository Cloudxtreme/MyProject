import re


class ShowTraceRouteParser:
    def get_parsed_data(self, command_response, delimiter=' '):
        """
        >>> import pprint
        >>> parser = ShowTraceRouteParser()
        >>> sample_text = '''traceroute to time.vmware.com (10.113.60.176), 30 hops max, 60 byte packets    # noqa
        ... 11  10.250.112.102 (10.250.112.102)  243.311 ms  243.246 ms 10.250.16.150 (10.250.16.150)  243.130 ms   # noqa
        ... 12  scrootdc02.vmware.com (10.113.60.176)  243.080 ms 10.250.16.150 (10.250.16.150)  236.199 ms scrootdc02.vmware.com (10.113.60.176)  236.127 ms   # noqa
        ...
        ... nsxmanager'''
        >>> pprint.pprint(parser.get_parsed_data(sample_text))
        {'hostname': 'scrootdc02.vmware.com',
         'route': [{'ipaddress': '10.113.60.176'},
                   {'ipaddress': '10.250.16.150'},
                   {'ipaddress': '10.250.16.150'},
                   {'ipaddress': '10.113.60.176'}]}
        """

        lines = command_response.strip().split("\n")

        if ((len(lines) > 0) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[0].upper().find("NOT FOUND") > 0) or
                                  (lines[0].upper().find("UNKNOWN HOST") > 0)
                                  or
                                  (lines[0].find("Name or service not known")
                                  > 0)
                                  or (len(lines) == 1
                                  and lines[0].strip() == ""))):
            parsed_data = {'hostname': lines[0]}
            return parsed_data

        last_line = lines[-3].strip()
        host_name = None
        pydicts = []
        last_ip = None
        host_name_re = re.compile(" [a-z]+[0-9]*\.[a-z]+[0-9]*\.[a-z]+[0-9]* ")
        host_name_list = re.findall(host_name_re, last_line)
        ###
        # sample output using above re
        # sample text = "12 10.250.112.102 (10.250.112.102) 227.365 ms
        # 10.250.16.150 (10.250.16.150) 220.058 ms scrootdc02.vmware.com
        # (10.113.60.176) 219.887 ms"
        # output after running re
        # host_name_list=[' scrootdc02.vmware.com ']
        ###
        if len(host_name_list):
            host_name = host_name_list[-1].strip()
        for word in last_line.split():
            word = word.replace("(", "")
            word = word.replace(")", "")
            if word.count(".") == 3 and word.replace(".", "").isdigit():
                pydict = dict()
                pydict.update({'ipaddress': word})
                pydicts.append(pydict)
                last_ip = word
        if host_name is None:
            host_name = last_ip
        parsed_data = {'hostname': host_name, 'route': pydicts}

        return parsed_data

if __name__ == '__main__':
    import doctest
    doctest.testmod()