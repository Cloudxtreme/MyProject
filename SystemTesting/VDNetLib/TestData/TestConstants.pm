########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::TestData::TestConstants;

use strict;
use warnings;
use VDNetLib::Common::GlobalConfig;

use constant DEFAULT_VM_VERSION  => "vmx-10";
use constant DEFAULT_NETDUMP_SERVER => "10.18.68.182";
use constant INVALIDVMK  => "vmk100";

# Max default workload timeout
use constant MAX_TIMEOUT => "3600";

# LLDP Timeout for Cisco Switches
use constant LLDP_TIMEOUT => "185";

use constant DEFAULT_SERVER_ONE     => "prme-vmkqa-100-vm1";
use constant DEFAULT_SERVER_TWO     => "prme-vmkqa-100-vm2";
use constant DEFAULT_SERVER_THREE   => "prme-vmkqa-100-vm3";
use constant DEFAULT_SERVER_FOUR    => "prme-vmkqa-100-vm4";

use constant DEFAULT_TEST_IP   => "192.168.100.1";
use constant DEFAULT_TEST_IPV6 => "2009::100";
use constant DEFAULT_NETMASK   => "255.255.255.0";
use constant DEFAULT_PREFIXLEN => "24";
use constant DEFAULT_PREFIX_IPV6 => "64";
use constant DEFAULT_VMK_IP_1   => "192.168.10.1";
use constant DEFAULT_VMK_IP_2   => "192.168.20.1";
use constant DEFAULT_NETWORK_1  => "192.168.100.0/24";
use constant DEFAULT_NETWORK_2  => "192.168.200.0/24";
use constant EDIT_NETWORK_1     => "192.168.100.0/23";

use constant PRIMARY_IP_ADDRESS   => "192.168.1.1";
use constant SECONDARY_IP_ADDRESS_1   => "192.168.1.2";

use constant PRIMARY_DNS   => "10.112.0.1";
use constant SECONDARY_DNS   => "10.112.0.2";

use constant DEFAULT_IXGBE_MAXVFS => 61;

use constant DEFAULT_ANSWERFILE  => "answerfile.xml";

use constant DEFAULT_CLUSTER    => "/Profile/Profile-test/Profile-Cluster";

use constant VMK_TESTESX        => "-s -v 2 --n net/vmknet-testesx.py";
use constant DEFAULT_CLUSTER    => "/Profile/Profile-test/Profile-Cluster";

use constant FIREWALL_RULESET_PATH => 'firewall.ruleset["key-vim-profile-host-RulesetProfile-';
use constant FIREWALL_RULESET_POLICY => 'RulesetPolicy';
use constant FIREWALL_RULESET_OPTION => 'FixedRulesetOption';
use constant FIREWALL_RULESET_ENABLED => 'ruleEnabled';
use constant FIREWALL_RULESET_ALLOWALL=> 'allowedAll';
use constant VSWITCH_PATH => 'network.vswitch["key-vim-profile-host-VirtualSwitchProfile-vSwitch0"]';
use constant VSWITCH_LINK_PATH => VSWITCH_PATH . '.link';
use constant VSWITCH_LINKSPEC_POLICY => 'LinkSpecPolicy';
use constant VSWITCH_LINKSPEC_OPTION => 'PnicsByName';
use constant VSWITCH_NICNAME => 'nicNames';
use constant VSWITCH_NICNAME_VALUE => '["vmnic1"]';
use constant VSWITCH_BEACONCONFIG_POLICY => 'BeaconConfigPolicy';
use constant VSWITCH_BEACONCONFIG_OPTION => 'NewFixedBeaconConfig';
use constant VSWITCH_BEACONCONFIG_INTERVAL => 'interval';
use constant VSWITCH_BEACONCONFIG_VALUE => '2';
use constant VSWITCH_NETWORK_PATH => VSWITCH_PATH . '.networkPolicy';
use constant VSWITCH_NUMPORTS_PATH => VSWITCH_PATH . '.numPorts';
use constant VSWITCH_NUMPORTS_POLICY => 'NumPortsPolicy';
use constant VSWITCH_NUMPORTS_OPTION => 'FixedNumPorts';
use constant VSWITCH_NUM_PORTS => 'numPorts';
use constant VSWITCH_NUM_PORTS_VALUE => '256';
use constant VSWITCH_MTU_NAME => 'mtu';
use constant VSWITCH_MTU_VALUE => '3000';

use constant DVSHOSTNIC_PATH => ' network.dvsHostNic["key-vim-profile-host-DvsHostVnicProfile-Profile-vds-Profile-dvpg-vmk1"]';
use constant DVSPORT_SELECTION_POLICY => 'DvsPortSelectionPolicy';
use constant DVSPORT_SELECTION_OPTION => 'FixedDVPortgroupSelectionOption';
use constant DVS_NAME => 'dvsName';
use constant DVS_NAME_VALUE => 'Profile-vds';
use constant PORTGROUP_NAME => 'portgroupName';
use constant PORTGROUP_NAME_VALUE => 'Profile-dvpg';
use constant DVS_EARLY_BOOT_VNIC_POLICY => 'DvsEarlyBootVnicPolicy';
use constant DVS_EARLY_BOOT_VNIC_OPTION => 'VmknicDefaultEarlyBootOption';
use constant DVS_VNIC_TEAM_POLICY => 'policy';
use constant DVS_VNIC_ACTIVE_UPLINKS => 'activeUplinks';
use constant DVS_VNIC_VMNIC => 'vmnic2';
use constant DVS_VNIC_STANDBY_UPLINKS => 'standbyUplinks';

use constant DVS_UPLINK_KEY => 'key-vim-profile-host-PnicUplinkProfile-';
use constant DVS_UPLINK_PORT_POLICY => 'DvsUplinkPortPolicy';
use constant DVS_UPLINK_PORT_OPTION => 'FixedUplinkPortgroupOption';
use constant DVS_UPLINK_UPLINK_PORT => 'uplinkPort';
use constant DVS_UPLINK_UPLINK_PORT_VALUE => 'uplink2';
use constant DVS_UPLINK_PORTGROUP => 'uplinkPortgroup';
use constant DVS_UPLINK_PORTGROUP_VALUE => 'Profile-vds-DVUplinks-200';
use constant DVS_PNIC_POLICY => 'SingularPnicPolicy';
use constant DVS_PNIC_OPTION => 'PnicsByName';
use constant DVS_PNIC_NAME => 'nicNames';
use constant DVS_PNIC_NAME_VALUE => '["vmnic2"]';
use constant DVS_PNIC_NAME_VALUE_1 => '["vmnic1"]';

use constant STATIC_ROUTE_KEY => 'ipRouteConfig.GenericStaticRouteProfile';
use constant STATIC_IP_ROUTE_POLICY => 'StaticIpRoutePolicy';
use constant STATIC_IP_ROUTE_OPTION => 'FixedStaticIpRoute';
use constant NETWORK => 'network';
use constant NETWORK_IP => '192.168.99.1';
use constant PREFIX  => 'prefix';
use constant PREFIX_VALUE => '20';
use constant GATEWAY => 'gateway';
use constant GATEWAY_IP  => '1.1.1.1';
use constant DEVICE  => 'device';
use constant DEVICE_NAME  => 'vmk2';
use constant FAMILY => 'family';
use constant FAMILY_TYPE => 'IPv6';
use constant FAMILY_TYPE_IPV4 => 'IPv4';

use constant NETSTACK_PATH => 'network.GenericNetStackInstanceProfile["key-vim-profile-host-GenericNetStackInstanceProfile-defaultTcpipStack"]';
use constant NETSTACK_DNSCONFIG_PATH => NETSTACK_PATH . '.GenericDnsConfigProfile';
use constant NETSTACK_IPROUTECONFIG_PATH => NETSTACK_PATH . '.ipRouteConfig';
use constant NETSTACK_IPROUTE_GATEWAY6_POLICY => 'IpRouteDefaultGatewayPolicy';
use constant NETSTACK_IPROUTE_GATEWAY6_OPTION => 'FixedDefaultGatewayOption';

use constant HOSTPORTGROUP_PROFILE => 'network.hostPortGroup["key-vim-profile-host-HostPortgroupProfile-';
use constant HOSTPROUGP_MANAGEMENT => HOSTPORTGROUP_PROFILE . 'ManagementNetwork"]';
use constant HOSTPROUGP_MANAGEMENT_PATH => HOSTPROUGP_MANAGEMENT . '.networkPolicy';
use constant HOSTPROUGP_VLAN_PATH => HOSTPROUGP_MANAGEMENT . '.vlan';
use constant HOSTPROUGP_VSWITCH_PATH => HOSTPROUGP_MANAGEMENT . '.vswitch';
use constant HOSTPROUGP_IPADDRESS_PATH => HOSTPROUGP_MANAGEMENT . '.ipConfig';
use constant HOSTPROUGP_POLICY_PATH => HOSTPROUGP_MANAGEMENT;
use constant NETWORKPOLICY => 'networkPolicy';
use constant SECURITY_POLICY => 'NetworkSecurityPolicy';
use constant SECURITY_POLICY_OPTION => 'NewFixedSecurityPolicyOption';
use constant ALLOW_PROMISCUOUS => 'allowPromiscuous';
use constant FORGE_TRANSMITS => 'forgedTransmits';
use constant MAC_CHANGE => 'macChanges';
use constant TRAFFIC_SHAPING_POLICY => 'NetworkTrafficShapingPolicy';
use constant TRAFFIC_SHAPING_POLICY_OPTION => 'NewFixedTrafficShapingPolicyOption';
use constant ENABLED => 'enabled';
use constant AVERAGE_BANDWIDTH => 'averageBandwidth';
use constant PEAK_BANDWIDTH => 'peakBandwidth';
use constant BURST_SIZE => 'burstSize';
use constant AVERAGE_BANDWIDTH_VALUE => '999999';
use constant PEAK_BANDWIDTH_VALUE => '999999';
use constant BURST_SIZE_VALUE => '999999';
use constant NIC_TEAMING_POLICY => 'NetworkNicTeamingPolicy';
use constant NIC_TEAMING_POLICY_OPTION => 'FixedNicTeamingPolicyOption';
use constant POLICY => 'policy';
use constant TEAMING_POLICY_MODE_IP => 'loadbalance_ip';
use constant TEAMING_POLICY_MODE_SRCID => 'loadbalance_srcid';
use constant TEAMING_POLICY_MODE_SRCMAC => 'loadbalance_srcmac';
use constant TEAMING_POLICY_MODE_LOADBASED => 'loadbalance_loadbased';
use constant TEAMING_POLICY_MODE_EXPLICIT => 'failover_explicit';
use constant TEAMING_NOTIFY_SWITCHES => 'notifySwitches';
use constant TEAMING_ROLLING_ORDER => 'rollingOrder';
use constant TEAMING_REVERSE_POLICY => 'reversePolicy';

use constant NETWORK_ORDER_POLICY => 'NetworkNicOrderPolicy';
use constant NETWORK_ORDER_POLICY_OPTION => 'FixedNicOrdering';
use constant ACTIVE_NICS => 'activeNics';
use constant FIXEDNICORDERING_STANDBYNICS => 'standbyNics';
use constant DEFAULT_NIC_0 => '["vmnic0"]';
use constant DEFAULT_NIC => '["vmnic1"]';
use constant DEFAULT_NIC_1 => '["vmnic2"]';
use constant INVALID_NIC => '["vmnic20"]';
use constant FAILOVER_POLICY => 'NetworkFailoverPolicy';
use constant FAILOVER_POLICY_OPTION => 'NewFixedFailoverCriteria';
use constant CHECK_BEACON => 'checkBeacon';
use constant DEFAULT_TRUE => 'true';
use constant DEFAULT_FALSE => 'false';

# Default NFS MaxVolumes for ESX
use constant DEFAULT_NFS_MAXVOLUMES => "32";

# VDS TSAM sleep between monitor and traffic
use constant VDS2TSAM_SLEEP_STATS => "150";

#
# LACP sleep between nic add/remove and negotiation finish
# There is a independent->hot-standby->bundled state machine
# This 5s also considers network latency and host response time.
#
use constant LACP_SLEEP_STATS => "5";

# OVF Url
use constant OVF_URL => "http://engweb.eng.vmware.com/~netfvt/ovf/service_insertion/rhel-5-32-svr.ovf";
use constant OVF_URL_FOR_LOAD_BALANCER => "http://engweb.eng.vmware.com/~netfvt/ovf/load_balancer/rhel-5-32-svr-ovf.ovf";
use constant OVF_URL_RHEL6_32BIT_61SVM => "http://engweb.eng.vmware.com/~netfvt/ovf/Rhel6-32bit-6.1svm/Rhel6-32bit-6.1svm.ovf";
use constant OVF_URL_RHEL6_32BIT_60SVM => "http://engweb.eng.vmware.com/~netfvt/ovf-repository/Rhel6-32bit-6.0svm/RHEL6-32bit-6.0svm.ovf";

use constant ARRAY_VDNET_CLOUD_ISOLATED_VLAN_NONATIVEVLAN => [
   VDNetLib::Common::GlobalConfig::VDNET_VLAN_DHCP_A,
   VDNetLib::Common::GlobalConfig::VDNET_VLAN_DHCP_B,
   VDNetLib::Common::GlobalConfig::VDNET_VLAN_DHCP_C,
   VDNetLib::Common::GlobalConfig::VDNET_VLAN_DHCP_D,
   # Skipping 20 as thats the native VLAN
   VDNetLib::Common::GlobalConfig::VDNET_VLAN_DHCP_F,
   VDNetLib::Common::GlobalConfig::VDNET_VLAN_DHCP_G,
];

use constant ARRAY_VXLAN_CONFIG_TEAMING_POLICIES => [
   "LOADBALANCE_SRCMAC",
   "LOADBALANCE_SRCID",
   "LOADBALANCE_LOADBASED",
   "FAILOVER_ORDER",
   "ETHER_CHANNEL",
   # Skipping LACP policies as they require special setup
   #"LACP_V2",
   #"LACP_ACTIVE",
   #"LACP_PASSIVE",
];

# Default Tester Name
use constant DEFAULT_TESTER  => "netfvt";
use constant DEFAULT_FOLDER  => "Profile";
use constant DEFAULT_DATACENTER  => "Profile-test";
use constant DEFAULT_CLUSTER_NAME     => "Profile-Cluster";
# default hostprofile name
use constant HOSTPROFILE_FILE => "/tmp/hp.xml";
use constant ANSWER_FILE => "/tmp/ans.xml";
use constant TASKLIST_FILE => "/tmp/task.xml";

use constant PCI_USB_UHCI_0_ID => '000:00:1a.0';
use constant PCI_USB_UHCI_1_ID => '000:00:1a.1';
use constant PCI_VMNIC_ID => '000:01:00.1';

use constant PCI_PROFILE => 'pciPassThru_pciPassThru_PciPassThroughProfile';
use constant PCI_CONFIG_PROFILE => 'pciPassThru_pciPassThru_PciPassThroughConfigProfile';
use constant PCI_CONFIG_POLICY => 'pciPassThru.pciPassThru.PCIPassThroughConfigPolicy';
use constant PCI_CONFIG_OPTION => 'pciPassThru.pciPassThru.PCIPassThroughConfigPolicyOption';
use constant PCI_APPLY_POLICY  => 'pciPassThru.pciPassThru.PCIPassThroughPolicy';
use constant PCI_APPLY_OPTION  => 'pciPassThru.pciPassThru.PCIPassThroughApplyOption';
use constant PCI_IGNORE_OPTION => 'pciPassThru.pciPassThru.PCIPassThroughIgnoreOption';

# vnic MAC Address policy
use constant VNICPROFILE_MACADDRESS_POLICY => "MacAddressPolicy";
use constant VNICPROFILE_MACADDRESS_OPTION => 'UserInputMacAddress';
use constant VNICPROFILE_MACADDRESSPOLICY_NODEFAULTOPTION => "NoDefaultOption";
use constant VNICPROFILE_MAC_KEY => "mac";
use constant VNICPROFILE_MAC_VALUE => "00:01:02:03:04:05";

use constant VIRTUALNICNAMEPOLICY_PARAM_NAME => "vmkNicName";
use constant VIRTUALNICNAMEPOLICY_PARAM_VALUE => "vmk11";
use constant VIRTUALNICNAMEPOLICY => "VirtualNICNamePolicy";
use constant VIRTUALNICNAMEPOLICY_FIXED_OPTION => "FixedVirtualNICNameOption";

use constant VNICPROFILE_MTUPOLICY => "MtuPolicy";
use constant VNICPROFILE_MTUPOLICY_FIXEDMTUOPTION => "FixedMtuOption";
use constant VNICPROFILE_MTUPOLICY_FIXEDMTUOPTION_MTU => "mtu";
use constant VNICPROFILE_MTUPOLICY_FIXEDMTUOPTION_MTU_VALUE => 9000;

use constant VLANPROFILE => "VlanProfile";
use constant VLANPROFILE_VLANIDPOLICY => "VlanIdPolicy";
use constant VLANPROFILE_VLANIDPOLICY_FIXEDVLANIDOPTION => "FixedVlanIdOption";
use constant VLANPROFILE_VLANIDPOLICY_FIXEDVLANIDOPTION_VLANID => "vlanId";
use constant VLANPROFILE_VLANIDPOLICY_FIXEDVLANIDOPTION_VLANID_VALUE => 100;
use constant VLANPROFILE_VLANIDPOLICY_FIXEDVLANIDOPTION_VLANID_VALUE2 => 0;
use constant VLANPROFILE_VLANIDPOLICY_FIXEDVLANIDOPTION_VLANID_VALUE3 => 4094;

# ip address profile
use constant IPADDRESSPROFILE => "IpAddressProfile";
use constant IPADDRESSPOLICY => "IpAddressPolicy";
use constant FIXEDIPCONFIG => "FixedIpConfig";
use constant USERINPUTIPADDRESS => "UserInputIPAddress";
use constant FIXEDDHCPOPTION => "FixedDhcpOption";
use constant USERINPUTIPADDRESS_USEDEFAULT => "UserInputIPAddress_UseDefault";

# dns profile
use constant DNSCONFIGPOLICY => "DnsConfigPolicy";
use constant DNSVIRTUALNICPOLICY => "DnsVirtualNicPolicy";
use constant DNSVIRTUALNICCONNECTEDTOPORTGROUP => "DnsVirtualNicConnectedToPortgroup";
use constant DNSVIRTUALNICCONNECTEDTODVPORT => "DnsVirtualNicConnectedToDvPort";
use constant FIXEDDNSCONFIG => "FixedDnsConfig";
use constant DNSSERVERADDR => "address";
use constant DNSSERVERADDR_VALUE  => '["192.168.100.1"]';

use constant DHCP => "dhcp";
use constant DHCP_VALUE => 'false';
use constant DOMAINNAME => "domainName";
use constant DOMAINNAME_VALUE => "eng.abc.com";
use constant SEARCHDOMAIN => "searchDomain";
use constant SEARCHDOMAIN_VALUE  => '["eng.def.com"]';
use constant VIRTUALNICDEVICE => "virtualNicDevice";

# netstackinsance profile
use constant NETSTACKINSTANCEPROFILE => "NetStackInstanceProfile";
use constant NETSTACKINSTANCEPOLICY => "NetStackInstancePolicy";
use constant DEFAULTNETSTACKINSTANCE_NAME => "defaultTcpipStack";
use constant DEFAULTNETSTACKINSTANCE_INVALID_NAME => "myTcpipStack";
use constant NETSTACKINSTANCE_FIXEDOPTION => "FixedNetStackInstanceOption";
use constant NETSTACKINSTANCE_NAME => "instanceName";
use constant NETSTACKINSTANCE_CONGESTIONCTRLALGORITHM => "congestionCtrlAlgorithm";
use constant NETSTACKINSTANCE_CONGESTIONCTRLALGORITHM_CUBIC => "cubic";
use constant NETSTACKINSTANCE_CONGESTIONCTRLALGORITHM_NEWRENO => "newreno";
use constant NETSTACKINSTANCE_MAXCONNECTION => "maxConnections";
use constant NETSTACKINSTANCE_MAXCONNECTION_DEFAULT => "9999";
use constant NETSTACKINSTANCE_MAXCONNECTION_INVALID => "-9999";
use constant NETSTACKINSTANCE_IPV6ENABLED => "ipV6Enabled";

use constant GENERIC_NETSTACKINSTANCE_PROFILE => "GenericNetStackInstanceProfile";
use constant GENERIC_DNSCONFIG_PROFILE => "GenericDnsConfigProfile";
use constant GENERIC_IPROUTECONFIG_PROFILE => "ipRouteConfig";
use constant VIRTUALNICINSTANCEPOLICY => "VirtualNICInstancePolicy";
use constant VIRTUALNICINSTANCEPOLICY_FIXED_OPTION => "FixedVirtualNICInstanceOption";
use constant VIRTUALNICINSTANCEPOLICY_PRAM_NAME => "instanceName";
use constant VIRTUALNICNAMEPOLICY => "VirtualNICNamePolicy";
use constant VIRTUALNICNAMEPOLICY_FIXED_OPTION => "FixedVirtualNICNameOption";
use constant VIRTUALNICNAMEPOLICY_PARAM_NAME => "vmkNicName";
use constant STATELESSAUTOCONFPOLICY => "StatelessAutoconfPolicy";
use constant STATELESSAUTOCONFPOLICY_OPTION => "StatelessAutoconfOption";
use constant STATELESSAUTOCONFPOLICY_PARAM_NAME => "autoconf";
use constant FIXEDDHCP6POLICY => "FixedDhcp6Policy";
use constant FIXEDDHCP6POLICY_OPTION => "FixedDhcp6Option";
use constant FIXEDDHCP6POLICY_PARAM_NAME => "dhcpv6";
use constant IP6ADDRESSPOLICY => "Ip6AddressPolicy";

use constant VSWITCH_NAME_KEY => "vswitchname";
use constant VSWITCH_NAME_VALUE => "vSwitch100";
use constant VSWITCH_SELECTION_POLICY => "VswitchSelectionPolcy";
use constant VSWITCH_SELECTION_OPTION => "FixedVswitchSelectionOption";

use constant VIRTUAL_NIC_TYPE_POLICY => "VirtualNICTypePolicy";
use constant VIRTUAL_NIC_TYPE_OPTION => "FixedNICTypeOption";
use constant VIRTUAL_NIC_NAME => "nicType";
use constant VIRTUAL_NIC_VALUE => '["management"]';
use constant VIRTUAL_NIC_INVALID_VALUE => '["mgmt"]';

use constant IP_PIM_SPARSE_DENSE_MODE => "sparse-dense-mode";

use constant NETFLOW_IDLE_TIMEOUT => "60";

# ipv4 multicast protocol version used by Linux kernel
use constant IGMP_VERSION => '/proc/sys/net/ipv4/conf/all/force_igmp_version';
# ipv6 multicast protocol version used by Linux kernel
use constant MLD_VERSION => '/proc/sys/net/ipv6/conf/all/force_mld_version';

# default multicast ipv4/ipv6 addresses in traffic workload
use constant MULTICAST_IPV4_ADDR => '239.1.1.1';
use constant MULTICAST_IPV6_ADDR => 'ff39::1:1';
# Generic default route destination for multicast ipv4/ipv6.
# For IPv4, multicast address range is 224.0.0.0-239.255.255.255 (class D),
# i.e. basically the leading 4 bits should be 1110 => 224.0.0.0/4.
use constant MULTICAST_IPV4_ROUTE_DEST => '224.0.0.0/4';
# For IPv6 multicast address the leading 8 bits should be 11111111 => ff00::/8.
use constant MULTICAST_IPV6_ROUTE_DEST => 'ff00::/8';

# VM Settings
# Iterator doesn't like - as delimiter, so using :
use constant VM_TEMPLATE_UUID => 'aaaaaaaa:bbbb:cccc:dddd:eeeeeeeeeeee';
# NVS branch info
use constant NVS_DEFAULT_BRANCH => "northfirst";
# Controller info file on host
use constant CONTROLLER_INFO_FILE => '/etc/vmware/netcpa/config-by-vsm.xml';

#Default VDL2 Parameters
use constant VDL2MCASTIP_A => "239.0.0.8";
use constant VDL2MCASTIP_B => "239.0.0.9";
use constant VDL2MCASTIP_C => "239.0.0.10";
use constant VDL2ID_A => "100";
use constant VDL2ID_B => "1000";
#default NIOC version
use constant VDS_NIOC_DEFAULT_VERSION => 'version3';
#last NIOC version
use constant VDS_NIOC_LAST_RELEASED_VERSION => 'version2';
#default VDS version
use constant VDS_DEFAULT_VERSION => '6.0.0';
#Last VDS version
use constant VDS_LAST_RELEASED_VERSION => '5.5.0';
#Last supported VDS version
use constant VDS_LAST_SUPPORTED_VERSION => '5.1.0';
#default vdnetVM
use constant VDNet_DEFAULT_VM => 'RHEL63_srv_64';
#default VM Harware version
use constant VM_DEFAULT_HW_VERSION => 'vmx-10';
#Last Released VM Harware version
use constant VM_LAST_RELEASED_HW_VERSION => 'vmx-09';
#Last supported VM Harware version
use constant VM_LAST_SUPPORTED_HW_VERSION => 'vmx-08';
# 5 static IP for VXLAN cases 
use constant VXLAN_VM_STATIC_IP_1 => '192.168.200.1';
use constant VXLAN_VM_STATIC_IP_2 => '192.168.200.2';
use constant VXLAN_VM_STATIC_IP_3 => '192.168.200.3';
use constant VXLAN_VM_STATIC_IP_4 => '192.168.200.4';
use constant VXLAN_VM_STATIC_IP_5 => '192.168.200.5';
# 2 static IP for VDNET_VLAN_VDL2_D segment
use constant VXLAN_VTEP_STATIC_IP_1 => '172.19.1.20';
use constant VXLAN_VTEP_STATIC_IP_2 => '172.19.1.21';
# 2 static IP for VDNET_VLAN_VDL2_C segment
use constant VXLAN_VTEP_STATIC_IP_C1 => '172.18.1.20';
use constant VXLAN_VTEP_STATIC_IP_C2 => '172.18.1.21';
#Testing multicast group connectivity method
use constant VXLAN_CONN_CHECK_MULTICAST => 'multicast ';
#Performing ping test
use constant VXLAN_CONN_CHECK_PING => 'p2p';
#VXLAN Multicast udp traffic bandwidth
use constant VXLAN_MULTICAST_UDP_BANDWIDTH => '5M';
# 2 static macaddress for SRIOV testing
use constant SRIOV_STATIC_MAC_1 => '00:50:56:33:44:51';
use constant SRIOV_STATIC_MAC_2 => '00:50:56:33:44:52';
# Netdump for vsphere-2015 w2k8
use constant CONFIG_DIR_6 => "C:\\ProgramData\\VMware\\CIS\\data\\netdump\\";
use constant CONFIG_FILE_6 => "C:\\ProgramData\\VMware\\CIS\\data\\netdump\\netdump-setup.xml";
use constant TEMP_DIR_6 => "C:\\ProgramData\\VMware\\CIS\\data\\netdump\\";
use constant ORIGINAL_LOGS_DIR_6 => "C:\\ProgramData\\VMware\\CIS\\logs\\netdump\\";
use constant ORIGINAL_DATA_DIR_6 => "C:\\ProgramData\\VMware\\CIS\\data\\netdump\\Data\\";
# Netdump for ESXi 5 w2k8
use constant CONFIG_DIR_5 => 'C:\\ProgramData\\VMware\\VMware ESXi Dump Collector\\';
use constant CONFIG_FILE_5 => "C:\\ProgramData\\VMware\\VMware ESXi Dump Collector\\vmconfig-netdump.xml";
use constant TEMP_DIR_5 => 'C:\\ProgramData\\VMware\\VMware ESXi Dump Collector\\';
use constant ORIGINAL_LOGS_DIR_5 => "C:\\ProgramData\\VMware\\VMware ESXi Dump Collector\\logs\\";
use constant ORIGINAL_DATA_DIR_5 => "C:\\ProgramData\\VMware\\VMware ESXi Dump Collector\\Data\\";
# Netdump for ESXi 5 w2k3
use constant CONFIG_DIR_W2K3  =>
  "C:\\Documents and Settings\\All Users\\Application  Data\\VMware\\VMware ESXi Dump Collector\\";
use constant CONFIG_FILE_W2K3 =>
  "C:\\Documents and Settings\\All Users\\Application  Data\\VMware\\VMware ESXi Dump Collector\\vmconfig-netdump.xml";
use constant TEMP_DIR_W2K3 =>
  "C:\\Documents and Settings\\All Users\\Application Data\\VMware\\VMware ESXi Dump Collector\\";
use constant ORIGINAL_LOGS_DIR_W2K3 =>
  "C:\\Documents and Settings\\All Users\\Application Data\\VMware\\VMware ESXi Dump Collector\\logs\\";
use constant ORIGINAL_DATA_DIR_W2K3 =>
  "C:\\Documents and Settings\\All Users\\Application Data\\VMware\\VMware ESXi Dump Collector\\Data\\";
#Fault Tolerance
use constant CHECK_FAULT_TOLERANCE => "CheckFT";
use constant INJECT_FAULT_TOLERANCE => "InjectFT";
use constant SHAREDSTORAGE => "vdnetSharedStorage";
use constant FTLOGGING => "faultToleranceLogging";
use constant VMOTION => "vmotion";
use constant MANAGEMENT => "management";
use constant MAXSMPFTVMPERHOST => 'das.maxSmpFtVmsPerHost';
use constant MAXFTVMPERHOST => 'das.maxFtVmsPerHost';
use constant IGNOREINSUFFICIENTHBDATASTORE => 'das.ignoreInsufficientHbDatastore';

# Regex
# MAC address
use constant MAC_ADDR_REGEX => '(?:[0-9a-fA-F]{2})(?:(?:[:-][0-9a-fA-F]{2}){5})';

1;
