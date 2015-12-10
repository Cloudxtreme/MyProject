import json

import sys
import traceback

import pylib

import neutron
import logical_switch_schema
import logical_switch
import logical_switch_port_schema
import logical_switch_port
import logical_services_node
import logical_services_node_schema
import logical_services_interface
import logical_services_interface_schema
import transport_zone_schema
import transport_zone
import transport_node_schema
import transport_node
import transport_node_cluster
import transport_node_cluster_schema
import tag_schema
import segment_id_pools
import segment_id_pools_schema
import multicast_pools
import multicast_pools_schema
import vif_attachment
import vif_attachment_schema

import connection

import global_deployment_container
import deployment_container_schema
from vsm import VSM

if __name__=='__main__':

    vsm_obj = VSM("10.67.120.30:443", "admin", "default", version="4.0")
    gdc_obj = global_deployment_container.GlobalDeploymentContainer(vsm_obj)
    py_dict = dict(name='nsx-dc', description='nsx-dc', hypervisortype='vsphere',
                   keyvaluearray=[{'key': 'computeResource', 'value': 'domain-c23'}, {'key': 'storageResource', 'value': 'datastore-15'}])
    gdc_schema = deployment_container_schema.DeploymentContainerSchema(py_dict)
    print gdc_schema.get_data('xml')
    result = gdc_obj.create(gdc_schema)
    print result.__dict__

    neutron_obj = neutron.Neutron("10.67.120.30", "admin", "default")

    sic = segment_id_pools.SegmentIDPools(neutron_obj)
    si = segment_id_pools_schema.SegmentIDPoolsSchema( { 'schema' : '/v1/schema/SegmentIDPool', 'start': 5000, 'end': 10000 } )
    result = sic.create(si)
    print  "segment create status = %s" % str(result.status_code)

    mpc = multicast_pools.MulticastPools(neutron_obj)
    mp = multicast_pools_schema.MulticastPoolsSchema( { 'schema' : '/v1/schema/MulticastAddressPool', 'start': '224.0.0.1', 'end': '224.0.0.254' } )
    result = mpc.create(mp)
    print  "multicast status = %s" % str(result.status_code)

    tzc = transport_zone.TransportZone(neutron_obj)
    tz = transport_zone_schema.TransportZoneSchema({'display_name' : 'name', 'schema' : '/v1/schema/TransportZone', 'transport_zone_type' : 'vxlan' })
    result = tzc.create(tz)
    print  "tz status = %s" % str(result.status_code)

    tnc1 = transport_node_cluster.TransportNodeCluster(neutron_obj)
    tn1 = transport_node_cluster_schema.TransportNodeClusterSchema({ 'schema':'/v1/schema/TransportNodeCluster', 'domain_type':'vsphere', 'domain_id':'9E7C227F-FC78-4878-9D1B-39D64B791730', 'domain_resource_id': 'domain-c23', 'zone_end_points': [ {  'transport_zone_id': tzc.id  }] })
    result = tnc1.create(tn1)
    print  "tr cluster 1 status = %s" % str(result.response)

#    tnc2 = transport_node_cluster.TransportNodeCluster(neutron_obj)
#    tn2 = transport_node_cluster_schema.TransportNodeClusterSchema({ 'schema':'/v1/schema/TransportNodeCluster', 'domain_type':'vsphere', 'domain_id':'29A06F0B-BA8D-4B5D-B1BE-BBC1814AD36D', 'domain_resource_id': 'domain-c23', 'zone_end_points': [ {  'transport_zone_id': tzc.id  }] })
#    result = tnc2.create(tn2)
#    print  "tr cluster 2 status = %s" % str(result.response)



    try:

        lsc = logical_switch.LogicalSwitch(neutron_obj)
        ls = logical_switch_schema.LogicalSwitchSchema({ 'schema': '/v1/schema/LogicalSwitch', 'transport_zone_binding' : [{ 'transport_zone_id': str(tzc.id) }] })
        result = lsc.create(ls)
        print str(result.response)


        lspc1 = logical_switch_port.LogicalSwitchPort(lsc)
        lsp1 = logical_switch_port_schema.LogicalSwitchPortSchema( { 'schema': '/v1/schema/LogicalSwitchPort', 'display_name': 'lsp-1' } )
        result = lspc1.create(lsp1)
        print str(result.response)

 #       lspc2 = logical_switch_port.LogicalSwitchPort(lsc)
 #       lsp2 = logical_switch_port_schema.LogicalSwitchPortSchema( { 'schema': '/v1/schema/LogicalSwitchPort', 'display_name': 'lsp-1' } )
 #       result = lspc2.create(lsp2)
 #       print str(result.response)

        lspc3 = logical_switch_port.LogicalSwitchPort(lsc)
        lsp3 = logical_switch_port_schema.LogicalSwitchPortSchema( { 'schema': '/v1/schema/LogicalSwitchPort', 'display_name': 'lsp-1' } )
        result = lspc3.create(lsp3)
        print str(result.response)

#        print "Press Enter to continue ..."

#       sys.stdin.read(1)

        vac1 = vif_attachment.VifAttachment(lspc1)
        va1 = vif_attachment_schema.VifAttachmentSchema( { 'schema': '/v1/schema/VifAttachment', 'vif_uuid': '7e87b086-9924-4b2b-8bcb-2e99b9596299.000' } )
        print str(va1.get_data())
        result = vac1.create(va1)
        print str(result.response)

        #vac2 = vif_attachment.VifAttachment(lspc2)
        #va2 = vif_attachment_schema.VifAttachmentSchema( { 'schema': '/v1/schema/VifAttachment', 'vif_uuid': 'b4ca712d-dae3-4d55-87a2-03dfc7802431.000' } )
        #print str(va2.get_data())
        #result = vac2.create(va2)
        #print str(result.response)

        print "Vif attachments done"

#        print "Press Enter to continue ..."

#        sys.stdin.read(1)

        lsnc = logical_services_node.LogicalServicesNode(neutron_obj)
        print "l services node client created"
        lsn = logical_services_node_schema.LogicalServicesNodeSchema( { 'schema': '/v1/schema/LogicalServicesNode', 'display_name': 'node-1', 'node_capacity': 'SMALL', 'location': 'datacenter-3', 'dns_settings': {'domain_name': 'node1', 'primary_dns': '10.112.0.1', 'secondary_dns': '10.112.0.2'} })
        print "l services schema object created " + lsn.get_data('json')
        result = lsnc.create(lsn)
        print str(result.response)

        lsic = logical_services_interface.LogicalServicesInterface(lsnc)
        print "l services interface client created"
        lsi = logical_services_interface_schema.LogicalServicesInterfaceSchema( { 'schema':'/v1/schema/LogicalServicesNodeInterface', 'display_name':'intf-1', 'interface_number': 1, 'interface_type': 'INTERNAL', 'interface_options': {'enable_send_redirects': False, 'enable_proxy_arp': False}, 'address_groups': [{'primary_ip_address':'192.168.1.1', 'subnet': '24', 'secondary_ip_addresses': ['192.168.1.2']}] } )
        print "l services interface schema object created " + lsi.get_data('json')
        print "lsic create endpoint = " + lsic.create_endpoint
        result = lsic.create(lsi)
        print str(result.response)

        pac = vif_attachment.VifAttachment(lspc3)
        pa = vif_attachment_schema.VifAttachmentSchema( { 'schema': '/v1/schema/PatchAttachment', 'peer_id': lsic.id })
        result = pac.create(pa)
        print str(result.response)

        print "Edge Deployed"

        print "Press Enter to continue ..."

        print "Resuming operations"

        pac.delete()
        lsic.delete()
        lsnc.delete()


        lsc.delete()
        tnc1.delete()
   #     tnc2.delete()
        tzc.delete()
        mpc.delete()
        sic.delete()
    except:
        print "Unexpected error:", sys.exc_info()[0]
        traceback.print_exc(file=sys.stdout)
        print "exception thrown cleaning up ..."
        lsc.delete()
        tnc1.delete()
    #    tnc2.delete()
        tzc.delete()
        mpc.delete()
        sic.delete()


