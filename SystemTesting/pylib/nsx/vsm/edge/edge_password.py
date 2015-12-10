import pylib
from vsm import VSM
from edge import Edge


class EdgePassword():
    def __init__(self):
        pass

if __name__ == '__main__':
    vsm_obj = VSM("10.112.243.232", "admin", "default", "", "")
    edge_create_controller = Edge(vsm_obj)
    edge_password = edge_create_controller.get_edge_password(vsm_obj,"edge-41", "vmware")
    print "edge password = %s" % edge_password
