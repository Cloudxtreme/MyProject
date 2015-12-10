
import string
import re
import json
import vmware.common.global_config as global_config

pylogger = global_config.pylogger


class EdgeCliJsonParser:
    """
    >>> import pprint
    >>> raw_data = '''
    ...         ---------------------------------------------------------
    ...         vShield Edge BGP Routing Protocol Config:
    ...         {
    ...            "bgp" : {
    ...               "gracefulRestart" : false,
    ...               "localAS" : 200,
    ...               "neighbors" : [
    ...                  {
    ...                     "keepAliveTimer" : 60,
    ...                     "ipAddress" : "192.168.50.50",
    ...                     "name" : "Neighbour 1",
    ...                     "description" : "Neighbour 1",
    ...                     "remoteAS" : 200,
    ...                     "password" : "****",
    ...                     "srcIpAddress" : "192.168.50.1",
    ...                     "holdDownTimer" : 180,
    ...                     "weight" : 60
    ...                  }
    ...               ],
    ...               "enabled" : true
    ...            }
    ...         }
    ... '''
    >>> edgeclijsonparser = EdgeCliJsonParser()
    >>> pprint.pprint(edgeclijsonparser.get_parsed_data(raw_data, 'bgp'))
    {'bgp': {'enabled': True,
             'gracefulrestart': False,
             'localas': 200,
             'neighbors': [{'description': 'Neighbour 1',
                            'holddowntimer': 180,
                            'ipaddress': '192.168.50.50',
                            'keepalivetimer': 60,
                            'name': 'Neighbour 1',
                            'password': '****',
                            'remoteas': 200,
                            'srcipaddress': '192.168.50.1',
                            'weight': 60}]}}
    """
    regex_lookup = {
        'ospf': {
            'regex': '(.*?)vShield Edge OSPF Routing Protocol Config:(.*)',
            'match_group': 2
        },

        'bgp': {
            'regex': '(.*?)vShield Edge BGP Routing Protocol Config:(.*)',
            'match_group': 2
        },

        'dhcp': {
            'regex': '(.*?)vShield Edge DHCP Config:(.*)',
            'match_group': 2
        }
    }

    # no inspection PyRedundantParentheses

    def get_parsed_data(self, rawdata, regex_lookup_table_key=None):
        lines = rawdata.strip()
        lines = rawdata.translate(string.maketrans("\n\r", "  "))

        print "parser lines = %s" % lines
        match = re.search(self.regex_lookup[regex_lookup_table_key]['regex'],
                          lines)

        if match:
            matched_string = match.group(
                self.regex_lookup[regex_lookup_table_key]['match_group'])
            pylogger.info("Matched String = %s " % matched_string)
            pydict = json.loads(matched_string)
            pydict = self.convert_to_unicode_and_lowercase(pydict)
            return pydict
        else:
            return "FAILURE"

    def convert_to_unicode_and_lowercase(self, rawdata):
        """
        Converts the keys of pydict object from unicode to string
        """
        if isinstance(rawdata, dict):
            return {self.convert_to_unicode_and_lowercase(key).lower():
                    self.convert_to_unicode_and_lowercase(value)
                    for key, value in rawdata.iteritems()}
        elif isinstance(rawdata, list):
            return [self.convert_to_unicode_and_lowercase(element)
                    for element in rawdata]
        elif isinstance(rawdata, unicode):
            return rawdata.encode('utf-8')
        else:
            return rawdata


if __name__ == '__main__':
    import doctest
    doctest.testmod()