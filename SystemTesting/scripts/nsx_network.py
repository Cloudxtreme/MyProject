########################################################################
# Copyright (C) 2014 VMware, Inc.
# # All Rights Reserved
########################################################################

""" This is a standalone script for provisiong network using NSX (previously
called as VSM). This script supports 2 main actions:
1. create network
This action involves following steps:
- creates an edge on the cloud per user
- create a logical switch
- creates an interface on edge per logical switch
- creates dhcp ippool corresponding to edge interface
- max number of networks supported per user is 9
2. delete network
This action involves following steps:
- deletes the interface on edge corresponding to the network/logical switch
- delete the logical switch
TODO: look for active logical switches and delete edge if possible
"""

from optparse import OptionParser
import os
import pwd
import re
import sys
import ssl
import time
import pylib
from address_group_schema import AddressGroupSchema
from appliances_schema import ApplianceSchema
from dhcp import DHCP
from edge import Edge
from edge_schema import EdgeSchema
from edge_firewall_schema import FirewallSchema
from edge_firewall_default_policy_schema import FirewallDefaultPolicySchema
from features_schema import FeaturesSchema
from pyVmomi import Vim, SoapStubAdapter
from vdn_scope import VDNScope
from vdn_scopes_schema import VDNScopesSchema
from virtual_wire import VirtualWire
from virtual_wire_create_spec_schema import VirtualWireCreateSpecSchema
from vnics import Vnics
from vnics_schema import VnicsSchema
from vsm import VSM
from vsm_address_group_schema import AddressGroupSchema
from vsm_vnic_schema import VnicSchema
import yaml

import vmware.common.nimbus_utils as nimbus_utils

FW_DEFAULT_RULE_ACCEPT = 'accept'
FW_DEFAULT_RULE_DENY = 'deny'
FW_DEFAULT_RULE_LIST = ['accept', 'deny']

class Options(object):
    """ Dummy class to model the options"""
    pass

def get_edge(vsm_obj):
    """ function to get edge id for the current user

    @param vsm_obj reference to vsm client object
    @return edge_id edge id from vsm
    """
    edge  = Edge(vsm_obj, '4.0')
    edges = (edge.query())
    edge_id = None
    for item in edges.edgePage.list_schema:
       user = pwd.getpwuid(os.getuid())[0]
       if item.name and re.search(user, item.name):
          print "Got Edge VM %s for user %s" % (item.name, user)
          edge_id = item.objectId
          break

    return edge_id

def create_network(options, vsm_obj):
    """ function to create network

    @param options cli options to this script
    @param vsm_obj reference to vsm client object
    @return True/False True - success False - error
    """
    edge_id = get_edge(vsm_obj)
    if not edge_id:
       if not add_edge(options):
           print("Failed to create edge")
           return False
       edge_id = get_edge(vsm_obj)

    vdn_scope = get_transport_zone(options)
    virtual_wire = VirtualWire(vdn_scope)
    name = get_network_name(options)
    response = virtual_wire.read_by_name(name)
    if response != "FAILURE":
       print("Found network %s already exists" % options.name)
       return True

    virtual_wire_create = VirtualWireCreateSpecSchema()
    virtual_wire_create.name = name
    virtual_wire_create.tenantId = name
    virtual_wire_create.description = 'NSX network %s' % name

    # check if user needs to enable guest vlan tagging,
    # this is require if one needs to run vlan tests in nested
    # environment.
    if hasattr(options, 'guest_vlan'):
        if options.guest_vlan is True:
           print("network %s has guest vlan tagging enabled"\
                 % options.name)
           virtual_wire_create.guestVlanAllowed = True

    print("Creating network %s" % options.name)
    result = virtual_wire.create(virtual_wire_create)
    if (result[0].response.status != 201):
       print "response: %s" % result[0].response.status
       print "response: %s" % result[0].response.reason
       return False
    print("Changing security settings on the network")
    set_network_security_policy(options)
    return add_edge_interface(options, edge_id)

def delete_network(options, vsm_obj):
    """ function to delete network

    @param options cli options to this script
    @param vsm_obj reference to vsm client object
    @return True/False True - success False - error
    """
    print("Disconnecting edge interface attached to this network")
    edge_id = get_edge(vsm_obj)
    edge = Edge(vsm_obj, '4.0')
    edge.id = edge_id
    vnics = Vnics(edge)
    vnics_schema = vnics.query()
    network = get_network_id(options, get_network_name_on_vc(options))
    for vnic in vnics_schema.vnics:
       if network and vnic.portgroupId == network:
          print("Found a matching vnic %s %s" % (options.name, vnic.index))
          vnic.isConnected = "False"
          vnic.portgroupId = None
          vnic.name = "vnic%s" % vnic.index
          vnics_schema = VnicsSchema()
          vnics_schema.vnics = [vnic]
          result = vnics.create(vnics_schema)
          if (result[0].response.status != 204):
             print "update vnic error: %s %s" \
                % (result[0].response.status, result[0].response.reason)
             return False
          else:
             break
    else:
        print ("No matching vnic found")

    vdn_scope = get_transport_zone(options)
    virtual_wire = VirtualWire(vdn_scope)
    vwire = virtual_wire.read_by_name(get_network_name(options))
    name = get_network_name(options)
    if vwire != "FAILURE":
       print("Found a matching network %s" % (options.name))
       virtual_wire.id = vwire.objectId
       result = virtual_wire.delete()
       if (result.response.status != 200):
          print ("Delete vwire error: %s" % result.response.reason)
          return False
    else:
        print ("No matching network found")
    print("Network %s deleted" % (options.name))

    return True


def add_edge_interface(options, edge_id):
    """ function to add an interface on edge

    @param options cli options to this script
    @param edge_id edge id on vsm
    @return True/False True - success False - error
    """
    vsm_obj = get_vsm_object(options)
    edge = Edge(vsm_obj, '4.0')
    edge.id = edge_id
    vnics = Vnics(edge)
    vnics_schema = vnics.query()
    active = []*10
    index = 0
    active_nics = 0
    for vnic in vnics_schema.vnics:
       if vnic.isConnected == "true":
          active.append(True)
          active_nics =+ 1
       else:
          active.append(False)
    if active_nics < 10:
       free_index = next((i for i, x in enumerate(active) if not x), None)
       vnic_schema =  VnicSchema()
       vnics_schema =  VnicsSchema()
       vnic_schema = get_vnic(options, free_index)
       vnics_schema.vnics = [vnic_schema]
       print("Creating vnic on edge %s" % edge_id)
       result = vnics.create(vnics_schema)
       if (result[0].response.status != 204):
          r_vars = vars(result[0])
          print("Create vnic error: %s" % result[0].response.reason)
          print ', '.join("%s: %s" % item for item in r_vars.items())
          return False
       range = get_dhcp_range(options, free_index)
       default_gateway = get_primary_ip(options, free_index)
       return create_dhcp_pool(options, vsm_obj, range, default_gateway)
    return True

def add_edge(options):
    """ function to add on edge

    @param options cli options to this script
    @return True/False True - success False - error
    """
    vsm_obj = get_vsm_object(options, '4.0')
    edge = Edge(vsm_obj, '4.0')
    edge_schema = EdgeSchema(None)
    edge_schema.datacenterMoid = get_datacenter_id(options)
    edge_schema.appliances.applianceSize = 'compact'

    appliance_schema = ApplianceSchema()
    appliance_schema.datastoreId = get_datastore_id(options)
    appliance_schema.resourcePoolId = get_cluster_id(options)

    # XXX(hchilkot):
    # set default firewall rule to accept for edge,
    # this is required to pass any traffic across networks.
    result, features_schema = set_edge_features_schema(default_firewall_rule = FW_DEFAULT_RULE_ACCEPT)
    if not result:
       print("Result : %r. Received: %r for features schema. \
              Failed to set edge features." % (result, features_schema))
       return False
    edge_schema.features = features_schema

    edge_schema.appliances.appliance = [appliance_schema]
    edge_schema.vnics = [get_vnic(options, 0)]
    edge_schema.name = get_edge_name(options)
    print ("Creating edge %s" % edge_schema.name)
    result = edge.create(edge_schema)
    if (result[0].response.status != 201):
       r_vars = vars(result[0])
       print("Create edge error: %s" % result[0].response.reason)
       print ', '.join("%s: %s" % item for item in r_vars.items())
       return False
    return True

def set_edge_features_schema(default_firewall_rule = None):
    """ function to set the features of edge (like firewall,
        l2 vpn etc)

    @param default_firewall
    @return feature,False Features - success False - error
    """
    if default_firewall_rule is None:
       print("no firewall rule specified,firewall rule won't be changed")
       return False, None
    if default_firewall_rule not in FW_DEFAULT_RULE_LIST:
       print ("%r is invalid value for default_firewall_rule" \
              "valid values are %r" % ( default_firewall_rule, \
               FW_DEFAULT_RULE_LIST))
       return False, None
    features_schema = FeaturesSchema()
    firewall_schema = FirewallSchema()
    default_firewall_schema = FirewallDefaultPolicySchema()
    default_firewall_schema.action = default_firewall_rule
    firewall_schema.defaultPolicy = default_firewall_schema
    features_schema.firewall = firewall_schema
    return True, features_schema

def get_datastore_id(options):
    """ function to get datastore mob id for given datastore

    @param options cli options to this script
    @return mob id of datastore
    """
    service_instance = get_vc_content(options)
    datastore = options.datastore
    datacenter = get_datacenter(options)
    for item in datacenter.datastoreFolder.childEntity:
       if (item.name == datastore):
          return item._GetMoId()

def get_network_id(options, network):
    """ function to get network mob id for given network

    @param options cli options to this script
    @return mob id of network
    """
    service_instance = get_vc_content(options)
    datacenter = get_datacenter(options)
    for item in datacenter.networkFolder.childEntity:
       if (item.name == network):
          return item._GetMoId()

def get_datacenter_id(options):
    """ function to get datacenter mob id

    @param options cli options to this script
    @return mob id of datacenter
    """
    datacenter = get_datacenter(options)
    return datacenter._GetMoId()

def get_cluster_id(options):
    """ function to get cluster mob id

    @param options cli options to this script
    @return mob id of cluster
    """
    cluster = options.cluster
    datacenter = get_datacenter(options)
    for item in datacenter.hostFolder.childEntity:
       if (item.name == cluster):
          return item._GetMoId()

def get_vnic(options, index):
    """ function to get vnic schema for given index

    @param options cli options to this script
    @param index index/number of the interface
    @return vnics_schema reference to VnicsSchema object
    """
    vnic_schema =  VnicSchema()
    address_group = AddressGroupSchema()
    address_group.primaryAddress = get_primary_ip(options, index)
    address_group.subnetMask = '255.255.0.0'
    vnic_schema.addressGroups = [address_group]
    vnic_schema.type = "Internal"
    vnic_schema.index = index
    if index == 0:
       mgmt_network_id = get_network_id(options, options.mgmt_network)
       vnic_schema.portgroupId = mgmt_network_id
       vnic_schema.name = mgmt_network_id
       options.mgmt_network
    else:
       vnic_schema.name = get_network_name(options)
       vnic_schema.portgroupId = get_network_id(options, get_network_name_on_vc(options))

    vnic_schema.isConnected = "True"

    return vnic_schema

def get_network_name(options):
    """ function to get network name based on user option

    @param options cli options to this script
    @return network name
    """
    user = pwd.getpwuid(os.getuid())[0]
    return "%s-%s" %(user, options.name)

def get_edge_name(options):
    """ function to get edge name based on user option

    @param options cli options to this script
    @return edge name
    """
    user = pwd.getpwuid(os.getuid())[0]
    return "%s-edge" %(user)

def get_primary_ip(options, index):
    """ function to get primary ip based on index

    @param options cli options to this script
    @param index of the interface
    @return primary ip address
    """

    second_octet = 160 + index
    return "192.%s.1.1" % second_octet

def get_vc_content(options):
    """ function to get content object of given vc

    @param options cli options to this script
    @return vc content object
    """
    vc_ip = options.vc
    vc_user = options.vc_user
    vc_password = options.vc_password
    stub = SoapStubAdapter(host=vc_ip, port=443, path="/sdk", version="vim.version.version7")
    service_instance = Vim.ServiceInstance("ServiceInstance", stub)
    if not service_instance:
       print("serviceInstance not defined")
    ssl._create_default_https_context = ssl._create_unverified_context
    content = service_instance.RetrieveContent()
    if not content:
       print("content not defined")
    content.sessionManager.Login(vc_user, vc_password)
    return content

def get_datacenter(options):
    """ function to get datacenter managed object reference

    @param options cli options to this script
    @return MOR for the given datacenter option
    """
    content = get_vc_content(options)
    rootFolder = content.rootFolder
    for item in rootFolder.childEntity:
       if (options.datacenter == item.name):
           return item
    return None

def get_vm_by_name(options, vm_name):
    """ function to get vm by name

    @param options: cli options to this script
    @param vm_name: name of the vm
    @return MOR of vm that matches given name
    """
    dc = get_datacenter(options)
    vmFolder = dc.GetVmFolder()
    users_folder = find_entity_by_name(vmFolder, 'users')
    current_user = os.environ["USER"]
    #current_user = pwd.getpwuid(os.getuid())[0]
    user_folder = find_entity_by_name(users_folder, current_user)
    vm = find_entity_by_name(user_folder, vm_name)
    if vm is not None:
        print "Found VM with name: %s" % vm_name
    return vm

def find_entity_by_name(parent_entity, name):
    """ generic function to search for an entity by name

    @param parent_entity: parent managed object to start search
    @param name: name of the entity, example folder or vm name
    @return MOR of entity that matches given name
    """
    children = parent_entity.GetChildEntity()
    for item in children:
        if item.GetName() == name:
            return item
    return None

def get_vm_ip(options, name):
    """ function to get ip address of vm which is accessible

    @param options: cli options to this script
    @param vm_name: naem of the vm
    @return ip address of the vm
    """
    try:
        vm = get_vm_by_name(options, name)
    except Exception, error:
        vm = None
        print "get_vm_by_name errored: %r" % error
        return None
    if vm is None:
        print "Not able to find vm %s, probably never deployed" % name
        return None
    summary = vm.summary
    # check if the vm is powered on
    if summary.runtime.powerState != 'poweredOn':
        print ("VM %s not in powerdOn state: %s. Powering on the VM" %
               (name, vm.runtime.powerState))
        vm.PowerOnVM_Task()
        timeout = 1200
        sleepTime = 10
        while timeout > 0:
            print ("Getting vmware tools status for vm %s\n" % name)
            if vm.guest.toolsRunningStatus == 'guestToolsRunning':
                break
            time.sleep(sleepTime)
            timeout = (timeout - sleepTime)

    # look for all ip addresses exposed by the guest
    # and select the one that is reachable
    for net_info in vm.guest.net:
        if net_info == None or net_info.ipConfig == None:
            # TODO: using print as this module is yet to be integrated with
            # logger
            print "net_info not defined, probably tools not running\n"
            break
        for entry in net_info.ipConfig.ipAddress:
            match = re.match("\d+.\d+.\d+.\d+", entry.ipAddress)
            if match:
                result = os.system("ping -c 1 -t 60 %s 2>&1 > /dev/null" \
                    % entry.ipAddress)
                if result == 0:
                    print "Found IP in vm.guest.net.ipConfig=%s" % entry.ipAddress
                    return entry.ipAddress

    # check if summary has ip address information
    if summary.guest.ipAddress and summary.guest.ipAddress != '127.0.0.1':
        print "Found IP in vm.summary.guest.ipAddress=%s" % summary.guest.ipAddress
        return summary.guest.ipAddress
    # as last option, rely on ip address written under annotation
    note = yaml.load(summary.config.annotation)
    if 'ip' in note:
        print "Found IP in vm.summary.config.annotation=%s" % note['ip']
        return note['ip']

    print "No ip address found for vm %s\n" % name
    return None

def get_network_on_vc(options):
    """ function to get network manage object on vc corresponsing
    to logical switch/network on vsm

    @param options cli options to this script
    @return network name
    """
    datacenter = get_datacenter(options)
    networks = datacenter.network

    name = get_network_name(options)
    for network in networks:
        if re.search(name, network.name):
            return network

def get_network_name_on_vc(options):
    """ function to get network name on vc corresponsing
    to logical switch/network on vsm

    @param options cli options to this script
    @return network name
    """
    network = get_network_on_vc(options)
    if network:
        return network.name

def create_dhcp_pool(options, vsm_obj, range, default_gateway):
    """ function to create dhcp ip pool

    @param options cli options to this script
    @param vsm_obj reference to vsm client object
    @param range dhcp ip range
    @param default_gateway default gateway
    @return True/False True - success False - error
    """
    edge = Edge(vsm_obj, '4.0')
    edge_id = get_edge(vsm_obj)
    edge.id = edge_id

    dhcp_py_dict = {
        'enabled': True,
        'logging': {'loglevel': 'info', 'enable': False},
        'ippools': [
                   {
                       'autoconfiguredns': True,
                       'defaultGateway': default_gateway,
                       'iprange': range,
                   }
        ],
    }
    dhcp_client = DHCP(edge)
    print("Creating dhcp ippool with range %s" % range)
    dhcp_schema_object = dhcp_client.get_schema_object(dhcp_py_dict)
    existing_dhcp_schema = dhcp_client.read()
    if existing_dhcp_schema and existing_dhcp_schema.ipPools:
       print "append dhcp ippool to existing list"
       dhcp_schema_object.ipPools = existing_dhcp_schema.ipPools + \
          dhcp_schema_object.ipPools
    result = dhcp_client.create(dhcp_schema_object)

    if (result[0].response.status != 204):
       r_vars = vars(result[0])
       print("Create IP Pool error: %s" % result[0].response.reason)
       print ', '.join("%s: %s" % item for item in r_vars.items())
       return False
    return True

def get_dhcp_range(options, index):
    """ function to get dhcp ip range based on index

    @param options cli options to this script
    @param index id/number of the interface
    @return ip_range dhcp ip range
    """
    second_octet = 160 + index
    return "192.%s.1.2-192.%s.255.254" % (second_octet, second_octet)

def get_vsm_object(options, version='4.0'):
    ip = "%s:443" % options.nsx_ip
    user = options.nsx_user
    if user == None:
       user = 'admin'

    password = options.nsx_password
    if password == None:
       password = 'default'

    return VSM(ip, user, password, None, version)

def get_transport_zone(options):
    """ function to get transport zone/vdn scope object

    @param options cli options to this script
    @return transport zone object
    """
    vsm_obj = get_vsm_object(options, '2.0')
    transport_zone = VDNScope(vsm_obj)
    response = transport_zone.query()
    transport_zones_object = VDNScopesSchema()
    transport_zones_object.set_data(response, 'xml')
    id = transport_zones_object.vdnScope[0].objectId
    transport_zone.id = id
    return transport_zone

def delete_all_edges(options):
    """ Function to delete all edges on given VSM

    @param options cli options to this script
    @return None
    """
    edge  = Edge(vsm_obj)
    edges = (edge.query())
    edge_id = None
    for item in edges.edgePage.list_schema:
       edge.id = item.objectId
       edge.delete()

def delete_all_logical_switches(options):
    """ Function to delete all logical switches on given VSM

    @param options cli options to this script
    @return None
    """
    vdn_scope = get_transport_zone(options)
    virtual_wire = VirtualWire(vdn_scope)
    virtual_wire_objects = virtual_wire.full_query()
    for vwire in virtual_wire_objects:
       print "name %s" % vwire.objectId
       virtual_wire.id = vwire.objectId
       virtual_wire.delete()

def set_network_security_policy(options):
    """ Function to configure security policy on the network
    to work in nested environment

    @param options cli options to this script
    @return None
    """
    network = get_network_on_vc(options)
    name = get_network_name(options)

    config_spec = Vim.Dvs.DistributedVirtualPortgroup.ConfigSpec()
    config_info = network.GetConfig()
    config_spec.description = config_info.name
    config_spec.name = name
    config_spec.configVersion = config_info.configVersion

    true_policy = Vim.BoolPolicy()
    true_policy.value = True
    dvs_port_setting = Vim.VMwareDVSPortSetting()
    security_policy = Vim.DVSSecurityPolicy()
    security_policy.allowPromiscuous = true_policy
    security_policy.forgedTransmits = true_policy
    security_policy.macChanges = true_policy
    security_policy.inherited = False
    dvs_port_setting.securityPolicy = security_policy
    config_spec.defaultPortConfig = dvs_port_setting

    network.ReconfigureDVPortgroup_Task(config_spec)

if __name__ == "__main__":
    func = nimbus_utils.read_nimbus_config
    config_dict = func(os.environ['NIMBUS_CONFIG_FILE'],
                       os.environ['NIMBUS'])
    nsx = None
    nsx_user = None
    nsx_password = None
    if 'nsx' in config_dict:
       nsx = config_dict['nsx']
    if 'nsx_user' in config_dict:
       nsx_user = config_dict['nsx_user']
    if 'nsx_password' in config_dict:
       nsx_password = config_dict['nsx_password']

    usage = "usage: %prog [options]"
    parser = OptionParser(usage=usage)
    parser.add_option("--action", dest="action", action="store",
                      type="string", help="create or delete")
    parser.add_option("--name", dest="name", action="store",
                       type="string", help="network name")
    parser.add_option("--vc", dest="vc", action="store",
                       default=config_dict['vc'],
                       type="string", help="vcenter ip")
    parser.add_option("--vcpassword", dest="vc_password", action="store",
                       default=config_dict['vc_password'],
                       type="string", help="vcenter ip")
    parser.add_option("--vcuser", dest="vc_user", action="store",
                       default=config_dict['vc_user'],
                       type="string", help="vcenter ip")
    parser.add_option("--datacenter", dest="datacenter", action="store",
                       default=config_dict['datacenter'],
                       type="string", help="datastore name")
    parser.add_option("--datastore", dest="datastore", action="store",
                       default=config_dict['datastore'],
                       type="string", help="datastore name")
    parser.add_option("--cluster", dest="cluster", action="store",
                       default=config_dict['computer'],
                       type="string", help="cluster name")
    parser.add_option("--mgmt-network", dest="mgmt_network", action="store",
                       default=config_dict['network'],
                       type="string", help="management network name")
    parser.add_option("--nsx", dest="nsx_ip", action="store",
                       default=nsx,
                       type="string", help="NSX IP address")
    parser.add_option("--nsxpassword", dest="nsx_password", action="store",
                       default=nsx_password,
                       type="string", help="NSX manager password")
    parser.add_option("--nsxuser", dest="nsx_user", action="store",
                       default=nsx_user,
                       type="string", help="NSX manager userid")
    parser.add_option("--guest_vlan", dest="guest_vlan", action="store_true",
                       help = "guest vlan flag")
    global options
    (options, args) = parser.parse_args()
    vsm_obj = get_vsm_object(options)
    result = True
    if options.action == "create":
       result = create_network(options, vsm_obj)
    else:
       result = delete_network(options, vsm_obj)

    if result:
       # exit with zero if everything is good
       sys.exit(0)
    else:
       sys.exit(1)
