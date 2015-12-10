########################################################################
#
# Requirements/Use cases
#    Generating custom packet.
#    Generating raw packets
#    Generating from vmknic, vnic etc
#    Templates for well knows packets like tso, cso, lro etc
#    Ability to override params like MAC address, IP address in a packet generating from vm.1.vnic.1
#    Ability to generate encapsulated packets like VXLAN packet, IPSec etc
#    Support for encapsulated packets in packet template so that user can say send all these packets to my vswitch, ovs etc
#
########################################################################



########################################################################
#
# Design/User Interface
#    Some definitions first:
#    1) Session: in TrafficWorkload = two nodes + one direction + unique packet(Iterator already gives
#  unique combinations which helps with Uniqueness of packets being generated from any tool)
#    2) Flow: When we have multiple client(multiple netperfs talking to same netserver)
#   under a sesison we call them flows
#    3) Stream: in Spirent = two nodes + one direction + Unique TCPIP packet
#    Thus we can say Session = Stream
#    Please note currently TrafficWorkload runs multiple streams in parallel across
#    different nodes but not across different combinations, So ipv4 and ipv6 don't
#    run in parallel as of now.
#

"TrafficWorkload_1"  => {
   Type                 => "Traffic",#
   NoofOutbound         => "3",#
   TestDuration         => "5",# OR NumberOfPackets (we can decide on keyname later)
   Toolname             => "Spirent,PktGen"
   TestAdapter          => "vm.[1].vnic.[1]",#   So packets will be generated from
                        # vm.1.vnic.1 and send to vm.2.vnic.1 as the flow is outbound
                        # for testadapter. We are hitting a wall with the NoofOutbound
                        # and NoofInbound which I will mention below
   SupportAdapter       => "vm.[2].vnic.[1]",#
   MaxTimeout           => "9000",#
   Stream => {
      [1] => {
         srcMAC => "00:11:22",# when using single mac, "00:11:22-00:11:44,3"
                              # when using range with step size of 3
			      # Thus now we need to use Iterator both in TrafficWorkload and
			      # Spirent/PktGen Core API
			      # Iterator of TrafficWorkload will give unique streams
			      # Iterator of Core API will give different packets in that stream
			      # E.g. A single stream containing packets with different srcMACs
         dstMAC => # If srcMAC or dstMAC are not given by user it will be taken
                   # from TestAdapter and supportAdapter. *** Note: NoofOutbound help here ***
		   # NoofOutbound = 5 does not make much sense. Does it mean we want to send
		   # 5 streams of type stream.1 but then it will send 5 streams of Type
		   # stream.2 also so we somehow need to say the direction in the stream itself
		   # and the number of streams of that type
         Protocol => "ip",# multiple values not supported,# as it violates the defination
                          # of a stream, if user wants to send ipv6 stream at the
                          # same time then he needs to construct stream.[2]
         Length => "N-M,X",# if one wants to give false lenght in packets
         Data => "L3Header",# Supported values are pointer to inner header or raw
                            # data for generating raw packets. Thus data => "path to
                            # file containing raw data" OR should we have
         L3Header => {
            TypeofService =>
            TotalLenght => "N-M,#X"
            Id =>
            FragmentOffset =>
            TTL =>
            Protocol => "TCP", # multiple not supported. Same reason as above
            HeaderChecksum =>
            SrcAddress => "192.168.1.1-192.168.1.254" # Same comment as srcMAC in ethernet header
            DstAddress => # Same comments as dstMAC in ethernet header
            Payload => "L4Header" # Same comment as Data in ethernet header
            L4Header => {
               #This will have TCP header.
               srcPort =>
               dstPort =>
               data => "L2Header" # in case of encapsulated packets
               data => "payload" # in case of regular packets
               payload => "" # Either a string user wants to send, or a file content etc
               # Please commnet if data should point to payload and payload contains the info
               # or data should directly do so. I am talking about non-encapsulated/regular packets here
            }
         }
      }
      [2] => {  # A sample vxlan packet
         Protocol => "ip",
         Data => "L3Header",
         L3Header => {
            Protocol => "UDP",
            Payload => "L4Header"
            L4Header => {
               srcPort =>
               dstPort =>
               data => "L2Header"
               L2Header => {
                  Protocol => "ip",
                  Data => "L3Header",
                  L3Header => {
                     Protocol => "TCP",
                     Payload => "L4Header"
                     L4Header => {
                        srcPort =>
                        dstPort =>
                        data => " vdnet generated custome vxlan packet",
                     }
                  }
               }
            }
         }
      }
      [3] => {  # A sample TCP packet
         Protocol => "ip",
         Data => "L3Header",
         L3Header => {
            Protocol => "TCP",
            Payload => "L4Header"
            L4Header => {
               srcPort =>
               dstPort =>
               data => "vdnet generated custome TCP packet"
            }
         }
      }
   }
#
#
#
########################################################################



########################################################################
#
# Implementation/Code changes
#    * We need to create a cli pktgen.pl so that packets can be generated from
#      interfaces in a remote machine.
#    * Need to install libnet and libpcap in our VM templates as well + support
#      remote installation for non-vdnet VMs.
#    * Weather to use remoteAgent or staf to execute the binary?
#    * Who does below work, TrafficWorkload or core API?
#      ** Iterator   - there is per testadapter, duration, etc combinations +
#         per packet combinations.
#      ** connectivity test
#      ** post mortem
#    * Iterator in workload will treat Stream as just one combination as it will not
#      look inside Stream key(iterator ignores hashes). Thus the entire Stream hash will go to
#      Core API(Spirent or PktGen) and they will handle as per their abilities.
#      Spirent can take array of packet Specs. Pkt Gen cannot so it will pop each entry
#      and generate packets that way.
#    * Only Stream key will be part of keysdatabase when we implement keys db in TrafficWorkload,
#      not the keys inside Stream so again a user documentation problem, no one stop
#      place to find out all supported keys
#      For documentation we have to show all nested keys of ethernet in that one
#      stream key of keysdatabase.
#    * A common library for processing L3Header, L4Header etc + Iterator inside core
#      API giving packet combinations
#
########################################################################
