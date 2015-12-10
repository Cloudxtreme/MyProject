import vsm_client
from bridges_schema import BridgesSchema
from edge import Edge
import vmware.common.logger as logger
from vsm import VSM
import vmware.common as common

class Bridges(vsm_client.VSMClient):
    """ Class to create bridges on edge"""

    def __init__(self, edge):
        """ Constructor to create bridge managed object

        @param edge object on which bridge will be created
        """
        super(Bridges, self).__init__()
        self.log.debug("Creating LIFs on Edge %s" % edge.id)
        self.schema_class = 'bridges_schema.BridgesSchema'
        self.set_connection(edge.get_connection())
        self.set_create_endpoint("/edges/" + edge.id + "/bridging/config")
        self.create_as_put = True
	self.id = None

    def get_bridge(self, vwireobjectid=None):
        bridgeobj = BridgesSchema()
        bridgeobj.set_data(self.base_query(),"xml")
        for bridge in bridgeobj.bridges:
            if bridge.virtualWire == vwireobjectid:
                return bridge

        return common.status_codes.FAILURE

if __name__ == '__main__':
    import base_client
    py_dict = {'ipAddress': '10.115.173.172', 'userName': 'root', 'password': 'vmware'}
    vsm_obj = VSM("10.115.173.172:443", "admin", "default")

    # Bulk Create
    edge = Edge(vsm_obj)
    edge.id = "edge-1"
    py_dict = {'bridges': [{'name': 'lif-vwire-1-20758',
                               'addressgroups':      [{'subnetmask': '255.255.0.0',
                                                       'addresstype': 'primary',
                                                       'primaryaddress': '172.31.1.1'}
                                                     ],
                               'isconnected': 'true',
                               'mtu': '1500',
                               'connectedtoid': 'virtualwire-1',
                               'type': 'internal'
                              }]
              }



    bridge_create = Bridges(edge)
    bridge_object_ids = base_client.bulk_create(bridge_create, [py_dict, py_dict])
    print bridge_object_ids
