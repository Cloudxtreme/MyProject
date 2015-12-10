#!/usr/bin/perl -w
########################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
########################################################################
package VDNetLib::NetAdapter::NetDiscover;
my $version = "1.0";

# VDNetLib::NetAdapter::NetDiscover.pm --
# This package exports modules to
# 1. get list of all adapters in a machine
# 2. get an adapter of type vlance/vmxnet2/e1000/e1000e/vmxnet3
# when a filter of above mentioned types is specified
# 3. creates a vlan interface
# 4. allows to get and set properties of an interface when specified.

use strict;
use warnings;
use Exporter;
use Data::Dumper;
use Net::IP;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError
                                   VDCleanErrorStack );
use VDNetLib::Common::DeviceProperties qw (%e1000 %e1000e %vmxnet2 %vmxnet3
                                           %vlance %ixgbe);
use VDNetLib::Common::VDLog;
use VDNetLib::Common::Utilities;

# To preserve static ip after resuming the VM we configure ip in user
# defined scripts which tools daemon will call after resume operation
our @toolsScriptsPath = qw(/etc/vmware-tools/);

BEGIN {
   eval "use Win32::OLE('in')";
   eval "use Win32API::File qw ( :ALL )";
   use constant INVALID_HANDLE => -1;
   }

use constant DEFAULT_SLEEP => 10;
use constant DEFAULT_TIMEOUT => 120;
use constant TRUE => 1;
use constant FALSE => 0;
use constant OSTYPE => VDNetLib::Common::GlobalConfig::GetOSType();
use constant OS_LINUX => 1;
use constant OS_WINDOWS => 2;
use constant OS_MAC => 4;
use constant OS_BSD => 5;
use constant OID_GEN_MAXIMUM_FRAME_SIZE => 0x00010106;  # OID to get MTU size
                                                        # using deviceIOControl
use constant OID_GEN_VLAN_ID => 0x0001021C;             # OID to get/set VLAN ID
use constant OID_GEN_DRIVER_VERSION => 0x00010110;      # OID to get Ndis
                                                        # driver version
use constant TEST_NETWORK => VDNetLib::Common::GlobalConfig::TEST_NETWORK;
use constant MGMT_NETWORK => VDNetLib::Common::GlobalConfig::MGMT_NETWORK;
my $Registry;   # Win32::TieRegistry exports global variable $Registry. Hence
                # any usage of $Registry will throw warnings on linux. To avoid
                # warnings, initialize $Registry

if (OSTYPE == OS_WINDOWS) {
   no warnings;
   require Win32::TieRegistry;  # use Win32::TieRegistry only on windows
   $Registry = $Win32::TieRegistry::Registry;   # update $Registry value to the
                                                # global value exported by
                                                # Win32::TieRegistry
   use warnings;
}


########################################################################
#
# GetAdapters --
#      Finds the all or selected network adapters along with some of
#      their configuration details.
#
# Input:
#      GetAdapters(<Control IP address>, <device filter>,
#                  <adaptersCount>)
#       - Control IP address: control network interface's IP address
#       - Device filter: can take ONE of the following values
#              all/e1000/e1000e/vmxnet2/vmxnet3/vlance or
#              mac address
#       - adaptersCount: number of adapters to discover.
#                        if given filter is a mac address, then 1
#                        is assigned to this parameter,
#                        if given filter is "all", then 'undef'
#                        is assigned to this parameter.
#
# Results:
#      If success, a reference to array of hashes with the following keys
#      will be returned for all/filtered network devices from the machine
#      specified at the input {interface, name, macaddress, ipv4, adminstate,
#      description, hwid, nictype}
#      Otherwise, in case of failure, -1 is returned.
#
# Side effects:
#       The network devices' state changes between enabled or disabled on the
#       remote machine based on the device filter parameter. The control
#       adapter's state will always be same. Control adapter is the interface
#       referred by the address at the input
#       If following device filter parameter to GetAdapters() module is passed,
#               - all, then all devices will be enabled
#               - e1000/e1000e/vlance/vmxnet2/vmxnet3, then the first
#                  adapter of type (other than the control adapter)
#                  specified by filter will be enabled if it was disabled
#                  and all other adapters except control adapter will be
#                  disabled.
#               - If the device filter does not match e1000/vlance/vmxnet2/
#                 vmxnet3/e1000e/all, then all adapters except control
#                 adapter will be disabled.
#
########################################################################

sub GetAdapters
{
   # input parameters (ipaddress, device filter and adapters count)
   my ($controlIP, $filterOnDev, $adaptersCount) = @_;
   my $filterOnDevice = lc $filterOnDev;
   my @allAdapters;
   my $discardDownAdapters = FALSE;        # indicates whether adapters that
                                           # are down should be returned or not

   unless (defined $controlIP) {
      $vdLogger->Error("The control ip address has not been passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   #
   # Default $adaptersCount to 1 if it is not defined
   # If the given filter is a mac address, then assign $adaptersCount equal to
   # 1. If the given filter is "all", then assign 'undef' to $adaptersCount.
   #
   $adaptersCount = (defined $adaptersCount) ? $adaptersCount : 1;
   if ($filterOnDevice =~ /:|-/) {
      $adaptersCount = 1;
   } elsif ($filterOnDevice =~ /all/i) {
      $adaptersCount = undef;
   }

   if ($filterOnDevice ne "") {
      $vdLogger->Debug("Filter on Device: $filterOnDevice");
   }

   @allAdapters = DiscoverAdapters($controlIP, $discardDownAdapters);

   if ($allAdapters[0] eq "FAILURE") {
      $vdLogger->Error("getAdaptersHash failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Call ApplyFilter only when <device filter> parameter value is defined
   if ($filterOnDevice ne "") {
      unless (my @filteredHash = _ApplyFilter(\@allAdapters, $filterOnDev,
                                              $controlIP, OSTYPE,
                                              $adaptersCount))
      {
         $vdLogger->Error("Apply filter failed");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      # Sleep to make sure the devices enabled/disabled are
      # at the right state before calling adapterHash
      sleep(5);

      $vdLogger->Debug("Adapter List after applying filter");
      $discardDownAdapters = TRUE;      # do not include adapters that are
                                        # disabled in the final array of hashes

      @allAdapters = DiscoverAdapters($controlIP, $discardDownAdapters);

      if ($allAdapters[0] eq "FAILURE") {
         $vdLogger->Error("getAdaptersHash failed");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      #
      # Make sure when device filter is used, number of test adapters returned
      # is same as what is expected ($adaptersCount).
      #
      $vdLogger->Debug("Number of adapters:" . scalar @allAdapters);
      if ((defined $adaptersCount && scalar @allAdapters < $adaptersCount) ||
         (scalar @allAdapters < 1)) {
         $vdLogger->Error("Number of adapters found " . scalar @allAdapters .
                          " is less than requested $adaptersCount");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
   $vdLogger->Trace("Adapter list" . Dumper(@allAdapters));
   return \@allAdapters;  # Always reference to array/hash/array of hashes
                          # is returned from any exported module in this package
}


########################################################################
#
# GetAdapterStats -
#       Function that returns the stats (ethtool -S <interface>) of the
#       specific adapter, it writes these stats to file and copies
#       the file to log directory.
#
# Input:
#   controlIP - IP address of a control adapter (required)
#   adapter   - Name of the adapter.
#
# Results:
#   On Success returns the stats for the adapter.
#   On Failure returns FAILRURE.
#
########################################################################

sub GetAdapterStats
{
   my $adapter = shift;
   my $command;
   my $stdout;

   if (not defined $adapter) {
      $vdLogger->Error("Name of the adapter not specifed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # run the command based on the OS type.
   if (OSTYPE == OS_LINUX) {
      $command = "ethtool -S $adapter";
   } else {
      $vdLogger->Error("OS not supported");
      VDSetLastError("ENOTSUP");
      return SUCCESS;
   }
   $stdout = `$command 2>&1`;
   if (not defined $stdout) {
      $vdLogger->Error("Failed to get stats for $adapter");
      VDSetLastError("EFAIL");
      return FAILURE;
   } else {
      return \$stdout;
   }
}

########################################################################
#
# GetAdapterEEPROMDump --
#       Function that returns the EEPROM dump of the specific
#       interface.
#
# Input:
#   controlIP - IP address of a control adapter (required)
#   adapter   - Name of the adapter.
#
# Results:
#   On Success returns the EEPROM Dump of the adapter.
#   On Failure returns FAILRURE.
#
########################################################################

sub GetAdapterEEPROMDump
{
   my $adapter = shift;
   my $command;
   my $stdout;

   if (not defined $adapter) {
      $vdLogger->Error("Name of the adapter not specifed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # run the command based on the OS type.
   if (OSTYPE == OS_LINUX) {
      $command = "ethtool -e $adapter";
   } else {
      $vdLogger->Error("OS not supported");
      VDSetLastError("ENOTSUP");
      return SUCCESS;
   }
   $stdout = `$command`;
   if (not defined $stdout) {
      $vdLogger->Error("Failed to get stats for $adapter");
      VDSetLastError("EFAIL");
      return FAILURE;
   } else {
      return \$stdout;
   }
}


########################################################################
#
# GetAdapterRegisterDump --
#       Function that returns the Register dump of the specific
#       interface.
#
# Input:
#   controlIP - IP address of a control adapter (required)
#   adapter   - Name of the adapter.
#
# Results:
#   On Success returns the Register dump for the adapter.
#   On Failure returns FAILRURE.
#
########################################################################

sub GetRegisterDump
{
   my $adapter = shift;
   my $command;
   my $stdout;

   if (not defined $adapter) {
      $vdLogger->Error("Name of the adapter not specifed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # run the command based on the OS type.
   if (OSTYPE == OS_LINUX) {
      $command = "ethtool -d $adapter";
   } else {
      $vdLogger->Error("OS type not supported");
      VDSetLastError("ENOTSUP");
      return SUCCESS;
   }
   $stdout = `$command`;
   if (not defined $stdout) {
      $vdLogger->Error("Failed to get stats for $adapter");
      VDSetLastError("EFAIL");
      return FAILURE;
   } else {
      # Below regexp substitution is to avoid STAF data marshall error
      # Received 7
      $stdout =~ s/\ set//gi;
      return \$stdout;
   }
}


########################################################################
#
# GetNetworkConfig
#       Function that returns the network config of the VM (ipconfig
#       or ifconfig)
#
# Input:
#   controlIP - IP address of a control adapter (required)
#
# Results:
#   On Success returns the networking config for the vm.
#   On Failure returns FAILRURE.
#
########################################################################

sub GetNetworkConfig
{
   my $command;
   my $stdout;

   # run the command based on the OS type.
  # if (OSTYPE == OS_LINUX) {
  #    $command = "ifconfig -a";
  # } elsif(OSTYPE == OS_WINDOWS) {
  #    $command = "ipconfig \/all";
  # }
   $command = "esxcli network nic list";
   $stdout = `$command`;
   if (not defined $stdout) {
      $vdLogger->Error("Failed to get the network config");
      VDSetLastError("EFAIL");
      return FAILURE;
   } else {
      # Below regexp substitution is to avoid STAF data marshall error
      # Received 7
      $stdout =~ s/\ \://g;
      return \$stdout;
   }
}


########################################################################
#
# GetRouteConfig
#       Function that returns the Route config of the VM (route -n
#       or route PRINT)
#
# Input:
#      controlIP - IP address of a control adapter (required)
#
# Results:
#        On Success returns the route config of the vm.
#        On Failure returns FAILRURE.
#
########################################################################

sub GetRouteConfig
{
   my $command;
   my $stdout;

   # run the command based on the OS type.
   if (OSTYPE == OS_LINUX) {
      $command = "route -n";
   } elsif(OSTYPE == OS_WINDOWS) {
      $command = "route PRINT";
   }
   $stdout = `$command`;
   if (not defined $stdout) {
      $vdLogger->Error("Failed to get the network config");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   } else {
      return \$stdout;
   }
}


########################################################################
#
# _ApplyFilter --
#       This sub-routine enables (if adapter was disabled) one data
#       type adapter specified and disables all other adapters except
#       the control adapter.
#       Then the complete adapters list with the changed configuration will
#       be retrieved again from the machine specified in <target machine>.
#
# Input:
#       ApplyFilter(<adapterList>, <filter>, <target machine>, <ostype>,
#                   <adaptersCount>)
#               - <adapterList> is the reference to an array of hashes
#                 which has the list of adapters and its properties
#               - <filter> : device name (vmxnet3/vmxnet2/e1000/e1000e
#                                         /vlance)
#                            or mac address or "all";
#
#               - <targetMachine> is the control IP address
#               - <ostype> : 1 for linux, 2 for windows
#               - <adaptersCount> : number of adapters to discover.
#
# Results:
#       An array of hashes which has the list of adapters and
#       their properties after configuration changes
#       (enable/disable) are made.
#
# Side effects:
#       Same as GetAdapters()
#
########################################################################

sub _ApplyFilter($$$$$)
{
   my $adaptersList   = shift;   # reference to an array of hashes (Required)
   my $filterOnDevice = shift;   # filter to apply on adapterList (Required)
   my $controlIP      = shift;   # target machine (Required)
   my $ostype         = shift;   # 1 for linux, 2 for windows (Required)
   my $adaptersCount  = shift;   # number of test adapters to return (Required)
   my $enabledDataNicCount = 0;  # Initialize # of data type adapters enabled to
                                 # zero
   my $adapter;
   my $resultString;
   my $filterKey;

   foreach $adapter (@{$adaptersList}) {

      my $interface = $adapter->{'interface'};
      if ($adapter->{'nicType'} !~ /data/i) {
         next;
      }

      if ($filterOnDevice =~ /:|-/) { # mac address is given as filter
         #
         # The given mac filter might have hyphens instead on semi-colon, so
         # replacing it with semi-colon to maintain consistency.
         #
         $filterOnDevice =~ s/-/:/g;
         if ($ostype eq OS_WINDOWS) {
            #
            # In case of windows, macAddress of an adapter is undefined if it
            # is in the disabled state. If the filter passed is a mac address,
            # then it is important to enable every adapter and check if it's
            # mac address is same as the filter. Otherwise, adapter discovery
            # would not detect the adapter.
            #
            $resultString = _DeviceFlapping($controlIP, $ostype,
                                            $interface, "ENABLE");
            if ($resultString eq "FAILURE") {
               $vdLogger->Error("Failed to change interface state");
               VDSetLastError(VDGetLastError());
            }
         }
         # Find the mac address after enabling the adapter
         $filterKey = &GetMACAddress($adapter->{'interface'});
         if ($filterKey eq FAILURE) {
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         # GetMACAddress() returns reference to scalar variable,
         # so de-reference it.
         #
         $filterKey = ${&GetMACAddress($adapter->{'interface'})};
      } else { # device name is given as filter
         $filterKey = $adapter->{'name'};
      }

      #
      # Now match the given filter with appropriate adapter property.
      # If the filter is device name, then filterKey is $adapter->{'name'}.
      # If the filter is mac address, then filterKey is adapter's mac address.
      # Based on the filterKey, check if the corresponding value of the
      # adapter matches, if yes, and the number of test adapters selected
      # already is within $adaptersCount, then include the adapter to the list
      # of test adapters. If the filter is "all" instead of device name and
      # mac address, then include all data adapters in the list of test
      # adapters.
      #
      if (((defined $filterKey && defined $filterOnDevice) &&
           (lc($filterKey) eq lc($filterOnDevice)) &&
           ($enabledDataNicCount < $adaptersCount)) ||
          ($filterOnDevice =~ /all/i)) {
         if ($adapter->{'adminstate'} =~ /DOWN/i) {#if adapter is disabled
            $vdLogger->Debug("Enabling " . $adapter->{'nicType'} .
                             " interface $interface on $controlIP");
            #
            # Enable the data type adapter that matches
            # the filter if it was disabled and count is less than expected
            # or enable all adapters if the filter is 'all'.
            #

            $resultString = _DeviceFlapping($controlIP, $ostype,
                                            $interface, "ENABLE");

            if ($resultString eq "FAILURE") {
               $vdLogger->Error("Failed to change interface state");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
         }
         $enabledDataNicCount++; # increment the count of test adapters
      } else {
         if ($adapter->{'adminstate'} !~ /DOWN/i) {  #if adapter is enabled
            $vdLogger->Debug("Disabling " . $adapter->{'nicType'} .
                             " interface $interface on $controlIP");
            #
            # Disable all adapters that do not match the filter and
            # if the filter matches and the # of data adapters that matches
            # the filter is greater than or equal to $adaptersCount,
            # then disable them as well.
            #
            $resultString = _DeviceFlapping($controlIP, $ostype,
                                            $interface, "DISABLE");

            if ($resultString eq "FAILURE") {
                $vdLogger->Error("Failed to change interface state");
                VDSetLastError(VDGetLastError());
                return FAILURE;
            }
         }
      }
   } # end of all adapters
   return SUCCESS;
}


########################################################################
#
# DeviceFlapping --
#       Sub-routine to enable or disable an network adapter on a machine
#
# Input:
#       _DeviceFlapping(<target IP>, <os type>, <interface to disable>,
#       <enable/disable>)
#       Interface is ethx for linux machines and hardware id for windows
# Return value:
#       0 if success; "deviceFlapError" if fails
#
# Side effects:
#       None
#
########################################################################

sub _DeviceFlapping($$$$) {

   my $target = shift;
   my $ostype = shift;
   my $interface = shift;
   my $flapOperation = shift;
   my $command;
   my $result;

   $vdLogger->Debug("Device flap sub-routine called with target: $target, " .
          "ostype:$ostype, interface name:$interface, flap operation: " .
          "$flapOperation");
   if ((not defined $ostype) ||
      (not defined $interface) ||
      (not defined $flapOperation)) {
      $vdLogger->Error("Insufficient parameters");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # Throw error if the flap operation is anything other than ENABLE or DISABLE
   if (($flapOperation !~ /ENABLE/i) &&
      ($flapOperation !~ /DISABLE/i)) {
      $vdLogger->Error("Invalid operation requested");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ($ostype == OS_LINUX || $ostype == OS_MAC) {
      if ($flapOperation =~ /ENABLE/i) {
         $command = 'ifconfig ' . $interface . ' up';
      } else {
         $command = 'ifconfig ' . $interface . ' down';
      }
      my $stdout = `$command 2>&1`;

      if ($stdout =~ m/No such device/i) {
         VDSetLastError("ENODEV");
         return FAILURE;
      }
   } elsif ($ostype == OS_WINDOWS) {
      # Use netsh command to do enable/disable operation
      $result = NetshEnableDisable($interface, $flapOperation);
      if ($result eq FAILURE) {
         $vdLogger->Warn("Error performing $flapOperation on $interface " .
                         "using netsh, trying devcon");
         VDSetLastError(VDGetLastError());
         # netsh command to enable/disable network adapter does not work on
         # windows xp sp1 guests. So, devcon is used in case if netsh fails
         #
         $result = DevconEnableDisable($interface, $flapOperation);
         if ($result eq FAILURE) {
            $vdLogger->Error("Error performing $flapOperation on $interface " .
                          "using devcon");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $vdLogger->Debug("Reset the adapter using devcon");
         VDCleanErrorStack();
      }
   }

   sleep(5);  # just to make sure the device operation is complete
   $result = &GetDeviceStatus($interface);

   if ((($result =~ /UP/i) && ($flapOperation =~ /Enable/i)) ||
      (($result =~ /DOWN/i) && ($flapOperation =~ /Disable/i))) {
      return SUCCESS;
   } else {
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }
}


########################################################################
#
# DiscoverAdapters --
#       This is wrapper function which calls a discover function based on the
#       OS.
#
# Input:
#       Control IP address and discardDownAdapters flag
#
# Results:
#       If successful, an array of references to hash with each hash containing
#       information about an adapter. In case of failure, -1 is returned
#
# Side effects:
#       None
#
########################################################################

sub DiscoverAdapters
{
   my $controlIP = shift;
   my $discardDownAdapters = shift;
   my @allAdapters;

   if ((not defined $controlIP) ||
       (not defined $discardDownAdapters)) {
      $vdLogger->Error("Invalid parameters");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (OSTYPE == OS_LINUX) {
      @allAdapters = DiscoverLinux($controlIP, $discardDownAdapters);
   } elsif (OSTYPE == OS_WINDOWS) {
      @allAdapters = DiscoverWindows($controlIP, $discardDownAdapters);
   } elsif(OSTYPE == OS_MAC) {
      @allAdapters = DiscoverMac($controlIP, $discardDownAdapters);
   } elsif(OSTYPE == OS_BSD) {
      @allAdapters = DiscoverMac($controlIP, $discardDownAdapters);
   } else {
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }

   if ($allAdapters[0] eq "FAILURE") {
      $vdLogger->Error("getAdaptersHash failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return @allAdapters;
}


########################################################################
#
# DiscoverMac --
#       Given the control IP address, this module returns the list of
#       adapters on a mac based machine. When 'discardDownAdapters' flag
#       is set, then adapters that are not in enabled state are not
#       returned
#
# Input:
#       Control IP address and discardDownAdapters flag
#
# Results:
#       If successful, an array of references to hash with each hash containing
#       information about an adapter. In case of failure, -1 is returned
#
# Side effects:
#       None
#
########################################################################

sub DiscoverMac($$)
{
   my $controlIP = shift;
   my $discardDownAdapters = shift;
   my @ifindex;
   my @result = ();
   my @resultStr = ();

   if (not defined $controlIP) {
      $vdLogger->Error("Control adapter's IP address not specified");
      VDSetLastError("EINVALID");
      return FAILURE;
   } if (not defined $discardDownAdapters) {
      $vdLogger->Error("Adapter not specified");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   #
   # Adding the control interface as an interface to the access
   # the default gateway. This is required because, if control ip was
   # not part of default route, then, any enabling/disabling adapters
   # that was originally the default interface would cause network
   # connectivity issues.
   #

   $vdLogger->Info("Adding $controlIP as default interface");

   # Not returning FAILURE for any error in UpdateDefaultGW(),
   # calling it as best effort approach to solve classic linux problem.
   # Run 'ifconfig' command to determine the list of adapters
   @resultStr = `ifconfig -a`;
   if (@resultStr < 0) {
      $vdLogger->Error("Executing ifconfig command failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   #Compute the number of adapters based on ifconfig output
   @ifindex = ();
   for (my $i = 0; $i < scalar @resultStr - 1; $i++) {
      $resultStr[$i] =~ /\w*\d:\s/i;
      if (defined ($resultStr[$i])) {
         if ($resultStr[$i] =~ /\s*flags/i) {
            my @tempArray = split(' ', $resultStr[$i]);
            my @interface = split(':', $tempArray[0]);
            push (@ifindex, $interface[0]);
         }
      }
   }

   # Get a block per interface
   for (my $k = 0; $k < scalar @ifindex ; $k++) {
      my $interface;
      my $deviceName;
      my $ipv4 = 'NULL';
      my $macAddress = 'NULL';
      my $adminState = 'DOWN';
      my $hwid = 'NULL';

      $interface = $ifindex[$k];
      if ($interface =~ /en|em/i) {
         # Get adapter's driver name
         $deviceName = &GetDriverName($interface);

         if ($deviceName eq FAILURE) {
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         # Get adapter's IPv4 address
         $ipv4 = &GetIPv4($interface);
         if ($ipv4 eq FAILURE) {
            $vdLogger->Error("Error returned while retrieving IPv4 address");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         # Get adapter's mac address
         $macAddress = &GetMACAddress($interface);

         if ($macAddress eq FAILURE) {
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         # Get adapter's state (UP or DOWN)
         $adminState = &GetDeviceStatus($interface);
         if ($adminState eq FAILURE) {
            $vdLogger->Error("Error returned while retrieving device status");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         # If the adapter's IP address is not the given control IP,
         # then mark the adapter's type as 'data'
         # De-referencing ipv4 below is very important
         my $nictype = ($controlIP ne $$ipv4) ? "data" : "control";

         # Generate a hash for each adapter
         my  %resultHash =
            ( interface  => $interface, name => $$deviceName,
              macAddress => $$macAddress, ipv4 => $$ipv4,
              adminstate => $adminState, hwid => 'NULL',
              nicType => $nictype, controlIP => $controlIP,
            );

         # Push the hash that has configuration details about one adapter
         # into an array.
         # The final array of all hashes will be returned from this
         # sub-routine.
         if (($discardDownAdapters == 0) ||
             (($discardDownAdapters == 1) && ($adminState =~ /up/i))) {
            if ($controlIP ne $$ipv4) {    # ignore control adapter
               push (@result, \%resultHash);
            }
         }
      }
   }
   if (defined $result[0]) {
      return @result;
   } else {
      $vdLogger->Debug("List of available adapters: \n" .
                       Dumper(GetNetworkConfig()));
      VDSetLastError("ENODEV");
      return FAILURE;
   }
}


########################################################################
#
# DiscoverLinux --
#       Given the control IP address, this module returns the list of adapters
# on a linux based machine. When 'discardDownAdapters' flag is set, then
# adapters that are not in enabled state are not returned
#
# Input:
#       Control IP address and discardDownAdapters flag
#
# Results:
#       If successful, an array of references to hash with each hash containing
#       information about an adapter. In case of failure, -1 is returned
#
# Side effects:
#       None
#
########################################################################

sub DiscoverLinux($$)
{
   my $controlIP = shift;
   my $discardDownAdapters = shift;
   my @ifindex;
   my @result = ();
   my @resultStr = ();

   if ((not defined $controlIP) ||
       (not defined $discardDownAdapters)) {
      $vdLogger->Error("Invalid parameters");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   #
   # Adding the control interface as an interface to the access
   # the default gateway. This is required because, if control ip was
   # not part of default route, then, any enabling/disabling adapters
   # that was originally the default interface would cause network
   # connectivity issues.
   #
   $vdLogger->Info("Adding $controlIP as default interface");

   #
   # Not returning FAILURE for any error in UpdateDefaultGW(),
   # calling it as best effort approach to solve classic linux problem.
   #
   UpdateDefaultGW($controlIP, "add");

   # Run 'ifconfig' command to determine the list of adapters
#   @resultStr = `ifconfig -a`;
  @resultStr = `esxcli network nic list`;
   if (@resultStr < 0) {
      $vdLogger->Error("Executing ifconfig command failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $vdLogger->Info("The result is: @resultStr");
   #Compute the number of adapters based on ifconfig output
   @ifindex = ("0");
   for (my $i = 0; $i < scalar @resultStr - 1; $i++) {
      $vdLogger->Info("The items are: $resultStr[$i]   +++++");
      $resultStr[$i] =~ s/\r|\n//g;
      if (defined ($resultStr[$i])) {
         if ($resultStr[$i] =~ /(^\w+)\s+Link encap/i) {
            push (@ifindex, $1);
         }
      }
   }

   # Get a block per interface
   for (my $k = 0; $k < scalar @ifindex - 1  ; $k++) {
      my $interface;
      my $deviceName;
      my $ipv4 = 'NULL';
      my $macAddress = 'NULL';
      my $adminState = 'DOWN';
      my $hwid = 'NULL';

      $interface = $ifindex[$k];
      if ($interface =~ /eth/i) {
         # Get adapter's driver name
         $deviceName = &GetDriverName($interface);

         if ($deviceName eq FAILURE) {
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         # Get adapter's IPv4 address
         $ipv4 = &GetIPv4($interface);
         if ($ipv4 eq FAILURE) {
            $vdLogger->Error("Error returned while retrieving IPv4 address");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         # Get adapter's mac address
         $macAddress = &GetMACAddress($interface);

         if ($macAddress eq FAILURE) {
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         # Get adapter's state (UP or DOWN)
         $adminState = &GetDeviceStatus($interface);
         if ($adminState eq FAILURE) {
            $vdLogger->Error("Error returned while retrieving device status");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         # If the adapter's IP address is not the given control IP,
         # then mark the adapter's type as 'data'
         # De-referencing ipv4 below is very important
         my $nictype = ($controlIP ne $$ipv4) ? "data" : "control";

         # Generate a hash for each adapter
         my  %resultHash =
            ( interface  => $interface, name => $$deviceName,
              macAddress => $$macAddress,  ipv4 => $$ipv4,
              adminstate => $adminState, hwid => 'NULL',
              nicType => $nictype, controlIP => $controlIP,
            );

         # Push the hash that has configuration details about one adapter
         # into an array.
         # The final array of all hashes will be returned from this
         # sub-routine.
         if (($discardDownAdapters == 0) ||
             (($discardDownAdapters == 1) && ($adminState =~ /up/i))) {
            if ($controlIP ne $$ipv4) {    # ignore control adapter
               # Kill the dhclient before running dhcp
               # for $interface becuase the if dhclient
               # is already running then the command
               # `dhclient -timeout 20 $interface &`
               # fails with this output:
               # [root@prome-mdt-dhcp24 ~]# dhclient eth5
               # dhclient(8354) is already running - exiting.
               # Also use system instead of back ticks
               my $dhclientprocess = `ps ax | grep \"dhclient $interface\"`;
               $dhclientprocess =~ s/^\s+//;
               my @pid = split(/ /, $dhclientprocess);
               # 1393058: Remove dhclient commands for all adapters as this may
               # cause IP address lost in template like rhel53_srv_32
#               if ((scalar(@pid) > 0) && ($pid[0] =~ /\d+/)) {
#                  $vdLogger->Debug("dhclient is already running with PID $pid[0]" .
#                                   "Trying a dhcp release in the foreground");
#                  system("dhclient -r $interface");
#               } else {
#                  $vdLogger->Debug("dhclient is not running" .
#                                   "Trying a dhcp release in the background");
#                  system("dhclient -r $interface &");
#               }
               # PR 1122263, set ifup before assigned Ip address from dhclient
               if (($adminState !~ /up/i) && (system("ifconfig $interface up") != 0)) {
                  $vdLogger->Error("ifup fails with error $?\n" . Dumper(%resultHash));
               }
#               system("dhclient $interface &");
            }
            push (@result, \%resultHash);
         }
      }
   }
   if (defined $result[0]) {
      return @result;
   } else {
      $vdLogger->Debug("List of available adapters: \n" .
                       Dumper(GetNetworkConfig()));
      VDSetLastError("ENODEV");
      return FAILURE;
   }
}


########################################################################
#
# GetDriverName --
#       This module returns driver information for an interface in a linux based
# machine
# Input;
#       Interface (eth0, eth1, ...) for which the driver details are required
#
# Results:
#       Name of the driver if passed. In case of failure, -1 is returned
#
# Side effects:
#       None
#
########################################################################

sub GetDriverName
{
   my ($interface) = shift;
   unless (defined $interface) {
      $vdLogger->Error("Invalid interface passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my %nicDesc;
   if (OSTYPE == OS_LINUX) {
      if ($interface =~ /(\w+)\.\d+/) { # check format <parentInterface>.<vlanId>
         #
         # if the interface is a vlan node, then on kernel versoin 2.6.32
         # ethtool does not give driver information. In that case, find the
         # parent node's driver name.
         #
         $interface = $1;
      }

      my $lspciOutput = `lspci`;
      if ($lspciOutput =~ /Virtio network device/i) {
         # Code for KVM VMs. We have to blindly rely on this data as ethtool -i ethx
         # is not working on KVM Guest i.e. virtio driver does not support ethtool
         # as of now. We can get rid of this code block when virtio starts supporting
         # ethtool
         my $deviceName = "virtio";
         return \$deviceName;
      }

      # %nicDesc has the values of device name and its corresponding vendor:device
      # ID
      %nicDesc = (
                  '1022:2000' => "flexible",
                  '15ad:0720' => "vmxnet2",
                  '15ad:07b0' => "vmxnet3",
                  '8086:100f' => "e1000",
                  '8086:10d3' => "e1000e",
                  '8086:10c6' => "ixgbe",
                  '8086:10c7' => "ixgbe",
                  '8086:10c8' => "ixgbe",
                  '8086:10db' => "ixgbe",
                  '8086:10dd' => "ixgbe",
                  '8086:10e1' => "ixgbe",
                  '8086:10ec' => "ixgbe",
                  '8086:10ed' => "ixgbe",
                  '8086:10f1' => "ixgbe",
                  '8086:10f4' => "ixgbe",
                  '8086:10f7' => "ixgbe",
                  '8086:10f8' => "ixgbe",
                  '8086:10f9' => "ixgbe",
                  '8086:10fb' => "ixgbe",
                  '8086:10fc' => "ixgbe",
                  '8086:1507' => "ixgbe",
                  '8086:1508' => "ixgbe",
                  '8086:150b' => "ixgbe",
                  '8086:1514' => "ixgbe",
                  '8086:1517' => "ixgbe",
                  '8086:151c' => "ixgbe",
                  '8086:1529' => "ixgbe",
                  '8086:154d' => "ixgbe",
                  '14e4:164f' => "bnx2x",
                  '14e4:164e' => "bnx2x",
                  '14e4:1650' => "bnx2x",
                  '14e4:1652' => "bnx2x",
                  '14e4:1662' => "bnx2x",
                  '14e4:1663' => "bnx2x",
		            '19a2:0710' => "be2net",
      );

      my $busNumber;
      my $busMapping;
      my $deviceName;
      my $vendorDeviceId;

      # Use 'ethtool -i' command to get driver info on linux
      my @result     = `ethtool -i $interface 2>/dev/null`;

      if (!scalar(@result)) {
         $deviceName = 'NULL';
      } elsif ($result[3] eq '') {
         $deviceName = 'NULL';
      } elsif ($result[3] =~ /bus-info:\s+(\S+)/) {
         $busNumber  = $1;
         $busNumber =~ s/\d\d\d\d://;
         $busMapping = `lspci -n | grep $busNumber`;
         chomp($busMapping);

      # Get Driver Name based on the vendor and device ID obtained from lspci
      # command. 0200 is the Class listed for Ethernet Controllers.
         if ($busMapping =~ /0200:\s+(\w+:\w+)/) {
            $vendorDeviceId = $1;
         }

         if (not defined $vendorDeviceId) {
            VDSetLastError("EINVAL");
            return FAILURE;
         }

         for my $key (keys %nicDesc) {
            my $value = $nicDesc{$key};
            if ($vendorDeviceId =~ m/$key/) {
               $deviceName = $value;
            }
         }
      }

      if ((defined $deviceName) && ($deviceName ne 'NULL')) {
         return \$deviceName;
      } else {
         $vdLogger->Error("No entry found for vendor id $vendorDeviceId");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   } elsif (OSTYPE == OS_WINDOWS) {

      %nicDesc = (
                  'ven_1022&dev_2000' => "vlance",
                  'ven_15ad&dev_0720' => "vmxnet2",
                  'ven_15ad&dev_07b0' => "vmxnet3",
                  'ven_8086&dev_100f' => "e1000",
                  'ven_8086&dev_10d3' => "e1000e",
                  'ven_8086&dev_10c6' => "ixgbe",
                  'ven_8086&dev_10c7' => "ixgbe",
                  'ven_8086&dev_10c8' => "ixgbe",
                  'ven_8086&dev_10db' => "ixgbe",
                  'ven_8086&dev_10dd' => "ixgbe",
                  'ven_8086&dev_10e1' => "ixgbe",
                  'ven_8086&dev_10ec' => "ixgbe",
                  'ven_8086&dev_10ed' => "ixgbe",
                  'ven_8086&dev_10f1' => "ixgbe",
                  'ven_8086&dev_10f4' => "ixgbe",
                  'ven_8086&dev_10f7' => "ixgbe",
                  'ven_8086&dev_10f8' => "ixgbe",
                  'ven_8086&dev_10f9' => "ixgbe",
                  'ven_8086&dev_10fb' => "ixgbe",
                  'ven_8086&dev_10fc' => "ixgbe",
                  'ven_8086&dev_1507' => "ixgbe",
                  'ven_8086&dev_1508' => "ixgbe",
                  'ven_8086&dev_150b' => "ixgbe",
                  'ven_8086&dev_1514' => "ixgbe",
                  'ven_8086&dev_1517' => "ixgbe",
                  'ven_8086&dev_151c' => "ixgbe",
                  'ven_8086&dev_1529' => "ixgbe",
                  '164f14e4' => "bnx2x",
                  '164e14e4' => "bnx2x",
                  '165014e4' => "bnx2x",
                  '165214e4' => "bnx2x",
                  '166214e4' => "bnx2x",
                  '166314e4' => "bnx2x",
		  'ven_19a2&dev_0710' => "be2net",

      );

      # In windows, netsh command is used to configure IP
      my $adapterObj = GetWin32NetworkConfigurationObj($interface);

      # Get the interfaceName for example, "Local Area Connection"
      # using Win32_NetworkAdapterConfiguration WMI class
      my $index = $adapterObj->{'Index'};
      my $interfaceName = &ReadWin32NetAdapter($index, "PNPDeviceID");

      if ($interfaceName eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      my $match;
      if ($interfaceName =~ /(VEN_\w+&DEV_\w+)/i) {
         $match = $1;
         $match = lc($match);

         if (defined $nicDesc{$match}) {
            return \$nicDesc{$match};
         } else {
            VDSetLastError("ENOTDEF");
            return FAILURE;
        }
      } elsif ($interfaceName =~ /&PCI_(\w+?)&SUBSYS_/i) {
           $match = $1;
           $match = lc($match);

           if (defined $nicDesc{$match}) {
              return \$nicDesc{$match};
           } else {
              VDSetLastError("ENOTDEF");
              return FAILURE;
           }
      } else {
            VDSetLastError("EINVALID");
            return FAILURE;
      }
   } elsif (OSTYPE == OS_MAC) {
      my $deviceName = 'NULL';
      %nicDesc = (
                  '1022:2000' => "vlance",
                  '15ad:0720' => "vmxnet2",
                  '15ad:07b0' => "vmxnet3",
                  '8086:100f' => "e1000",
                  '8086:10d3' => "e1000e",
                  '14e4:1684' => "e1000",
                 );
      my @result  = `system_profiler SPEthernetDataType`;
      my $vendorId = "";
      my $deviceId = "";
      for (my $i=0; $i<@result; $i++) {
         if($result[$i]=~ /Vendor/i && $result[$i]=~ /ID/i && !($result[$i] =~ /Subsystem/i)) {
            my @splitLine = split(':',$result[$i]);
            my @vendorIdArray = split('x',$splitLine[1]);
            $vendorId = $vendorIdArray[1];
            $vendorId =~ s/\r|\n//g;
         }
         if($result[$i]=~/Device/i && $result[$i]=~/ID/i && !($result[$i] =~ /Subsystem/i)) {
            my @splitLine = split(':',$result[$i]);
            my @deviceIdArray = split('x',$splitLine[1]);
            $deviceId = $deviceIdArray[1];
            $deviceId =~ s/\r|\n//g;
         }
      }
      my $match = $vendorId.':'.$deviceId;
      if (defined $nicDesc{$match}) {
         return \$nicDesc{$match};
      } else {
         VDSetLastError("ENOTDEF");
         return FAILURE;
     }
   } elsif (OSTYPE == OS_BSD){
      my $deviceName = 'NULL';
      %nicDesc = (
                  '1022:2000' => "vlance",
                  '15ad:0720' => "vmxnet2",
                  '15ad:07b0' => "vmxnet3",
                  '8086:100f' => "e1000",
                  '8086:10d3' => "e1000e",
                  '14e4:1684' => "e1000",
                  );
      my $result = `devinfo -v | grep $interface`;
      #
      # sample output of devinfo
      # devinfo -v | grep em1
      #   em1 pnpinfo vendor=0x8086 device=0x100f subvendor=0x15ad \
      #   subdevice=0x0750 class=0x020000 at slot=1 function=0 \
      #   handle=\_SB_.PCI0.P2P0.S2F0
      #
      my $vendorId = undef;
      my $deviceId = undef;
      if ($result =~ /$interface pnpinfo vendor=0x(.*)\sdevice=0x(.*)\ssubvendor/i) {
         $vendorId = $1;
         $deviceId = $2;
      }

      if ((not defined $vendorId) || (not defined $deviceId)) {
         $vdLogger->Error("Could not find driver info for $interface " .
                          "in $result");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      my $key = $vendorId . ":" . $deviceId;
      if (defined $nicDesc{$key}) {
         return \$nicDesc{$key};
      } else {
         $vdLogger->Error("No entry for the driver $key in nicDesc");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   } else {
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# DiscoverWindows --
#       Given the control IP address, this module returns the list of adapters
# on a Win32 based machine. When 'discardDownAdapters' flag is set, then
# adapters that are not in enabled state are not returned
#
# Input:
#       Control IP address and discardDownAdapters flag
#
# Results:
#       If successful, an array of references to hash with each hash containing
#       information about an adapter. In case of failure, -1 is returned
#
# Side effects:
#       None
#
########################################################################

sub DiscoverWindows($$)
{
   my $controlIP = shift;
   my $discardDownAdapters = shift;
   use constant wbemFlagReturnImmediately => 0x10;
   use constant wbemFlagForwardOnly => 0x20;
   my $hostname = `hostname`;
   my $Host = uc($hostname);
   my $nicConfigStr = "SELECT * FROM Win32_NetworkAdapterConfiguration";
   chomp($Host);
   my $computer = ("$Host");
   my $nictype;

   unless (defined $controlIP) {
      $vdLogger->Error("Invalid Control IP passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $objWMIService =
      Win32::OLE->GetObject("winmgmts:\\\\$computer\\root\\CIMV2");

   unless ($objWMIService) {
      $vdLogger->Error("WMI connection failed.");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $colItems1 = $objWMIService->ExecQuery($nicConfigStr, "WQL",
                                             wbemFlagReturnImmediately |
                                             wbemFlagForwardOnly);
   my @activeNics = ();
   @activeNics = &ReadWin32NetAdapter;

   my @result = ();
   my ($mac, $interface, $adapter, @macadd);
   my @ipv4 = ();
   my $adminState;

   # Get adapter details like interface name, ip address, mac address etc.,
   # using the Win32::NetworkAdapter and Win32::NetAdapterConfiguration WMI
   # classes
   foreach my $objItem (in $colItems1) {
      for (my $id = 0; $id <= $#activeNics; $id++) {
         if ($activeNics[$id] eq $objItem->{Index}) {
            $mac = $objItem->{MacAddress};
            $mac =~ s/:/-/g if (defined $mac);

            # Network interface in windows is uniquely identified by GUID
            # which is obtained using Win32_NetworkAdapterConfiguration
            $interface = $objItem->{SettingID};

            if (not defined $interface) {
               VDSetLastError("EINVALID");
               return FAILURE;
            }

            my $description = $objItem->{Description};
            @macadd = $objItem->{MACAddress};
            @ipv4 = (in $objItem->{IPAddress});
            $ipv4[0] = "NULL" if (not defined $ipv4[0]);

            # correct status of the adapter is important when device filter is
            # used to enable/disable adapters
            $adminState = &GetDeviceStatus($interface);

            if ($adminState eq FAILURE) {
               $vdLogger->Error("Error returned while retrieving device status");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
            # Get Driver name
            my $adapterName = &GetDriverName($interface);

            if ($adapterName eq FAILURE) {
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }

            $adapterName = $$adapterName; # GetDriverName() returns a reference
                                          # to scalar
            my $hwid = &ReadWin32NetAdapter($objItem->{Index}, "PNPDeviceID");

            $nictype = 'data';
            foreach my $ip (@ipv4) {
               if ($controlIP eq $ip) {
                  $nictype = 'control';
               }
            }

            my $ndisVersion;
            if ($adminState =~ /UP/i) {
               # get the ndis version which works only if the device is UP
               $ndisVersion = &GetNDISVersion($interface);

               if ($ndisVersion eq FAILURE) {
                  $vdLogger->Debug("Failed to get ndis version of $interface" .
                                   " on $controlIP");
                  VDSetLastError(VDGetLastError());
                  return FAILURE;
               }
            }

            my  %resultHash =
               ( interface  => $interface, name => $adapterName,
                 macAddress => $macadd[0],  ipv4 => $ipv4[0],
                 adminstate => $adminState, hwid => $hwid,
                 nicType => $nictype, controlIP => $controlIP,
                 ndisVersion => $ndisVersion,
               );

            # Push the hash that has configuration details about one adapter
            # into the array. The final array of all hashes will be returned
            # from this sub-routine.
            if (($discardDownAdapters == 0) ||
                (($discardDownAdapters == 1) && ($adminState =~ /up/i))) {
               if ($controlIP ne $ipv4[0]) {    # ignore control adapter
                  push (@result, \%resultHash);
               }
            }
         } # end of if ($activeNics[$id] eq $objItem->{Index})
      } # end of activeNics loop
   }
   if (defined $result[0]) {
      return @result;
   } else {
      $vdLogger->Debug("List of available adapters: \n" .
                       Dumper(GetNetworkConfig()));
      VDSetLastError("ENODEV");
      return FAILURE;
   }
}


########################################################################
#
# ReadWin32Processor --
#       The sub-routine uses WMI Win32_Processor class to get details
#       about OS and processor
#
# Input:
#       ReadWin32NetAdapter(<index>, <key>)
#               The input parameters are mandatory
#               <key> - adapter property for which value is needed
#
# Results:
#       Return the configuration value of a specific property if the query
#       is successful otherwise returns FAILURE
#
# Side effects:
#       None
#
########################################################################

sub ReadWin32Processor
{
   my ($key) = @_;
   my $keyValue;

   if (not defined $key) {
      $vdLogger->Error("Invalid parameter passed:$!");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $hostname = `hostname`;
   my $Host = uc($hostname);
   chomp($Host);
   my @computers = ("$Host");

   my $objWMIService =
      Win32::OLE->GetObject("winmgmts:\\\\$Host\\root\\CIMV2");

   unless ($objWMIService) {
      $vdLogger->Error("WMI connection failed.");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $processorInfo = $objWMIService->InstancesOf("Win32_Processor");
   foreach my $cpu (in($processorInfo)) {
      $keyValue = $cpu->{$key};
      if (not defined $keyValue) {
         $vdLogger->Error("The key: $key is not valid");
         VDSetLastError("EINVALID");
         return FAILURE;
      } else {
         return $keyValue;
      }
   }
}


########################################################################
#
# ReadWin32NetAdapterConfigValue --
#       The sub-routine uses WMI Win32_NetworkAdapterConfiguration
#       classes to get details about a network adapter in Windows
#
# Input:
#       ReadWin32NetAdapter(<index>, <key>)
#               The input parameters are mandatory
#               <deviceID> - device ID of a network adapter
#               <key> - adapter property for which value is needed
#
# Results:
#       Return the configuration value of a specific property (key value
#       at the input) network adapter if the deviceID and key parameters
#       are passed. Otherwise, returns -1
#
# Side effects:
#       None
#
########################################################################

sub ReadWin32NetAdapterConfigValue
{
   my ($deviceID, $key) = @_;
   my $keyValue;

   if ((not defined $deviceID) || (not defined $key)) {
      $vdLogger->Error("Invalid parameter passed:$!");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Get an instance of WMI Win32_NetworkAdapterConfiguration class
   # that matched the interface/GUID given in the input
   my $nicStr = "SELECT * FROM Win32_NetworkAdapterConfiguration " .
      "where SettingID like \'$deviceID\'";
   my $hostname = `hostname`;
   my $Host = uc($hostname);
   my $colItems;
   chomp($Host);
   my @computers = ("$Host");

   my $objWMIService =
      Win32::OLE->GetObject("winmgmts:\\\\$Host\\root\\CIMV2");

   unless ($objWMIService) {
      $vdLogger->Error("WMI connection failed.");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   unless ($colItems =
      $objWMIService->ExecQuery($nicStr, "WQL",
                                wbemFlagReturnImmediately | wbemFlagForwardOnly))
   {
      $vdLogger->Error("Error Executing WMI query:$nicStr");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   foreach my $objItem (in $colItems) {
      $vdLogger->Debug("ActualDeviceID: " . Dumper($objItem->{SettingID}) . "");
      $vdLogger->Debug("input: " . Dumper($deviceID) . "");

      # Find the key value if the SettingID/GUID maches the given interface
      if ($objItem->{SettingID} eq $deviceID) {
         $keyValue = $objItem->{$key};
         last;
      }
   }
   if (not defined $keyValue) {
      $vdLogger->Warn("Failed to get $key value of $deviceID");
      return "NULL";
   } else {
      return $keyValue;
   }
}


########################################################################
#
# ReadWin32NetAdapter --
#       The sub-routine uses WMI Win32_NetworkAdapter classes to
#       get details about a network adapter in Windows
#
# Input:
#       ReadWin32NetAdapter(<index>, <key>)
#               The input parameters are optional
#               <index> - index value of a network adapter
#               <key> - adapter property for which value is needed
#
# Results:
#       Return the configuration value of a specific property (key value
#       at the input) network adapter if the index and key parameters
#       are passed. Otherwise, returns array of index values of all
#       network adapters in the host
#
# Side effects:
#       None
#
########################################################################

sub ReadWin32NetAdapter
{
   my ($index, $key) = @_;
   my @adaptersIndex = ();
   my $keyValue;
   my $nicStr = "SELECT * FROM Win32_NetworkAdapter where NetConnectionID " .
                "like \'\%Ethernet\%\'";

   #
   # The NetConnetionID on the windows 2003,2008,Windows 7 is "Local  *"
   # And on the Win7&Win2012  and the later version ,the NetConnetionID
   # is "Ethernet *". So make the diffrent string for $nicStr .

   my @osname = `systeminfo | findstr /C:"OS Name`;
   if ($osname[0] =~ /(Windows 7)|(200)/) {
     $nicStr = "SELECT * FROM Win32_NetworkAdapter where NetConnectionID " .
                "like \'\%Local\%\'";
   }

   my $hostname = `hostname`;
   my $Host = uc($hostname);
   chomp($Host);
   my @computers = ("$Host");

   if ((@_ != 0) && (@_ != 2)) {        # check if the number of arguments is
                                        # not equal to 0 or 2 i.e either both
                                        # index and key parameters should be
                                        # passed or none of them
      $vdLogger->Error("Index or Key value not specified");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (@_ == 2) {       # if number of args is 2, then verify both $index
                        # and $key values are defined
      if ((not defined $index) || (not defined $key)) {
         $vdLogger->Error("Invalid parameter passed:$!");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   }

   my $objWMIService =
       Win32::OLE->GetObject("winmgmts:\\\\$Host\\root\\CIMV2");
   unless ($objWMIService) {
      $vdLogger->Error("WMI connection failed.");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $colItems = $objWMIService->ExecQuery($nicStr, "WQL",
                                           wbemFlagReturnImmediately |
                                           wbemFlagForwardOnly);

   foreach my $objItem (in $colItems) {
      push (@adaptersIndex, $objItem->{Index});
      if ((defined $index) && ($objItem->{Index} eq $index)) {
         $keyValue = $objItem->{$key};
      }
   }

   if (not defined $index) {
      return @adaptersIndex;
   } elsif (defined $keyValue) {
      return $keyValue;
   } else {
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   return FAILURE;
}


########################################################################
#
# GetDeviceStatus --
#       This module returns the adapter's status 'enabled or disabled'
#
# Input:
#       Interface (ethx - in case of linux; device id in case of windows)
#
# Results:
#       "UP", if the device is enabled
#       "DOWN", if the device is disabled
#       -1, in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetDeviceStatus($) {
   my $interface = shift;
   my $deviceStatus;
   unless (defined $interface) {
      $vdLogger->Error("Invalid argument passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (OSTYPE == OS_LINUX) {
     # Look for "UP" in the ifconfig output
     my $result = ReadIfConfig($interface, "status");

     if ($result eq FAILURE) {
        VDSetLastError(VDGetLastError());
        return FAILURE;
     }

     return ($result eq "UP") ? "UP" : "DOWN";
   } elsif (OSTYPE == OS_WINDOWS) {
      my $np = new VDNetLib::Common::GlobalConfig;
      # Get the default test binaries path from VDNetLib::Common::GlobalConfig.pm
      my $testCodePath = $np->BinariesPath(OSTYPE);
      my $arch;
      # Determine if the OS is 32 or 64 bit
      my $command;
      $arch = &ReadWin32Processor("AddressWidth");
      if ($arch eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      if ($arch =~ m/32/i) {
         $arch = "x86_32";
      } elsif ($arch =~ /64/i) {
         $arch = "x86_64";
      } else {
         $vdLogger->Error("Error finding processor architecture:$command");
         VDSetLastError("EINVALID");
         return FAILURE;
      }

      my $path = "$testCodePath" . "$arch\\\\windows\\\\" . 'devcon.exe';

      my $index = &ReadWin32NetAdapterConfigValue($interface,
                                                  "Index");
      if ($index eq FAILURE || $index eq "NULL") {
         $vdLogger->Error("invalid Index returned");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      my $hwid = &ReadWin32NetAdapter($index, "PNPDeviceID");

      if ($hwid eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      $command = "$path " . "status " . "\"\@$hwid\"";
      $vdLogger->Debug("Executing command:$command");
      $deviceStatus = `$command`;

      if ($deviceStatus =~ /running/i) {
         return "UP";
      } elsif ($deviceStatus =~ /disabled/i) {
         return "DOWN";
      } else {
         $vdLogger->Error("Device Status:$deviceStatus");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   } elsif ((OSTYPE == OS_MAC) || (OSTYPE == OS_BSD)){
      # Look for "status" in the ifconfig output
      my $result = ReadMacOSIfConfig($interface, "status");
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      return ($result eq "active") ? "UP" : "DOWN";
   } else {
      $vdLogger->Error("OS NOTSUPPORTED");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# SetDeviceStatus --
#       This module changes the adapter's status 'enabled or disabled' based on
#       the input 'UP' or 'DOWN'
#
# Input:
#       <Interface> (ethx - in case of linux; device id in case of windows)
#       <action> ('UP' to enable, 'DOWN' to disable the device)
#
# Results:
#       "SUCCESS", if the action requested is successful
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub SetDeviceStatus
{
   my $interface = shift;
   my $action = shift;
   my $result;

   if ((not defined $interface) ||
       (not defined $action)) {
      $vdLogger->Error("Insufficent arguments passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # make sure the action parameter is either 'UP' or 'DOWN'
   if (($action !~ /UP/i) &&
       ($action !~ /DOWN/i)) {
      $vdLogger->Error("Invalid action requested");
      VDSetLastError("EINVALID");
      return FAILURE;
   } elsif ($action =~ /UP/i) {
      $action = "ENABLE"; # Equivalent string for UP in DeviceFlapping is
                          # 'ENABLE' and for 'DOWN', it is 'DISABLE'
   } elsif ($action =~ /DOWN/i) {
      $action = "DISABLE";
   }

   # call DeviceFlapping() to do the requested operation
   $result = _DeviceFlapping('local', OSTYPE,
                              $interface, $action);

   if ($result eq FAILURE) {
      $vdLogger->Error("Error returned while device status change is performed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # DeviceFlapping() takes care of verifying whether the requested action is
   # performed successfully using GetDeviceStatus()
   return SUCCESS;
}


########################################################################
#
# GetMTU --
#       This function returns the adapter's MTU size
#
# Input:
#       Interface (ethx - in case of linux; device id in case of windows)
#
# Results:
#       MTU value, if success
#       -1, in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetMTU($) {
   my $interface = shift;
   my $mtu;
   unless (defined $interface) {
      $vdLogger->Error("Invalid argument passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (OSTYPE == OS_LINUX) {

      # using ifconfig output to get the MTU size
      return \&ReadIfConfig($interface, "mtu");
   } elsif (OSTYPE == OS_WINDOWS) {

      # query OID_GEN_MAXIMUM_FRAME_SIZE using deviceIO control
      $mtu = GetOIDValue($interface,
                         OID_GEN_MAXIMUM_FRAME_SIZE);
      if (($mtu eq "FAILURE") || (not defined $mtu)) {
         $vdLogger->Info("Invalid MTU value returned");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         $mtu = hex($mtu); # getOIDValue returns hex value, convert it to
                           # decimal
         return \$mtu;
      }
   } elsif (OSTYPE == OS_MAC) {

      # using ifconfig output to get MTU size
      return \&ReadMacOSIfConfig ($interface, "mtu");
   } else {
      $vdLogger->Error("OS NOTSUPPORTED");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# SetMTU --
#       This function sets the user specified MTU value to an adapter
#
# Input:
#       Interface (ethx - in case of linux; device id in case of windows)
#
# Results:
#       "SUCCESS", if given mtu is set successfully
#       "FAILURE", in case of error
#
# Side effects:
#       Resets the device. Details like IP address might go invalid if IP
#       address is obtained automatically using DHCP
#
########################################################################

sub SetMTU($$)
{
   my ($interface, $mtuValue) = @_;
   unless ((defined $interface) && (defined $mtuValue)) {
      $vdLogger->Info("Invalid arguments called");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Check if the MTU size is within 0-16111
   # The end value is 16111 because, e1000 supports max of 16110
   # on Linux
   if ($mtuValue =~ /^(\d\d?\d?\d?\d?)$/) {
      if (($1 < 0) || ($1 > 16111)) {
         $vdLogger->Error("MTU size out of range");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   } else {
         $vdLogger->Error("Invalid MTU size");
         VDSetLastError("EINVALID");
         return FAILURE;
   }

   $vdLogger->Debug("calling mtuset with $interface and $mtuValue");

   # The ifconfig functionality for Mac OS and Linus is similar and hence they are
   # incorporated into the same if block.
   if (OSTYPE == OS_LINUX || OSTYPE == OS_MAC) {
      my $command = "/sbin/ifconfig " . $interface . " " . "mtu " . $mtuValue;
      my $result = `$command`;

      if ($result ne '') {
         $vdLogger->Error("MTU set error:$result");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $vdLogger->Info("executing command:$command,result: $result");
   } elsif (OSTYPE == OS_WINDOWS)   {
      my $mtuString;
      my $tempString = InterfaceRegistryKey($interface);

      my $interfaceKey = $Registry->{$tempString};

      unless (defined $interfaceKey) {
         $vdLogger->Error("Can't find the Windows Registry interfaceKey");
         VDSetLastError("ENOENT");
         return FAILURE;
      }

      # find from registry the correct string to use to set MaximumFrameSize
      if ($interfaceKey->{"Ndi\\Params\\MaxFrameSize"}) {
         $mtuString = "MTU";
      } elsif ($interfaceKey->{"Ndi\\params\\MTU"}) {
         $mtuString = "MTU";
      } elsif ($interfaceKey->{"Ndi\\Params\\*JumboPacket"}) {
         $mtuString = "*JumboPacket";
      } elsif ($interfaceKey->{"PROSetNdi\\Params\\MaxFrameSize"}) {
         $mtuString = "MaxFrameSize";
      } else {
         $vdLogger->Error("Could not find MTU key in the supported params");
         VDSetLastError("ENOENT");
         return FAILURE;
      }

      # setting the MTU size here
      $interfaceKey->{"$mtuString"} = [$mtuValue, "REG_SZ"];

   # The device has to be reset in order for the MTU changed value to be
   # effective
   my $resultString = DeviceReset($interface);
   if ($resultString eq "FAILURE") {
      $vdLogger->Error("Failed to change interface $$interface state");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}

   # Verify if the MTU value has actually been set to the right value.
   # MTU values on windows drivers depend on the enum values. For example,
   # to MTU size 1500 on e1000, the value to write in the registry is 1514.
   #
   my $getMTUValue = GetMTU($interface); # reference to MTU value is returned
   if ((int($$getMTUValue) < (int($mtuValue) - 14)) ||
       (int($$getMTUValue) > (int($mtuValue) + 14))) {
      $vdLogger->Error("SET mtu:$mtuValue and GET MTU value:$$getMTUValue " .
                   "are different");
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetIPv4 --
#       This function gets the IPv4 address of a given adapter
#
# Input:
#       Interface (ethx - in case of linux; device id in case of windows)
#
# Results:
#       string that contains IPv4 address, if success
#       -1, in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetIPv4($)
{
   my $interface = shift;
   my $ipAddr;

   unless (defined $interface) {
      $vdLogger->Error("Invalid Argument passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (OSTYPE == OS_LINUX) {
      # Using ifconfig output to get IP address on linux machines
      return \&ReadIfConfig($interface, "ipv4");
   } elsif (OSTYPE == OS_WINDOWS) {
      # Using Win32::NetworkAdapterConfiguration WMI class to get ipv4 address
      # on windows
      $ipAddr = ReadWin32NetAdapterConfigValue($interface, "IPAddress");
      if (FAILURE eq $ipAddr || "NULL" eq $ipAddr){
         $vdLogger->Error("Invalid IP address returned");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         my @derefArray = @$ipAddr;
         return \$derefArray[0];
      }
   } elsif (OSTYPE == OS_MAC){
      # Using ifconfig output to get IP address on mac machines
      return \&ReadMacOSIfConfig($interface, "ipv4");
   } elsif (OSTYPE == OS_BSD){
      # Using ifconfig output to get IP address on mac machines
      return \&ReadMacOSIfConfig($interface, "ipv4");
   } else {
      $vdLogger->Error("OS NOT SUPPORTED");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# GetOIDValue --
#       This function queries the OID values of a device using deviceIO control
#
# Input:
#       Interface (ethx - in case of linux; device id in case of windows)
#       OID string to query
#
# Results:
#       value of the OID string, if success
#       -1, in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetOIDValue($$)
{

   # Importing the NDIS I/O control codes:
   # Here 0x17 is the device type value for Network Adapters,
   # 2 refers to  'METHOD_OUT_DIRECT', value for transfer type
   # For more information on Device IO control codes, refer to
   # http://msdn.microsoft.com/en-us/library/ms795909.aspx
   # http://msdn.microsoft.com/en-us/library/aa914767.aspx

   sub IOCTL_NDIS_QUERY_GLOBAL_STATS () { 0x17 << 16 | 2 };

   my $deviceID = shift;
   my $oid = shift;

   unless ((defined $deviceID) &&
           (defined $oid)) {
      $vdLogger->Info("Invalid parameters");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # A file handle is opened using the device interface/GUID provided
   my $handle = CreateFile("\\\\.\\$deviceID", GENERIC_READ()|GENERIC_WRITE(),
                          FILE_SHARE_READ(), [], OPEN_EXISTING(), 0, [] );

   if (INVALID_HANDLE == $handle) {
      $vdLogger->Error("Create Handle failed: $^E");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $lOutBuf;
   my $olRetBytes;
   my $pOverlapped;
   my $nBytes = 0;
   my $buf = "\0"x10;
   my $oidp = pack("L", $oid);

   # DeviceIoControl will fail if the device is in disabled state
   # The device status is checked and error ENETDOWN (closest error code) is
   # returned if the device is down
   my $result = &GetDeviceStatus($deviceID);

   if ($result =~ /DOWN/i) {
      VDSetLastError("ENETDOWN");
      return FAILURE;
   }
   # DeviceIoControl() exported export Win32API is used to read the device
   # configuration for the OIDs provided as input
   if (!DeviceIoControl($handle,
                        IOCTL_NDIS_QUERY_GLOBAL_STATS(),
                        $oidp, length($oidp),
                        $buf, length($buf),
                        $nBytes,
                        [])) {
      $vdLogger->Error("DeviceIOControl Failed:$^E");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   if(!CloseHandle($handle)) {
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   if($nBytes > 0) {
      $buf = unpack("h*", $buf); # return in hex format to be common and useful
                                 # for all OID queries used in NetDiscover.pm
      $buf = reverse $buf;       # for some reason, the OID query returns in
                                 # reverse order, so converting back to normal
      return $buf;
   } else {
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


########################################################################
#
# ReadIfConfig --
#       This function is used on linux based systems to get adapter properties
#       like ip address, mac address, mtu size, subnet mask, device status,
#       ipv6 address from the 'ifconfig' command output
#
# Input:
#       Interface (for example, eth0, eth1, ...)
#       Property to query using ifconfig command
#
# Results:
#       value of the property/config value queried, if success
#       -1, in case of error
#
# Side effects:
#       None
#
########################################################################

sub ReadIfConfig($$)
{
   my $interface = shift;
   my $key = shift;
   my $searchString;

   unless ((defined $interface) && (defined $key)) {
      $vdLogger->Error("Invalid interface passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my @ifindex = ();
   my @resultStr = `ifconfig $interface`;
   if ($resultStr[0] =~ /error/i) {
      $vdLogger->Error("Executing ifconfig command failed, error:$resultStr[0]");
      VDSetLastError("EINVALCMD");
      return FAILURE;
   }

   # escape each escape character (\), otherwise all \ will be removed
   if ($key =~ /ipv4/i) {
      $searchString = "inet\\s+addr:(\\S+)";
   } elsif ($key =~ /broadcast/i) {
      $searchString = "\\s*Bcast:(\\S+)";
   } elsif ($key =~ /mtu/i) {
      $searchString = "\\s*MTU:(\\S+)";
   } elsif ($key =~ /subnet/i) {
      $searchString = "\\s*Mask:(\\S+)";
   } elsif ($key =~ /macAddress/i) {
      $searchString = "\\s*HWaddr\\s+(\\S+)";
   } elsif ($key =~ /ipv6Global/i) {
      $searchString = "inet6\\s+addr:\\s*(\\S+)\\s+Scope:Global";
   } elsif ($key =~ /ipv6Link/i) {
      $searchString = "inet6\\s+addr:\\s*(\\S+)\\s+Scope:Link";
   } elsif ($key =~ /status/i) {
      $searchString = "(UP)";
   } else {
      $vdLogger->Error("Key not supported by ReadifConfig module");
      VDSetLastError("ENOENT");
      return FAILURE;
   }

   unless (defined $searchString) {
      $vdLogger->Error("Unable to find the search string");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   #
   # Parse the ifconfig output to read the configured value of the network
   # interface
   # Sample ifconfig output
   # eth0      Link encap:Ethernet  HWaddr 00:1D:09:0E:90:B5
   #           inet addr:10.20.84.51  Bcast:10.20.87.255  Mask:255.255.252.0
   #           inet6 addr: fc00:10:20:87:21d:9ff:fe0e:90b5/64 Scope:Global
   #           inet6 addr: fe80::21d:9ff:fe0e:90b5/64 Scope:Link
   #           UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
   #           RX packets:139169671 errors:0 dropped:0 overruns:0 frame:0
   #           TX packets:129037186 errors:0 dropped:0 overruns:0 carrier:0
   #           collisions:0 txqueuelen:1000
   #           RX bytes:3333952357 (3.1 GiB) TX bytes:2470937444 (2.3 GiB)
   #           Interrupt:17
   #
   @ifindex = ("0");
   my @resultArr;
   for (my $i = 0; $i < scalar @resultStr; $i++) {
      $resultStr[$i] =~ s/\r|\n//g;
      if($resultStr[$i] =~ /Link encap/) {
         my @tempArray  = split(/ /, $resultStr[$i]);
         my $tempInterface  = $tempArray[0];
         # Make sure that the ifconfig output being read is really of the given
         # interface
         if ($interface ne $tempInterface) {
            $vdLogger->Error("Reading a wrong interface config");
            VDSetLastError("ENODEV");
            return FAILURE;
         }
      }
      if ($resultStr[$i] =~ /$searchString/) {
         push(@resultArr, $1);
      }
   }
   # There could one or more ipv6 addresses for a given adapter, so a change
   # has been made on 08.05.2009 to return array of ipv6 addresses than just
   # one. For other key values, only the first element of the array is returned
   # to avoid any regression. TODO - for ipv4 address
   if (scalar(@resultArr) > 0) {
      if (($key =~ /ipv6Link/i) || ($key =~ /ipv6Global/i)) {
         return @resultArr;
      } else {
         return $resultArr[0]
      }
   } else {
      $vdLogger->Debug("Executing command \"ifconfig $interface\" returns " .
                   Dumper(@resultStr));
      return "NULL";
   }
}


########################################################################
#
# ReadMacOSIfConfig --
#       This function is used on mac based systems to get adapter properties
#       like ip address, mac address, mtu size, subnet mask, device status,
#       ipv6 address from the 'ifconfig' command output
#
# Input:
#       Interface (for example, en0, en1, ...)
#       Property to query using ifconfig command
#
# Results:
#       value of the property/config value queried, if success
#       -1, in case of error
#
# Side effects:
#       None
#
########################################################################

sub ReadMacOSIfConfig($$)
{
   my $interface = shift;
   my $key = shift;
   my $searchString;

   unless ((defined $interface) && (defined $key)) {
      $vdLogger->Error("Invalid interface passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my @ifindex = ();
   my @resultStr = `ifconfig $interface`;
   if ($resultStr[0] =~ /error/i) {
      $vdLogger->Error("Executing ifconfig command failed, error:$resultStr[0]");
      VDSetLastError("EINVALCMD");
      return FAILURE;
   }

   # escape each escape character (\), otherwise all \ will be removed
   if ($key =~ /ipv4/i) {
      $searchString = "inet\\s(\\S+)";
   } elsif ($key =~ /broadcast/i) {
      $searchString = "\\s*broadcast\\s(\\S+)";
   } elsif ($key =~ /mtu/i) {
      $searchString = "\\s*mtu\\s(\\S+)";
   } elsif ($key =~ /subnet/i) {
      $searchString = "\\s*netmask\\s(\\S+)";
   } elsif ($key =~ /macAddress/i) {
      $searchString = "ether\\s+(\\S+)";
   } elsif ($key =~ /ipv6Global/i) {
      $searchString = "inet6\\s*(\\S+)\\s";
   } elsif ($key =~ /ipv6Link/i) {
      $searchString = "inet6\\s*(\\S+)\\s";
   } elsif ($key =~ /status/i) {
      $searchString = "status:\\s*(\\S+)";
   } else {
      $vdLogger->Error("Key $$key not supported by ReadifConfig module");
      VDSetLastError("ENOENT");
      return FAILURE;
   }

   unless (defined $searchString) {
      $vdLogger->Error("Unable to find the search string $$searchString");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   #
   # Parse the ifconfig output to read the configured value of the network
   # interface
   # Sample ifconfig output
   # en0: flags=8963<UP,BROADCAST,SMART,RUNNING,PROMISC,SIMPLEX,MULTICAST> mtu 1500
   # ether 10:9a:dd:62:1a:c6
   # inet6 fe80::129a:ddff:fe62:1ac6%en0 prefixlen 64 scopeid 0x4
   # inet6 fc00:10:20:132:129a:ddff:fe62:1ac6 prefixlen 64 autoconf
   # inet6 fc00:10:20:133:129a:ddff:fe62:1ac6 prefixlen 64 autoconf
   # inet6 fc00:10:20:134:129a:ddff:fe62:1ac6 prefixlen 64 autoconf
   # inet6 fc00:10:20:135:129a:ddff:fe62:1ac6 prefixlen 64 autoconf
   # inet 10.20.132.120 netmask 0xfffffc00 broadcast 10.20.135.255
   # media: autoselect (1000baseT <full-duplex,flow-control>)
   # status: active


   #
   @ifindex = ("0");
   my @resultArr;
   for (my $i = 0; $i < scalar @resultStr; $i++) {
      $resultStr[$i] =~ s/\r|\n//g;
      if($resultStr[$i] =~ /Link encap/) {
         my @tempArray  = split(/ /, $resultStr[$i]);
         my $tempInterface  = $tempArray[0];
         # Make sure that the ifconfig output being read is really of the given
         # interface
         if ($interface ne $tempInterface) {
            $vdLogger->Error("Reading a wrong interface config than the expected
                             $$interface interface");
            VDSetLastError("ENODEV");
            return FAILURE;
         }
      }
      if ($resultStr[$i] =~ /$searchString/) {
         push(@resultArr, $1);
      }
   }
   # There could one or more ipv6 addresses for a given adapter, so a change
   # has been made on 08.05.2009 to return array of ipv6 addresses than just
   # one. For other key values, only the first element of the array is returned
   # to avoid any regression. TODO - for ipv4 address
   if (scalar(@resultArr) > 0) {
      if (($key =~ /ipv6Link/i) || ($key =~ /ipv6Global/i)) {
         return @resultArr;
      } else {
         return $resultArr[0]
      }
   } else {
      return "NULL";
   }
}


########################################################################
#
# GetVLANDetailsForMac --
#       This function returns the VLAN id on the given interface
#
# Input:
#       Interface (en in Mac) and vlanId (vlan<id> in Mac)
#
# Results:
#       VLAN tag number of the interface, if success
#        0, if no VLAN is configured on the given interface
#       FAILURE, in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetVLANDetailsForMac ($$) {
   my ($interface, $vlanId) = @_;

   if (OSTYPE!=OS_MAC) {
      $vdLogger->Error("OS NOT SUPPORTED");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }

   if (not defined $interface) {
      $vdLogger->Error("invalid parameter passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # In Mac, read the output of networksetup -listVLANs to read the vlan configuration
   # Sample output for "networksetup -listVLANs"
   #
   # VLAN User Defined Name: vlan80
   # Parent Device: en0
   # Device ("Hardware" Port): vlan0
   # Tag: 1
   #
   # VLAN User Defined Name: vlan23
   # Parent Device: en0
   # Device ("Hardware" Port): vlan1
   # Tag: 3
   #
   my @cmd = `networksetup -listVLANs`;
   if(not defined $cmd[0]) {
      $vdLogger->Info("No VLAN configured on this machine");
      return \"0"; # zero indicates no VLAN configured
   } elsif ($cmd[0] =~ /No/i) {
      $vdLogger->Info("No VLAN configured on this machine");
      return \"0"; # zero indicates no VLAN configured
   }

   # This function will return an array of hash of details about all the
   # vlans configured for the interface passed as a parameter.
   my @adapterArray = ();

   for (my $i=1; $i<scalar(@cmd); $i=$i+5) {
      my @splitInterfaceArray = split(":",$cmd[$i+1]);
      my $newInterface = $splitInterfaceArray[@splitInterfaceArray - 1];
      $newInterface =~ s/^\s+|\s+$//g;
      if ($cmd[$i]=~m/VLAN/i && $newInterface eq $interface) {
         my @splitTagArray = split(":",$cmd[$i+3]);
         my $tag = $splitTagArray[@splitTagArray - 1];
         $tag =~ s/^\s+|\s+$//g;
         my @splitDeviceName = split(":",$cmd[$i+2]);
         my $vlanName = $splitDeviceName[@splitDeviceName - 1];
         $vlanName =~ s/^\s+|\s+$//g;
         my @splitUserDefined = split(":",$cmd[$i]);
         my $userDefName = $splitUserDefined[@splitUserDefined - 1];
         $userDefName =~ s/^\s+|\s+$//g;
         my %adapterHash = (
            'interface' => $newInterface,
            'tag' => $tag,
            'name' => $vlanName,
            'userDefName' => $userDefName,
         );
         push(@adapterArray, \%adapterHash);
      }
   }
   return @adapterArray;
}

########################################################################
#
# GetVLANId --
#       This function returns the VLAN id on the given interface
#
# Input:
#       Interface (ethx in linux, device GUID in windows)
#
# Results:
#       VLAN id of the interface, if success
#        0, if no VLAN is configured on the given interface
#       FAILURE, in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetVLANId($)
{
   my $interface = shift;

   if (not defined $interface) {
      $vdLogger->Error("invalid parameter passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $vdLogger->Info("Get VLAN id for $interface");
   if (OSTYPE == OS_LINUX) {
      if ($interface =~ /(\w+)\.\d+/) { # check format <parentInterface>.<vlanId>
         #
         # if the interface is a vlan node, then get vlan makes sense for the
         # parent interface.
         #
         $interface = $1;
         $vdLogger->Info("Parent index $interface");
      }
      # In linux, read /proc/net/vlan/config to read the vlan configuration
      my @cmd = `cat /proc/net/vlan/config`;
      if (not defined $cmd[0]) {
         $vdLogger->Info("No VLAN configured on this machine");
         return \"0"; # zero indicates no VLAN configured
      }

      for (my $i=0; $i < scalar(@cmd); $i++) {
         $cmd[$i] =~ s/\r|\n//g;   # Remove all carriage returns and new line

         #config file has 2 lines information about the format of the file
         if(($cmd[$i] !~ /vlan/i) || ($cmd[$i] !~ /Name/i)) {
            $cmd[$i] =~ s/\s//g;   # Remove spaces in each line
            my ($devname ,$vlanId, $baseDev) = split(/\|/,$cmd[$i]);
            return \$vlanId if ($baseDev eq $interface);
         }
      }
      $vdLogger->Error("No VLAN configured for $interface");
      return \"0";
   } elsif (OSTYPE == OS_WINDOWS) {
      my $vlanId = &GetOIDValue($interface, OID_GEN_VLAN_ID);

      if ($vlanId eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vlanId = hex($vlanId); # convert the hex to decimal before returning
      return \$vlanId;
   } elsif (OSTYPE == OS_MAC) {

      # In Mac, read the output of networksetup -listVLANs to read the vlan configuration
      #
      # VLAN User Defined Name: vlan0
      # Parent Device: en0
      # Device ("Hardware" Port): vlan0
      # Tag: 1
      #

      my @cmd = `networksetup -listVLANs`;
      if(not defined $cmd[0])
      {
         $vdLogger->Info("No VLAN configured on this machine");
         return \"0"; # zero indicates no VLAN configured
      } elsif ($cmd[0] =~ /No/i) {
         $vdLogger->Info("No VLAN configured on this machine");
         return \"0"; # zero indicates no VLAN configured
      }

      for (my $i=scalar(@cmd) - 1; $i >= 0; $i--) {
         # Remove all carriage returns and new line
         $cmd[$i] =~ s/\r|\n//g;
         # config file has 2 lines information about the format of the file
         if(($cmd[$i] =~ /Parent/i) && ($cmd[$i] =~ /Device/i)) {
            my @splitLine = split(':', $cmd[$i]);
            $splitLine[1] =~ s/^\s+|\s+$//g;
            if($splitLine[1] eq $interface)
            {
               $i--;
               if(($cmd[$i] =~ /Defined/i) && ($cmd[$i] =~ /Name/i)) {
                  my @tempString  = split(':', $cmd[$i]);
                  my $vlanId = $tempString[1];
                   $vlanId =~ s/^\s+|\s+$//g;
                  return \$vlanId;
               }
            }
         }
      }
      return \ "0";
   } else {
      $vdLogger->Error("OS NOT SUPPORTED");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# SetVLAN --
#       This function Sets/Creates a vlan interface with the given vlan id
#       on the given interface
#
# Input:
#       Interface (ethx in linux, device GUID in windows)
#       VLAN Id (1 - 4095 is the range)
#       staticIP : ip address
#       netmask: mask to specify correct subnet
#       tag: provided as a parameter in the Mac OS networksetup
#            command to identify the vlans in an interface uniquely.
#
# Results:
#       New interface (ethx in linux, GUID in windows), if success
#       "FAILURE", in case of error
#
# Side effects:
#       Since the device has to reset once, the IP details might changed if it
#       was configured using DHCP.
#       In Linux, the IP address of the parent interface is changed to 0.0.0.1
#       to avoid the parent interface being used for testing
#
########################################################################

sub SetVLAN
{
   #Here a tag number is also included as an extra parameter for Mac
   my ($interface, $vlanID, $staticIP, $netmask, $tag, $gateway) = @_;
   my $vlanInterface;

   if ((not defined $interface) ||
       (not defined $vlanID) ||
       (not defined $staticIP) ||
       (not defined $netmask)) {
      $vdLogger->Error("Invalid parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (OSTYPE == OS_LINUX) {
     $vlanInterface = $interface . "." . $vlanID; # update vlan interface name
                                                  # which is the concatenation
                                                  # of parent interface and the
                                                  # vlan id
   } else {
      $vlanInterface = $interface;
   }
   # Getting the vlan ID configured on the given interface and
   # if it is same as the vlan id given as input, then return here itself.
   my $getVlanID = GetVLANId($interface);
   if ((defined $getVlanID) && ($$getVlanID eq $vlanID)) {
      $vdLogger->Debug("get ($$getVlanID) and set ($vlanID) values are same");
      return $vlanInterface;
   }

   if (OSTYPE == OS_LINUX) {
      # Using vconfig command on linux to create a new vlan interface
      my $vconfigCmd = "vconfig add ";
      my $modProbe  = `modprobe 8021q`;
      my $upInterface = "ifconfig $interface up";

      if ($modProbe ne '') {
         $vdLogger->Error("Error:$modProbe");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      $vconfigCmd = $vconfigCmd . $interface . " " . $vlanID;
      $vconfigCmd = $upInterface . ";" . $vconfigCmd;
      my $result = system($vconfigCmd);

      if ($result) {
         $vdLogger->Error("vconfig execution failed");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

     # change vlan parent interface's ip to 0.0.0.1 to avoid this interface
     # being used for testing
     $result = SetIPv4($interface,
                       "0.0.0.1",
                       "255.0.0.0",
                       $gateway);

     if ("FAILURE" eq $result) {
        $vdLogger->Error("failed at setting IP");
        VDSetLastError(VDGetLastError());
        RemoveVLAN($interface); #check error?
        return $result;
     }

      # remove all the global ipv6 addresses on the parent interface
      my $ipv6Addr = GetIPv6Global($interface);
      if ($ipv6Addr ne FAILURE) {
         foreach my $addr (@$ipv6Addr) {
            my ($ip, $prefix) = split(/\//,$addr);
            if (defined $ip && defined $prefix) {
               $vdLogger->Debug("Removing ipv6 address $ip/$prefix from $interface");
               SetIPv6($interface, "delete", $ip, $prefix);
            }
         }
      }

   } elsif (OSTYPE == OS_WINDOWS) {
      # In windows, VLAN is configured using registry values on the given
      # interface itself. No child interface is created like in Linux machines
      my $vlanStatusString;
      my $tempString = InterfaceRegistryKey($interface);
      my $interfaceKey = $Registry->{$tempString};

      unless (defined $interfaceKey) {
         $vdLogger->Error("Can't find the Windows Registry interfaceKey");
         VDSetLastError("ENOENT");
         return FAILURE;
      }
      # TODO
      # VLAN on e1000 is not working if the default driver is used.
      # If PROEM64T.exe  downloaded from Intel site is used, the following
      # piece of code can be added. But commenting them now until a generic way
      # to set vlan on e1000 is determined
      # ($interfaceKey->{"DriverDesc"} =~ /Intel/i) {
      # $interfaceKey->{"VLANID"} = [$vlanID, "REG_MULTI_SZ"]; # for e1000
      # $interfaceKey->{"VlanMode"} = [pack('L', "1"), "REG_DWORD"];
      # $interfaceKey->{"TaggingMode"} = ["1", "REG_SZ"];
      #
      if ($interfaceKey->{"Ndi\\Params\\*PriorityVLANTag"}) {
         $vlanStatusString = "*PriorityVLANTag";
         #for vmxnet3,e1000e
         # value of 2 for the registry key *PriorityVLANTag represents
         # both priority tag and vlan will be enabled.
         #
         $interfaceKey->{"$vlanStatusString"} = ["2", "REG_SZ"];
         $interfaceKey->{"VlanId"} = [$vlanID, "REG_SZ"];
      } else {
         $vdLogger->Info("Operation Not Supported");
         VDSetLastError("ENOTSUP");
         return FAILURE;
      }

      # reset the device to make the changes effective
      my $result = DeviceReset($interface);

      if ($result eq FAILURE) {
         $vdLogger->Error("device reset failed");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      $vlanInterface = $interface; # update vlan interface same as the given
                                   # interface since no new interface is
                                   # created in windows for vlan
   } elsif (OSTYPE == OS_MAC) {
      # Since in the networksetup -createVLAN command in Mac, a tag number has to
      # be provided, we will be using an extra parameter tag to setup the VLAN
      if(not defined $tag) {
         $vdLogger->Error("Invalid parameters passed");
         VDSetLastError("EINVALID");
         return FAILURE
      }

      my $cmd = "networksetup -createVLAN $vlanID $interface $tag";
      my $resultStr = system($cmd);
      if(!$resultStr eq "") {
         $vdLogger->Error("networksetup -createVLAN execution failed");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

   } else {
      $vdLogger->Error("OS NOT SUPPORTED");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }

   # VLAN interface created will not work until its IP/mask is configured.
   # Using the given ip address, and netmask, the new interface is enabled
   my $result = SetIPv4($vlanInterface,
                       $staticIP,
                       $netmask,
                       $gateway);

   if (FAILURE eq $result) {
      $vdLogger->Error("failed at setting IP");
      VDSetLastError(VDGetLastError());
      RemoveVLAN($interface); #check error?
      return $result;
   }

   # Getting the vlan ID after resetting the interface and verified
   # if it is same as the vlan id given as input
   $getVlanID = GetVLANId($interface);

   if ($$getVlanID ne $vlanID) {
      $vdLogger->Error("get ($$getVlanID) and set ($vlanID) values differ");
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }
   return \$vlanInterface;
}


########################################################################
#
# RemoveVLAN --
#       This function deletes the VLAN configured on the given interface
#
# Input:
#       Interface (ethx in linux, device GUID in windows, en0 in mac)
#
# Results:
#       "SUCCESS", if success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub RemoveVLAN($)
{
   my $interface = shift;
   my $vlanID = '';
   my $baseInterface;

   if (not defined $interface) {
      $vdLogger->Error("Invalid parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ($interface =~ /(\\w)\.\\w/) {
      # Get the base interface from baseInterface.vlanID
      $baseInterface = $1;
   } else {
      $baseInterface = $interface;
   }

   if (OSTYPE == OS_LINUX) {
      # Using 'vconfig rem' command to delete the vlan interface in linux

      # First, the vlan id is obtained from the interface, then the interface
      # name is concatenated with vlan id
      my $vlanInterface = $interface;

      if ($interface !~ /\./) {
         $vlanID = GetVLANId($interface);

         if ($vlanID eq FAILURE) {
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $vlanInterface = "$interface.$$vlanID "; # dereference vlanID
      }

      my $vconfigCmd = "vconfig rem  $vlanInterface";
      my $result = `$vconfigCmd 2>&1`;

      if ($result =~ /error/i) {
         $vdLogger->Info("Failed to remove VLAN $vlanID from interface $interface");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      my $scriptName = "ifcfg-" . $vlanInterface;
      $result = system("rm -rf /etc/sysconfig/network-scripts/$scriptName");

      if ($result) {
         $vdLogger->Warn("Failed to remove $scriptName");
      }

   } elsif (OSTYPE == OS_WINDOWS) {
      # In windows, remove all the registry entries that correspond to vlan
      # configuration of the interface
      my $vlanStatusString;
      my $tempString = InterfaceRegistryKey($interface);
      my $interfaceKey = $Registry->{$tempString};

      unless (defined $interfaceKey) {
         $vdLogger->Error("Can't find the Windows Registry interfaceKey");
         VDSetLastError("ENOENT");
         return FAILURE;
      }

      if ($interfaceKey->{"Ndi\\Params\\*PriorityVLANTag"}) {
         $vlanStatusString = "*PriorityVLANTag";
         #for vmxnet3,e1000e
         $interfaceKey->{"$vlanStatusString"} = ["0", "REG_SZ"];
         $interfaceKey->{"VlanId"} = ["0", "REG_SZ"]; # O vlanid disables vlan
      } elsif ($interfaceKey->{"DriverDesc"} =~ /Intel/i) {
         $interfaceKey->{"VlanId"} = ["0", "REG_MULTI_SZ"]; # for e1000
         $interfaceKey->{"VlanMode"} = [pack('L', "0"), "REG_DWORD"];
         $interfaceKey->{"TaggingMode"} = ["0", "REG_SZ"];
      } else {
         $vdLogger->Error("Operation Not Supported");
         VDSetLastError("ENOTSUP");
         return FAILURE;
      }

      # reset the device to make the changes effective
      my $result = DeviceReset($interface);

      if ($result eq FAILURE) {
         $vdLogger->Error("device reset failed");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } elsif (OSTYPE == OS_MAC) {
      # In mac when using the networksetup command to delete a VLAN, the parent
      # interface name and the VLAN tag needs to be supplied. Since the user is
      # not supplying it as a command line argument, therefore, the following
      # code fetches the VLAN tag of the latest added VLAN.
      my @interfaceDetails = GetVLANDetailsForMac($interface, $vlanID);
      if (@interfaceDetails == 0) {
         $vdLogger->Error("No VLANs configure for the interface $interface");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my $hash = {};
      foreach $hash (@interfaceDetails) {
         $vlanID = $hash->{'name'};
         my $tagNo = $hash->{'tag'};
         my $cmd = "networksetup -deleteVLAN $vlanID $interface $tagNo";
         my $resultStr = system($cmd);
         if ($resultStr) {
            $vdLogger->Info("Failed to remove VLAN $hash->{'userDefName'} from
                            interface $interface");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      }
   } else {
      $vdLogger->Error("OS NOT Suppored");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
   # As static ip is configured in SetVLAN(), the adapter's ip must be reset
   # using dhcp
   if(EnableDHCP($interface) eq FAILURE) {
      $vdLogger->Error("failed to enable dhcp");
#      VDSetLastError(VDGetLastError());#TODO decide whether dhcp is always
#      good when removing vlan.
#      return FAILURE;
   }

   $vlanID = GetVLANId($baseInterface);

   if ($vlanID eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   } elsif ($$vlanID ne "0") { # if vlan ID is non-zero, return error
      VDSetLastError("EOPFAILED");
   } else {
      return SUCCESS;
   }
}


########################################################################
#
# SetIPv4 --
#       This function configures the IP address of the given interface
#
# Input:
#       interface (ethx in linux, device GUID in windows) (Required)
#       ipaddr - IP address to set (Required)
#       netmask - network mask to set (Required)
#
# Results:
#       0, if success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub SetIPv4
{  my ($interface, $ipaddr, $netmask, $gateway) = @_;
   my $ifconfigCmd;
   my $line;
   if ((not defined $interface) ||
      (not defined $ipaddr) ||
      (not defined $netmask)) {
      $vdLogger->Error("Invalid parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ($ipaddr =~ m/dhcp/i) {
      if(EnableDHCP($interface) eq FAILURE) {
         $vdLogger->Error("Failed to get IP via DHCP on $interface");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      if ($ipaddr !~ m/remove/i) {
         # Check the correctness of the given IP address
         if (CheckIPValidity($ipaddr) eq FAILURE) {
            $vdLogger->Error("Invalid IP address provided");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         # Check the correctness of the given netmask
         if (CheckIPValidity($netmask) eq FAILURE) {
            $vdLogger->Error("Invalid Netmask provided");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }

      if (OSTYPE == OS_LINUX || OSTYPE == OS_MAC) {
         # In linux, ifconfig command to is used to configure the ip address
         # of the interface
         if ($ipaddr =~ /remove/) {
            $ifconfigCmd = "//sbin//ifconfig $interface 0";
         } else {
            $ifconfigCmd = "//sbin//ifconfig $interface $ipaddr netmask " .
                           "$netmask up";
         }
         my $result = `$ifconfigCmd 2>&1`;

         if ($result ne '' ) {
            $vdLogger->Error("Result:$result");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
         if ($ipaddr =~ /remove/) {
            $line = "ifconfig $interface 0";
         } else {
            $line = "ifconfig $interface $ipaddr netmask " .
                       "$netmask up";
         }
         my $netScripts = EditToolsScripts($interface, $line);
         if ($netScripts eq FAILURE) {
            $vdLogger->Error("Error returned from EditToolsScripts");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         my $return = StaticIpFileEdit($interface, $ipaddr, $netmask);
         if ($return eq FAILURE) {
            $vdLogger->Warn("Error returned from StaticFileEdit , the OS version could be different");
         }

      } elsif (OSTYPE == OS_WINDOWS) {
         # In windows, netsh command is used to configure IP
         my $adapterObj = GetWin32NetworkConfigurationObj($interface);

         # Get the interfaceName for example, "Local Area Connection"
         # using Win32_NetworkAdapterConfiguration WMI class
         my $index = $adapterObj->{'Index'};
         my $interfaceName = &ReadWin32NetAdapter($index, "NetConnectionID");

         if ($interfaceName eq FAILURE) {
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }

         my $ipSetCommand = "netsh interface ip set address " .
                           "name=\"$interfaceName\" static $ipaddr $netmask";

         $vdLogger->Debug("executing $ipSetCommand");

         my $result = `$ipSetCommand 2>&1`;

         if (($result !~ /Ok/i) &&  # 'Ok'is not returned in pre-vista
            ($result =~ /\S+/)) {   # Empty space is returned in >= vista
            $vdLogger->Error("Error:$result returned");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      } else {
         $vdLogger->Error("OS NOT SUPPORTED");
         VDSetLastError("EOSNOTSUP");
         return FAILURE;
      }

      # verify to make sure the given ip details are set correctly
      my $getIPv4 = GetIPv4($interface);

      if ($getIPv4 eq FAILURE) {
         $vdLogger->Error("Error returned from GetIPv4");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Debug("The IPv4 address get is: ".Dumper($$getIPv4));
      if (($ipaddr =~ /remove/i) && ($$getIPv4 eq 'NULL')) {
          $vdLogger->Debug("Remove the IPv4 address successfully.");
          return SUCCESS;
      }
      if ($$getIPv4 ne $ipaddr) {
         $vdLogger->Error("Mismatch in IPv4 $$getIPv4 get and set $ipaddr value");
         VDSetLastError("EMISMATCH");
         return FAILURE;
      }
   }

   return SUCCESS;
}

########################################################################
#
# FileEditDHCP --
#       This function edits the network scripts file for dhcp
#
# Input:
#       interface : ethx in linux  (Required)
#
# Results:
#       "SUCCESS" , if the function is able to edit the dhcp config file
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub FileEditDHCP
{    my $interface = shift;
     my $file = "/etc/sysconfig/network-scripts/ifcfg-"."$interface";
     if (-e $file) {
         my $command = "rm -f " . $file;
         my $stdout = system($command);
         if ($stdout) {
            $vdLogger->Error("Execute remove file $command returned:". $stdout);
            VDSetLastError("EFAILED");
            return FAILURE;
         }
      }
      my $command = "touch " . $file;
      my $stdout = system($command);
      if ($stdout) {
          $vdLogger->Error("Execute touch command $command returned:". $stdout);
          VDSetLastError("EFAILED");
          return FAILURE;
      }
      $command = "chmod 777 " . $file;
      $stdout = system($command);
      if ($stdout) {
          $vdLogger->Error("Execute chmod command $command returned:". $stdout);
          VDSetLastError("EFAILED");
          return FAILURE;
       }
      my $macaddr = ${&GetMACAddress($interface)};
      my @lines = ();
      my $line = "DEVICE=".$interface;
      push @lines, $line;
      $line = "BOOTPROTO=dhcp";
      push @lines, $line;
      $line = "ONBOOT=yes";
      push @lines, $line;
      $line = "HWADDR=".$macaddr;
      push @lines, $line;
      foreach my $line (@lines) {
        my $arg = "$file"."\*"."'insert'"."\*"."$line"."\*"."$line";
        my $ret = VDNetLib::Common::Utilities::EditFile($arg);
      }
      return SUCCESS;
}

########################################################################
#
# StaticIpFileEdit --
#       This function edits the network scripts file for static ip
#
# Input:
#       interface : ethx in linux  (Required)
#       ipAddress : ip address to be set on interface ( Required)
#       netmask   : netmask (Required)
#
# Results:
#       "SUCCESS" , if the function is able to edit the dhcp config file
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub StaticIpFileEdit {
     my $interface = shift;
     my $ipAddress = shift;
     my $netmask = shift;
     my $macAddress = GetMACAddress($interface);
     if ($macAddress eq FAILURE) {
        $vdLogger->Error("GetMACAddress returned FAILURE.");
        VDSetLastError(VDGetLastError());
        return FAILURE;
     }
     my $baseScriptsDir = "/etc/sysconfig/network-scripts";
     my $file = "$baseScriptsDir/ifcfg-"."$interface";
     if (-d $baseScriptsDir) {
         my $command = undef;
         my $stdout = undef;
         if (-e $file) {
             $command = "rm -f ".$file;
             $stdout = system($command);
             if ($stdout) {
                $vdLogger->Error("Execute remove file $command returned:". $stdout);
                VDSetLastError("EFAILED");
                return FAILURE;
             }
         }
         $command = "touch ".$file;
         $stdout = system($command);
         if ($stdout) {
             $vdLogger->Error("Execute touch command $command returned:". $stdout);
             VDSetLastError("EFAILED");
             return FAILURE;
         }
         $command = "chmod 777 ". $file;
         $stdout = system($command);
         if ($stdout) {
             $vdLogger->Error("Execute chmod command $command returned:". $stdout);
             VDSetLastError("EFAILED");
             return FAILURE;
          }
         my @lines = ();
         my $line = "DEVICE=".$interface;
         push @lines, $line;
         if ($ipAddress !~ m/remove/i) {
            $line = "IPADDR=$ipAddress";
            push @lines, $line;
            $line = "NETMASK=$netmask";
            push @lines, $line;
         }
         $line = "ONBOOT=yes";
         push @lines, $line;
         $line = "HWADDR=$$macAddress";
         push @lines, $line;
         foreach my $line (@lines) {
           my $arg = "$file"."\*"."'insert'"."\*"."$line"."\*"."$line";
           my $ret = VDNetLib::Common::Utilities::EditFile($arg);
         }
      } else {
         $vdLogger->Warn("Unable to make the static IP persistent as IP " .
                         "scripts dir $baseScriptsDir does not exist on " .
                         "the host");
      }
      return SUCCESS;
   }

########################################################################
#
# EnableDHCP --
#       This function configures the network interface to use DHCP to get IP
#       address
#
# Input:
#       Interface (ethx in linux, device GUID in windows)
#
# Results:
#       0, if success
#       -1, in case of error
#
# Side effects:
#       Might affect the previous ip configuration
#
########################################################################

sub EnableDHCP($)
{  my $interface = shift;
   unless (defined $interface) {
      $vdLogger->Error("Invalid Parameter passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $result = undef;
   my $return_val = undef;
   if (OSTYPE == OS_LINUX) {
      my $dhclient_cmd = "dhclient $interface";
      my $dhclient_release_cmd = "dhclient -r $interface";
      # first release the IP
      $vdLogger->Trace("Releasing the IP address on $interface");
      $result = `$dhclient_release_cmd 2>&1`;
      # TODO(adityak/salmanm): Make a utility method for executing a system
      # command and logging the STDOUT/STDERR and return code.
      if ($? == -1)
      {
        $vdLogger->Warn("\'$dhclient_release_cmd\' failed with return code: $?, " .
                         "Output:\n$result");
      }
      my $dhcpDir = "/etc/sysconfig/network-scripts" ;
      if(! -d $dhcpDir) {
         $vdLogger->Debug("sysconfig directory is not present hence skipping enabling dhcp");
      }
      if(FileEditDHCP($interface) eq FAILURE) {
         $vdLogger->Warn("DHCP File Edit failed");
      }
      $vdLogger->Debug("Bring down the interface $interface");
      $result = `ifdown $interface`;
      sleep(5);
      $vdLogger->Debug("Bringing it up");
      $result = `ifup $interface`;
      sleep(5);
      $result = `ifconfig $interface`;
      if ($result !~ /UP /mi) {
         # Do not throw an error if the interface is not up as the DHCP Client
         # will initialize the interface and bring it up along with IP Address
         # assignment.
            $vdLogger->Warn("Unexpected output: $result");
      }
      $vdLogger->Trace("Running dhclient on $interface");
      # Now renew dhcp client
      $result = `$dhclient_cmd 2>&1`;
      if ($? == -1)
      {
        $vdLogger->Warn("Command \'$dhclient_cmd\'failed with return code: $?, " .
                         "Output:\n$result");
      }
      $return_val = SUCCESS;
   } elsif (OSTYPE == OS_WINDOWS) {
      # Using netsh command in windows to enable dhcp for an interface
      my $adapterObj = GetWin32NetworkConfigurationObj($interface);

      # Get the interfaceName for example, "Local Area Connection"
      # using Win32_NetworkAdapterConfiguration WMI class
      my $index = $adapterObj->{'Index'};
      my $interfaceName = &ReadWin32NetAdapter($index, "NetConnectionID");

      if ($interfaceName eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      my $ipSetCommand = "netsh interface ip set address " .
                         "name=\"$interfaceName\" source=dhcp";
      $vdLogger->Debug("executing $ipSetCommand");

      $result = `$ipSetCommand 2>&1`;

      if ($result =~ /""|Ok|already enabled/i) {
         $return_val = SUCCESS;
      } else {
         $vdLogger->Error("Error:$result returned");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   } elsif (OSTYPE == OS_MAC) {
      # command to cause an interface to get an IP address for the DHCP, for Mac
      $result = `ipconfig set $interface DHCP`;
      if (($result ne "") &&
         ($result !~ /already/i)) {
         $vdLogger->Error("Unexpected output: $result");
         VDSetLastError("EOPFAILEDL");
         return FAILURE;
      }
      $return_val = SUCCESS;
   } else {
      $vdLogger->Info("OS Not Supported");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
   # Verify IP address
   my $ipv4 = GetIPv4($interface);
   if ($$ipv4 eq FAILURE || $$ipv4 =~ /NULL/) {
         $vdLogger->Warn("Did not find any IP address on $interface after " .
                         "running dhclient");
   } else {
     $vdLogger->Debug("IP found on $interface after running dhclient is: " .
                      Dumper($$ipv4));
   }
   return $return_val;
}


########################################################################
#
# InterfaceRegistryKey --
#       This function returns the entire path to the interface's key variable
#       in windows registry. For example,
#       'LMachine\System\CurrentControlSet\Control\Class\
#        {4D36E972-E325-11CE-BFC1-08002BE10318}\$member\0001'
#
# Input:
#       Interface (ethx in linux, device GUID in windows)
#
# Results:
#       path to interface's key/member value in registry, if success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub InterfaceRegistryKey($)
{
   if (OSTYPE != OS_WINDOWS) {
      $vdLogger->Error("NOT APPLICABLE");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }

   my $interface = shift;
   if (not defined $interface) {
      $vdLogger->Error("Invalid parameter passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # {4D36E972-E325-11CE-BFC1-08002BE10318} is the class identifier
   # for network adapter
   my $netClassKey = $Registry->{"LMachine\\System\\CurrentControlSet\\" .
                    "Control\\Class\\{4D36E972-E325-11CE-BFC1-08002BE10318}\\"};
   unless (defined $netClassKey) {
      $vdLogger->Error("Can't find the Windows Registry interfaceKey");
      VDSetLastError("ENOENT");
      return FAILURE;
   }

   my @members = keys (% {$netClassKey});
      foreach my $member (@members) {
         $member =~ s/\\//;
         # checking if the NetCfgInstanceId is equal to the given interface
         # GUID
         my $interfaceKey = $netClassKey->{"$member\\NetCfgInstanceId"};

         if (defined $interfaceKey) {
            if ($interfaceKey =~ /$interface/i) {
               # return the maching key along with the entire path
               my $ret = "LMachine\\System\\CurrentControlSet\\Control\\Class\\" .
                       "{4D36E972-E325-11CE-BFC1-08002BE10318}\\$member\\";
               return $ret;
            }
         }

      }
      $vdLogger->Error("NOT VALID KEY");
      VDSetLastError("ENOENT");
      return FAILURE;
}


########################################################################
#
# DeviceReset --
#       This function resets the given interface
#
# Input:
#       Interface (ethx in linux, device GUID in windows)
#
# Results:
#       "SUCCESS", if success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub DeviceReset($)
{
   my $interface = shift;

   unless (defined $interface) {
      $vdLogger->Error("Invalid parameter passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # TODO skip disable operation by checking device status
   # First, call DeviceFlapping to disable the interface
   my $resultString = _DeviceFlapping('local', OSTYPE,
                                      $interface, "DISABLE");
   if ($resultString eq FAILURE) {
      $vdLogger->Error("Failed to change interface state");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   sleep(5);
   # call DeviceFlapping to enable the interface
   $resultString = _DeviceFlapping('local', OSTYPE,
                                   $interface, "ENABLE");
   if ($resultString eq FAILURE) {
      $vdLogger->Error("Failed to change interface state");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # sleep to make sure enabling the interface is complete
   sleep(5);
   return SUCCESS;
}


########################################################################
#
# GetWin32NetworkConfigurationObj --
#       This function returns an instance of Win32_NetworkAdapterConfiguration
#       WMI class which matches the given the interface GUID on windows
#
# Input:
#       Interface (ethx in linux, device GUID in windows)
#
# Results:
#        An object of Win32_NetworkAdapterConfiguration , if success
#       -1, in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetWin32NetworkConfigurationObj($)
{
   my $interface = shift;

   unless (defined $interface) {
      $vdLogger->Error("Invalid parameter passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # executing a query to get the Win32_NetworkAdapterConfiguration objects
   # whose SettingID value is equal to the given interface GUID
   my $nicStr = "SELECT * FROM Win32_NetworkAdapterConfiguration " .
      "where SettingID like \'$interface\'";
   my $hostname = `hostname`;
   my $Host = uc($hostname);
   my $colItems;
   chomp($Host);
   my @computers = ("$Host");

   my $objWMIService =
      Win32::OLE->GetObject("winmgmts:\\\\$Host\\root\\CIMV2");

   unless ($objWMIService) {
      $vdLogger->Error("WMI connection failed.");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   unless ($colItems =
      $objWMIService->ExecQuery($nicStr, "WQL",
                                wbemFlagReturnImmediately |
                                wbemFlagForwardOnly))
   {
      $vdLogger->Error("Error Executing WMI query:$nicStr");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # $colItems is expected to have only one item in its hash
   # since the query is executed to find only one unique device
   # that matches $interface
   foreach my $objItem (in $colItems) {
      return $objItem;
   }
   VDSetLastError("EINVAL");
   return FAILURE;
}


########################################################################
#
# GetInterfaceName -
#        Gives the interface name (example, "Local Area Connection #") for a
#        network adapter on windows. In linux or mac, there is no such name for an
#        adapter
#
# Input:
#        <interface> (ethx for linux, GUID of network adapter on windows)
#
# Results:
#        <InterfaceName>, if success
#        'FAILURE', in case of any error
#
# Side effects:
#        None
#
########################################################################

sub GetInterfaceName
{
   my $interface = shift;

   unless (defined $interface) {
      $vdLogger->Error("Invalid parameter passed");
      VDSetLastError("EINVALID");
   }
   # operation only supported on windows
   if (OSTYPE != OS_WINDOWS) {
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
   my $adapterObj = GetWin32NetworkConfigurationObj($interface);

   # Get the interfaceName for example, "Local Area Connection"
   # using Win32_NetworkAdapterConfiguration WMI class
   my $index = $adapterObj->{'Index'};
   my $interfaceName = &ReadWin32NetAdapter($index, "NetConnectionID");

   if ($interfaceName eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return \$interfaceName;
}


########################################################################
#
# GetOffload -
#        Gives the status (enabled or diabled) of offload operation provided
#        as input. On windows, IPV6 offload functions can be retrieved only if
#        IPv6 protocol is installed.
#
# Input:
#        <interface> (ethx in linux, GUID in case of windows
#        <param>
#        Any one of the following offload functions:
#        TSOIPv4, TCPTxChecksumIPv4, TCPRxChecksumIPv4,
#        UDPTxChecksumIPv4, UDPRxChecksumIPv4, TCPGiantIPv4, IPTxChecksum,
#        IPRxChecksum, TSOIPv6, TCPTxChecksumIPv6, TCPRxChecksumIPv6,
#        UDPTxChecksumIPv6, UDPRxChecksumIPv6, TCPGiantIPv6
#
# Results:
#        'Enabled', if the offload operation is enabled on the adapter
#        'Disabled', if the offload operation is disabled on the adapter
#        'FAILURE', in case of any error
#
# Side effects:
#        None
#
########################################################################

sub GetOffload
{
   my $interface = shift;  # Required
   my $param = shift;      # Required
   my $result;

   if ((not defined $interface) || (not defined $param)) {
      $vdLogger->Error("Invalid parameter passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (OSTYPE == OS_LINUX) {
      my $status;

      # ethtool -k|--show-offload <dev> command is used to get the offload
      # function status on linux. For the given interface, the offload
      # function is captured from the output of the ethtool command.
      # Therefore, the search string is common across different adapters
      # on linux. The input offload function string and corresponding
      # output string from ethtool are captured in the following hash
      my %offloadParams = (
         'tsoipv4' => 'tcp segmentation offload',
         'tcptxchecksumipv4' => 'tx-checksumming',
         'tcprxchecksumipv4' => 'rx-checksumming',
         'ufo' => 'udp fragmentation offload',
         'gso' => 'generic segmentation offload',
         'lro' => 'large receive offload',
         'sg' => 'scatter-gather',
         );

      if (not defined $offloadParams{$param}) {
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      #
      # Using short form -k instead of --show-ofload because older version of
      # ethtool supports only short form
      #
      $result = `ethtool -k $interface`;

      # The ouput from ethtool -k|--show-offload would look like:
      # tcp segmentation offload: on
      # tx-checksumming: off
      # rx-checksumming: on
      # udp fragmentation offload: on
      # generic segmentation offload: off
      # scatter-gather: on
      #
      # Look for on/off for the given offload function
      #

      #
      # The ethtool command output differs between linux kernel version 2.6.32
      # and earlier. Space between udp fragmentation offload and
      # "generic segmentation offload" are replace by hyphens. So, substituting
      # hyphens with spaces in both the offload parameter to search and ethtool
      # output as well
      #
      $offloadParams{$param} =~ s/-/ /g;
      $result =~ s/-/ /g;

      if ($result =~ /$offloadParams{$param}:\s+(\S+)/i) {
         $status = $1;
      } else {
         $vdLogger->Error("ethtool -k|--show-offload output:$result");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      # Return Enabled/Disabled if on/off is captured
      if ($status =~ /on/i) {
         return \"Enabled";
      } elsif ($status =~ /off/i) {
         return \"Disabled";
      } else {
         VDSetLastError("EINVALID");
         return FAILURE;
      }

   } elsif (OSTYPE == OS_WINDOWS) {

      # netsh interface ip/ipv6 show offload "interface name" is used to
      # get the offload function status on windows. For the given interface,
      # the offload function is captured from the output of the netsh command.
      # Therefore, the search string is common across different adapters
      # on windows. The input offload function string and corresponding
      # output string from netsh are captured in the following hash
      my %offloadParams = (
         'tsoipv4' => 'tcp large send',
         'tcptxchecksumipv4' => 'tcp transmit checksum',
         'tcprxchecksumipv4' => 'tcp receive checksum',
         'udptxchecksumipv4' => 'udp transmit checksum',
         'udprxchecksumipv4' => 'udp receive checksum',
         'tcpgiantipv4' => 'tcp giant send',
         'iptxchecksum' => 'ipv4 transmit checksum',
         'iprxchecksum' => 'ipv4 receive checksum',
         'tsoipv6' => 'tcp large send',
         'tcptxchecksumipv6' => 'tcp transmit checksum',
         'tcprxchecksumipv6' => 'tcp receive checksum',
         'udptxchecksumipv6' => 'udp transmit checksum',
         'udprxchecksumipv6' => 'udp receive checksum',
         'tcpgiantipv6' => 'tcp giant send',
         );

      if (not defined $offloadParams{$param}) {
         VDSetLastError("EINVALID");
         return FAILURE;
      }

      my $interfaceName = &GetInterfaceName($interface);

      if ($interfaceName eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      $interfaceName = $$interfaceName; # dereference scalar value returned

      if ($offloadParams{$param} =~ /IPv6/i) {
         $result = `netsh interface ipv6 show offload \"$interfaceName\"`;
      } else {
         $result = `netsh interface ip show offload \"$interfaceName\"`;
      }

      # netsh command for offload returns the value mentioned in %offloadParams
      # only if that particular offload operation is supported currently on the
      # given adapter
      if ($result =~ /$offloadParams{$param}/i) {
         return \"Enabled";
      } elsif (($result =~ /incorrect/i) || ($result =~ /invalid/i) ||
               ($result =~ /not/i)) {
         $vdLogger->Error("Operation failed:$result");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      } else {
         return \"Disabled";
      }
   } else {
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# SetOffload -
#        Enables/disables a offload operation provided as input
#        on the network adapter. On windows, IPv6 offload functions can be
#        performed only if IPv6 protocol is installed.
#
# Input:
#        <interface> (ethx for linux, GUID of network adapter for windows
#        <offloadFunction>
#        Any one of the following offload functions:
#        TSOIPv4, TCPTxChecksumIPv4, TCPRxChecksumIPv4,
#        UDPTxChecksumIPv4, UDPRxChecksumIPv4, TCPGiantIPv4, IPTxChecksum,
#        IPRxChecksum, TSOIPv6, TCPTxChecksumIPv6, TCPRxChecksumIPv6,
#        UDPTxChecksumIPv6, UDPRxChecksumIPv6, TCPGiantIPv6
#        <action>
#        'Enable', to enable the specified offload operation
#        'Disable', to disable the specified offload operation
#
# Results:
#        'SUCCESS', if the action on the specified offload operation
#           is successful on the adapter
#        'FAILURE', in case of any error
#
# Side effects:
#        None
#
########################################################################

sub SetOffload
{
   my $interface = shift;        # Required
   my $offloadFunction = shift;  # Required
   my $action = shift;           # Required

   if ((not defined $interface) ||
      (not defined $offloadFunction) ||
      (not defined $action)) {
      $vdLogger->Error("Invalid parameter passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (OSTYPE == OS_LINUX) {
      # ethtool -K|--offload <dev> command is used to set the offload
      # function on linux. For the given interface, the offload
      # function is set using the standard arguments of ethtool command
      # The command is common for any network adapter on linux.
      # The input offload function string for this sub-routine and
      # corresponding argument for ethtool command are captured in the
      # following hash

      my %offloadParams = (
         'tsoipv4' => 'tso',
         'tcptxchecksumipv4' => 'tx',
         'tcprxchecksumipv4' => 'rx',
         'ufo' => 'ufo',
         'gso' => 'gso',
         'sg' => 'sg',
         'lro'=> 'lro',
         );

      if (not defined $offloadParams{$offloadFunction}) {
         VDSetLastError("EINVALID");
         return FAILURE;
      }

      my %checkoffloadParams = (
         'tsoipv4' => 'tcp-segmentation-offload',
         'tcptxchecksumipv4' => 'tx-checksumming',
         'tcprxchecksumipv4' => 'rx-checksumming',
         'ufo' => 'udp-fragmentation-offload',
         'gso' => 'generic-segmentation-offload',
         'sg' => 'scatter-gather',
         'lro'=> 'large-receive-offload',
         );

      if (not defined $checkoffloadParams{$offloadFunction}) {
         VDSetLastError("EINVALID");
         return FAILURE;
      }

      # The $action argument to this sub-routine takes 'enable' or 'disable'
      # Convert them to "on" or "off" respectively
      my $arg = ($action =~ /enable/i) ? "on" : "off";

      if (not defined $arg) {
         $vdLogger->Error("Invalid parameter passed");
         VDSetLastError("EINVALID");
         return FAILURE;
      }

      # Using short form -K instead of --offload because older version of
      # ethtool supports only short form
      my $command = "ethtool -K $interface " .
                    "$offloadParams{$offloadFunction} $arg ";

      $vdLogger->Debug("Executing command: $command");
      # Execute the ethtool command to set (on/off) the offload function
      my $result = `$command 2>&1`;

      # Before version of ubuntu1304 the output of ethtool command to set offload function is expected
      # to be nothing in case of success. But in newer version of OS (such as RH7,ubuntu1404-3.17-GA
      # setting the offload of sg or tx) the output is not always noting.
      # So when we set offload and get some output we check the display command to get the final state.
      #(Plseas check PR1340691 and PR1303904 for detail).
      if  ($result eq ""){
         return SUCCESS;
      }

      my $checkcommand = "ethtool -k $interface ";
      $vdLogger->Debug("Executing Command : $checkcommand");

      my @resultStr = `$checkcommand 2>&1`;
      if ($resultStr[0] eq "") {
          return FAILURE;
      }

      for (my $i = 0; $i < scalar @resultStr; $i++) {
        $resultStr[$i] =~ s/\r|\n//g;
        if($resultStr[$i] =~ /$checkoffloadParams{$offloadFunction}/){
          $vdLogger->Debug("Check the state of $checkoffloadParams{$offloadFunction} is $arg");
          if ($resultStr[$i] =~ /\b$arg\b/) {
             return SUCCESS;
          }
         }
     }

      $vdLogger->Error("Error:Check offload result " . Dumper(@resultStr));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   } elsif (OSTYPE == OS_WINDOWS) {
      my $localHashRef;
      my $key;
      my $value;

      # The offload functions are enable or disabled for a given network
      # adapter using certain registry keys. These registry are different
      # based on:
      # * network adapter's driver
      # * ndis version
      # To capture the registry keys and values for various drivers like e1000,
      # vmxnet2, vmxnet3, and vlance for different ndis version,
      # devProperties.pm is used
      # This sub-routine refers the hash exported from DeviceProperties.pm to
      # set a specific offload function on the given adapter

      # First step, get the driver name of the given adapter/interface
      my $driverName = &GetDriverName($interface);

      if ($driverName eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      # driver name obtained is a reference
      $driverName = $$driverName;

      # Second step, get the ndis version
      my $ndisVersion = &GetNDISVersion($interface);

      if ($ndisVersion eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      # The ndis version returned will be '5.x', '6.x' format. Converting them
      # to represent the format being in used in DeviceProperties.pm
      if ($ndisVersion =~ /5.\d/)  {
         $ndisVersion = "Ndis5";
      } elsif ($ndisVersion =~ /6.\d/) {
         $ndisVersion = "Ndis6";
      }

      # Define the mapping to the actully offload function method
      my %supportedOffloadFunction = (
         'tsoipv4' => 'TSOIPv4',
         'tcptxchecksumipv4' => 'TCPTxChecksumIPv4',
         'tcprxchecksumipv4' => 'TCPRxChecksumIPv4',
         'udptxchecksumipv4' => 'UDPTxChecksumIPv4',
         'udprxchecksumipv4' => 'UDPRxChecksumIPv4',
         'tcpgiantipv4' => 'TCPGiantIPv4',
         'iptxchecksum' => 'IPTxChecksum',
         'iprxchecksum' => 'IPRxChecksum',
         'tsoipv6' => 'TSOIPv6',
         'tcptxchecksumipv6' => 'TCPTxChecksumIPv6',
         'tcprxchecksumipv6' => 'TCPRxChecksumIPv6',
         'udptxchecksumipv6' => 'UDPTxChecksumIPv6',
         'udprxchecksumipv6' => 'UDPRxChecksumIPv6',
         'tcpgiantipv6' => 'TCPGiantIPv6'
      );
      if (not exists $supportedOffloadFunction{$offloadFunction}) {
         $vdLogger->Error("Given offload $offloadFunction is not supported");
         VDSetLastError("ENOTSUP");
         return FAILURE;
      }
      $offloadFunction = $supportedOffloadFunction{$offloadFunction};

      # Based on the driver name, ndis version, get the registry key and value
      # for the given offload function for the given adapter
      eval "\$localHashRef = \\\%$driverName";

      if (not defined $localHashRef->{$ndisVersion}->{$offloadFunction}) {
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      # if the offload fucntion is marked 'NA', return not supported error
      if ($localHashRef->{$ndisVersion}->{$offloadFunction} eq 'NA') {
         VDSetLastError("ENOTSUP");
         return FAILURE;
      }


      $key = $localHashRef->{$ndisVersion}->{$offloadFunction}->{'Registry'};

      # Based on the $action parameter, decide the right key in
      # DeviceProperties.pm
      if ($action =~ /Enable/i) {
         $value = $localHashRef->{$ndisVersion}->{$offloadFunction}->{'Enable'};
      } elsif ($action =~ /Disable/i) {
         $value = $localHashRef->{$ndisVersion}->{$offloadFunction}->{'Disable'};
      } else {
         $value = $localHashRef->{$ndisVersion}->{$offloadFunction}->{'Default'};
      }

      if ((not defined $key) || (not defined $value)) {
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      if ($value eq 'NA') {
         VDSetLastError("ENOTSUP");
         return FAILURE;
      }

      # From the registry key and value obtained above, change the registry
      # settings of the given adapter

      my $tempString = InterfaceRegistryKey($interface);
      my $interfaceKey = $Registry->{$tempString};

      unless (defined $interfaceKey) {
         $vdLogger->Error("Can't find the Windows Registry interfaceKey");
         VDSetLastError("ENOENT");
         return FAILURE;
      }

      # Writing to the registry
      $interfaceKey->{$key} = [$value, "REG_SZ"];
   } else {    # for any other OS return error
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }

   # The device has to be reset in order for the MTU changed value to be
   # effective
   my $resultString = DeviceReset($interface);

   if ($resultString eq FAILURE) {
      $vdLogger->Error("Failed to change interface state");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Verify whether the registry changes really affected the offload settings
   # using GetOffload()
   $resultString = &GetOffload($interface, lc($offloadFunction));

   if ($resultString eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($$resultString !~ /$action/i) {
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetNDISVersion -
#        Gives the Ndis version of the mini-port driver being used by the
#        network adapter
#
# Input:
#       <interface> (ethx for linux, GUID of network adapter for windows
#
# Results:
#        Returns Ndis version (5.x, 6.x etc) if success
#        "FAILURE", in case of any error
#
# Side effects:
#        None
#
########################################################################

sub GetNDISVersion
{
   my $interface = shift;

   if (not defined $interface) {
      $vdLogger->Error("Invalid parameter passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # only supported on windows, for other OS return ENOTSUP
   if (OSTYPE != OS_WINDOWS) {
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
   # DeviceIoControl() is used to query the ndis driver version
   # The return value from GetOIDValue() is hex
   my $version = &GetOIDValue($interface, OID_GEN_DRIVER_VERSION);

   if ($version eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # The return value from GetOIDValue() will look like 0501 for 5.1,
   # 0601 for 6.1 ndis version. Remove the first zero and replace the
   # second zero with a dot
   $version =~ s/^0//;
   $version =~ s/0/./;
   if ($version =~ /(\d)(\d)(\d?)/) {
      $version = "$1.$2$3";
   }
   return $version;
}


########################################################################
#
# GetMACAddress -
#       Returns the mac address (hardware address) of the given
#       adapter/interface
#
# Input:
#       <interface> (ethx for linux, GUID of network adapter for windows
#
# Results:
#       Mac address of the given the adapter/interface
#       'FAILURE', in case of any error
#
# Side effects:
#        None
#
########################################################################

sub GetMACAddress
{
   my $interface = shift;  # Required
   my $mac;

   unless (defined $interface) {
      $vdLogger->Error("Invalid argument passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (OSTYPE == OS_LINUX) {
     # Look for "HWADDR:" in the ifconfig output on linux
     $mac = ReadIfConfig($interface, "macAddress");

     if ($mac eq FAILURE) {
        VDSetLastError(VDGetLastError());
        return FAILURE;
     }
     return \$mac;
   } elsif (OSTYPE == OS_WINDOWS) {
      # On windows, using win32_networkadapterconfiguration class to get the
      # mac address of a network adapter

      $mac = &ReadWin32NetAdapterConfigValue($interface,
                                             "MACAddress");
      if ($mac eq FAILURE || $mac eq "NULL") {
        VDSetLastError(VDGetLastError());
        return FAILURE;
      }
      return \$mac;
   } elsif ((OSTYPE == OS_MAC) || (OSTYPE == OS_BSD)){
       # Look for "ether" in the ifconfig output of Mac OS
       my $macAddress = ReadMacOSIfConfig($interface, "macAddress");

       if ($macAddress eq FAILURE) {
          VDSetLastError(VDGetLastError());
          return FAILURE;
       }
       return \$macAddress;
   } else {
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# CheckIPValidity --
#        Checks whether the given address has valid IP format and each octet is
#        within the range. This is just a utility function currently placed in
#        this package.
#
# Input:
#        <Interface> (ethx in linux, GUID in windows)
#        <Address in IP format> (xxx.xxx.xxx.xxx)
#
# Results:
#        "SUCCESS", if the given address has correct format and range
#        "FAILURE", if the given address has invalid format or range
#
# Side effects:
#        None
#
########################################################################

sub CheckIPValidity
{
   my $address = shift;

   if (not defined $address) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ($address =~ /^(\d\d?\d?)\.(\d\d?\d?)\.(\d\d?\d?)\.(\d\d?\d?)$/) {
      if ($1 > 255 || $2 > 255 || $3 > 255 || $3 > 255 || $4 > 255) {
         $vdLogger->Error("Address out of range: $address");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   } else {
         $vdLogger->Error("Invalid address: $address");
         VDSetLastError("EINVALID");
         return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetLinkState --
#     Gives the current link state of the adapter
#
# Input:
#     <Interface>  (ethx on linux, GUID on windows)
#
# Results:
#     'Connected', if the link is active
#     'Disconnected', if the link is not active
#     'FAILURE', in case of any errror
#
# Side effects:
#     None
#
########################################################################

sub GetLinkState
{
   my $interface = shift;  # Required
   my $linkState;

   unless (defined $interface) {
      $vdLogger->Error("Invalid argument passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (OSTYPE == OS_LINUX) {
      # On linux, ethtool is used to get the link state of an adapter
      # The stdout of ethtool <interface> has a line
      # "Link detected: yes/no"
      $linkState = `ethtool $interface | grep -i  \"Link detected\"`;
      if ($linkState =~ /Link detected:\s+(\w+)/i) {
         $linkState = $1;
         $vdLogger->Info("linkstate:$linkState");
         if ($linkState =~ /yes/i) {
            return "Connected";
         } elsif ($linkState =~ /no/) {
            return "Disconnected";
         } else {
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
      } else {
         VDSetLastError("EOPFAILED");
         $vdLogger->Info("GetLinkState: $linkState");
         return FAILURE;
      }
   } elsif (OSTYPE == OS_WINDOWS) {
      # On windows, "netsh interface ipv6 show interface <connection name>"
      # command gives the link state of the adapter. The output/behavior of
      # this command is consistent (unlike ipv4 interface) across various
      # windows versions
      my $command;
      # GetInterfaceName will return the connection name, for example,
      # 'Local area connection', which is needed for netsh command
      my $interfaceName = &GetInterfaceName($interface);

      if ($interfaceName eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      # As always, GetInterfaceName returns reference to string, so
      # de-referencing here
      $interfaceName = $$interfaceName;

      $command = "netsh interface ipv6 show interface \"$interfaceName\" ";

      my $result = `$command`;

      # The above mentioned command will not work if ipv6 protocol is not
      # installed on the windows machine, so in case of error due to ipv6
      # installation, ipv6 is installed and then the netsh command is executed
      # again. By default, ipv6 is installed on post-vista

      my $commandInstall;
      if (($result =~ /command not found/i) ||
          ($result =~ /ipv6 is not installed/i)) {
         $vdLogger->Info("Installing ipv6");
         $commandInstall = system("netsh interface ipv6 install");
         if (0 != $commandInstall) {
            $vdLogger->Error("IPv6 not installed:$commandInstall");
            if (256 == $commandInstall) {
               $vdLogger->Error("Reboot required to complete ipv6 installation");
            }
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }

         # Running the netsh command again if ipv6 installation was needed
         $result = `$command`;
      }
      # The output of the above command will look like:
      # Connection Name             : Local Area Connection
      # GUID                        : {98E94E7D-6D31-45A1-9D3B-966B689934AA}
      # State                       : Connected
      # Metric                      : 0
      # Link MTU                    : 1500 bytes
      # True Link MTU               : 1500 bytes
      # Current Hop Limit           : 64
      # Reachable Time              : 30s
      # Base Reachable Time         : 30s
      # Retransmission Interval     : 1s
      # DAD Transmits               : 1
      # DNS Suffix                  : eng.vmware.com
      # Firewall                    : disabled
      # Site Prefix Length          : 48 bits
      # Zone ID for Link            : 6
      # Zone ID for Site            : 2
      # Uses Neighbor Discovery     : Yes
      # Sends Router Advertisements : No
      # Forwards Packets            : No
      # Link-Layer Address          : 00-1d-09-0e-93-19
      #
      # Get the value of 'State' from the output

      if ($result =~ /State\s+:\s+(\w+)/i) {
         $linkState = $1;
      } else {
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      if ($linkState =~ /disconnected/i) {
         return "Disconnected";
      } elsif ($linkState =~ /connected/i) {
         return "Connected";
      } else {
         VDSetLastError("EINVALID");
         $vdLogger->Info("linkState:$result,$linkState");
         return FAILURE;
      }
   } elsif (OSTYPE == OS_MAC) {
      # This will check whether a network adapter is connected or disconnected
      # This can be ensured by checking the value of the status component when we
      # ifconfig for that particular network adapter.
      $linkState = &ReadMacOSIfConfig($interface, "status");
      if($linkState =~ /inactive/i) {
         return "Disconnected";
      } elsif ($linkState =~ /active/i) {
         return "Connected";
      } else {
         VDSetLastError("EINVALID");
         $vdLogger->Error("Invalid linkState:$linkState returned");
         return FAILURE;
      }
   }else {
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# GetIPv6Address --
#     Gives the IPv6 address of the given adapter. This routine is used to get
#     both link-local and Global addresses. This routine is not directly
#     exposed to users via NetAdapter.
#
# Input:
#     <Interface> (ethx on linux, GUID on windows)
#     <addrType> (link/global)
#
# Results:
#      Array of IPv6 address is returned, in case of no errors
#     'FAILURE', in case of any errror
#
# Side effects:
#     None
#
########################################################################

sub GetIPv6Address
{
   my $interface = shift; # Required
   my $addrType = shift;  # Required
   my @ipv6Address;
   my $command;
   my $commandInstall;

   if ((not defined $interface) ||
       (not defined $addrType)) {
      $vdLogger->Error("Invalid argument passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # Return error if the address type reuqested is other than 'link' or
   # 'global'

   if (($addrType !~ /link/i) &&
       ($addrType !~ /global/i)) {
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Make sure the device is enabled
   if (GetDeviceStatus($interface) !~ /UP/i) {
      $vdLogger->Error("Device should not be DOWN at this stage");
      VDSetLastError("ENETDOWN");
      return FAILURE;
   }

   if (OSTYPE == OS_LINUX) {
      #
      # On Linux, ifconfig <interface> output is used to get the ipv6 address
      # The portion of ifconfig ouput for ipv6 address will look like:
      # .
      # inet addr:10.20.84.70  Bcast:10.20.87.255  Mask:255.255.252.0
      # inet6 addr: fc00:10:20:87:20c:29ff:fe23:8aee/64 Scope:Global
      # inet6 addr: fe80::20c:29ff:fe23:8aee/64 Scope:Link
      #
      if ($addrType =~ /link/i) {
         @ipv6Address = &ReadIfConfig($interface, "ipv6Link");
      } elsif ($addrType =~ /global/i) {
         @ipv6Address = &ReadIfConfig($interface, "ipv6Global");
      }
      $vdLogger->Debug(Dumper(@ipv6Address));
      return @ipv6Address;

   } elsif (OSTYPE == OS_WINDOWS) {
      # On windows, "netsh interface ipv6 show address <connection name>" is
      # used to get the IPv6 address (both link and global)
      # GetInterfaceName() returns connection name of the adapter, for example,
      # 'Local area connection #1'
      my $interfaceName = &GetInterfaceName($interface);

      if ($interfaceName eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      # De-referencing the reference to string returned by GetInterfaceName()
      $interfaceName = $$interfaceName;
      # level=normal gives table formatted output, which will look like:
      # .
      # Temporary  Deprecated 3m7s 0s fc00:10:20:87:20e0:b964:bc2e:4600
      # Manual     Preferred  5m4s 4m 2001:db6::32
      # Public     Preferred  5m4s 4m fc00:10:20:87:21d:9ff:fe0e:9319
      # Link       Preferred infinite infinite fe80::21d:9ff:fe0e:9319
      # .
      # Get the Public and Link addresses from the output
      $command = "netsh interface ipv6 show address \"$interfaceName\" " .
                 "level=normal";

      my $result = `$command`;

      # IPv6 is not installed by default on pre-vista, if netsh command above
      # complains that ipv6 is not installed, then install and try the command
      # again to get the ipv6 addresses

      if (($result =~ /command not found/i) ||
         ($result =~ /ipv6 is not installed/i)) {
         $commandInstall = `netsh interface ipv6 install`;

        if (($commandInstall !~ /Ok/i) &&
           ($commandInstall =~ /reboot/i)) {
         $vdLogger->Info("Reboot needed to complete action");
         VDSetLastError("ENOTPERM"); # change error code
         return FAILURE;
        } elsif ($commandInstall !~ /Ok/) {
            VDSetLastError("EOPFAILED");
            $vdLogger->Info("IPv6 not installed:$commandInstall");
            return FAILURE;
         }
         # Updating the result after running the netsh command with ipv6
         # installed manually, if needed
         $result = `$command`;
      }
      # Get the ipv6 address from the netsh output
      # IPv6 link address starts with fe80::
      # IPv6 global address starts with fc00:
      # IPv6 global address starts with 2001:
      # IPv6 address set manually using netsh command will show address type
      # as 'Manual'
      #
      $vdLogger->Debug("IPv6 entries" . Dumper($result));
      my @resultArray = split(/\n/, $result);
      foreach $result (@resultArray) {
         if (($addrType =~ /link/i) && ($result =~ /tentative|preferred/i) &&
            ($result =~ /Other|Link|Manual/i) &&
            ($result =~ /(fe80::[a-z0-9:]+)/i)) {
            push(@ipv6Address,$1);
         } elsif (($addrType =~ /Global/i) &&
                  ($result =~ /tentative|preferred/i) &&
                 ($result =~ /Manual|Other|Public/i) &&
                 (($result =~ /(fc00:[a-z0-9:]+)/i) ||
                  ($result =~ /(2001:[a-z0-9:]+)/i))) {
            push(@ipv6Address,$1);
         }
      }
      if (scalar(@ipv6Address) <= 0) {
         # return empty array if no ipv6 address is configured
         @ipv6Address = ();
         return @ipv6Address;
      }
      $vdLogger->Debug(Dumper(@ipv6Address));
      return @ipv6Address;
   } elsif (OSTYPE == OS_MAC) {
      # On Mac, ifconfig <interface> output is used to get the ipv6 address
      # The portion of ifconfig ouput for ipv6 address will look like:
      # .
      # inet addr:10.20.84.70  Bcast:10.20.87.255  Mask:255.255.252.0
      # inet6 addr: fc00:10:20:87:20c:29ff:fe23:8aee/64 scope_id=0x4
      # inet6 addr: fe80::20c:29ff:fe23:8aee/64 scope_id = 0x1
      #
      if ($addrType =~ /link/i) {
         @ipv6Address = &ReadMacOSIfConfig($interface, "ipv6Link");
      } elsif ($addrType =~ /global/i) {
         @ipv6Address = &ReadMacOSIfConfig($interface, "ipv6Global");
      }
      $vdLogger->Debug(Dumper(@ipv6Address));
      return @ipv6Address;
   } else {
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# GetIPv6Local --
#     Gives the IPv6 link-local address for the given interface
#
# Input:
#     <Interface> (ethx on linux, GUID on windows)
#
# Results:
#     Reference to an array of IPv6 link-local address, on success
#     Empty array if no ipv6 local address is configured
#     'FAILURE', in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetIPv6Local
{
   my $interface = shift; # Required
   my @ipv6Address;

   if (not defined $interface) {
      $vdLogger->Error("Interface not specified");
      VDSetLastError("EINVALID");
   }

   # Calls GetIPv6Address() with addrType parameter as 'link'
   @ipv6Address = &GetIPv6Address($interface, "link");
   if ($ipv6Address[0] eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # As any other routine, return reference to the ipv6address array
   return \@ipv6Address;
}


########################################################################
#
# GetIPv6Global --
#     Gives the IPv6 global address for the given interface
#
# Input:
#     <Interface> (ethx on linux, GUID on windows)
#
# Results:
#     Reference to an array of IPv6 global address, on success
#     Empty array if no ipv6 global address is configured
#     'FAILURE', in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetIPv6Global
{
   my $interface = shift; # Required
   my @ipv6Address;

   if (not defined $interface) {
      $vdLogger->Error("Interface not specified");
      VDSetLastError("EINVALID");
   }

   # Calls GetIPv6Address() with addrType parameter as 'global'
   @ipv6Address = &GetIPv6Address($interface, "global");
   if ($ipv6Address[0] eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return \@ipv6Address;
}


########################################################################
#
# SetIPv6 --
#       This function configures the IP address of the given interface
#
# Input:
#       <interface> (ethx in linux, device GUID in windows) (Required)
#       <operation> add or delete (Required)
#       <ipaddr> - IPv6 address to set (Required)
#       <prefixLength> - prefix length to set (Required)
#
# Results:
#       "SUCCESS", if success
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub SetIPv6
{
   my ($interface, $operation, $ipaddr, $prefixLength, $gateway) = @_;

   if ((not defined $interface) ||
      (not defined $operation) ||
      (not defined $ipaddr) ||
      (not defined $prefixLength)) {
      $vdLogger->Error("Invalid parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # If user passes ipAddr as '2001:bd6::000c:2957:426c'
   # system treats it as '2001:bd6::c:2957:426c'
   # Thus lets convert it to system format
   $ipaddr  =~ s/\:0+/:/g;

   my $addrType = ($ipaddr =~ /fe80/i) ? "link" : "global";
   my $tempOperation;
   if (($operation !~ /add/i) && ($operation !~ /delete/i)) {
      $vdLogger->Error("Invalid operation specified, use 'add' or 'delete'");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # Make sure the device is enabled
   if (GetDeviceStatus($interface) !~ /UP/i) {
      $vdLogger->Error("Device should not be DOWN at this stage");
      VDSetLastError("ENETDOWN");
      return FAILURE;
   }
   if (OSTYPE == OS_LINUX) {
      # Check if ipv6 module is loaded or not.
      my $lsmodIPv6  = `lsmod | grep ipv6`;
      if ($lsmodIPv6 ne '') {
         $vdLogger->Trace("lsmod | grep ipv6 returned:$lsmodIPv6");
	 # Try to load the ipv6 module if it is not loaded.
         my $modProbeIPv6  = `modprobe ipv6`;
         if ($modProbeIPv6 ne '') {
            $vdLogger->Error("Error:$modProbeIPv6");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      }


      # In linux, ifconfig command to is used to configure the ip address
      # of the interface
      $tempOperation = ($operation =~ /add/i) ? "add" : "del";
      my $ifconfigCmd = "//sbin//ifconfig $interface $tempOperation " .
                        "$ipaddr/$prefixLength up";
      my $result = `$ifconfigCmd 2>&1`;
      $vdLogger->Info("SetIPv6:$result");
      # This verification is enough to detect malformed IPv6 addresses
      # and assigning already assigned IPv6 address to an interface.
      # We don't need to use Net::IPv6Addr CPAN module to verify the
      # validity.
      if (($result ne '' ) && ($result !~ /SIOCSIFADDR/)) {
         $vdLogger->Error("Result:$result");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      my $line = "ifconfig $interface $tempOperation " .
                 "$ipaddr/$prefixLength up";

      my $netScripts = EditToolsScripts($interface, $line);
      if ($netScripts eq FAILURE) {
         $vdLogger->Error("Error returned from EditToolsScripts");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

   } elsif (OSTYPE == OS_WINDOWS) {
      # In windows, netsh command is used to configure IP
      my $adapterObj = GetWin32NetworkConfigurationObj($interface);


      # Get the interfaceName for example, "Local Area Connection"
      # using Win32_NetworkAdapterConfiguration WMI class
      my $index = $adapterObj->{'Index'};
      my $interfaceName = &ReadWin32NetAdapter($index, "NetConnectionID");

      if ($interfaceName eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $tempOperation = ($operation =~ /add/i) ? "set" : "delete";
      my $ipSetCommand = "netsh interface ipv6 $tempOperation address " .
                         "\"$interfaceName\" $ipaddr";

      $vdLogger->Debug("executing $ipSetCommand");
      my $result = `$ipSetCommand 2>&1`;

      # IPv6 is not installed by default on pre-vista, if netsh command above
      # complains that ipv6 is not installed, then install and try the command
      # again to get the ipv6 addresses

      if (($result =~ /command not found/i) ||
         ($result =~ /ipv6 is not installed/i)) {
         my $commandInstall = `netsh interface ipv6 install`;

        if (($commandInstall !~ /Ok/i) &&
           ($commandInstall =~ /reboot/i)) {
         $vdLogger->Info("Reboot needed to complete action");
         VDSetLastError("ENOTPERM"); # change error code
         return FAILURE;
        } elsif ($commandInstall !~ /Ok/) {
            VDSetLastError("EOPFAILED");
            $vdLogger->Info("IPv6 not installed:$commandInstall");
            return FAILURE;
         }
         # Updating the result after running the netsh command with ipv6
         # installed manually, if needed
         $result = `$ipSetCommand 2>&1`;
      }
      if (($result !~ /Ok/i) &&  # 'Ok'is not returned in pre-vista
         ($result =~ /\S+/)) {   # Empty space is returned in >= vista
         $vdLogger->Error("Error:$result returned");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   } elsif (OSTYPE == OS_MAC) {
      # Run the command to activate ipv6 is being done below. Unlike linux
      # we dont need to first check whether it is enabled or not. We can directly
      # run the command, if it is already enabled, it will just give an error.
      # In mac, ifconfig command to is used to configure the ip address
      # of the interface
      my $enableIPv6  = `ip6 -u $interface`;
      if ($enableIPv6 ne '') {
         # error will be thrown if ip6 is already enabled, therefore displaying
         # error message would be enough, no need to exit control for this function
         $vdLogger->Error("IPv6 already activated");
      }

      $tempOperation = ($operation =~ /add/i) ? "add" : "del";
      my $ifconfigCmd = "ifconfig $interface  inet6 " .
                        "$ipaddr prefixlen $prefixLength alias";
      my $result = `$ifconfigCmd 2>&1`;
      $vdLogger->Info("SetIPv6:$result");
      # This verification is enough to detect malformed IPv6 addresses
      # and assigning already assigned IPv6 address to an interface.
      # We don't need to use Net::IPv6Addr CPAN module to verify the
      # validity.
      if (($result ne '' ) && ($result !~ /SIOCSIFADDR/)) {
         $vdLogger->Error("Result:$result");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      # this command used here will be added to the VMware tools script document
      # maintaned by this test.
      my $netScripts = EditToolsScripts($interface, $ifconfigCmd);
      if ($netScripts eq FAILURE) {
         $vdLogger->Error("Error returned from EditToolsScripts");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

   } else {
      $vdLogger->Error("OS not supported");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
   # To make sure IPv6 address is set correctly,
   # GetIPv6Local/Global immediately after set operation
   # will have DAD state in netsh output as 'tentative', but
   # we expect 'preferred' which gets changed after few seconds
   sleep(10);
   my @ipv6Array;
   my $result;

   if ($addrType =~ /link/i) {
      $result = GetIPv6Local($interface);
   } else {
      $result = GetIPv6Global($interface);
   }

   if ($result eq FAILURE) {
      $vdLogger->Error("Error returned from GetIPv6Local/Global");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   @ipv6Array = @$result;
   my $found = 0;
   $vdLogger->Debug('GetIPv6 return value at SetIPv6:' . Dumper(@ipv6Array). "");
   foreach my $ipv6 (@ipv6Array) {
      if ($ipv6 =~ /$ipaddr/i) {
         $vdLogger->Debug("Found the ipv6 address: $ipv6");
         $found = 1;
         last;
      }
   }
   if (($operation =~ /add/i) && (!$found)) {
      $vdLogger->Error("Operation failed to set given ipv6 address");
      VDSetLastError("EMISMATCH");
      return FAILURE;
   } elsif (($operation =~ /delete/i) && ($found)) {
      $vdLogger->Error("Operation failed to delete given ipv6 address");
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# GetWoL --
#     Gives the wake-on LAN configuration on the given interface.
#     The return value is string which can be any combination of the
#     following:
#     ARP - wake on arp
#     UNICAST - wake on unicast packet
#     MAGIC - wake on magic packet
#
#     *** or ***
#     DISABLE - wake-on lan feature is disabled or not supported
#
# Input:
#     <interface> (ethx on linux, GUID on windows)
#
# Results:
#     A string with any combination of the above, on success
#     'FAILURE', in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetWoL
{
   my $interface = shift; # Required

   my ($unicast, $arp, $magic, $disable) = 0;
   my $string = "";

   if (not defined $interface) {
      $vdLogger->Error("Interface not specified");
      VDSetLastError("EINVALID");
   }

   if (OSTYPE == OS_LINUX) {
      # On Linux, 'ethtool <interface>' command is used to get the wake on lan
      # configuration currently set on the given interface
      my $result = `ethtool $interface`;

      # A part of ethtool <interface> command will look like:
      #  .
      #  .
      #  Transceiver: internal
      #  Auto-negotiation: off
      #  Supports Wake-on: uag
      #  Wake-on: d
      #  Read 'Wake-on: ' value to get the current configuration

      # If the ethtool output does not have 'Supports Wake-on', the WoL is not
      # supported for the given interface.
      #
      # Differentiate between 'Supports Wake-on' and just 'Wake-on'by using new
      # line and a white space before 'Wake-on'
      # The letters next to 'Wake-on' indicates,
      #  u - unicast; a- arp; g -magic; d- disable
      #
      if ($result !~ /Supports Wake-on/i) {
         $vdLogger->Error("Wake-on LAN not supported for this interface");
         VDSetLastError("ENOTSUP");
         return FAILURE;
      } elsif ($result =~ /\n+\s+Wake-On:\s+(\w+)/i) {
         my $wol = $1;
         if ($wol =~ /u/) {
            $unicast = 1;
         }
         if ($wol =~ /a/) {
            $arp = 1;
         }
         if ($wol =~ /g/) {
            $magic = 1;
         }
         if ($wol =~ /d/) {
            $vdLogger->Info("WoL disabled on this interface $interface");
            $disable = 1;
            goto out;
         }
      } else {
         $vdLogger->Error("Unexpected output:$result");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   } elsif (OSTYPE == OS_WINDOWS) {
      # Get an object of MSPower_DeviceWakeEnable class that corresponds to the
      # given interface and read its attribute 'Enable' to get the current
      # status of WoL configuration using arp/unicast packet

      my $arpWakeObj = GetWMIDeviceWakeUpObj($interface,
                                         "MSPower_DeviceWakeEnable");
      if ($arpWakeObj eq FAILURE) {
         if (VDGetLastError() =~ /ENOTDEF/) {
            $vdLogger->Info("Wake on LAN not supported or disabled");
            $disable = 1;
            goto out;
         } else {
            $vdLogger->Error("Failed to get MSPower_DeviceWakeEnable object");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      } elsif ($arpWakeObj->{Enable}) { # if 'Enable' is 1, wake on arp is
                                        # enabled
         $vdLogger->Info("Wake on arp enabled");
         $arp = 1;
         $unicast = 1;
      } else {
         $vdLogger->Info("Wake on arp not enabled");
         $arp = 0;
      }

      # Get an object of MSNdis_DeviceWakeOnMagicPacketOnly class that
      # corresponds to the given interface and read its attribute
      # 'EnableWakeOnMagicPacketOnly' to get the current status of WoL
      # configuration using magic packet
      #
      my $magicWakeObj = GetWMIDeviceWakeUpObj($interface,
                                         "MSNdis_DeviceWakeOnMagicPacketOnly");
      if ($magicWakeObj eq FAILURE) {
         if (VDGetLastError() =~ /ENOTDEF/) {
            $vdLogger->Info("Wake on LAN not supported or disabled");
            $disable = 1;
            goto out;
         } else {
            $vdLogger->Error("Failed to get MSNdis_DeviceWakeOnMagicPacketOnly " .
                         "object");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      } elsif ($magicWakeObj->{EnableWakeOnMagicPacketOnly}) {
         # if the attribute EnableWakeOnMagicPacketOnly is '1', then wake on
         # magic packet only is enabled
         $vdLogger->Info("Wake on Magic Packet only enabled");
         $magic = 1;
      } else {
         $vdLogger->Info("Wake on Magic Packet not enabled");
         $magic = 0;
      }
   } else {
      $vdLogger->Error("Unsupported OS");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
out:
   # Compose the string based on the wake on methods currently set on the given
   # adpater
   if ($magic) {
      $string = $string . "MAGIC ";
   }
   if ($unicast) {
      $string = $string . "UNICAST ";
   }
   if ($arp) {
      $string = $string . "ARP ";
   }
   if ($disable) {
      return \"DISABLE";
   }
   return \$string;
}


########################################################################
#
# SetWoL --
#     Sets the wake-on LAN configuration on the given interface.
#     The wake-on method is string which can be any combination of the
#     following:
#     ARP - wake on arp
#     UNICAST - wake on unicast packet
#     MAGIC - wake on magic packet
#
#     *** OR ***
#     DISABLE - disable wake-on lan feature
#
# Input:
#     <interface> (ethx on linux, GUID on windows)
#     <wakeUpMethods>
#        String with methods mentioned above, for example,
#        SetWoL(eth0,'MAGIC ARP'), SetWoL(eth0,'DISABLE')
#
# Results:
#     'SUCCESS', if the given wake-method is configured or wol is disabled
#     'FAILURE', in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetWoL
{
   my $interface = shift;    # required
   my $wakeUpMethods = shift;# required

   my ($arp, $magic, $unicast, $disable) = 0;
   my $string = "";

   if ((not defined $interface) ||
       (not defined $wakeUpMethods)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
   }

   # Get the driver name
   my $driverName = &GetDriverName($interface);

   if ($driverName eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # driver name obtained is a reference
   $driverName = $$driverName;

   # There is no way to enable/disable WoL for e1000 or e1000e on Windows guests
   # from within the guest, so just return
   if ($driverName =~ /e1000/) {
      return SUCCESS;
   }

   # Construct the string required for ethtool command based on the user input
   # to configure WoL on the given interface
   if ($wakeUpMethods =~ /ARP/i) {
      $arp = 1;
      $string = $string . "a";
   }
   if ($wakeUpMethods =~ /MAGIC/i) {
      $magic = 1;
      $string = $string . "g";
   }
   if ($wakeUpMethods =~ /UNICAST/i) {
      $unicast = 1;
      $string = $string . "u";
   }
   if ($wakeUpMethods =~ /DISABLE/i) {
      $disable = 1;
      $string = "d"; # No concatenation here when disable option is given
   }
   if (OSTYPE == OS_LINUX) {
      # on linux, 'ethtool -s|--change <interface> wol u|a|g|d' command is used to
      # enable WoL with specific wake up methods or disable WoL
      #
      my $result = `ethtool -s $interface wol $string`;
      if ($result ne "") {
         $vdLogger->Error("Unexpected error returned:$result");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   } elsif (OSTYPE == OS_WINDOWS) {
      #
      # On windows, WoL is enabled/disabled on the given adapter using the
      # registry settings. Then specific wake up method is configured using WMI
      # class mentioned in GetWMIDeviceWakeUpObj().
      # First get the Registry key value for Wake-on LAN for the given
      # interface using the GetDeviceConfig() routine which reads
      # hash exported by DeviceProperties.pm
      #
      my $localHashRef = GetDeviceConfig($interface);
      if ($localHashRef eq FAILURE) {
         $vdLogger->Info("Error returned while retrieving device config information");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      $vdLogger->Debug("Device Config Hash:" . Dumper($localHashRef) . "");
      # If the device WoL feature is marked 'NA' , then WoL is not supported on
      # this particular driver
      if ($localHashRef->{'WakeOnLAN'} eq 'NA') {
         VDSetLastError("ENOTSUP");
         return FAILURE;
      }

      my $key = $localHashRef->{'WakeOnLAN'}->{'Registry'};
      my $value;

      # Based on the $action parameter, decide the right key in
      # DeviceProperties.pm
      if ($disable) {
         $value = $localHashRef->{'WakeOnLAN'}->{'Disable'};
      } else {
         $value = $localHashRef->{'WakeOnLAN'}->{'Enable'};
      }
      $vdLogger->Info("Key:$key, value:$value");

      if ((not defined $key) || (not defined $value)) {
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      # if the registry value is marked 'NA' , then WoL is not supported on
      # this particular driver
      if ($value eq 'NA') {
         VDSetLastError("ENOTSUP");
         return FAILURE;
      }

      # From the registry key and value obtained above, change the registry
      # settings of the given adapter

      my $tempString = InterfaceRegistryKey($interface);
      my $interfaceKey = $Registry->{$tempString};

      if (not defined $interfaceKey) {
         $vdLogger->Error("Can't find the Windows Registry interfaceKey");
         VDSetLastError("ENOENT");
         return FAILURE;
      }

      # Writing to the registry
      $interfaceKey->{$key} = [$value, "REG_SZ"];

      # Any registry changes require device reset for the changes to be
      # effective
      #
      my $resultString = DeviceReset($interface);

      if ($resultString eq "FAILURE") {
         $vdLogger->Error("Failed to change interface state");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      # If the wakeUpMethod parameter at the input is 'DISABLE', the routine
      # can  quit here itself without going through WMI configuration for
      # specific wake up method
      if ($disable) {
         return SUCCESS;
      }

      # Get an object of MSPower_DeviceWakeEnable class that
      # corresponds to the given interface and set its attribute
      # 'Enable' to 1 if WoL configuration using arp/unicast
      # packet is requested, otherwise disable this option
      #
      my $arpWakeObj = GetWMIDeviceWakeUpObj($interface,
                                         "MSPower_DeviceWakeEnable");
      if ($arpWakeObj eq FAILURE) {
         if (VDGetLastError() =~ /ENOTDEF/) {
            $vdLogger->Info("Wake on LAN not supported or disabled");
            $arp = 0;
            goto out;
         } else {
            $vdLogger->Error("Failed to get MSPower_DeviceWakeEnable object");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }

      if (($arp) || ($magic) || ($unicast)) {
         $arpWakeObj->{Enable} = "1";
      } else {
         $arpWakeObj->{Enable} = "0";
      }

      $arpWakeObj->put_(); # to actually update the object
      #
      # Get an object of MSNdis_DeviceWakeOnMagicPacketOnly class that
      # corresponds to the given interface and set its attribute
      # 'EnableWakeOnMagicPacketOnly' to 1 if WoL configuration using
      # magic packet is requested, otherwise disable this option
      #
      my $magicWakeObj = GetWMIDeviceWakeUpObj($interface,
                                         "MSNdis_DeviceWakeOnMagicPacketOnly");
      if ($magicWakeObj eq FAILURE) {
         if (VDGetLastError() =~ /ENOTDEF/) {
            $vdLogger->Info("Wake on LAN not supported or disabled");
            $magic = 0;
            goto out;
         } else {
            $vdLogger->Error("Failed to get MSNdis_DeviceWakeOnMagicPacketOnly " .
                         "object");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }

      if ($magic) {
         $magicWakeObj->{EnableWakeOnMagicPacketOnly} = "1";
      } else {
         $magicWakeObj->{EnableWakeOnMagicPacketOnly} = "0";
      }
      $magicWakeObj->put_(); # updates the object
   } else {
      $vdLogger->Error("OS type not supported");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
   # Get the WoL configuration on the interface after Set operation is
   # performed to verify correct changes
   my $getValue = GetWoL($interface);
   if ($getValue eq FAILURE) {
      $vdLogger->Error("Get WoL failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $getValue = $$getValue; # GetWoL() returns reference to string, so
                           # de-reference
   my @tmp = split(/:/,$wakeUpMethods);
   for (my $i = 0; $i < scalar(@tmp); $i++) {
      if ($getValue !~ /$tmp[$i]/i) {
         $vdLogger->Error("Get:$getValue, Set:$tmp[$i] data mismatch");
         VDSetLastError("EMISMATCH");
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# GetWMIDeviceWakeUpObj --
#     Gives an object of MSPower_DeviceWakeEnable or
#     MSNdis_DeviceWakeOnMagicPacketOnly WMI class corresponding to the given
#     interface.
#
# Input:
#     <interface> (ethx in linux, GUID of network adapter in windows)
#     <className> MSPower_DeviceWakeEnable | MSNdis_DeviceWakeOnMagicPacketOnly
#
# Results:
#     Reference to hash/object of either MSPower_DeviceWakeEnable or
#        MSNdis_DeviceWakeOnMagicPacketOnly class
#     'FAILURE', in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetWMIDeviceWakeUpObj
{
   my $interface = shift;
   my $className = shift;

   if ((not defined $interface) ||
       (not defined $className)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
   }
   #
   # On windows, the following WMI classes are used:
   # MSPower_DeviceWakeEnable - to get/set wake-on lan/with arp/unicast
   # MSNdis_DeviceWakeOnMagicPacketOnly - to get/set wake-on lan only using
   #                                      a magic packet
   # An object of MSPower_DeviceWakeEnable class will have attributes
   # Instancename - PNPDeviceID of the adapter
   # Active - if WoL is active or not
   # Enable - get/set if this method of WoL is active or not
   #
   # An object of MSNdis_DeviceWakeOnMagicPacketOnly will have attributes
   # Instancename - PNPDeviceID of the adapter
   # Active - if WoL is active or not
   # EnableWakeOnMagicPacketOnly - get/set if this method of WoL is active or not
   #

   # In windows, netsh command is used to configure IP
   my $adapterObj = GetWin32NetworkConfigurationObj($interface);

   # Get the PNPDeviceID for example,
   # "PCI\VEN_15AD&DEV_07&SUBSYS_07B015AD&REV_01\4&21C36F57&0&00A8"
   # using Win32_NetworkAdapterConfiguration WMI class
   my $index = $adapterObj->{'Index'};
   my $PNPDeviceID = &ReadWin32NetAdapter($index, "PNPDeviceID");
   #
   # executing a query to get the MSPower_DeviceWakeEnable or
   # MSNdis_DeviceWakeOnMagicPacketOnly objects, then retrieve the object
   # corresponding to the given interface by matching its Instancename
   # attribute with interface's PNPDeviceID
   #
   my $nicStr = "SELECT * FROM $className";
   my $hostname = `hostname`;
   my $Host = uc($hostname);
   my $colItems;
   chomp($Host);
   my @computers = ("$Host");
   # Note the power management/WoL classes used in this routine
   # are from root 'Wmi'
   my $objWMIService =
      Win32::OLE->GetObject("winmgmts:\\\\$Host\\root\\Wmi");

   unless ($objWMIService) {
      $vdLogger->Error("WMI connection failed.");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   unless ($colItems =
      $objWMIService->ExecQuery($nicStr, "WQL",
                                wbemFlagReturnImmediately |
                                wbemFlagForwardOnly))
   {
      $vdLogger->Error("Error Executing WMI query:$nicStr");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # $colItems will return hash of MSPower_DeviceWakeEnable or
   # MSNdis_DeviceWakeOnMagicPacketOnly object
   #
   #  quotemeta is used to add escape slash with all non-word characters in the
   #  given expression. Since PNPDeviceId \ and &, they have to be escaped
   #  before any regex operation
   $PNPDeviceID = quotemeta($PNPDeviceID);
   foreach my $objItem (in $colItems) {
      if ($objItem->{InstanceName} =~ /$PNPDeviceID/i) {
         return $objItem;
      }
   }
   VDSetLastError("ENOTDEF");
   return FAILURE;

}


########################################################################
#
# GetDeviceConfig --
#     Get the reference to hash for a particular driver
#     (e1000/vlance/vmxnet2/vmxnet2) which is exported by DeviceProperties.pm
#     The keys and values of the hash has details pertaining to the registry
#     settings, default values for a specific feature like jumboframe, wake-on
#     lan.
#
# Input:
#     <interface> (ethx for linux, GUID of network adapter for windows)
#
# Results:
#     Reference to hash in DeviceProperties.pm for the given interface/driver;
#     'FAILURE', in case of any error
#
########################################################################

sub GetDeviceConfig
{
   my $interface = shift;
   my $localHashRef;
   if (not defined $interface) {
      $vdLogger->Error("Interface not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # First step, get the driver name of the given adapter/interface
   my $driverName = &GetDriverName($interface);

   if ($driverName eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # driver name obtained is a reference
   $driverName = $$driverName;

   # Second step, get the ndis version
   my $ndisVersion = &GetNDISVersion($interface);

   if ($ndisVersion eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # The ndis version returned will be '5.x', '6.x' format. Converting them
   # to represent the format being in used in DeviceProperties.pm
   if ($ndisVersion =~ /5.\d/)  {
      $ndisVersion = "Ndis5";
   } elsif ($ndisVersion =~ /6.\d/) {
      $ndisVersion = "Ndis6";
   }

   # Based on the driver name, ndis version, get the registry key and value
   # for the given feature/configuration of the given adapter
   eval "\$localHashRef = \\\%$driverName";

   if (not defined $localHashRef->{$ndisVersion}) {
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   return $localHashRef->{$ndisVersion};
}


########################################################################
#
# DevconEnableDisable --
#     Sub-routine to do enable or disable network adapter using devcon.exe
#
# Input:
#     <interface> (GUID of a network adapter)
#     <operation> (enable or disable)
#
# Results:
#     "SUCCESS", if the required operation enable/disable is performed without
#              any error
#     "FAILURE", in case of any error
#
# Side effects:
#     Since this routine changes the state of the adapter, all dynamic
#     configurations such as ip address obtained through dhcp might change
#
########################################################################

sub DevconEnableDisable
{
   my $interface = shift;  # required
   my $operation = shift;  # required
   my $command;

   if ((not defined $interface) ||
      (not defined $operation)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $gc = VDNetLib::Common::GlobalConfig->new();
   my $np = new VDNetLib::Common::GlobalConfig;
   # Get the default test binaries path from VDNetLib::Common::GlobalConfig.pm
   my $testCodePath = $np->BinariesPath(OSTYPE);
   my $arch;

   # Determine if the OS is 32 or 64 bit
   $arch = &ReadWin32Processor("AddressWidth");
   if ($arch eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($arch =~ m/32/i) {
      $arch = "x86_32";
   } elsif ($arch =~ /64/i) {
      $arch = "x86_64";
   } else {
      VDSetLastError("EINVALID");
      $vdLogger->Error("Find process arch output: $command");
      return FAILURE;
   }
   $vdLogger->Debug("Processor architecture: $arch");

   my $path = "$testCodePath" . "$arch\\\\windows\\\\" . 'devcon.exe';
   my $adapterObj = GetWin32NetworkConfigurationObj($interface);

   if ($adapterObj eq "FAILURE") {
      $vdLogger->Error("Failed to get valid Win32_NetworkConfiguration object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Get the interfaceName for example, "Local Area Connection"
   # using Win32_NetworkAdapterConfiguration WMI class
   my $index = $adapterObj->{'Index'};
   if ($index eq "FAILURE") {
      $vdLogger->Error("invalid Index returned");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Get the hardware id for the interface/adapter to be used as a parameter
   # for devcon.exe
   my $hwid = &ReadWin32NetAdapter($index, "PNPDeviceID");

   if ($hwid eq "FAILURE") {
      $vdLogger->Error("Invalid Hardware ID returned");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Using devcon.exe to enable/disable an interface
   if ($operation =~ /ENABLE/i) {
      $command = "$path " . "enable " . "\"\@$hwid\"";
   } else {
      $command = "$path " . "disable " . "\"\@$hwid\"";
   }

   $vdLogger->Debug("Executing Command: $command");

   my $stdout = `$command 2>&1`;
   $vdLogger->Debug("$stdout");

   if ($stdout =~ m/No devices/i) {
      $vdLogger->Error("device failed to $operation");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# NetshEnableDisable --
#     Sub-routine to do enable or disable network adapter using devcon.exe
#
# Input:
#     <interface> (GUID of a network adapter)
#     <operation> (enable or disable)
#
# Results:
#     "SUCCESS", if the required operation enable/disable is performed without
#              any error
#     "FAILURE", in case of any error
#
# Side effects:
#     Since this routine changes the state of the adapter, all dynamic
#     configurations such as ip address obtained through dhcp might change
#
########################################################################

sub NetshEnableDisable {
   my $interface = shift;  # required
   my $operation = shift;  # required
   my $command;

   if ((not defined $interface) ||
       (not defined $operation)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Get the object of Win32_NetworkConfiguration class that refers to the
   # given interface
   #
   my $adapterObj = GetWin32NetworkConfigurationObj($interface);

   # Get the interfaceName for example, "Local Area Connection"
   # using Win32_NetworkAdapterConfiguration WMI class
   my $index = $adapterObj->{'Index'};
   my $interfaceName = &ReadWin32NetAdapter($index, "NetConnectionID");

   if ($interfaceName eq FAILURE) {
      $vdLogger->Error("Error returned while retrieving interface name");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $command = "netsh interface set interface \"$interfaceName\" " .
              "$operation";

   my $stdout = `$command 2>&1`;

   $vdLogger->Debug("Executed Command: $command");
   $vdLogger->Debug("Output: " . $stdout . "");

   if ($stdout =~ /\S+/) {
      $vdLogger->Error("device failed to $operation");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# ReadWriteToRegistry --
#     Routine to read and write registry values in windows specifically the
#     features mentioned in DeviceProperties.pm
#
# Input:
#     <interface> (GUID of a network adapter)
#     <features> (Feature string mentioned in DeviceProperties.pm
#                 for example, RxRing2Size, LargeRxBuffers, OffloadIPOptions
#                 etc)
#     <operation> ("WRITE" - to indicate it is a write operation
#                  "READ"  -  to indicate it is a read operation)
#     <value> (value to write if <operation> is 'write',
#              it can be a number of one of these strings
#              "Enable", "Disable", or "Default")
#
# Results:
#     The current value of the registry requested by the user input;
#     0 if the feature is disabled;
#     "FAILURE", in case of any error
#
# Side effects:
#     Changing the registry value using this routine affects the device
#     configuration. Any unsupported value requested to write will throw an
#     error. It is user responsibility to provide the supported values to
#     write.
#
########################################################################

sub ReadWriteToRegistry
{
   my $interface = shift;  # required
   my $feature = shift;    # required
   my $operation = shift;  # required
   my $value = shift;      # required if <operation> is 'write'

   if ((not defined $interface) ||
      (not defined $feature) ||
      (not defined $operation)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (($operation !~ /write/i) && ($operation !~ /read/i)) {
      $vdLogger->Info("Unknown operation \"$operation\" specified");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # making sure the value to write is provided if it is a write operation
   if (($operation =~ /write/i) && (not defined $value)) {
      $vdLogger->Error("Provide value to write to registry");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # Get the hash from DeviceProperties.pm corresponding to the driver of the
   # given interface
   #
   my $localHashRef = GetDeviceConfig($interface);
   if ($localHashRef eq FAILURE) {
      $vdLogger->Info("Error returned while retrieving device config information");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Debug("Device Config Hash:" . Dumper($localHashRef) . "");
   # If given feature is marked 'NA' for the given interface in
   # DeviceProperties.pm, then error is returned
   #
   if ((not defined $localHashRef->{$feature}) ||
      ($localHashRef->{$feature} eq 'NA')) {
      VDSetLastError("ENOTIMPL");
      return FAILURE;
   }

   my $key = $localHashRef->{$feature}->{'Registry'};

   # From the registry key and value obtained above, change the registry
   # settings of the given adapter

   # Find reference to the key in windows registry
   my $interfaceKey = $Registry->{InterfaceRegistryKey($interface)};

   if (not defined $interfaceKey) {
      $vdLogger->Error("Can't find the Windows Registry interfaceKey");
      VDSetLastError("ENOENT");
      return FAILURE;
   }

   # If the feature is disabled, they sometimes do not appear in the list of
   # registry keys of the given adapter. If the code reaches this stage, it
   # confirms the feature is supported but disabled. Zero is returned if the
   # given feature is disabled on the given interface.
   #
   if ($operation =~ /read/i) {
      if (not defined $interfaceKey->{$key}) {
         $vdLogger->Error("The $feature is disabled on $interface");
         return 0;
      } else {
         # For read operation return here itself.
         return $interfaceKey->{$key};
      }
   }
   # The registry value to Enable/Disable/Default certain features are defined
   # in DeviceProperties.pm. If the user input is one of these operations, then
   # the corresponding value for the key is identified
   #
   if ($value =~ /Enable/i) {
      $value = $localHashRef->{$feature}->{'Enable'};
   } elsif ($value =~ /Disable/i) {
      $value = $localHashRef->{$feature}->{'Disable'};
   } elsif ($value =~ /Default/i) {
      $value = $localHashRef->{$feature}->{'Default'};
   }
   my $exists = 0;
   $vdLogger->Debug("Enum values:" . Dumper($interfaceKey->{"Ndi\\params\\$key\\enum"}) .
         "");
   # Check whether the given key value is among the supported enum values.
   # To avoid some invalid key values being writtent to the registry, the user
   # input value is checked against supported values
   #
   my $supportedValues = $interfaceKey->{"Ndi\\params\\$key\\enum"};
   if (not defined $supportedValues) {
      $vdLogger->Error("Invalid registry key/string being used");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   while (my ($enum, $val) = each %$supportedValues) {
      $enum =~ s/\\//g;
      if ($enum eq $value) {
         $exists = 1;
      }
   }
   # Throw error if the given value is not supported
   if (!$exists) {
      $vdLogger->Info("Given value \"$value\" to write is not supported");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   # Writing to the registry
   $interfaceKey->{$key} = [$value, "REG_SZ"];

   # Any registry changes will be effective only after restarting the device

   my $resultString = DeviceReset($interface);

   if ($resultString eq "FAILURE") {
      $vdLogger->Error("Failed to restart the device");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetInterruptModeration --
#     Routine to get the status of InterruptModeration.
#     Currently this feature is supported only on windows
#
# Input:
#     <interface> (GUID of a network adapter)
#
# Results:
#     "Enabled" or "Disabled", if the feature is enabled or disabled on the
#                              given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetInterruptModeration
{
   my $interface = shift;  # required

   if (not defined $interface) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # This operation is not supported on Linux
   if (OSTYPE != OS_WINDOWS) {
      $vdLogger->Error("Operation not supported on this OS");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
   # Read the status of Interrupt moderation from windows registry
   my $result = ReadWriteToRegistry($interface, "InterruptModeration", "READ");

   if ($result eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return ($result eq '0') ? "DISABLED" : "ENABLED";

}


########################################################################
#
# GetDriverVersion --
#     Routine to get the driver version of the adapter.
#
# Input:
#     <interface> (GUID of a network adapter or ethX)
#
# Results:
#     "Driver version as a string
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetDriverVersion
{
   my $interface = shift;  # required

   if (not defined $interface) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $drvVersion;
   if (OSTYPE == OS_LINUX) {
      my $ethtoolInfo = `ethtool -i $interface`;
      if ($? != 0) {
         $vdLogger->Warn("\'ethtool -i $interface\' command failed with " .
                         "return code $?, Output:\n$ethtoolInfo");
         return FAILURE;
      }
      my @drvInfo = split(/\n/, $ethtoolInfo);
      $drvVersion = $drvInfo[1];
      $drvVersion =~ s/version: //g;

      if ($drvVersion =~ /-/) {
         @drvInfo = split('-', $drvVersion);
         $drvVersion = $drvInfo[0];
      }
   } elsif (OSTYPE == OS_WINDOWS) {
      my $tempString = InterfaceRegistryKey($interface);
      my $interfaceKey = $Registry->{$tempString};

      unless (defined $interfaceKey) {
         $vdLogger->Error("Can't find the Windows Registry interfaceKey");
         VDSetLastError("ENOENT");
         return FAILURE;
      }
      $drvVersion = $interfaceKey->{"DriverVersion"};
   } elsif (OSTYPE == OS_MAC) {
      # lspci is not available by default in Mac OSX. However a third party
      # installer is available which can be installed on the test VM when
      # vdnet starts.
      my $lspciInfo = `lspci -nn | grep Ethernet`;
      my @lspciResultArray = split('rev', $lspciInfo);
      my $driverVersion = $lspciResultArray[scalar(@lspciResultArray) - 1];
      $driverVersion =~ m/(\d+)/g;
      $drvVersion = $1;
   } elsif (OSTYPE == OS_BSD) {
      $drvVersion = "0.0.0"; # Fix me: only way to get driver version in
                             # freebsd is vis dmesg, which has different format
                             # for different driver. Still looking for some
                             # other way (consistent) to get driver version
   } else {
      $vdLogger->Error("OS NOT Supported");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
   return $drvVersion;
}


########################################################################
#
# SetInterruptModeration --
#     Routine to change the status (enable/disable) InterruptModeration.
#     Currently this feature is supported only on windows
#
# Input:
#     <interface> (GUID of a network adapter)
#     <operation> ("Enable" or "Disable")
#
# Results:
#     "SUCCESS", if the given operation is successful on the given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetInterruptModeration
{
   my $interface = shift;  # required
   my $operation = shift;  # required

   if ((not defined $interface) ||
      (not defined $operation)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # This operation (coalescing) is not yet supported on Linux
   if (OSTYPE == OS_LINUX) {
      $vdLogger->Error("Operation Not Supported on Linux");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   } elsif (OSTYPE == OS_WINDOWS) {
      # Write to windows registry key to enable/disable Interrupt moderation
      my $result = ReadWriteToRegistry($interface,
                                       "InterruptModeration",
                                       "WRITE",
                                       $operation);

      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      return SUCCESS;
   } else {
      $vdLogger->Error("OS NOT Supported");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# GetOffloadTCPOptions --
#     Routine to get the status of Offload TCP options on the given interface.
#     Currently this feature is supported only on windows
#
# Input:
#     <interface> (GUID of a network adapter)
#
# Results:
#     "Enabled" or "Disabled", if the feature is enabled or disabled on the
#                              given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetOffloadTCPOptions
{
   my $interface = shift;  # required

   if (not defined $interface) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # This operation is not supported on Linux
   if (OSTYPE != OS_WINDOWS) {
      $vdLogger->Error("Operation not supported on this OS");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }

   # Read windows registry to get the status of Offload TCP options on the
   # given adapter
   #
   my $result = ReadWriteToRegistry($interface, "OffloadTCPOptions", "READ");

   if ($result eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return ($result eq '0') ? "DISABLED" : "ENABLED";

}


########################################################################
#
# SetOffloadTCPOptions --
#     Routine to change the status (enable/disable) of Offload TCP options
#     Currently this feature is supported only on windows
#
# Input:
#     <interface> (GUID of a network adapter)
#     <operation> ("Enable" or "Disable")
#
# Results:
#     "SUCCESS", if the given operation is successful on the given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetOffloadTCPOptions
{
   my $interface = shift;  # required
   my $operation = shift;  # required

   if ((not defined $interface) ||
      (not defined $operation)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
   }
   # This operation is not supported on Linux
   if (OSTYPE != OS_WINDOWS) {
      $vdLogger->Error("Operation not supported on this OS");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
   # Write to windows registry to enable/disable offload tcp options on the
   # given interface
   #
   my $result = ReadWriteToRegistry($interface,
                                    "OffloadTCPOptions",
                                    "WRITE",
                                    $operation);

   if ($result eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetOffloadIPOptions --
#     Routine to get the status of Offload IP options on the given interface.
#     Currently this feature is supported only on windows
#
# Input:
#     <interface> (GUID of a network adapter)
#
# Results:
#     "Enabled" or "Disabled", if the feature is enabled or disabled on the
#                              given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetOffloadIPOptions
{
   my $interface = shift;  # required

   if (not defined $interface) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # This operation is not supported on Linux
   if (OSTYPE != OS_WINDOWS) {
      $vdLogger->Error("Operation not supported on this OS");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }

   # Read from windows registry the status of offload ip options on the given
   # interface
   my $result = ReadWriteToRegistry($interface, "OffloadIPOptions", "READ");

   if ($result eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return ($result eq '0') ? "DISABLED" : "ENABLED";

}


########################################################################
#
# SetOffloadIPOptions --
#     Routine to change the status (enable/disable) of Offload IP options
#     Currently this feature is supported only on windows
#
# Input:
#     <interface> (GUID of a network adapter)
#     <operation> ("Enable" or "Disable")
#
# Results:
#     "SUCCESS", if the given operation is successful on the given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetOffloadIPOptions
{
   my $interface = shift;  # required
   my $operation = shift;  # required

   if ((not defined $interface) ||
      (not defined $operation)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # This operation is not supported on Linux
   if (OSTYPE != OS_WINDOWS) {
      $vdLogger->Error("Operation not supported on this OS");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
   # Write to windows registry to enable/disable offload ip options on the
   # given adapter

   my $result = ReadWriteToRegistry($interface,
                                    "OffloadIPOptions",
                                    "WRITE",
                                    $operation);

   if ($result eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetRSS --
#     Routine to get the status of RSS on the given interface.
#
# Input:
#     <interface> (GUID of a network adapter or ethX)
#
# Results:
#     "Enabled" or "Disabled", if the feature is enabled or disabled on the
#                              given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetRSS
{
   my $interface = shift;  # required

   if (not defined $interface) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (OSTYPE == OS_LINUX) {
      my $rqs = `cat /proc/interrupts | grep $interface | grep Rx | wc -l`;
      if ($rqs > 1) {
         return "ENABLED";
      } else {
         return "DISABLED";
      }
   } elsif (OSTYPE == OS_WINDOWS) {
      # Read windows registry to get the status of RSS on the given interface
      my $result = ReadWriteToRegistry($interface, "RSS", "READ");

      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      return ($result eq '0') ? "DISABLED" : "ENABLED";
   } else {
      $vdLogger->Error("Operation not supported on this OS");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# IntrModParams --
#     Routine to reload the driver with the given intr mod_params.
#     This is only supported on Linux
#
# Input:
#     <interface> (ethX)
#     <driverName> (Name of the driver)
#     <modParams>  (mod_params to load)
#
# Results:
#     "SUCCESS", if the given operation is successful on the given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub IntrModParams
{
   my $interface = shift;  # required
   my $driverName = shift; # reqired
   my $modParams = shift; # required
   my $result;

   if ((not defined $interface) ||
      (not defined $driverName) ||
      (not defined $modParams)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (OSTYPE == OS_LINUX) {
      $result = DriverLoad($interface, $driverName, $modParams);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Operation not supported on this OS");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# SetRSS --
#     Routine to change the status (enable/disable) of RSS.
#
# Input:
#     <interface> (GUID of a network adapter or ethX)
#     <operation> ("Enable" or "Disable")
#
# Results:
#     "SUCCESS", if the given operation is successful on the given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetRSS
{
   my $interface = shift;  # required
   my $operation = shift;  # required
   my $driverName = shift; # reqired only for Linux
   my $result;
   my $modParams;

   if ((not defined $interface) ||
      (not defined $operation)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (OSTYPE == OS_LINUX) {
      if (not defined $driverName) {
         $vdLogger->Error("Driver name is not defined");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      # RSS can be enabled in two ways, one by passing "enable" key
      # and the other by passing num_rqs with rss_ind_table. And
      # rss_ind_table alone can be used to change the order of RSS
      # indirection table (Vmxnet3MultiqueueRSS wiki has more info).
      if ($operation =~ /enable/i) {
         $modParams = "num_tqs:0::num_rqs:0";
      } elsif ($operation =~ /disable/i) {
         $modParams = "num_tqs:1::num_rqs:1";
      } elsif ($operation =~ /rss_ind_table/i){
         $modParams = $operation;
      } else {
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $result = DriverLoad($interface, $driverName, $modParams);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } elsif (OSTYPE == OS_WINDOWS) {
      if ($operation =~ /rss_ind_table/i) {
         $vdLogger->Info("Changing indirection table is not supported on " .
                         "Windows, enabling RSS with default values");
         $operation = "enable";
      }
      # Write to windows registry to enable/disable RSS on the given interface
      $result = ReadWriteToRegistry($interface,
                                       "RSS",
                                       "WRITE",
                                       $operation);

      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Operation not supported on this OS");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetMaxTxRxQueues --
#     Routine to get the status of number of Tx or Rx queues.
#     Currently this feature is supported only on windows
#
# Input:
#     <interface> (GUID of a network adapter)
#     <type> ("Tx" or "Rx")
#
# Results:
#     "Enabled" or "Disabled", if the feature is enabled or disabled on the
#                              given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetMaxTxRxQueues
{
   my $interface = shift;  # required
   my $type = shift; #required

   if ((not defined $interface) ||
      (not defined $type)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (OSTYPE == OS_LINUX) {
      my $nqs = `cat /proc/interrupts | grep $interface | grep -i $type | wc -l`;
      return \$nqs;
   }

   if (OSTYPE != OS_WINDOWS) {
      $vdLogger->Error("Operation not supported on this OS");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
   my $devPropString;
   # Decide the hash to read from DeviceProperties.pm based on the type of
   # queues (Tx/Rx) provided at the input
   #
   if ($type =~ /Tx/i) {
      $devPropString = 'MaxTxQueues';
   } elsif ($type =~ /Rx/i) {
      $devPropString = 'MaxRxQueues';
   } else {
      $vdLogger->Error("Unknown queue type provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # Read windows registry to get the status of Tx or Rx maximum queue size
   my $result = ReadWriteToRegistry($interface, $devPropString, "READ");

   if ($result eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $result;
}


########################################################################
#
# SetMaxTxRxQueues --
#     Routine to change the number of Tx/Rx queues.
#
# Input:
#     <interface> (GUID of a network adapter or ethX)
#     <type> ("Tx" or "Rx")
#     <value> (One of these values: 1, 2, 4 or 8)
#
#
# Results:
#     "SUCCESS", if the given operation is successful on the given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetMaxTxRxQueues
{
   my $interface = shift;  # required
   my $type = shift; # required
   my $value = shift;  # required
   my $driverName = shift; # reqired only for Linux
   my $rxqSupport = shift; # Optional
   my $result;

   if ((not defined $interface) ||
      (not defined $type) ||
      (not defined $value)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (OSTYPE == OS_LINUX) {
      if (not defined $driverName) {
         $vdLogger->Error("Driver name is not defined");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      my $modParams;
      if ($type =~ /tx/i) {
         $value =~ m/(\d)/;
         $modParams = "num_tqs:$value";
      } elsif ($type =~ /rx/i) {
         $value =~ m/(\d)/;
         $modParams = "num_rqs:$value";
      } else {
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $result = DriverLoad($interface, $driverName, $modParams, $rxqSupport);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } elsif (OSTYPE == OS_WINDOWS) {
      # Decide the hash to read from DeviceProperties.pm based on the type of
      # queues (Tx/Rx) provided at the input
      #
      my $devPropString;
      if ($type =~ /Tx/i) {
         $devPropString = 'MaxTxQueues';
      } elsif ($type =~ /Rx/i) {
         $devPropString = 'MaxRxQueues';
      } else {
         $vdLogger->Error("Unknown queue type prodided");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $result = ReadWriteToRegistry($interface,
                                       $devPropString,
                                       "WRITE",
                                       $value);

      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Operation not supported on this OS");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetRxBuffers --
#     Routine to get the size of of small or large Rx buffers.
#     Currently this feature is supported only on windows
#
# Input:
#     <interface> (GUID of a network adapter)
#     <type> ("small" or "large")
#
# Results:
#     "Enabled" or "Disabled", if the feature is enabled or disabled on the
#                              given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetRxBuffers
{
   my $interface = shift;  # required
   my $type = shift;       # required

   if ((not defined $interface) ||
      (not defined $type)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # This operation is not supported on Linux
   if (OSTYPE != OS_WINDOWS) {
      $vdLogger->Error("Operation not supported on this OS");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }

   # Decide the hash to read from DeviceProperties.pm based on the type of
   # Rx buffers (small/large) provided at the input
   #
   my $devPropString;
   if ($type =~ /small/i) {
      $devPropString = 'SmallRxBuffers';
   } elsif ($type =~ /large/i) {
      $devPropString = 'LargeRxBuffers';
   } else {
      $vdLogger->Error("Unknown Rx buffer type prodided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $result = ReadWriteToRegistry($interface, $devPropString, "READ");

   if ($result eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $result;
}


########################################################################
#
# SetRxBuffers --
#     Routine to change the size of small or large Rx buffers.
#     Currently this feature is supported only on windows
#
# Input:
#     <interface> (GUID of a network adapter)
#     <type> ("small" or "large")
#     <value> (One of these values: 64, 128, 256, 512, 768, 1024, 1536, 2048,
#                                   3072, 4096, 8192)
#
#
# Results:
#     "SUCCESS", if the given operation is successful on the given interface
#     "FAILURE", in case of any error
#
# Side effects:
#
########################################################################

sub SetRxBuffers
{
   my $interface = shift;  # required
   my $type = shift;       # required
   my $value = shift;      # required

   if ((not defined $interface) ||
      (not defined $type) ||
      (not defined $value)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
   }
   # This operation is not supported on Linux
   if (OSTYPE != OS_WINDOWS) {
      $vdLogger->Error("Operation not supported on this OS");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
   # Decide the hash to read from DeviceProperties.pm based on the type of
   # Rx buffers (small/large) provided at the input
   #
   my $devPropString;
   if ($type =~ /small/i) {
      $devPropString = 'SmallRxBuffers';
   } elsif ($type =~ /large/i) {
      $devPropString = 'LargeRxBuffers';
   } else {
      $vdLogger->Error("Unknown Rx buffer type prodided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $result = ReadWriteToRegistry($interface,
                                    $devPropString,
                                    "WRITE",
                                    $value);

   if ($result eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetRingSize --
#     Routine to get ring size (Tx/Rx1/Rx2) of the given adapter
#
# Input:
#     <interface> (ethx in Linux, GUID in case of windows)
#     <type> (Tx, or Rx1, or Rx2. Rx2 is not supported on linux)
#
# Results:
#     Ring size of the given interface, in case of no error
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetRingSize
{
   my $interface = shift;  # required
   my $type = shift; # required

      if ((not defined $interface) ||
          (not defined $type)) {
         $vdLogger->Error("Insufficient parameters passed");
         VDSetLastError("EINVALID");
         return FAILURE;
      }

   if (OSTYPE == OS_LINUX) {
      # On Linux, 'ethtool -g ' is used to get ring size information of a
      # network adapter. For example, the output of
      # 'ethtool -g|--show-ring <interface>' will look like:
      # """
      # Ring parameters for eth2:
      # Pre-set maximums:
      # RX:         4096
      # RX Mini:    0
      # RX Jumbo:   0
      # TX:         4096
      # Current hardware settings:
      # RX:         256
      # RX Mini:    0
      # RX Jumbo:   0
      # TX:         512
      # """
      #
      my $devPropString;
      # Decide the string to look from ethtool output based on the type of
      # ring size (Tx/Rx1) provided at the input
      #
      if ($type =~ /Tx/i) {
         $devPropString = 'TX';
      } elsif ($type =~ /Rx1/i) {
         $devPropString = 'RX';
      } else {
         $vdLogger->Error("Unknown ring type type prodided");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      my $result = `ethtool -g $interface 2>&1`;
      #  Split the ethtool output between 'Pre-set maximums' and 'Current hardware
      #  settings'
      #
      my ($maxValues, $currentValues) = split(/Current hardware settings:/, $result);

      if ((not defined $maxValues) || (not defined $currentValues)) {
         $vdLogger->Error("Unexpected output returned: $result");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      # Parse for "TX" or "RX" under 'current hardware settings' and capture
      # the value set
      #
      if ($currentValues =~ /\n$devPropString:\s+(\S+)\n/) {
         my $result = $1;
         return $result;
      } else {
         $vdLogger->Info("Couldn't find $type details for $interface");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   } elsif (OSTYPE == OS_WINDOWS) {

      my $devPropString;
      # Decide the hash to read from DeviceProperties.pm based on the type of
      # ring size (Tx/Rx1/Rx2) provided at the input
      #
      if ($type =~ /Tx/i) {
         $devPropString = 'TxRingSize';
      } elsif ($type =~ /Rx1/i) {
         $devPropString = 'RxRing1Size';
      } elsif ($type =~ /Rx2/i) {
         $devPropString = 'RxRing2Size';
      } else {
         $vdLogger->Error("Unknown ring type type prodided");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      my $result = ReadWriteToRegistry($interface, $devPropString, "READ");

      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      return $result;
   } else {
      $vdLogger->Error("OS not supported");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }

}


########################################################################
#
# SetRingSize --
#     Routine to set ring size (Tx/Rx1/Rx2) on the given adapter
#
# Input:
#     <interface> (ethx in Linux, GUID in case of windows)
#     <type> (Tx, or Rx1, or Rx2. Rx2 is not supported on linux)
#     <value> (on Linux, any value less than maximum supported, usually 4096;
#              on Windows, one of these values:
#              32, 64, 128, 256, 512, 1024, 2048, 4096)
#
# Results:
#     "SUCCESS", if the given ring size is set without any error
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetRingSize
{
   my $interface = shift;  # required
   my $type = shift; # required
   my $value = shift;  # required

   if ((not defined $interface) ||
      (not defined $type) ||
      (not defined $value)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (OSTYPE == OS_LINUX) {
      # On Linux, 'ethtool -G|--set-ring <interface> <ring type> <value>'
      # is used to set ring size information of a
      # network adapter.
      #
      my $devPropString;
      my $max;
      # Decide the parameter (TX or RX) to use for <ring type> in the ethtool
      # command based on the user input.
      if ($type =~ /Tx/i) {
         $devPropString = 'TX';
      } elsif ($type =~ /Rx1/i) {
         $devPropString = 'RX';
      } else {
         $vdLogger->Error("Unknown ring type type prodided");
         VDSetLastError("EINVALID");
         return FAILURE;
      }

      my $getMTUValue = GetMTU($interface); # reference to MTU value is returned
      my $isJumboEnabled = 0;
      if (int($$getMTUValue) > 1500) {
	 $isJumboEnabled = 1;
      }

      # For the given ring type, find the maximum supported value. If the user
      # input is greater than the maximum value supported, then throw error
      #
      my $result = `ethtool -g $interface 2>&1`;
      my ($maxValues, $currentValues) = split(/Current hardware settings:/, $result);
      if ((not defined $maxValues) || (not defined $currentValues)) {
         $vdLogger->Info("Unexpected output returned: $result");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      if ($maxValues =~ /\n$devPropString:\s+(\S+)\n/) {
         $max = $1;
      } else {
         $vdLogger->Info("Couldn't find $type details for $interface");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      if ("$value" > "$max") { # note double quotes on $value and $max uses
                               # the actual number and not string for
                               # comparison
         $vdLogger->Info("Given ring size ($value) is greater than max value:$max ");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      # The ring type has to be tx or rx (lower case)
      $devPropString = lc($devPropString);

      # After verifying that the given value is under the maximum supported,
      # running the ethtool command to set the ring size
      #
      $result = `ethtool -G $interface $devPropString $value 2>&1`;

      # The output expected is empty space in case of success
      if ($result =~ /\S+/) {
         $vdLogger->Warn("Set ring size operation failed:$result");
      }
      # Make sure the ring size set is equal to the ring size given at the
      # input
      my $current = GetRingSize($interface, $type);

      #
      # When jumboframes are configured (lets say MTU 9000) 3 bufs/recv
      # descriptors are required per frame. Minimum size of ring is  32
      # freames, which will need (32 x 3) = 96 bufs. Hence all the ring
      # sizes programmed from  ethtool are aligned to 96 bufs  (i.e. 32
      # frames and not to 32.
      #
      if($isJumboEnabled) {
	 if ($current < ($value - 96) ||
	     $current > ($value + 96)) {
		$vdLogger->Error("Jumbo Frames are Enabled. Mismatch in the".
				" given ($value) and value set ($current)");
		VDSetLastError("EMISMATCH");
		return FAILURE;
	 }
      } elsif ($current !~ $value) {
         $vdLogger->Error("Mismatch in given ($value) and value set ($current)");
         VDSetLastError("EMISMATCH");
         return FAILURE;
      }
      return SUCCESS;
   } elsif (OSTYPE == OS_WINDOWS) {
      my $devPropString;
      # Decide the hash to read from DeviceProperties.pm for the given ring
      # type (Tx/Rx1/Rx2) corresponding to the given interface
      #
      if ($type =~ /Tx/i) {
         $devPropString = 'TxRingSize';
      } elsif ($type =~ /Rx1/i) {
         $devPropString = 'RxRing1Size';
      } elsif ($type =~ /Rx2/i) {
         $devPropString = 'RxRing2Size';
      } else {
         $vdLogger->Error("Unknown ring type type prodided");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      # Write to windows registry to change the ring size to the given value
      my $result = ReadWriteToRegistry($interface,
                                       $devPropString,
                                       "WRITE",
                                       $value);

      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      return SUCCESS;
   } else {
      $vdLogger->Error("OS NOT Supported");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
}

########################################################################
#
# DriverLoad--
#     Routine to load the driver
#
# Input:
#     <driverName>    (Name of the driver to load)
#     <module_params> (Module parameters to use while loading the
#                     driver)
#     <unload>        (flag to indicate the driver should be unloaded
#                     before loading) (optional)
#
# Results:
#     "SUCCESS", if the load is successful
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub DriverLoad
{
   my $interface    = shift; # required
   my $driverName   = shift; # required
   my $moduleParams = shift; # optional
   my $rxqSupport   = shift; # optional
   my $unload       = shift; # optional
   my @params;
   my $finalParams = " ";
   my $num_tqs;
   my $num_rqs;
   my $buddy_intr;
   my $share_tx_intr;

   if (not defined $driverName) {
      $vdLogger->Error("Insufficient params passed: should pass driver name");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # NetAdapterWorkload needs the user to pass null if the user doesn't want
   # pass any module_params. Strip that here.
   if ($moduleParams =~ /null/i) {
      undef $moduleParams;
   }

   if (defined $moduleParams) {
      if ($driverName =~ /vmxnet3/i) {
	 @params = split('::', $moduleParams);
	 foreach my $val (@params) {
            $val =~ s/:/=/;
            if (($val =~ /num_tqs/i) and ($val =~ m/(\d)/)) {
	          $num_tqs = $1;
	    } elsif (($val =~ /num_rqs/i) and ($val =~ m/(\d)/)) {
               $num_rqs = $1;
	    } elsif (($val =~ /buddy_intr/i) and ($val =~ m/(\d)/)) {
               $buddy_intr = $1;
	    } elsif (($val =~ /share_tx_intr/i) and ($val =~ m/(\d)/)) {
               $share_tx_intr = $1;
	    }
	    if ($val =~ /rss_ind_table/i) {
               my $count = $val =~ tr/://;
               while ($count != 0) {
                  $val =~ s/:/,/;
                  $count--;
               }
	    }
	    $finalParams = $finalParams . $val . " ";
	 }
      } elsif ($driverName =~ /vmxnet2/i) {
	 @params = split('::', $moduleParams);
	 foreach my $val (@params) {
            $val =~ s/:/=/;
	    $finalParams = $finalParams . $val . " ";
	 }
      } elsif ($driverName =~ /e1000/i) {
	 @params = split('::', $moduleParams);
	 foreach my $val (@params) {
            $val =~ s/:/=/;
	    $finalParams = $finalParams . $val . " ";
	 }
      }
   }

   if (OSTYPE == OS_LINUX) {
      # For vmxnet2, strip the 2 in the end since the driver name
      # actually is vmxnet
      if (($driverName !~ /vmxnet3/i) and ($driverName =~ /vmxnet/i)) {
         $driverName =~ s/\d//g;
      }
      #For pcnet32, the vmware-tools is not installed.
      #For vmxnet, the vmware-tools is installed.
      if (($driverName=~/flexible/i)) {
          my $vmtoolInfo=system("vmware-toolbox-cmd -v");
          if ( $vmtoolInfo!~/^[0-9]/) {
              $driverName="pcnet32";
	      } else {
              $driverName="vmxnet";
          }
      }
      # Get the kernel minor version
      my ($minorVersion, $majorVersion) =
                VDNetLib::Common::Utilities::GetKernelVersion("local");
      # Multiple tqs are supported from 2.6.25 but multiple rqs are
      # supported from 2.6.27 when MSI/MSI-x is enabled
      if (($driverName =~ /vmxnet3/i) and
          ($majorVersion == 2) and
          ($minorVersion < 27) and
          (($finalParams =~ /num_tqs/i) or
          ($finalParams =~ /num_rqs/i) or
          ($finalParams =~ /buddy_intr/i) or
          ($finalParams =~ /share_tx_intr/i) or
          ($finalParams =~ /rss_ind_table/i))) {
         $vdLogger->Error("Multiqueues are not supported for this kernel");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      # Check if the interrupt mode is INTx, if it is, set multi rx queues
      # to 1 since it's not supported in this mode.
      my $intr = `cat /proc/interrupts | grep $interface`;
      if ($driverName eq "vmxnet" || $driverName eq "pcnet32") {
	      $vdLogger->Info("The driver is $driverName");
      } elsif ($intr =~ /IO-APIC/i) {
	     $finalParams =~ s/num_rqs=$num_rqs/num_rqs=1/i;
         $num_rqs = 1;
      }
      #
      # unload the driver by default before loading it
      #
      $unload = (defined $unload) ? $unload : 1;
      my $result;
      if ($unload) {
         my $unloadCmd = "modprobe -r $driverName";
         $result = system($unloadCmd);
         if ($result) {
            $vdLogger->Error("Driver unload error:$result");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      }

      my $loadCmd = "modprobe $driverName";
      system("dmesg -c");
      if (defined $moduleParams) {
         $loadCmd = $loadCmd . $finalParams;
      }
      $vdLogger->Info("Loading driver with params:$loadCmd");
      $result = system($loadCmd);
      if ($result) {
         $vdLogger->Error("Error:$result");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      my $timeout = DEFAULT_TIMEOUT;
      while ($timeout > 0) {
         my $cmd = `ifconfig $interface`;
         if ($cmd =~ /hwaddr/i) {
            last;
         } else {
            sleep DEFAULT_SLEEP;
            $timeout = $timeout - 20;
         }
      }

      # Sometimes after module load, the interface is not coming UP,
      #	so do it explictly.
      system("sleep 2; ifconfig $interface up");

      if ($driverName =~ /vmxnet3/i) {
         my $dmesg = `dmesg`;

         # Get the driver version
      my $ethtoolInfo = `ethtool -i $interface`;
      my @driverInfo = split('\.', $ethtoolInfo);
	 # From CLN 1242878, if the user doesn't pass num_tqs and/or num_rqs
         # module_params while loading vmxnet3 driver, we allocate as many
	 # queues as vCPUs.
         # We allocate only 1 tx/rx queue in this case for driver versions
         # between 1.0.16.0 to 1.0.23.0. So this change only applies for
         # driver versions >= 1.0.24.0
	 # But if the user passes 0 to either one or both of these module_params
	 # then the driver allocates as many queues as vCPUs.
         # The drivers from vmcore-main have versions like 1.1.X.0, so we
         # should take care of that too.
	 if (($finalParams !~ /num_tqs/i) and ($finalParams !~ /num_rqs/i)) {
	    if (($driverInfo[2] >= 24) || ($driverInfo[1] == 1)) {
	       $num_tqs = $num_rqs =
				`cat /proc/cpuinfo | grep processor | wc -l`;
	    } else {
	       $num_tqs = $num_rqs = 1;
	    }
	 } elsif ($finalParams !~ /num_rqs/i) {
	    if (($driverInfo[2] >= 24) || ($driverInfo[1] == 1)) {
	       $num_rqs = `cat /proc/cpuinfo | grep processor | wc -l`;
	    } else {
	       $num_rqs = 1;
	    }
	 } elsif ($finalParams !~ /num_tqs/i) {
	    if (($driverInfo[2] >= 24) || ($driverInfo[1] == 1)) {
	       $num_tqs = `cat /proc/cpuinfo | grep processor | wc -l`;
	    } else {
	       $num_tqs = 1;
	    }
         } elsif (($num_tqs == 0) and ($num_rqs == 0)) {
	    $num_tqs = $num_rqs = `cat /proc/cpuinfo | grep processor | wc -l`;
         } elsif ($num_tqs == 0) {
	    $num_tqs = `cat /proc/cpuinfo | grep processor | wc -l`;
         } elsif ($num_rqs == 0) {
	    $num_rqs = `cat /proc/cpuinfo | grep processor | wc -l`;
	 }
	 # Remove the trailing spaces, if any.
	 chomp($num_tqs);
	 chomp($num_rqs);

	 # For vmxnet3 Number_of_Max_Tx_Queues = Number_of_Max_Rx_Queues = 8
	 if ($num_tqs > 8) {
	    $num_tqs = 8;
	 }
	 if ($num_rqs > 8) {
	    $num_rqs = 8;
	 }

         # Check if the rxqSupport flag is set to 0. If yes, then multi
         # Rx queue are not supported in the currently set interrupt mode.
         if ((defined $rxqSupport) && $rxqSupport == 0) {
            $finalParams =~ s/num_rqs=$num_rqs/num_rqs=1/i;
	    $num_rqs = 1;
         }

	 #
         # This check is only applicable for driver versions 1.0.16.0 or later
	 # and kernel versions >= 2.6.25. For multi rqs the kernel version should
         # be at least 2.6.27.
	 #
	 if (($driverInfo[2] >= 16) and
             ($minorVersion >= 27 || $majorVersion > 2)) {
            my $str   = "# of Tx queues : " . $num_tqs . ", # of Rx queues : "
			. $num_rqs;
            if ($dmesg !~ /$str/i) {
               $vdLogger->Error("Error: Driver loaded with incorrect no. of " .
				"queues! Expected: $num_tqs tx and $num_rqs" .
				" rx queues");
               VDSetLastError("EOPFAILED");
               return FAILURE;
            }
            system("sleep 5");

            # MSIx interrupts count depends on what module_params the user passes
            #
            # If the user only passes buddy_intr (this case is same as passing none
            # buddy_intr or share_tx_intr)
            # if num_tqs = num_rqs then total vectors = num_rqs + 1 for events
            # otherwise it is num_tqs + num_rqs + event
            #
            # If the user only passes share_tx_intr or passes both buddy_intr
            # and share_tx_intr
            # it will always be 1 (for all tx queues) + num_rqs + event
            # irresective of number of tx/rx queues
            #
            # If the VM has lot of vmxnet3 adapters then most of MSIx vectors gets
            # used up so it will only allocate 2 vectors 1 (for all tx/rx) + 1 for
            # events.
            my $intrs_count = `cat /proc/interrupts | grep $interface | wc -l`;

            if (($finalParams =~ /buddy_intr/i) and
	        ($finalParams =~ /share_tx_intr/i)) {
               if ($intrs_count != (1 + $num_rqs + 1)) {
                  $vdLogger->Warn("Incorrect number of MSIx intrs");
               }
            } elsif ($finalParams =~ /buddy_intr/i) {
               if (($num_tqs == $num_rqs) and ($intrs_count != ($num_rqs + 1))) {
                  $vdLogger->Warn("Incorrect number of MSIx intrs");
               } elsif (($num_tqs != $num_rqs) and
	               ($intrs_count != ($num_tqs + $num_rqs + 1))) {
                  $vdLogger->Warn("Incorrect number of MSIx intrs");
               }
            } elsif ($finalParams =~ /share_tx_intr/i) {
               if ($intrs_count != (1 + $num_rqs + 1)) {
                  $vdLogger->Warn("Incorrect number of MSIx intrs");
               }
            } elsif ($driverInfo[2] >= 16) {
               if (($num_tqs == $num_rqs) and ($intrs_count != ($num_rqs + 1))) {
                  $vdLogger->Warn("Incorrect number of MSIx intrs");
               } elsif (($num_tqs != $num_rqs) and
	               ($intrs_count != ($num_tqs + $num_rqs + 1))) {
                  $vdLogger->Warn("Incorrect number of MSIx intrs");
               }
            }
         }
      }
      return SUCCESS;
   } elsif (OSTYPE == OS_WINDOWS) {
      #TODO
      $vdLogger->Error("Windows is not support yet");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   } else {
      $vdLogger->Error("OS NOT Supported");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
}

########################################################################
#
# DriverUnload--
#     Routine to unload the driver
#
# Input:
#     <driverName> (Name of the driver to unload)
#
# Results:
#     "SUCCESS", if the unload is successful
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub DriverUnload
{
   my $driverName = shift;  # required

   if (not defined $driverName) {
      $vdLogger->Error("Insufficient params passed: should pass driver name");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

	if (OSTYPE == OS_LINUX) {
      # For vmxnet2, strip the 2 in the end since the driver name
      # actually is vmxnet
      if (($driverName !~ /vmxnet3/i) and ($driverName =~ /vmxnet/i)) {
         $driverName =~ s/\d//g;
      }
      if ( $driverName=~/flexible/i ) {
		my $vmtoolInfo=system("vmware-toolbox-cmd -v");
		if ( $vmtoolInfo!~/^[0-9]/) {
			$driverName="pcnet32";
		} else {
			$driverName="vmxnet";
         }
      }
	  my $unloadCmd = "modprobe -r $driverName";
	  my $result = system($unloadCmd);
      if ($result) {
         $vdLogger->Error("Error:$result");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      return SUCCESS;
   } elsif (OSTYPE == OS_WINDOWS) {
      # TODO
      $vdLogger->Error("Windows is not support yet");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   } else {
      $vdLogger->Error("OS NOT Supported");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
}

########################################################################
#
# UpdateDefaultGW --
#      The routine adds/deletes the given interface as default gateway
#      interface in routing table on a linux machine.
#
# Input:
#      interface: ethX or ip address of the interface (Required)
#      action   : "add" or "delete" (Optional, default is add)
#      defaultGW: default gateway address (Optional)
#
# Results:
#      "SUCCESS", if the default gateway route is updated successfully;
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub UpdateDefaultGW
{
   my $interface = shift;
   my $action = shift || "add";
   my $defaultGW = shift;
   my $defaultInterface;
   my $gatewayInterface;

   if (not defined $interface) {
      $vdLogger->Error("Interface not provided to update gateway");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $command;
   if (OSTYPE == OS_LINUX) {
      if ($interface =~ /(\d+\.\d+\.\d+\.\d+)/) {
         # ip address if given, find the adapter interface that has this ip
         # address.
         $command = `ifconfig |grep -B 2 $interface`;
         if ($command =~ /eth(\d+)/i) {
            $interface = "eth" . $1;
         } else {
            $vdLogger->Error("Interface name not found for given " .
                             "address $interface");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      }
      return SUCCESS;
   } elsif (OSTYPE == OS_MAC) {
      if ($interface =~ /(\d+\.\d+\.\d+\.\d+)/) {
         # ip address if given, find the adapter interface that has this ip
         # address.
         $command = `system_profiler SPNetworkDataType | grep $interface`;
         my  $adapter = "";
         my @commandResultArr = split("\n",$command);
         for(my $i = 0 ;$i<@commandResultArr ;$i++) {
            if($commandResultArr[$i] =~ m/BSD/i && $commandResultArr[$i] =~ m/Device/i) {
               my @deviceNameArr = split(":", $commandResultArr[$i]);
               $adapter = $deviceNameArr[@deviceNameArr - 1];
               $adapter =~ s/^ *//;
               $adapter =~ s/ *$//;
            }
         }
         if($adapter =~ /en(\d+)/i) {
            $interface = "en".$1;
         } else {
            $vdLogger->Error("Interface name not found for given " .
                             "address $interface");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      }
      # This is assuming any other interface connecting to any other gateway is
      # not present. For example in corporate systems, the interface connected to
      # the vmware corporate n/w will have a different gateway, and the one
      # connected to vmwair will have a different gateway.
      if (not defined $defaultGW) {
         # A sample output for the command below:
         # default            10.20.135.253      UGSc           16        3     en0
         # default            link#5             UCSI            2        0     en2
         # default            192.168.23.253     UGScI           1        0     en1
         # default            link#10            UCSI            0        0   vlan0

         $command = `netstat -nr | grep default`;
         if ($command =~ /default\s+(\d+\.\d+\.\d+\.\d+)\s+UG\s+(\d)\s+(\d)\sen(\d)/gi) {
            $defaultGW = $1;
            # assuming the for all guest the device name starts with "en".
            $gatewayInterface = "en".$4;
         }
      }
      $command = "route add default $defaultGW";
      # run the command to add/delete default gatewayi
      system($command);

      # making sure that the expected change happened in the routing table
      $command = `netstat -nr | grep default`;
      if ($command !~ /default\s+(\d+\.\d+\.\d+\.\d+)\s+UG\s+(\d)\s+(\d)\s$defaultInterface/gi) {
         $vdLogger->Error("The default gateway failed to update");
         VDSetLastError("EMISMATCH");
         return FAILURE;
      }
   }
   return SUCCESS;
}

########################################################################
#
# SetMACAddr --
#     Routine to set the MAC address
#
# Input:
#     <valid NetAdapter object>
#     <mac> (User passed MAC address)
#
# Results:
#     "SUCCESS", if the load is successful
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetMACAddr
{
   my $interface = shift; # required
   my $mac = shift;  # Required

   if (not defined $mac) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   $mac = uc($mac);
   # Check the validity of the MAC address
   my @params = split(':', $mac);
   foreach my $val (@params) {
      if ($val !~ /^[0-9A-F]{1,4}$/i) {
         $vdLogger->Error("Invalid MAC address passed");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   }

   if (OSTYPE == OS_LINUX) {
      my $cmd = "ifconfig $interface hw ether $mac";
      my $result = system($cmd);
      if ($result) {
         $vdLogger->Error("Setting mac address failed with error:$result");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   } elsif (OSTYPE == OS_WINDOWS) {
      #
      # On windows, MAC is set/reset on the given adapter using the
      # registry settings.
      # Get the Registry key value for SetMAC for the given
      # interface using the GetDeviceConfig() routine which reads
      # hash exported by DeviceProperties.pm
      # TODO: Check if the given mac address is allowed.
      #

      my $localHashRef = GetDeviceConfig($interface);
      if ($localHashRef eq FAILURE) {
         $vdLogger->Info("Error returned while retrieving device config information");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      # SetMAC is usually supported on all devices and all of them have
      # same RegistryKey. Still checking just to make sure
      if ($localHashRef->{'SetMAC'} eq 'NA') {
         VDSetLastError("ENOTSUP");
         return FAILURE;
      }

      my $key = $localHashRef->{'SetMAC'}->{'Registry'};
      my $value = $mac;

      # Windows registry does not accept any - or : in MAC address;
      $vdLogger->Info("Key:$key, value:$value");
      $value =~ s/(:|-)//g;

      if ((not defined $key) || (not defined $value)) {
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      # Now that we have registry key and value obtained above, change the registry
      # settings of the given adapter
      my $tempString = InterfaceRegistryKey($interface);
      my $interfaceKey = $Registry->{$tempString};

      if (not defined $interfaceKey) {
         $vdLogger->Error("Can't find the Windows Registry interfaceKey");
         VDSetLastError("ENOENT");
         return FAILURE;
      }

      # Writing to the registry
      $interfaceKey->{$key} = [$value, "REG_SZ"];

      # Any registry changes require device reset for the changes to be
      # effective
      #
      my $resultString = DeviceReset($interface);

      if ($resultString eq "FAILURE") {
         $vdLogger->Error("Failed to change interface state");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

   } else {
      $vdLogger->Error("OS NOT Supported");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }

   # Checking if the desired mac address was set
   my $newMAC = ${&GetMACAddress($interface)};
   if ($newMAC eq $mac) {
      $vdLogger->Info("MAC address set successfully");
      return SUCCESS;
   } else {
      $vdLogger->Error("MAC address set to wrong value: $newMAC");
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }
}


########################################################################
#
# GetNetworkAddr --
#       This function gets the IPv4, broadcast and subnet mask
#
# Input:
#       Interface (ethx - in case of linux; device id in case of windows)
#
# Results:
#       string that contains IPv4 address, if success
#       -1, in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetNetworkAddr($)
{
   my $interface = shift;
   my ($ipAddr, $subnet);
   my $addressHash;

   unless (defined $interface) {
      $vdLogger->Error("Invalid Argument passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (OSTYPE == OS_LINUX) {
      # Using ifconfig output to get IP address on linux machines
       $addressHash->{ipv4} = ReadIfConfig($interface, "ipv4");
       $addressHash->{netmask} = ReadIfConfig($interface, "subnet");
       $addressHash->{broadcast} = ReadIfConfig($interface, "broadcast");
       return $addressHash;
   } elsif (OSTYPE == OS_WINDOWS) {
      # Using Win32::NetworkAdapterConfiguration WMI class to get ipv4 address
      # on windows
      $ipAddr = ReadWin32NetAdapterConfigValue($interface, "IPAddress");
      if (FAILURE eq $ipAddr) {
         $vdLogger->Error("Invalid IP address returned");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } elsif ("NULL" eq $ipAddr){
         $vdLogger->Warn("No IP address returned from" . Dumper($interface));
      } else {
         my @derefArray = @$ipAddr;
         $addressHash->{ipv4} = $derefArray[0];
      }
      # Using Win32::NetworkAdapterConfiguration WMI class to get ipv4 address
      # on windows
      $subnet = ReadWin32NetAdapterConfigValue($interface,"IPSubnet");
      if (FAILURE eq $subnet) {
         $vdLogger->Error("Invalid Subnet Mask returned");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } elsif ("NULL" eq $subnet){
         $vdLogger->Warn("No Subnet Mask returned from" . Dumper($interface));
      } else {
         my @derefArray = @$subnet;
         $addressHash->{subnet} = $derefArray[0];
      }
      ## Calculating Broadcast address from subnet mask
      my $bcast = "";
      my @ipSplitArray = split('\.',$addressHash->{ipv4});

      my @octets = split('\.',$addressHash->{subnet});
      my $firstOctet = 255 - int($octets[0]);
      my $secondOctet = 255 - int($octets[1]);
      my $thirdOctet = 255 - int($octets[2]);
      my $fourthOctet = 255 - int($octets[3]);

      if($firstOctet == 0) {
         $bcast = $ipSplitArray[0];
      } else {
         $bcast =  $firstOctet;
      }
      if($secondOctet == 0) {
         $bcast = $bcast . "." . $ipSplitArray[1];
      } else {
         $bcast = $bcast . "." . $secondOctet;
      }
      if($thirdOctet == 0) {
         $bcast = $bcast . "." . $ipSplitArray[2];
      } else {
         $bcast =  $bcast . "." . $thirdOctet;
      }
      if($fourthOctet == 0) {
         $bcast = $bcast . "." . $ipSplitArray[3];
      } else {
         $bcast =  $bcast . "." . $fourthOctet;
      }
      $vdLogger->Trace("Brodcast address calculated is:$bcast");
      $addressHash->{broadcast} = $bcast;
      return $addressHash;
   } elsif (OSTYPE == OS_MAC) {
      # Using ifconfig output to get IP address on mac machines
       $addressHash->{ipv4} = ReadMacOSIfConfig($interface, "ipv4");
       $addressHash->{netmask} = ReadMacOSIfConfig($interface, "subnet");
       $addressHash->{broadcast} = ReadMacOSIfConfig($interface, "broadcast");
       return $addressHash;
   }
   else {
      $vdLogger->Error("OS NOT SUPPORTED");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# EditToolsScripts --
#       Edits the VMware Tools scripts for configuring static IP. Creates
#       script if it does not exists. The reason to choose this approach
#       was that editing network scripts on different flavors of different
#       linux distributions would require high mantaince as each flavor
#       has different network-script dir, filename and different format
#       to represent static ip. Also it would make this API OS-Aware.
#       We want to keep it OS-agnostic.
#
# Input:
#       Interface (ethx - in case of linux; device id in case of windows)
#
# Results:
#       string that contains IPv4 address, if success
#       -1, in case of error
#
# Side effects:
#       None. Since we create the parent directories of VMware Tools
#       even if VMware Tools is not install this method will work
#       Thus we create the script irrespective of Tools installation.
#       If it is installed then it resets the IP after resume operation
#       and then call our script which will set the IP again.
#       If it is not installed then there is no one to reset the IP
#       after a resume operation. Thus this method won't have side
#       effects
#
########################################################################

sub EditToolsScripts($$$)
{
   my ($interface, $line) = @_;
   my ($arg, $ret, $newLine, $oldLine, $file);
   if (not defined $interface || not defined $line) {
      $vdLogger->Error("Parameters missing in EditToolsScripts");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # VMware Tools gives the option of writing user scripts.
   # We create user script to set static ip as VMware Tools
   # resets it after doing a resume and revert operation.
   #
   foreach my $userScript (@toolsScriptsPath) {
      #
      # User defined script location is
      # /etc/vmware-tools/scripts/resume-vm-default.d/ for
      # scripts to run after resume operation.
      #
      my $dir = $userScript . "scripts/resume-vm-default.d/";
      unless (-d $dir) {
         my $command = "mkdir -p " . $dir;
         my $stdout = system($command);
         if ($stdout) {
            $vdLogger->Error("Execute $command returned:". $stdout);
            VDSetLastError("EFAILED");
            return FAILURE;
         }
      }
      #
      # We are creating file
      # /etc/vmware-tools/scripts/resume-vm-default.d/vdnet_static_ip
      # to store static ips for DUT
      #
      $file = "$dir" . "vdnet_static_ip";
      unless (-e $file) {
         my $command = "touch " . $file;
         my $stdout = system($command);
         if ($stdout) {
            $vdLogger->Error("Execute $command returned:". $stdout);
            VDSetLastError("EFAILED");
            return FAILURE;
         }
         # Making our script executable
         $command = "chmod 777 " . $file;
         $stdout = system($command);
         if ($stdout) {
            $vdLogger->Error("Execute $command returned:". $stdout);
            VDSetLastError("EFAILED");
            return FAILURE;
         }
      }
      # Assuming we will always use 192.x.x.x range ips for test
      # interfaces
      $oldLine = "ifconfig $interface 192";
      # This is for IPv6 address.
      $oldLine = "ifconfig $interface add" if $line !~ /netmask/i;
      $newLine = $line;
      $arg = "$file"."\*"."'modify'"."\*"."$newLine"."\*"."$oldLine";
      $ret = VDNetLib::Common::Utilities::EditFile($arg);
      if ($ret eq FAILURE) {
         $vdLogger->Error("Failed to modify IPADDR entry in ".
                          "network-scripts");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Info("Configured static ip in file:$file");
      return SUCCESS;
   }
   $vdLogger->Error("EditToolsScripts: Not able to configure static ip");
   VDSetLastError(VDGetLastError());
   return FAILURE;
}



########################################################################
#
# SetLRO --
#     Routine to set lro on device.
#
# Input:
#     <interface> (ethX)
#     <driverName> (Name of the driver)
#     <modParams>  (mod_params to load)
#
# Results:
#     "SUCCESS", if the given operation is successful on the given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetLRO
{
   my $interface = shift;  # required
   my $driverName = shift; # reqired
   my $action = shift; # required
   my $result;
   my $flag = 1;

   if ((not defined $interface) ||
      (not defined $driverName) ||
      (not defined $action)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (OSTYPE != OS_LINUX) {
      $vdLogger->Error("Operation not supported on this OS");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }

   # For vmxnet3
   # Use driver reload for kernel
   # versions += 2.6.18 and <= 2.6.24,
   # E.g. modprobe vmxnet disalbe_lro=0
   # Beyond 2.6.24, we need to use ethtool to set/get LRO
   # For rest of the drivers (vmxnet2 for now)
   # We will use reloading the driver with appropriate params
   #
   if ($driverName =~ /vmxnet3/i) {
      #
      # Get the kernel version
      #
      my ($minorVersion, $majorVersion) =
                VDNetLib::Common::Utilities::GetKernelVersion("local");

      if (($majorVersion != 2) || ($minorVersion > 24)) {
         #
         # We will use SetOffload method which uses ethtool to set lro
         #
         $result = SetOffload($interface, "LRO", $action);
         if ($result eq FAILURE) {
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $flag = 0;
      } else {
         $flag = 1;
      }
   }

   if ($flag == 1) {
      #
      # We will use driver reload to enable/disable lro
      #
      if ($action =~ /enable/i) {
         $action = "disable_lro:0";
      } else {
         $action = "disable_lro:1";
      }
      $result = DriverLoad($interface, $driverName, $action);
      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      # DriverLoad method clears the dmesg before loading driver.
      # Thus current dmesg will tell us the state of the loaded driver.
      # We are relying on this line of dmesg
      # features: sg csum vlan jf tso lro tsoIPv6 highDMA
      my $dmesg = `dmesg`;
      if (($action =~ /0$/) && ($dmesg =~ / (lro|lpd) ?/)) {
         $vdLogger->Info("LRO enabled on $interface, $driverName");
      } elsif (($action =~ /1$/) && ($dmesg !~ /lro/)) {
         $vdLogger->Info("LRO disabled on $interface, $driverName");
      } else {
         $vdLogger->Error("Reloading $interface, $driverName with ".
                         "LRO settings failed");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
   }

   return $result;
}


########################################################################
#
# SetPriorityVLAN --
#     Method to set the PriorityVLAN for any vmxnet3 driver in Windows.
#
# Input:
#     <interface> (GUID of a network adapter or ethX)
#     <parameter> ("Priority" or "VLAN")
#     <operation> ("Enable" or "Disable")
#
# Results:
#     "SUCCESS", if the given operation is successful on the given interface
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetPriorityVLAN
{
   my $interface = shift;
   my $parameter = shift;
   my $operation = shift;
   my $result;
   my $modParams;

   if ((not defined $interface) ||
      (not defined $parameter) ||
      (not defined $operation)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (OSTYPE == OS_WINDOWS) {
      # Write to windows registry to enable/disable Priority/VLAN on the given
      # interface
      $result = ReadWriteToRegistry($interface,
                                       $parameter,
                                       "WRITE",
                                       $operation);

      if ($result eq FAILURE) {
         $vdLogger->Error("Operation to $operation PriorityVLAN failed");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Operation not supported on this OS");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
   # Checking whether retrieved value is the same as the set value
   my $checkResult = GetPriorityVLAN($interface, $parameter);
   if ($checkResult =~ /$operation/i) {
      $vdLogger->Info("Priority set to $operation successfully");
      return SUCCESS;
   } else {
      $vdLogger->Error("Priority set operation failed");
      return FAILURE;
   }
}


########################################################################
#
# GetPriorityVLAN --
#     Method to get the PriorityVLAN set for any vmxnet3 driver in Windows.
#
# Input:
#     <interface> (GUID of a network adapter or ethX)
#     <parameter> ("Priority" or "VLAN")
#
# Results:
#     VLANPriority, if retrieved
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetPriorityVLAN
{
   my $interface = shift;
   my $parameter = shift;

   if ((not defined $interface) ||
       (not defined $parameter)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (OSTYPE == OS_WINDOWS) {
      # Read windows registry to get the status of PriorityVLAN on the
      # given interface
      my $result = ReadWriteToRegistry($interface, $parameter, "READ");

      if ($result eq FAILURE) {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      return ($result eq '0') ? "DISABLED" : "ENABLED";
   } else {
      $vdLogger->Error("Operation not supported on this OS");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }
}


########################################################################
#
# ConfigureRoute
#     Routine to add/del ipv4 and ipv6 routes
#
# Input:
#     routeOperation - add or delete
#     network     - Network address to be added. Default value is "default"
#                   (Optional)
#     gateway     - Gateway address to be added
#     ipv6Gateway - IPv6 Gateway address to be added
#     netmask     - Netmask value to be added. Default is 0 (Optional)
#     interface   - Interface to use for that route
#
# Results:
#     SUCCESS, if the route is added successfully;
#     FAILURE, in case of any error
#
# Side effects:
#     This entry in routing table will take precedence over any default
#     configuration
#
########################################################################

sub ConfigureRoute
{
   my $routeOperation = shift; # add,delete
   my $network        = shift || '0.0.0.0';
   my $netmask        = shift || '0.0.0.0';
   my $gateway        = shift;
   my $interface      = shift;
   my $routeCmd;
   # XXX(gjayavelu): Fix this hack and enable ExecuteRemoteMethod to accept
   # kwargs.
   if ($netmask eq 'undef') {
       $netmask = undef;
   }
   if ($gateway =~ /:/) {
      # For ipv6 based gateway
      $routeCmd = "route -A inet ";
   } else {
      $routeCmd = "route ";
   }

   if ($routeOperation =~ /add/i) {
      $routeCmd = $routeCmd . "add"
   } elsif ($routeOperation =~ /delete/i) {
      $routeCmd = $routeCmd . "del"
   } else {
      $vdLogger->Error("Unknown route operation");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   if (Net::IP::ip_iptobin($network, 4) eq Net::IP::ip_iptobin("0.0.0.0", 4)) {
      $routeCmd = $routeCmd . " default";
   } elsif ($gateway =~ /:/) {
      # For ipv6 based gateway
      $routeCmd = $routeCmd . " $network\:\:\/$netmask" if defined $netmask;
   } else {
      $routeCmd = $routeCmd . " -net $network netmask $netmask" if defined $netmask;
   }

   $routeCmd = $routeCmd . " gw $gateway";

   if ($gateway !~ /:/) {
      # For ipv4 routes
      $routeCmd = $routeCmd . " dev $interface" if defined $interface;
   }

   $vdLogger->Debug("Executing command: $routeCmd");
   my $result = `$routeCmd 2>&1`;

   my $allRoutes = `route -n`;
   $vdLogger->Debug("Routes after reconfiguration:\n $allRoutes");

   if (($result ne "") && ($result !~ /file exists/i)) {
      my $errMsg = undef;
      if (defined $interface) {
          $errMsg = "Route config on $interface failed with error: $result";
      } else {
          $errMsg = "Route config failed with error: $result";
      }
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $allRoutes = `route -n`;
   my $network_index = 0;
   my $gateway_index = 1;
   my $interface_index = -1;
   my @lines = split(/\n/, $allRoutes);
   my $found = 0;
   foreach my $line (@lines) {
      my @temp = split(/\s+/, $line);
      if (((defined $network) ? ($temp[$network_index] eq $network) : 1) &&
          ((defined $gateway) ? ($temp[$gateway_index] eq $gateway) : 1) &&
          ((defined $interface) ? ($temp[$interface_index] eq $interface) : 1)) {
            $found = 1;
            return SUCCESS if ($routeOperation =~ /add/i);
      }
   }

   if (($routeOperation =~ /add/i) && (!$found)) {
      $vdLogger->Error("No routes configured for $interface matching " .
                       "network $network and gateway $gateway in routes:\n " .
                       $allRoutes);
      VDSetLastError("EOPVERIFY");
      return FAILURE;
   } elsif (($routeOperation =~ /delete/i) && ($found)) {
      $vdLogger->Error("Routes found matching network $network after delete " .
                       "operation");
      VDSetLastError("EOPVERIFY");
      return FAILURE;
   }
   return SUCCESS;
}

1;
