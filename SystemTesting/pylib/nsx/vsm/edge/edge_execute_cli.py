from vsm import VSM
from edge import Edge
from expect_client import ExpectClient
import connection
import re
from vmware.common.global_config import pylogger

class EdgeExecuteCli():
    def __init__(self):
        pass

if __name__ == '__main__':
    vsm_obj = VSM("10.112.243.232", "admin", "default", "", "")
    edge_create_controller = Edge(vsm_obj)
    edge_username = "admin"
    edge_password = "default"

    schema_key = 'dhcp'
    vtysh_command = "show configuration dhcp"
    edge_create_controller.execute_edge_cli(vtysh_command,edge_username,edge_password,schema_key)

    schema_key = 'ospf'
    vtysh_command = "show configuration ospf"
    edge_create_controller.execute_edge_cli(vtysh_command,edge_username,edge_password,schema_key)