class ListInterfacesParser:

    def get_parsed_data(self, input, delimiter=' '):
        data = []
        lines = input.strip().split("\n")

        if ((len(lines) > 0) and ((lines[0].upper().find("ERROR") > 0) or
                                  (lines[0].upper().find("NOT FOUND") > 0) or
                                  (len(lines) == 1
                                   and lines[0].strip() == ""))):
            return input

        for line in lines:
            if line.strip() != "":
                data.append(line.strip())

        '''
        Output format:
        NSXManager# show interfaces
        lo is up, line protocol is up
        Description: lo
        Internet address is 127.0.0.1/8
        MTU 16436 bytes
            8950704 packets input, 766691416 bytes
            0 input errors, 0 frame
            8950704 packets output, 766691416 bytes
            0 output errors
        mgmt is up, line protocol is up
        Hardware address is 0050.56b0.14fc
        Description: mgmt
        Internet address is 10.112.11.30/23
        MTU 1500 bytes
            15211544 packets input, 1068280914 bytes
            0 input errors, 0 frame
            79279 packets output, 5115094 bytes
            0 output errors
        '''
        data = data[:-1]

        pydicts = []
        '''Get data of first interface'''
        line = data[0]
        columns = line.split()
        interface_name = columns[0]

        line = data[1]
        columns = line.split()
        summary = columns[1]

        line = data[2]
        columns = line.split()
        column3 = columns[3]
        values = column3.split("/")
        ipaddress = values[0]

        line = data[3]
        columns = line.split()
        mtu = columns[1]

        pydict = {'name': interface_name, 'summary': summary,
                  'ipaddress': ipaddress, 'mtu': mtu}
        pydicts.append(pydict)

        '''Get data of second interface'''
        line = data[5]
        columns = line.split()
        interface_name = columns[0]

        line = data[7]
        columns = line.split()
        summary = columns[1]

        line = data[8]
        columns = line.split()
        column3 = columns[3]
        values = column3.split("/")
        ipaddress = values[0]

        line = data[9]
        columns = line.split()
        mtu = columns[1]

        pydict = {'name': interface_name, 'summary': summary,
                  'ipaddress': ipaddress, 'mtu': mtu}
        pydicts.append(pydict)

        parsed_data = {'interfaces': pydicts}

        return parsed_data
