########################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
########################################################################
package VDNetLib::Common::GlobalConfig;

# This package contains all the Global data structures used across
# Virtual Device networking automation libraries, and scripts.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";

use VDNetLib::Common::VDErrorno qw( FAILURE SUCCESS VDSetLastError VDGetLastError );
use VDNetLib::Common::VDLog;
use Cwd;
use FindBin;
use Data::Dumper;

#
# Use a constant VDNetScriptPath
# to point to perl scripts under ../scripts/
#
use constant VDNetScriptPath => "$FindBin::Bin/../scripts/";
use constant OS_LINUX => 1;
use constant OS_WINDOWS => 2;
use constant OS_ESX => 3;
use constant OS_MAC => 4;
use constant OS_BSD => 5;
use constant DEFAULT_VDNET_SUPPORT_KERNEL => "2.6,3.0,3.2.0,3.5.0,3.8.0,3.12.15";
use constant VDNET_SUPPORT_MAXIMUM_KERNEL => "2.4,2.6,3.0,3.2.0,3.5.0,3.8.0,3.12.15";
use constant VDNET_SUPPORT_DRIVER_RELATED_KERNEL => "2.6.27,3.2.0,3.5.0,3.8.0,3.12.15";
use constant DEFAULT_VDNET_SUPPORT_NDISVER => "5.1,6.1,6.14";

use constant DEFAULT_WINDOWS_USER => "Administrator";
use constant DEFAULT_WINDOWS_PASSWORD => 'ca\\$hc0w';
use constant DEFAULT_KVM_VM_USER => 'root';
use constant DEFAULT_KVM_VM_PASSWORD => 'ca$hc0w';
use constant DEFAULT_ESX_VM_USER => 'root';
use constant DEFAULT_ESX_VM_PASSWORD => 'ca$hc0w';
use constant PASS => "PASS";
use constant FAIL => "FAIL";
use constant SKIP => "SKIP";
use constant TRUE => 1;
use constant FALSE => 0;
use constant EXIT_SUCCESS => 0;
use constant EXIT_FAILURE => 1;
use constant EXIT_ERROR   => 2;
use constant EXIT_SKIP    => 3;
use constant RUNTIME_DIR_MC => "/tmp/";
use constant RUNTIME_DIR_WIN => "C:\\\\Tools\\\\";

use constant STARTUP_DIR => "C:\\Documents and Settings\\Administrator\\" .
                            "Start Menu\\Programs\\Startup\\";
use constant WIN7_STARTUP_DIR => "C:\\ProgramData\\Microsoft\\Windows\\" .
                               "Start Menu\\Programs\\Startup\\";

use constant WAIT_TIMEOUT => 60;			# in seconds.
use constant STAF_CALL_TIMEOUT		=> 600;	        # in seconds.
							# This value was increased  to 1800
							# from 600, as a workaround for the
							# PR 683432. Change back to 600 on
							# May 12,2014
use constant DEFAULT_WORKLOAD_TIMEOUT	=> 3600;	# in seconds

use constant TRANSIENT_TIME => 60;

use constant START_ZOOKEEPER_TIMEOUT => 180;   # in seconds

# VMFS system base path
use constant VMFS_BASE_PATH => "/vmfs/volumes/";

# Logging defaults
use constant DEFAULT_LOG_LEVEL => 7; # INFO log level
use constant DEFAULT_LOG_FOLDER => "/tmp/vdnet";
use constant DEFAULT_LOG_FILE  => "vdnet.log";
use constant LOG_LEVEL_DEBUG => 8; # DEBUG log level

use constant DEFAULT_VDNET_SRC_SERVER => "scm-trees.eng.vmware.com";

use constant DEFAULT_TOOLCHAIN_SERVER => "build-toolchain.eng.vmware.com";
use constant DEFAULT_TOOLCHAIN_SHARE => "/toolchain";
use constant DEFAULT_TOOLCHAIN_MOUNTPOINT => "/bldmnt/toolchain";
#
# In esx50-stable branch use the following
#use constant DEFAULT_VDNET_SRC_DIR => "/trees/vdnet/esx50-stable/automation";
#
use constant DEFAULT_VDNET_COMMON_BASE_PATH => '/trees/vdnet';
use constant DEFAULT_VDNET_SRC_DIR => "/trees/vdnet/main/automation";
use constant VDNET_AUTOMATION_ROOT_DIR => "/automation";
use constant DEFAULT_VDNET_BRANCH => "master";
use constant DEFAULT_VDNET_2015_BRANCH => "2015";
use constant DEFAULT_VDNET_SRC_USR => 'eng_vdt_glob_1';
use constant DEFAULT_VDNET_SRC_PWD => '.a.YpYzu.eVU@ubU@EH';
use constant DEFAULTLOCKFILE => ".lckvdnet";
use constant DEFAULT_GUEST_BOOT_TIME => 1200; # considering 9 test adapters take
                                             # max time to get dhcp address
#default shared storage to use
use constant DEF_SHAREDSTORAGE =>
            "prme-bheemboy.eng.vmware.com:/nfs/vdnetSharedStorage";

# constant to match the persist data.
# Example: "nsxmanager.[1].logicalrouter.[1]->read_next_hop->next_hop"
use constant PERSIST_DATA_REGEX  => qr/\-\>\w\S*\-\>/;
use constant IP_REGEX => qr/\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/;

# Default netmask to be used for all test adapter
use constant DEFAULT_NETMASK  => "255.255.0.0";

# Default portgroup for vm vnic
use constant DEFAULT_VM_MANAGEMENT_PORTGROUP  => "VM Network";

use constant DEFAULT_PASSWORDS => ('ca\$hc0w', 'vmware', '');
# Default VC username, VC password, STAF server.
use constant DEFAULT_VC_LINUX_OS_USER => "root";
use constant DEFAULT_VC_LINUX_OS_PASSWD => "vmware";
use constant DEFAULT_STAF_SERVER     => "local";
use constant DEFAULT_VDL2_PASSWD     => "ca\\\$hc0w";
use constant DEFAULT_ESX_USER        => "root";
use constant DEFAULT_ESX_PASSWD      => "ca\$hc0w";
use constant DEFAULT_VC_CREDENTIALS  => {
             "administrator\@vsphere\.local" => "Admin\!23",
             "Administrator" => "ca\$hc0w",
             "root"       => "vmware" };

# switch specific.
use constant DEFAULT_DV_PORTS	      => "30";
use constant DEFAULT_SWITCH_TRANSPORT => "Telnet";
use constant DEFAULT_SWITCH_TYPE      => "cisco";
use constant DEFAULT_SWITCH_CREDENTIALS => { "vmware" => "ca\$hc0w",
                                             "admin"  => "ca\$hc0w" };
# netfvt specific
use constant NETFVT_USER     => "netfvt";
use constant NETFVT_PASSWORD => '!A@e.Ene!e6uqu6y.A!';
# nimbus gateway
use constant NIMBUS_GATEWAY  => "nimbus-gateway.eng.vmware.com";
use constant NETFVT_TRAMP    => "/mts/home4/netfvt/pxe/tramp";

# vsm user config
use constant DEFAULT_VSM_USERNAME => "admin";
use constant DEFAULT_VSM_PASSWORD => "default";
use constant DEFAULT_VSM_ROOT_PASSWORD => "default";

# nsx manager user config
use constant DEFAULT_NSX_MANAGER_USERNAME => "admin";
use constant DEFAULT_NSX_MANAGER_PASSWORD => "default";

# nsx controller user config
use constant DEFAULT_NSX_CONTROLLER_USERNAME => "admin";
use constant DEFAULT_NSX_CONTROLLER_PASSWORD => "Defaultca\$hc0w";

#edge user config
use constant DEFAULT_EDGE_USERNAME => "admin";
use constant DEFAULT_EDGE_PASSWORD => "default";

# perforce user for netfvt
use constant NETFVT_P4USER => "netfvt-automation";
use constant NETFVT_P4PASSWORD => "vdnet_rocks";

# neutron static testbed details
use constant KVM_CERT_1 => "-----BEGIN CERTIFICATE-----MIIDjTCCAnUCAQYwDQYJKo".
                           "ZIhvcNAQEEBQAwgYkxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJ".
                           "DQTEVMBMGA1UEChMMT3BlbiB2U3dpdGNoMRUwEwYDVQQLEwxj".
                           "b250cm9sbGVyY2ExPzA9BgNVBAMTNk9WUyBjb250cm9sbGVyY".
                           "2EgQ0EgQ2VydGlmaWNhdGUgKDIwMTMgSmFuIDE0IDIzOjE2Oj".
                           "ExKTAeFw0xMzExMDUxNzAxNDVaFw0xNDExMDUxNzAxNDVaMIG".
                           "OMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0ExFTATBgNVBAoT".
                           "DE9wZW4gdlN3aXRjaDEfMB0GA1UECxMWT3BlbiB2U3dpdGNoI".
                           "GNlcnRpZmllcjE6MDgGA1UEAxMxb3ZzY2xpZW50IGlkOmQ1Zj".
                           "NiOTRjLTM0NzQtNDE3NS05MmFiLTAwZDkxNDI0ODY0ZTCCASI".
                           "wDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALZqyt2V0ZGW".
                           "/gBBVEVYQtWIWcR4R9p+00OmnAYKXWxRQe7DHa+3oItnOaZUA".
                           "LfRd5bqNDWjUABSHpE7yBzqHE+f6Xdh4Uj9Ob8yk2XEn39FIl".
                           "+KrhaQsxBAEAZxt/WNTO7QZRilwmF07dkrajgPE1p0lWd7q5q".
                           "X+hc7tDp8jwRlc/BX7nBrs6NMa2ZW+OWPT7go8ZJ6LF+Uh4hI".
                           "sLo7B3yuKvoZ6uqGmTqNJ3Lyt6kSjhtyXgZ46GX5xHsUvoecl".
                           "3IzFma03zEEx5J8m5bnTsYcrzAbedRaGMIanMmLO0ewJyr0Mm".
                           "bBd1BlbmKS6MEZ4+BJNd7AEuLcJN59H7QSJTUCAwEAATANBgk".
                           "qhkiG9w0BAQQFAAOCAQEAZH1b4Ms+iYSf0hljWkYXEfmNENnN".
                           "f/fmW47IPeT0KWBa84OtOa+/GkO0bkScDc/xwXgVWGtiVBprb".
                           "c92RLo5s4ozL7FdyJYyMc21AFtQmIkjd2+kFW8KrMSxhg2VpR".
                           "ij/Q9ViDw3sSisIy3n5rRyU2/MxGO5159gTtD/VyZcF3Gfs8G".
                           "3ByHiyts2Gl4ZxwigZC58tFiIthErMV0wcaIQfyJcv2Mph7ho".
                           "C0Ly2omBFbFdNUg9ZMxawgtQxPTdafEu0aLAZAfEGgtEseear".
                           "aRLSWAdZX0p5nISQxLu06Br62JHUIVyCNnm5dgSQ5A0bgNNK4".
                           "PdpYpumJbYoVgko42eCQ==-----END CERTIFICATE-----";


# build web
use constant BUILDWEB => 'http://build-squid.eng.vmware.com/build/mts/release/';
use constant BUILDWEB_INDEX => '/publish/CUR-depot/ESXi/index.xml';

# space at the beginning and end is left intentional to check for whole word
use constant MACHINE_ENTRIES => " vm host switch prefixdir sync cache tools ".
                                "vnic vmnic switch pswitch ";
use constant supportedvnic   => " vmxnet3 vmxnet2 e1000 vlance e1000e ixgbe" .
                                " bnx2x bnx2 be2net ";
use constant supportedswitch => " vss vds ";
use constant supportedframework => " vdnet ats vcqe mh ";
use constant VALIDSTATUSCODES => qw(200 201 CREATED SUCCESS);

# reserve index, typically used to represent system defaults
use constant VDNET_RESERVE_INDEX => 0;

# Linux kernel minor version
use constant KERNEL_MINOR_VERSION => 18;
# Linux kernel major version
use constant KERNEL_MAJOR_VERSION => 2.6;

use constant TEST_NETWORK => '172.0.0.0/8';
use constant MGMT_NETWORK => '10.0.0.0/8';
# PHY VLAN CONFIGURATION

use constant VDNET_VLAN_DHCP_A => "16";
use constant VDNET_VLAN_DHCP_B => "17";
use constant VDNET_VLAN_DHCP_C => "18";
use constant VDNET_VLAN_DHCP_D => "19";
use constant VDNET_VLAN_DHCP_E => "20";
use constant VDNET_VLAN_DHCP_F => "21";
use constant VDNET_VLAN_DHCP_G => "22";
use constant VDNET_VLAN_DHCP_H => "243"; # BLR lab

use constant VDNET_VLAN_A => "16";
use constant VDNET_VLAN_B => "17";
use constant VDNET_VLAN_C => "18";
use constant VDNET_VLAN_D => "19";
use constant VDNET_VLAN_E => "21"; # vlan 20 is the native vlan
use constant VDNET_VLAN_VDL2_A => "16"; # need private dhcp
use constant VDNET_VLAN_VDL2_B => "17"; # need private dhcp
use constant VDNET_VLAN_VDL2_C => "18"; # need private dhcp
use constant VDNET_VLAN_VDL2_D => "19"; # need private dhcp
use constant VDNET_VLAN_VDL2_E => "21"; # need private dhcp + default gateway for VXLAN TSAM test
use constant VDNET_NATIVE_VLAN     => $ENV{VDNET_NATIVE_VLAN} ||
                                       VDNET_VLAN_A;
use constant DEFAULTVDSVERSION => "5.5";
#10G VLANs
use constant VDNET_10G_VLAN_A => "3333"; # no dhcp
use constant VDNET_10G_VLAN_B => "3334"; # no dhcp
use constant VDNET_10G_VLAN_C => "3003";
use constant VDNET_10G_VLAN_D => "3004";
use constant VDNET_NATIVE_VLAN_10G => $ENV{VDNET_NATIVE_VLAN_10G} ||
                                       VDNET_10G_VLAN_A;

#
# ip address for vds which is to be used for ipfix,
# hardcoding since this doesn't have any significance
# it is just used for identification purpose and the ipfix collectors
# expect the ip to associated with it.
#
use constant VDNET_VDS_IP_ADDRESS => "192.100.100.100";
use constant NETFLOW_COLLECTOR_PORT => "5000";
use constant NETFLOW_DOMAIN_ID => "900";

# ChannelGroup/PortChannel on Pswitch for LACP
use constant DEFAULT_CHANNEL_GROUP => 33;
use constant VDNET_CHANNEL_GROUP_A => 34;
use constant VDNET_CHANNEL_GROUP_B => 35;
use constant VDNET_CHANNEL_GROUP_C => 36;

# PVLANS
use constant VDNET_PVLAN_PRI_A => "170";
use constant VDNET_PVLAN_SEC_ISO_A => "171";
use constant VDNET_PVLAN_SEC_COM_A => "173";

use constant VDNET_ALLOWED_VLAN => VDNET_VLAN_A . "," . VDNET_VLAN_B . "," .
                                   VDNET_VLAN_C . "," . VDNET_VLAN_D . "," .
                                   VDNET_VLAN_E . "," . VDNET_PVLAN_PRI_A . "," .
                                   VDNET_PVLAN_SEC_ISO_A . "," .
                                   VDNET_PVLAN_SEC_COM_A;

# Remote SPAN VLAN
use constant VDNET_RSPAN_VLAN_A => "1000";
use constant VDNET_RSPAN_VLAN_B => "1001";

# Static IP for VMKnic

use constant VDNET_VMKNIC_IP_A => "172.25.10.1";
use constant VDNET_VMKNIC_IP_B => "172.16.10.1";
use constant VDNET_VMKNIC_NETMASK_A => "255.255.0.0";
use constant VDNET_VMKNIC_NETMASK_B => "255.255.0.0";

# Static Route for VXLAN VMKnic
use constant VDNET_VMKNIC_VXLAN_GATEWAY_A => "172.25.0.1";
use constant VDNET_VMKNIC_VXLAN_GATEWAY_B => "172.16.0.1";
use constant VDNET_VMKNIC_VXLAN_ROUTE_NETWORK => "172.0.0.0";
use constant VDNET_VMKNIC_VXLAN_ROUTE_NETMASK => "255.0.0.0";

use constant INLINE_JVM_INITIAL_PORT => 7500;
use constant STAFPROC_INITIAL_PORT  => 6510;
use constant ZOOKEEPER_INITIAL_PORT => 2182;
use constant ZOOKEEPER_TEST_SESSION_NODE => '/testbed';
use constant MAX_VDNET_SESSIONS  => 5;

# VXLAN Java configuration tools location
use constant VXLAN_TOOL_URL => "http://engweb.vmware.com/~wxzhang/VMware-vxlan-tool.tgz";


# TCPIP default stack instance
use constant DEFAULT_STACK_NAME => "defaultTcpipStack";

# Default VM repository, changed in Nov.06,2014 in PR 1353988
# TODO: Need use DNS name instead of IP address for server name
# so that do not need change options in different cloud
use constant DEFAULT_VM_SERVER => "10.115.160.201";
use constant DEFAULT_VM_SHARE  => "/fvt-protected-02";
use constant DEFAULT_VM_MOUNTPOINT => "/vdtest";

#
# The following information is to store the default NFS server which can used
# as shared storage (write permission enabled) for tests like vmotion
#
use constant DEFAULT_SHARED_SERVER => "10.115.160.201";
use constant DEFAULT_SHARED_SHARE  => "/fvt-1/vdnetSharedStorage";
use constant DEFAULT_SHARED_MOUNTPOINT => "vdnetSharedStorage";

# The size of testcase.log is bigger than this value will be counted in BIG LOG
use constant BIG_LOG_SIZE => 20 * 1024 * 1024;

# STAFSDK - Testware
use constant VC6X_STAFSDK  => "vc6x-testware";
use constant VC5X_STAFSDK  => "vc5x-testware";
use constant DEFAULTSTAFSDKBRANCH  => "vmkernel-main";

use constant WATCHDOG_PID_FILENAME => "watchdog-pids";

use constant FLOCK_SHARE => 1;
use constant FLOCK_EXCLUSIVE => 2;
use constant FLOCK_NON_BLOCKING => 4;
use constant FLOCK_UNLOCK => 8;

use constant LLDP_IPV6_ADDRESS => "fe80::2001:2:3";

# authserver user config
use constant DEFAULT_AUTHSERVER_USERNAME => "ess";
use constant DEFAULT_AUTHSERVER_PASSWORD => "ca\$hc0w";

# open vswitch control command
use constant OVS_VS_CTL => "ovs-vsctl";
use constant OVS_VTEP_CTL => "vtep-ctl";
use constant OVS_VTEP_BIN => "/usr/share/openvswitch/scripts/ovs-vtep";

our $STAF_STATIC_HANDLE;
use base 'Exporter';
our @EXPORT    = qw($vdLogger $sessionSTAFPort $STAF_DEFAULT_PORT $sshSession
                    PASS FAIL SKIP TRUE FALSE $STAF_STATIC_HANDLE PERSIST_DATA_REGEX
                    EXIT_SUCCESS EXIT_FAILURE EXIT_ERROR EXIT_SKIP OVS_VS_CTL
                    OVS_VTEP_CTL OVS_VTEP_BIN IP_REGEX);

@VDNetLib::Common::GlobalConfig::ISA = qw(Exporter);

our $STAF_DEFAULT_PORT = "6500";
our $sessionSTAFPort   = $STAF_DEFAULT_PORT;

my %TEST_PATH = (
   1  => "/root/d/",
   2  => "c:\\Tools\\",
   3  => "/root/Tests",
   4  => "/root/Tests",
   5  => "/root/",
);

my %CTRL_PATH = (
   1 => "/automation/VDNetLib/",
);

my %VDNET_SCRIPTS = (
   0 => "/automation/scripts/",
   1 => "/automation/scripts/",
   2 => "m:\\\\scripts\\\\",
   3 => "/automation/scripts/",
   4 => "/automation/scripts/",
   5 => "/automation/scripts/",

);

my %VDNET_MAIN = (
   0 => "/automation/main/",
   1 => "/automation/main/",
   2 => "m:\\\\main\\\\",
   3 => "/automation/main/",
   4 => "/automation/main/",
   5 => "/automation/main/",
);

my %BINARIES_PATH = (
   1 => "/automation/bin/",
   2 => "m:\\\\bin\\\\",
   3 => "/automation/bin/",
   4 => "/automation/bin/",
   5 => "/automation/bin/",
);

# Not sure why these are defined as local variable
my %EXIT_VALUE = (
   "EXIT_SUCCESS" => 0,
   "EXIT_FAILURE" => 1,
   "EXIT_ERROR" => 2,
);

my %VMWARE_LIB = (
   1 => "/usr/bin/",
   2 => "c:\\\\Program Files\\\\VMware\\\\VMware Workstation\\\\",
  #4 => "/Applications/VMware\\ Fusion.app/Contents/Library/",
   4 => "/Users/test/Desktop/VMware\\ Fusion.app/Contents/Library/",
);
#
# The array below has all the test categories in vdnet framework
# under fvt-networking
#

my @TESTSETS = qw(Sample SampleVC NetIORM);

#
# virtual networking devices related definitions
# vmkernel is not really a device type, for now keep
# this hack (TO DO - Find better way).
#
my @VD_NET_DEVICES = qw(vmxnet3 vmxnet2 e1000 vlance e1000e vmkernel ixgbe bnx2x);

# The below list of files required to be in C:\vmqa on windows to perform
# the setup activities like disabling firewall, event tracker, etc.
our  @winSetupFiles = ("install_vet_winguest.bat");

# The below data structure stores keys used to indicate parameters to tcpdump
# or windump program that can only be filled up during run time.  For example
# source mac address is only available after discovering the device under test
# The value of these keys indicate the method name of the
# VDNetLib::NetAdapter::NetAdapter
# which will return the actual value during run time.
# Example TCPDUMP expression used in the TDS:
# -p -c 500 src host %srcipv4% and dst host %dstipv4% and greater 8000'
# srcipv4 and dstipv4 enclosed with in % is computed during run-time using
# the information in the below data structure by function PrepareTcpdumpExpr
# in the VDNetLib::Verification::PktCapVerification package.
#
my %TCPDUMPEXPR = (
   'srcmac' => 'macAddress',
   'dstmac' => 'macAddress',
   'srcipv4' => "IPv4",
   'dstipv4' => "IPv4",
   'srcvlan' => "VLANId",
   'dstvlan' => "VLANId",
);

#######################################################################
# This is a hash for interrupt mode string to number match constants.
# The numbers indicate enum of the interrupt mode to be set in the
# vmx file with an entry. For example ethernetx.intrMode = "5" for
# Active mode of interrupt with INTX as interrupt selected.
########################################################################
my %INTERRUPTMODE = (
   'AUTO-INTX'   => 1,
   'AUTO-MSI'    => 2,
   'AUTO-MSIX'   => 3,
   'ACTIVE-INTX' => 5,
   'ACTIVE-MSI'  => 6,
   'ACTIVE-MSIX' => 7,
);

#######################################################################
# This is a hash for interrupt mode string to verification string match
# constants, where interrupt mode is the key and its corresponding value
# is a string for verification in case of linux gets from the contents of
# /proc/interrupts file.
# For example, for INTX the string seen in /proc/interrupts file is
# "vmxnet ether, eth", independent of if it is active or auto mode.
# INTERRUPTSTRING is for older kernels (2.6.18 or lower)
# MSI-X shows up as "IO-APIC-level  eth" in 2.6.18 and earlier but
# we do not support MSI-X in kernels older than 2.6.19 hence when MSI-X
# interrupt mode is set, MSI should be used instead by the driver
# NEWINTERRUPTSTRING is for newer kernels
# TODO Find a better place for this code (may be DeviceProperties.pm or
# NetAdapter.pm)
########################################################################

my %INTERRUPTSTRING = (
   'AUTO-INTX'   => "IO-APIC-level  eth",
   'AUTO-MSI'    => "PCI-MSI  eth",
   'AUTO-MSIX'   => "PCI-MSI  eth",
   'ACTIVE-INTX' => "IO-APIC-level  eth",
   'ACTIVE-MSI'  => "PCI-MSI  eth",
   'ACTIVE-MSIX' => "PCI-MSI  eth",
);

my %NEWINTERRUPTSTRING = (
   'AUTO-INTX'   => "fasteoi .* eth",
   'AUTO-MSI'    => "PCI-MSI-edge      eth",
   'AUTO-MSIX'   => "PCI-MSI-edge      eth",
   'ACTIVE-INTX' => "fasteoi .* eth",
   'ACTIVE-MSI'  => "PCI-MSI-edge      eth",
   'ACTIVE-MSIX' => "PCI-MSI-edge      eth",
);

our $vdLogger;

# DVFilter data structures
my %DVFilterAgents = (
   'esx41' => {
      'dvfilter-fw-slow' => {
         'name' => 'dvfilter-fw-slow',
         'type' => 'SlowPath',
         # location is relative to build tree
         # TODO beta should be replaced with the buildtype like beta,
         # obj, release
         'location' =>
          '/build/scons/package/devel/linux32/beta/esx/apps/dvfilter-fw-slow/'
      },
      'dvfilter-dummy' => {
         'name' => 'dvfilter-dummy',
         'type' => 'SlowPath',
         # verified the location the 4.1 build 260402
         'location' =>
          '/build/scons/package/devel/linux32/beta/esx/apps/dvfilter-fw-slow/',
      },
      'dvfilter-fw' => {
         'name' => 'dvfilter-fw',
         'type' => 'FastPath',
         # verified the location the 4.1 build 260402
         'location' =>
          'build/linux/bora/build/esx/beta/vmkmod-vmkernel64-signed/',
         'chardevname' => 'dvfilter-fw',
      },
   },
   'esx50' => {
      'dvfilter-generic' => {
         'name' => 'dvfilter-generic',
         'type' => 'FastPath',
         'location' => '/build/scons/package/devel/linux32/' .
                       'beta/esx/vmkmod-vmkernel64-signed/',
         'chardevname' => sub {
                                my $agentName = shift;
                                if (not defined $agentName) {
                                   $vdLogger->Error("undefined agent");
                                   VDSetLastError("EINVALID");
                                   return FAILURE;
                                }
                                return "/vmfs/devices/dvfilter-fw";
                          },
      },
   },
   'esx51' => {
      'dvfilter-generic' => {
         'name' => 'dvfilter-generic',
         'type' => 'FastPath',
         'location' => '/build/scons/package/devel/linux32/' .
                       'beta/esx/vmkmod-vmkernel64-signed/',
         'chardevname' => sub {
                                my $agentName = shift;
                                if (not defined $agentName) {
                                   $vdLogger->Error("undefined agent");
                                   VDSetLastError("EINVALID");
                                   return FAILURE;
                                }
                                return "/vmfs/devices/dvfilter-fw";
                          },
      },
   },
   'esx55' => {
      'dvfilter-generic' => {
         'name' => 'dvfilter-generic',
         'type' => 'FastPath',
         'location' => '/build/scons/package/devel/linux32/' .
                       'beta/esx/vmkmod-vmkernel64-signed/',
         'chardevname' => sub {
                                my $agentName = shift;
                                if (not defined $agentName) {
                                   $vdLogger->Error("undefined agent");
                                   VDSetLastError("EINVALID");
                                   return FAILURE;
                                }
                                return "/vmfs/devices/dvfilter-fw";
                          },
      },
   },
   'esx60' => {
      'dvfilter-generic' => {
         'name' => 'dvfilter-generic',
         'type' => 'FastPath',
         'location' => '/build/scons/package/devel/linux32/' .
                       'beta/esx/vmkmod-vmkernel64-signed/',
         'chardevname' => sub {
                                my $agentName = shift;
                                if (not defined $agentName) {
                                   $vdLogger->Error("undefined agent");
                                   VDSetLastError("EINVALID");
                                   return FAILURE;
                                }
                                return "/vmfs/devices/dvfilter-fw";
                          },
      },
   },
);

my %VMKLoadModOps = (
   'load' => sub {
                    my ($modname) = @_;
                    return "vmkload_mod $modname";
                 },
   'unload' => sub {
                    my ($modname) = @_;
                    return "vmkload_mod -u $modname";
                 },
   '_default_' => sub {
                    my ($options) = @_;
                    return undef if (not defined $options);
                    return "vmkload_mod $options";
                 },
);

my %DVFilterCtlOps = (
        'copy' => {
            'option' => '-c',
            'description' => 'copy \{0|1\} enable/disable copy of delayed packets',
            'method' => '',
        },
        'delay' => {
            option => '-d',
            description => 'delay<ms> set delay of matching packets',
            method => '',
        },
        'forward' => {
            option => '-f',
            description => 'forward \{0,1,2\} forward \{no, the matching,' .
                           ' all\} packets to the slow path agent',
            method => '',
        },
        'inbound' => {
            option => '-i',
            description => 'inbound \{0,1\} enable/disable matching ' .
                           'of inbound packets',
            method => '',
        },
        'loglevel' => {
            option => '-l',
            description => 'loglevel <level> set the driver\'s loglevel',
            method => '',
        },
        'dnaptport' => {
            option => '-n',
            description => 'dnaptport \{0,<port>\} enable/disable ' .
                           'rewriting destination port of matching TCP packets',
            method => '',
        },
        'outbound' => {
            option => '-o',
            description => 'outbound \{0,1\} enable/disable ' .
                           'matching of outbound packets',
            method => '',
        },
        'udp' => {
            option => '-u',
            description => 'udp \{0,<port>\} enable/disable matching of' .
                           ' UDP packets with either port being <port>',
            method => '',
        },
        'tcp' => {
            option => '-t',
            description => 'tcp \{0,<port>\} enable/disable ' .
                           'matching of TCP packets with either '.
                           ' port being <port>',
            method => '',
        },
        'device' => {
            option => '-D',
            description => 'device <dev> name of the control device',
            method => sub {
                         my ($branch, $dvfAgentName) = @_;
                         $vdLogger->Info("branch = $branch, ".
                                         "agentname = $dvfAgentName");
                         my $devName =
                            $DVFilterAgents{$branch}{$dvfAgentName}{chardevname};
                         if (ref($devName) eq "CODE") {
                            $devName = &$devName($dvfAgentName);
                         }
                         return "-D $devName";
            },
        },
        'fakeprocessing' => {
            option => '-F',
            description => 'fakeprocessing \{0,1\} enable/disable ' .
                           'simulated long packet processing',
            method => '',
        },
        'host' => {
            option => '-H',
            description => 'host <hostname>  hostname of the slow '.
                           'path agent to configure',
            method => '',
        },
        'filterName' => {
            option => '-N',
            description => 'filterName <name> name of the filter to control',
            method => '',
        },
        'icmp' => {
            option => '-I',
            description => 'icmp \{0,1\} enable/disable matching ICMP packets',
            method => '',
        },
        'port' => {
            option => '-P',
            description => 'port <port> port of the slow path ' .
                           'agent to configure',
            method => '',
        },
        'testIoctl' => {
            option => '-T',
            description => 'testIoctl <timeout> test the ioctl path',
            method => '',
        },
        'vcUUID' => {
            option => '-U',
            description => 'vcUUID <vcUUID> Alternative to ' .
                           'passing a filterName',
            method => '',
        },
        'vNICIndex' => {
            option => '-v',
            description => 'vNicIndex <idx>  vNicIndex of filter ' .
                           'Valid only and required if --vcUUID is used',
            method => '',
        },
);

########################################################################
# new --
#       Returns blessed referece to the VDNetLib::Common::GlobalConfig
#       object
#
# Input:
#       none
#
# Results:
#       none
#
# Side effects:
#       none
#
########################################################################

sub new
{
   my $self = shift;
   return  bless ({},$self);
}

########################################################################
# TcpDumpExpr --
#       This method return the above hash to the caller, caller can
#       access it via procedural syntax directly instead of going through
#       the below method.
#
# Input:
#       none
#
# Results:
#       none
#
# Side effects:
#       none
#
########################################################################

sub TcpDumpExpr
{
   my $self = shift;
   return \%TCPDUMPEXPR;
}


########################################################################
# VmwareLibPath --
#       The below method return the right path to all the fusion tools
#	given the OS type.
#
# Input:
#       OS type, 1 for linux, 2 for windows, 4 for Mac
#
# Results:
#       reference to absolute path of controllers in automation dir tree
#
# Side effects:
#       none
#
########################################################################

sub VmwareLibPath
{
   my $self = shift;
   my $arg  = shift;
   my $ref = $VMWARE_LIB{$arg};
   unless ($ref) {
      VDSetLastError("EINVALID");
   }
   return $ref;
}


########################################################################
# CtrlPath --
#       The below method return the right path to all the controllers given the
#       OS type.
#
# Input:
#       OS type, 1 for linux, 2 for windows
#
# Results:
#       reference to absolute path of controllers in automation dir tree
#
# Side effects:
#       none
#
########################################################################

sub CtrlPath
{
   my $self = shift;
   my $arg  = shift;
   my $ref = $CTRL_PATH{$arg};
   unless ($ref) {
      VDSetLastError("EINVALID");
   }
   return $ref;
}

########################################################################
# TestCasePath --
#       The below method return the right path to testcode given the OS type.
#
# Input:
#       OS type, 1 for linux, 2 for windows
#
# Results:
#       reference to absolute path of controllers in automation dir tree
#
# Side effects:
#       none
#
########################################################################

sub TestCasePath
{
   my $self   = shift;
   my $arg    = shift;
   my $pathto = shift || "scripts";

   my $ref;
   if ($pathto =~ /scripts/i) {
      $ref = $VDNET_SCRIPTS{$arg};
   } else {
      $ref = $VDNET_MAIN{$arg};
   }
   unless ($ref) {
      VDSetLastError("EINVALID");
   }
   return $ref;
}

########################################################################
# GetSetupDir --
#       The below method return the setup directory on windows
#
# Input:
#       OS type, 1 for linux, 2 for windows
#
# Results:
#       return setup directory for windows
#
# Side effects:
#       none
#
########################################################################

sub GetSetupDir
{
   my $self = shift;
   my $arg = shift;
   if ( $arg =~ /win/i ) {
      return "C:\\\\vmqa\\\\";
   }
   return undef;
}

########################################################################
# BinariesPath --
#       The below method return binaries directory for windows in automation
#       directory tree.
#
# Input:
#       OS type, 1 for linux, 2 for windows
#
# Results:
#       return binaries directory for windows
#
# Side effects:
#       none
#
########################################################################

sub BinariesPath
{
   my $self = shift;
   my $arg  = shift;
   my $ref = $BINARIES_PATH{$arg};
   unless ($ref) {
      VDSetLastError("EINVALID");
   }
   return $ref;
}

########################################################################
# GetExitValue --
#       Returns an integer corresponding to the given exit criteria
#
# Input:
#       Criteria - example, FAILURE, ERROR
#
# Results:
#       Returns integer 0,1,2 depending upon the given criteria
#
# Side effects:
#       none
#
########################################################################

sub GetExitValue
{
   my $self = shift;
   my $criteria = shift;
   my $value = $EXIT_VALUE{$criteria};
   return $value;
}

########################################################################
# TestPath --
#       Returns test path for a given OS
#
# Input:
#       OS type
#
# Results:
#       Returns directory name for the given OS
#
# Side effects:
#       none
#
########################################################################

sub TestPath
{
   my $self = shift;
   my $arg = shift;
   my $ref = $TEST_PATH{$arg};
   return $ref;
}


########################################################################
# GetOSType --
#       Returns OS Type of the machine
#
# Input:
#       none
#
# Results:
#       OS_WINDOWS or OS_LINUX
#
# Side effects:
#       none
#
########################################################################

sub GetOSType
{
   my $self = shift;
   if ($^O =~ /MSWin/i) {
      return OS_WINDOWS;
   } elsif ($^O =~ /Linux/i) {
      return OS_LINUX;
   } elsif ($^O =~ /darwin/i){
      return OS_MAC;
   } elsif ($^O =~ /freebsd/i){
      return OS_BSD;
   }
}

########################################################################
# GetAllVDNetDevices --
#       Returns the above list of (para)virtual devices.
#
# Input:
#       none
#
# Results:
#       reference to array that has list of (para)virtual devices
#
# Side effects:
#       none
#
########################################################################

sub GetAllVDNetDevices
{
   return (\@VD_NET_DEVICES);
}

########################################################################
# GetAllTestSets --
#       Returns list of all testsets - the above array
#
# Input:
#       none
#
# Results:
#       reference to array that has list of testsets
#
# Side effects:
#       none
#
########################################################################

sub GetAllTestSets
{
   return (\@TESTSETS);
}

########################################################################
# GetInterruptMode --
#        This is a method to get the interrupt mode numeral from
#        the interrupt mode for making an entry into vmx file.
#
# Input:
#        Takes a Interrupt mode string
#        Ex: AUTO-INTX  or AUTO-MSI or AUTO-MSIX for Auto mode
#        ACTIVE-INTX or ACTIVE-MSI or ACTIVE-MSIX for Active Mode
#
# Results:
#        returns a number corresponding the Interrupt mode string
#
# Side effects:
#        None
#
########################################################################

sub GetInterruptMode
{
   my $self = shift;
   my $mode = shift;
   $mode = uc $mode;

   return $INTERRUPTMODE{$mode};
}

########################################################################
# GetInterruptString --
#       This method returns a string corresponding to the interrupt mode
#       and the return value is a match string in the /proc/interrupts
#       file contents in case of Linux VM
#
# Input:
#       Takes a Interrupt mode string
#       Ex: AUTO-INTX  or AUTO-MSI or AUTO-MSIX for Auto mode
#       ACTIVE-INTX or ACTIVE-MSI or ACTIVE-MSIX for Active Mode
#       And kernel version
#
# Results:
#       Returns a string for verification from /proc/interrupts
#       file on linux guests.
#
# Side effects:
#       None
#
########################################################################

sub GetInterruptString
{
   my $self = shift;
   my $mode = shift;
   my $version = shift;
   my $majorVersion = shift;
   $mode = uc $mode;

   if (((not defined $majorVersion) || ($majorVersion <= KERNEL_MAJOR_VERSION))&& ((not defined $version) || ($version <= KERNEL_MINOR_VERSION))) {
      return $INTERRUPTSTRING{$mode};
   } else {
      return $NEWINTERRUPTSTRING{$mode};
   }
}


########################################################################
# CreateVDLogObj --
#      Creates a VDNetLib::Common::VDLog object and assigns the object
#      to the global variable $vdLogger defined in
#      VDNetLib::Common::GlobalConfig.
#      Also sets the environment variables VDNET_LOGLEVEL,
#      VDNET_LOGTOFILE, VDNET_LOGFILENAME, VDNET_VERBOSE.
#
# Input:
#      Hash containing keys (attributes of VDNetLib::Common::VDLog class)
#      logLevel, logToFile, logFileName, verbose.
#      Refer to VDNetLib::Common::VDLog.pm for their attributes
#      description
#
# Results:
#      None
#
# Side effects:
#      A VDNetLib::Common::VDLog object is assigned to global variable
#      $vdLogger
#
########################################################################

sub CreateVDLogObj
{
   my %vdLog = @_;
   if (not defined $vdLog{'logLevel'}) {
      $vdLog{'logLevel'} = DEFAULT_LOG_LEVEL;
   }
   if (not defined $vdLog{'logFileLevel'}) {
      $vdLog{'logFileLevel'} = LOG_LEVEL_DEBUG;
   }
   if (defined $vdLog{'logLevel'}) {
      $ENV{VDNET_LOGLEVEL} = $vdLog{'logLevel'};
   }
   if (defined $vdLog{'logToFile'}) {
      $ENV{VDNET_LOGTOFILE} = $vdLog{'logToFile'};
   }
   if (defined $vdLog{'logFileName'}) {
      $ENV{VDNET_LOGFILENAME} = $vdLog{'logFileName'};
   }
   if (defined $vdLog{'verbose'}) {
      $ENV{VDNET_VERBOSE} = $vdLog{'verbose'};
   }
   $vdLogger = new VDNetLib::Common::VDLog(%vdLog);
}

########################################################################
#
# GetLogsDir --
#      Returns the temp dir on Master Controller which can be used for
#      storing temp files like packetCapture files, combination file,
#      netperf stdout file etc.
#      If the dir is not present then it is created and permissions are
#      set to write.
#      For windows os, dir is created in MC and as MC's mount point is
#      available in win, the method returns windows's runtimeDir
#
# Input:
#      os(optional) - is required in case of windows. This input is not
#                     required when calling this method for
#                     linux/MasterController
#
# Results:
#      None
#
# Side effects:
#
########################################################################

sub GetLogsDir
{
   my $os = shift || undef;
   if (not defined $os){
      $os = "linux";
   }
   my $dir = RUNTIME_DIR_MC;
   unless(-d $dir){
      mkdir $dir, 777 or VDSetLastError("EFAIL");
   }
   chmod(0777, $dir) or VDSetLastError("EFAIL");

   if ($os =~ m/win/i){
      return RUNTIME_DIR_WIN;
   } else {
      return $dir;
   }
}

###############################################################################
#
# GetVdNetRootPath --
#      This method get vdNet root path.
#
# Input:
#      None
#
# Results:
#      Returns a string, if success.
#      Returns udnef, if any error occured.
#
# Side effects:
#      None.
################################################################################

sub GetVdNetRootPath
{
   my $launchingPath;
   my $pwdPath;
   my $pwdPath1;
   my $fullPath;
   my $fullPath1;
   my $vdNetRootPath;
   my $i=-1;
   my $count=0;

   $launchingPath=$0;
   $pwdPath=getcwd;
   # Check launching vdNet.pl path from Absolute path or Relative path
   $i=index($launchingPath,"/");
   if($i == 0){
      # Launching vdNet.pl from Absolute path
      $i=index($launchingPath,"/main/vdNet.pl");
      $vdNetRootPath=substr($launchingPath,0,$i);
   }else{
      # Launching vdNet.pl from Relative path
      $fullPath=$pwdPath."/".$launchingPath;
      # Relative path include three cases ./abc or ../abc or abc/xyz/..
      $i=index($launchingPath,"./");
      if($i == -1){
         # String start with abc/...
         $fullPath=$pwdPath."/".$launchingPath;
      }elsif($i == 0){
         # String start with './', removing './' in $launchingPath
         $fullPath=$pwdPath."/".substr($launchingPath,2);
      }else{
         # String start with '../'
         # count '../' number in $launchingPath and remove corresponding level directory in $pwdPath
         $count = 0;
         while( $launchingPath =~ /\.\.\//g )
         {
            $count ++;
         }
         my @array1 = split(/\//, $pwdPath);
         my @array2 = split(/\//, $launchingPath);
         print "\@array1=@array1, \@array2=@array2 \n";
         for( $i=0; $i < $count; $i++ )
         {
            pop(@array1);
            shift(@array2);
         }
         $fullPath="";
         $fullPath=join("/",@array1);
         $fullPath1=join("/",@array2);
         $fullPath="$fullPath/$fullPath1";
      }
      $i=index($fullPath,"/main/vdNet.pl");
      $vdNetRootPath=substr($fullPath,0,$i);
   }
   return $vdNetRootPath;
}

###############################################################################
#
# GetVDL2ConfigToolPath --
#      This method get VDL2 configuration tool path.
#
# Input:
#      None
#
# Results:
#      Returns absolute path to vdl2 config tool (string), if success.
#      Returns undef, if any error occured.
#
# Side effects:
#
################################################################################

sub GetVDL2ConfigToolPath
{
   my $logFileName;
   my $cfgToolsDir;
   my $pathIndex;
   my $logFilePath;
   # Get log path
   $logFileName = $vdLogger->GetLogFileName();
   $pathIndex = rindex($logFileName, '/');

   $logFilePath = substr($logFileName,0,$pathIndex);
   $cfgToolsDir = "$logFilePath/../VDL2cfgTool";
   return $cfgToolsDir;
}

########################################################################
#
# GetDVFilterAgents --
#
# Input:
#      branch: esx41 or esx50
#      build_type: release, beta, opt
#
# Results:
#      Return DVFilterAgents hash
#
# Side effects:
#
########################################################################

sub GetDVFilterAgents
{
   my $self = shift;
   my $branch = shift;
   my $build_type = shift;
   my $dvfilter_agents;
   my $key;
   if (!$branch || !$build_type) {
       return undef;
   }
   $dvfilter_agents = $DVFilterAgents{lc($branch)};
   if (!$dvfilter_agents) {
        return undef;
   }
   $build_type = lc($build_type);
   if ($build_type !~ /beta/i) {
       foreach $key (keys %$dvfilter_agents) {
          if ($dvfilter_agents->{$key}->{location}) {
              $dvfilter_agents->{$key}->{location} =~ s/beta/$build_type/;
          }
       }
   }
   return  $dvfilter_agents;
}


########################################################################
#
# GetDVFilterCtlOps --
#      Return DVFilterCtlOps hash
#
# Input:
#      None
# Results:
#      None
#
# Side effects:
#
########################################################################

sub DVFilterCtlOps
{
   return (\%DVFilterCtlOps);
}


########################################################################
#
# GetVMKLoadModOps --
#      Return VMKLoadModOps hash
#
# Input:
#      None
# Results:
#      None
#
# Side effects:
#
########################################################################

sub GetVMKLoadModOps
{
   my $self = shift;

   return (\%VMKLoadModOps);

}


########################################################################
#
# GetTDSList--
#      Method to get the list of TDSes in VDNet.
#
# Input:
#      tdsPath: absolute path to the directory which contains all TDS
#               packages (classes that inherit
#               TDS::Main::VDNetMainTDS class). The file names in this
#               directory should end with "Tds.pm" (Optional)
#      tds    : any specific TDS file name (Optional)
#
# Results:
#      Reference to an array of TDS, if successful. For example, the
#      TDS name will be EsxServer.VDS.LLDP;
#
# Side effects:
#      None
#
########################################################################

sub GetTDSList
{
   my $self    = shift;
   my $tdsPath = shift;
   my $tds     = shift;
   my $TestSetTds;
   my @tdslist;

   #
   # If tdsPath is not defined then assuming the directory structure in
   # //depot/vdnet/main/automation, use $FindBin::Bin/../TDS as tdsPath
   #
   $tdsPath = (defined $tdsPath) ? $tdsPath : "$FindBin::Bin/../TDS";
   #$tds = (defined $tds) ? $tds . "Tds.pm" : "*Tds.pm";

   #
   # If no specific tds file name is given, then look for all tds files
   # under the tdsPath.
   #
   $tds = (defined $tds) ? $tds : "*";

   # append "Tds.pm" with tds name if not already present
   my $perlTds = $tds . "Tds.pm";
   my $yamlTds;
   if ($tds !~ /Tds\.yaml$/) {
      $yamlTds = $tds . "Tds.yaml";
   }

   my $result;
   if ($tds ne "*" ) {
      if (-f $tdsPath . '/' . $yamlTds) {
         $result = $tdsPath . '/' . $yamlTds;
      } elsif (-f $tdsPath . '/' . $perlTds) {
         $result = $tdsPath . '/' . $perlTds;
      } else {
         return undef;
      }
   } else {
      # wildcard option * given, so find all the tds files
      my $cmd = "find $tdsPath -name $yamlTds";
      $vdLogger->Debug("Command to find TDS list: $cmd");
      $result = `$cmd`;
      if (($result eq "") || ($tds eq "*")) {
         $cmd = "find $tdsPath -name $perlTds";
         $result .= `$cmd`;
         if ($result eq "") {
            return undef;
         }
      }
   }

   my @temp = split(/\n/,$result);

   foreach my $set (@temp) {
      #
      # As per VDNet's directory structure, the absolute tds path
      # format should be
      # TDS/<Category>/<Component>/[<SubComponentName>]/<TDSName>.pm
      # Parse and select the portion of absolute path that starts from
      # TDS/
      #
      # Also, vdNet.pl command line does not expect the TDSname to have
      # TDS. in the beginning and Tds.pm at the end, so remove it here as
      # well to avoid confusion.
      #
      if (($set =~ /.*\/TDS\/(.*)Tds\.pm$/) ||
         ($set =~ /.*\/TDS\/(.*)Tds\.yaml$/)) {
         $set = $1;
         $set =~ s/\//\./g;     # replace / with .

         #
         # Don't consider TDSes "Main.VDNetMain" and "Main.Template" as they
         # not valid TDS
         #
         if (($set eq "Main.VDNetMain") ||
             ($set eq "Main.Template")) {
            next;
         }
         push (@tdslist, $set);
      } else {
         next;
      }
   }
   return \@tdslist;
}


###############################################################################
#
# GetWatchdogFilePath --
#      This method gets watch dog file path.
#
# Input:
#      None
#
# Results:
#      Returns absolute path to watch dog file (string), if success.
#      Returns undef, if any error occured.
#
# Side effects:
#
################################################################################

sub GetWatchdogFilePath
{
   my $logFileName;
   my $watchdogFilePath;
   my $pathIndex;
   my $logFilePath;
   # Get log path
   $logFileName = $vdLogger->GetLogFileName();
   $pathIndex = rindex($logFileName, '/');

   $logFilePath = substr($logFileName,0,$pathIndex);
   $watchdogFilePath = "$logFilePath/../" . WATCHDOG_PID_FILENAME;
   return $watchdogFilePath;
}


########################################################################
#
# GetSourceDir--
#     Routine to get vdnet source directory
#
# Input:
#     sourceInput: vdnet source input in <server>:<share> format
#                 (optional)
#
# Results:
#     (<server>, <share directory>) if successful;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetSourceDir
{
   my $sourceInput = shift;

   if (not defined $sourceInput) {
      return GetDefaultVDNetSourceDirectory();
   } else {
      return GetUserSourceDirectory($sourceInput);
   }
}


########################################################################
#
# GetDefaultVDNetSourceDirectory--
#     Routine to get vdnet default source directory
#
# Input:
#     None
#
# Results:
#     (<server>, <share directory>) if successful;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetDefaultVDNetSourceDirectory
{
   my $sourceDir = DEFAULT_VDNET_COMMON_BASE_PATH;
   my $sourceServer = DEFAULT_VDNET_SRC_SERVER;
   $vdLogger->Warn("VDNet source will be mounted from " .
                   DEFAULT_VDNET_SRC_SERVER . ", use src option to " .
                   "export local changes via NFS");
   my $result = `cd $FindBin::Bin && git branch`;
   my $branch;
   if ($result =~ /\*\s(.*)/) {
      $branch = $1;
   } else {
      $vdLogger->Error("Unable to find branch information: $result");
      $branch = DEFAULT_VDNET_BRANCH;
   }
   my $branchMap = {
      DEFAULT_VDNET_BRANCH => 'main',
      DEFAULT_VDNET_2015_BRANCH   => 'vdnet-2015',
   };
   if (exists $branchMap->{$branch}) {
      $sourceDir .= "/$branchMap->{$branch}";
   } else {
      $sourceDir .= "/$branch";
   }
   $sourceDir .= VDNET_AUTOMATION_ROOT_DIR;
   # on vdnet launcher, scm-trees is mounted as /build/trees
   if (-e "/build$sourceDir") {
      $vdLogger->Info("Using vdnet source: $sourceServer:$sourceDir");
   } else {
      $vdLogger->Info("Could not find vdnet source dir $sourceDir " .
                      "associated with branch $branch, so using " .
                      DEFAULT_VDNET_SRC_DIR);
      $sourceDir = DEFAULT_VDNET_SRC_DIR;
   }
   return ($sourceServer, $sourceDir);
}


########################################################################
#
# GetSourceDir--
#     Routine to get vdnet source directory
#
# Input:
#     sourceInput: vdnet source input in <server>:<share> format
#                 (optional)
#
# Results:
#     (<server>, <share directory>) if successful;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetUserSourceDirectory
{
   my $sourceInput = shift;
   my @srcInfo = split(/:/, $sourceInput);
   if (not defined $srcInfo[1]) {
      $vdLogger->Error("Invalid value given for vdnet src option, " .
                       "the format is src: <server>:<share>");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if ($srcInfo[0] =~ /local/i) {
      $srcInfo[0] = VDNetLib::Common::Utilities::GetLocalIP();
      if ($srcInfo[0] eq FAILURE) {
         $vdLogger->Error("Unable to local host IP");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }
   $vdLogger->Info("VDNet source will be mounted from " .
                   "$srcInfo[0], ensure $srcInfo[1] is NFS exported");
   return ($srcInfo[0], $srcInfo[1]);
}
