########################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Common::Utilities;

#
# VDNetLib::Common::Utilities Module: Houses more generic methods
#
# Methods provided by the Module:
#      1. IsValidIP            - API for ichecking if ip is of correct syntax
#
#      Date: 10-July-2009
#      Revision Date: 15-July-2009
#
# Note: Need to identify the repetedly used code in other modules and can be
#       created as a method in this module

# Load Necessary Modules
use strict;
use warnings;
use Tie::File;
use IO::Socket;
use Net::IP;
use File::Basename;
use FindBin;
use List::MoreUtils qw(any);
use Cwd 'abs_path';
use JSON;
use Fcntl qw(:flock);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                           VDCleanErrorStack IsFailure);
use VDNetLib::Common::LocalAgent qw( ExecuteRemoteMethod );
use VDNetLib::Common::VDLog;
use VDNetLib::Common::GlobalConfig qw($vdLogger $STAF_DEFAULT_PORT
                                      $sessionSTAFPort $sshSession);
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::SshHost;
use VDNetLib::InlineJava::Host;
use Time::HiRes qw(gettimeofday);
BEGIN {
   eval "use VDNetLib::Common::DHCPLeases"; warn "DHCPLeases.pm not loaded" if $@;
}
use Data::Dumper;
use Storable 'dclone';
use constant TRUE => 1;
use constant FALSE => 0;
use constant DEFAULT_LOG_LEVEL => 7; # INFO log level
use constant GUEST_DEFAULT_TIMEOUT => 300;
use constant DEFAULT_SLEEP_TIME => 15;
use constant GUESTIP_SLEEPTIME => 5;
use constant DEFAULT_MULTICAST_ADDRESS => "224.0.65.";
use constant VSAN_LOCAL_MOUNTPOINT => "vsanDatastore";
# Got this multicast IPv6 address from
# http://engweb.eng.vmware.com/~qa/p4depot/documentation/MN/Networking-FVT/TDS
# /VMkernel_ESX_vDS_Switching_Test_Design_Specification.doc
use constant DEFAULT_IPV6_MULTICAST_ADDRESS => "ff05::";
use constant {
   CMD_STOP_FIREWALL => '/etc/init.d/iptables stop',
   CMD_STOP_ESX_FIREWALL => 'esxcfg-firewall --allowIncoming --allowOutgoing',
   CMD_STOP_VISOR_FIREWALL => 'esxcli system firewall setenabled -e false',
   CMD_NEW_STOP_VISOR_FIREWALL => 'esxcli network firewall set -e false',
   CMD_MOUNT_RESTORE => "esxcfg-nas -r",
   CMD_SET_PROFILE => ". /etc/profile",
   CMD_TOUCH_ROOT_PROFILE => "touch /.profile",
   CMD_SET_ROOT_PROFILE => ". /.profile",
   CMD_START_VMVISOR_STAF => "if [ -e /usr/lib/vmware/rp/bin/runInRP ]; then \n".
                             "   /usr/lib/vmware/rp/bin/runInRP --max=2500 ".
                                 "setsid /bin/STAFProc >/dev/null 2>&1 & \n".
                             "else \n".
                             "   setsid /bin/STAFProc >/dev/null 2>&1 & \n".
                             "fi",
};
use constant STAF_SDK_SESSION_TIMEOUT_ERROR => 5102;
# FIXME(llai): Remove the dependency on INVENTORYCOMPONENTS.
use constant INVENTORYCOMPONENTS => {
   'vc'            => ['folder', 'datacenter', 'cluster', 'vds', 'dvportgroup'],
   'host'          => ['vmnic', 'vmknic', 'portgroup', 'vss', 'netstack', 'ovs',
                       'nvpnetwork', 'pswitchport', 'disk'],
   'esx'           => ['vmnic', 'vmknic', 'portgroup', 'vss', 'netstack', 'ovs',
                       'nvpnetwork', 'pswitchport', 'disk',  'nsxvswitch',
                       'vtep'],
   'kvm'           => ['pif', 'bridge', 'ovs', 'nvpnetwork', 'pswitchport',
                       'disk'],
   'vm'            => ['cpu', 'memory', 'disk', 'vnic', 'pci'],
   'vsm'           => ['datacenter', 'cluster', 'networkscope', 'vwire'],
   'pswitch'       => [],
   'powerclivm'    => [],
   'dhcpserver'    => [],
   'torgateway'    => [],
   'linuxrouter'    => [],
   'testinventory' => ['testcomponent'],
   'testbed'       => ['vc','host','vm','vsm','pswitch','powerclivm',
                       'testinventory', 'esx','dhcpserver', 'torgateway',
                       'linuxrouter'],
   'authserver'    => [],
   'nsxmanager'        => [],
   'nsxcontroller'        => [],
   'nsxedge'        => [],
   'logserver'        => [],
   'uidriver'        => [],
   'nsx_uidriver'        => [],
};

our $localIP = GetLocalIP();
BEGIN {
    use Exporter();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK,);
    @ISA = qw(Exporter);
    @EXPORT_OK = qw( &IsValidIP &VDNetInventoryBasedAlgorithm
                     &ResolveIndexValuesWithPath &ExpandTupleValueRecursive);
};
use Scalar::Util;

########################################################################
# IsValidIP --
#       This is the constructor module for NetAdapterClass
#
# Input:
#       This method is to check if IP is ipv4 or
#       ipv6 address and has correct syntax
#
# Results:
#       SUCCESS if it is a valid IP else FAILURE
#
# Side effects:
#       None
#
########################################################################

sub IsValidIP
{
   my $hostIP = shift;

   if (not defined $hostIP){
      $vdLogger->Error("IP address of host is not provided as input.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # While testing locally and using HostedVMOperations it makes sense to use
   # local as input param and thus verify localhost or local as the hostname/ip
   if ($hostIP =~ /local|localhost/i) {
      return SUCCESS;
   }

   # Regular Expression for matching IPv6Addresses
   my $IPv4_re = qr/^
      ((?:(?: 2(?:5[0-5]|[0-4][0-9])\. ) # 200 - 255
      |(?: 1[0-9][0-9]\. )|(?: (?:[1-9][0-9]?|[0-9])\. )){3}
      (?: (?: 2(?:5[0-5]|[0-4][0-9]) )|(?: 1[0-9][0-9] )|
      (?: [1-9][0-9]?|[0-9] )) $)/x;


   # Regular Expression for matching IPv6Addresses
   my $G = "[\\da-f]{1,4}";
   my @tail = ( ":",
             ":(?:$G)?",
             "(?:(?::$G){1,2}|:$IPv4_re?)",
             "(?::$G)?(?:(?::$G){1,2}|:$IPv4_re?)",
             "(?::$G){0,2}(?:(?::$G){1,2}|:$IPv4_re?)",
             "(?::$G){0,3}(?:(?::$G){1,2}|:$IPv4_re?)",
             "(?::$G){0,4}(?:(?::$G){1,2}|:$IPv4_re?)" );

   our $IPv6_re = $G;
   $IPv6_re = "$G:(?:$IPv6_re|$_)" for @tail;
   $IPv6_re = qr/:(?::$G){0,5}(?:(?::$G){1,2}|:$IPv4_re)|$IPv6_re/i;

   if ($hostIP =~ $IPv4_re) {
       return SUCCESS;
   } elsif ($hostIP =~ $IPv6_re) {
       return SUCCESS;
   } else {
       VDSetLastError("EINVALID");
       return FAILURE;
   }
}

########################################################################
# GetAbsFileofVMX --
#       Convert Storage vmxfile into absolute path of the file
#       Add escape characters for the spaces and braces that is part of
#       vmx path path. E.g. [Storage1] win2k8_64/win2k8_64.vmx
#
# Input:
#       vmx file in storage vmx format
#
# Results:
#       VMX file name
#
# Side effects:
#       none
#
########################################################################

sub GetAbsFileofVMX
{
   my $vmx = shift;
   if ( not defined $vmx ) {
      # Do we want to use vdError here?  Others may not be able to use this if
      # we do.  But ultimately, we should make Storage folks use vdError
      $vdLogger->Error("Undefined VMX file passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ($vmx =~ /\[(.*)\]\s*(.*)/) {
      my $storage = $1;
      my $file = $2;
      $storage =~ s/ /\\ /;
      $storage =~ s/\(/\\(/;
      $storage =~ s/\)/\\)/;

      $storage =~ s/\\/\\/;

      # On hosted, it is possible to have spaces in the file name too
      # so escape those spaces too
      $file =~ s/ /\\ /;
      my $vmxFile = '/vmfs/volumes/'. $storage .'/' . $file;
      return $vmxFile;
   } else {
      return $vmx;
   }
}


########################################################################
#
# IsPath --
#       Method to check if the given string is a path
#
# Input:
#       <string> (required)
#
# Results:
#       1 - if the given string is a path;
#       0 - if the given string is not a path;
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub IsPath
{
   my $string = shift;

   if (not defined $string) {
      $vdLogger->Error("String not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # If the given string has any slash then it considered as a path
   if ($string =~ /\/|\\/) {
      return TRUE;
   } else {
      return FALSE;
   }
}


########################################################################
#
# IsVMName --
#       Method to check the VM Name by extracting its vmx file
#
# Input:
#       hostObj - instance of VDNetLib::Host::HostOperations
#       VMName  - Registered VM Name
#       stafHelper - staf helper object
#
# Results:
#       vmx file - if the given VM is registerd and powered on
#       FAILURE - if the given VM is not a valid VM Name or in
#       case of any error
#
# Side effects:
#       None
#
########################################################################

sub IsVMName
{
   my $hostObj    = shift;
   my $vmName     = shift;
   my $stafHelper = shift;

   my $hostIP     = $hostObj->{hostIP};
   if ((not defined $hostIP) ||
       (not defined $vmName) ||
       (not defined $stafHelper)) {
      $vdLogger->Error("Host IP, VMName and/or STAFHelper obj " .
                       "not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $stafVMAnchor = $hostObj->{stafVMAnchor};
   # Get the vmx path of the given registered VM on the host
   my $command = "GETVMXPATH ANCHOR $stafVMAnchor VM $vmName";
   my $result = $stafHelper->STAFSubmitVMCommand("local",
                                                 $command);
   if ($result->{rc} != 0) {
      $vdLogger->Debug("Failed to get VMXPATH for $vmName on $hostIP");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $vmxFile = $result->{result};
   my $vmx;

   # If the result is defined and appears to be a file
   if ($vmxFile =~ /\/|\\/) {
      $vdLogger->Debug("GETVMXPATH on $vmName returned $vmxFile");
      $vmx = GetAbsFileofVMX($vmxFile);
      if ($vmx eq FAILURE) {
         $vdLogger->Error("Failed to get absolute vmx file for $vmxFile");
         VDSetLastError(VDGetLastError());
      } else {
         $vdLogger->Debug("vmx file of $vmName is $vmx");
         return $vmx;
      }
   } else {
      $vdLogger->Error("Unable to find vmx file name for $vmName");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
}


########################################################################
#
# GetVMFSRelativePathFromAbsPath --
#       Convert the given vmfs absolute path to vmfs relative path
#       (esx style - "[Datastore x] <subDir>)
#
# Input:
#       absolute path to a file
#
# Results:
#       VMFS relative path for the given vmfs absolute path;
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub GetVMFSRelativePathFromAbsPath
{
   my $absolutePath = shift;
   my $host         = shift;
   my $stafHelper   = shift;
   my $datastore;
   my $dir;

   if (not defined $absolutePath) {
      $vdLogger->Error("Absolute path not provided at input");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ((not defined $stafHelper) || ($stafHelper eq FAILURE)) {
      my $options;
      $options->{logObj} = $vdLogger;
      $stafHelper = VDNetLib::Common::STAFHelper->new($options);
      if ( $stafHelper eq FAILURE ) {
         $vdLogger->Error("Failed to create STAFHelper object");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }

   # if the given path is already in vmfs format
   # "[datastore] <pathtoVMX>", then return the same
   if ($absolutePath =~ /\[.*\] .*/) {
      return $absolutePath;
   }
   # VSAN has this strange requirement of having the Symlink
   # of the folder names instead of just names
   if ($absolutePath =~ /vsan/i) {
      $absolutePath = VDNetLib::Common::Utilities::ReadLink($absolutePath,
                                                            $host,
                                                            $stafHelper);
   }
   if ($absolutePath !~ /\/vmfs\/volumes/) {
      $vdLogger->Error("VMFS absolute path (starts with /vmfs/volumes) " .
                        "not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Remove  "/vmfs/volumes/" in the absolute path
   $absolutePath =~ s/\/vmfs\/volumes\///;

   # Get the first word before "/" into $1 and the rest into $2
   if ($absolutePath =~ /(.+?)\/(.+)/) {
      $datastore = $1;
      $dir = $2;
      if ($datastore =~ /vsan:(.+?)/i) {
         $datastore = VSAN_LOCAL_MOUNTPOINT;
      }
      return "[$datastore] " . $dir;
   }
}


########################################################################
#
# GetNetIDFromIPandNetmask --
#       Compute the subnet ID given the IP address and the netmask.
#       Converts the input into bit format and perform AND operation on
#       the two strings.  Convert the result back into decimal and
#       return
#
# Input:
#       IPv4 address and netmask in dotted notation
#
# Results:
#       subnet ID
#
# Side effects:
#       none
#
########################################################################

sub GetNetIDFromIPandNetmask
{

   if ( scalar(@_) < 2 ) {
      # TODO: Do we want to use VDError in the utilities function
      $vdLogger->Error("INSUFFICIENT NO. OF PARMS ");
      return undef;
   }

   my $ip          = shift;
   my $subnet_mask = shift;
   if ( not defined $ip ||
        not defined $subnet_mask ) {
      $vdLogger->Error("INVLAID PARMS ");
      return undef;
   }

   my $network = '';
   my $i;
   my (@ip_octets, @net_octets);

   @ip_octets  = split( /\./, $ip );
   @net_octets = split( /\./, $subnet_mask );

    # Validate the IP address, that is, it should be in x.x.x.x notation
    # AND each octet should be between 0 and 255
    if ( !($ip =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) ) {
        return undef;
    }
    if ( ($1 > 255) || ($1 < 0) ||
         ($2 > 255) || ($2 < 0) ||
         ($3 > 255) || ($3 < 0) ||
         ($3 > 255) || ($4 < 0) ) {
       return undef;
    }

    for ( $i = 0 ; $i < 4 ; $i++ ) {

        # Convert the corresponding octets of IP and NETMASK to binary format
        my $ip_oct     = unpack( 'B32', pack( 'N', $ip_octets[$i] ) );
        my $subnet_oct = unpack( 'B32', pack( 'N', $net_octets[$i] ) );

        # Perform bit-wise AND operation
        my $net_oct = $ip_oct & $subnet_oct;

        # Convert the resultant octet into decimal
        $net_oct = unpack( 'N', pack( 'B32',
                      substr( "0" x 32 . $net_oct, -32 ) ) );

        # Concatenate each resultant decimal octet with '.' to convert into
        # dotted notation
        $network .= $net_oct . '.';
    }

    # Remove the trailing '.'
    $network =~ s/\.$//;
    return $network
}


########################################################################
# SendMagicPkt --
#       This code is from CPAN, it basically sends a WoL magic packet to
#       the given MAC/IP address or subnet.
#
# Input:
#       host - remote host IP address
#       mac - MAC address of the remote ethernet interface
#       port - optional - port address of the remote socket, default is
#       9
#
# Results:
#       SUCCESS after sending the magic packet.
#
# Side effects:
#       none
#
########################################################################

sub SendMagicPkt
{
   my ($host, $mac_addr, $port, $maxPkts) = @_;

   $maxPkts = (defined $maxPkts) ? $maxPkts : 5;
   my $count = 0;

   # use the discard service if $port not passed in
   if (! defined $host) { $host = '255.255.255.255' }
   if (! defined $port || $port !~ /^\d+$/ ) { $port = 9 }

   my $sock = new IO::Socket::INET(Proto=>'udp') || return undef;

   my $ip_addr = inet_aton($host);
   my $sock_addr = sockaddr_in($port, $ip_addr);
   $mac_addr =~ s/://g;
   my $packet =
       pack('C6H*', 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, $mac_addr x 16);

   setsockopt($sock, SOL_SOCKET, SO_BROADCAST, 1);
   while ($count < $maxPkts) {
      if (not defined (send($sock, $packet, 0, $sock_addr))) {
         $vdLogger->Error("Send error:$!");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $count++;
   }
   close ($sock);

   return SUCCESS;
}


########################################################################
# GetCountFromPktExpr --
#       Retrieves count from packet capture expression
#
# Input:
#       tcpdump expr: for example
#       '-p -c 5000 src host %srcipv4% and dst host %dstipv4% and
#       greater 8000'
#
# Results:
#       No. of packets if it is found else FAILURE
#
# Side effects:
#       none
#
########################################################################

sub GetCountFromPktExpr
{
   my $expr = shift;

   if ( $expr =~ /.*-c\s+(\d+)\s+.*/ ) {
       return $1;
   }
   return FAILURE;
}


########################################################################
#  GetLenFromPktExpr --
# Retrieves count from packet capture expression
#
#  Input:
#       tcpdump expr: for example
#       '-p -c 5000 src host %srcipv4% and dst host %dstipv4% and
#       greater 8000'
#
#  Results:
#       No. of packets if it is found else FAILURE
#
#  Side effects:
#       none
#
########################################################################

sub GetLenFromPktExpr
{
   my $expr = shift;

   if ( $expr =~ /.*(greater|less)\s+(\d+).*/ ) {
       return $2;
   }

   return FAILURE;
}


########################################################################
# GetTimeStamp--
#       Generates a unique string with timestamp that can be used for
#       files that needed to be created by default or run time usage
#       purposes
#
# Input:
#       Time Separator operator (optional)
#       Date Separator operator (optional)
#
# Results:
#       TimeStamp in "$mon . $mday . '-' . $hour . $min . $sec"
#       format Ex: 20100110-034520
#
# Side effects:
#       none
#
########################################################################

sub GetTimeStamp
{
   my $sep1 = shift || "";
   my $sep2 = shift || "";

   my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
   $mon = eval ($mon+1);

   foreach my $val ($mon, $mday, $hour, $min, $sec) {
      if ($val < 10) { $val = "0$val";}
   }
   # Enable this logic if at all you want to use year timestamp.
   $year=$year+1900;

   # The return value looks like: 20091225-101010 (for 25th Dec 2009 at
   # 10:10:10 hr in case no parameters are passed.
   #
   # if $sep1 is passed and $sep1 is say "-", then the return value for
   # the above mentioned time looks like 2009-12-25-101010
   #
   # if $sep1 and $sep2 are passed and $sep1 is say "-", $sep2 is say ":"
   # then the return value for the above mentioned time looks like
   # 2009-12-25-10:10:10
   #
   return $year.$sep1.$mon.$sep1.$mday.'-'.$hour.$sep2.$min.$sep2.$sec;
}

########################################################################
# GetArrayIndex --
#   Returns index of an element in array.
#
#   Algorithm:
#       1. Iterate over array to get the index
#
#  Input:
#       array name and array element
#
#  Results:
#       index and -1 in case of array element is not found.
#
#  Side effects:
#       none
#
########################################################################

sub GetArrayIndex
{
   my $element = shift;
   my (@array) = @_;

   for (my $i = 0; $i < @array; $i++) {
      if ($element eq $array[$i]) {
         return $i;
      }
   }
   return -1
}

########################################################################
# EditFile --
#   Edit The file.
#
#  Input:
#       Filename   - Name of the file to be edited.(absolute path)
#       EditOption - Insert - Insert a line
#                    delete - delete a matching line
#                    modify - modify a line with new content
#       Line       - Line that you want to insert, modify or delete
#       MatchString- Line that you want to insert, modify or delete
#                    (This is optional input and is required only
#                    when task is modify. If line to be modified is
#                    available in the given file, we use the line
#                    parameter, to replace a matched line.).
#  Results:
#       none.
#
#  Side effects:
#       Modifies the original file
#
########################################################################

sub EditFile
{
   my ($args) = @_;
   my ($file, $task, $line, $matchString) = split(/\*/, $args);
   my @array;
   my $size;
   my $flag = 0;

   if (not defined $line or $line eq "") {
      $vdLogger->Debug("No line specified in EditFile");
      untie @array;
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Check if filename argument is defined and file exists
   if (defined $file and -e $file) {
      tie @array, 'Tie::File', "$file" or $flag = 1;
      if ($flag) {
         $vdLogger->Error("Unable to tie an array in EditFile method in Utlities module");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      $size = @array;

      # Check if task information is defined
      if (not defined $task or $task eq "") {
         $vdLogger->Error("Invalid Task mentioned");
         VDSetLastError("EINVALID");
         untie @array;
         return FAILURE;
      }

      if ($task =~ /insert/i) {

         # Check if string which we are trying to add exists or not.
         my $stringFound = 0;
         for (my $i = 0; $i <$size; $i++) {
            if ($array[$i] =~ /$line/) {
               $stringFound = 1;
               last;
            }
         }

         # If does not exists then add it otherwise don't
         if($stringFound == 0){
            $array[$size] = $line;
         }
         untie @array;
         return SUCCESS;
      } elsif ($task =~ /delete/i) {

         for (my $i = 0; $i <$size; $i++) {
            if ($array[$i] =~ /$line/) {
               $array[$i] = "";
               last;
            }
         }
         untie @array;
         return SUCCESS;
      } elsif ($task =~ /modify/i) {

         # Check if match string is supplied to replace a line in file
         if (not defined $matchString or $matchString eq "") {
            untie @array;
            return SUCCESS;
         }

         my $stringFound = 0;
         for (my $i = 0; $i <$size; $i++) {
            if ($array[$i] =~ /$matchString/) {
               $array[$i] = "$line";
               $stringFound = 1;
               last;
            }
         }

         # If the string which we are looking to modify does not exists
         # then add that string.
         if($stringFound == 0){
            $array[$size] = $line;
         }
         untie @array;
         return SUCCESS;
      }
   } else {
      # Check for errors
      $vdLogger->Error("Invalid File supplied.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
}


########################################################################
# ExecuteMethod --
#   To Execute methods on remote machine.
#
#  Input:
#       IP address where to execute this method
#       Method Name   - Method Name
#       arguments     - arguments to the method
#
# Results:
#      The result of the Method
#
#  Side effects:
#       none.
#
# Note:  For this method to be called for other methods in this file,
#        the way they take inputs need to be modified.
#
########################################################################

sub ExecuteMethod
{
   my $ip = shift;
   my $method = shift;
   my $args = shift;

   # Use the ExecuteRemoteMethod from VDNetLib::Common::LocalAgent
   my $return = VDNetLib::Common::LocalAgent::ExecuteRemoteMethod($ip,
                                                                  "$method",
                                                                  "$args");
   return ($return ne FAILURE) ? $return : FAILURE;
}


########################################################################
# ExecuteBashCmd ---
#  Executes bash command on the launcher.
#
#  Input:
#       cmd: Command to execute.
#       logError: Flag to indiciate whther or not to log stderr/stdout
#           when the command execution fails (set to TRUE by default)
#
# Results:
#      The exit code returned by command as well as stdout/stderr if
#      any.
########################################################################
sub ExecuteBashCmd
{
    my $cmd = shift;
    my $logError = shift || TRUE;
    my $output = `$cmd 2>&1`;
    my $exitCode = $?;
    if ($exitCode && $logError && $output) {
        $vdLogger->Error("Failed to run $cmd on local host:\n$output");
    }
    return ($exitCode, $output);
}

########################################################################
# IsValidMultcastIP --
#
# Description: This method is to check if input is a valid ipv4 multcast
#              ip address
#
# Input Args : Multicast IP address
#
# Results    : SUCCESS on success
#              FAILURE on failure
#
# Side Effects:
#              None
########################################################################

sub IsValidMulticastIP
{
   my $multicastIP = shift;

   # verify if multicast ip is localhost, if yes return FAILURE.
   if ($multicastIP =~ /local|localhost/i) {
      return FAILURE;
   }

   my $ret = IsValidIP($multicastIP);
   if ($ret eq "FAILURE") {
      $vdLogger->Error("Invalid multicast IP address supplied");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my @octates = split(/\./, $multicastIP);
   if ($octates[0] > 223 and $octates[0] < 240) {
      return SUCCESS;
   } else {
      $vdLogger->Error("Invalid multicast IP address supplied");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
}


########################################################################
# GetLocalIP --
#       Get local IP on visor or linux machine
#
# Input:
#       None
#
# Results:
#       Returns local IP address if it is possible else return FAILURE
#
# Side Effects:
#       none
#
########################################################################

sub GetLocalIP
{
   my $IP = '127.0.0.1';

   my $os = $^O;
   if ($os =~ /MSWin/i) {
      my $IP = `ipconfig | find /I \"ip\"`;
      if ($IP =~ /:\s+(10.\d\d?\d?.\d\d?\d?.\d\d?\d?)/) {
         return $1;
      }
   } elsif ($os =~ /Linux/i) {
      my $os = `uname -a`;
      $os =~ s/^(\S+).*/$1/;
      $os =~ s/^\s+//;
      $os =~ s/\s+$//;
      chomp($os);
      $os = lc($os);
      if ($os =~ /linux/i) {
         my $out = `ifconfig -a | grep "inet addr"`;
         if ($out =~ /.*inet addr:(10\.\d+\.\d+\.\d+)\s+.*/i) {
            $IP =  $1;
            return $IP;
         }
      } elsif ($os =~ /vmkernel/i) {
         my @out = `esxcfg-vmknic -l`;
         foreach my $line (@out) {
            if ($line =~ /^vmk/i) {
               my @elements = split(/\s\s+/, $line);
               if (($elements[0] =~ /vmk0/i) &&
                   ($elements[1] =~ /Management Network/i) &&
                   ($elements[3] =~ /10\./)) {
                   $IP = $elements[3];
                   return $IP;
               }
            }
         }
      } else {
         $vdLogger->Error("uname did not return correct value: $os");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   } elsif ($os =~ /darwin/i) {
        my @out = `ifconfig -a |grep "inet "`;
        foreach my $line (@out) {
           my @elements = split(/\s+/,$line);
           if (($elements[1] =~ /inet/i) &&
               ($elements[2] =~ /10\./i) &&
               ($elements[3] =~ /netmask/i)){
               $IP = $elements[2];
               return $IP;
           }
       }
   } elsif ($os =~ /freebsd/i) {
      my $out = `ifconfig -a | grep "inet"`;
      if ($out =~ /.*inet (10\.\d+\.\d+\.\d+)\s+.*/i) {
         $IP =  $1;
         return $IP;
      }
   } else {
      $vdLogger->Error("GetLocalIP not supported on given OS $os");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   return $IP;
}


########################################################################
#
# GetVDLogObj --
#      Returns a VDLog object the attributes of which are decided based
#      on environment variables VDNET_LOGLEVEL, VDNET_LOGTOFILE,
#      VDNET_LOGFILENAME, VDNET_VERBOSE. If these environment variables
#      are not defined then VDLog object with default values will be
#      created.
#
# Input:
#      None (The above mentioned environment variables could
#
# Results:
#      VDLog object
#
# Side effects:
#      None
#
########################################################################

sub GetVDLogObj
{
   my %vdLog = ();
   $vdLog{'logLevel'} = DEFAULT_LOG_LEVEL;
   if (defined $ENV{VDNET_LOGLEVEL}) {
      $vdLog{'logLevel'} = $ENV{VDNET_LOGLEVEL};
   }

   if (defined $ENV{VDNET_LOGTOFILE}) {
      $vdLog{'logToFile'} = $ENV{VDNET_LOGTOFILE};
   }
   if (defined $ENV{VDNET_LOGFILENAME}) {
      $vdLog{'logFileName'} = $ENV{VDNET_LOGFILENAME};
   }
   if (defined $ENV{VDNET_VERBOSE}) {
      $vdLog{'verbose'} = $ENV{VDNET_VERBOSE};
   }
   my $vdlogObj = new VDNetLib::Common::VDLog(%vdLog);
   return $vdlogObj;
}


########################################################################
#
# GetVMIPUsingVIM --
#      This routine finds the ip address of the given VM using vim-cmd.
#      Correct version of VMware tools is expected to run inside
#      the guest.
#
# Input:
#      host    - host name/ip on which the given VM is powered on.
#      vmx     - absolute vmx path
#      mac     - if ip address of a specific adapter need to be
#                found (Optional)
#      timeout - time to wait to get ip address of the given VM
#                (optional)
#
# Results:
#      ip address (in 10.x.x.x format) if successful;
#      "FAILURE", in case of any error. Run VDGetLastError() to retrieve
#                 error information.
#
# Side effects:
#      None
#
########################################################################

sub GetVMIPUsingVIM
{
   my $host = shift;
   my $vmx = shift;
   my $mac = shift;
   my $timeout = shift || GUEST_DEFAULT_TIMEOUT;

   my $sleeptime = DEFAULT_SLEEP_TIME;
   my ($ret, $data);

   if (not defined $host || not defined $vmx) {
      $vdLogger->Error("host and/or vmx not provided");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $options;
   $options->{logObj} = $vdLogger;
   my $stafHelper = VDNetLib::Common::STAFHelper->new($options);
   if ( $stafHelper eq FAILURE ) {
      $vdLogger->Error("Failed to create STAFHelper object");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   #
   # This function is only work for esx/vmkernel, if host type is not vmkernel
   # then returning undef as guestControlIP
   #
   if ($stafHelper->GetOS($host) !~ /vmkernel|esx/i){
      return undef;
   }
   #
   # On ESX, the guest VM's ip address is obtained using vim-cmd utility which
   # requires the unique id correspnding to the given VM
   #
   my $vimID = VDNetLib::Common::Utilities::GetVimCmdGuestID($host,
                                                             $vmx);
   if ($vimID eq FAILURE) {
      $vdLogger->Error("Failed to VM ID for vim-cmd");
      $vdLogger->Error(VDGetLastError());
      return FAILURE;
   }

   my $guestControlIP;
   my $startTime = time();

   while ($timeout && $startTime + $timeout > time()) {
      my $temp;
      #
      # Run the 'vim-cmd vmsvc/get.guest <vimID>' on the given the host.
      # vimID is a unique ID for the given VM defined while registering the VM
      #
      my $command = "START SHELL COMMAND vim-cmd vmsvc/get.guest $vimID " .
                    "WAIT RETURNSTDOUT STDERRTOSTDOUT";
      ($ret, $data) = $stafHelper->runStafCmd($host,
                                              'PROCESS',
                                              $command);

      if (($ret eq FAILURE) ||
         ($data eq "")) {
         $vdLogger->Error("Failed to get guest info on $host:$data");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      if ($data =~ /toolsStatus = \"toolsOld\"/i) {
         $vdLogger->Trace("Warning: VMware Tools inside the guest is old, update it");
      }
      #
      # Control IP address is the class-A address (VMware's subnet is 10.x.x.x)
      # using which the VM can be accessed by any machine under VMware's
      # network.
      # A portion of the data returned would look like this:
      #       'ipAddress = (string) [
      #            "192.168.0.64",
      #            "fe80::20c:29ff:fe95:8f2b"
      #        ],
      #       macAddress = "00:0c:29:95:8f:2b",';
      #

      $data =~ s/\n//g;
      my $ipRegex = VDNetLib::Common::GlobalConfig::IP_REGEX;
      if (defined $mac) {
         #
         # If IP address of a specific adapter (given mac adapter) is required,
         # then verify whether the mac address matches.
         #
         if ($data =~ /ipAddress = .*\"($ipRegex)\".*macAddress = \"$mac\",/i) {
            $temp = $1;
         }
      } elsif ($data =~ /ipAddress = \"($ipRegex)\".*macAddress = /i) {
         $temp = $1;
      } elsif ($data =~ /ipAddress = .*\"($ipRegex)\".*macAddress = /i) {
         $temp = $1;
      }
      if (defined $temp) {
         unless(system("ping -c 1 $temp > \/dev\/null")) {
            $guestControlIP = $temp;
            $vdLogger->Debug("GuestControlIP using VIM:$guestControlIP");
            return $guestControlIP;
         }
      } else {
         $guestControlIP = undef;
      }
   }
   if (not defined $guestControlIP) {
      if ($data =~ /guestToolsNotRunning/i) {
         $vdLogger->Trace("Warning: Tools not running inside the guest");
      }
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
}


########################################################################
#
# GetVimCmdGuestID --
#       Method to get the unique id assigned to a VM while registration.
#       This id is required to make use of any vm related services
#       (vim-cmd vmsvc/) offered by vim-cmd utility on ESX.
#
# Input:
#       <hostIP> - endpoint ip address on which the VM is registered
#                  (required)
#       <vmx>    - absolute vmx path of a VM (required)
#
# Results:
#       VM's unique ID, or
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub GetVimCmdGuestID
{
   my $hostIP = shift;
   my $vmx = shift;
   my $vmID;

   $vmx =~ s/\\//g;

   if ((not defined $hostIP) ||
      (not defined $vmx)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
   my $options;
   $options->{logObj} = $vdLogger;
   my $stafHelper = VDNetLib::Common::STAFHelper->new($options);
   if ( $stafHelper eq FAILURE ) {
      $vdLogger->Error("Failed to create STAFHelper object");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $hostType = $stafHelper->GetOS($hostIP);

   if ($hostType eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($hostType !~ /esx|vmkernel/i) {
      $vdLogger->Error("This method applies only to esx");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }

   my ($command, $ret, $data);
   #
   # 'vim-cmd vmsvc/getallvms' will list all the registered VMs on the given
   # host
   #
   $command = "START SHELL COMMAND vim-cmd vmsvc/getallvms WAIT RETURNSTDOUT " .
              "STDERRTOSTDOUT";
   ($ret, $data) = $stafHelper->runStafCmd($hostIP,
                                           'PROCESS',
                                            $command);
   if (($ret eq FAILURE) ||
      ($data eq "")) {
      $vdLogger->Error("Failed to get list of VMs on $hostIP:$data");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $vdLogger->Debug("List of registered vms on $hostIP: $data");

   # changing vmfs file format
   $vmx = VDNetLib::Common::Utilities::GetVMFSRelativePathFromAbsPath($vmx,
                                                                      $hostIP,
                                                                      $stafHelper);
   if ($vmx eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # if the vmx file name using the datastore UUID, then convert it to name
   if ($vmx =~ m/\[([0-9a-z]{8}-[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{12})\]\s(.*)/i) {
       my $dataStoreName = VDNetLib::Common::Utilities::GetDataStoreName(
                                                $stafHelper, $hostIP, $1);
       $vmx = "[" . $dataStoreName . "] " . $2;
   }
   if ($vmx eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my @vimcmd = split(/\n/,$data);
   if ( scalar(@vimcmd) > 1 ) {
      foreach my $vmline (@vimcmd) {
         # Substitute one or more white spaces with one white space in each line
         $vmline =~ s/\s+/ /g;
         # Remove tabs, newline characters and carriage returns in each line
         $vmline =~ s/\t|\n|\r//g;
         #
         # Store vmID as $1 and [dataStore] vmxPath together as $2 from the
         # string of following format:
         # "vmID vmName [dataStore] vmxPath guestOS Version Annotation"
         #
         if ( $vmline =~ /(^\d+) .* (\[.*\]\s+.*\.vmx) .*/ )  {
            if ($2 eq "$vmx") {
               $vmID = $1;
               return $vmID; # return VM id
            }
         }
      }
   }
   $vdLogger->Info("Given vmx $vmx not found in the list of registered VMs");
   VDSetLastError("ENOTDEF");
   return FAILURE;
}


########################################################################
#
# GetVMIPUsingDHCP --
#      This routine finds the dhcp address of the given VM using host's
#      dhcp address. An IP address is returned only if the host
#      dhcp lease information is up to date and atleast one of the
#      adapters inside the guest is configured to use DHCP.
#
# Input:
#      host       - host name/ip on which the given VM is powered on.
#      vmx        - absolute vmx path
#      macAddress - if ip address of a specific adapter need to be
#                   found (Optional)
#      timeout    - time to wait to get ip address of the given VM
#                   (optional)
#
# Results:
#      ip address (in 10.x.x.x format) if successful;
#      "FAILURE", in case of any error. Run VDGetLastError() to retrieve
#                 error information.
#
# Side effects:
#      None
#
########################################################################

sub GetVMIPUsingDHCP
{
   my $host = shift;
   my $vmx  = shift;
   my $macAddress  = shift;
   my $timeout = shift || GUEST_DEFAULT_TIMEOUT;

   if (not defined $host || not defined $vmx) {
      $vdLogger->Error("host and/or vmx not provided");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $sleeptime = DEFAULT_SLEEP_TIME;
   my $options;
   $options->{logObj} = $vdLogger;
   my $stafHelper = VDNetLib::Common::STAFHelper->new($options);
   if ( $stafHelper eq FAILURE ) {
      $vdLogger->Error("Failed to create STAFHelper object");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Create an instance of DhcpLeases
   my $dhcpLeases = new VDNetLib::Common::DHCPLeases();
   if (not defined $dhcpLeases) {
      $vdLogger->Error("Failed to create VDNetLib::Common::DHCPLeases object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   #
   # This routine works under the assumption that the dhcp server of a
   # guest on the given host will be same as the host's dhcp server.
   my $dhcpServer = $dhcpLeases->GetDHCPServer($host,$stafHelper);
   if ($dhcpServer eq FAILURE) {
      $vdLogger->Warn("Failed to get DHCP server of host $host");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("DHCP server of $host: $dhcpServer");
   #
   # Since the VM's IP address is not known, host's dhcp server is queried.
   # MAC address of all the adapters in the given vmx file are collected
   # and any entry of these mac addresses is searched in the
   # dhcp server. The presence of VM's mac address and corresponding dhcp
   # address is not sufficient to guarantee the VM's ip address,
   # we need to ping this ip address and make sure it is successful.
   #
   my $data = CheckForPatternInVMX($host, $vmx, "generatedAddress");
   if (not defined $data) {
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my @temp = split(/\n/, $data);
   my @macList;
   foreach my $line (@temp) {
      if ($line =~ /(([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2})/i) {
         # Store all the mac addresses in the vmx file in an array
         push (@macList, $1);
      }
   }
   my $guestControlIP;
   my $startTime = time();
   while ($timeout &&  $startTime + $timeout > time()) {
      foreach my $mac (@macList) {
         if (defined $macAddress && $macAddress !~ /$mac/i) {
               next;
         }
         # Check dhcp leases for one MAC address at a time
         $dhcpLeases->GetLeases($dhcpServer);
         for my $dhcpServer (keys %{$dhcpLeases->{dhcp}}) {
            my $temp = $dhcpLeases->{dhcp}->{$dhcpServer}->{lc($mac)};
            if (not defined $temp){
	       $temp = $dhcpLeases->{dhcp}->{$dhcpServer}->{$mac};
	    }
            if (not defined $temp){
               next;
            }
            $vdLogger->Debug("Pinging $temp");
            unless (system("ping -c 1 $temp > \/dev\/null")) {
               #
               # ping to the dhcp entry (corresponding to the given mac
               # address in dhcp server) should be successful to confirm the
               # right ip address
               #
               $guestControlIP = $temp;
               $vdLogger->Debug("GuestControlIP using DHCP:$guestControlIP");
               return $guestControlIP;
            }
         }
      }
   }
   if (not defined $guestControlIP) {
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
}


########################################################################
#
# GetVMIPUsingARP --
#      This routine finds the ip address of the given VM using arp
#      inspection feature in vmkernel.
#
# Input:
#      vmObj      - instance of VDNetLib::VM:VMOperations
#      macAddress - if ip address of a specific adapter need to be
#                   found (Optional)
#      timeout    - time to wait to get ip address of the given VM
#                   (optional)
#
# Results:
#      ip address (in 10.x.x.x format) if successful;
#      "FAILURE", in case of any error. Run VDGetLastError() to retrieve
#                 error information.
#
# Side effects:
#      None
#
########################################################################

sub GetVMIPUsingARP
{
   my $vmObj      = shift;
   my $macAddress = shift;
   my $timeout    = shift || GUEST_DEFAULT_TIMEOUT;
   my $sleeptime  = DEFAULT_SLEEP_TIME;
   my $options;

   my $worldId = $vmObj->GetWorldID();
   if ($worldId eq FAILURE) {
      $vdLogger->Error("Get world ID returns FAILURE");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $startTime = time();
   while ($timeout &&  $startTime + $timeout > time()) {
      my $portsHash = $vmObj->GetNetworkPortsInfo();
      my $macAddress = lc($macAddress);
      my $ip;
      if ((defined $portsHash) && ($portsHash eq FAILURE)) {
         $vdLogger->Error(
            "GetNetworkPortsInfo for $vmObj failed:\n" .
            VDNetLib::Common::Utilities::StackTrace());
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      if (defined $portsHash->{$macAddress}) {
         $ip = $portsHash->{$macAddress}{'IP Address'};
      }
      if ((not defined $ip) || ($ip eq '0.0.0.0')) {
         next;
      }

      unless (system("ping -c 1 $ip > \/dev\/null")) {
         return $ip;
      }
   }
   $vdLogger->Debug("Failed to get IP address using arp in $timeout seconds");
   VDSetLastError(VDGetLastError());
   return FAILURE;
}


########################################################################
#
# GetGuestControlIP --
#       Method to get the guest VM's control IP using which all
#       commands are executed using staf.
#
# Input:
#       <vmObj>      - instance of VDNetLib::VM::VMOperations
#       <macAddress> - if ip address of specific adapter is needed
#                      (Optional)
#       <timeout>    - max time to wait to get the guest VM's control IP
#                      address (Optional)
#
# Results:
#       Guest VM's control IP address or
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub GetGuestControlIP
{
   my $vmObj      = shift;
   my $macAddress = shift;
   my $timeout    = shift;
   my $portgroup  = shift ||
        VDNetLib::Common::GlobalConfig::DEFAULT_VM_MANAGEMENT_PORTGROUP;

   my $hostObj    = $vmObj->{hostObj};
   my $hostIP     = $hostObj->{hostIP};
   my $vmx        = $vmObj->{vmx};
   my ($command, $ret, $data, $portsHash);
   if (not defined $hostIP || not defined $vmx) {
      $vdLogger->Error("Host IP, type and/or vmx path not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $timeout = (defined $timeout) ? $timeout :
                 VDNetLib::Common::GlobalConfig::DEFAULT_GUEST_BOOT_TIME;

   if (not defined $macAddress) {
      $portsHash = $vmObj->GetNetworkPortsInfo();
      foreach my $mac (keys %$portsHash) {
         if ((defined $portsHash->{$mac}{'Portgroup'}) &&
             ($portsHash->{$mac}{'Portgroup'} eq $portgroup)) {
            $macAddress = $mac;
            last;
         }
      }
   }

   $vdLogger->Debug("Using timeout value $timeout to get guest control ip");

   my $sleeptime = GUESTIP_SLEEPTIME;

   my $guestControlIP;
   my $startTime = time();
   my $firstTime = 1;
   while ($timeout && $startTime + $timeout > time()) {
      if ($firstTime == 0) {
         sleep($sleeptime);
      }

      $firstTime = 0;

      # In this block, 2 methods DHCP and vim-cmd are used to find the VM's ip
      # address. Since these methods does not work individually due to other
      # dependencies like vmware-tools, dhcp settings etc, both of them
      # are tried to make sure VM's ip address is found.
      #
      # Please note timeout value of 1 is passed to these methods to ensure a
      # single method does not take the whole specified time to find the ip
      # address.
      #
      VDCleanErrorStack();
      $guestControlIP = VDNetLib::Common::Utilities::GetVMIPUsingARP($vmObj,
                                                                     $macAddress,
                                                                     5);
      if (VDNetLib::Common::Utilities::IsValidIP($guestControlIP) eq SUCCESS) {
         VDCleanErrorStack();
         return $guestControlIP;
      } else {
         $guestControlIP = undef;
      }

      $guestControlIP = VDNetLib::Common::Utilities::GetVMIPUsingVIM($hostIP,
                                                                     $vmx,
                                                                     $macAddress,
                                                                     5);
      if (VDNetLib::Common::Utilities::IsValidIP($guestControlIP) eq SUCCESS) {
         VDCleanErrorStack();
         return $guestControlIP;
      } else {
         $guestControlIP = undef;
      }

      $guestControlIP = VDNetLib::Common::Utilities::GetVMIPUsingDHCP($hostIP,
                                                                      $vmx,
                                                                      $macAddress,
                                                                      5);
      if (VDNetLib::Common::Utilities::IsValidIP($guestControlIP) eq SUCCESS) {
         VDCleanErrorStack();
         return $guestControlIP;
      } else {
         $guestControlIP = undef;
      }
   }
   if (not defined $guestControlIP) {
      $portsHash = $vmObj->GetNetworkPortsInfo();
      $vdLogger->Debug("Network ports info is " . Dumper($portsHash) .
                         " and mac address is $macAddress");
      $data = CheckForPatternInVMX($hostIP, $vmx, "generatedAddress");
      if (defined $data) {
         $vdLogger->Debug("Check generatedAddress in VMX file $vmx returns: " .
                     Dumper($data));
      }
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
}


#######################################################################
#
# ChangeHostname --
#      Changes the hostname/computer name of a windows VM.
#
# Input:
#      A hash or named parameter with following keys:
#      compName : the new computer name that needs to used
#      winIP    : static ip address of the windows guest
#                 (no dhcp address)
#                OR
#      vmx      : absolute path to the VM
#      host     : host on which the given vm is present
#
#      compName is mandatory, winIP OR (vmx, host) have to be passed
#
# Results:
#      "SUCCESS", if the computer name is updated without any error
#      "FAILURE", in case of any error
#
# Side effects:
#      This method could restart the windows VM. In such cases,
#      the ip address of the host ($host) might change if dhcp has
#      been used. Use VDNetLib::Common::Utilities::GetVMGuestControlIP()
#      utility functions to retrieve the updated the ip address
#      of the VM.
#
########################################################################

sub ChangeHostname
{
   my %opts     = @_;

   my $host       = $opts{'host'};
   my $winIP      = $opts{'winIP'};
   my $compName   = $opts{'compName'};
   my $vmObj      = $opts{'vmObj'};
   my $machine    = $opts{'machine'};
   my $macAddress = $opts{'macAddress'};
   my $stafObj    = $opts{'stafHelper'};
   my $vmx        = $vmObj->{'vmx'};

   if (((not defined $host || not defined $vmx) || not defined $winIP) ||
      (not defined $compName)) {
      $vdLogger->Error("One or more parameters missing");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $vdLogger->Debug("DHCP address of $vmx is $winIP");

   if (not defined $stafObj) {
      my $hash = {'logObj' => $vdLogger};
      # Using the new wrapper for STAF
      $stafObj = new VDNetLib::Common::STAFHelper($hash);
      if(not defined $stafObj) {
         $vdLogger->Error("Failed to create STAF object");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   }

   if ($stafObj->WaitForSTAF($winIP) eq FAILURE) {
      $vdLogger->Error("STAF not running on $winIP");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $targetOS = $stafObj->GetOS($winIP);

   if (not defined $targetOS) {
      $vdLogger->Error("Unable to find the guest OS type of $winIP");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($targetOS !~ /win/i) {
      $vdLogger->Debug("Change hostname not required for $targetOS");
      return $winIP;
   }

   $vdLogger->Info("$winIP: Changing the machine's hostname to avoid conflict");

   # This method copies and runs the script changeHostname.pl inside
   # the windows machine to change the hostname. The reason to use a
   # separate perl script and not any sub-routine/function is:
   # Sometimes this method could be used to change computer name if there is
   # any hostname conflict.
   # Such an issue will throw error when trying to mount any automation source
   # code inside the guest. Therefore, the above mentioned approach is used.
   #
   # Find the path to the script changeHostname.pl
   my $gc = new VDNetLib::Common::GlobalConfig();
   my $source = $gc->TestCasePath(VDNetLib::Common::GlobalConfig::OS_LINUX);
   if ($source eq FAILURE) {
      $vdLogger->Error("Failed to get absolute path for changeHostname.pl");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $source = $source . "changeHostname.pl";

   # Using C:\changeHostname as the destination path
   my $dest = 'C:\\changeHostname.pl';


   # Copy the script changeHostname.pl inside the given machine
   my $fileCopy = $stafObj->STAFFSCopyFile($source, "$dest", "local", "$winIP");
   if ($fileCopy == -1) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   # Run changeHostname.pl inside the windows machine to change its computer
   # name to $compName
   my $result = $stafObj->STAFAsyncProcess($winIP, "perl $dest -n $compName");
   if ($result->{rc}) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   # changeHostname.pl script restarts few services, so putting the script.
   sleep 2*DEFAULT_SLEEP_TIME;

   #
   # changeHostname.pl returns 0 in case of success, 1 in case of any script
   # error and 2 in case if the host requires a reboot.
   #
   my $exitValue = undef;
   while (not defined $exitValue) {
      #TODO - this block is not needed if static ip is configured
      $winIP = VDNetLib::Common::Utilities::GetGuestControlIP($vmObj);
      if ($winIP eq FAILURE) {
         $vdLogger->Error("Failed to get dhcp address of $vmx on $host");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Trace("DHCP address of $vmx is $winIP");
      $exitValue = $stafObj->CheckProcessStatus($winIP,$result->{handle});
      sleep 10;
   }

   if ($exitValue == 2) { # which means restart required
      $vdLogger->Info("Restarting $vmx for change in hostname to be " .
                      "effective");
      $result = $stafObj->STAFAsyncProcess($winIP, "shutdown -r -f -t 0");
      if ($result->{rc}) {
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      #
      # The following sleep is required because when the command to reboot is
      # issues, it takes few seconds for the network to go down completely.
      # Without this sleep, any staf command to the machine might work but that
      # is just the time before the machine shut down completely.
      #
      sleep 4*DEFAULT_SLEEP_TIME;
      $winIP = VDNetLib::Common::Utilities::GetGuestControlIP($vmObj,
                                                         $macAddress);
	if ($winIP eq FAILURE) {
         $vdLogger->Error("Failed to get dhcp address of $vmx on $host");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return $winIP;
}


########################################################################
#
# GetAvailableTestIP --
#      This routine gives an ip address (C class) available (not being
#      assigned to any interface) within the given machine's
#      sub-network.
#
# Input:
#      controlIP: ip address of a machine through which an available
#      class-c ip address has to be found.
#      mac: MAC address of the test adapater
#      type: Address type IPv4 or IPv6
#
# Results:
#      A string which is an IP address in the range 192.168.0.x to
#      192.168.1.x, where 0 < x < 255, if successful;
#      FAILURE, in case of any error or failure to find an ip within 10
#      retries.
#
# Side effects:
#      None
#
########################################################################

sub GetAvailableTestIP {
   my $controlIP = shift || "local";
   my $mac = shift || "undef";
   my $type = shift || "ipv4";

   #
   # TODO - Get  IP address from host name if needed.
   $controlIP = VDNetLib::Common::Utilities::GetIPfromHostname($controlIP);
   if ($controlIP eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #
   # if type is ipv6 then generate the unique ipv6 address
   # Algorithm will function like below
   # IF MAC is 00:0C:29:57:41:AC then IPv6 address would be
   # 2001:bd6::000c:2957:41AC
   #
   if($type =~ /ipv6/i) {
      if(not defined $mac) {
         $vdLogger->Error("MAC address is not provided");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      #
      # IPv6 Prefix to be used is 2001:bd6::
      my $prefix =  "2001:bd6::";

      # split the mac address and join adjecent octets
      my @tempArry = split(":", $mac);
      # Special logic is required for octets 0, 1, 2 and 4 of the MAC
      # address because for MAC 00:0C:29:57:41:AC, the generated
      # IPv6 address will be 2001:bd6::000c:2957:41AC/64. When it's
      # set for the interface using ifconfig, it will be set as
      # 2001:bd6::c:2957:41AC. In SetIPv6(), after setting this
      # IPv6 address we verify it by using GetIPv6Global/Local() and compare
      # the default value we generated here and the set value, if we
      # don't remove these leading zeros (in 0, 1, 2 and 4 octets) this
      # function will fail to match the addresses.
      $tempArry[0] =~ s/^0*//;
      $tempArry[1] =~ s/^0*//;
      $tempArry[2] =~ s/^0*//;
      $tempArry[4] =~ s/^0*//;
      my $mac1 = $tempArry[0] . $tempArry[1];
      my $mac2 = $tempArry[2] . $tempArry[3];
      my $mac3 = $tempArry[4] . $tempArry[5];
      $mac = $mac1 . ":" . $mac2 . ":" . $mac3;
      my $IPv6_addr = $prefix . $mac;
      return $IPv6_addr;
   }

   my ($lastOctet, $secondLastOctet);
   my $retries = 0;
   my $command;
   my $result;

   # STAFHelper object is required to run a ping command on the given machine
   my $hash = {'logObj' => $vdLogger};
   my $stafObj = new VDNetLib::Common::STAFHelper($hash);
   if(not defined $stafObj) {
      $vdLogger->Error("Failed to create STAF object");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $vdLogger->Info("Finding a class-c ip address available on $controlIP " .
                   "sub-network");

   my ($ip, $os);

   #
   # This algorithm picks the last two octets of IP address from either
   # the last two octets of the control IP address or randomnly selects a value
   # between 1 to 254. If last two octets of control ip address is chosen, then
   # it is appended to "192.168.". In case of random number, then it is
   # appended to "192.168.RETRIES.". In the both the cases, the selected ip address
   # is pinged to see if there is any response. Control ip corresponding to
   # 10.20.RETRIES.RandomNumber is also pinged just to make sure we dont use
   # the test ip of an adapter which does not have connectivity yet.
   # If no response, then it is assumed available.
   # There could be no response even when there is no adapter
   # configured to be on 192.168.0.0 sub-network. In that case, the algorithm
   # picks the last two octets of control ip address because 192.168.y.x (y -
   # second last octect, x - last octet) will be unique in the entire sub-network.
   #
   my @testoctets;
   my @ctrloctets = split('\.', $controlIP);
   if ($ctrloctets[3] eq "255" || $ctrloctets[3] eq "0") {
      #
      # If the last octet of control ip address is 1 or 255, then assign the
      # temporary ip to same as control ip, so that ping to control ip will
      # definitely be successful and the algorithm will try picking a random
      # last octet.
      #
      $ip = $controlIP;
   } else {
      # if the last octet is from control ip, then use 192.168.0.x
      $ip = "192.168." . $ctrloctets[2] . "." . $ctrloctets[3];
   }

   $os = $stafObj->GetOS($controlIP);
   if ($os =~ /win/i) {
      $command = "ping -n 1 $ip";
   } elsif($os !~ /(esx|vmkernel)/i) {
      $command = "ping -c 1 $ip";
   }
   if ($os =~ /(esx|vmkernel)/i) {
      $result = VDNetLib::Common::Utilities::CheckAllStackInstances($controlIP,
                                                                    $ip,
                                                                    $stafObj);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failure while checking ip availibility on $controlIP");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   } else {
      $result = $stafObj->STAFSyncProcess($controlIP, $command, 30);
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to execute command on $controlIP");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      if ($result->{exitCode} != 0 || $result->{stdout} =~ /unreachable/i) {
         $result = 1;
      } else {
         $result = 0;
      }
   }

   # The first attempt to generate a test ip assdress is using the
   # last 2 octects of control adapter.
   # If ping to it replies then we try with randomly generated ip addresses.
   if ($result eq 1) {
      return $ip;
   } else {
      my $availableIP = 0;
      while ($retries < 10) {
         $lastOctet = VDNetLib::Common::Utilities::RandomNumberInRange(1, 254);
         $secondLastOctet = VDNetLib::Common::Utilities::RandomNumberInRange(1, 254);

         # We use retries as the second last octect 192.168.y.x
         # where y = retires
         # We generate last octect, a random number x, then use 192.168.1.x

         # We ping 192.168.x.y to make sure there is no test adapter with
         # same ip on our network and 10.20.x.y to make sure there is
         # no control ip so that his test interface won't be assigned
         # that control ip's last octect, when there is no connectivity
         # of the test network.
         $ip = "192.168." . $secondLastOctet . "." . $lastOctet;
         if ($os =~ /win/i) {
            $command = "ping -n 1 $ip" ;
         } else {
            $command = "ping -c 1 $ip";
         }
         $result = $stafObj->STAFSyncProcess($controlIP, $command, 30);
         if ($result->{rc} != 0) {
            $vdLogger->Error("Failed to execute command on $controlIP");
            VDSetLastError("ESTAF");
         }
         # Check if there is no test adapter with this ip address in
         # out test network
         if ($result->{exitCode} != 0 || $result->{stdout} =~ /unreachable/i) {
            $availableIP = 1;
         } else {
            $availableIP = 0;
         }

         # We generate 10.20.x.y where x and y are 192.168.x.y
         @testoctets = split('\.', $ip);
         my $remoteVMCtrlIP = $ctrloctets[0]. "." .$ctrloctets[1]. "." .
                              $testoctets[2]. "." .$testoctets[3];
         if ($os =~ /win/i) {
            $command = "ping -n 1 $remoteVMCtrlIP" ;
         } else {
            $command = "ping -c 1 $remoteVMCtrlIP";
         }
         $result = $stafObj->STAFSyncProcess($controlIP, $command, 30);
         if ($result->{rc} != 0) {
            $vdLogger->Error("Failed to execute command on $controlIP");
            VDSetLastError("ESTAF");

         }

         # Check if there is no control adapter with this ip address in
         # out control network, so that we dont take the ip which will
         # be configured for his 1st test adapter.
         if ($result->{exitCode} != 0 || $result->{stdout} =~ /unreachable/i) {
            $availableIP = 1;
         } else {
            $availableIP = 0;
         }

         # If both checks passed, this ip is safe to use.
         if($availableIP eq 1) {
            return $ip;
         }
         $retries++;
      }
   }

   return FAILURE;
}


########################################################################
#
# RandomNumberInRange --
#      This utility function returns a random integer with the given
#      range.
#
# Input:
#      start: starting integer value
#      finish: final integer value
#      (Note: If the 'start' value is greater than 'finish' value, then
#      this routine will convert start to finish and vice-versa)
#
# Results:
#      A random integer value
#
# Side effects:
#      None
#
########################################################################

sub RandomNumberInRange {
   my $start  = shift || 1;
   my $finish = shift || 255;
   # return start value if the given start and finish values are equal
   return $start if $start == $finish;
   ($start, $finish) = ($finish, $start) if $start > $finish;
   # It looks like the rand() doesn't generate real random numbers
   # we need to reseed it with srand(),PR1067733
   srand();
   return $start + int rand(1 + $finish - $start);
}



########################################################################
#
# GetRegisteredVMName --
#      Method to get registered name of a VM from the given vmx path.
#
# Input:
#      host: host ip address (Required)
#      vmx: absolute vmx path (Required)
#      stafHelper: an object of VDNetLib::Common::STAFHelper package
#                  (Required)
#      stafVMAnchor: anchor to the host generated using
#                    VDNetLib::Common::Utilities::GetSTAFAnchor()
#                    (Optional)
#
# Results:
#      A scalar string of the given VM's registered name if successful;
#      A scalar string "FAILURE" in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub GetRegisteredVMName
{
   my $hostIP       = shift;
   my $vmx          = shift;
   my $stafHelper   = shift; # object of VDNetLib::Common::STAFHelper
   my $stafVMAnchor = shift;

   if ((not defined $hostIP) ||
       (not defined $vmx) ||
       (not defined $stafHelper)) {
      $vdLogger->Error("Host IP, absolute vmx path and/or STAFHelper obj " .
                       "not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $stafVMAnchor) {
      $stafVMAnchor = VDNetLib::Common::Utilities::GetSTAFAnchor($stafHelper,
                                                                 $hostIP,
                                                                 "VM");
      if ($stafVMAnchor eq FAILURE) {
         $vdLogger->Error("Failed to get STAF VM anchor");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   #
   # Get the list of all registered VMs on the host and from the given
   # vmx path, find the registered VM name.
   #
   my $command = "GETVMS ANCHOR $stafVMAnchor";
   my $result = $stafHelper->STAFSubmitVMCommand("local",
                                                 $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to get VMs list from $hostIP");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $vmx = VDNetLib::Common::Utilities::GetVMFSRelativePathFromAbsPath($vmx,
                                                                      $hostIP,
                                                                      $stafHelper);
   # if the vmx file name using the datastore UUID, then convert it to name
   if ($vmx =~ m/\[([0-9a-z]{8}-[0-9a-z]{8}-[0-9a-z]{4}-[0-9a-z]{12})\]\s(.*)/i) {
       my $dataStoreName = VDNetLib::Common::Utilities::GetDataStoreName(
                                                $stafHelper, $hostIP, $1);
       $vmx = "[" . $dataStoreName . "] " . $2;
   }
   if ($vmx eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # STAF GETVMS sometimes returns relative path with space and sometimes
   # without space. Thus we are checking for both
   # Contructing relative vmx path without space
   my $vmxWithoutSpace = $vmx;
   $vmxWithoutSpace =~ s/\] /]/;
   my @arrayVMX = ($vmx, $vmxWithoutSpace);

   # Checking for both in loop
   foreach my $vmxType (@arrayVMX) {
      $vmx = $vmxType;
      $vmx =~ s/\\//g;    # remove all slashes \
      my $data = $result->{result};
      if (ref($data) eq "ARRAY") {
         foreach my $element (@$data) {
            my $listVMX = $element->{'VM VMXPATH'};
            if ((defined $listVMX) && ($listVMX eq $vmx)) {
               return $element->{'VM NAME'};
            }
         }
      } else { # assuming output format is staf 4x-testware
         my @tempArray = split("\n", $data);
         foreach my $line (@tempArray) {
            if ($line =~ /(.*)\;(.*)\;(.*)/) {
               if ($3 eq $vmx) {
                  return $1;
               }
            }
         }
      }
   }

   $vdLogger->Error("Unable to find registered name for $vmx");
   VDSetLastError("ENOTDEF");
   return FAILURE;
}


########################################################################
#
# GetDataStoreName --
#      Method to get data store name by data store UUID
#
# Input:
#      stafHelper: an object of VDNetLib::Common::STAFHelper package
#                  (Required)
#      hostIP  : ip address of the host to which the anchor has to be
#                created # Required
#      dataStoreUUID : like 5420e44f-60f9e413-d990-0050569d8395
#
# Results:
#      A scalar string of the given given datastore name , like datastore1
#      A scalar string "FAILURE" in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub GetDataStoreName
{
   my $stafHelper = shift;
   my $hostIP     = shift;
   my $dataStoreUUID = shift;

   my $command = "esxcli --formatter=csv storage filesystem list | grep $dataStoreUUID";
   # sample output of esxcli --formatter=csv storage filesystem list
   #
   # esxcli --formatter=csv storage filesystem list
   # 1340080128,/vmfs/volumes/551a775c-74196922-cd22-00505698283b,true,24696061952,VMFS-5,551a775c-74196922-cd22-00505698283b,datastore1,
   # 4286971904,/vmfs/volumes/52565ef3-6359a3d4-c255-00505682ecc2,true,4293591040,vfat,52565ef3-6359a3d4-c255-00505682ecc2,,
   # 97198080,/vmfs/volumes/99129475-adfa5567-29d9-a59e4df71762,true,261853184,vfat,99129475-adfa5567-29d9-a59e4df71762,,
   # 96272384,/vmfs/volumes/0bbcb47e-0f20a68e-dc95-652d2656e37c,true,261853184,vfat,0bbcb47e-0f20a68e-dc95-652d2656e37c,,
   # 99147776,/vmfs/volumes/52565eb0-a133a2e8-7c44-00505682ecc2,true,299712512,vfat,52565eb0-a133a2e8-7c44-00505682ecc2,,

   my $result = $stafHelper->STAFSyncProcess($hostIP, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Debug("Failed to run command:$command on host:$hostIP".
                        Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   chomp($result->{stdout});
   my @dataStoreDetails = split(",", $result->{stdout});
   my $dataStoreName = pop @dataStoreDetails;
   $vdLogger->Info("Found dataStoreName: " . $dataStoreName .
                   " for dataStoreUUID: " . $dataStoreUUID);
   chomp($dataStoreName);
   return $dataStoreName;
}


########################################################################
#
# GetSTAFAnchor --
#      Method to get staf anchor (vm/host) required to execute any
#      STAF SDK related commands.
#
# Input:
#      hostIP  : ip address of the host to which the anchor has to be
#                created # Required
#      service : "host" or "vm" depending on whether host or vm service
#                in STAF SDK will be used
#      user    : userid to connect to the host # Optional, default
#                                                is root
#      password: password to connect to the host # Optional
#
# Results:
#      A scalar string of the given VM's registered name if successful;
#      A scalar string "FAILURE" in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub GetSTAFAnchor
{
   my $stafHelper = shift;
   my $hostIP     = shift;
   my $service    = shift || "host";
   my $user       = shift || "root";
   my $password   = shift;

   my $stafAnchor;

   if ((not defined $stafHelper) || (not defined $hostIP)) {
      $vdLogger->Error("STAFHelper object and/or hostip not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   #
   # Host's password is needed to create a STAF anchor for Host/VM service.
   # So, trying the default passwords one by one until successful.
   #
   my @passwords;
   if (defined $password) {
      push(@passwords,$password);
   } else {
      @passwords = VDNetLib::Common::GlobalConfig::DEFAULT_PASSWORDS;
   }
   foreach my $pwd (@passwords) {
      my $command = "CONNECT AGENT $hostIP SSL USERID \"$user\" " .
                    "PASSWORD \"$pwd\"";

      my $result;
      if ($service =~ /host/i) {
         $result = $stafHelper->STAFSubmitHostCommand("local",
                                                      $command);
      } elsif ($service =~ /setup/i) {
         $result = $stafHelper->STAFSubmitSetupCommand("local",
                                                      $command);

      } else {
         $result = $stafHelper->STAFSubmitVMCommand("local",
                                                    $command);
      }
      if ($result->{rc} == 0) {
         $stafAnchor = $result->{result};
         return $stafAnchor;
      }
   }

   if (not defined $stafAnchor) {
      $vdLogger->Warn("Failed to create $service staf anchor");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
}


########################################################################
#
# GetMulticastIP --
#      This routine gives an ip address (C class) available (not being
#      assigned to any interface) within the given machine's
#      sub-network.
#
# Input:
#      controlIP: ip address of a machine through which an available
#      class-c ip address has to be found.
#
# Results:
#      A string which is an IP address in the range 192.168.0.x to
#      192.168.1.x, where 0 < x < 255, if successful;
#      FAILURE, in case of any error or failure to find an ip within 10
#      retries.
#
# Side effects:
#      None
#
########################################################################

sub GetMulticastIP
{

   my $addressType = shift || undef;
   if(not defined $addressType){
      $addressType = "ipv4";
   } elsif($addressType =~ m/6$/i){
      $addressType = "ipv6";
   } else {
      $addressType = "ipv4";
   }
   my $ip = undef;
   # Multicast address.
   # 224.0.0.0 - 224.0.0.255- Reserved for well-known  multicast addresses.
   # 224.0.1.0 - 238.255.255.255- Internet-wide multicast addresses.
   # 239.0.0.0 - 239.255.255.255- local scoped multicast addresses.

   # We use 224.0.65.68 as default multicast address and use different ports
   # if we want to run parallel multicast sessions.
   if($addressType =~ m/4$/i) {
      my $lastOctet = VDNetLib::Common::Utilities::RandomNumberInRange(2, 254);
      return (DEFAULT_MULTICAST_ADDRESS . $lastOctet);
   } else {
      my $secondlastOctet = VDNetLib::Common::Utilities::RandomNumberInRange(1,9);
      my $lastOctet = VDNetLib::Common::Utilities::RandomNumberInRange(1,9);
      return (DEFAULT_IPV6_MULTICAST_ADDRESS . $secondlastOctet .$lastOctet);
   }
}


################################################################################
#
# ProcessVSISHOutput
#       Returns the ouptut of the VSISH Command as a hash reference if the
#       ouput is complex, else return as a string.
#
# Input:
#       RESULT : VSISH output, must be passed as scalar.
#
#
# Results:
#       Returns the output of the VSISH Command as a hash ref in necessary.
#
# Side effects:
#       None.
#
################################################################################

sub ProcessVSISHOutput
{
   my %args = @_;
   my $result = $args{RESULT};

   if (not defined $result){
      return FAILURE;
   }
   if ( $result !~ m/{|}/g ) {
      return $result;
   }
   $result =~ s/|^\s+|\s+$//g;
   $result =~ s/\'/\\'/g;
   $result =~ s/\"/\'/g;
   $result =~ s/\:\s\{|\:\{/ => {/g;
   $result =~ s/:/ => /g;
   my $hash = eval $result;
   return $hash;
}


########################################################################
#
# IsValidAddress --
#       This function will check whether the given string is valid IP
#       address (IPv4/IPv6)or valid domain name.
#
# Input:
#       Sting -- address sting
#
# Results:
#       SUCCESS if it is a valid IP or domain name else FAILURE
#
# Side effects:
#       None
#
########################################################################

sub IsValidAddress
{
   my $address = shift;
   my $ret;

   $ret = IsValidIP($address);
   if ( $ret eq "FAILURE"){
      # Check whether it is a valid domain name.
      if ( $address =~ m/([\w|-|_]+\.[\w|-|_]+)+\.[com|net|org]/gi ){
         return SUCCESS;
      } else {
         return FAILURE;
      }
    }
    return SUCCESS;

}


########################################################################
# UpdateVMX --
#	Appends the given list of lines into vmx file on the given host
#
# Input:
#       HOST, LIST Of lines, and VMXFILE
#       stafHelper - optional
#
# Results:
#       returns SUCCESS if successfully updated the VMX file else FAILURE
#
# Side effects:
#       none
#
########################################################################

sub UpdateVMX
{
   my $host = shift;
   my $list = shift;
   my $vmxFile = shift;
   my $stafHelper = shift;

   my ($command, $ret, $data);

   if ( not defined $host ||
        not defined $vmxFile ) {
      $vdLogger->Error("updatevmx: $host, @$list $vmxFile");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ( scalar(@$list) == 0 ) {
      # there is nothing to update, just return success
      return SUCCESS;
   }
   #
   # escape spaces and () with \
   #
   if ($vmxFile !~ /\\/) { # if already escaped, ignore
                           # TODO: take care of this for hosted
                           # (windows)
                           #
      $vmxFile =~ s/ /\\ /;
      $vmxFile =~ s/\(/\\(/;
      $vmxFile =~ s/\)/\\)/;
   }

   my $options;
   $options->{logObj} = $vdLogger;
   if (not defined $stafHelper) {
      $stafHelper = VDNetLib::Common::STAFHelper->new($options);
      if ( $stafHelper eq FAILURE ) {
         $vdLogger->Error("Failed to create STAFHelper object");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }

   foreach my $l (@$list) {
      my ($option, $value) = split(/=/, $l);
      $option =~ s/^\s+|\s+$//g;
      $value =~ s/^\s+|\s+$//g;
      $value =~ s/"//g; # remove any quotes around the value
      my $change = $option . " = " . "\"$value\"";
      my $currentEntry = CheckForPatternInVMX($host,
                                              $vmxFile,
                                              $option,
                                              $stafHelper);

      if (not defined $currentEntry) {
          $vdLogger->Error("CheckForPatternInVMX is undefined.");
          VDSetLastError("EFAIL");
          return FAILURE;
      }
      if (defined $currentEntry && $currentEntry ne "") {
         my ($existingOption, $existingValue) = split(/=/, $currentEntry);
         $existingValue =~  s/^\s+|\s+$//g;
         $existingValue =~ s/"//g; # remove any quotes around the value
         $existingOption =~  s/^\s+|\s+$//g;
         if ($existingValue eq $value) {
            next;
         } else {
            my $sedCmd;
            if ($value =~ /\{\{vdnet-erase\}\}/) {
               $sedCmd = "perl -p -i -e " .
                         "\"s/^$existingOption.*//\" "." $vmxFile ";
            } else {
               $sedCmd = 'perl -p -i -e ' .
                         '"s/^' . $existingOption . '.*/' . $option .
                         ' = "' . $value. '"/g" ' . $vmxFile;
            }
            $command = "$sedCmd ";
            $vdLogger->Debug("command: $command");
            my $result = $stafHelper->STAFSyncProcess($host, $command);
            # Process the result
            if ((($result->{rc} != 0) || ($result->{exitCode} != 0)) ||
                ($result->{stdout} ne "")) {
               $vdLogger->Error("Failed to execute $command or update vmx");
               VDSetLastError("ESTAF");
               $vdLogger->Error(Dumper($result));
               return FAILURE;
            }
         }
      } else {
         $command = 'echo '. " $change >> $vmxFile";
         my $result = $stafHelper->STAFSyncProcess($host, $command);
         # Process the result
         if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
               $vdLogger->Error("Failed to execute $command");
               VDSetLastError("ESTAF");
               $vdLogger->Error(Dumper($result));
               return FAILURE;
         } else {
            next;
         }
      }
   }
   return SUCCESS;
}


########################################################################
# CheckForPatternInVMX --
#       Looks for the given pattern in the VMX file of the given MACHINE
#	in the testbed
#
# Input:
#       ESX host ip, absolute path name of the esx file on the host, and
#	the pattern to grep in the vmx file
#       stafHelper object - optional
#
# Results:
#       return value of the egrep command
#
# Side effects:
#       none
#
########################################################################

sub CheckForPatternInVMX
{
   my $host = shift;
   my $vmxFile = shift;
   my $pattern = shift;
   my $stafHelper = shift;
   my $hostOS = shift || undef;
   my $command;

   if ( (not defined $pattern) || (not defined $host) ||
        (not defined $vmxFile) ) {
      $vdLogger->Error("CheckForPatternInVMX: invalid/undefined parms");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $options;
   $options->{logObj} = $vdLogger;
   if (not defined $stafHelper) {
      $stafHelper = VDNetLib::Common::STAFHelper->new($options);
      if ( $stafHelper eq FAILURE ) {
         $vdLogger->Error("Failed to create STAFHelper object");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }

   my ($option, $value) = split(/=/, $pattern);
   $option =~ s/^\s+|\s+$//g; # remove space before and after config key

   #
   # escape spaces and () with \
   #
   if ($vmxFile !~ /\\/) { # if already escaped, ignore
                           # TODO: take care of this for hosted (windows)
                           #
      $vmxFile =~ s/ /\\ /;
      $vmxFile =~ s/\(/\\(/;
      $vmxFile =~ s/\)/\\)/;
   }

   if (not defined $hostOS ||
      ((defined $hostOS) && ($hostOS =~ /(esx|vmkernel|linux)/i))) {
      $command = "egrep -i \'$option\' $vmxFile";
   } elsif ($hostOS =~ /^win/) {
      $command = "findstr \"$option\" $vmxFile";
   } else {
      $command = "egrep -i \'$option\' $vmxFile";
   }

   my $result = $stafHelper->STAFSyncProcess($host, $command);
   # Process the result
   # Returning undef if something wrong, parent function will take care
   # if it require to return FAILURE
   if ($result->{rc} != 0) {
      $vdLogger->Debug("Unable to find pattern \'$option\' in $vmxFile");
      VDSetLastError("ESTAF");
      $vdLogger->Debug(Dumper($result));
      return undef;
   }

   return $result->{stdout};
}


########################################################################
# GetInterruptModeFromVmwareLog --
#
# Input:
#       srcIP : ESX host IP where the vm used for testing is hosted.
#	modeStrORethUnit : Ethernet unit number
#       vmwarelog : vmware.log path
#       stafHelper: STAF Helper object
#
# Results:
#       Returns currently set interrupt mode value, in case of SUCCESS
#	FAILURE, in case of any ERROR
#	undef, if no interrupt mode is explicitly mentioned in the vmx
#	   file. This signifies the default interrupt mode. i.e. MSI-X
#
# Side effects:
#       none
#
########################################################################

sub GetInterruptModeFromVmwareLog
{
   my $srcIP	  = shift;
   my $modeStrORethUnit = shift;
   my $vmwarelog  = shift;
   my $stafHelper = shift;
   my $modeValue  = undef;

   my ($command, $ret, $data, $line);
   if ((not defined $modeStrORethUnit) ||
       (not defined $vmwarelog) ||
       (not defined $srcIP) ||
       (not defined $stafHelper)) {
      $vdLogger->Error("One or more parameters missing");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $line = "$modeStrORethUnit"."\.intrMode"." = ";
   #$line = "$modeStrORethUnit"."\.intrMode"." = "."$modeValue";
   $command = "grep 'intrMode' $vmwarelog";
   $ret = $stafHelper->STAFSyncProcess($srcIP, $command);
   # check for success or failure of the command
   if ($ret eq "FAILURE") {
      $vdLogger->Error(": Failed to get".
		       " the Interrupt mode info.");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $data = $ret->{stdout};

   if ($data =~ /$line(\d+).*/) {
      $modeValue = $1;
   }
   return $modeValue;
}


########################################################################
# GetEthUnitNum --
#       Returns the ethernet# corresponding to the given MAC address
#	in the given VMX file on the given HOST.  This method is only
#	applicable to ESX
#	Grep for the MAC address and return the first word.
#
# Input:
#       HOST, VMXFILE, and MAC address
#       stafHelper object - optional
#
# Results:
#       ethernet# if found else undef or FAILURE for any other error
#
# Side effects:
#       none
#
########################################################################

sub GetEthUnitNum
{
   my $host = shift;
   my $vmxFile = shift;
   my $mac = shift;
   my $stafHelper = shift;

   my $command;
   my $result;
   my $service;
   my $data;


   if ((not defined $host) ||
       (not defined $mac) ||
       (not defined $vmxFile)) {
      $vdLogger->Error("GetEthUnitNum: invalid/undefined parms");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $options;
   $options->{logObj} = $vdLogger;
   if (not defined $stafHelper) {
      $stafHelper = VDNetLib::Common::STAFHelper->new($options);
      if ( $stafHelper eq FAILURE ) {
         $vdLogger->Error("Failed to create STAFHelper object");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }

   #
   # escape spaces and () with \
   #
   if ($vmxFile !~ /\\/) { # if already escaped, ignore
                           # TODO: take care of this for hosted
                           # (windows)
                           #
      $vmxFile =~ s/ /\\ /;
      $vmxFile =~ s/\(/\\(/;
      $vmxFile =~ s/\)/\\)/;
   }

   #
   # vmx file always use : for mac address. ipconfig of windows has - in mac
   # address. Coverting hyphes to colons to be consistent
   #
   $mac =~ s/-/:/g;
   $mac =~ s/\s//g;
   $command = "grep -i $mac $vmxFile ";
   $result = $stafHelper->STAFSyncProcess($host, $command);
   # Process the result
   if ((($result->{rc} != 0) && ($result->{exitCode} != 0)) ||
       (not defined $result->{stdout})) {
      $vdLogger->Error("GetEthUnitNum: failed to get eth unit number " .
                       "for $mac" .  " in $vmxFile");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }

   # ethernet0.generatedAddress = "00:50:56:97:63:cc"
   if ( $result->{stdout} =~ /^ethernet(\d+).*/ ) {
      return "ethernet$1";
   } else {
      $vdLogger->Debug("ethernet entry in the vmx file is not in ".
                       "correct format for $mac in $vmxFile");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
}


########################################################################
#
# IsMounted --
#	Checks if a given share on given server is mounted on the
#	remote machine
#
# Input:
#       Remote machine's IP address
#       Remote machine's OS type
#       Server IP address
#       Mount/Share name on server
#       folder name on remote machine where it has to be mounted
#       stafHelper - optional
#
# Results:
#       Returns TRUE if share is mounted on a given folder on
#       remote machine else FALSE.  FAILURE for any other errors
#
# Side effects:
#       none
#
########################################################################

sub IsMounted
{
   my $ip = shift; # where you want to mount
   my $os = shift; # os type of the remote machine
   my $serverIP = shift; # mount server IP address
   # folder name on remote machine where it has to be mounted
   my $share = shift;
   my $folder = shift;
   my $stafHelper = shift;

   my ($command, $result, $data);

   if (($os =~ /lin/i) ||($os =~ /esx/i)) {
      # this should take care of both nfs and cifs mount
      $command = "mount | grep \"$serverIP:$share on $folder \"";
   } elsif ($os =~ /win/i) {
      $command = "net use $folder";
   } elsif ($os =~ /vmkernel|esxi/i) {
      $folder =~ s/^\///;
      $command = "esxcfg-nas -l | grep \"$folder is $share from\"";
   }
   my $options;
   $options->{logObj} = $vdLogger;
   if (not defined $stafHelper) {
      $stafHelper = VDNetLib::Common::STAFHelper->new($options);
      if ( $stafHelper eq FAILURE ) {
         $vdLogger->Error("Failed to create STAFHelper object");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   $command = STAF::WrapData($command);
   $result = $stafHelper->STAFSyncProcess($ip, $command);
   # Process the result
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Executing $command failed");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }
   $vdLogger->Debug("data: $result->{stdout}");

   if ($os =~ /win/i) {
      # remove / in case if full path of the share is given
      $share =~ s/^\///;
      $share =~ s/\//\\/g;
      $share = quotemeta($share);
      if ((defined $data) &&
          ($data =~ /$serverIP\\$share/) &&
          ($data =~ /Status\s+OK/i) ) {
         $vdLogger->Debug("Share $share from $serverIP is mounted on $folder");
         return VDNetLib::Common::GlobalConfig::TRUE;
      } else {
         $vdLogger->Debug("Share $share from $serverIP is NOT mounted on $folder");
         return VDNetLib::Common::GlobalConfig::FALSE;
      }
   }

   if ((defined $data) && ($data =~ /$serverIP/i)) {
      $vdLogger->Debug("Share $share from $serverIP is mounted on $folder");
      return VDNetLib::Common::GlobalConfig::TRUE;
   } else {
      $vdLogger->Debug("Share $share from $serverIP is NOT mounted on $folder");
      return VDNetLib::Common::GlobalConfig::FALSE;
   }
}


########################################################################
#
# GetActualVMFSPath --
#      Method to get the actual vmx path (which represents datastore
#      in an id) for the given absolute vmx path.
#      For example, the actual path of
#      /vmfs/volumes/datastore1/vdtest0/Win2k3.vmx is
#      /vmfs/volumes/4c609bdc-46e83530-9a8e-001e4f439d6f/vdtest0/Win2k3.vmx
#
# Input:
#      host: host on which the vmx file exists (Required)
#      absVMXPath: absolute path to a vmx file (Required)
#      stafHelper: reference to a VDNetLib::Common::STAFHelper object
#                  (Optional)
#
# Results:
#      The actual vmx path (scalar string), if successful;
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
#########################################################################


sub GetActualVMFSPath
{
   # Works only on ESX
   my $host = shift;
   my $absVmxPath = shift;
   my $stafHelper = shift;

   my $datastore = undef;
   # Extract the datastore information from the given vmx path
   if ($absVmxPath =~ /\/vmfs\/volumes\/(.*?)\/.*/i) {
      $datastore = $1;
   } elsif ($absVmxPath =~ /\/vmfs\/volumes\/(.*)/i) {
      # sometimes the path could be just /vmfs/volumes/<datastore>
      # Keeping both the conditions to avoid any regression.
      $datastore = $1;
   }

   if (not defined $datastore){
      $vdLogger->Error("Given file $absVmxPath is not an absolute vmx path");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Create an instance of STAFHelper if not defined.
   if (not defined $stafHelper) {
      my $options;
      $options->{logObj} = $vdLogger;
      $stafHelper = VDNetLib::Common::STAFHelper->new($options);
      if (not defined $stafHelper) {
         $vdLogger->Error("Failed to create object of STAFHelper");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   #
   # Get the target name of the datastore
   my $file = "/vmfs/volumes/$datastore";
   my $target = $stafHelper->STAFFSGetLinkTarget($file, $host);
   if (not defined $target) {
      $vdLogger->Error("Failed to get link target of $absVmxPath on $host");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   #
   # If there is no target available, then return the given path itself.
   if ($target =~ /None/) {
      return $absVmxPath;
   } else {
      my $temp = $target;
      $absVmxPath =~ s/[()]//g; # remove braces in path example, datastore1 (1)
      $datastore =~ s/[()]//g;
      # substitute the datastore in the given path with the target name
      # and return th entire path
      $absVmxPath =~ s/$datastore/$target/g;
      return $absVmxPath;
   }
}


########################################################################
#
# SerializeData --
#      This routine converts the given data format into one scalar
#      string. Doinn an eval() on the result of this method
#      would give the data in orinigal format.
#
# Input:
#      data in any format (scalar, array, hash)
#
# Results:
#      scalar string containing the given data in serialized format
#
########################################################################

sub SerializeData
{
   my ($thisArg) =@_;
   my $dumper = new Data::Dumper([$thisArg]);
   $dumper->Terse(1)->Indent(0);
   return $dumper->Dump();
}


########################################################################
#
# PrettyPrintDataStructure --
#      This routine converts a datatsructure into pretty format where
#      reference are resolved using Purity, indentation is fixed using
#      Indent and made concise through Terse. Also => in dict is replaced
#      with :.
#
# Input:
#      data in any format (scalar, array, hash)
#
# Results:
#      Return data in pretty format
#
########################################################################

sub PrettyPrintDataStructure
{
   my ($thisArg) = shift;
   my $dumper = new Data::Dumper([$thisArg]);
   $dumper->Indent(1);
   $dumper->Terse(1);
   $dumper->Purity(1);
   return $dumper->Dump();
}


########################################################################
#
# GetIPfromHostname --
#      This routine gives the ip address for the given hostname.
#
# Input:
#      hostname: host whose ip address need to be found (Required)
#
# Results:
#      ip address (scalar string), if successful;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetIPfromHostname
{
   my $hostname = shift;

   if (not defined $hostname) {
      $vdLogger->Error("hostname not provided");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($hostname =~ /^([\d]+)\.([\d]+)\.([\d]+)\.([\d]+)$/) {
      # given hostname is already an ip address
      return $hostname;
   }

   # Using nslookup to find the ip address for the given hostname
   my $result = `nslookup $hostname`;

   $result =~ s/\n/ /g; # converts all lines into just one line

   # Looks for Name: <hostname> Address: <ip address> from the output above
   if ($result =~ /Name:\s+(.*)Address:\s(.*)/i) {
      my $ip = $2;
      $ip =~ s/\s//g;   # remove any space
      return $ip;
   } else {
      $vdLogger->Error("Failed to get ip address of $hostname");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


########################################################################
#
# GetAvailableTestIPv6 --
#      This routine gives an ipv6 address available (not being
#      assigned to any interface) within the given machine's
#      sub-network.
#
# Input:
#      controlIP: ip address of a machine through which an available
#      ipv6 address has to be found.
#
# Results:
#      A string which is an IP address in the range 2001:bd6::000c:2957:x,
#      where 0 < x < 999, if successful;
#      FAILURE, in case of any error or failure to find an ip within 10
#      retries.
#
# Side effects:
#      None
#
########################################################################

sub GetAvailableTestIPv6 {
   my $controlIP = shift || "local";

   $controlIP = VDNetLib::Common::Utilities::GetIPfromHostname($controlIP);
   if ($controlIP eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }


   # STAFHelper object is required to run a ping command on the given machine
   my $hash = {'logObj' => $vdLogger};
   my $stafObj = new VDNetLib::Common::STAFHelper($hash);
   if(not defined $stafObj) {
      $vdLogger->Error("Failed to create STAF object");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $vdLogger->Info("Finding an IPv6 address available on $controlIP " .
                   "sub-network");

   my $ip = undef;
   my $thirdIpv4Octet  = undef;
   my $fourthIpv4Octet = undef;
   my $randomFourthIpv4Octet = undef;
   my $retries = 0;
   my $command;
   #
   # This algorithm picks the last 2 octets of IP address from the third and
   #fourth octet of the control IP address.If the fourth octet of control ip
   #is 0, it will pick a  randomn value between 1 to 999 for the last octet.
   #If last 2 octets are chosen, then it is appended to "2001:bd6::000c:2957:".
   # This ip address is pinged to see if there is any response. If no response,
   #then it is assumed available. Otherwise, a random last octet will be selected.
   #
   if ($controlIP =~ /(\d+)\.(\d+)$/) {
      $thirdIpv4Octet = $1;
      $fourthIpv4Octet = $2;
      if ($fourthIpv4Octet eq "0") {
         $randomFourthIpv4Octet = VDNetLib::Common::Utilities::RandomNumberInRange(1, 999);
         $ip = "2001:bd6::c:2957:" . $thirdIpv4Octet . ":" . $randomFourthIpv4Octet;
      } else {
         $ip = "2001:bd6::c:2957:" . $thirdIpv4Octet . ":" . $fourthIpv4Octet;
      }
   }
   while ($retries < 10) {
      if ($stafObj->GetOS($controlIP) =~ /win/i) {
         $command = "ping -6 -n 1 $ip";
      } else {
         $command = "ping6 -c 1 $ip";
      }
      my $result = $stafObj->STAFSyncProcess($controlIP,
                                             $command,
                                             30);
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to execute command on $controlIP");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      if ($result->{exitCode} != 0 || $result->{stdout} =~ /unreachable/i) {
         return $ip;
      }
      $randomFourthIpv4Octet = VDNetLib::Common::Utilities::RandomNumberInRange(1, 999);
      # if the last octet is a random number, then use 192.168.1.x
      $ip = "2001:bd6::c:2957:" . $thirdIpv4Octet . ":" . $randomFourthIpv4Octet;
      $retries++;
   }
   return FAILURE;
}


########################################################################
#
# GetMACFromIP --
#      Routine to get mac address from given ip address. This method
#      required staf to be running at the end point.
#
# Input:
#      ipAddress: ip address for which mac address is to be found
#                 (Required).
#      stafHelper: reference to object of VDNetLib::Common::STAFHelper
#                 (Required)
#
# Results:
#      mac address (scalar string) of the given ip address,
#        if successful;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetMACFromIP
{
   my $ipAddress  = shift;
   my $stafHelper = shift; # Reference to object of
                           # VDNetLib::Common::STAFHelper
   my $controlIP = shift || $ipAddress;
   my $os = shift || undef;

   if ((not defined $ipAddress) || (not defined $stafHelper)) {
      $vdLogger->Error("ip address and/or stafhelper not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # Get the guest os type
   #
   if (not defined $os) {
      $os = $stafHelper->GetOS($controlIP);
   }

   if (not defined $os) {
      $vdLogger->Error("Failed to get $controlIP os type, staf running?");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $command;
   if (($os =~ /lin/i ) || ($os =~ /BSD/i)){
      $command = "ifconfig -a ";
   } else {
      $command = "ipconfig /all ";
   }

   my $result = $stafHelper->STAFSyncProcess($controlIP, $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to execute command $command on $controlIP");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my @cmdout = split("\n",$result->{stdout});

   my $start = 0;
   my ($ipaddr, $phyaddr);
   my @tmparr;

   #
   #  This block is from VDNetLib::Common::STAFHelper.
   #  No changes made to that.
   #
   foreach my $line (@cmdout) {
      if ($line =~ /\s*\t*Physical Address*/ ) {
         @tmparr = split(/:/,$line);
         $phyaddr = $tmparr[1];
         $phyaddr =~ s/^\s*//;
         chomp($phyaddr);
         $phyaddr =~ s/-/:/g;
      } elsif ( $line =~ /^eth/ ) {
         $line =~ s/\s+/ /g;
         @tmparr = split(/ /,$line);
         $phyaddr = $tmparr[4];
         $phyaddr =~ s/^\s*//;
      }
       elsif ( $line =~ /ether/ ) {
         $line =~ s/\s+/ /g;
         my @macarr = split(/ /,$line);
         $phyaddr = $macarr[2];
         $phyaddr =~ s/^\s*//;
      }


      # For Linux
      if ($ipAddress =~ /:/) {
         if ($line =~ /inet6 addr/) {
            my @iparray = split(' ', $line);
            @iparray = split ('/', $iparray[2]);
            return $phyaddr if ( $iparray[0] =~ $ipAddress );
         }
      } else {
         if ( $line =~ /.*inet addr\:(.*?) .*/ ) {
            $ipaddr = $1;
            $ipaddr =~ s/^\s*//;
            return $phyaddr if ( $ipaddr =~ $ipAddress );
         }
      }

      # For BSD
      if ($ipAddress =~ /:/) {
         if ($line =~ /inet6/) {
            my @iparray = split(' ', $line);
            @iparray = split ('%', $iparray[2]);
            return $phyaddr if ( $iparray[0] =~ $ipAddress );
         }
      } else {
         if ( $line =~ /.*inet / ) {
                my @iparray = split " ", $line;
            	$ipaddr=$iparray[1];
            	return $phyaddr if ( $ipaddr =~ $ipAddress );
         }
      }

      # For Windows
      if ($ipAddress =~ /:/) {
         if ( $line =~ /\s*\t*IP|IPv6 Address*/ ) {
            @tmparr = split(/: /,$line);
            $ipaddr = $tmparr[1];
            next if not defined $ipaddr;
            $ipaddr =~ s/^\s+//;
            $ipaddr =~ s/\s+$//;
            if ($ipaddr =~ /\(/) {
               @tmparr = split('\(', $ipaddr);
               $ipaddr = $tmparr[0];
            }
            chomp($ipaddr);
            return $phyaddr if ($ipaddr =~ $ipAddress);
         }
      } else {
         if ( $line =~ /\s*\t*IP|IPv4 Address*/ ) {
            @tmparr = split(/:/,$line);
            $ipaddr = $tmparr[1];
            next if not defined $ipaddr;
            $ipaddr =~ s/^\s+//;
            $ipaddr =~ s/\s+$//;
            return $phyaddr if ($ipaddr =~ $ipAddress);
         }
      }
   }
   $vdLogger->Error("Failed to get mac address of $ipAddress");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


########################################################################
#
# GetKernelVersion --
#      Routine to get Linux kernel's minor and major version number
#
# Input:
#      srcControlIP:   IP address of SUT (Required).
#      newSTAFHelper:  newSTAFHelper object (Required)
#
# Results:
#      kernel minor and major version numbers, if successful;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetKernelVersion
{
   my $srcControlIP = shift;
   my $newSTAFHelper = shift;
   my $ret;
   my $data;
   my $minorVersion;

   my $command = "uname -r";

   if ($srcControlIP =~ /local/i) {
      $data = `$command`;
   } else {
      $ret = $newSTAFHelper->STAFSyncProcess($srcControlIP, $command);
      if ($ret eq "FAILURE") {
         $vdLogger->Error("Failed to obtain interrupt mode info");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      $data = $ret->{stdout};
   }

   my @version = split('\.', $data);
   if ($version[2] =~ /-/) {
      my @subver = split('-', $version[2]);
      $minorVersion = $subver[0];
   } else {
      $minorVersion = $version[2];
   }
   # If the kernel version is like 2.6.28, returns minorVersion as 28
   # and majorVersion as 2.
   return ($minorVersion, $version[0]);
}


########################################################################
#
# KillDHClient --
#      Routine to kill the DHClient process on the remote host/vm
#
# Input:
#      targetControlIP:   IP address of target host/vm (Required).
#      targetInterface:   Interface name (e.g. eth3) (Required).
#      newSTAFHelper  :   newSTAFHelper object (Required)
#
# Results:
#      SUCCESS, if successful;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub KillDHClient
{
   my $targetControlIP = shift;
   my $targetInterface = shift;
   my $newSTAFHelper = shift;
   my $result;

   if ((not defined $targetControlIP) ||
	(not defined $targetInterface)||
	(not defined $newSTAFHelper)) {
      $vdLogger->Warn("IP address and/or Interface-name".
		      " and/or stafhelper not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $command = "pkill -9 -f ";

   $command = $command . "dhclient-" . $targetInterface;

   $vdLogger->Debug("Executing the command : $command on host: $targetControlIP");
   $result = $newSTAFHelper->STAFSyncProcess($targetControlIP, $command, 30);

   if ($result->{rc} != 0) {
      $vdLogger->Warn("Failed to execute command: $command on host: ".
		       "$targetControlIP. Stdout: $result->{stdout}");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# ConfigureLinuxService --
#   Checks if a service is running on linux. Performs desired action on
#   that service.
#
# Input:
#       Remote machine's IP address
#       Remote machine's OS type
#       Service Name - E.g. NFS, iptables, SMB
#       Action - Start Stop
#       stafObj - STAFHelper Obj.
#
# Results:
#       SUCCESS in case action is done performed correctly
#       FAILURE in case of error
#
# Side effects:
#       Yes. Some services might require reboot of OS after we set them
#       to start status. Their current status would still show stopped.
#
########################################################################

sub ConfigureLinuxService
{
   my $ipAddress  = shift;
   my $os = shift;
   my $serviceName = shift;
   my $action = shift;
   my $stafHelper = shift; # Reference to object of
                           # VDNetLib::Common::STAFHelper
   my $serviceStatus = undef;
   my ($result, $data);

   if ((not defined $ipAddress) || (not defined $stafHelper) ||
       (not defined $serviceName) || (not defined $action)) {
      $vdLogger->Error("ip address and/or stafhelper not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (($os !~ /lin/i)) {
      return SUCCESS;
   } elsif($action !~ /start/i && $action !~ /stop/i) {
      $vdLogger->Error("Only Start/Stop Service is support.");
      return FAILURE;
   }

   # It will be 3 step process.
   # Check status of service - if status is desired return there itself.
   # Do the desired action
   # Check the status again to verify if the desired action was performed.
   my $cmd = "service $serviceName status";
   $result = $stafHelper->STAFSyncProcess($ipAddress, $cmd);
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to execute $cmd on $ipAddress");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }

   if (($result->{stdout}=~ /is stopped/i && $action =~ /stop/i) ||
       ($result->{stdout}=~ /is running/i && $action =~ /start/i) ||
       ($result->{stdout}=~ /is not running/i && $action =~ /stop/i) ||
       ($result->{stdout}=~ /Table:\s+?filter/i && $action =~ /start/i)) {
      $vdLogger->Debug("$serviceName status on $ipAddress is $action");
      return SUCCESS;
   } else {
      $vdLogger->Trace("$serviceName status on $ipAddress:$result->{stdout}");
   }

   if ($result->{stdout} =~ /unrecognized service/i ) {
      VDSetLastError("EFAILED");
      return FAILURE;
   }

   $cmd = "service $serviceName $action";
   $result = $stafHelper->STAFSyncProcess($ipAddress, $cmd);
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to execute $cmd on $ipAddress");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }

   # Execute chkconfig to store the status permanently of the service
   # in case serveice status get changed again after VM reboot
   my $service_status;
   if ($action =~ /stop/i) {
      $service_status = 'off';
   } else {
      $service_status = 'on';
   }
   $cmd = "chkconfig $serviceName $service_status";
   $result = $stafHelper->STAFSyncProcess($ipAddress, $cmd);
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to execute $cmd on $ipAddress");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }

   $cmd = "service $serviceName status";
   $result = $stafHelper->STAFSyncProcess($ipAddress, $cmd);
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to execute $cmd on $ipAddress");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }
   if (($result->{stdout}=~ /is stopped/i && $action =~ /stop/i) ||
       ($result->{stdout}=~ /is running/i && $action =~ /start/i) ||
       ($result->{stdout}=~ /is not running/i && $action =~ /stop/i) ||
       ($result->{stdout}=~ /Table:\s+?filter/i && $action =~ /start/i)) {
      $vdLogger->Debug("$serviceName status on $ipAddress is $action");
      return SUCCESS;
   }

   $vdLogger->Trace("$serviceName status on $ipAddress:$result->{stdout}");
   VDSetLastError("EFAILED");
   return FAILURE;
}


########################################################################
#
# Ping --
#   Description: pings to the given IP address to verify it
#                its responsiveness
#
# Input:
#       host: Host which needs to be pinged
#
# Results:
#       0 if the host is pingable
#       1 if the host is not pingable
#
# Side effects:
#       None
#
########################################################################

sub Ping
{
   my $host = shift;
   my $pingresult = system("ping -c 3 -W 5 $host > /dev/null 2>&1");
   return $pingresult ? 1 : 0;
}


########################################################################
#
# GetLockAccess--
#      Routine to check whether the given host has lock access on the
#      given lock. The lock is valid for the storage/directory under
#      which the lock file is present.
#      For example, if lock filename is /vmfs/volumes/vdtest/.lckvdnet,
#      then the lock .lckvdnet is for the directory /vmfs/volumes/vdtest
#      This is vdNet specific implementation following the idea of
#      vmkernel locks.
#
# Input:
#      lockFileName : Absolute path to a lock filename (Required)
#      host         : host on which the lock is present (Required)
#      uniqueID     : id/string that represents a lock (Required)
#      stafHelper   : reference to object of
#                     VDNetLib::Common::STAFHelper (Required)
#
# Results:
#      undef, if the given lock filename does not exist;
#      0, if the given host has access to a lock on the given
#         storage/directory;
#      1, if the given host has NO access to a lock on the given
#         storage/directory;
#
# Side effects:
#      None
#
########################################################################

sub GetLockAccess
{
   my $lockFileName = shift;
   my $host         = shift;
   my $uniqueID     = shift;
   my $stafHelper   = shift;
   my $result;

   # GetFileSystemType(IP, lockfilename)
   # If vsan, then call vsan staf method instead of STAFFS
   # else continue with regular flow

   #
   # First check if the file is present or not.
   #

   if ( GetFileSystemType($host, $lockFileName, $stafHelper ) =~ /vsan/i ) {
      # Send the command to Host
      my $command = 'cat $lockFileName';
      my $ret = $stafHelper->STAFSyncProcess( $host, $command);
      if ($ret->{exitCode} != 0 || $ret->{rc} != 0) {
         $vdLogger->Error("Failed to execute command $command on $host".
                           Dumper($ret));
         return undef;
      }
      $result = $ret->{data};
   } else {
      $result = $stafHelper->STAFFSReadFile( $host, $lockFileName );
   }

   if (not defined $result) {
      return  undef;
   }

   chomp($result);

   if ($result eq $uniqueID) {
      return VDNetLib::Common::GlobalConfig::TRUE;
   } else {
      $vdLogger->Debug("Lock access $lockFileName not permitted on $host:" .
                        $result);
         return VDNetLib::Common::GlobalConfig::FALSE;
   }
}

########################################################################
#
# CreateLockFile--
#      Routine to create a lock file for the given host.
#      The lock is valid for the storage/directory under which the
#      lock file need to be created.
#      For example, if lock filename is /vmfs/volumes/vdtest/.lckvdnet,
#      then the lock .lckvdnet is for the directory /vmfs/volumes/vdtest
#      This is vdNet specific implementation. The lock does not prevent
#      access to the locked directory by any non-vdnet process.
#
# Input:
#      lockFileName : Absolute path to a lock filename (Required)
#      host         : host for which the lock is needed (Required)
#      uniqueID     : id/string that represents a lock (Required)
#      stafHelper   : reference to object of
#                     VDNetLib::Common::STAFHelper (Required)
#
# Results:
#      "SUCCESS", if a lock file is created under the given location
#                 for the given host;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub CreateLockFile
{
   my $lockFileName = shift;
   my $host     = shift;
   my $uniqueID = shift;
   my $stafHelper = shift;

   my $result;
   #
   # Check if a lock by the given name already exists, if yes,
   # check if the given host and current process has access to edit it.
   # If access is allowed, then replace the lock.
   #
   my $access = VDNetLib::Common::Utilities::GetLockAccess($lockFileName,
                                                           $host,
                                                           $uniqueID,
                                                           $stafHelper);
   if ((defined $access) && $access) {
      return SUCCESS;
   } elsif (not defined $access) { # if no file already exists
      #
      # Create lock file with unique content in it.
      # Escape lockFileName with double qoutes is required to handle datastore
      # names with space.
      #
      my $command = "echo $uniqueID > \"$lockFileName\"";
      $result = $stafHelper->STAFSyncProcess($host, $command);
      if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to execute $command on $host");
         $vdLogger->Debug("Error:" . Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      return SUCCESS;
   } else { # if the given host/process has no access to replace existing lock
            # file, then throw error
      $vdLogger->Error("No access to create lock file $lockFileName");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


########################################################################
#
# RemoveLockFile--
#      Routine to remove a lock file on the given host.
#      This is vdNet specific implementation.
#
# Input:
#      lockFileName : Absolute path to a lock filename (Required)
#      host         : host on which the lock is present (Required)
#      uniqueID     : id/string that represents a lock (Required)
#      stafHelper   : reference to object of
#                     VDNetLib::Common::STAFHelper (Required)
#
# Results:
#      "SUCCESS", if a lock file is removed from the given host;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub RemoveLockFile
{
   my $lockFileName = shift;
   my $host     = shift;
   my $uniqueID = shift;
   my $stafHelper = shift;

   my $access = VDNetLib::Common::Utilities::GetLockAccess($lockFileName,
                                                           $host,
                                                           $uniqueID,
                                                           $stafHelper);
   if (not defined $access) {
      return SUCCESS; # no lock file to remove
   }
   if ($access == VDNetLib::Common::GlobalConfig::FALSE) {
      $vdLogger->Error("No access to create lock file $lockFileName");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $result = $stafHelper->STAFFSDeleteFileOrDir($host, $lockFileName);
   if (not defined $result) {
      $vdLogger->Error("Failed to delete $lockFileName on $host");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetPerlVersion--
#      Routine to get the perl version installed on the given host.
#
# Input:
#      host      : host from which perl version need to obtained
#                  (Required)
#      stafHelper: reference to an object of
#                  VDNetLib::Common::STAFHelper (Required)
#
# Results:
#      perl version (scalar string), if successful;
#      FAILURE in case of any errors;
#
# Side effects:
#      None
#
########################################################################

sub GetPerlVersion
{
   my $host       = shift;
   my $stafHelper = shift;

   my $command;
   my $result;

   # This command is common across various guest OS
   $command = "perl -v";

   $result = $stafHelper->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to execute $command on $host");
      $vdLogger->Debug("Error:" . Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Check the perl version which will be in the format vX.X.X
   if ($result->{stdout} =~ / v(\d+\.\d+\.\d+) /i) {
      return $1;
    } else {
       $vdLogger->Debug("GetPerlVersion error: " . Dumper($result));
       return FAILURE;
    }
}

########################################################################
#
# UpdateSymlink --
#   Create Symlink on a host with given parameters
#
# Input:
#       host: On which symlink needs to be created
#       sourceFile: File which is to be symlinked (mandatory)
#       DestDir: Dir where symlink is to be created (mandatory)
#       Symlink Name: Name of symlink (optional)
#       STAFHelper: Staf Obj already created
#
# Results:
#       SUCCESS - if symlink is created or exists
#       FAILURE in case of error
#
# Side effects:
#       None
#
########################################################################

sub UpdateSymlink
{
   my $host = shift;
   my $sourceFile = shift;
   my $destDir = shift;
   my $symlinkName = shift;
   my $stafHelper = shift;

   if ((not defined $host) ||
      (not defined $sourceFile) ||
      (not defined $destDir)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if(not defined $stafHelper) {
      my $options;
	  $options->{logObj} = $vdLogger;
	  $stafHelper = VDNetLib::Common::STAFHelper->new($options);
	  if (not defined $stafHelper) {
	     $vdLogger->Error("UpdateSymlink:STAF is not running");
	  }
   }

   # remove the last char if it is "/"
   if ((length($destDir) > 0) && (substr($destDir, -1) eq "/")) {
      $destDir = substr($destDir, 0, length($destDir)-1);
   }

   $symlinkName = "" if (not defined $symlinkName);
   my ($command, $result, $data);
   if ($stafHelper->GetOS($host) !~ /win/i) {

      $result = $stafHelper->DirExists($host, "$destDir/$symlinkName");
      if ($result == 1) {
         # Check if symlink is already pointing to same src. if yes
         # then return SUCCESS.
         $command = "ls -l '$destDir/$symlinkName' ";
         $result = $stafHelper->STAFSyncProcess($host, $command);
         if ($result->{rc} && $result->{exitCode}) {
            $vdLogger->Error("Staf error while removing symlink on $host:".
                              $result->{result});
            VDSetLastError("ESTAF");
            return FAILURE;
         } elsif ($result->{stdout} =~ /-> $sourceFile$/) {
            $vdLogger->Debug("Symlink to '$destDir/$symlinkName' ".
                             "already exists");
            return SUCCESS;
         }

         # Remove the old symlink before creating new one.
         my $options;
         $options->{recurse}      = 1;
         $options->{ignoreerrors} = 1;
         my $result = $stafHelper->STAFFSDeleteFileOrDir($host,
                                                         "$destDir/$symlinkName",
                                                         $options);
         if (not defined $result) {
            $vdLogger->Warn("Failed to remove $destDir/$symlinkName on $host");
            $vdLogger->Debug(Dumper($result));
            VDSetLastError("ESTAF");
            return FAILURE;
         }
      }

      $command = "ln -sf $sourceFile '$destDir/$symlinkName' ";
      $result = $stafHelper->STAFSyncProcess($host, $command);
      if ($result->{rc} && $result->{exitCode}) {
         $vdLogger->Error("Staf error while removing symlink on $host:".
                           $result->{result});
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      # Verify if the symlink got created.
      $command = "ls -l '$destDir/$symlinkName' ";
      $result = $stafHelper->STAFSyncProcess($host, $command);
      if ($result->{rc} && $result->{exitCode}) {
         $vdLogger->Error("Staf error while removing symlink on $host:".
                           $result->{result});
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      if ($result->{stdout} =~ /no such file or directory/) {
         $vdLogger->Error("Create symlink failed on $host:".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("CreateSymlink Not Implemented on this host type");
      VDSetLastError("ENOTIMPL");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# VMwareToolsVIMCMDVersion --
#       Convert VMware Tools Version from VIM-CMD format to that given
#       inside guest and vice versa.
#
# Input:
#       $task - which way to convert.
#
# Results:
#       tools version
#       FAILURE in case of error
#
# Side effects:
#       None
#
########################################################################

sub VMwareToolsVIMCMDVersion
{
   my $tools_version = shift;
   my $task = shift || "vimcmd_to_toolboxcmd";

   if (not defined $tools_version){
      $vdLogger->Error("Tools version missing in VMwareToolsVIMCMDVersion");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my ($Version_Major, $Version_Minor, $Version_Sub, $vimcmd_version);
   # Conver the VMware Tool version from vim-cmd format to
   # vmware-toolbox-cmd format

   if($task =~ /vimcmd_to_toolboxcmd/i) {
      $vimcmd_version = $tools_version;
      $Version_Major = $vimcmd_version>> 10;
      $Version_Minor = ($vimcmd_version  >> 5) & 0x1f;
      $Version_Sub = $vimcmd_version  & 0x1f;
      $tools_version = $Version_Major . "." . $Version_Minor . "." .
                       $Version_Sub;
   } elsif($task =~ /toolboxcmd_to_vimcmd/i) {
      # Will implement as and when the need arises
   }

   return $tools_version;
}


########################################################################
#
# ReadLink --
#      Routine to read the symlink (if any) of the given path
#
# Input:
#      file : absolute path of a file or directory (required)
#      host : host which the file is located (required)
#      stafHelper : reference to object of VDNetLib::Common::STAFHelper
#                   (required)
#
# Results:
#      link to the given path (scalar string), if successful;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub ReadLink
{
   my $file       = shift;
   my $host       = shift;
   my $stafHelper = shift;

   if ((not defined $file) || (not defined $host) ||
      (not defined $stafHelper)) {
      $vdLogger->Error("ReadLink - One or more parameters missing");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $command = "readlink -f $file";
   my $result  = $stafHelper->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0)) {
      $vdLogger->Error("Failed to execute $command on $host:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if (not defined $result->{stdout}) {
      $vdLogger->Info("Failed to find symlink of $file on $host");
      $vdLogger->Trace(Dumper($result->{stdout}));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $result->{stdout} =~ s/\n//g; # remove new line character
   return $result->{stdout};
}


########################################################################
#
# GetVCCredentials --
#      Routine to get the login credentials for the given VC
#
# Input:
#      vcaddr	  : IP address of the VC (required)
#      stafHelper : reference to object of VDNetLib::Common::STAFHelper
#                   (required)
#
# Results:
#      login credentials (username/passwd), in case of success;
#      "undef", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub GetVCCredentials
{
   my $stafHelper = shift;
   my $vcaddr	  = shift;
   my $proxy	  = VDNetLib::Common::GlobalConfig::DEFAULT_STAF_SERVER;

   my $possibleVCLogins = VDNetLib::Common::GlobalConfig::DEFAULT_VC_CREDENTIALS;

   if ((not defined $vcaddr) || (not defined $stafHelper)) {
      $vdLogger->Error("GetVCCredentials - One or more parameters missing");
      VDSetLastError("ENOTDEF");
      return (undef, undef);
   }
   $vdLogger->Debug("Checking for the correct VC credentials among the following: " .
		    Dumper($possibleVCLogins));
   #
   # Administrator/UNCENSORED is more common credentials for VC. Thus sorting
   # keys would improve the chances of hitting the right login in first attemp
   #
   foreach my $user (sort keys %$possibleVCLogins) {
      my $passwd = $possibleVCLogins->{$user};
      # command to connect to VC
      my $command = " connect agent ".$vcaddr." userid \"".$user."\" password \"" .
                    $passwd."\" ssl ";
      $vdLogger->Debug("proxy:$proxy, command:$command");
      my $result = $stafHelper->STAFSubmitVMCommand($proxy,$command);
      if ($result->{rc} != 0) {
         $vdLogger->Debug("Could not connect to VC with crendentials:
                          $user/$passwd:" . Dumper($result));
         next;
      }
      $vdLogger->Debug("Could connect to VC with crendentials: $user/$passwd");
      return ($user, $passwd);
   }

   return (undef, undef);
}


########################################################################
#
# GetPswitchCredentials --
#      Routine to get the login credentials for given physical switch
#
# Input:
#      vcaddr	  : IP address of the Physical Switch (required)
#
# Results:
#      login credentials (username/passwd), in case of success;
#      "undef", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub GetPswitchCredentials
{
   my $switchName = shift;
   my $sessionObj = undef;
   my $user	  = undef;
   my $passwd	  = undef;

   my $transport	     = VDNetLib::Common::GlobalConfig::DEFAULT_SWITCH_TRANSPORT;
   my $possiblePswitchLogins = VDNetLib::Common::GlobalConfig::DEFAULT_SWITCH_CREDENTIALS;

   if (not defined $switchName) {
      $vdLogger->Error("GetPswitchCredentials - Pswitch Id is not provided.");
      VDSetLastError("ENOTDEF");
      return (undef, undef);
   }
   $vdLogger->Debug("Checking for the correct Pswitch credentials among the " .
		    "following:" . Dumper($possiblePswitchLogins));

   foreach $user (keys % $possiblePswitchLogins) {
      eval {
	 $passwd = $possiblePswitchLogins->{$user};
	 # command to connect to Pswitch
	 $sessionObj = Net::Appliance::Session->new(Host      => $switchName,
						    Transport => $transport);
	 $vdLogger->Debug("GetPswitchCredentials - Session Object Created");

	 $sessionObj->connect(Name => $user,
			      Password => $passwd,
			      SHKC => 0);
	 $vdLogger->Debug("Connection to $switchName established Successfully");
      };
      #
      # If any errors occur in any of switch configuration statements in the above
      # eval block. They are caught below and the corresponding error is Reported.
      #
      if ($@) {
	 if(defined $sessionObj) {
	    $sessionObj->close();
	    # 5 seconds of sleep is required for the login prompt to return on
	    # the  physical  switch, so that future connect calls can succeed.
	    sleep 5;
	 }
	 $vdLogger->Debug("Could not connect to Pswitch with crendentials: $user/$passwd");
	 $vdLogger->Debug("GetPswitchCredentials - $@");
	 next;
      }
      $vdLogger->Debug("Could connect to Pswitch with crendentials: $user/$passwd");
      if(defined $sessionObj) {
	 $sessionObj->close();
	 # 5 seconds of sleep is required for the login prompt to return on
	 # the  physical  switch, so that future connect calls can succeed.
	 sleep 5;
      }
      return ($user, $passwd);
   }
   return (undef, undef);
}


########################################################################
#
# InstallSTAF--
#     Routine to install STAF on the given machine
#
# Input:
#     sshHost: reference to object of VDNetLib::Commom::SshHost (Required)
#     host : hostname or ip address of the host (Required)
#
# Results:
#     undef, in case of any error; # to maintain minimum code changes
#                                  # w.r.t the same API in ATLAS, that
#                                  # way maintenance is easy
#
# Side effects:
#     None
#
########################################################################

sub InstallSTAF
{
   my $sshHost = shift;
   my $host = shift;
   my $output;

   if ((not defined $sshHost) || (not defined $host)) {
      $vdLogger->Error("SshHost object and/or host not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $rcStaf = 0;
   my $rcRP = 0;
   my $rcLocal = "";

   my $stop_new_firewall_cmd = CMD_NEW_STOP_VISOR_FIREWALL;
   my ($rc, $out) = $sshHost->SshCommand($stop_new_firewall_cmd);
   $vdLogger->Debug("Ran command: $stop_new_firewall_cmd, RC: $rc, output: @$out");

   # TODO: use the staf server based on the location
   # (Bglr/PA/Cambridge/Beijing)
   my ($mountStAutomation, $shareStAutomation);
   my $stafMirror = $ENV{VDNET_STAF_MIRROR};
   if (defined $stafMirror) {
      ($mountStAutomation, $shareStAutomation) = split(":", $stafMirror);
   } else {
      ($mountStAutomation, $shareStAutomation) = ('pa-group.eng.vmware.com',
                                                  '/stautomation');
   }
   my $mountDirVisor     = "pa-group-stautomation";
   my $CMD_MOUNT_STAUTOMATION = "esxcfg-nas -y -a -o $mountStAutomation ".
                                 "-s $shareStAutomation $mountDirVisor";
   my $CMD_UNTAR_STAF = "tar -xvf /vmfs/volumes/$mountDirVisor/Vmvisor/staf.tar";

   # Get rc.local
   my $localRcLocal = "/tmp/$sshHost->{host}.rc.local";
   $sshHost->ScpFromCommand("/etc/rc.local", $localRcLocal);
   `chmod 777 $localRcLocal`; # if running as non-root, then copying file from
                              # remote host will only have read permissions
   if (not defined (open (FH_RC_LOCAL, "< $localRcLocal"))) {
      $vdLogger->Error("Failed to open $localRcLocal");
      return undef;
   }
   while (<FH_RC_LOCAL>) {
      $rcLocal .= $_;
      if ($_ =~ /[^#]*STAFProc/) {
         $vdLogger->Debug("Found STAFProc in /etc/rc.local");
         $rcStaf = 1;
      }
      if ($_ =~ /shellRP.sh/) {
         $vdLogger->Debug("Found shellRP.sh in /etc/rc.local");
         $rcRP = 1;
      }
      last if ($rcStaf && $rcRP); # We aren't going to add anything, just run rc.local
   }
   close (FH_RC_LOCAL);

   # STAFProc wasn't found in rc.local, so we will add it
   unless ($rcStaf) {
      $vdLogger->Debug("Adding STAFProc to rc.local");
      $rcLocal .= "\n# Start STAF \n" .
                  join("\n", ($CMD_MOUNT_STAUTOMATION, CMD_MOUNT_RESTORE,
                              $CMD_UNTAR_STAF, CMD_START_VMVISOR_STAF, ''));
   }

   # shellRP wasn't found in rc.local, so we will add it
   unless ($rcRP) {
      $vdLogger->Debug("Adding shellRP to rc.local");
      my $shellRPScript = "$FindBin::Bin/../scripts/shellRP.sh";
      if (not defined (open (FH_SHELLRP, "< $shellRPScript"))) {
         $vdLogger->Error("Failed to open $shellRPScript");
         return undef;
      }
      while (<FH_SHELLRP>) {
         $rcLocal .= "$_";
      }
      close (FH_SHELLRP);
   }

   unless ($rcStaf && $rcRP) {
      if (not defined (open (FH_RC_LOCAL, "> $localRcLocal"))) {
         $vdLogger->Error("Failed to open $localRcLocal:$@");
         return undef;
      }
      print FH_RC_LOCAL $rcLocal;
      close (FH_RC_LOCAL);
      $sshHost->ScpToCommand($localRcLocal, "/etc/rc.local");
      unlink $localRcLocal;
   }
   # issue command to run /etc/rc.local
   my $cmd = join (";", (CMD_TOUCH_ROOT_PROFILE,
                         CMD_SET_ROOT_PROFILE,
                         CMD_SET_PROFILE,
                         $CMD_MOUNT_STAUTOMATION,
                         CMD_MOUNT_RESTORE,
                         $CMD_UNTAR_STAF,
                         CMD_START_VMVISOR_STAF));
   (undef, $output) = $sshHost->SshCommand($cmd);
   $vdLogger->Debug("STAF installation output " . join ("\n", @$output));
}


########################################################################
#
# VsiNodeWalker --
#      Routine to get all Vsi Nodes under a designated dir.
#
# Input:
#      $host	  : Host to check (required)
#      $dir	  : Vsi node dir on host to be checked, e.g. '/net' (required)
#      $leaf	  : An array reference, the results of this function
#                   will be stored in it (required)
#      $stafObj	  : Used to send VSISH commands to host (Optional)
#
# Results:
#      The modified $leaf is used to contain all VSISH nodes under
#      the designated dir;
#
# Side effects:
#      None
#
########################################################################

sub VsiNodeWalker {
   my $host = shift;
   my $dir = shift;
   my $leaf = shift;
   my $stafObj = shift;
   my $ret;
   my @res;

   # Create a staf helper object if no one is provided,
   # return undef if the creation failed.
   unless(defined $stafObj){
      $stafObj = new VDNetLib::Common::STAFHelper(
         {'logObj' => $vdLogger});
      unless(defined $stafObj){
        $vdLogger->Info("Unable to create stafhelper object.");
	return undef;
      }
   }
   # Delete trailing / character to avoid result such as /net//aaa
   $dir =~ s/\/$//g;
   $ret = $stafObj->STAFSyncProcess($host, "vsish -pe ls $dir");
   if($ret->{rc} != 0) {
      $vdLogger->Error("Failed to execute command vsish -pe ls " .
         "$dir on $host" . Dumper($ret));
      return undef;
   }
   @res = split(/\n/, $ret->{stdout});
   foreach my $e (@res){
      if($e =~ /\/$/){
         VsiNodeWalker($host, "$dir/$e", $leaf, $stafObj);
      }else{
         push (@$leaf, "$dir/$e");
      }
   }
}


######################################################################
#
# GetVMDirectory--
#     Routine get the vm's directory from the absolute vmx path.
#
# Input:
#     vmx: complete vmx path.
#
# Results:
#     On SUCCESS returns the name of the vm directory.
#     On FAILURE returns the FAILURE.
#
# Side effects:
#     None
#
########################################################################

sub GetVMDirectory
{
   my $vmx = shift;
   my $file;
   my $directory;

   if (not defined $vmx) {
      $vdLogger->Error("Name of the vmx file not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($vmx !~ /\/vmfs\/volumes/) {
      $vdLogger->Error("VMFS absolute path (starts with /vmfs/volumes) " .
                        "not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   ($file, $directory) = fileparse($vmx);
   if (defined $directory) {
      return $directory;
   } else {
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}


########################################################################
#
# STAFSubmit--
#      Wrapper for PLSTAF's submit method.
#
# Input:
#      handle : reference to STAF::STAFHandle object (required)
#      host   : host on which request/command to be executed (required)
#      service: name of the service (required)
#      request: request/command to be executed for the given service
#               (required)
#      retry  : 0/1
#
# Results:
#      returns whatever submit() method in PLSTAF returns. Refer to
#      STAF documentation
#
# Side effects:
#      None
#
########################################################################

sub STAFSubmit
{
   my $handle  = shift;
   my $host    = shift;
   my $service = shift;
   my $request = shift;
   my $retry   = shift;
   $retry = (defined $retry) ? $retry : 0;

   if ($host !~ /@/) { # if host has @, assume port is already defined
      if ($host eq "$localIP") {
         # for the local machine (MC) use current staf tcp port
         $host = $host . '@' . $sessionSTAFPort;
      } elsif ($host !~ /local/i) {
         # for any remote machine using default port
         $host = $host . '@' . $STAF_DEFAULT_PORT;
      }
   }

   my $ret = $handle->submit($host, $service, $request);
   # If retry is 0, which is the default case, then enter this
   # block
   if ((!$retry) &&
      ($ret->{rc} == STAF_SDK_SESSION_TIMEOUT_ERROR)) {
      my $hash = {'logObj' => $vdLogger};
      #
      # capture host IP from the request which is the format
      # staf local <service> <command> anchor <ip>:<username>
      #
      $request =~ /anchor (.*):/i;
      my $stafHelper = VDNetLib::Common::STAFHelper->new($hash);
      my $remoteHost = $1;
      $vdLogger->Info("Connection to $remoteHost timed out, reconnecting..");
      if (FAILURE ne GetSTAFAnchor($stafHelper, $remoteHost, $service)) {
        $ret = STAFSubmit($handle, $host, $service, $request, 1);
      }
   }
   if ($ret->{rc} != 0) {
         $vdLogger->Debug(
            "Staf request=$request on $host failed with rc=$ret->{rc}:\n" .
            VDNetLib::Common::Utilities::StackTrace());
   }
   return $ret;
}


########################################################################
#
# IsPortOccupied--
#      Utility to check if the given port is occupied on local machine
#      or not
#
# Input:
#      port : port number (required)
#      protocol: tcp/udp (default udp)
#
# Results:
#
# Side effects:
#
########################################################################

sub IsPortOccupied
{
   my $port = shift;
   my $protocol = shift || "tcp";
   my $netstat = `netstat -anlp 2>/dev/null | grep $port`;

   #
   # Following code takes care of matching the given local port
   # on the localhost.
   #
   if ($netstat =~ /$protocol.*\s+.*\s+.*\s+.*:$port\s.*:/i) {
      return 1;
   } else {
      return 0;
   }
}


########################################################################
#
# StackTrace
#      Utility to print the stack trace of function calls
#
# Input:
#      num : Number of functions upto which the stack trace should be
#            returned(depth)
#
# Results:
#
# Side effects:
#
########################################################################

sub StackTrace
{
   my $num = shift || 7;
   my $stack = "";

   for (my $i = 0; $i <= $num; $i++) {
      my $subroutine = (caller($i))[3];
      if (defined $subroutine) {
         $stack = $stack . $subroutine . "\n";
      }
   }

   return $stack;
}


########################################################################
#
# AddARPEntry --
#     Adds ARP entry to the required host IP being sent by user
#
# Input:
#     Cmd: ARP entry command to run
#
# Results:
#     'SUCCESS', if the command is successful
#     'FAILURE', in case of any error
#
# Side effects:
#     None
#
########################################################################

sub AddARPEntry
{
   my ($testIP, $testMAC, $supportIP) = @_;
   my $cmd;

   if (defined $supportIP) {
      $cmd = "arp -s $testIP $testMAC $supportIP";
   } else {
      $cmd = "arp -s $testIP $testMAC";
   }

   my $result = `$cmd`;
   if ($result ne "") {
      $vdLogger->Error("Unexpected error returned:$result");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetKeyList --
#     Routine to resolve the actual list of values from the given
#     string. This is primarily used to represent key/values in
#     vdnet framework.
#
# Input:
#     string : scalar string value which can be specific value,
#              list of comma separared values or
#              range of values represented as x-y where x is the
#              starting value and y is the ending the value.
#              Here x and y should be integers.
#
# Results:
#     reference to an array which has all possible values resolved
#     from the given string
#     Example, if "1" is given the, return value will be [1]
#              if "1,3" is given then return value will be [1,3]
#              if "1-5" is given, then the return value will be
#              [1,2,3,4,5]
#
# Side effects:
#     None
#
########################################################################

sub GetKeyList
{
   my $string = shift;
   my @keyList;
   if ($string =~ /-/) {
      my ($start, $end) = split(/-/, $string);
      @keyList = ($start .. $end);
   } elsif ($string =~ /,/) {
      @keyList = split(/,/, $string);
   } else {
      push (@keyList, $string);
   }
   return \@keyList;
}


########################################################################
#
# UpdateLauncherHostEntry --
#     Routine to add vdnet launcher's host/machine name to
#     hosts lookup file (also windows equivalent)
#
# Input:
#     remoteIP: remote machine's ip address where hosts lookup file
#               need to be updated (Required)
#     remoteOS: OS type (example: "windows"/"linux") of remote
#               machine (Required)
#     stafHelper: reference to an instance of
#                 VDNetLib::Common::STAFHelper (Required)
#
# Results:
#     "SUCCESS", if the hosts file on remote machine is updated;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub UpdateLauncherHostEntry
{
   my $remoteIP = shift;
   my $remoteOS = shift;
   my $stafHelper = shift;

   my $ipList = GetAllLocalIPAddresses();

   my @remoteIPOctets = split('\.', $remoteIP);
   foreach my $launcherIP (@$ipList) {
      my @launcherIPOctets = split('\.', $launcherIP);
      if ($remoteIPOctets[0] ne $launcherIPOctets[0]) {
         $vdLogger->Debug("Skipping $launcherIP to be updated for host lookup");
         next;
      }
      my $entry = $launcherIP . " " . $launcherIP;
      if (FAILURE eq UpdateDNSLookupTable($entry, $remoteIP,
                               $remoteOS, $stafHelper)) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# UpdateDNSLookupTable--
#     Routine to update hosts lookup file on a given machine
#
# Input:
#     entry   : entry to be added in the hosts file (Required)
#               example: 10.115.174.33 prme-vmkqa-087
#     remoteIP: remote machine's ip address where hosts lookup file
#               need to be updated (Required)
#     remoteOS: OS type (example: "windows"/"linux") of remote
#               machine (Required)
#     stafHelper: reference to an instance of
#                 VDNetLib::Common::STAFHelper (Required)
#
# Results:
#     "SUCCESS", if the hosts file on remote machine is updated;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub UpdateDNSLookupTable
{
   my $entry      = shift;
   my $remoteIP   = shift;
   my $remoteOS   = shift;
   my $stafHelper = shift;

   if (not defined $entry) {
      $vdLogger->Error("Failed to get the host/machine name of $remoteIP");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   my $fileName;
   if ($remoteOS =~ /^win/i) {
      $fileName = "C:\\Windows\\System32\\Drivers\\Etc\\hosts";
   } else {
      $fileName = '/etc/hosts';
   }

   #
   # retrieve the existing contents of hosts file
   #
   my $existingData = $stafHelper->STAFFSReadFile($remoteIP, $fileName);

   if (not defined $existingData) {
      $vdLogger->Error("Failed to read file $fileName from the host $remoteIP");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my ($ip, $host) = split(/\s/, $entry);
   my $command;
   # \s is required to parse the format <ip> <hostname>
   if ($existingData =~ /$ip\s/i) {
      #
      # If an entry with ip address exists, then replace that line
      # And -pi.bak is needed for windows, otherwise error
      # "Can\'t do inplace edit without backup" will be thrown.
      # qoutemeta() escapes non-word character using \
      #
      $command = 'perl -pi.bak -e ' .
                 '"s/^' . quotemeta($ip) . '.*/' . quotemeta($entry) .
                 '/g" ' . $fileName;
   } else {
      # if an entry with given ip address does not exist, then append
      $command = 'echo ' . $entry . ' >> ' . $fileName;
   }

   $vdLogger->Debug("Executing command on $remoteIP: $command");
   my $result  = $stafHelper->STAFSyncProcess($remoteIP, $command);
   if (($result->{rc} != 0) || ($result->{exitCode}))  {
      $vdLogger->Error("Failed to execute $command on $remoteIP");
      $vdLogger->Error("Error:" . Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   #
   # double check if the given entry is placed in hosts file
   #
   my $verifyData = $stafHelper->STAFFSReadFile($remoteIP, $fileName);

   if (not defined $verifyData) {
      $vdLogger->Error("Failed to read file $fileName from the host $remoteIP");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($verifyData !~ $entry) {
      $vdLogger->Error("Given entry $entry not found in $fileName");
      $vdLogger->Debug("Existing value:$verifyData");
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# GetDateTime --
#      Return data nad time in ISO 8601 format.
#
# Input:
#      None.
#
# Results:
#      Timestamp string in ISO 8601 format.
#
# Side effects:
#      None
#
########################################################################

sub GetDateTime
{
   my $dateTime;
   my ($seconds, $microseconds);
   my $tmp;

   $dateTime = [(localtime(time()))[0..5]];
   $dateTime->[4]++;        # Months go from 0-11
   $dateTime->[5] += 1900;  # Years start at 1900
   ($seconds, $microseconds) = gettimeofday;
   $tmp = sprintf ("%04d-%02d-%02d-%02d-%02d-%02d", reverse @$dateTime);
   return "$tmp";
}


########################################################################
#
# GetHostType --
#      This method gives the type of the host whether it is esx or
#      vmkernel or hosted.
#      To find the os type, use GetOS() method in this package.
#
# Input:
#      hostIP: ip address of the host whose type has to be found
#      stafHelper: an object of VDNetLib::Common::STAFHelper package
#		   (optional)
#
# Results:
#      a string (scalar) which can be "esx" or "vmkernel" or "hosted";
#      undef, in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetHostType
{
   my $hostIP = shift;
   my $stafHelper = shift;

   if (not defined $hostIP) {
      return undef;
   }
   if(not defined $stafHelper) {
      my $options;
      $options->{logObj} = $vdLogger;
      $stafHelper = VDNetLib::Common::STAFHelper->new($options);
      if (not defined $stafHelper) {
         $vdLogger->Error("Failed to create STAFHelper object");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   my $os = $stafHelper->GetOS($hostIP);
   if ($os) {
      if ($os =~ /vmkernel/i) {
         return "vmkernel";
      } else {
         #
         # Return hosted for linux, windows and darwin(MAC OS)
         # or even if the os is non-vmkernel
         #
         return "hosted";
      }
   }
   return undef;
}


########################################################################
#
# GetVDNetSourceTree--
#      This method gives the absolute path of the vdnet source tree.
#
# Input:
#     None
#
# Results:
#      on success absolute path of the vdnet source tree,
#      on failure returns the FAILURE;
#
# Side effects:
#      None
#
########################################################################

sub GetVDNETSourceTree
{
   my $cwd;
   my $tree;

   #
   # Get the current working directory based on this script
   # vdNet.pl
   #
   $cwd = abs_path($0);
   $cwd =~ s/vdNet\.pl|generateTDS\.pl//;
   $tree = "$cwd../";

   # remove the double dot so that we get the absolute path.
   $tree =~ s/\/[^\/]*\/\.\.//;
   if (defined $tree) {
      return $tree;
   } else {
      $vdLogger->Error("Failed to get the vdnet source tree");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}


########################################################################
#
# GetFileSystemType--
#      This method returns the datastore storage type
#
# Input:
#      host: ip addr of ESX on which the datastore type needs to be found.
#      datastoreName: Absolute Path
#      stafObj: Staf handler for host ip
#
# Results:
#      a string which can be "NFS" or "VMFS-5" or "vfat"
#       or "vsan";
#      failure, in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetFileSystemType {
   my $host          = shift;
   my $datastoreName = shift;
   my $stafObj       = shift;
   #my $os = getOSType($host);

   # Fuzz Input
   unless ( defined $host || defined $datastoreName || defined $stafObj ) {
      $vdLogger->Error("Invalid Input:datastore $datastoreName ".
                       "or host $host or stafobj is null");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my @arry = split('/', $datastoreName);
   $datastoreName = $arry[3];

   # Create a staf helper object if no one is provided,
   # return undef if the creation failed.

   # Send the command to Host
   my $command = 'esxcli storage filesystem list';
   my $ret = $stafObj->STAFSyncProcess( $host, $command);
   if ($ret->{rc} != 0){
      $vdLogger->Error(
      "Failed to execute command $command on $host".Dumper($ret));
      return undef;
   }
   $vdLogger->Debug("Staf command \"$command\" returns " . Dumper($ret));

   # Create the Hash for variable input
   my $input        = $ret->{stdout};
   my @columns      = split( /\s\s+/, ( split /\n/, $input )[0] );
   my %hashOfCoulms = ();
   my $count        = 0;
   foreach my $key (@columns) {
      $hashOfCoulms{$key} = $count;
      $count++;
   }
   # Check for filesystem type if volumne name is given
   my $indexVN   = $hashOfCoulms{"Volume Name"};
   my $indexType = $hashOfCoulms{"Type"};
   $count = 0;
   foreach my $line ( split /\n/, $input ) {
      if ( $count > 1 ) {
         my @eachRow = split( /\s\s+/, $line );
         if ( $eachRow[$indexVN] eq $datastoreName ) {
            return $eachRow[$indexType];
         }
      }
      $count++;
   }
   $vdLogger->Error("Failed to get the type for datastore $datastoreName");
   VDSetLastError("EFAIL");
   return FAILURE;
}

########################################################################
#
# CreateDirectory--
#      This method executes mkdir command based upon the type of datasore.
#      VSAN does not support mkdir at the root directory.
#      e.g. mkdir /vmfs/volumes/vsanDatastore does not work. use
#      osfs-mkdir. However, when we use osfs-mkdir to create dir SUT
#      in vdtest /vmfs/volumes/vsanDatastore/vdtest/SUT, it creates SUT on
#      vsanDatastore instead inside vdtest. Thus for that we have to
#      use mkdir /vmfs/volumes/vsanDatastore/vdtest/SUT.
#
# Input:
#      host: ip address of the ESX on which the datastore
#             stype needs to be found.
#      dir: directory/path where the vm will be stored
#      filesystemtype: ssan/NFS (optional)
#      stafObj: Staf handler for host ip (optional)
#
# Results:
#      a string which can be "mkdir" or "osfs-mkdir"
#      undef, in case of any error.
#
# Side effects:
#      not checking if the directory already exists
#      or not under vsanDatastore through osfs-ls
#
########################################################################

sub CreateDirectory
{
   my $host            = shift;
   my $dir             = shift;
   my $filesystemtype  = shift;
   my $stafObj         = shift;

   # Fuzz Input
   unless ( (defined $host) && (defined $dir)) {
   $vdLogger->Error(
       "Invalid Input:Either directory $dir or host $host is null");
       VDSetLastError("EFAIL");
       return FAILURE;
   }

   # Create a staf helper object if no one is provided,
   # return undef if the creation failed.
   $stafObj =
      new VDNetLib::Common::STAFHelper( { 'logObj' => $vdLogger } );
      unless ( defined $stafObj ) {
         $vdLogger->Info("Unable to create stafhelper object.");
         return undef;
      }

   #Initialize common variables used in if/else block
   my $command='';
   my $data='';
   my $ret='';

   #Check if the type is vsan or not
   if ($filesystemtype eq 'vsan') {
      # Check if path contains the directory after vmfs/volumes/vsanDatasore
      # If yes, check for next directory, if no, create SUT/helper

      my @arry = split('/', $dir);

      #capture vdtest1159 from vmfs/volumes/vsanDatastore/vdtest1159/SUT
      my $subdirvsan = $arry[4];
      #capture SUT from /vmfs/volumes/vsanDatastore/vdtest1159/SUT
      my $subdirmachine = $arry[5];
      pop @arry;
      my $vsandir=join('/',@arry);
      my $ret = '';
      if (defined $subdirvsan){
         if (defined $subdirmachine){
            $command = "/usr/lib/vmware/osfs/bin/osfs-mkdir $vsandir;mkdir $dir";
         } else {
            $command = "/usr/lib/vmware/osfs/bin/osfs-mkdir $vsandir";
         }
         $ret=$stafObj->STAFSyncProcess($host,$command);
      } else {
         $vdLogger->Error("Insufficient info: vdtest folder not provided".
                           Dumper($ret));
         return FAILURE;
      }
      if ($ret->{exitCode} != 0 || $ret->{rc} != 0){
         $vdLogger->Error("Failed to execute command  on $host".
                           Dumper($ret));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   } else {
      $command = "CREATE DIRECTORY "."$dir".
                 " FULLPATH";
      ($ret, $data) = $stafObj->runStafCmd($host,'FS',$command);
      if ($data) {
         $vdLogger->Error("Staf error while creating directory $dir " .
                          "on $host:$data");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   return 'SUCCESS';
}

########################################################################
#
# RemoveOldDirectories--
#      This method removes old directories inside a given path
#      Command 1 is used to just print dir which have not been accessed
#      in $time days. Once we get the list of dir, we use Command 2 to
#      scan individual directories for files which have not been accessed
#      in $time days,
#         Command 1: find <$dir>/* -maxdepth 0 -type d -mtime + $time
#            $dir*: All files under the folder $dir
#            maxdepth 0: means apply these to command line arguments
#            type d: Used for depth and compatlibity with other OS
#            mtime: Files was last accesed. Comaptible with ESX
#         Command 2:find <$dir>/vdtest-* -maxdepth 0 -type d -mtime - $time
# Input:
#      dir: Absolute Path
#      time: Time since the files were last accessed. Based on this fact
#            deletion happens. For e.g. if time is set to 3, all the
#            files/directories under the given $dir that were not accessed
#            in last 3 days will be considered old and will be removed from
#            the system.(optional)
#
# Results:
#      SUCSESS nothing is returned
#      FAILURE is returned if the find/delete command fails
#
# Side effects:
#    Since this method is called by cleanup.pl, we cannot use $vdLogger
#    Hence no logging is present.
########################################################################

sub RemoveOldDirectories
{
   my $dir      = shift;
   my $time     = shift || "3";
   my $originalDirPath = $dir;
   $dir =~ s/ /\\ /;
   $dir =~ s/\(/\\(/;
   $dir =~ s/\)/\\)/;
   if ((not defined $dir) || ($dir !~ /\/vmfs\/volumes/)) {
      $vdLogger->Error("Attempting to remove something under root system");
      VDGetLastError("ENOTDEF");
      return FAILURE;
   }
   my $command = 'find ' . $dir . ' -maxdepth 0 -type d -mtime +' . $time;
   my $output = `$command`;
   unless (not defined $output) {
      my @arryin = ();
      my $count = 0;
      foreach my $line (split /\n/, $output) {
         $arryin[$count] = $line . '/';
         $count++;
      }
      my $arrylen = $count;
      my $deletedDirectoriesPointer;
      $originalDirPath =~ s/vdtest\*//;
      my $logFileName = $originalDirPath . '/' . "cleanup.txt";
      if (!open ($deletedDirectoriesPointer, "+>>$logFileName")) {
         die "Could not open $logFileName: $!";
      }
      my $datetime = scalar(localtime(time));
      print $deletedDirectoriesPointer "Execution Time: $datetime\n";
      for ($count = 0; $count < $arrylen; $count++) {
         my $output;
         $arryin[$count] =~ s/ /\\ /;
         $arryin[$count] =~ s/\(/\\(/;
         $arryin[$count] =~ s/\)/\\)/;
         my $command = 'find ' . $arryin[$count] . '*' . ' -mtime -' . $time;
         $output = `$command`;
         if ($output eq '') {
            $command = 'rm -rf ' . $arryin[$count];
            if (($command !~ /vmfs/) || ($command !~ /volumes/)) {
               $vdLogger->Error("Can only delete directories in /vmfs/volumes");
               VDGetLastError("ENOTDEF");
               return FAILURE;
            }
            print $deletedDirectoriesPointer "Delete: $command\n";
            $output = `$command`;
         }
      }
      close ($deletedDirectoriesPointer);
   }
}


###############################################################################
#
# GetTupleInfo -
#       This module takes the 4 values, tuple as the input in the
#       following format:
#        <inventory>.[<index/range>].<component>.[<index/range>]
#
#       And returns 4 values separately in the following format:
#       - <inventory>
#       - Reference to array, consisting index/range-of-index
#       - <component>
#       - Reference to array, consisting index/range-of-index
#
# Input:
#       $str - 4 values tuple, in the following format:
#               <inventory>.[<index/range>].<component>.[<index/range>]
#
# Results:
#       Returns 4 values in the format given above, in case of SUCCESS.
#       FAILURE, in case of failure.
#
# Side effects:
#       None
#
###############################################################################

sub GetTupleInfo
{
   my $str   = shift;
   my @value = undef;

   @value = split(/\./, $str);

   my $inventory = $value[0];
   my $index1    = $value[1];
   my $component = $value[2];
   #
   # This would replace the hyphen separator for the given range by ..
   # The below given substitution takes care of -ve numbers in the range
   # e.g. [1-5] will get changed to [1..5]
   # e.g. [-1-5] will get changed to [-1..5]
   #
   $index1 =~  s/(^\[\-?\d+)(\-)(.+\]$)/$1..$3/g;

   $index1 = eval $index1;
   if (not defined $component) {
      return ($inventory, $index1);
   } else {
      my $index2    = $value[3];
      $index2 =~  s/(^\[\-?\d+)(\-)(.+\]$)/$1..$3/g;
      $index2 = eval $index2;
      return ($inventory, $index1, $component, $index2);
   }
}


###############################################################################
#
# GenerateName -
#       Generates a unique name which will be created for the current session
#       of the test run.
#
# Input:
#       string - String to represent the type of name user want (mandatory)
#       index  - A digit/number to be used while creating the name (mandatory)
#		 This digit would make the name unique in the given context
#
# Results:
#       switch Name - on SUCCESS
#
# Side effects:
#       None
#
###############################################################################

sub GenerateName
{
   # Please note that this function is being used by VM deployment and any
   # change would affect re-using VMs
   my $string = shift;
   my $index  = shift;
   my $name = $index . "-" . $string .  "-" . getpgrp($$) % 2000;
   return $name;
}


###############################################################################
#
# GenerateNameWithRandomId  -
#       Generates a unique name with a ramdom Id
#
# Input:
#       string - String to represent the type of name user want (mandatory)
#       index  - A digit/number to be used while creating the name (mandatory)
#		 This digit would make the name unique in the given context
#
# Results:
#       switch Name - on SUCCESS
#
# Side effects:
#       None
#
###############################################################################

sub GenerateNameWithRandomId
{
   my $string = shift;
   my $index  = shift;
   my $name = $index . "-" . $string .  "-" . int(rand(getpgrp($$) % 2000));
   return $name;
}


###############################################################################
#
# ProcessMultipleTuples -
#       This module takes tuples separated by ";;" inside a group as input and
#       returns a reference to an array.
#
#       We have to use ";;" if the user wants to send multiple tuples without
#       the Iterator splitting the input.
#
#       For key 'deletehostsfromdc', if the user wants to send one group
#       having multiple tuples, then he can send it like this "group1" where
#       group1 = host.[1];;host.[2] (refer Case1):
#           Case1:
#           deletehostsfromdc => "host.[1];;host.[2]"
#
#       If the user wants to send multiple groups having multiple tuples,
#       then he can send it like this "group1,group2" where
#       group1 = host.[1];;host.[2] and
#       group2 = host.[3](refer Case2):
#           Case2:
#           deletehostsfromdc => "host.[1];;host.[2],host.[3]"
#
#       Following are two standard type of inputs to this api:
#       Case1: "host.[1];;host.[2]"
#       Case2: "host.[1];;host.[2] , host.[3]"
#
# Input:
#       $inputString - Tuples separated by ;; or ,
#
# Results:
#       SUCCESS - Return values for case1 and case2 are as follows:
#                 Case1: ArrayRef of ["host.[1]","host.[2]"]
#                 Case2: ArrayRef of [["host.[1]","host.[2]"],
#                                            ["host.[3]"]]
#       FAILURE - Incase ";;" delimiter was not found
#
# Side effects:
#       None
#
###############################################################################

sub ProcessMultipleTuples
{
   my $inputString = shift;
   my @arrayReturned;

   if ((not defined $inputString)) {
      $vdLogger->Error("Either input is not defined" . $inputString);
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   @arrayReturned = split (';;', $inputString);
   my @newArray = ();
   foreach my $adapter (@arrayReturned) {
      my $refArray = VDNetLib::Common::Utilities::ProcessTuple($adapter);
      push @newArray, @$refArray;
   }
   @arrayReturned = ();
   push @arrayReturned, @newArray;
   return \@arrayReturned;

}


########################################################################
#
#   FindHashValues --
#       Method to return the values in a hash that matches the pattern
#       provided.
#
#   Input:
#       patterns: Array reference that contains the patterns to match
#           against.
#       hashRef: Reference to a hash where we need to find the values
#           in.
#
########################################################################

sub FindHashValues {
    my $patterns = shift;
    my $hashRef = shift;
    my $foundValues = [];
    if (not defined $patterns or ref($patterns) ne 'ARRAY') {
        $vdLogger->Error("Expected patterns to be an array ref, got:\n" .
                         Dumper($patterns));
        VDSetLastError("EFAIL");
        return FAILURE;
    }
    if (not defined $hashRef or ref($hashRef) ne 'HASH') {
        $vdLogger->Error("Expected hashRef to be a hash ref, got:\n" .
                         Dumper($hashRef));
        VDSetLastError("EFAIL");
        return FAILURE;
    }
    foreach my $key (keys %$hashRef) {
        if (ref($hashRef->{$key}) eq 'HASH') {
            my $retValues = FindHashValues($patterns, $hashRef->{$key});
            foreach my $retValue (@$retValues) {
                if (defined $retValue and FAILURE eq $retValue) {
                    VDSetLastError("EFAIL");
                    return FAILURE;
                }
            }
            push @$foundValues, @$retValues;
        } elsif (ref($hashRef->{$key}) eq 'ARRAY') {
            my $retValues;
            foreach my $arrayElement (@{$hashRef->{$key}}) {
                if (ref($arrayElement) eq 'HASH') {
                    $retValues = FindHashValues($patterns, $arrayElement);
                    foreach my $retValue (@$retValues) {
                        if (defined $retValue and FAILURE eq $retValue) {
                            VDSetLastError("EFAIL");
                            return FAILURE;
                        }
                    }
                } else {
                    # Load the whole ARRAY if values in the ARRAY are not HASH
                    foreach my $pattern (@$patterns) {
                        if ($hashRef->{$key} =~ m/$pattern/) {
                            push @$foundValues, [$key, $hashRef->{$key}];
                        }
                    }
                    last;
                }
                push @$foundValues, @$retValues;
            }
        } else {
            foreach my $pattern (@$patterns) {
                if ($hashRef->{$key} =~ m/$pattern/) {
                    push @$foundValues, [$key, $hashRef->{$key}];
                }
            }
        }
    }
    return $foundValues;
}


########################################################################
#
#   ReplaceInStruct --
#       Method to replace the values in a hash that matches the keys of
#       the valueToReplace hash.
#
#   Input:
#       valueToReplace: Hash reference that contains the keys that will
#           be used as a replacement of the other hash.
#       struct: Reference to a hash or array where we need to find the
#           values in.
#
########################################################################

sub ReplaceInStruct{
    my $valuesToReplace = shift;
    my $struct = shift;
    if (not defined $valuesToReplace or ref($valuesToReplace) ne 'HASH') {
        $vdLogger->Error("Expected valuesToReplace to be a hash ref, got:\n" .
                         Dumper($valuesToReplace));
        VDSetLastError("EFAIL");
        return FAILURE;
    }
    if (not defined $struct or (ref($struct) ne 'HASH' and ref($struct) ne 'ARRAY')) {
        $vdLogger->Error("Expected struct to be a hash or array ref, got:\n" .
                         Dumper($valuesToReplace));
        VDSetLastError("EFAIL");
        return FAILURE;
    }

    if (defined ref($struct) and 'HASH' eq ref($struct)) {
        foreach my $key (keys %$struct) {
            if (ref($struct->{$key}) eq 'HASH' or ref($struct->{$key}) eq 'ARRAY') {
                my $ret = ReplaceInStruct($valuesToReplace, $struct->{$key});
                if (defined $ret and FAILURE eq $ret) {
                    return FAILURE;
                }
                $struct->{$key} = $ret;
            } else {
                foreach my $valueToReplace (keys %$valuesToReplace) {
                    if ($struct->{$key} eq $valueToReplace) {
                        $struct->{$key} = $valuesToReplace->{$valueToReplace};
                        last;
                    }
                }
            }
        }
    } elsif (defined ref($struct) and 'ARRAY' eq ref($struct)) {
        my @replacedArray;
        foreach my $arrayElement (@{$struct}) {
            if (ref($arrayElement) eq 'HASH' or ref($arrayElement) eq 'ARRAY') {
                my $ret;
                $ret = ReplaceInStruct($valuesToReplace, $arrayElement);
                if (defined $ret and FAILURE eq $ret) {
                    VDSetLastError("EFAIL");
                    return FAILURE;
                }
                push @replacedArray, $ret;
            } else {
                my $replaced = 0;
                foreach my $valueToReplace (keys %$valuesToReplace) {
                    if ($arrayElement eq $valueToReplace) {
                        push @replacedArray, $valuesToReplace->{$valueToReplace};
                        $replaced = 1;
                        last;
                    }
                }
                if (!$replaced) {
                    push @replacedArray, $arrayElement;
                }
            }
        }
        $struct = \@replacedArray;
    }
    return $struct;
}


########################################################################
#
# ConvertJSONToHash --
#     Routine to convert given JSON file in into perl hash
#
# Input:
#     jsonFile: file name that has JSON objects
#
# Results:
#     perl hash if converted successfully;
#     undef in case of any error;
#
# Side effects:
#
########################################################################

sub ConvertJSONToHash
{
   my $jsonfile = shift;
   my $result = open FILE, $jsonfile;
   if (not defined $result) {
      $vdLogger->Error("Could not open file $jsonfile: $!");
      return undef;
   }
   sysread(FILE, $result, -s FILE);
   my $decoded_json = VDNetLib::Common::Utilities::ConvertJSONDataToHash(
       $result);
   close FILE;
   return $decoded_json;
}


########################################################################
#
# ConvertJSONDataToHash --
#     Routine to convert given data to perl hash
#
# Input:
#     jsonData: Data as a string in json format.
#
# Results:
#     perl hash if converted successfully;
#     undef in case of any error;
#
# Side effects:
#
########################################################################

sub ConvertJSONDataToHash
{
   my $jsonData = shift;
   if (not defined $jsonData) {
      $vdLogger->Error("JSON data is not defined");
      return undef;
   }
   return JSON->new->utf8->decode($jsonData);
}


########################################################################
#
# ConvertHashDataToJSON --
#     Routine to convert given hash data to json
#
# Input:
#     hashData: Data as a string in hash format.
#
# Results:
#     json if converted successfully;
#     undef in case of any error;
#
# Side effects:
#
########################################################################

sub ConvertHashDataToJSON
{
   my $hashData = shift;
   if (not defined $hashData) {
      $vdLogger->Error("Hash data is not defined");
      return undef;
   }
   return JSON->new->utf8->encode($hashData);
}

########################################################################
#
# ConvertYAMLToHash --
#     Routine to convert given YAML file to perl hash
#
# Input:
#     yamlFile: file that has YAML objects
#
# Results:
#     perl hash if converted successfully;
#     undef in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConvertYAMLToHash
{
   my $yamlFile = shift;
   my $yamlData;
   eval {
      # Making it load here as remoteAgent uses Utilities
      # which does not have toolchain to load this module from toolchain
      my $module = "YAML::XS";
      eval "require $module";
      import $module qw{ Dump Load LoadFile};
      $yamlData = LoadFile($yamlFile);
   };
   if ($@) {
      $vdLogger->Error("Failed to open YAML file $yamlFile: $@");
      return undef;
   };
   return $yamlData;
}


########################################################################
#
# ProcessTuple --
#     A wraper on top of GetTupleInfo. Returns a reference to array
#     consisting of all tuples in expanded form.
#
# Input:
#     $inputTuple: a tuple in format host.[1-2].vmknic.[1-2]
#
# Results:
#     SUCCESS - returns a reference to array consisting:
#                    ["host.[1].vmknic.[1]",
#                     "host.[1].vmknic.[2]",
#                     "host.[2].vmknic.[1]",
#                     "host.[2].vmknic.[2]",
#     FAILURE - in case of any failure
#
# Side effects:
#     None
#
########################################################################

sub ProcessTuple
{
   my $inputTuple = shift;
   my @returnArray;

   if ((not defined $inputTuple)) {
      $vdLogger->Error("Input is not defined" . $inputTuple);
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $inputTuple =~ s/\[-1\]/\[all\]/g;
   my @arr = VDNetLib::Common::Utilities::HelperProcessTuple(split /\[(.*?)\]/,
                                                             $inputTuple, -1);
   foreach my $element (@arr) {
      if ($element =~ /=/) {  # Don't process the custom formulas.
         $vdLogger->Trace("Not processing the custom formula: $element");
         push @returnArray, $element;
         next;
      }
      $element =~ s/(\d+)/[$1]/g;
      $element =~ s/all/\[-1\]/g;
      # matching .x specifically, otherwise any string that matches 'x' will be
      # through this block. example: vxlancontroller
      if ($element =~ m/\.x/i) {
         my @tempArr = split('\.', $element);
         $element = "$tempArr[0].$tempArr[1]";
      }
      push @returnArray, $element;
   }

   return \@returnArray;
}


########################################################################
#
# HelperProcessTuple --
#     This api is used by ProcessTuple to expand ranges and N-tuples.
#     The code uses recursion and map library for expansion.
#
# Input:
#     $inputTuple: A tuple as an array e.g (host., 1-2, vmknic., 1-2)
#
# Results:
#     SUCCESS - returns a reference to array consisting:
#                    ["host.1.vmknic.1",
#                     "host.1.vmknic.2",
#                     "host.2.vmknic.1",
#                     "host.2.vmknic.2"]
#
# Side effects:
#     None
#
########################################################################

sub HelperProcessTuple
{
   return @_ if @_ == 1;
   my ($pre,$pat,$post)=splice @_, 0, 3;
   my $indices = ExpandIndices($pat);
   if ($indices eq FAILURE) {
      $vdLogger->Error("Failed to expand: $pre.$pat,$post");
      return FAILURE;
   }
   map {HelperProcessTuple($pre . $_ . $post, @_)} @$indices;
}

########################################################################
#
# ExpandIndices --
#     Expands the comma separated values and ranges into individual
#     indices.
# Input:
#     $inputIndices: String which has comma separated values or ranges.
#     $expandCustomForumlas: Determines whether the CSV's that are part
#        of custom VDNet formulas needs to be expanded or not. By
#        default this is set to false i.e. the custom formulas will be
#        returned as-is.
#
# Results:
#     Returns a reference to array containing each individual index.
#     Returns FAILURE if something goes wrong.
#
# Side effects:
#     None
#
########################################################################

sub ExpandIndices
{
   my  $inputIndices = shift;
   my $expandCustomForumlas = shift || 0;
   if (not defined $inputIndices or $inputIndices eq '') {
       $vdLogger->Error("Input index is not defined");
       return FAILURE;
   }
   if ($inputIndices =~ /=/ && not $expandCustomForumlas){
       # Return the index as is.
       my @ret = ($inputIndices);
       return \@ret;
   }
   $inputIndices =~ s/\s+//g;  # Remove spaces.
   my @allIndices = split(/,/, $inputIndices);
   my @expandedIndices = ();
   foreach my $index (@allIndices) {
      if ($index =~ /(\d+)\-(\d+)/) {
         push(@expandedIndices, $1 .. $2);
         next;
      }
      push(@expandedIndices, $index);
   }
   my %uniqueHash = map {$_ => 1} @expandedIndices;
   my @expandedUniqueIndices = keys(%uniqueHash);
   return \@expandedUniqueIndices;
}


#######################################################################
#
# GetAllTCPIPInstances --
#     Routine to get all the tcpip instances.
#
# Input:
#     IP: IP address of the esx host.
#     stafHelper: Staf helper obj
#
# Results:
#     array of tcpip stack instances on success,
#     on failure returns FAILURE.
#
# Side effects:
#     None
#
########################################################################

sub GetAllTCPIPInstances
{
   my $esxIP = shift;
   my $stafHelper = shift;
   my $result;
   my $command;
   my @instances;

   if ((not defined $esxIP) || (not defined $stafHelper)) {
      $vdLogger->Error("IP of host or staf helper not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $command = "vsish -e ls /net/tcpip/instances/";
   $result = $stafHelper->STAFSyncProcess($esxIP,
                                          $command);

   # check for success or failure of the command executed using staf
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to get tcpip instances" . Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if (defined $result->{stdout}) {
      @instances = split(/\n/, $result->{stdout});
   } else {
      $vdLogger->Error("Failed to get the tcpip instance list");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return \@instances;
}


#######################################################################
# CheckAllStackInstances --
#     Routine to check if a ip is availabe in each instance.
#
# Input:
#     Control IP: IP address of the esx host.
#     ip: ip address.
#     Staf helper : Staf helper obj.
#
# Results:
#     0 if ip adddress is not available,
#     1 if ip address is available,
#     FAILURE if there are other errors.
#
# Side effects:
#     None
#
########################################################################

sub CheckAllStackInstances
{
   my $esxIP = shift;
   my $testIP = shift;
   my $stafHelper = shift;
   my $command;
   my $result;

   if ((not defined $esxIP) || (not defined $testIP) ||
       (not defined $stafHelper)) {
      $vdLogger->Error("One or more paramter control ip,test ip or ".
                       "stafHelper is missing");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # get the list of netstack instances.
   $result = VDNetLib::Common::Utilities::GetAllTCPIPInstances($esxIP,
                                                               $stafHelper);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get list of netstack instances");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # run ping in all instances.
   foreach my $instance (@{$result}) {
      $instance =~ s/\///;
      $command = "ping ++netstack=$instance -c 1 $testIP";
      $result = $stafHelper->STAFSyncProcess($esxIP,
                                             $command);
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to execute command on $esxIP");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      if ($result->{exitCode} != 0 || $result->{stdout} =~ /unreachable/i) {
         next;
      } else {
         return 0;
      }
   }
   return 1;
}


########################################################################
#
# GetFreePort --
#     Routine to get a free port on the local host
#
# Input:
#     startingPort: starting port number (Required)
#     endingPort  : ending port number (Required)
#
# Results:
#     Free port available between given startingPort and endingPort;
#     FAILURE, if no port is found
#
# Side effects:
#
########################################################################

sub GetFreePort
{
   my $startingPort = shift;
   my $endingPort   = shift;
   my $port  = $startingPort;
   while ($port <= $endingPort) {
      if (!VDNetLib::Common::Utilities::IsPortOccupied($port)) {
         return $port;
      }
      $vdLogger->Debug("TCP port $port occupied");
      $port++;
   }

   $vdLogger->Error("No port available in the given range " .
                    "from $startingPort to $endingPort");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


########################################################################
#
# ExpandTuplesInSpec --
#     Method to expand the tuple represented [] format.
#     This will create separate hashes within the range specified in []
#     and point their values to the original
#
# Input:
#     spec: reference to spec which has keys/indexes in [] format (required)
#
# Results:
#     Reference to hash which is expanded version given spec
#
# Side effects:
#     None
#
########################################################################

sub ExpandTuplesInSpec
{
   my $componentSpec = shift;
   my $returnHash = {};
   foreach my $identifier (keys %$componentSpec) {
      my ($initial, $final, $total) = ResolveArrayReference($identifier);
      for (my $index = $initial; $index <= $final; $index++) {
         #
         # We create a newHash in case of 1-1 mapping subcomponent.[x]
         # For multiple specs refering to same component we can reference
         # the same hash
         #
         my $createNewHash = 0;
         my $newHash       = undef;
         my $currentHash   = $componentSpec->{$identifier};
         for my $hashKey (keys %$currentHash) {
            my $hashValue = $currentHash->{$hashKey};
               my $modified;
               ($newHash->{$hashKey}, $modified) = ResolveIndexValues($index,
                                                                     $hashValue);
               if ($newHash->{$hashKey} eq FAILURE) {
                  $vdLogger->Error("Failed to resolve index value $hashValue");
                  VDSetLastError(VDGetLastError());
                  return FAILURE;
               }
               $createNewHash = 1 if ($modified);
         }
         if ((defined $newHash) && ($createNewHash == 1)) {
            $returnHash->{$index} = $newHash;
         } else {
            $returnHash->{$index} = $componentSpec->{$identifier};
         }
      }
   }
   return $returnHash;
}


########################################################################
#
# ExpandTuplesInSpecRecursive --
#     Method to expand the tuple represented [] format.
#     This will create separate hashes within the range specified in []
#     and point their values to the original
#
# Input:
#     spec: reference to spec which has keys/indexes in [] format (required)
#     specDepth: the depth for current spec (required), like vm.1.vnic.1
#       When firstly enter this function, it is like 'vm' which means
#       we begin to parse vm spec recursively
#
# Results:
#     Reference to hash which is expanded version given spec
#
# Side effects:
#     None
#
########################################################################

sub ExpandTuplesInSpecRecursive
{
   my $componentSpec = shift;
   my $specDepth = shift;

   $vdLogger->Debug("Spec of $specDepth :".Dumper($componentSpec));
   my $returnHash = {};
   foreach my $identifier (keys %$componentSpec) {
      my ($initial, $final, $total) = ResolveArrayReference($identifier);
      my $index = $initial;
      while ((not defined $index) || ($index <= $final)) {
         #
         # For multiple specs refering to same component we can reference
         # the same hash, for example,
         #   'vnic' => {
         #          '[1-3]' => {
         #           'portgroup' => 'vc.[1].dvportgroup.[1]',
         #           'driver' => 'vmxnet3'
         #         },
         #       },
         # Then vnic.1.portgroup and vnic.2.portgroup can refer to same hash
         # that vc.[1].dvportgroup.[1] defines
         # But in following situations we need create a newHash for each vnic
         # as the value of portgroup for each vnic is different
         #   'vnic' => {
         #          '[1-3]' => {
         #           'portgroup' => 'vc.[1].dvportgroup.[x=vm_index+vnic_index]',
         #           'driver' => 'vmxnet3'
         #         },
         #       },
         #
         if (not defined $index) {
            $index = $identifier;
         }
         my $createNewHash = 0;
         my $newHash       = undef;
         my $currentHash   = $componentSpec->{$identifier};
         if (not defined $currentHash) {
            $returnHash->{$index} = $currentHash;
            if (not defined $final) {
               last;
            }
            $index = $index + 1;
            next;
         }
         if (ref($currentHash) ne "HASH") {
            #This is to deal with following spec
            # controller:
            #    [1-3] : "abcmanager.[x]"
            my $modified;
            my $newDepth = $specDepth . "." . $index;
            ($newHash, $modified) = ResolveIndexValuesWithPath($index,
                                                   $currentHash, $newDepth);
            if (IsFailure($newHash)) {
               $vdLogger->Error("Failed to resolve index value $currentHash");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
            $createNewHash = 1 if ($modified);
            if ((defined $newHash) && ($createNewHash == 1)) {
               $returnHash->{$index} = $newHash;
            } else {
               $returnHash->{$index} = $currentHash;
            }
            if (not defined $final) {
               last;
            }
            $index = $index + 1;
            next;
         }
         for my $hashKey (keys %$currentHash) {
            my $hashValue = $currentHash->{$hashKey};
            my ($start, $end, $totalKeys) = ResolveArrayReference($hashKey);
            my $firstKey = $start;
            while ((not defined $firstKey) || ($firstKey <= $end)) {
               if (not defined $firstKey) {
                  $firstKey = $hashKey;
               }
               my $modified;
               my $newDepth = $specDepth . "." . $index . "." . $firstKey;
               if (ref($hashValue) ne "HASH") {
                  ($newHash->{$firstKey}, $modified) = ResolveIndexValuesWithPath($index,
                                                   $hashValue, $newDepth);
                  if (IsFailure($newHash->{$firstKey})) {
                     $vdLogger->Error("Failed to resolve index value $hashValue");
                     VDSetLastError(VDGetLastError());
                     return FAILURE;
                  }
                  $createNewHash = 1 if ($modified);
               } else {
                  $newHash->{$firstKey} = ExpandTuplesInSpecRecursive($hashValue,
                                                                      $newDepth);
                  $createNewHash = 1;
               }
               if (not defined $end) {
                  last;
               }
               $firstKey = $firstKey + 1;
               next;
            }
         }
         if ((defined $newHash) && ($createNewHash == 1)) {
            $returnHash->{$index} = $newHash;
         } else {
            $returnHash->{$index} =  dclone ($currentHash);
         }
         #if it is not a range, or not a number, need break for loop
         if (not defined $final) {
            last;
         }
         $index = $index + 1;
      } # end of while index loop
   }
   return $returnHash;
}


########################################################################
#
# ExpandTupleValueRecursive --
#     Method to expand current spec, which can be hash, array, scalar
#     ExpandTuplesInSpecRecursive() is for testbed spec parsing, which has
#     hash structure, there is requirement to parse tuple value in workload
#     which may be hash in array. So we add this function. After this function
#     is well tested, we can replace ExpandTuplesInSpecRecursive with it.
#
# Input:
#     currentSpec: reference to spec which we need parse (required)
#                  or just a scalar
#     specDepth: the depth for current spec (required), like vm.1.vnic.1
#       When firstly enter this function, it is like 'vm' which means
#       we begin to parse vm spec recursively
#
# Results:
#     Reference to hash or array, or return scalar which is expanded
#     version for given $currentSpec. When $currentSpec is undef, return undef
#     return FAILURE is any error
#
#
# Side effects:
#     None
#
########################################################################

sub ExpandTupleValueRecursive
{
   my $currentSpec = shift;
   my $specDepth = shift;

   $vdLogger->Debug("Spec of $specDepth :".Dumper($currentSpec));

   # Logic:
   # 1) If undef, return undef
   # 2) If string, return parsed string
   # 3) If array, visit each array element and parse their values.
   # 4) If hash, check its key.. If key is string, just go on to parse each key, and return new hash
   #    if key is number or range of number, expand them and then return new hash.
   # 5) If none of all above, just return it as is

   # $modified is a flag, we use it to indicate after parsing the spec is changed
   # or not.
   my $modified = 0;
   my $index;
   my $newValue;

   if (not defined $currentSpec) {
      $vdLogger->Debug("Spec is undef for $specDepth");
      return undef;
   }
   # If not a reference, then it is scalar
   if (ref($currentSpec) eq '') {
      if ($specDepth =~ /.*\.\[?(\d+)\]?/) {
         $index = $1;
      } else {
         my @specArray = split(/\./, $specDepth);
         if (@specArray >= 2) {
            $index = $specArray[-2];
         } else {
            $index = $specArray[-1];
         }
      }
      ($newValue, $modified) = ResolveIndexValuesWithPath($index,$currentSpec, $specDepth);
      if (IsFailure($newValue)) {
         $vdLogger->Error("Failed to resolve spec $currentSpec with index $index " .
                          "and spec depth $specDepth");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      return $newValue;
   }
   if (ref($currentSpec) eq 'ARRAY') {
      my $arrayNumber = @$currentSpec;
      for (my $i=0; $i<$arrayNumber; $i++){
         # If there is need to expand tuple value based on array index, we need set
         # $specDepth to have [$i] appended.
         $newValue = ExpandTupleValueRecursive($currentSpec->[$i], $specDepth);
         if (IsFailure($newValue)) {
            $vdLogger->Error("Failed to resolve spec " . Dumper($currentSpec->[$i]));
            $vdLogger->Debug("Spec depth is $specDepth");
            VDSetLastError("EFAILED");
            return FAILURE;
         }
         # If undef returned, we think it is unusual and log a message, but we not fail
         # here as in some situations, tuple value maybe undef like for verification
         # workload.
         if (not defined $newValue) {
            $vdLogger->Debug("Expanded value is undef with spec depth as $specDepth " .
                             "for spec: " . Dumper($currentSpec->[$i]));
         }
         $currentSpec->[$i] = $newValue;
      }
      return $currentSpec;
   }
   if (ref($currentSpec) ne "HASH") {
       $vdLogger->Debug("It is object of " . ref($currentSpec) . " for spec: " .
                        Dumper($currentSpec));
       return $currentSpec;
   }

   # Following code are for HASH
   my $newHash = {};
   my $newDepth;
   foreach my $hashKey (keys %$currentSpec) {
      # If key is in array format, like '[2,3]'
      if (($hashKey !~ /\[\?\]/) && ($hashKey =~ /\[(.*)\]/)) {
         my $keyArray = ResolveRangeInArray($1);
         foreach my $value (@$keyArray) {
            $newDepth = $specDepth . "." . $value;
            $newValue = ExpandTupleValueRecursive($currentSpec->{$hashKey}, $newDepth);
            if (IsFailure($newValue)) {
               $vdLogger->Error("Failed to resolve spec " . Dumper($currentSpec->{$hashKey}));
               $vdLogger->Debug("Spec depth is $newDepth");
               VDSetLastError("EFAILED");
               return FAILURE;
            }
            if (not defined $newValue) {
               $vdLogger->Debug("Expanded value is undef with spec depth as " .
                                "$newDepth for spec: " .
                                Dumper($currentSpec->{$hashKey}));
            }
            $newHash->{$value} = $newValue;
         }
         next;
      }
      # Following is normal key
      $newDepth = $specDepth . "." . $hashKey;
      $newValue = ExpandTupleValueRecursive($currentSpec->{$hashKey}, $newDepth);
      if (IsFailure($newValue)) {
         $vdLogger->Error("Failed to resolve spec " . Dumper($currentSpec->{$hashKey}));
         $vdLogger->Debug("Spec depth is $newDepth");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      if (not defined $newValue) {
         $vdLogger->Debug("Expanded value is undef with spec depth as " .
                          "$newDepth for spec: " .
                          Dumper($currentSpec->{$hashKey}));
      }
      $newHash->{$hashKey} = $newValue;
   }

   return $newHash;
}


########################################################################
#
# ResolveArrayReference --
#     Method to process tuple/identifier given in [] format and return
#     initial, final values and total number of elements
#
# Input:
#     tuple : string the format [<initial>-<final>]
#
# Results:
#     returns 3 values (initial, final, total) in same order
#
# Side effects:
#     None
#
########################################################################

sub ResolveArrayReference
{
   my $tuple = shift;
   if ($tuple =~ /ARRAY/i) {
      $vdLogger->Error("Tuple/identifiers should be scalar, " .
                       "check if it is not enclosed within qoutes");
   }
   my ($initial, $final, $total) = undef;
   if ($tuple =~ /\[(\d+)-?(\d+)?\]/) {
      $initial = $1;
      $final   = $2 || $initial;
      $total   = $final - $initial + 1;
   } elsif ($tuple =~ /\[?-1\]?/i) {
      $initial = -1;
      $final   = -1;
      $total   = 1;
   } elsif ($tuple =~ /^(\d+)/i){
      $initial = $1;
      $final   = $1;
      $total   = 1;
   }
   return ($initial, $final, $total);
}


########################################################################
#
# ResolveRangeInArray --
#     Method to resolve range of number and save them in an array.
#     For example, for string "2,3,4-6", the output is array reference
#     of [2,3,4,5,6]
#
# Input:
#     tuple : string going to be resolved
#
# Results:
#     returns array reference that includes resolved numbers
#
# Side effects:
#     None
#
########################################################################

sub ResolveRangeInArray
{
   my $tuple = shift;
   my @arrayOfNumbers;
   if (not defined $tuple) {
      $vdLogger->Debug("Parameter not defined for ResolveRangeInArray");
      return $tuple;
   }
   if ($tuple =~ /\[(.*)\]/) {
      $tuple = $1;
   }
   # remove all spaces
   $tuple =~ s/\s//g;
   my @keyArray = split(/\,/, $tuple);
   foreach my $value (@keyArray) {
      if ($value =~ /(\d+)\-(\d+)/) {
         my $start = $1;
         my $end = $2;
         for (my $index = $start; $index <= $end; $index++){
            push(@arrayOfNumbers, $index);
         }
         next;
      }
      push(@arrayOfNumbers, $value);
   }

   return \@arrayOfNumbers;
}

########################################################################
#
# ConvertRawDataToHash
#       This is to convert stdout raw data into a hash
#
# Input:
#       data
#
# Results:
#       A hash of formatted data
#
# Side effects:
#       None
#
########################################################################

sub ConvertRawDataToHash
{
   my $data = shift;

   # 1) Split the value by '\n'
   # 2) Split the lines with :\s+
   # 3) Removing trailing spaces.
   # 4) Store them in hash and return the hash.

   my $convertedData;
   my @values = split('\n', $data);
   foreach my $value (@values) {
      my @counter;
      if ($value =~ /(:|=)/) {
         @counter = split(':\s+', $value) if $value =~ /:/;
         if (not defined $counter[1]) {
            next;
         }
         if ($counter[1] =~ /(\s+)/) {
            next;
         }
         # Remove leading space and tabs
         $counter[0] =~ s/^\s+//g;
         $counter[0] =~ s/\s+$//g;
         $counter[1] =~ s/(^\s+|\t)//g;
         $counter[1] =~ s/(\s+$|\t)//g;
         $convertedData->{$counter[0]} = $counter[1];
      } else {
         next;
      }
   }

   return $convertedData;
}


########################################################################
#
# ConvertHorizontalRawDataToHash
#       This is to convert stdout raw data into a hash
#
# Input:
#       data: as shown in the comment below
#
# Results:
#       A hash of formatted data
#
# Side effects:
#       None
#
########################################################################

sub ConvertHorizontalRawDataToHash
{
   my $data = shift;
   my $convertedData;

   #
   # We dont need the first two lines of stdout
   # ~ # esxcli network vswitch dvs vmware lacp get config
   # DVS Name           LAG ID  NICs                  Enabled  Mode
   # -----------------  ------  --------------------  -------  ----
   # vdswitch-0-1-1695       0  vmnic1,vmnic2,vmnic3    true   Active
   # vdswitch-1-1-1695       0                          true   Active
   # vdswitch-2-1-1695       0  vmnic4                  true   Passive
   #

   my @headerLine;
   my @tmp = split(/\n/, $data);
   for (my $i=0; $i<scalar(@tmp); $i++){
      my $line = $tmp[$i];
      # The line before data starts
      if ($line =~ /(--\s+--)/i) {
         @headerLine = split(/\s+/, $tmp[$i-1]);
         next;
      }
      # If the headers are not filled then go to next line
      if (scalar(@headerLine) eq 0) {
         next;
      }
      my @currentLine = split(/\s+/, $tmp[$i]);
      # In cases such as line vdswitch-1-1-1695, we dont know how to map
      # headers to data, so we bail out
      if (scalar(@currentLine) ne scalar(@headerLine)){
         $vdLogger->Error("Not sure how to handle this. Dont use this API ".
                          "for variable stdouts". Dumper($data));
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      foreach (my $y=0; $y<scalar(@currentLine); $y++) {
         $convertedData->{$currentLine[0]}->{$headerLine[$y]} =
                                                           $currentLine[$y];
      }
   }
   return $convertedData;
}


########################################################################
#
# HtoNL
#       Convert value from host to network byte order
#
# Input:
#       interger
#
# Results:
#       converted integer
#
# Side effects:
#       None
#
########################################################################

sub HtoNL
{
   my $input = shift;
   if (not defined $input) {
      $vdLogger->Error("input param missing");
      VDSetLastError("EFAILED");
      return FAILURE;
   }
   return unpack('N*', pack('L*', $input));
}


########################################################################
#
# NtoHL
#       Convert value from network to host byte order
#
# Input:
#       interger
#
# Results:
#       converted integer
#
# Side effects:
#       None
#
########################################################################

sub NtoHL
{
   my $input = shift;
   if (not defined $input) {
      $vdLogger->Error("input param missing");
      VDSetLastError("EFAILED");
      return FAILURE;
   }
   return unpack('L*', pack('N*', $input));
}


#######################################################################
#
# GetBroadcastFromIPandNetMask
#       Does what the name says
#
# Input:
#       ip address
#       netmask
#
# Results:
#       broadcast ip
#
# Side effects:
#       None
#
#########################################################################

sub GetBroadcastFromIPandNetMask
{
   my $ipaddr = shift;
   my $nmask  = shift;
   if ((not defined $ipaddr) || (not defined $nmask)) {
      $vdLogger->Error("Either IP or netmask is not defined");
      VDSetLastError("EFAILED");
      return FAILURE;
   }

   my @addrarr=split(/\./,$ipaddr);
   my ( $ipaddress ) = unpack( "N", pack( "C4",@addrarr ) );

   my @maskarr=split(/\./,$nmask);
   my ( $netmask ) = unpack( "N", pack( "C4",@maskarr ) );

   # Calculate broadcase address by inverting the netmask
   # and do a logical or with network address
   my $bcast = ( $ipaddress & $netmask ) + ( ~ $netmask );
   my @bcastarr=unpack( "C4", pack( "N",$bcast ) ) ;
   my $broadcast=join(".",@bcastarr);

   $vdLogger->Debug("Bcast ip for ip:$ipaddr and netmask:$nmask is $broadcast");
   return $broadcast;
}


########################################################################
#
# ProcessSpec --
#     Method to resolve any reference to keys (inventory/component
#     identifiers) in [] format to proper indexes with integer values.
#     Each key (with the new index) will refer to the original
#     value.
#     For example, if vm identifier is [1-5] => {..spec..},
#     then it will be resolved to 1 => <..spec..>, 2 => <..spec..>,
#     3=> <..spec..>, 4 => <..spec..>, 5 => <..spec..>
#
# Input:
#     spec: reference to the spec (user spec/testcase spec)
#
# Results:
#    Modified spec, if the conversion is successful;
#    FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ProcessSpec
{
   my $spec = shift;
   if (not defined $spec) {
      $vdLogger->Error("spec not defined in ProcessSpec()");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my %specCopy = %$spec;
   my $temp = \%specCopy;
   my $specComponents = INVENTORYCOMPONENTS;

   foreach my $inventory (keys %specCopy) {
      if (not defined $specComponents->{$inventory}) {
         $vdLogger->Debug("Unknown inventory item: $inventory");
         next;
      }
      my $inventorySpec = $specCopy{$inventory};

      my $expandedInventorySpec = VDNetLib::Common::Utilities::ExpandTuplesInSpecRecursive(
                                                               $inventorySpec, $inventory);
      $temp->{$inventory} = $expandedInventorySpec;

      foreach my $inventoryIdentifier (keys %$expandedInventorySpec) {
         foreach my $component (keys %{$expandedInventorySpec->{$inventoryIdentifier}}) {
            if (!grep(/$component/, @{$specComponents->{$inventory}})) {
               $vdLogger->Trace("$component is not a component");
               next;
            }
         }
      }
   }
   return $temp;
}


########################################################################
#
# ConvertKeysToLowerCase --
#     Method to covert all the keys of the hash in lower case
#
# Input:
#     spec: reference to the hash
#
# Results:
#    Modified spec, if the lower case conversion is successful;
#
# Side effects:
#     None
#
########################################################################

sub ConvertKeysToLowerCase
{
   my $spec = shift;
   my $lowerCaseSpec;
   if (ref($spec) eq "HASH") {
      foreach my $key (keys %$spec) {
         my $lowerCaseKey = lc($key);
         if (ref($spec->{$key}) eq "HASH") {
            $lowerCaseSpec->{$lowerCaseKey} = ConvertKeysToLowerCase($spec->{$key})
         } else {
            $lowerCaseSpec->{$lowerCaseKey} = $spec->{$key};
         }
      }
   }
   return $lowerCaseSpec;
}

#########################################################################
#
#  GetBuildInfo --
#      Gets Build Information
#
# Input:
#      None
#
# Results:
#      Returns "buildID, ESX Branch and buildType"
#      if there was no error executing the command
#      "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub GetBuildInfo
{
   my $hostIP = shift;
   my $stafHelper = shift;
   my ($cmd, $result);

   my ($build, $branch, $version, $buildType);

   $cmd = "vmware -v";
   $result = $stafHelper->STAFSyncProcess($hostIP, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Debug("STAF command $cmd failed:". Dumper($result));
      return FAILURE;
   }

   if (defined $result->{stdout}){
      my $test;
      ($test, $build) = split(/-/,$result->{stdout});
      chomp($build);

   # only first two digits of the version number is used, for example
   # for MN, it will be ESX50
      $branch = ($result->{stdout} =~ /.*(\d\.\d)\..*/) ? $1 : undef;
      if (defined $branch) {
         # get esxi version, for MN.next it will be 5.1
         $version = $branch;
         $branch =~ s/\.//g;
         $branch = 'ESX'."$branch";
      }
   } else {
      $vdLogger->Error("Unable to get branch info");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $vdLogger->Debug("ESX Branch = $branch Build = $build");
   $cmd = "vsish -e get /system/version";
   $result = $stafHelper->STAFSyncProcess($hostIP, $cmd);
   # Process the result
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to execute $cmd");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }

   if ($result->{stdout} =~ /.*buildType\:(.*)\n.*/){
      $buildType = $1;
      if ($buildType !~ /beta|obj|release|debug/i) {
         $vdLogger->Warn("Unknown build Type $buildType");
      }
      $vdLogger->Debug("BuildType = $buildType");
   } else {
      $vdLogger->Debug("Can't find buildType");
      return FAILURE;
   }
   return ($build, $branch, $buildType, $version);
}


##############################################################################
#
# CleanupOldFiles:
#    Remove Old Files provided in input
#
# Input:
#   path       : path of directory which will be deleted
#   stafhelper : staf object
#   systemip   : IP address of system where old files will be deleted
#
# Results:
#   none
#
###############################################################################

sub CleanupOldFiles
{
   my %args        = @_;
   my $systemip    = $args{systemip};
   my $stafhelper  = $args{stafhelper};
   my $path        = $args{path};

   if ((not defined $path) || ($path eq '/')) {
      $vdLogger->Warn("filetype undefined or trying to delete from / folder");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $commandForDel = 'perl ' . "/automation/scripts/cleanup.pl " . $path;
   $vdLogger->Debug("Deleting old files and directory from ESX Host " .
                   "using command= $commandForDel");
   my $ret = $stafhelper->STAFAsyncProcess($systemip, $commandForDel);
   if ($ret->{rc}) {
      $vdLogger->Warn("Failed to delete the directories" . Dumper($ret));
      VDSetLastError("EFAIL");
   }
}


########################################################################
#
# GetPIDFromName  --
#     Method to get process id from search string
#
# Input:
#     searchStr: grep string to find process
#
# Results:
#    process id, if process found;
#    FAILURE, if not found
#
# Side effects:
#     None
#
########################################################################

sub GetPIDFromName
{
   my $searchStr = shift;

   if (not defined $searchStr) {
      $vdLogger->Error("Search string not defined to get process ID");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $plist = `ps ax | grep -v grep | grep $searchStr `;
   $plist =~ s/^\s+//;
   my @pid = split(/ /, $plist);
   if ((scalar(@pid) > 0) && ($pid[0] =~ /\d+/)) {
      $vdLogger->Debug("Process ID " . $pid[0] . " for search string $searchStr");
      return $pid[0];
   }
   $vdLogger->Debug("Process ID not found for search string $searchStr");
   return FAILURE;
}


########################################################################
#
#  PickRandomElementFromArray
#       This method does what the method name says if user gives an array
#       Else just returns the value as it is.
#       E.g. vlan => VDNetLib::Common::GlobalConfig::ARRAY_VDNET_CLOUD_ISOLATED_VLAN_NONATIVEVLAN,
#
# Input:
#       value can be string or array
#       E.g. "lacp" will return lacp
#       ["lacp", "lacpv1", "lacpv2"] will pick any random value from this array
#
# Results:
#      Returns the same value or a random element from the array of values
#
# Side effetcs:
#       None
#
########################################################################

sub PickRandomElementFromArray
{
   my $value            = shift;
   if (ref($value) =~ /ARRAY/) {
      my @arrayOfValues = @$value;
      return $arrayOfValues[rand($#arrayOfValues)];
   }
   return $value;
}


########################################################################
#
#  PickRandomNumberFromARange
#       This method does what the method name says if user gives a range
#       Else just returns the value as it is.
#
# Input:
#       value can be number or range
#       E.g. 5 will return 5
#       5-10 will return any random number between this range
#
# Results:
#      Returns the same value or a random element from the range
#
# Side effects:
#       None
#
########################################################################

sub PickRandomNumberFromARange
{
   my $value            = shift;
   if ($value =~ /-/) {
      my @arrayOfValues = split('-', $value);
      return int(rand($arrayOfValues[1] - $arrayOfValues[0])) + $arrayOfValues[0];
   }
   return $value;
}


########################################################################
#
# GetRandomNumberFromSeed
#      This method returns a random number based on an int seed value
#
# Input:
#      integer or 'pid'. if 'pid' is found then use $$ as input
#
# Results:
#      Returns a random value based on the shifted pid
#      Returns FAILURE if intput is not an integer
#
# Side effects:
#       None
#
########################################################################

sub GetRandomNumberFromSeed
{
   my $input = shift;

   if ( $input !~ /^\d+$/ ) {
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ($input =~ /pid/i) {
       return srand($$<<15);
   }
   else {
       return srand($input<<15);
   }
}

########################################################################
#
# GetFileSystemTypeFromVIM--
#      This method returns the datastore storage type
#
# Input:
#      host: IP address of ESX on which the datastore type needs to be found.
#            (mandatory)
#      datastoreName: Absolute Path (mandatory)
#      userid : User name to login to host (mandatory)
#      password : password used to login to host (mandatory)
#
# Results:
#      a string which can be "NFS" or "VMFS" or "vfat"
#       or "vsan";
#      failure, in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetFileSystemTypeFromVIM
{
   my $host          = shift;
   my $datastoreName = shift;
   my $userid = shift;
   my $password = shift;
   my $result;
   my @typeArray = ();

   $vdLogger->Debug("Get datastore type of $datastoreName on host $host with " .
             "credential $userid $password");
   my $inlineHostObj = VDNetLib::InlineJava::Host->new(host => $host,
                                          user => $userid,
                                          anchor => undef,
                                          password => $password
                                          );

   if ((not defined $inlineHostObj) ||
       (defined $inlineHostObj && $inlineHostObj == FALSE)) {
      $vdLogger->Error("Failed to create inline Host object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $inlineHostObj->GetDatastoreType($datastoreName, \@typeArray);

   if (exists $typeArray[0]) {
      $vdLogger->Debug("Data store type is " . $typeArray[0]);
      return $typeArray[0];
   }
   return FAILURE;
}

########################################################################
# AddNodeToXml --
#       Looks for the given child node in the xml file, if the child node
#       exists,removes it first, then add the child node in; if the child
#       doesn't exist, add the child node in.
#
# Input:
#       fileName, the fileName of the XML file
#       parentPath, absolute path of the parent node
#                   a typical path is like /config/plugins/hostsvc/sriov
#       childNode, a hash represents the added node
#                  {
#                    tag: tagname
#                    attributes:{
#
#                              }
#                    text: text
#                   }
#
# Results:
#       return SUCCESS if the operation is successful
#       return FAILURE if encounter any error
#
# Side effects:
#       xmlFile is added with the new node
#
########################################################################

sub AddNodeToXml
{
   my $fileName = shift;
   my $parentPath = shift;
   my $childNode = shift;
   my $nodeTag = $childNode->{tag};
   my $attributes = $childNode->{attributes} if defined $childNode->{attributes};
   my $text = $childNode->{text};
   my $newChildElement;
   my $i;

   if ((not defined $fileName) || (not defined $parentPath) ||
        (not defined $childNode) || !$nodeTag) {
      $vdLogger->Error("AddNodeToXml: invalid/undefined parms");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   eval "require XML::LibXML";
   if ($@) {
      $vdLogger->Error("Loading XML::LibXML failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   eval {
      my $parser = XML::LibXML->new();
      my $doc = $parser->parse_file($fileName);
      my $root = $doc->documentElement();

      #The parent path may not exist yet,need to fill the gap
      #Find the first not empty node in the Path reversely
      my @parentNodes = split(/\//,$parentPath);
      my $firstNotEmptyNode = $root;
      for ($i = $#parentNodes;$i > 0;$i--){
         my @pathNode = $root->findnodes($parentPath);
         if (!$pathNode[0]) {
            $parentPath = substr($parentPath,0,rindex($parentPath,"/"));
         } else {
            $firstNotEmptyNode = $pathNode[0];
            last;
         }
      }
      #Fill the gap with new path Nodes
      for (my $emptyNode = $i+1;$emptyNode <= $#parentNodes;$emptyNode++){
         my $newPathElement = XML::LibXML::Element->new($parentNodes[$emptyNode]);
         $firstNotEmptyNode->appendChild($newPathElement);
         $firstNotEmptyNode = $newPathElement;
      }
      #Now the path is intact, add in the child node
      my @childrenNodes = $firstNotEmptyNode->getChildrenByTagName($nodeTag);
      if (@childrenNodes) {
         foreach my $child (@childrenNodes) {
            $firstNotEmptyNode->removeChild($child);
         }
      }

      $newChildElement = XML::LibXML::Element->new($nodeTag);
      if ((defined $attributes) && (%$attributes)) {
         while ((my $key,my $value) = each %$attributes){
            $newChildElement->setAttribute($key,$value);
         }
      }
      if (defined $text) {
         $newChildElement->appendTextNode($text);
      }
      $firstNotEmptyNode->appendChild($newChildElement);
      $doc->toFile($fileName);
   };
   if ($@) {
      $vdLogger->Error("Unable to add the node, throw exception:$@");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
#  AppendToFile
#       This method appends data to file with or without lock
#
# Input:
#       fileName: file absolute path (required)
#       data: data needs append (required)
#       operation: locking operations. 1,2,4 represents LOCK_SH, LOCK_EX,
#                  LOCK_NB. 0 means no lock (optional)
#
# Results:
#      SUCCESS: successfully write to file
#      FAILURE: incase any error
#
# Side effetcs:
#      Note that some versions of flock cannot lock things over the network;
#      you would need to use the more system-specific fcntl for that.
#
########################################################################

sub AppendToFile
{
   my $fileName = shift;
   my $data = shift;
   my $operation = shift || 0;
   my $FH;

   if ($operation <0 || $operation >=8) {
      $vdLogger->Error("Invalid operation to lock file $fileName");
      return FAILURE;
   }
   if (not defined open($FH, ">> " . $fileName)) {
      $vdLogger->Error("Unable to open file $fileName");
      return FAILURE;
   }
   if ($operation > 0) {
      if (flock($FH, $operation) == 0) {
         close $FH;
         $vdLogger->Error("Unable to lock file $fileName with operation $operation : $!");
         return FAILURE;
      }
   }
   print $FH  $data;
   print $FH  "\n";
   if ($operation > 0) {
      if (flock($FH, VDNetLib::Common::GlobalConfig::FLOCK_UNLOCK) == 0) {
         close $FH;
         $vdLogger->Error("Unable to unlock file $fileName : $!");
         return FAILURE;
      }
   }
   close $FH;
   return SUCCESS;
}


########################################################################
#
#  SavePIDToWatchdog
#       This method saves process ID to watch dog file
#
# Input:
#       pid: process ID (required)
#
# Results:
#      SUCCESS: successfully write to file
#      FAILURE: incase any error
#
# Side effetcs:
#      None
#
########################################################################

sub SavePIDToWatchdog
{
   my $pid = shift;
   my $filepath;
   my $ret;

   if ((not defined $pid) || ($pid < 0)) {
      $vdLogger->Error("Process ID not valid");
      return FAILURE;
   }
   $filepath = VDNetLib::Common::GlobalConfig::GetWatchdogFilePath();
   $vdLogger->Debug("Process ID $pid will be written into file $filepath");
   $ret = VDNetLib::Common::Utilities::AppendToFile($filepath, $pid,
            VDNetLib::Common::GlobalConfig::FLOCK_EXCLUSIVE);

   return $ret;
}


########################################################################
#
# GetProcessInstances --
#     Method to get number of process instances for the given process
#     name/pattern
#
# Input:
#     processName: name/pattern of a process
#
# Results:
#     array containing elements as process id;
#     (array size wil be zero, if no matching process id found)
#
# Side effects:
#     None
#
########################################################################

sub GetProcessInstances
{
   my $processName = shift;
   my $psOut = `ps ax | grep -v grep | grep \"$processName\" | awk '{print \$1}'`;

   my @pid = split(/\n/, $psOut);
   if (!scalar(@pid)) {
      $vdLogger->Debug("Couldn't get PID of $processName");
   }
   $vdLogger->Trace("Process instances for $processName: " . Dumper(@pid));
   return @pid;
}


#######################################################################
#
# FillServerForm --
#      The objective of this method is to fill out the empty
#      'server forms' with the data in 'payload' with the help
#      of attribute 'mapping'.
#
# Input:
#      payload      - a datastructure filled with key/value pair
#      serverForm   - empty server form to be used for filling data
#                     from the payload
#      mapping      - attribute mapping
#
# Results:
#      Return completed server forms.
#      Return FAILURE incase of any errors.
#
# Side effects:
#
########################################################################

sub FillServerForm
{
   my $payload         = shift;
   my $serverForm      = shift;
   my $mapping         = shift;

   if (ref($payload) ne ref($serverForm)) {
      $vdLogger->Error("payload reftype ref($payload) is not equal to" .
                       "serverForm reftype ref($serverForm)," .
                       Dumper($payload) . Dumper($serverForm) );
      $vdLogger->Error("payload: " . Dumper($payload));
      $vdLogger->Error("serverForm: " . Dumper($serverForm));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (ref($payload) eq "ARRAY") {
      $vdLogger->Debug("Reftype is array for payload");
      my @inputArray = ();
      my $count = 0;
      foreach my $arrayElement (@{$payload}) {
         my $result = RecurseThroughDatastructure($arrayElement,
                                                  $serverForm->[$count],
                                                  $mapping);
         if ($result eq FAILURE) {
            $vdLogger->Error("Filling out the server form (array) failed.");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         push(@inputArray, $result);
         $count++;
      }
      return \@inputArray;
   } elsif (ref($payload) eq "HASH") {
      $vdLogger->Debug("Reftype is hash for payload");
      my $result = RecurseThroughDatastructure($payload,
                                               $serverForm,
                                               $mapping);
      if ($result eq FAILURE) {
         $vdLogger->Error("Filling out the server form (array) failed.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      return $result;
   } else {
      $vdLogger->Error("The payload is neither hash nor array," .
                       " format not supported" . Dumper($payload));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}


#######################################################################
#
# RecurseThroughDatastructure --
#      This method recurses through server form data structure and calls
#      FillValuesInForm() if values inside $userData are strings.
#
# Input:
#      payload      - a datastructure filled with key/value pair
#      serverForm   - empty server form to be used for filling data
#                     from the payload
#      mapping      - attribute mapping
#
# Results:
#      Return completed serverforms.
#      Return FAILURE incase of any errors.
#
# Side effects:
#
########################################################################

sub RecurseThroughDatastructure
{
   my $payload         = shift;
   my $serverForm       = shift;
   my $mapping         = shift;
   if (ref($serverForm) eq "HASH") {
      $vdLogger->Debug("Reference type of serverForm is HASH");
      #
      # Data structure type is hash,
      # Start iterating through each key
      # of the hash.
      #
      foreach my $key (keys %$serverForm) {
         if ((ref($serverForm->{$key}) eq "HASH")) {
               $vdLogger->Debug("Reftype is hash and recurse for key $key");
               my $result = RecurseThroughDatastructure($payload->{$key},
                                                        $serverForm->{$key},
                                                        $mapping);
               if ($result eq FAILURE) {
                  $vdLogger->Error("Filling out the server form (array) failed.");
                  VDSetLastError(VDGetLastError());
                  return FAILURE;
               }
         } elsif (ref($serverForm->{$key}) eq "ARRAY") {
            my @inputArray = ();
            my $count = 0;
            foreach my $serverFormElement (@{$payload->{$key}}) {
               $vdLogger->Debug("Reftype is array and recurse for key $key");
               my $helper = $serverForm->{$key};
               my $result = RecurseThroughDatastructure($serverFormElement,
                                                        $helper->[0],
                                                        $mapping);
               $count++;
               if ($result eq FAILURE) {
                  $vdLogger->Error("Filling out the server form (array) failed.");
                  VDSetLastError(VDGetLastError());
                  return FAILURE;
               }
               my $resultClone = dclone $result;
               push(@inputArray, $resultClone);
            }
            #
            # Storing the values returned from RecurseThroughDatastructure()
            # for each element of array in {$userData->{$key}
            # in a bucket @inputArray and return the array reference
            #
            $serverForm->{$key} = \@inputArray;
         } else {
            $vdLogger->Debug("Calling FillValuesInForm() for key $key");
            $serverForm = FillValuesInForm($payload,
                                           $key,
                                           $serverForm,
                                           $mapping);
         }
      }
   } elsif (ref($serverForm) eq "ARRAY") {
      $vdLogger->Debug("Reference type of serverForm is ARRAY");
      #
      # Data structure type is array,
      # Start iterating through each element
      # of the array.
      #
      my @inputArray = ();
      my $count = 0;
      foreach my $arrayElement (@{$payload}) {
         $vdLogger->Debug("Iterating/recursing through each element of" .
                          "serverform");
         my $result = RecurseThroughDatastructure($arrayElement,
                                                  $serverForm->[0],
                                                  $mapping);
         if ($result eq FAILURE) {
            $vdLogger->Error("Filling out the server form (array) failed.");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         push(@inputArray, $result);
         $count++;
      }
      #
      # Storing the values returned from RecurseThroughDatastructure()
      # for each element of array in {$userData->{$key}
      # in a bucket @inputArray and return the array reference
      #
      return \@inputArray;
   }
   return $serverForm;
}

#######################################################################
#
# FillValuesInForm --
#      Replace empty values with the values in payload using server form.
#      This is a helper method called by RecurseThroughDataStructure()
#
# Input:
#      payload      - a datastructure filled with key/value pair
#      serverForm   - empty server form to be used for filling data
#                     from the payload
#      mapping      - attribute mapping
#
# Results:
#      Return proper values in place of null values
#
# Side effects:
#
########################################################################

sub FillValuesInForm
{
   my $payload      = shift;
   my $key           = shift;
   my $serverForm    = shift;
   my $mapping       = shift;

   if (exists $mapping->{$key}) {
      $serverForm->{$key} = $payload->{$mapping->{$key}{payload}};
   } else {
      $vdLogger->Debug("Key $key not present in mapping, the entry" .
                       " for this key will be used from payload");
      $serverForm->{$key} = $payload->{$key};
   }
   return $serverForm;
}


########################################################################
#
# SortTestcasesByTestbed --
#     Method to sort test cases by testbed specification
#
# Input:
#     arrayOfTestcaseHashes: reference to array of testcase hashes
#
# Results:
#     sortedTestcases: reference to sorted array of testcase hashes
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub SortTestcasesByTestbed
{
   my $arrayOfTestcaseHashes = shift;

   my @sortedArrayOfChecksums;

   my $hashOfChecksumKeys;
   my @sortedTestcases;
   #
   # Go through each test case hash, get the
   # testbed spec. Serialize testbed spec, lower case the keys,
   # remove spaces to ensure differences in case or space
   # is not treated as different spec
   #
   foreach my $testcaseHash (@$arrayOfTestcaseHashes) {
      my $testbed = $testcaseHash->{'TestbedSpec'};
      my $checksum = GetChecksumForHash($testbed);
      if ($checksum eq FAILURE) {
         $vdLogger->Debug("Failed to get checksum value for hash");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      push(@sortedArrayOfChecksums, $checksum);
      #
      # Organize the testcases
      # using hash with key name as checksum
      # and value as array of testcases with same checksum
      #
      push(@{$hashOfChecksumKeys->{$checksum}}, $testcaseHash);
   }
   #
   # Sort of the array which contains elements as checksum
   # Note: this sorting is better than sorting using serialized
   # hash as elements
   #
   @sortedArrayOfChecksums = sort @sortedArrayOfChecksums;

   #
   # Now, go through the array of checksums, lookup
   # for each checksum in the hashOfChecksumKeys
   # and pop an element (testcase) from the array
   #
   foreach my $checksum (@sortedArrayOfChecksums) {
      my $testcase = pop(@{$hashOfChecksumKeys->{$checksum}});
      if (scalar(@{$hashOfChecksumKeys->{$checksum}}) == 0) {
         $testcase->{'isLastTestInTheGroup'} = 1;
      } else {
         $testcase->{'isLastTestInTheGroup'} = 0;
      }
      push(@sortedTestcases, $testcase);
   }
   return \@sortedTestcases;
}


########################################################################
#
# GetChecksumForHash --
#     Method to compute checksum for the given hash
#
# Input:
#     inputHash: reference to hash for which checksum should be computed
#
# Results:
#     A string of length 32 which is checksum in hex value for the given
#     hash;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetChecksumForHash
{
   my $inputHash = shift;
   my $checksum;
   my $dumper = Data::Dumper->new([$inputHash]);
   $dumper->Deepcopy(1);
   #
   # Use eval to load the Digest module to avoid
   # failures in remoteAgent.pl which runs on guest OS
   #
   eval "require Digest::MD5";

   if ($@) {
      $vdLogger->Error("Failed to load Digest::MD5 module: $@");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   # serialize the given hash and change to lower case
   $inputHash = lc($dumper->Dump());
   # remove all spaces in the serialized value
   $inputHash =~ s/\s//g;
   # compute checksum
   $checksum = Digest::MD5::md5_hex($inputHash);
   return $checksum;
}


########################################################################
#
# CreateSSHSession --
#     Method to create ssh session to a remote host
#
# Input:
#     host: host IP
#     user: user name
#     password: login password
#
# Results:
#      SUCCESS: successfully login
#      FAILURE: incase any error
#
# Side effects:
#     None
#
########################################################################

sub CreateSSHSession
{
   my $host = shift;
   my $user = shift;
   my $password = shift;

   if (not defined $sshSession->{$host}) {
      my  $sshHost = VDNetLib::Common::SshHost->new($host, $user,
                                                    $password);
      unless ($sshHost) {
         $vdLogger->Error("Failed to establish a SSH session with " .
                          $host);
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $sshSession->{$host} = $sshHost;
      if (VDNetLib::Common::Utilities::SavePIDToWatchdog($sshHost->GetPID()) eq
          FAILURE) {
         $vdLogger->Error("Failed to save SSH process ID to watch dog");
      }
   }
   return SUCCESS;
}


########################################################################
#
# GetAllLocalIPAddresses --
#     Routine to get all local ip addresses except loopback
#
# Input:
#     None
#
# Results:
#     Reference to an array of ip addresses
#
# Side effects:
#     None
#
########################################################################

sub GetAllLocalIPAddresses
{
   my $cmd = `ifconfig | grep "inet addr:"`;
   my @temp = split("\n", $cmd);
   my @list;
   my $ipRegex = VDNetLib::Common::GlobalConfig::IP_REGEX;
   foreach my $line (@temp) {
      if ($line =~ /inet addr:($ipRegex)/i) {
         my $ip = $1;
         if ($ip !~ /^127/) {
            push(@list, $ip);
         }
      }
   }
   return \@list;
}


########################################################################
#
# ResolveIndexValues --
#     Routine to resolve indexes with special representation
#
# Input:
#     index:  this is the first level index in the spec
#             example: vm => {
#                          '[1]' => {
#                                host => "host.[x]",
#                           },
#                      }
#                      Here, [1] is the first level index;
#     value:  this is the value to be resolved using
#             the 'index' given above;
#             example: [x], [x:mod:<int>]
#                      TODO: [x:level:<componentName>]
#
# Results:
#     resolved value (string);
#     FAILURE, in case of error;
#
# Side effects:
#     None
#
########################################################################

sub ResolveIndexValues
{
   my $index = shift;
   my $value = shift;
   my $modified = 1; # flag to indicate if any change was made

   # any value that starts with x means, it needs to be resolved
   if ($value =~ /\[(x:?\w?:?.*?)\]/i) {
      my $resolvedValue;
      my $unresolvedIndex = $1;
      # the format of special index value is
      # x:<function>:<parameter>
      my ($x, $operator, $parameter) = split(":", $unresolvedIndex);
      my $operatorHash = {
         'vdnetmod' => \&VDNetModuloOperator,
         'vdnetrange' => \&VDNetRangeOperator,
      };
      if (defined $operator) {
         if (defined $operatorHash->{$operator}) {
            $resolvedValue = &{$operatorHash->{$operator}}($index, $parameter);
         } else {
            $vdLogger->Error("Unknown operator $operator given to resolve index");
            VDSetLastError("ENOTSUP");
            return FAILURE;
         }

      } else {
         $resolvedValue = $index;
      }
      # replace unresolved value in x:<function>:<parameter> format
      # with resolved value
      $value =~ s/\[x.*?\]/\[$resolvedValue\]/ig;
   } else{
      $modified = 0;
   }
   return ($value, $modified);
}


########################################################################
#
# VDNetRangeOperator --
#    Routine to get range value based on the given index and value.
#    Example: for x= 1,2, the index in host.[x:vdnetrange:32]
#    will resolve to host.[1-32] and host.[33-64]
#
# Input:
#     index     : index value for which a range of value should be
#                 computed
#     rangeValue: range value as integer
#
# Results:
#     range value in <minValue>-<maxValue> format
#
# Side effects:
#     None
#
########################################################################

sub VDNetRangeOperator
{
   my $index      = shift;
   my $rangeValue = shift;
   my $max = $index * $rangeValue;
   my $min = ($max - $rangeValue) + 1;
   return "$min-$max";

}

########################################################################
#
# VDNetModuloOperator --
#     Routine to get modulo of given index and value
#
# Input:
#     firstNumber: LHS of modulo operator
#     secondNumber: RHS of modulo operator
#
#
# Results:
#
# Side effects:
#
########################################################################

sub VDNetModuloOperator
{
   my $firstNumber  = shift;
   my $secondNumber = shift;
   my $result;
   # this is slightly modified version of mod operator where if the result
   # is zero, the secondNumber of returned. this is primarily implemented
   # this way for vdnet's component index representation. example 4 % 4 is 0
   # but, this returns 4 to avoid index value as 0.
   return (!($result = $firstNumber % $secondNumber)) ? $secondNumber : $result;
}


########################################################################
#
# VDNetInventoryBasedAlgorithm
#     Routine to get index based on inventoryIndex,component index and
#     component number
#
# Input:
#     index     : index value
#     formula  : formula for calculating index
#     specDepth : depth for spec like host.1.vnic.1
#
# Results:
#
# Side effects:
#
########################################################################

sub VDNetInventoryBasedAlgorithm
{
   my $index  = shift;
   my $formula = shift;
   my $specDepth = shift;

   if (not defined $formula) {
      $vdLogger->Error("formula is not defined for specDepth " .
                       "($specDepth)");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $vdLogger->Debug("Component index $index formula $formula " .
                    "for object $specDepth");

   # if $formula is constant, just use it
   if ($formula !~ /index/i) {
     return $formula;
   }
   $specDepth =~ s/\[|\]//ig;

   # Idea here is, split $specDepth into an Array, for example,
   # @pathArray = ['vm', '3', 'vnic', '1']
   # Based on this array, we replace vm_index in formula with 3,
   # replace vnic_index in formula with 1. Then we change formula
   # from "vm_index + vnic_index" to "3 + 1"
   my @pathArray  = split(/\./, $specDepth);
   for (my $position=0; $position < int(scalar(@pathArray)/2); $position++) {
      my $indexValue = $pathArray[$position*2+1];
      my $indexExpression = $pathArray[$position*2] . "_index";
      if ((not defined $indexValue) || ($indexValue eq '')) {
         $vdLogger->Error("indexValue is not defined");
         return FAILURE;
      }
      $formula =~ s/$indexExpression/$indexValue/ig;
   }
   $formula =~ s/mod/\%/ig;
   $vdLogger->Debug("Resolved formula $formula");
   my $result = undef;
   eval {
      $result = eval($formula);
   };
   if ($@) {
      $vdLogger->Error("Failed to evaluate the formula: $formula");
      return FAILURE;
   }
   if (not defined $result) {
      $vdLogger->Error("Evaluating formula ($formula) did not produce a " .
                       "result");
      return FAILURE;
   }
   $vdLogger->Debug("Calculated index is $result");
   if ($result =~ /\d+/) {
      return $result;
   }
   return $index;
}


########################################################################
#
# ResolveIndexValuesWithPath --
#     Routine to resolve indexes with special representation
#
# Input:
#     index:  this is the first level index in the spec
#             example: vm => {
#                          '[1]' => {
#                                host => "host.[x]",
#                           },
#                      }
#                      Here, [1] is the first level index;
#     value:  this is the value to be resolved using
#             the 'index' given above;
#             example: [x], [x:mod:<int>]
#                      TODO: [x:level:<componentName>]
#     specDepth: object path in spec, like host.1.vds.1
#
# Results:
#     (resolved value, modified flag) : resolved value will be undef
#        if $value is undef
#     FAILURE, in case of error;
#
# Side effects:
#     None
#
########################################################################

sub ResolveIndexValuesWithPath
{
   my $index = shift;
   my $value = shift;
   my $specDepth = shift;
   my $resolvedValue;

   my $modified = 0; # flag to indicate if any change was made
   if (not defined $value) {
      $vdLogger->Debug("Value of $specDepth is undef");
      return ($value, $modified);
   }

   # PR 1299303: Move this as first condition since its subset of
   # next if condition
   # "[x=(level1_index-1)*8+level2_index]"
   # any value that starts with x= means goes to this block
   if ($value =~ /\[x=([\W\w]*)\]/i) {
      # Incase there are more than one formula in value, like
      # value ==  vm.[x=vm_index].vnic.[x=vnic_index], split value with "."
      my @componentArray = split(/\./, $value);
      my $newValue = "";
      foreach my $component (@componentArray) {
         if ($component !~ /\[x=([\W\w]*)\]/i) {
            $newValue .= ($newValue eq "") ? $component : ("." . $component);
            next;
         }
         my $formula = $1;
         $resolvedValue = VDNetInventoryBasedAlgorithm($index, $formula, $specDepth);
         if ((not defined $resolvedValue) || ($resolvedValue eq FAILURE)) {
            $vdLogger->Error("Applying VDNet Inventory based algorithm " .
                             "failed on index: $index, formula $formula and" .
                             "specDepth: $specDepth");
            return FAILURE;
         }
         $component =~ s/\[x.*?\]/\[$resolvedValue\]/ig;
         $newValue .= ($newValue eq "") ? $component : ("." . $component);
      }
      # Save the new value into $value, then do the x: checking in next if block
      $vdLogger->Debug("Replace $value with $newValue");
      $value = $newValue;
      $modified = 1;
   }

   # any value that starts with x: means, it needs to be resolved
   if ($value =~ /\[(x:?\w?:?.*?)\]/i) {
      my $unresolvedIndex = $1;
      # the format of special index value is
      # x:<function>:<parameter>
      my ($x, $operator, $parameter) = split(":", $unresolvedIndex);
      my $operatorHash = {
         'vdnetmod' => \&VDNetModuloOperator,
         'vdnetrange' => \&VDNetRangeOperator,
      };
      if (defined $operator) {
         if (defined $operatorHash->{$operator}) {
            $resolvedValue = &{$operatorHash->{$operator}}($index, $parameter);
         } else {
            $vdLogger->Error("Unknown operator $operator given to resolve index");
            VDSetLastError("ENOTSUP");
            return FAILURE;
         }

      } else {
         # Check if $index is not number, then get the real index from specDepth
         if (($index =~  /\D/) && ($specDepth =~ /(\d+)\D*\z/)) {
            $resolvedValue = $1;
         } else {
            $resolvedValue = $index;
         }
      }
      # replace unresolved value in x:<function>:<parameter> format
      # with resolved value
      $value =~ s/\[x.*?\]/\[$resolvedValue\]/ig;
      $modified = 1;
   }

   return ($value, $modified);
}


########################################################################
#
# CollectMemoryInfo --
#     Method to collect memory usage info in machine that runs it
#
# Input:
#     None
#
# Results:
#     None
#
# Side effects:
#     None
#
########################################################################

sub CollectMemoryInfo
{
   my $checkCommand = "bash -c \"ulimit -a\"";
   my $result = `$checkCommand`;
   $vdLogger->Debug("$checkCommand returns:\n$result");

   $checkCommand = "ps ux";
   $result = `$checkCommand`;
   $vdLogger->Debug("\"$checkCommand\" returns:\n$result");

   $checkCommand = "ps ef";
   $result = `$checkCommand`;
   $vdLogger->Debug("\"$checkCommand\" returns:\n$result");

   $checkCommand = "free -m";
   $result = `$checkCommand`;
   $vdLogger->Debug("\"$checkCommand\" returns:\n$result");
}


########################################################################
#
# RetryMethod --
#     Method to retry a particular method
#
# Input:
#     Hash containing these values
#     object  : Input object
#     method  : Method to retry
#     timeout : TIMEOUT value
#     sleep   : sleep between retries
#  Optional Paramter:
#     expectedResult: value of the expected result
# Results:
#     Return value if SUCCESS
#     otherwise returns FAILURE
#
# Side effects:
#     None
#
########################################################################

sub RetryMethod
{
   my $inputHash = shift;
   my $method  = $inputHash->{'method'};
   my $obj  = $inputHash->{'obj'};
   my $timeout  = $inputHash->{'timeout'} || 50;
   # Default sleep is 10% of TIMEOUT
   my $sleep    = $inputHash->{'sleep'} || ($timeout * 0.1);
   my $result;
   my $expectedResult;
   if( exists $inputHash->{'expectedResult'} ) {
       $expectedResult = $inputHash->{'expectedResult'};
   } else {
       $expectedResult = "None";
   }
   if ((not defined $method) or (not defined $obj)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $vdLogger->Debug("Running $method with TIMEOUT: $timeout sleep: $sleep");
   while ($timeout > 0) {
      $result= $obj->$method($inputHash->{'param1'});
      if ((defined $result) and ($result ne FAILURE)) {
            return $result;
      } elsif (($expectedResult ne "None") and ($result->{rc} eq $expectedResult)) {
            return SUCCESS;
      }
      sleep($sleep);
      $timeout -= $sleep;
   }
   $vdLogger->Debug("TIMEOUT running $method.");
   return FAILURE;
}


###############################################################################
#
# TypeOfMacAddress -
#       Get the mac address type, whether it is unicast, multicast or broadcast
#
# Input:
#       mac address(required)
#
# Results:
#       type of mac address.
#       INVALID - in case of invalid mac address.
#
# Side effects:
#       None.
#
###############################################################################

sub TypeOfMacAddress
{
   my $mac  = shift;
   my $type = "invalid";
   if ($mac !~ /(([0-9a-fA-F]{2})(([:-][0-9a-fA-F]{2}){5}))/) {
      $vdLogger->Error("not a valid mac address $mac");
      VDSetLastError("EINVALID");
      return $type;
   }
   $mac =~ s/-/:/g;
   if ($mac =~ /ff:ff:ff:ff:ff:ff/i) {
      $type = "broadcast";
   } elsif ($mac =~ /^01:.*/i || $mac =~ /^33:33:.*/i) {
      $type = "multicast";
   } else {
      $type = "unicast";
   }

   return $type;
}


###############################################################################
#
# FullLengthIPv6Address -
#       Convert a IPv6 address to full length
#       For example, fe00::2001:2:3 to
#       fe00:0000:0000:0000:0000:2001:0002:0003
# Input:
#       IPv6 address(required)
#
# Results:
#       IPv6 address converted to full length
#       otherwise returns 'invalid'
#
# Side effects:
#       None.
#
###############################################################################

sub FullLengthIPv6Address
{
  my $ipv6addr  = shift;
  if (not defined $ipv6addr) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return 'invalid';
  }
  my $fulllengthipv6addr = new Net::IP($ipv6addr);
  if (not defined $fulllengthipv6addr){
     $vdLogger->ERROR("Invalid ipv6 address: $ipv6addr");
     return 'invalid';
  } else {
     return $fulllengthipv6addr->ip();
 }
}


########################################################################
#
# MergeSpec --
#     Method to merge user config spec and testcase spec
#
# Input:
#     userSpec: reference to hash containing user configuration
#     testSpec: reference to hash containing test case spec
#               (These specs have to be simple structure i.e
#               should not be nested hash)
#
# Results:
#     SUCCESS, if specs are merged;
#
# Side effects:
#     None
#
########################################################################

sub MergeSpec
{
   my $customSpec       = shift;
   my $specTobeUpdated  = shift;

   foreach my $item (keys %$customSpec) {
      if (ref($customSpec->{$item}) eq "HASH") {
         #
         # First check if the item is a hash, if yes, then,
         # merge only if the hash exists in the actual testbed spec
         # from the test case. This will ensure components that
         # are required by test case are updated and not any additional
         # components from custom spec. For example, if the user has
         # entries for 2 hosts, but the testcase requires only one host,
         # then merge only one host.
         #
         if (defined $specTobeUpdated->{$item}) {

            # recursive call to process all component specs
            $specTobeUpdated->{$item} = MergeSpec($customSpec->{$item},
                                                      $specTobeUpdated->{$item}
                                                      );
         } else {
            next;
         }
      } elsif (not defined $specTobeUpdated->{$item}) {
         $specTobeUpdated->{$item} = $customSpec->{$item};
      } else {
            # update the spec, make sure this is updating the actual
            # spec and not the pointer
            my %orig = %$specTobeUpdated;
            $orig{$item} = $customSpec->{$item};
            $specTobeUpdated = \%orig;
            $vdLogger->Debug("Overriding $item with $customSpec->{$item}");
         if ($specTobeUpdated->{$item} =~ /\<|\>/) {
            $vdLogger->Debug("Overriding $item with $customSpec->{$item}");
         } else {
            # TBD: whether to throw error/skip if something can't be overridden
            #$vdLogger->Warn("Cannot override $item since it is not a variable");
         }
      }
   }
   return $specTobeUpdated;
}


###############################################################################
#
# CopyDirectory
#      This method will check if there is file under one directory,
#      If yes, copy them to dest directory.
#
# Input:
#      srcDir : source directory on host (mandatory). This is absolute path.
#      dstDir : destination directory name on MC (mandatory) This is not absolute
#               path, just directory name under vdnet log directory
#      srcIP : IP address of directory source (mandatory)
#      stafHelper : staf helper (optional)
#      isRemoveNeeded : after copy finished, if we need remove files from source
#                       (optional) By default it is 0, means not remove
#
# Results:
#      SUCCESS: file copy successful
#      FAILURE: in case any error
#
# Side effects:
#      None.
#
###############################################################################

sub CopyDirectory
{
   my %args = @_;
   my $srcDir = $args{srcDir};
   my $dstDir = $args{dstDir};
   my $srcIP = $args{srcIP};
   my $stafHelper = $args{stafHelper};
   my $isRemoveNeeded = $args{isRemoveNeeded};
   my $result;

   if ((not defined $srcDir) || (not defined $dstDir)) {
      $vdLogger->Error("Directory names not defined for copy operation");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $isRemoveNeeded) {
      $isRemoveNeeded = 0;
   }
   # If ssh host object exists, call ssh copy
   if (defined ($sshSession->{$srcIP})) {
      return $sshSession->{$srcIP}->CopyDirectory(srcDir => $srcDir,
             dstDir => $dstDir, srcIP => $srcIP,
             isRemoveNeeded => $isRemoveNeeded);
   }
   if (not defined $stafHelper) {
      $vdLogger->Error("Staf helper not defined for copy operation");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $stafHelper->STAFCopyDirectory(srcDir => $srcDir,
             dstDir => $dstDir, srcIP => $srcIP,
             isRemoveNeeded => $isRemoveNeeded);
}


########################################################################
#
# CheckIfPIDIsRunning --
#     Routine to check if given process id exists/running
#
# Input:
#     pid: process id to check
#
# Results:
#     boolean, 1 if pid exists, 0 otherwise
#
# Side effects:
#     None
#
########################################################################

sub CheckIfPIDIsRunning
{
   my $pid = shift;
   my $result = `ps cax | grep $pid`;
   my @lines  = split("\n", $result);
   for my $line (@lines) {
      # example for "ps cax":
      # 6004 pts/6    Sl+    0:00 java
      # remove any space in the beginning of the line
      $line =~ s/^\s+//;
      my @processInfo = split('\s', $line);
      if ($pid eq $processInfo[0]) {
         $vdLogger->Debug("Process with pid $pid running: $line");
         return TRUE;
      }
   }
   $vdLogger->Debug("No process with pid $pid running: $result");
   return FALSE;
}


########################################################################
#
# ParseTextTupleMethod --
#    Method to parse string of the form '(*)vdnet_tuple->method'.
#    XXX(gangarm): Current limitation is tuple must be restricted to
#    basic form of vm.[1].vnic.[1]. Indices like [-1], [1-4] not
#    supported for now.
#
# Example:
#   input: "cflow.srcaddr==vm.[1].vnic.[1]->GetMACAddress"
#   output:
#          { 'method' => 'GetMACAddress'
#            'text' => 'cflow.srcaadr=='
#            'tuple' => 'vm.[1].vnic.[1]'}
#
# Input:
#   $word: String of the form (.*)<tuple->method>
#
# Results:
#   Hash containing (.*), tuple and method obtained by parsing the
#   input if input matches the given form, else undef.
#   FAILURE on error.
#
# Side effects:
#     None
#
########################################################################

sub ParseTextTupleMethod
{
   my $word = shift;
   if (not defined $word) {
      $vdLogger->Error("Insufficient parameters for ParseTextTupleMethod()");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if ($word =~ /^(.*?)(\w+\.\[.*?\])\->(\S+)/) {
      my $text = $1;
      my $tuple = $2;
      my $method = $3;
      $vdLogger->Trace("Parsed $word to return text=$text, tuple=$tuple and " .
                       "method=$method");
      return {'text'=>$text, 'tuple'=>$tuple, 'method'=>$method};
   }
   else {
      $vdLogger->Debug("Input $word not of the form (.*)vdnet_tuple->method." .
                       " Returning undef.");
      return undef;
   }
}


###############################################################################
#
# DirExists
#      This method will check if a directory exists in destination host
#
# Input:
#      dir : directory name (mandatory). This is absolute path.
#      remoteIP : IP address of VM that dir locates (mandatory)
#      stafHelper : staf helper (optional)
#
# Results:
#      TRUE: if dir exists on remote VM
#      FALSE: dir not exists
#      FAILURE: in case of any error
#
# Side effects:
#      None.
#
###############################################################################

sub DirExists
{
   my %args = @_;
   my $dir = $args{dir};
   my $remoteIP = $args{remoteIP};
   my $stafHelper = $args{stafHelper};

   if ((not defined $dir) || (not defined $remoteIP)) {
      $vdLogger->Error("Directory name or remote IP not defined");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # If ssh host object exists, use ssh command
   if (defined ($sshSession->{$remoteIP})) {
      my $command = "if [ -d $dir ];then echo \'YES\';else echo \'No\';fi";
      my ($result, $output) = $sshSession->{$remoteIP}->SshCommand($command);
      if ($result ne "0") {
         $vdLogger->Debug("SSH command $command failed on $remoteIP:". Dumper($output));
         return FAILURE;
      }
      if ((scalar(@$output) > 0) && ($output->[0] =~ /YES/)) {
         return TRUE;
      }
      return FALSE;
   }
   if (not defined $stafHelper) {
      $vdLogger->Error("Staf helper not defined");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $stafHelper->DirExists($remoteIP, $dir);
}


###############################################################################
#
#  ListDirectory
#      This method will list content in a directory in destination host
#
# Input:
#      dir : directory name (mandatory). This is absolute path.
#      remoteIP : IP address of VM that dir locates (mandatory)
#      stafHelper : staf helper (optional)
#
# Results:
#      directory content
#      FAILURE: in case of any error
#
# Side effects:
#      None.
#
###############################################################################

sub ListDirectory
{
   my %args = @_;
   my $dir = $args{dir};
   my $remoteIP = $args{remoteIP};
   my $stafHelper = $args{stafHelper};

   if ((not defined $dir) || (not defined $remoteIP)) {
      $vdLogger->Error("Directory name or remote IP not defined");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # If ssh host object exists, use ssh command
   if (defined ($sshSession->{$remoteIP})) {
      my $command = "ls $dir";
      my ($result, $output) = $sshSession->{$remoteIP}->SshCommand($command);
      if ($result ne "0") {
         $vdLogger->Debug("SSH command $command failed on $remoteIP:". Dumper($output));
         return FAILURE;
      }
      return $output;
   }
   if (not defined $stafHelper) {
      $vdLogger->Error("Staf helper not defined");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $stafHelper->STAFFSListDirectory($remoteIP, $dir);
}

1;
