
import string
import re
import json
from vmware.common.global_config import pylogger

class EdgeCliJsonParser:
    """
    Sample output dump: To parse the output, like:

    vShield Edge OSPF Routing Protocol Config:
    {
       "ospf" : {
          "defaultOriginate" : false,
          "forwardingAddress" : null,
          "gracefulRestart" : true,
          "redistribute" : {
             "rules" : [],
             "enabled" : false
          },
          "protocolAddress" : null,
          "areas" : [
             {
                "areaId" : 51,
                "authenticationType" : "none",
                "authenticationSecret" : null,
                "type" : "nssa"
             },
             {
                "areaId" : 0,
                "authenticationType" : "none",
                "authenticationSecret" : null,
                "type" : "normal"
             }
          ],
          "enabled" : false
       }
    }
    """
    regex_lookup = {
        'ospf': {
            'regex' : '(.*?)vShield Edge OSPF Routing Protocol Config:(.*)',
            'match_group': 2
        },

        'dhcp':{
            'regex' : '(.*?)vShield Edge DHCP Config:(.*)',
            'match_group': 2
        }

    }

    # no inspection PyRedundantParentheses
    def get_parsed_data(self, input, regex_lookup_table_key):
        data = []
        lines = input.strip()
        lines = input.translate(string.maketrans("\n\r","  "))

        print "parser lines = %s" %lines
        match = re.search(self.regex_lookup[regex_lookup_table_key]['regex'], lines)

        if match:
            matched_string = match.group(self.regex_lookup[regex_lookup_table_key]['match_group'])
            pylogger.info("Matched String = %s " % matched_string)
            pydict = json.loads(matched_string)
            pydict = self.convert_to_unicode_and_lowercase(pydict)
            return pydict
        else:
            return "FAILURE"

    def convert_to_unicode_and_lowercase(self, input):
        """
        Converts the keys of pydict object from unicode to string
        """
        if isinstance(input, dict):
            return {self.convert_to_unicode_and_lowercase(key).lower(): self.convert_to_unicode_and_lowercase(value) for key, value in input.iteritems()}
        elif isinstance(input, list):
            return [self.convert_to_unicode_and_lowercase(element) for element in input]
        elif isinstance(input, unicode):
            return input.encode('utf-8')
        else:
            return input

if __name__ == '__main__':
    hor = EdgeCliJsonParser()

    input = '/opt/vmware/vshield/cli/show_edge_config.pl ospf\r\n-----------------------------------------------------------------------\r\nvShield Edge OSPF Routing Protocol Config:\r\n{\r\n   "ospf" : {\r\n      "defaultOriginate" : false,\r\n      "forwardingAddress" : null,\r\n      "gracefulRestart" : true,\r\n      "interfaces" : [],\r\n      "redistribute" : {\r\n         "rules" : [],\r\n         "enabled" : false\r\n      },\r\n      "protocolAddress" : null,\r\n      "areas" : [\r\n         {\r\n            "areaId" : 51,\r\n            "authenticationType" : "none",\r\n            "authenticationSecret" : null,\r\n            "type" : "nssa"\r\n         },\r\n         {\r\n            "areaId" : 0,\r\n            "authenticationType" : "none",\r\n            "authenticationSecret" : null,\r\n            "type" : "normal"\r\n         }\r\n      ],\r\n      "enabled" : false\r\n   }\r\n}\r\n[root@vShield-edge-41-0 ~]#'
    print hor.get_parsed_data(input,'ospf')
