#!/usr/bin/env python
# *** PLEASE NOTE this tool can only be run with root user ***
#
################################################################################

import sys
import getopt
import time
import re
import os
import socket
import struct
import ConfigParser

SCAPY_PYTHON_PATH = "/bldmnt/toolchain/noarch/scapy-2.1.0/lib/python2.7/" \
                    "site-packages"
sys.path.append(SCAPY_PYTHON_PATH)
from scapy.all import *

DEFAULT_HOST = '127.0.0.1'
DEFAULT_PROTOCOL = 'icmp'
BCAST_MAC = 'ff:ff:ff:ff:ff:ff'
# keep consistent with default value for testduration as 5
DEFAULT_PACKET_DURATION = 5
DEFAULT_INTERVAL = 1000
DEFAULT_SECTION = 'SCAPY_CONFIG'
ERROR_MESSAGE_PREFIX = 'ERROR:'
DEFAULT_TTL = 64


def ip2long(ip):
    '''
    This function converts an IPv4 IP address to integer
    '''
    return struct.unpack("!L", socket.inet_aton(ip))[0]

def long2ip(number):
    '''
    This function converts a number to IP
    '''
    return socket.inet_ntoa(struct.pack('!L', number))

def gen_mac(ip):
    '''
    This function generates MAC address from an IP address
    ip: ip string in *.*.*.* format
    return: MAC address with last 4 bytes same with IP address
    '''
    strr=':'
    mac = [ "%02x" % int(i) for i in ip.split('.')]
    mac.insert(0,'01')
    mac.insert(0,'00')
    return  strr.join(mac)

class ScapyTools(object):

    def __init__(self):
        """
        Initialize class member variables
        """
        self.config_parser = ConfigParser.RawConfigParser(allow_no_value=False)
        # Following attributes are packets related
        self.destination_address = None
        self.protocol = None
        self.source_address = None
        self.sourcemac = None
        self.destmac = None
        self.sourceiface = None
        self.version = 4
        # By default, will send 3 packets
        # Duration is in unit of second, interval is in millisecond
        self.duration = DEFAULT_PACKET_DURATION
        self.interval = DEFAULT_INTERVAL
        self.ipttl = DEFAULT_TTL
        # Please note pktcount has privilege over duration. If both specified,
        # pktcount will take effect.
        self.pktcount = 0
        # If verbose is set to 0, scapy function will be silent
        self.verbose = 0
        self.sourceport = None
        self.destport = None
        self.payload = ""
        self.tcpflags = None
        self.tcpseq = None
        self.tcpack = None

    def read_user_input(self, filename, section_name):
        """
        Read user input specified in filename
        Return 0 if successful, -1 if validation check fails
        """
        if not filename:
            print ERROR_MESSAGE_PREFIX + "File name not defined"
            return -1
        if not section_name:
            print ERROR_MESSAGE_PREFIX + "section name not defined"
            return -1

        self.config_parser.read(filename)

        if self.config_parser.has_option(section_name, 'destination_address'):
            self.destination_address = \
                self.config_parser.get(section_name, "destination_address")
        if self.config_parser.has_option(section_name, "protocol"):
            self.protocol = self.config_parser.get(section_name, "protocol")

        if self.config_parser.has_option(section_name, "source_address"):
            self.source_address = self.config_parser.get(section_name, "source_address")
        if self.config_parser.has_option(section_name, "source_mac"):
            self.sourcemac = self.config_parser.get(section_name, "source_mac")
        if self.config_parser.has_option(section_name, "destination_mac"):
            self.destmac = self.config_parser.get(section_name, "destination_mac")
        if self.config_parser.has_option(section_name, "sourceiface"):
            self.sourceiface = self.config_parser.get(section_name, "sourceiface")
        if self.config_parser.has_option(section_name, "ipttl"):
            self.ipttl = int(self.config_parser.get(section_name, "ipttl"))
        if self.config_parser.has_option(section_name, "debug"):
            debug = int(self.config_parser.get(section_name, "debug"))
            if (debug == 1):
                self.verbose = None
        if self.config_parser.has_option(section_name, "sourceport"):
            self.sourceport = int(self.config_parser.get(section_name, "sourceport"))
        if self.config_parser.has_option(section_name, "destport"):
            self.destport = int(self.config_parser.get(section_name, "destport"))
        if self.config_parser.has_option(section_name, "l3protocol"):
            l3protocol = self.config_parser.get(section_name,"l3protocol")
            if l3protocol.lower() == "ipv6":
                self.version = 6
        if self.config_parser.has_option(section_name, "payload"):
            self.payload = self.config_parser.get(section_name, "payload")
        if self.config_parser.has_option(section_name, "tcpflags"):
            self.tcpflags = self.config_parser.get(section_name, "tcpflags")
        if self.config_parser.has_option(section_name, "tcpseq"):
            self.tcpseq = int(self.config_parser.get(section_name, "tcpseq"))
        if self.config_parser.has_option(section_name, "tcpack"):
            self.tcpack = int(self.config_parser.get(section_name, "tcpack"))

        if (not self.protocol):
            print ERROR_MESSAGE_PREFIX + "Protocol not defined"
            return -1
        if (not self.sourcemac or not self.source_address):
            print ERROR_MESSAGE_PREFIX + "Source IP or MAC not defined"
            return -1
        if (not self.destination_address):
            print ERROR_MESSAGE_PREFIX + "Destination address not defined"
            return -1
        if (self.ipttl < 1 or self.ipttl > 255):
            print ERROR_MESSAGE_PREFIX + "TTL should be in between 1 and 255"
            return -1

        self.protocol = self.protocol.lower()
        if (self.protocol not in ['icmp', 'arp', 'tcp', 'udp']):
            print ERROR_MESSAGE_PREFIX + "Protocol %s is not supported" % self.protocol
            return -1

        duration = self.config_parser.get(section_name, "duration")
        if (duration != None):
            duration = int(duration)
            if (duration < 1 or duration > 3600):
                print ERROR_MESSAGE_PREFIX + "Duration should be in " \
                      "between 1 and 3600 seconds"
                return -1
            self.duration = duration

        if self.config_parser.has_option(section_name, "interval"):
            interval = self.config_parser.get(section_name, "interval")
            interval = int(interval)
            if (interval < 0 or interval > 60000):
                print ERROR_MESSAGE_PREFIX + "Interval should be in " \
                      "between 0 and 60000 milliseconds"
                return -1
            self.interval = interval

        if self.config_parser.has_option(section_name, "pktcount"):
            pktcount = self.config_parser.get(section_name, "pktcount")
            pktcount = int(pktcount)
            if (pktcount < 1 or pktcount > 10000):
                print ERROR_MESSAGE_PREFIX + "packet count should be in " \
                      "between 1 and 10000"
                return -1
            self.pktcount = pktcount
        if (self.sourceport != None and \
            (self.sourceport < 1 or self.sourceport > 65535)):
            print ERROR_MESSAGE_PREFIX + "source port should be in " \
                  "between 1 and 65535"
            return -1

        if (self.destport != None and \
            (self.destport < 1 or self.destport > 65535)):
            print ERROR_MESSAGE_PREFIX + "destination port should be in " \
                  "between 1 and 65535"
            return -1
        if (self.version == 6):
            if (self.destination_address.find('-') > 0):
                print ERROR_MESSAGE_PREFIX + "destination address as a range " \
                  " is not supported for IPv6"
                return -1
            if (self.source_address.find('-') > 0):
                print ERROR_MESSAGE_PREFIX + "source address as a range " \
                  " is not supported for IPv6"
                return -1

        return 0

    def dump_user_input(self):
        print "destination_address=%s" % self.destination_address
        print "protocol=%s" % self.protocol
        print "source_address=%s" % self.source_address
        print "sourcemac=%s" % self.sourcemac

    def define_ip_header(self, version=4, tos=None, ttl=None, proto=None,
                         src=None, dst=None):
        """
        Returns the IP object with header fields in Scapy'

        Inputs:
            src = source IP (e.g. "192.168.0.1")
            dst = destination IP (e.g. "192.168.0.2")
            version = IP version (e.g. 4L, 6L)
            tos = TOS field (e.g. 0x0)
            ttl = TTL value (e.g. 74)
            proto = scapy-defined proto string (e.g. "TCP", "UDP", "ICMP")

        Outputs:
            the scapy IP object
        """

        if version == 4:
            ip_pkt = IP()
        else:
            ip_pkt = IPv6()

        if src:
            ip_pkt.src = src

        if dst:
            ip_pkt.dst = dst

        if tos:
            ip_pkt.tos = tos

        if ttl:
            ip_pkt.ttl = ttl

        if proto:
            ip_pkt.proto = proto

        return ip_pkt

    def define_icmp_header(self, typeicmp=None, code=None,
                           seq=None, version=4):
        """
        Returns the ICMP object with header fields in Scapy'

        Inputs:
            typeicmp = ICMP type (e.g. 0L for echo reply, 8L for echo)
            code = ICMP code
            seq = sequence number (e.g. 0L, 23L)

        Outputs:
            the scapy ICMP object
        """
        #TODO: Add support for parameters

        if version == 4:
            icmp_pkt = ICMP()
        else:
            icmp_pkt = ICMPv6EchoRequest()

        return icmp_pkt

    def define_ethernet_header(self, src=None, dst=None, typeeth=None, tag=None):
        """
        Returns the Ether object to define an Ethernet packet into scapy'

        Inputs:
            src = source MAC (e.g. "AA:AA:AA:AA:AA:AA")
            dst = destination MAC (e.g. "BB:BB:BB:BB:BB:BB")
            typeeth = Ethernet type (e.g. 0x800)

        Outputs:
            the scapy Ether object
        """
        ether_header = Ether()
        if (dst == None):
            ether_header.dst = BCAST_MAC
        else:
            ether_header.dst = dst
        ether_header.src = src
        return ether_header

    def define_arp_header(self, psrc=None, pdst=None):
        """
        Returns the ARP object to define an arp packet into scapy'

        Inputs:
            psrc = IP of the host asking for info (e.g. "192.168.0.1")
            pdst = IP of the target ((e.g. "192.168.0.2"))

        Outputs:
            the scapy ARP object
        """
        arp_header = ARP()
        arp_header.pdst = pdst
        arp_header.psrc = psrc
        return arp_header

    def define_tcp_header(self, sport=None, dport=None, seq=None, ack=None,
                          flags=None):
        """
        Returns the TCP object to define a TCP packet into scapy'

        Inputs:
            sport = TCP source port (e.g. 23)
            dport = TCP source port (e.g. 34)
            seq = TCP sequence number (e.g. 0L, 0x0)
            ack = ACK flag (e.g. 0L, 1)
            flags = TCP flags (e.g. "S", "SA", etc.)

        Outputs:
            the scapy TCP object
        """
        tcp_header = TCP()
        tcp_header.sport = sport
        tcp_header.dport = dport
        if seq:
            tcp_header.seq = seq
        if ack:
            tcp_header.ack = ack
        if flags:
            tcp_header.flags = flags
        return tcp_header

    def define_udp_header(self, sport=None, dport=None):
        """
        Returns the UDP object to define a UDP packet into scapy'

        Inputs:
            sport = UDP source port (e.g. 23)
            dport = UDP source port (e.g. 34)

        Outputs:
            the scapy UDP object
        """
        udp_header = UDP()
        udp_header.sport = sport
        udp_header.dport = dport
        return udp_header

    def scapy_create_send_ICMP(self, ipdst):
        """
        This function creates and sends an ICMP Echo message to ipdst
        using all the default values at Eth/IP layer.
        """
        ip_header = self.define_ip_header(dst=ipdst)
        icmp_header = self.define_icmp_header()
        send(ip_header/icmp_header, count = DEFAULT_PACKET_DURATION)

    def scapy_create_send_ICMP_customized(self, ipdst, ipsrc, send1=True, \
        macdst=None, macsrc=None):
        """
        This function creates and sends an ICMP Echo message to ipdst
        using customized values at Eth/IP layer.
        Params: send1: if true only 1 packet will be sent
                       false will calculate packet count and send
        """
        ip_header = self.define_ip_header(dst=ipdst, src=ipsrc,\
                    ttl=self.ipttl, version=self.version)
        icmp_header = self.define_icmp_header(version=self.version)
        if send1:
            if (macdst == None):
                send(ip_header/icmp_header, verbose=self.verbose)
            else:
                ether_header = self.define_ethernet_header(src=macsrc, \
                    dst=macdst)
                sendp(ether_header/ip_header/icmp_header, verbose=self.verbose, \
                    iface=self.sourceiface)
            return

        pktcount = self.pktcount
        # If user does not specify pktcount, need calculate it based on
        # duration and interval
        if (pktcount == 0):
            pktcount = int(self.duration*1000/self.interval)
        send(ip_header/icmp_header, count=pktcount, inter=self.interval/1000.0,
             verbose=self.verbose)

    def scapy_create_send_ARP(self, ipdst):
        """
        This function creates and sends ARP messages to ipdst
        using all the default values at Eth/IP layer.
        """
        ether_header = self.define_ethernet_header()
        arp_header = self.define_arp_header(pdst=ipdst)
        sendp(ether_header/arp_header, count = DEFAULT_PACKET_DURATION,\
              iface=self.sourceiface)

    def scapy_create_send_ARP_customized(self, ipdst, ipsrc, macsrc, send1=True):
        """
        This function creates and sends ARP messages to ipdst
        using customized values at Eth/IP layer.
        Params: send1: if true only 1 packet will be sent
                       false will calculate packet count and send
        """
        ether_header = self.define_ethernet_header(src=macsrc)
        arp_header = self.define_arp_header(pdst=ipdst, psrc=ipsrc)
        if send1:
            sendp(ether_header/arp_header, verbose=self.verbose, \
                  iface=self.sourceiface)
            return
        pktcount = self.pktcount
        # If user does not specify pktcount, need calculate it based on
        # duration and interval
        if (pktcount == 0):
            pktcount = int(self.duration*1000/self.interval)
        sendp(ether_header/arp_header, count=pktcount,inter=self.interval/1000.0,
              iface=self.sourceiface, verbose=self.verbose)

    def scapy_create_send_layer4(self, ipdst, ipsrc, layer4proto="udp", \
        macdst=None, macsrc=None, payload=None):
        """
        This function creates and sends TCP/UDP packets to ipdst.
        If dest mac not specified, scapy will send it from L3.
        """
        if payload == None:
            # Payload cannot be None type, hence default to ''.
            payload = ''
        ip_header = self.define_ip_header(dst=ipdst, src=ipsrc,\
                    ttl=self.ipttl, version=self.version)
        ether_header = self.define_ethernet_header(src=macsrc, \
            dst=macdst)
        if layer4proto == "tcp":
            tcp_header = self.define_tcp_header(sport=self.sourceport,
                         dport=self.destport, seq=self.tcpseq, ack=self.tcpack,
                         flags=self.tcpflags)
            if (macdst == None):
                send(ip_header/tcp_header, verbose=self.verbose)
            else:
                sendp(ether_header/ip_header/tcp_header, verbose=self.verbose, \
                    iface=self.sourceiface)
        elif layer4proto == "udp":
            udp_header = self.define_udp_header(sport=self.sourceport,
                         dport=self.destport)
            if (macdst == None):
                send(ip_header/udp_header, verbose=self.verbose)
            else:
                sendp(ether_header/ip_header/udp_header/payload, verbose=self.verbose, \
                    iface=self.sourceiface)

    def scapy_create_send_layer4_with_l2header(self, ipdst, ipsrc, \
        layer4proto="udp", macdst=None, macsrc=None):
        """
        This function creates and sends TCP/UDP packets to ipdst with
        ethernet header specified.
        """
        ip_header = self.define_ip_header(dst=ipdst, src=ipsrc,\
                    ttl=self.ipttl, version=self.version)
        ether_header = self.define_ethernet_header(src=macsrc, \
            dst=macdst)
        if layer4proto == "tcp":
            tcp_header = self.define_tcp_header(sport=self.sourceport,
                         dport=self.destport, seq=self.tcpseq, ack=self.tcpack,
                         flags=self.tcpflags)
            sendp(ether_header/ip_header/tcp_header, verbose=self.verbose, \
                iface=self.sourceiface)
        elif layer4proto == "udp":
            udp_header = self.define_udp_header(sport=self.sourceport,
                         dport=self.destport)
            sendp(ether_header/ip_header/udp_header, verbose=self.verbose, \
                iface=self.sourceiface)

    def send_packets_to_IPv4_targets(self, dest, protocol):
        """
        This function sends packets to IPv4 targets specified with dest
        dest can be an IP address or address range like 1.1.1.1-1.1.1.10
        """
        dest_array = dest.split('-')
        start = dest_array[0]
        end = start
        if (len(dest_array) > 1):
            end = dest_array[1]
        for i in range (ip2long(start), ip2long(end)+1):
            # By default, send 3 packets
            current_dest = long2ip(i)
            print("Send %s packets to %s" % (protocol, current_dest))
            if protocol == "icmp":
               self.scapy_create_send_ICMP(current_dest)
            elif protocol == "arp":
               self.scapy_create_send_ARP()

    def send_packets_to_IPv4_targets_customized(self):
        """
        This function sends packets to IPv4 targets with fields like sourcemac,
        source_address, destmac, destination_address specified in class
        """
        pktcount = self.pktcount
        # If user does not specify pktcount, need calculate it based on
        # duration and interval
        if (pktcount == 0):
            pktcount = int(self.duration*1000/self.interval)

        # If destmac not specified, then use default value
        # If source_address is a range, then calculate source mac based on IP

        dest_array = self.destination_address.split('-')
        start = dest_array[0]
        end = start
        if (len(dest_array) > 1):
            end = dest_array[1]
        print("Send %s packets to %s from source %s" % (self.protocol, \
               self.destination_address, self.source_address))

        source_array = self.source_address.split('-')
        sstartip = source_array[0]
        sendip = sstartip
        if (len(source_array) > 1):
            sendip = source_array[1]
        for sip in range(ip2long(sstartip), ip2long(sendip)+1):
            sourceip = long2ip(sip)
            sourcemac = None
            if (len(source_array) > 1):
                sourcemac = gen_mac(sourceip)
            else:
                sourcemac = self.sourcemac
            destmac = self.destmac
            for count in range(0, pktcount):
                for i in range (ip2long(start), ip2long(end)+1):
                    current_dest = long2ip(i)
                    if self.protocol == "icmp":
                        self.scapy_create_send_ICMP_customized(current_dest,\
                             sourceip, True, destmac, sourcemac)
                    elif self.protocol == "arp":
                        self.scapy_create_send_ARP_customized(current_dest,\
                             sourceip, sourcemac)
                    elif self.protocol in ['tcp', 'udp']:
                        self.scapy_create_send_layer4(current_dest, sourceip, \
                             self.protocol, destmac, sourcemac, self.payload)
                    # Sleep between sending packets
                    time.sleep(self.interval/1000.0)

    def send_packets_to_IPv6_targets(self):
        """
        This function sends packets to IPv6 targets with fields like sourcemac,
        source_address, destmac, destination_address specified in class
        """
        pktcount = self.pktcount
        # If user does not specify pktcount, need calculate it based on
        # duration and interval
        if (pktcount == 0):
            pktcount = int(self.duration*1000/self.interval)
        sourceip = self.source_address
        destip = self.destination_address
        sourcemac = self.sourcemac
        destmac = self.destmac
        payload = self.payload

        for count in range(0, pktcount):
            if self.protocol == "icmp":
                self.scapy_create_send_ICMP_customized(destip,\
                    sourceip, True, destmac, sourcemac)
            elif self.protocol in ['tcp', 'udp']:
                self.scapy_create_send_layer4(destip, sourceip, \
                     self.protocol, destmac, sourcemac, payload)
            # Sleep between sending packets
            time.sleep(self.interval/1000.0)

    def send_packets_on_user_input(self, filename):
        """
        This function sends packets based on user inputs which are
        specified in filename
        """
        ret_value = self.read_user_input(filename, DEFAULT_SECTION)
        if (ret_value < 0):
            print ERROR_MESSAGE_PREFIX + \
                "Please check input parameters in file %s" % filename
            return

        if (self.version == 4):
            self.send_packets_to_IPv4_targets_customized()
        else:
            self.send_packets_to_IPv6_targets()

def print_help():
    print 'Usage: python scapy_tool.py -f config_file'
    print 'Unit test: python scapy_tool.py -u'

def unit_test():
    scapy_tools = ScapyTools()
    scapy_tools.send_packets_to_IPv4_targets(DEFAULT_HOST, DEFAULT_PROTOCOL)

def main():
    """
    Since this script will be called from perl layer with parameters,
    we accept user input parameters from config file
    Execute: python mcast_test.py  -f scapy_tool.conf
    This tool will read user input from scapy_tool.conf and send traffic based
    on that
    # cat scapy_tool.conf
    [SCAPY_CONFIG]
    protocol=icmp
    destination_address=172.16.247.164
    source_address=172.16.247.163
    source_mac=00:50:56:8a:61:a1
    destination_mac=00:01:02:03:04:05
    sourceiface=eth0
    ipttl=10
    duration=10
    interval=100
    sourceport=20
    destport=80
    debug=1

    [Note]: Unit for duration is second, unit for interval is millisecond
            If debug=1 is set, output for scapy function will be print
            These options are mandatory: protocol, destination_address,
            source_address, source_mac, sourceiface. Others are optional

    If you want to try this script, just run "python scapy_tool.py -u"
    which will send ICMP echo request to local host, that is,  '127.0.0.1'
    """
    filename = None

    try:
        opts, args = getopt.getopt(sys.argv[1:], 'f:hu', ['file=', 'help', 'unit_test'])
    except getopt.GetoptError, err:
        print ERROR_MESSAGE_PREFIX + str(err)
        print_help()
        sys.exit(1)

    for opt, value in opts:
        if opt in ('-f', '--file'):
            filename = value
        elif opt in ('-h', '--help'):
            print_help()
            sys.exit(0)
        elif opt in ('-u', '--unit_test'):
            unit_test()
            sys.exit(0)

    if not os.path.exists(filename):
        print ERROR_MESSAGE_PREFIX + "File %s does not exist" % filename
        sys.exit(1)

    scapy_tools = ScapyTools()
    scapy_tools.send_packets_on_user_input(filename)

if __name__ == '__main__':
    main()
