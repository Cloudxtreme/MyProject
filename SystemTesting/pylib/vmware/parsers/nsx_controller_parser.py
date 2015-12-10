from xml.dom.minidom import parseString


class NsxControllerParser:

    """
    To parse the /etc/vmware/nsx/config-by-vsm.xml table, and get the key
    controller information

    >>> import pprint
    >>> nsx = NsxControllerParser()
    >>> raw_data = '''
    ... <?xml version="1.0" encoding="utf-8"?>
    ... <config>
    ...         <connectionList>
    ...                 <connection id="0">
    ...                         <server>10.115.175.187</server>
    ...                         <port>1234</port>
    ...                         <crtFile>/etc/vmware/nsx/ccp-10.115.175.187-1234.crt</crtFile>  # noqa
    ...                         <sslEnabled>true</sslEnabled>
    ...                 </connection>
    ...                 <connection id="1">
    ...                         <server>10.115.175.186</server>
    ...                         <port>1234</port>
    ...                         <crtFile>/etc/vmware/nsx/ccp-10.115.175.186-1234.crt</crtFile>  # noqa
    ...                         <sslEnabled>true</sslEnabled>
    ...                 </connection>
    ...                 <connection id="2">
    ...                         <server>10.115.175.185</server>
    ...                         <port>1234</port>
    ...                         <crtFile>/etc/vmware/nsx/ccp-10.115.175.185-1234.crt</crtFile>  # noqa
    ...                         <sslEnabled>true</sslEnabled>
    ...                 </connection>
    ...         </connectionList>
    ...         <hostSwitchList>
    ...                 <hostSwitch id="0">
    ...                         <uuid>79 35 77 85 92 a3 45 25-86 17 4b 1c 88 7d 13 f9</uuid>  # noqa
    ...                         <teamingPolicy>FAILOVER</teamingPolicy>
    ...                         <numUplink>1</numUplink>
    ...                         <numActiveUplink>1</numActiveUplink>
    ...                         <uplinkPortNames>uplink1</uplinkPortNames>
    ...                 </hostSwitch>
    ...         </hostSwitchList>
    ... </config>
    ... '''
    >>> py_dict = nsx.get_parsed_data(raw_data)
    >>> pprint.pprint(py_dict, width=78)
    {'table': [{'controller': '10.115.175.187',
                'port': '1234',
                'sslenabled': 'true'},
               {'controller': '10.115.175.186',
                'port': '1234',
                'sslenabled': 'true',
               {'controller': '10.115.175.185',
                'port': '1234',
                'sslenabled': 'true'}]}
    """
    def get_parsed_data(self, raw_data, delimiter='<'):
        '''
        @param raw_data output from the CLI execution result
        @type raw_data str
        @param delimiter character to split the key and value
        @type delimiter str

        @rtype: dict
        @return: calling the get_parsed_data function will return a hash
                 including array while
        each array entry is a hash, based on above sample, the return
        data will be:
        {
            {'table': [{'controller': '10.115.175.187',
                        'port': '1234',
                        'sslenabled': 'true'},
                       {'controller': '10.115.175.186',
                        'port': '1234',
                        'sslenabled': 'true'},
                       {'controller': '10.115.175.185',
                        'port': '1234',
                        'sslenabled': 'true'}]}
        }
        '''
        parsed_data = {}
        count = 0

        dom = parseString(raw_data)
        serverList = dom.getElementsByTagName('server')
        portList = dom.getElementsByTagName('port')
        sslList = dom.getElementsByTagName('sslEnabled')
        count = len(serverList)
        py_dicts = []
        for i in range(0, count):
            py_dict = {}
            node = serverList[i]
            value = node.childNodes[0].data
            py_dict.update({'controller': value})
            node = portList[i]
            value = node.childNodes[0].data
            py_dict.update({'port': value})
            node = sslList[i]
            value = node.childNodes[0].data
            py_dict.update({'sslenabled': value})
            py_dicts.append(py_dict)

        parsed_data = {'table': py_dicts, 'count': count}
        return parsed_data

if __name__ == '__main__':
    import doctest
    doctest.testmod()
