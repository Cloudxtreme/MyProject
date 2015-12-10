#!/usr/bin/python
########################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
########################################################################

#
#This script will add/remove one user defined ruleset to(from) firewall,
#which can open specific TCP/UDP port(src or dst) at inbound or outbound.
#It looks line below:
#Direction       Protocol        PortType        Port
#inbound         tcp             dst             100
#inbound         tcp             src             101
#

import os
import sys
import xml.dom.minidom
import getopt
import codecs


########################################################################
#
# Usage --
#      This will show how to use this scripts
# Input:
#      None
# Results:
#      Print out the help info.
# Side effects:
#      None
#
########################################################################

def Usage():
   print "Usgae: FirewallConfiguration.py operation rulesetname [direction] [protocol] [porttype] [port/port range]"
   print "     operation:   "
   print "               list: List all the port rules in the specific ruleset"
   print "               add: Add new port rule to ruleset, this command will create a ruleset if it's not exist"
   print "               remove: Remove port rule from ruleset, ruleset will be removed if it's empty"
   print "               removeruleset: Remove ruleset even it's not empty"
   print "     rulesetname:    "
   print "     direction: inbound or outbound "
   print "     protocol: udp or tcp "
   print "     porttype: src or dst "
   print "     port:     single port or port range. Examples: 100, 100-200  "

if len(sys.argv) < 3:
   Usage()
   sys.exit()

xmlDir = "/etc/vmware/firewall/"
serviceName = sys.argv[2]
xmlName = xmlDir+serviceName+".xml"
initString = "\n<ConfigRoot>\n\
<service>\n\
<id>"+serviceName+"</id>\n\
<enabled>true</enabled>\n\
<required>false</required>\n\
</service>\n\
</ConfigRoot>\n"


########################################################################
#
# InitFile --
#      Create xml file
# Input:
#      XML file name
# Results:
#      Create new one xml file under /etc/vmware/firewall.
# Side effects:
#      None
#
########################################################################

def InitFile():
   if not os.path.exists(xmlName):
      f = file(xmlName, 'w')
      f.write(initString)
      f.close()


########################################################################
#
# getText --
#      get xml node text
# Input:
#      XML node
# Results:
#      get xml node text
# Side effects:
#      None
#
########################################################################

def getText(nodeList):
   result = []
   for node in nodeList:
      if node.nodeType == node.TEXT_NODE:
         result.append(node.data)
   return ''.join(result)


########################################################################
#
# GetPortList --
#      get tcp/udp port info in XML file
# Input:
#      None
# Results:
#      max ID(rule id in xml) and port list(direction protocol porttype port).
# Side effects:
#      None
#
########################################################################

def GetPortList():
   maxId = 0
   portList = []
   for rule in service.getElementsByTagName('rule'):
      maxId = maxId+1
      protocol_text = getText(rule.getElementsByTagName('protocol')[0].childNodes)
      direction_text = getText(rule.getElementsByTagName('direction')[0].childNodes)
      porttype_text = getText(rule.getElementsByTagName('porttype')[0].childNodes)
      port = rule.getElementsByTagName('port')[0]
      port_text = ""
      if len(port.getElementsByTagName('begin')) == 0:
	 port_text = getText(port.childNodes)
      else:
	 port_begin = getText(port.getElementsByTagName('begin')[0].childNodes)
	 port_end = getText(port.getElementsByTagName('end')[0].childNodes)
	 port_text = port_begin+"-"+port_end
      portList.append((direction_text, protocol_text, porttype_text, port_text))
   result = (maxId, portList)
   return result


########################################################################
#
# ListPort --
#      list ruleset port info
# Input:
#      None
# Results:
#      print rule set port info(direction protocol porttype port).
# Side effects:
#      None
#
########################################################################

def ListPort():
   (maxId, portList) = GetPortList()
   print "Direction\tProtocol\tPortType\tPort"
   for (direction,protocol,porttype,port) in portList:
      print ""+direction+"\t\t"+protocol+"\t\t"+porttype+"\t\t"+port


########################################################################
#
# ListPort --
#      Write new ruleset info to xml file
# Input:
#      None
# Results:
#      Write new ruleset info to xml file
# Side effects:
#      None
#
########################################################################

def WriteBack():
   f = open(xmlName, 'w')
   writer = codecs.lookup('utf-8')[3](f)
   dom.writexml(writer, encoding='utf-8')
   writer.close()
   os.system(" esxcli network firewall refresh")


########################################################################
#
# AddPort --
#      Add new ruleset port info to xml file
# Input:
#      Direction : Inbound/Outbound
#      Protocol  : Tcp/Udp
#      Porttype  : Src/Dst
#      Port      : Tcp/Udp port number
# Results:
#      Write new ruleset info to xml file
# Side effects:
#      None
#
########################################################################

def AddPort(directionstr, protocolstr, porttypestr, portstr):
   (id,portList) = GetPortList()
   if portList.count((directionstr, protocolstr, porttypestr, portstr)) > 0:
      print "port already exist\n"
      return None
   if directionstr not in [ "inbound","outbound" ]:
      print "dir parameter invalid\n"
      return None
   if protocolstr not in [ "tcp","udp" ]:
      print "protocol parameter invalid\n"
      return None
   if porttypestr not in [ "src","dst" ]:
      print "porttype parameter invalid\n"
      return None
   rule = dom.createElement('rule')
   rule.setAttribute('id', str(id))

   direction = dom.createElement('direction')
   direction_text = dom.createTextNode(directionstr)
   direction.appendChild(direction_text)
   rule.appendChild(direction)

   protocol = dom.createElement('protocol')
   protocol_text = dom.createTextNode(protocolstr)
   protocol.appendChild(protocol_text)
   rule.appendChild(protocol)


   porttype = dom.createElement('porttype')
   porttype_text = dom.createTextNode(porttypestr)
   porttype.appendChild(porttype_text)
   rule.appendChild(porttype)

   port = dom.createElement('port')
   portList = portstr.split('-')
   if len(portList) == 2:
      portbegin = dom.createElement('begin')
      portbegin_text = dom.createTextNode(portList[0])
      portbegin.appendChild(portbegin_text)
      portend = dom.createElement('end')
      portend_text = dom.createTextNode(portList[1])
      portend.appendChild(portend_text)
      port.appendChild(portbegin)
      port.appendChild(portend)
   elif len(portList) == 1:
      port_text = dom.createTextNode(portList[0])
      port.appendChild(port_text)
   else:
      print "port parameter invalid"
      Usage()

   rule.appendChild(port)
   service.appendChild(rule)
   WriteBack()


########################################################################
#
# RemovePort --
#      Remove one ruleset port info from xml file
# Input:
#      Direction : Inbound/Outbound
#      Protocol  : Tcp/Udp
#      Porttype  : Src/Dst
#      Port      : Tcp/Udp port number
# Results:
#      Write new ruleset info to xml file
# Side effects:
#      None
#
########################################################################

def RemovePort(directionstr, protocolstr, porttypestr,  portstr):
   removeId = 0
   updateId = 0
   if directionstr not in [ "inbound","outbound" ]:
      print "dir parameter invalid\n"
      return None
   if protocolstr not in [ "tcp","udp" ]:
      print "protocol parameter invalid\n"
      return None
   if porttypestr not in [ "src","dst" ]:
      print "porttype parameter invalid\n"
      return None
   for rule in service.getElementsByTagName('rule'):
      if removeId > 0:
         rule.setAttribute('id', str(updateId))
         updateId = updateId + 1
	 continue
      updateId = updateId+1
      protocol_text = getText(rule.getElementsByTagName('protocol')[0].childNodes)
      direction_text = getText(rule.getElementsByTagName('direction')[0].childNodes)
      porttype_text = getText(rule.getElementsByTagName('porttype')[0].childNodes)
      if protocol_text == protocolstr and \
         direction_text == directionstr and \
         porttype_text == porttypestr:
	 port = rule.getElementsByTagName('port')[0]
	 port_text = ""
	 if len(port.getElementsByTagName('begin')) == 0:
	    port_text = getText(port.childNodes)
         else:
	    port_begin = getText(port.getElementsByTagName('begin')[0].childNodes)
	    port_end = getText(port.getElementsByTagName('end')[0].childNodes)
	    port_text = port_begin+"-"+port_end
	 if port_text == portstr:
	    service.removeChild(rule)
	    removeId = updateId
	    updateId = updateId-1

   if removeId == 0:
      print "port does not exists"
      return None
   else:
      if updateId == 0:
         RemoveRuleset()
      else:
         WriteBack()


########################################################################
#
# RemoveRuleset --
#      Remove one ruleset from firewall
# Input:
#      xmlName : user defined xml rule set
# Results:
#      Remove one ruleset from firewall
# Side effects:
#      None
#
########################################################################

def RemoveRuleset():
   os.remove(xmlName)
   os.system(" esxcli network firewall refresh")

InitFile()
dom = xml.dom.minidom.parse(xmlName)
root = dom.documentElement

service = root.getElementsByTagName('service')[0]

if sys.argv[1] == "add":
   if len(sys.argv) != 7:
      Usage()
      sys.exit()
   AddPort(sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6])
elif sys.argv[1] == "remove":
   if len(sys.argv) != 7:
      Usage()
      sys.exit()
   RemovePort(sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6])
elif sys.argv[1] == "list":
   if len(sys.argv) != 3:
      Usage()
      sys.exit()
   ListPort()
elif sys.argv[1] == "removeruleset":
   if len(sys.argv) != 3:
      Usage()
      sys.exit()
   RemoveRuleset()
else:
   Usage()
   sys.exit()


