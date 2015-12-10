import unittest
import vmware.common.logger as logger
import vmware.common.utilities as utilities


class AttributeMappingTest(unittest.TestCase):
    """
        Class to unit-test attribute mapping
    """
    def test_attribute_mapping(self):
        self.log = logger.setup_logging(self.__class__.__name__)
        #Attribute map
        attribute_map = {
            'name': 'display_name',
            'summary': 'description',
            'begin': 'start',
            'ipv': 'ip_version',
            'ranges': 'allocation_ranges',
            'dns': 'dns_nameservers',
            'hop': 'next_hop'
        }

        #User dictionary
        py_dict = {'subnets':
                       [{'static_routes': [{'hop': '192.168.10.5', 'destination_cidr': '192.168.10.0/24'}],
                         'ranges': [{'start': '192.168.1.2', 'end': '192.168.1.6'},
                                    {'start': '192.168.1.10', 'end': '192.168.1.100'}],
                         'dns': ['10.10.10.11', '10.10.10.12'],
                         'gateway_ip': '192.168.1.1',
                         'ipv': 4,
                         'cidr': '192.168.1.0/24'},
                         {'cidr': '192.175.1.0/24'}],
                         'name': 'TestIPPool-1-2091',
                         'summary': 'Test IPPool'}

        self.log.debug("User dictionary: %s" % py_dict)

        #Convert user dictionary to product expected form using map_attributes function
        py_dict = utilities.map_attributes(attribute_map, py_dict)

        #Dictionary in product expected form
        self.log.debug("Dictionary in product expected form:: %s" % py_dict)

        self.assertTrue("name" not in py_dict.keys())
        self.assertTrue("display_name" in py_dict.keys())
        self.assertEqual(py_dict["display_name"], "TestIPPool-1-2091")
        self.assertTrue("summary" not in py_dict.keys())
        self.assertTrue("description" in py_dict.keys())
        self.assertEqual(py_dict["description"], "Test IPPool")

        #Convert product expected dictionary in user dictionary form using map_attributes function
        py_dict = utilities.map_attributes(attribute_map, py_dict, reverse_attribute_map=True)

        #Dictionary in user expected form
        self.log.debug("Dictionary in user expected form:: %s" % py_dict)

        self.assertTrue("display_name" not in py_dict.keys())
        self.assertTrue("name" in py_dict.keys())
        self.assertEqual(py_dict["name"], "TestIPPool-1-2091")
        self.assertTrue("description" not in py_dict.keys())
        self.assertTrue("summary" in py_dict.keys())
        self.assertEqual(py_dict["summary"], "Test IPPool")

if __name__ == "__main__":
    """
    By default using unittest.main() functions
    whose name start with 'test' are run
    """
    unittest.main()
