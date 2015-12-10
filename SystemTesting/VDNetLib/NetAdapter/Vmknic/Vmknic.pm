##########################################################################
# Copyright (C) 2010 VMware, Inc.
# All Rights Reserved
################################################################################
package VDNetLib::NetAdapter::Vmknic::Vmknic;

# File description:
# This module contains all the methods that should be used for any functions
# pertaining to vmknic on the ESXi server

# Used to enforce coding standards
use strict;
use warnings;
use FindBin;
# Inheriting from VDNetLib::NetAdapter::NetAdapter package.
use vars qw /@ISA/;
@ISA = qw(VDNetLib::NetAdapter::NetAdapter);
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::Utilities;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                           VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use Data::Dumper;
use VDNetLib::Suites::TAHI;
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              ConfigureLogger
                                              ConvertToPythonBool
                                              CallMethodWithKWArgs) ;

# Path of the binary in ESXi
our $vmknicBin = "/sbin/esxcfg-vmknic";
our $routeBin = "/sbin/esxcfg-route";
our $vmknicEsxcli = "/sbin/esxcli network ip";
our $vmnicEsxcli = "/sbin/esxcli network nic";
our $vswitchEsxcli = "/sbin/esxcli network vswitch standard";
# Default values of LRO Enabled and Disabled flags
our $LROEnable = 5;
our $LRODisable = 1;

# TCPIP4 instances VSI tree path
our $tcpipVSIPath = "/net/tcpip/instances";

################################################################################
#
# new --
#      Creates an object instance of Vmknic object.
#
# Input:
#      pgName   : portgroup name of the vmknic (Required)
#                 (for vmknic, portgroup name is unique identifier)
#      controlIP: ip address of the host on which the given vmnic
#                 exists (Required)
#      hostObj  : Host operations object (Mandatory)
#
# Results:
#      Reference to required Vmknic is returned.If the object is
#      not created FAILURE is returned
#
# Side effects:
#      None
#
################################################################################

sub new
{
   my $class = shift;
   my %args = @_;
   my $self;
   $self->{controlIP}  = $args{controlIP};
   $self->{hostObj}    = $args{hostObj};
   $self->{pgName}     = $args{pgName};
   $self->{deviceId}   = $args{deviceId};
   $self->{switchObj}  = $args{switchObj};
   $self->{switchType} = $args{switchObj}{switchType} || "vswitch";
   $self->{switch}     = $args{switchObj}{switch} || undef;
   $self->{netstackObj} = $args{netstackObj};
   $self->{driver}     = "vmkernel";
   $self->{_pyIdName} = "name";
   $self->{'name'} = $self->{deviceId};
   $self->{parentObj} = $self->{hostObj};
   $self->{_pyclass} = "vmware.vsphere.esx.vmknic.vmknic_facade.VmknicFacade";
   if (not defined $self->{controlIP} ||
       not defined $self->{pgName} ||
       not defined $self->{hostObj}) {
      $vdLogger->Error("Hostname and/or interface not passed for creating " .
                        "object of VDNetLib::NetAdapter::Vmknic::Vmknic");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $self->{hostName} = $self->{controlIP};

   bless ($self,$class);

   if (not defined $self->{deviceId}) {
      $vdLogger->Error("Device id is not defined for vmknic ".
                       "attached to portgroup $self->{pgName}");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Retrieving the properties of the vmknic required
   if ($self->GetVmknicProperties() eq FAILURE) {
      $vdLogger->Error("Unable to retrieve properties of vmknic specified");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # vds specfic information.
   if ($self->{switchType} =~ m/vdswitch/i) {
      my $client = $self->{deviceId};
      my $result = $self->{switchObj}->GetDVSPortIDForAnyNIC($self->{hostObj},
                                                             $client);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to retreive the vds port id for $client");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $self->{dvport} = $result;
   }

   # tcpip instance name to which this vmknic belongs is part of...
   if (not defined $self->{netstackObj}) {
      $self->{netstackName} = "defaultTcpipStack";
   } else {
      $self->{netstackName} = $self->{netstackObj}->{netstackName};
   }

   return $self;
}


################################################################################
#
# GetVmknicProperties -
#  Get Vmknic properties for a specified vmknic. Returns SUCCESS if it
#  is successful.
#
# Input -
#  None.
#
# Results -
#  Returns SUCCESS if successful
#  Returns FAILURE if properties were not retrieved / specified vmknic is not
#  found
#
# Side effects -
#  None
#
################################################################################

sub GetVmknicProperties
{
   my $self = shift;
   my $vmknicHash;

   my $host = $self->{hostObj}->{hostIP};
   $vmknicHash = $self->{hostObj}->GetAdapterInfo(deviceId => $self->{deviceId});
   if ($vmknicHash eq FAILURE) {
      $vdLogger->Error("Failed to get info of $self->{deviceId} on host $host");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $self->{macAddress} = $vmknicHash->{mac};
   $self->{MTU} = $vmknicHash->{mtu};
   $self->{IP} = $vmknicHash->{ipv4};
   $self->{netmask} = $vmknicHash->{netmask};
   $self->{broadcast} =
   VDNetLib::Common::Utilities::GetBroadcastFromIPandNetMask($self->{IP},
                                                             $self->{netmask});

   #
   # if $vmknicHash->{ipv6} is defined then call
   # listIPv6 so that we get all ipv6 properties.
   #
   if (defined $vmknicHash->{ipv6}) {
      $self->ListIPv6();
   }
   return SUCCESS;
}


########################################################################
#
# CheckIPValidity --
#        Checks whether the given address has valid IP format and each octet is
#        within the range. This is just a utility function currently placed in
#        this package.
#
# Input:
#        Address in IP format (xxx.xxx.xxx.xxx)
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


################################################################################
#
# SetDeviceStatus -
#  Enables / disables a vmknic and returns SUCCESS if the status has been changed properly
#
# Input -
#  'UP' or 'DOWN'.
#
# Results -
#  Returns SUCCESS if vmknic is enabled / disabled
#  Returns FAILURE if vmknic is not enabled / disabled
#
# Side effects -
#  None
#
################################################################################

sub SetDeviceStatus
{
   my $self = shift;
   my $action = shift;
   my $command = undef;
   my $switchType = $self->{switchType};
   my $switch = $self->{switch};
   my $dvport = $self->{dvport};

   # Creating the command depending on the action
   if ($action eq "UP") {
      if ($switchType =~ m/vdswitch/i) {
         if (not defined $switch) {
            $vdLogger->Error("switch name is required for vds");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
         $command = "$vmknicBin --enable --dvport-id $dvport ".
                    " --dvs-name $switch";
         if ((defined $self->{netstackName}) && ($self->{netstackName} eq 'vxlan')) {
            $command = "$command --netstack $self->{netstackName}";
         }
      } else {
         $command = "$vmknicBin --enable $self->{pgName}";
      }
   } elsif ($action eq "DOWN") {
      if ($switchType =~ m/vdswitch/i) {
         if (not defined $switch) {
            $vdLogger->Error("switch name is required for vds");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }

         $command = "$vmknicBin --disable --dvport-id $dvport ".
                    "--dvs-name $switch";
         if ((defined $self->{netstackName}) && ($self->{netstackName} eq 'vxlan')) {
            $command = "$command --netstack $self->{netstackName}";
         }
      } else {
         $command = "$vmknicBin --disable $self->{pgName}";
      }
   } else {
      $vdLogger->Error("DeviceStatus action not specified correctly");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                   ($self->{hostName},
                                                    $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("SetDeviceStatus:" . Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   my $status=$self->GetDeviceStatus();
   # Checking whether action has been executed or not
   if ($self->GetVmknicProperties() eq SUCCESS) {
      if ($action eq "UP") {
         if ($status =~ /UP/i) {
            return SUCCESS;
         } else {
            $vdLogger->Error("Vmknic action $action not executed correctly");
            VDSetLastError("EINVALID");
            return FAILURE;
         }
      } else {
         if ($status =~ /DOWN/i) {
            return SUCCESS;
         } else {
            $vdLogger->Error("Vmknic action $action not executed correctly");
            VDSetLastError("EINVALID");
            return FAILURE;
         }
      }
   } else {
      $vdLogger->Error("Vmknic properties not correctly retrieved");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}


################################################################################
#
# SetLROStatus -
#  Enables / disables LRO for a vmknic. Returns SUCCESS if it is successful.
#
# Input -
#  'ENABLE' or 'DISABLE'.
#
# Results -
#  Returns SUCCESS if LRO status is set
#  Returns FAILURE if LRO status is not set
#
# Side effects -
#  None
#
################################################################################
sub SetLROStatus
{
   my $self = shift;
   my $action = shift;
   my $command = undef;

   # Creating the command according to action specified
   if ($action =~ /ENABLE/i) {
      $command = "vsish -e set /net/lro/$self->{deviceId}/cmd set-flags stats".
                 " $action";
   } elsif ($action =~ /DISABLE/i) {
      $command = "vsish -e set /net/lro/$self->{deviceId}/cmd unset-flags ".
                 "stats $action";
   } else {
      $vdLogger->Error("SetLRO action not specified correctly");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                   ($self->{hostName},
                                                    $command);
   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Checking whether action has been executed or not
   if ($self->GetLROStats() eq SUCCESS) {
      if ($action =~ /ENABLE/i) {
         if ($self->{LROStats}->{flags} == $LROEnable) {
            $vdLogger->Info("LRO Status set to \"$action\" successfully");
            return SUCCESS;
         } else {
            $vdLogger->Error("Vmknic action \"$action\" not executed correctly");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      } else {
         if ($self->{LROStats}->{flags} == $LRODisable) {
            $vdLogger->Info("LRO Status set to \"$action\" successfully");
            return SUCCESS;
         } else {
            $vdLogger->Error("Vmknic action \"$action\" not executed correctly");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      }
   } else {
      $vdLogger->Error("LRO Stats not correctly retrieved");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}


################################################################################
#
# GetLROStats -
#  Gets LRO stats for a particular vmknic
#
# Input -
#  None.
#
# Results -
#  Returns SUCCESS - The LRO stats key is updated with all the values of LRO
#
#  Returns FAILURE if any error
#
# Side effects -
#  None
#
################################################################################

sub GetLROStats
{
   my $self = shift;

   # Creating the command
   my $command = "vsish -pe get /net/lro/$self->{deviceId}/status";

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                   ($self->{hostName},
                                                    $command);
   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return undef;
   }

   # Converting string output to a hash for easy parsing
   # The standard behavior is that the output would be an array that starts with
   # the character "{" or "}" as per the sample output given below:
   # {
   #    "<variable>" : <value>,
   #    "<variable>" : <value>,
   #    "<variable>" : <value>,
   #    "<variable>" : <value>,
   #    "<variable>" : <value>,
   #    "<variable>" : <value>,
   #    "<variable>" : <value>,
   $result->{stdout} = VDNetLib::Common::Utilities::ProcessVSISHOutput
                       (RESULT => $result->{stdout});
   if ($result->{stdout} eq FAILURE) {
      VDSetLastError("EOPFAILED");
      $vdLogger->Error("Unable to parse vsish output of LRO stats");
      return FAILURE;
   }

   $self->{LROStats} = $result->{stdout};

   # Checking whether LRO stats are correct (5: activated / 1: deactivated)
   if ($self->{LROStats}->{flags} == $LRODisable ||
       $self->{LROStats}->{flags} == $LROEnable) {
      $vdLogger->Info("LRO Stats retrieved successfully");
      return SUCCESS;
   } else {
       $vdLogger->Debug("LRO status unknown. flags should be ".
		        "(5: activated / 1: deactivated) ".
			Dumper($self->{LROStats}));
   }
   VDSetLastError(VDGetLastError());
   return FAILURE;
}


################################################################################
#
# SetLROMaxLength -
#  Set LRO max length for vmknic
#
# Input -
#  None.
#
# Results -
#  Returns SUCCESS if max length is set
#  Returns undef if value is not set / specified vmknic is not found
#
# Side effects -
#  None
#
################################################################################

sub SetLROMaxLength
{
   my $self = shift;
   my $value = shift;

   if (not defined $value) {
      $vdLogger->Error("Value not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Creating the command
   my $command = "vsish -e set /net/lro/$self->{deviceId}/cmd set-variable".
                 " max_length $value";

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                   ($self->{hostName},
                                                    $command);
   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Checking if max LRO has been set successfully
   if ($self->GetLROMaxLength() == $value) {
      $vdLogger->Info("LRO Max length set successfully to $value");
      return SUCCESS;
   }
   VDSetLastError("ESTAF");
   return FAILURE;
}


################################################################################
#
# GetLROMaxLength -
#  Get LRO max length for vmknic
#
# Input -
#  None.
#
# Results -
#  Returns LRO Max length if retrieved
#  Returns FAILURE if value is not retrieved / specified vmknic is not found
#
# Side effects -
#  None
#
################################################################################

sub GetLROMaxLength
{
   my $self = shift;

   # Retrieving LRO Max Length
   if ($self->GetLROStats() eq SUCCESS) {
      if (defined $self->{LROStats}->{maxLength}) {
         $vdLogger->Info("LRO Max length: $self->{LROStats}->{maxLength}");
         return $self->{LROStats}->{maxLength};
      }
   }
   VDSetLastError("ESTAF");
   return FAILURE;
}


################################################################################
#
# SetMTU -
#  Set MTU for a specified vmknic. Returns SUCCESS if it is successful.
#
# Input -
#  value - Value of the MTU size to be set
#
# Results -
#  Returns SUCCESS if successful
#  Returns FAILURE if MTU is not set / specified vmknic is not found
#
# Side effects -
#  None
#
################################################################################

sub SetMTU
{
   my $self = shift;
   my $value = shift;
   my $type = $self->{switchType};
   my $device = $self->{deviceId};

   if (not defined $value) {
      $vdLogger->Error("Value not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $vmknicPyObj = $self->GetInlinePyObject();
   my $result = CallMethodWithKWArgs($vmknicPyObj, 'update', {'mtu' => int($value)});
   if (defined $result && $result eq FAILURE){
       $vdLogger->Error("Could not set mtu=$value for $device on host: ".
                        "$self->{hostObj}->{hostIP}");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
   $vdLogger->Info("Successfully set mtu=$value for $device on host: ".
                   "$self->{hostObj}->{hostIP}");
   return SUCCESS;
}


################################################################################
#
# GetTcpipStressValue --
#      Method to get specific value for tcpip stress option
#
# Input:
#      stress : Stress option name (Mandatory)
#
# Results:
#      Value if successful
#      FAILURE if there is any error
#
# Side effects:
#      None
#
################################################################################

sub GetTcpipStressValue
{
   my $self = shift;
   my $stress = shift;
   if (not defined $stress) {
      $vdLogger->Error("Stress not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   # We only test the default TCPIP stack instance for now, when we do
   # support multiple stacks, this has to be updated.
   my $stackInstance = VDNetLib::Common::GlobalConfig::DEFAULT_STACK_NAME;

   # Creating the command
   my $command = "vsish -pe get $tcpipVSIPath/$stackInstance/".
                 "vNics/$self->{deviceId}/stress/$stress";

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                   ($self->{hostName},
                                                    $command);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Debug("Host might have TCPIP3 installed, try the old path");
      $command = "vsish -pe get /net/tcpip/vNics/$self->{deviceId}/stress/".
                 "$stress";
      $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                   ($self->{hostName},
                                                    $command);
      if ($result->{rc} != 0) {
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }

   # Parsing the output
   my @tmp = split /\s+/,$result->{stdout};
   $self->{$stress."Value"} = $tmp[3];
   chop($self->{$stress."Value"});
   return $self->{$stress."Value"};
}


################################################################################
#
# SetTcpipStressValue --
#      Method to set specific value for tcpip stress option
#
# Input:
#      stress : Stress option name (Mandatory)
#      value  : Value to be set (Mandatory)
#
# Results:
#      SUCCESS if successful
#      FAILURE if there is any error
#
# Side effects:
#      None
#
################################################################################

sub SetTcpipStressValue
{
   my $self = shift;
   my %args = @_;
   my $args = \%args;
   if (not defined $args->{settcpipstress} ||
       not defined $args->{tcpipstressvalue}) {
      $vdLogger->Error("Stress / value not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $stress = $args->{settcpipstress};
   my $value = $args->{tcpipstressvalue};
   # We only test the default TCPIP stack instance for now, when we do
   # support multiple stacks, this has to be updated.
   my $stackInstance = VDNetLib::Common::GlobalConfig::DEFAULT_STACK_NAME;

   # Tweaking the value to be suited for vsish
   # e.g. vsish -pe set /net/tcpip/instances/defaultTcpipStack/vNics/
   # <vmk>/stress/<stress> \"<value>\"
   my $tmp = "\\\"".$value."\\\"";

   # Creating the command
   my $command = "vsish -pe set $tcpipVSIPath/$stackInstance/".
                 "vNics/$self->{deviceId}/stress/$stress $tmp";

   $vdLogger->Info("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                   ($self->{hostName},
                                                    $command);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Debug("Host might have TCPIP3 installed, try the old path");
      $command = "vsish -pe set /net/tcpip/vNics/$self->{deviceId}/stress/".
                 "$stress $tmp";
      $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                   ($self->{hostName},
                                                    $command);
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to set the stress option");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }

   # Checking if option has been set correctly
   if ($self->GetTcpipStressValue($stress) == $value) {
      $vdLogger->Info("Stress option $stress set to value $value successfully");
      return SUCCESS;
   }
   VDSetLastError(VDGetLastError());
   return FAILURE;
}


################################################################################
#
# AddRoute -
#  Add route for vmknic. Returns SUCCESS if it is successful.
#
# Input -
#  network     - Network address to be added. Default value is "default"
#                (Optional)
#  gateway     - Gateway address to be added (Optional)
#  ipv6Gateway - IPv6 Gateway address to be added (Optional)
#  netmask     - Netmask value to be added. Default is 0 (Optional)
#
# Results -
#  Returns SUCCESS if successful
#  Returns FAILURE if there is any error
#
# Side effects -
#  None
#
################################################################################

sub AddRoute
{
   my $self = shift;
   my %args = @_;
   my $gateway = $args{gateway} || undef;
   my $ipv6gateway = $args{ipv6gateway} || undef;

   if (not defined $gateway &&
       not defined $ipv6gateway) {
      $vdLogger->Error("Gateway and IPv6Gateway values are not passed. One of".
                       " them should be mentioned");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $netmask = $args{netmask} || '0.0.0.0';
   my $network = $args{network} || 'default';

   # Creating the command
   my $command = "$routeBin";

   # If the gateway is IPv6, should be specified explicitily in the command.
   # Adding this information to the command.Default is V4.
   if (defined $ipv6gateway) {
      $command .= " -f V6";
   }

   if ($network =~ m/default/) {
      $command .= " -a $network";
   } elsif (defined $ipv6gateway) {
      $command .= " -a $network\:\:\/$netmask";
   } else {
      $command .= " -a $network $netmask";
   }

   # Adding the gateway information to the command
   if (defined $gateway) {
      $command .= " $gateway";
   } elsif (defined $ipv6gateway) {
      $command .= " $ipv6gateway";
   }

   # Add netstack information
   $command .= " -N $self->{netstackName}";

   $vdLogger->Info("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                   ($self->{hostName},
                                                    $command);
   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Verifying if route has been set
   if (defined $gateway) {
      $command = "$routeBin -l | grep $gateway";
      $vdLogger->Debug("Checking if gateway $gateway has been set");

      # Submit STAF command
      $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                      ($self->{hostName},
                                                       $command);
      if ($result->{rc} != 0) {
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      # Creating the success string pattern to be matched
      # Pattern will be:
      # Network              Netmask           Gateway
      my $successPattern = $network."\\s+".$netmask."\\s+".$gateway;
      if ($result->{stdout} =~ m/$successPattern/i) {
         $vdLogger->Info("VMK Route set");
         return SUCCESS;
      }
   } elsif (defined $ipv6gateway) {
      $command = "$routeBin -f V6 -l | grep $ipv6gateway";
      $vdLogger->Debug("Checking if gateway $ipv6gateway has been set");
      # Submit STAF command
      $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                      ($self->{hostName},
                                                       $command);
      if ($result->{rc} != 0) {
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      # Creating the success string pattern to be matched
      # Pattern will be:
      # Network              Netmask           Gateway
      my $successPattern = undef;
      if ($network =~ m/default/){
         $netmask = '0';
         $successPattern = $network."\\s+".$netmask."\\s+".$ipv6gateway;
      } else {
         $successPattern = $network."\:\:\\s+".$netmask."\\s+".$ipv6gateway;
      }
      if ($result->{stdout} =~ m/$successPattern/i) {
         $vdLogger->Info("VMK Route set");
         return SUCCESS;
      }
   }
   VDSetLastError(VDGetLastError());
   return FAILURE;
}


################################################################################
#
# DeleteRoute -
#  Delete route for vmknic. Returns SUCCESS if it is successful.
#
# Input -
#  network     - Network address to be added. Default value is "default"
#                (Optional)
#  gateway     - Gateway address to be added (Optional)
#  ipv6Gateway - IPv6 Gateway address to be added (Optional)
#  netmask     - Netmask value to be added. Default is 0 (Optional)
#
# Results -
#  Returns SUCCESS if successful
#  Returns FAILURE if there is any error
#
# Side effects -
#  None
#
################################################################################

sub DeleteRoute
{
   my $self = shift;
   my %args = @_;
   my $gateway = $args{gateway} || undef;
   my $ipv6gateway = $args{ipv6gateway} || undef;

   if (not defined $gateway &&
       not defined $ipv6gateway) {
      $vdLogger->Error("Gateway and IPv6Gateway values are not passed. One of".
                       " them should be mentioned");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $netmask = $args{netmask} || '0.0.0.0';
   my $network = $args{network} || 'default';

   # Creating the command
   my $command = "$routeBin";

   # If the gateway is IPv6, should be specified explicitily in the command.
   # Adding this information to the command.Default is V4.
   if (defined $ipv6gateway) {
      $command .= " -f V6";
   }

   if ($network =~ m/default/) {
      $command .= " -d $network";
   } elsif (defined $ipv6gateway) {
      $command .= " -d $network\:\:\/$netmask";
   } else {
      $command .= " -d $network $netmask";
   }

   # Adding the gateway information to the command
   if (defined $gateway) {
      $command .= " $gateway";
   } elsif (defined $ipv6gateway) {
      $command .= " $ipv6gateway";
   }

   $vdLogger->Info("Running command: $command");

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                   ($self->{hostName},
                                                    $command);
   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Verifying if route has been deleted
   if (defined $gateway) {
      $command = "$routeBin -l | grep $gateway";
      $vdLogger->Info("Verifying if gateway $gateway has been deleted");

      # Submit STAF command
      $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                      ($self->{hostName},
                                                       $command);
      if ($result->{rc} != 0) {
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      # Creating the success string pattern to be matched
      # Pattern will be:
      # Network              Netmask           Gateway
      my $successPattern = $network."\\s+".$netmask."\\s+".$gateway;
      if ($result->{stdout} =~ m/$successPattern/i) {
         $vdLogger->Error("Failed to delete VMK Route" . Dumper($result));
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   } elsif (defined $ipv6gateway) {
      $command = "$routeBin -f V6 -l | grep $ipv6gateway";
      $vdLogger->Info("Verifying if gateway $ipv6gateway has been deleted");
      # Submit STAF command
      $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess
                                                      ($self->{hostName},
                                                       $command);
      if ($result->{rc} != 0) {
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      # Creating the success string pattern to be matched
      # Pattern will be:
      # Network              Netmask           Gateway
      my $successPattern = undef;
      if ($network =~ m/default/){
         $netmask = '0';
         $successPattern = $network . "\\s+" . $netmask . "\\s+" . $ipv6gateway;
      } else {
         $successPattern = $network."\:\:\\s+".$netmask."\\s+".$ipv6gateway;
      }
      if ($result->{stdout} =~ m/$successPattern/i) {
         $vdLogger->Error("Failed to delete VMK Route" . Dumper($result));
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }

   return SUCCESS;
}


################################################################################
#
# SetVMotion --
#      Method to enable / disable VMotion
#
# Input:
#      value  : Enable / Disable (Mandatory)
#
# Results:
#      SUCCESS if successful
#      FAILURE if there is any error
#
# Side effects:
#      None
#
################################################################################

sub SetVMotion
{
   my $self = shift;
   my $value = shift;
   if (not defined $value) {
      $vdLogger->Error("Value for VMotion action not been passed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $vmknicPyObj = $self->GetInlinePyObject();
   my $result = CallMethodWithKWArgs($vmknicPyObj, 'enable_vmotion',
                    {'enable'=>ConvertToPythonBool(undef, $value)});
   if(defined $result && $result eq FAILURE){
       $vdLogger->Error("Could not set vmotion on $self->{deviceId} to $value");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
   $vdLogger->Info("VMotion has been set to \"$value\" successfully");
   return SUCCESS;
}


################################################################################
#
# GetMTU --
#      Method to return MTU size of the vmknic.
#
# Input:
#      None
#
# Results:
#      MTU Size (scalar string), if successful;
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
################################################################################

sub GetMTU
{
   my $self = shift;
   if ($self->GetVmknicProperties() eq FAILURE) {
      $vdLogger->Error("Failed to get vmknic properties");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $self->{MTU};
}


################################################################################
#
# GetIPv4 --
#      Method to return IPv4 address currently configured on the vmknic.
#
# Input:
#      None
#
# Results:
#      IPv4 address (scalar string), if successful;
#      "FAILURE", in case of any error
#
#
# Side effects:
#      None
#
################################################################################

sub GetIPv4
{
   my $self = shift;
   if ($self->GetVmknicProperties() eq FAILURE) {
      $vdLogger->Error("Failed to get vmknic properties");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (defined ($self->{IP})) {
      return $self->{IP};
   } else {
      $vdLogger->Error("No IPv4 address configured on $self->{deviceId}");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

}


################################################################################
#
# SetIPv4 --
#      Method to change the IPv4 address configured on the vmknic.
#
# Input:
#      ipaddr: ip address to be configured (Required)
#      netmask: subnet mask to be configured (Required)
#
# Results:
#      "SUCCESS", if ipv4 address is configured successfully;
#      "FAILURE", in case of any error
#
#
# Side effects:
#      None
#
################################################################################

sub SetIPv4
{
   my $self = shift;
   my $ipaddr = shift;
   my $netmask = shift;
   my $host = $self->{hostName};
   my $interface = $self->{deviceId};
   my $command;
   my $result;

   if (not defined $ipaddr) {
      $vdLogger->Error("IP Address not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($ipaddr !~ m/none|dhcp/i) {
       if (not defined $netmask) {
	 $vdLogger->Error("Netmask not defined");
	 VDSetLastError("ENOTDEF");
	 return FAILURE;
       }
   }

   $command = "$vmknicEsxcli interface ipv4 set -i $interface ";
   if ($ipaddr =~ m/none|dhcp/i) {
      $command = "$command -t none; $command -t $ipaddr";
   } else {
      $command = "$command -t static -I $ipaddr -N $netmask ";
   }

   # Run command to set the ipaddress
   $vdLogger->Debug("Command is : $command\n");
   $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess($host,
                                                                $command);

   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to set ip $ipaddr for $interface");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $self->{hostObj}->HostNetRefresh();
   # Checking whether IP has been set successfully
   if ($ipaddr !~ /none|dhcp/i) {
      my $retry = 5;	# Retry count 5.
      while ($retry >= 0) {
         sleep 1;
         if ($self->GetIPv4() ne $ipaddr) {
	    next if ($retry-- > 0);

	    $vdLogger->Error("Failed to get expected ip address for $interface");
	    VDSetLastError("EFAIL");
	    return FAILURE;
         }
	 last;
      }
   }

   return SUCCESS;
}


################################################################################
#
# ListIPv6 --
#      Method to list IPv6 addresses and retrieve the IPv6 of the vmknic
#
# Input:
#      None.
#
# Results:
#      "SUCCESS" if successful
#      "FAILURE", in case of any error
#
#
# Side effects:
#      None
#
################################################################################

sub ListIPv6
{
   my $self = shift;

   # Creating command
   my $command = "$vmknicEsxcli interface ipv6 address list | grep ".
                 "$self->{deviceId}";

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess(
                                                $self->{hostName},
                                                $command);

   if ($result->{rc} != 0) {
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Parsing the output to store all the IPv6 addresses
   my $lc = 0;
   my @tmp = split(/\n/,$result->{stdout});
   foreach my $ai (@tmp) {
      my @line = split /\s+/,$ai;
      $self->{ipv6}->{$lc}->{ipv6Addr} = $line[1];
      $self->{ipv6}->{$lc}->{prefixLen} = $line[2];
      $self->{ipv6}->{$lc}->{ipv6Type} = $line[3];
      $self->{ipv6}->{$lc}->{ipv6Status} = $line[4];
      $lc++;
   }
   return SUCCESS;
}


################################################################################
#
# SetIPv6 --
#      Method to set the IPv6 address on an already created vmknic.
#
# Input:
#      operation: add or delete (Required)
#      ipaddr: ip address to be configured (Required)
#              Values are: "DHCPV6"
#                          "ROUTER"
#                          "PEERDNS"
#                          "<IPAddr>::<IPAddr>" (default mask 64 not to be mentioned)
#                             e.g. "2001::1234:11"
#                          "STATIC"
#
# Results:
#      "SUCCESS", if ipv6 address is configured successfully;
#      "FAILURE", in case of any error
#
#
# Side effects:
#      None
#
################################################################################

sub SetIPv6
{
   my $self = shift;
   my $operation = shift;
   my $ipaddr = shift;
   my $result = undef;
   my $command = undef;

   if (not defined $self->{deviceId} ||
       not defined $operation) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Checking if host supports IPv6
   my $checkSupport = $self->{hostObj}->CheckIPv6Host();
   if ($checkSupport eq FAILURE) {
      $vdLogger->Error("Host doesn't support IPv6");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Creating command
   if ($operation =~ m/delete/i) {
      $result = $self->ListIPv6();
      if ($result eq FAILURE) {
         $vdLogger->Error("Unable to retrieve list of IPv6 addresses");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      # Each vmknic may have more than one IPv6 address
      foreach my $keys (keys(%{$self->{ipv6}})) {
         $command = "$vmknicEsxcli interface ipv6 address remove  -i ".
                    "$self->{deviceId} -I ".
                    "$self->{ipv6}{$keys}{ipv6Addr}\/".
                    "$self->{ipv6}{$keys}{prefixLen}";
         $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess(
                                                   $self->{hostName},
                                                   $command);
         if ($result->{rc} != 0) {
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }
      return SUCCESS;
   } elsif ($operation =~ m/add/i) {
      if ($ipaddr =~ m/dhcpv6/i) {
         $command = "$vmknicEsxcli interface ipv6 set -i ".
                    "$self->{deviceId} -d true";
      } elsif ($ipaddr =~ m/router/i) {
         $command = "$vmknicEsxcli interface ipv6 set -i ".
                    "$self->{deviceId} -r true";
      } elsif ($ipaddr =~ m/peerdns/i) {
         $command = "$vmknicEsxcli interface ipv6 set -i ".
                    "$self->{deviceId} -P 1";
      } elsif ($ipaddr =~ m/static/i) {
         $ipaddr = VDNetLib::Common::Utilities::GetAvailableTestIPv6(
                                                $self->{controlIP});
         if ($ipaddr =~ /(.*)\::(.*)/) {
            $command = "$vmknicEsxcli interface ipv6 address add -i ".
                       "$self->{deviceId} -I $ipaddr\/64";
         } else {
            $vdLogger->Error("Unable to generate IPv6 address");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      } elsif ($ipaddr =~ /(.*)\::(.*)/) {
         # Checking if IP address already exists in the same network
         $command = "ping6 -c 1 $ipaddr";
         $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess(
                                                $self->{hostName},
                                                $command);
         if ($result->{rc} != 0) {
            VDSetLastError("EFAIL");
            $vdLogger->Debug("STAF error:" .Dumper($result));
            return FAILURE;
         }
         if ($result->{exitCode} != 0 || $result->{stdout} =~ /unreachable/i) {
            $command = "$vmknicEsxcli interface ipv6 address add -i ".
                       "$self->{deviceId} -I $ipaddr\/64";
         } else {
            $vdLogger->Error("IP address $ipaddr already exists. Please ".
                             "enter another one");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      } else {
         $vdLogger->Error("Incorrect value for IPV6ADDR. Should be:\n".
                          "\"DHCPV6\" or\n".
                          "\"ROUTER\" or\n".
                          "\"PEERDNS\" or\n".
                          "\"2001::1234:1 <default mask 64>\" or\n".
                          "\"STATIC\"");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Incorrect value for action. Should be:\n".
                       "\"ADD\" or".
                       "\"DELETE\"");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess(
                                             $self->{hostName},
                                             $command);

   if ($result->{rc} != 0) {
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   # Checking if IP address has been set correctly
   if ($ipaddr =~ /(.*)\::(.*)/) {
      $result = $self->ListIPv6();
      if ($result eq FAILURE) {
         $vdLogger->Error("Unable to retrieve list of IPv6 addresses");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      foreach my $keys (keys(%{$self->{ipv6}})) {
         if ($self->{ipv6}{$keys}{ipv6Addr} =~ m/$ipaddr/i) {
            $vdLogger->Debug("Successfully set IPv6 address $ipaddr");
            return SUCCESS;
         }
      }
   } elsif ($ipaddr =~ m/router/i ||
            $ipaddr =~ m/peerdns/i ||
            $ipaddr =~ m/dhcpv6/i) {
      return SUCCESS;
   }
   $vdLogger->Error("Unable to set IPv6 parameter - $ipaddr");
   VDSetLastError("EFAIL");
   return FAILURE;
}


################################################################################
#
# GetVLANId --
#      Method to retrieve the VLAN Id of the portgroup to which vmknic is
#      connected
#
# Input:
#      None.
#
# Results:
#      VLAN id of the interface, if successful
#      "FAILURE", in case of any error
#
#
# Side effects:
#      None
#
################################################################################

sub GetVLANId
{
   my $self = shift;
   my $pgName = $self->{interface};
   if (not defined $pgName) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Creating command
   my $command = "esxcfg-vswitch -l | grep \"$pgName\"";

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess(
                                                $self->{hostName},
                                                $command);

   if ($result->{rc} != 0) {
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Converting output into an array
   my @tmp = split('\s+',$result->{stdout});
   #
   # VLAN ID is stored as the third element of the array
   # Output of the command looks like:
   # esxcfg-vswitch -l | grep vmk1-pg-2691
   #   vmk1-pg-2691          0        1           vmnic1
   #
   if (defined $tmp[2]) {
      if ($tmp[2] =~ /\d+/) {
         return $tmp[2];
      }
   }
   VDSetLastError("EOPFAILED");
   $vdLogger->Error("Unable to retrieve VLAN Id of PG $pgName");
   return FAILURE;
}


########################################################################
#
# GetIPv6Global --
#     Gives the IPv6 global address for the given interface
#
# Input:
#     A valid NetAdapter object
#
# Results:
#     Array of IPv6 global address, on success
#     'FAILURE', in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetIPv6Global
{
   my $self = shift;    # Required
   my $args = $self->{'interface'};
   my @globalIp = (); # Array to store IP addresses

   # Listing out all the IPv6 addresses for interface
   my $result = $self->ListIPv6();
   if ($result eq FAILURE) {
      $vdLogger->Error("Unable to retrieve list of IPv6 addresses");
      $vdLogger->Warn("Check if ipv6 is enabled on the host ".
                      "Using:vim-cmd /hostsvc/net/info | grep -i ipv6Enabled*");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Storing only the global IPv6 addresses in an array
   my $lc = 0;
   foreach my $keys (keys(%{$self->{ipv6}})) {
      my @tmp = split('::',$self->{ipv6}{$keys}{ipv6Addr});
      if ($tmp[0] !~ m/fe80/i) {
         $globalIp[$lc] = $self->{ipv6}{$keys}{ipv6Addr};
         $lc++;
      }
   }
   if ((scalar @globalIp) > 0) {
      return \@globalIp;
   } else {
      $globalIp[0] = "NULL";
      return \@globalIp;
   }

}


########################################################################
#
# SetVLAN -
#       Method to set VLAN Id on the portgroup of a vmknic
#
# Input:
#       VLAN ID - 1 to 4095 (required)
#
# Results:
#       A new NetAdapter object, if success
#       "FAILURE", in case of any error
#
# Side effects:
#       None.
#
########################################################################

sub SetVLAN
{
   my $self = shift;
   my $vlanId = shift;

   # Check if the vlan id is within range 0-4095
   if ($vlanId =~ /^(\d\d?\d?\d?)$/) {
      if (($1 < 0) || ($1 > 4095)) {
         $vdLogger->Error("VLAN Id out of range");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   } else {
         $vdLogger->Error("Invalid VLAN Id");
         VDSetLastError("EINVALID");
         return FAILURE;
   }

   my $pgName = $self->{interface};

   # Creatng the command
   my $command = "/sbin/esxcli network vswitch standard portgroup set".
                 " -v $vlanId -p $pgName";

   # Submit STAF command
   my $result = $self->{hostObj}->{stafHelper}->STAFSyncProcess(
                                                $self->{hostName},
                                                $command);

   if ($result->{rc} != 0) {
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Checking if VLAN ID has been set correctly
   my $checkVlan = $self->GetVLANId();
   if ($checkVlan == $vlanId) {
      my $newSelf = {
         controlIP => $self->{controlIP},
         interface => $self->{interface},
         macAddress => $self->{macAddress},
         intType => "vmknic",
      };
      bless $newSelf;
      return $newSelf;
   }
   $vdLogger->Error("Unable to set VLAN Id to PG $pgName");
   VDSetLastError("EFAIL");
   return FAILURE;
}


########################################################################
#
# RemoveVLAN -
#       Removes (i.e. sets to "0") the VLAN Id configured on the portgroup
#       connected to the vmknic
#
# Input:
#       None
#
# Results:
#       "SUCCESS", if remove operations is success
#       "FAILURE", in case of any error
#
# Side effects:
#       None.
#
########################################################################

sub RemoveVLAN
{
   my $self = shift;
   my $pgName = $self->{'interface'};

   # Setting VLAN Id to 0
   my $result = $self->SetVLAN("0");
   if ($result eq FAILURE) {
      $vdLogger->Error("Unable to remove VLAN Id from PG $pgName");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetDeviceStatus -
#        Gives the status (UP or DOWN) of the vmknic
#
# Input:
#       None
#
# Results:
#       "UP", if the vmknic is enabled
#       "DOWN", if the vmknic is disabled
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub GetDeviceStatus
{
   my $self = shift;
   my $status = undef;

   my $result = $self->{hostObj}->GetVmknicList();
   foreach my $item (@$result) {
      if($item->{'Name'} eq $self->{deviceId}) {
         $self->{enabled} = $item->{'Enabled'};
      }#end of if
    }#end of foreach

   # Checking device status
   if ($self->GetVmknicProperties() eq SUCCESS) {
      if ($self->{enabled} =~ /true/i) {
         $status = "UP";
         return $status;
      } elsif ($self->{enabled} =~ /false/i) {
         $status = "DOWN";
         return $status;
      }
   }
   $vdLogger->Error("Vmknic properties not correctly retrieved");
   VDSetLastError("EFAIL");
   return FAILURE;
}


########################################################################
#
# SetOffload -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::SetOffload
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub SetOffload
{
   return SUCCESS;
}


########################################################################
#
# GetMACAddress -
#       Returns the mac address (hardware address) of the given
#       vmknic
#
# Input:
#       None
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
   my $self = shift;    # Required
   if ($self->GetVmknicProperties() eq FAILURE) {
      $vdLogger->Error("Failed to get vmknic properties");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $self->{macAddress};
}


########################################################################
#
# GetInterfaceName -
#        Gives the interface name of the vmknic e.g. vmk0, vmk1, etc.
#
# Input:
#        None
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
   my $self = shift;    # Required

   if ($self->GetVmknicProperties() eq FAILURE) {
      $vdLogger->Error("Failed to get vmknic properties");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $self->{deviceId};
}


########################################################################
#
# GetLinkState --
#     Gives the current link state of the vmknic. Since vmknic doesn't have
#     something called a "link state", this will return the status of the
#     adapter
#
# Input:
#     A valid NetAdapter object
#
# Results:
#     'Connected', if the vmknic is "UP"
#     'Disconnected', if the vmknic is "DOWN"
#     'FAILURE', in case of any errror
#
# Side effects:
#     None
#
########################################################################

sub GetLinkState
{
   my $self = shift;    # Required
   my $state = undef;

   my $result = $self->GetDeviceStatus();
   if ($result =~ /UP/i) {
      $state = "Connected";
      return $state;
   } elsif ($result =~ /DOWN/i) {
      $state = "Disconnected";
      return $state;
   } else {
      $vdLogger->Error("Failed to get vmknic device status");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
}


########################################################################
#
# GetIPv6Local --
#     Gives the IPv6 link-local address for the given interface
#
# Input:
#     A valid NetAdapter object
#
# Results:
#     Array of IPv6 link-local address, on success
#     'FAILURE', in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetIPv6Local
{
   my $self = shift;    # Required
   my @localIp = (); # Array to store IP addresses

   # Listing out all the IPv6 addresses for interface
   my $result = $self->ListIPv6();
   if ($result eq FAILURE) {
      $vdLogger->Error("Unable to retrieve list of IPv6 addresses");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Storing only the local IPv6 addresses in an array
   my $lc = 0;
   foreach my $keys (keys(%{$self->{ipv6}})) {
      my @tmp = split('::',$self->{ipv6}{$keys}{ipv6Addr});
      if ($tmp[0] =~ m/fe80/i) {
         $localIp[$lc] = $self->{ipv6}{$keys}{ipv6Addr};
         $lc++;
      }
   }
   if ((scalar @localIp) > 0) {
      return \@localIp;
   }
   $vdLogger->Error("Unable to retrieve list of local IPv6 addresses for".
                    " interface $self->{'interface'}");
   VDSetLastError("EFAIL");
   return FAILURE;
}


########################################################################
#
# SetWoL -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::SetWoL
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub SetWoL
{
   return SUCCESS;
}


########################################################################
#
# SetInterruptModeration -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::SetInterruptModeration
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub SetInterruptModeration
{
   return SUCCESS;
}


########################################################################
#
# SetOffloadTCPOptions -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::SetOffloadTCPOptions
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub SetOffloadTCPOptions
{
   return SUCCESS;
}


########################################################################
#
# SetOffloadIPOptions -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::SetOffloadIPOptions
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub SetOffloadIPOptions
{
   return SUCCESS;
}


########################################################################
#
# SetRSS -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::SetRSS
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub SetRSS
{
   return SUCCESS;
}


########################################################################
#
# SetMaxTxRxQueues -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::SetMaxTxRxQueues
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub SetMaxTxRxQueues
{
   return SUCCESS;
}


########################################################################
#
# SetRxBuffers -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::SetRxBuffers
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub SetRxBuffers
{
   return SUCCESS;
}


########################################################################
#
# SetRingSize -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::SetRingSize
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub SetRingSize
{
   return SUCCESS;
}


########################################################################
#
# DriverLoad -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::DriverLoad
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub DriverLoad
{
   return SUCCESS;
}


########################################################################
#
# DriverUnload -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::DriverUnload
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub DriverUnload
{
   return SUCCESS;
}


########################################################################
#
# DriverReload -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::DriverReload
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub DriverReload
{
   return SUCCESS;
}


########################################################################
#
# SetMACAddr -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::SetMACAddr
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub SetMACAddr
{
   return SUCCESS;
}


########################################################################
#
# GetNetworkAddr -
#       This method returns the Other address configured for the
#       adapter/interface like Subnet Mask, Broadcast address along with
#       IPv4 address
#
# Input:
#       None
#
# Results:
#       Hash of IPv4 address, Subnet Mask and Bcast address if success
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub GetNetworkAddr
{
   my $self = shift;
   my $addressHash;

   if ($self->GetVmknicProperties() eq FAILURE) {
      $vdLogger->Error("Failed to get vmknic properties");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $addressHash->{ipv4} = $self->{IP};
   $addressHash->{netmask} = $self->{netmask};
   $addressHash->{broadcast} = $self->{broadcast};
   return $addressHash;
}


########################################################################
#
# GetDriverName -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::GetDriverName
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub GetDriverName
{
   return SUCCESS;
}


########################################################################
#
# GetNDISVersion -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::GetNDISVersion
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub GetNDISVersion
{
   return SUCCESS;
}


########################################################################
#
# GetOffload -
#        The method will take in paramters pertaining to TSO and will
#        return "Enabled" / "Disabled" depending on that. If parameter
#        is anything else, method will return "Disabled".
#
# Input:
#        OffLoadfunction: Parameter for which value is to be retrieved.
#                         [Mandatory]
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
   my $self = shift;
   my $offloadFunction = shift;  # Required
   if (not defined $offloadFunction) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $status = "Disabled";

   # Checking what value to retrieve
   if ($offloadFunction =~ /TSO/i) {
      if ($self->GetVmknicProperties() eq FAILURE) {
         $vdLogger->Error("Failed to get vmknic properties");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      if ($self->{TSO} =~ /\d+/) {
         $status = "Enabled";
         return $status;
      } else {
         return $status;
      }
   } else {
      # Returning "Disabled" for any value other than "TSO"
      return $status;
   }
}


########################################################################
#
# GetWoL -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::GetWoL
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub GetWoL
{
   return SUCCESS;
}


########################################################################
#
# GetInterruptModeration -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::GetInterruptModeration
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub GetInterruptModeration
{
   return SUCCESS;
}


########################################################################
#
# GetOffloadTCPOptions -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::GetOffloadTCPOptions
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub GetOffloadTCPOptions
{
   return SUCCESS;
}


########################################################################
#
# GetOffloadIPOptions -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::GetOffloadIPOptions
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub GetOffloadIPOptions
{
   return SUCCESS;
}


########################################################################
#
# GetRSS -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::GetRSS
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub GetRSS
{
   return SUCCESS;
}


########################################################################
#
# GetMaxTxRxQueues -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::GetMaxTxRxQueues
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub GetMaxTxRxQueues
{
   return SUCCESS;
}


########################################################################
#
# GetRxBuffers -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::GetRxBuffers
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub GetRxBuffers
{
   return SUCCESS;
}


########################################################################
#
# GetRingSize -
#        This is a dummy method. For details on the method, please refer to
#        VDNetLib::NetAdapter::Vnic::Vnic::GetRingSize
#
# Input:
#        None.
#
# Results:
#        'SUCCESS'
#
# Side effects:
#        None
#
########################################################################

sub GetRingSize
{
   return SUCCESS;
}


########################################################################
#
# GetNetworkConfig--
#      Get the networking config on the esx host, vswitch, vds and vmknic
#      output.
#
# Input:
#      logDir : Name of the directory on master controller where
#               logs are to be copied.
#
#
# Results:
#     SUCCESS if vsi file is created and gets copied to master controller
#     FAILURE if there are errors during VSI cache file generation or while
#             copying it.
#
# Side effects:
#      None
#
########################################################################

sub GetNetworkConfig
{
   my $self = shift;
   my $logDir = shift;
   my $file;
   if(-d $logDir) {
      $file = $logDir."/"."Network_Config";
   } else {
      $file = $logDir;
   }

   if (not defined $logDir) {
      $vdLogger->Error("logging directory not specifed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $self->{controlIP}) {
      $vdLogger->Error("Control IP address of the vm not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $hostIP = $self->{controlIP};
   my ($vswitch, $vmknic, $vmnic);
   my $command;
   my $result;
   my $ret = SUCCESS;

   # list the vswitch.
   $command = "$vswitchEsxcli list";
   $result = $self->{hostObj}{stafHelper}->STAFSyncProcess($hostIP, $command);
   if (($result->{rc} !=0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to list vswitch on host $hostIP");
      VDSetLastError("ESTAF");
      $ret = FAILURE;
   }
   $vswitch = $result->{stdout};

   # list the vmknic
   $command = "$vmknicBin -l";
   $result = $self->{hostObj}{stafHelper}->STAFSyncProcess($hostIP, $command);
   if (($result->{rc} !=0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to list vmknic on host $hostIP");
      VDSetLastError("ESTAF");
      $ret = FAILURE;
   }
   $vmknic = $result->{stdout};


   # list pnics.
   $command = "$vmnicEsxcli list";
   $result = $self->{hostObj}{stafHelper}->STAFSyncProcess($hostIP, $command);
   if (($result->{rc} !=0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to list pnic on host $hostIP");
      VDSetLastError("ESTAF");
      $ret = FAILURE;
   }
   $vmnic = $result->{stdout};

   open FILE, ">" ,$file;
   print FILE "Virtual Switch Configuration\n\n";
   print FILE "$vswitch\n\n\n";
   print FILE "VMkernel NIC Configuration\n\n";
   print FILE "$vmknic\n\n\n";
   print FILE "Physical NIC Configuration\n\n";
   print FILE "$vmnic\n\n\n";
   close (FILE);

   return $ret;
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
   my $self = shift;
   my $logDir = shift;
   my $file;
   if(-d $logDir) {
      $file = $logDir."/"."Network_Config";
   } else {
      $file = $logDir;
   }

   if (not defined $logDir) {
      $vdLogger->Error("logging directory not specifed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $self->{controlIP}) {
      $vdLogger->Error("Control IP address of the vm not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $hostIP = $self->{controlIP};
   my ($route);
   my $command;
   my $result;
   my $ret = SUCCESS;

   # list the vswitch.
   $command = "$routeBin -l";
   $result = $self->{hostObj}{stafHelper}->STAFSyncProcess($hostIP, $command);
   if (($result->{rc} !=0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to list vswitch on host $hostIP");
      VDSetLastError("ESTAF");
      $ret = FAILURE;
   }
   $route = $result->{stdout};

   open FILE, ">" ,$file;
   print FILE "Route Table\n\n";
   print FILE "$route\n\n\n";
   close (FILE);

   return $ret;
}

########################################################################
#
# SetRouterAdvertisement--
#     Method to configure router advertisement on the given adapter
#
# Input:
#     protocol : "ipv4" or "ipv6" (Optional, default is "ipv4")
#     action   : "true" or "false" (Optional, default is false)
#
# Results:
#     SUCCESS, if router advertisement is configured successfully;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetRouterAdvertisement
{
   my $self = shift;
   my $action = shift || "false";
   my $protocol = shift || "ipv4";

   my $command = "esxcli network ip interface $protocol ".
                 "set -r $action -i $self->{deviceId}";

   $vdLogger->Debug("Executing SetRouterAdvertisement command: $command");
   my $result = $self->{hostObj}{stafHelper}->STAFSyncProcess($self->{controlIP},
                                                              $command);
   if (($result->{rc} !=0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to configure router advertisement of " .
                       " $self->{deviceId} on $self->{controlIP}");
      $vdLogger->Debug("Error: " . Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($self->GetRouterAdvertisement($protocol) !~ /$action/) {
      $vdLogger->Error("Mismatch in router advertisement configuration");
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }
}


########################################################################
#
# GetRouterAdvertisement--
#     Method to current configuration of router advertisement on the
#     given adapter
#
# Input:
#     protocol : "ipv4" or "ipv6" (Optional, default is "ipv4")
#
# Results:
#     Boolean ("true" or "false"), if successful;
#     FAILURE, in case of any errors
#
# Side effects:
#     None
#
########################################################################

sub GetRouterAdvertisement
{
   my $self = shift;
   my $protocol = shift || "ipv4";
   my $command = "esxcli network ip interface $protocol get -n " .
                 "$self->{deviceId} | grep -i $self->{deviceId}";

   $vdLogger->Debug("Executing GetRouterAdvertisement command: $command");
   my $result = $self->{hostObj}{stafHelper}->STAFSyncProcess($self->{controlIP},
                                                              $command);
   if (($result->{rc} !=0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to get router advertisement of " .
                       " $self->{deviceId} on $self->{controlIP}");
      $vdLogger->Debug("Error: " . Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $data = $result->{stdout};
   chomp($data);
   my @result_array = split(/\s+/, $data);
   my $len = scalar @result_array;

   if ($len eq 4) {
      my ($interface, $dhcp, $router, $dns) = @result_array;
      return $router;
   } elsif ($len eq 5) {
      my ($interface, $ip, $dhcp, $router, $dns) = @result_array;
      return $router;
   } else {
      $vdLogger->Error("Invalid router advertisement result: $data");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
}


########################################################################
#
# Reconfigure --
#     Method to edit the vmknic configuration on host
#
# Input:
#     Reference to hash containing following keys:
#     $vmknicSpec  : ref to hash containing details that need to
#                    be applied on the vmknic
#
# Results:
#     SUCCESS, if the adapter is reconfigured correctly;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub Reconfigure
{
   my $self       = shift;
   my $vmknicSpec = shift;
   my $inlineVirtualAdapter = $self->GetInlineVirtualAdapter();

   my $inlineVmknicSpec;
   my $inlinePortgroup;

   # TODO: Need to take care
   # of other attributes that
   # can be part of vmknic spec
   if (defined $vmknicSpec->{portgroup}) {
      $inlinePortgroup = $vmknicSpec->{portgroup}->GetInlinePortgroupObject();
      $inlineVmknicSpec->{portgroup} = $inlinePortgroup;
   }
   if (defined $vmknicSpec->{ip}) {
      $inlineVmknicSpec->{ip} = $vmknicSpec->{ip};
   }
   if (defined $vmknicSpec->{netmask}) {
      $inlineVmknicSpec->{netmask} = $vmknicSpec->{netmask};
   }

   my $result = $inlineVirtualAdapter->Reconfigure($inlineVmknicSpec);
   if ($result eq 0) {
      $vdLogger->Error("Unable to reconfigure vmknic $self->{deviceId}");
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# SetTagging--
#     Method to add/remove the tagging for given interface.
#
# Input:
#     tagging : parameter to specify the add/remove of the tag
#     tagName : Name of the tag to be added or removed.
#
# Results:
#     SUCCESS, if adding/removing tags is successful
#     FAILURE, in case of any errors
#
# Side effects:
#     None
#
########################################################################

sub SetTagging
{
   my $self = shift;
   my $tagging = shift || "add",
   my $tagName = shift;
   my $interface = $self->{deviceId};
   my $stafHelper = $self->{hostObj}->{stafHelper};
   my $host = $self->{hostObj}->{hostIP};
   my $result;
   my $command;
   my $validOperations = "add|remove";

   if (not defined $tagName) {
      $vdLogger->Error("Name of the tag to added/removed to/from ".
                       "$interface is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($tagging !~ m/$validOperations/i) {
      $vdLogger->Error("Invalid operations - $tagging, valid ones ".
                       "are - add/remove");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # command to add/remove tag.
   if ($tagging =~ m/add/i) {
      $command = "$vmknicEsxcli interface tag add -t $tagName -i $interface";
   } else {
      $command = "$vmknicEsxcli interface tag remove -t $tagName -i $interface";
   }
   $result = $stafHelper->STAFSyncProcess($host,$command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to $tagging tag $tagName for $interface ".
                       "failed");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Info("Successfully set tagging for $interface");
   return SUCCESS;
}


########################################################################
#
# BindDVFilter--
#     Method to set/reset dvfilter internal communication endpoint.
#
# Input:
#     dvfilter : parameter to specify if we need to set/reset the
#                dvfilter internal communication endpoint, if
#                it is default that means we want restore the default
#                settings for the config option
#                 /Net/DVFilterBindIpAddress.
#
# Results:
#     SUCCESS, if setting dvfilter internal communication endpoint is
#              success
#     FAILURE, in case of any errors
#
# Side effects:
#     None
#
########################################################################

sub BindDVFilter
{
   my $self = shift;
   my $dvfilter = shift || "default";
   # this only works with ipv6.
   my $ip = $self->GetIPv4();
   my $host = $self->{hostName};
   my $stafHelper = $self->{hostObj}->{stafHelper};
   my $command;
   my $result;

   $command = "esxcli system settings advanced set -o /Net/DVFilterBindIpAddress ";
   if (! $dvfilter) {
      $command = "$command -d ";
   } else {
      $command = "$command -s $ip";
   }

   $result = $stafHelper->STAFSyncProcess($host,$command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to set /Net/DVFilterBindIpAddress $command to $ip");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
#
# VerifyVmknicArpCache--
#     Method to verify whether a newly added neighbor vmknic is displayed in the
#     ARP cache of the SUT host (after traffic has been passed between them)
#
# Input:
#     vmkinfo - tuple of the vmknic that is being checked for
#
# Results:
#     SUCCESS, upon successful verification
#     FAILURE, in case of any errors
#
# Side effects:
#     None
#
################################################################################

sub VerifyVmknicArpCache
{
   my $self = shift;
   my $vmkInfo = shift;
   my $deviceId = $self->{deviceId};
   my $stafHelper = $self->{hostObj}->{stafHelper};
   my $command;
   my $result;

   $result = $self->{hostObj}->GetNetworkNeighborList(deviceid => $deviceId);

   # Matching the MAC address of the destination vmknic with the output
   my $destMac = $vmkInfo->{macAddress};
   if ($result !~ /$destMac/i) {
      $vdLogger->Error("Vmknic with MAC: $destMac not present in ARP cache of ".
                       "vmknic $deviceId on host $self->{hostObj}->{hostIP}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return SUCCESS;
}


################################################################################
#
# VerifyARPNegativeTimer--
#     Method to verify whether the ARP timer shows a negative value for hosts
#     that do not exist
#
# Input:
#     vmkinfo - tuple of the vmknic that is being checked for
#
# Results:
#     SUCCESS, upon successful verification
#     FAILURE, in case of any errors
#
# Side effects:
#     None
#
################################################################################

sub VerifyARPNegativeTimer
{
   my $self = shift;
   my $vmkInfo = shift;
   my $deviceId = $self->{deviceId};
   my $stafHelper = $self->{hostObj}->{stafHelper};
   my $host = $self->{hostObj}->{hostIP};
   my $result;
   my $incTime = undef;

   # retrieving the neighbor list
   $result = $self->{hostObj}->GetNetworkNeighborList(deviceid => $deviceId);

   #
   # Note that once a vmknic that does not exist is pinged, the IP address
   # is entered in the neighbor list with an "incomplete" entry for its
   # corresponding MAC address. This entry stays for exactly 20 seconds and is
   # denoted by a negative time value, on the expiry of which the entry is
   # removed from the neighbor list.
   #
   # Retrieving time for the destination MAC address. If MAC address is not
   # present, then checking for "incomplete" entry and its corresponding time
   # value
   #
   my @tmp = split(/\n/,$result);
   foreach my $line (@tmp) {
      if ($line =~ /$vmkInfo->{macAddress}/i) {
         $vdLogger->Error("MAC address $vmkInfo->{macAddress} should not be ".
                          "present in the neighbor list of deviceId $deviceId".
                          " under host $host");
         $vdLogger->Error(Dumper($result));
         VDSetLastError("EOPFAILED");
         return FAILURE;
      } elsif ($line =~ /incomplete/i) {
         my @list = split (/\s+/, $line);
         $incTime = $list[3];
      }
   }

   if (not defined $incTime) {
      $vdLogger->Info("Entry for invalid IP destination must have expired by ".
                      "the time this check was made");
      return SUCCESS;
   }

   # Checking if the retrieved time is valid
   if ($incTime =~ /-\d+/) {
      $incTime =~ s/-//;
      if ($incTime > 20) {
         $vdLogger->Error("Retrieved time: -$incTime, is not within 20 seconds ".
                          "that is the permissible value for invalid ARP entries".
                          " for deviceId $deviceId under host $host");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Retrieved time: $incTime, should be a negative value ".
                       "lesser than 20 seconds, for invalid ARP entries for ".
                       "deviceId $deviceId under host $host");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return SUCCESS;
}


################################################################################
#
# GetInlineVirtualAdapter--
#     Method to create and return Vmknic inline object
#
# Input:
#     None
#
# Results:
#     returns Vmknic Inline Object
#
# Side effects:
#     None
#
################################################################################

sub GetInlineVirtualAdapter
{
   my $self = shift;
   use VDNetLib::InlineJava::Vmknic;
   my $inlineHost = $self->{hostObj}->GetInlineHostObject();
   return VDNetLib::InlineJava::Vmknic->new('host' => $inlineHost,
                                        'deviceId' => $self->{deviceId});
}

###############################################################################
#
# TAHIRun
#      This method will run TAHI command operation
#
# Input:
#      testModules : command array
#      adapterRef  : adapter obj
#      supportRef  : adapter obj
#
# Results:
#      SUCCESS: Command run successful
#      FAILURE: Command run failed
#
# Side effects:
#      None.
#
###############################################################################

sub TAHIRun
{
    my $self = shift;
    my $testModules = shift;
    my $testAdapter = shift;
    my $supportAdapter = shift;

    my $stafHelper = $self->{stafHelper};
    my $suiteName = "TAHI";
    my $pg = $testAdapter->{'pgName'};
    my $host = $testAdapter->{'hostName'};
    my $switch = $testAdapter->{'switchObj'}{'name'};
    my $suiteObj;

    my $logDir = File::Basename::dirname($vdLogger->{logFileName});
    $logDir = $logDir . "/TAHIlogs";
    $vdLogger->Debug("$suiteName log path: $logDir");

    $suiteObj = VDNetLib::Suites::TAHI->new(
                            'nut'         => $testAdapter,
                            'testNode'    => $supportAdapter,
                            'stafHelper'  => $stafHelper,
                            'logDir'      => $logDir,
                            );

    if ($suiteObj eq FAILURE) {
       $vdLogger->Error("Failed to $suiteName suite object");
       VDSetLastError(VDGetLastError());
       return FAILURE;
    }

    my $result = $suiteObj->Setup($testModules, $pg, $switch, $host);
    if ($result eq FAILURE) {
       $vdLogger->Error("Setup failed for $suiteName suite");
       VDSetLastError(VDGetLastError());
       return FAILURE;
    }

    $result = $suiteObj->RunTests($testModules);
    if ($result eq FAILURE) {
       $vdLogger->Error("Running tests/modules in $suiteName suite failed");
       VDSetLastError(VDGetLastError());
       return FAILURE;
    }

    $result = $suiteObj->Cleanup();
    if ($result eq FAILURE) {
       $vdLogger->Error("Cleanup failed for $suiteName suite");
       VDSetLastError("EOPFAILED");
       return FAILURE;
    }

    return SUCCESS;
}


########################################################################
#
# EnableDisableVSAN--
#     Method to enable/disable VSAN for given interface.
#
# Input:
#     operation: parameter to enable/disable VSAN
#
# Results:
#     SUCCESS, if VSAN enable/disable is successful
#     FAILURE, in case of any errors
#
# Side effects:
#     None
#
########################################################################

sub EnableDisableVSAN
{
   my $self       = shift;
   my $operation  = shift || "enable",
   my $interface  = $self->{deviceId};
   my $stafHelper = $self->{hostObj}->{stafHelper};
   my $host       = $self->{hostObj}->{hostIP};
   my $result;
   my $command;
   my $validOperations = "enable|disable";

   if ($operation !~ m/$validOperations/i) {
      $vdLogger->Error("Invalid operation - $operation, valid ones ".
                       "are - enable/disable");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # check the status before doing the operation
   my $vsanStatus = $self->GetVSANStatus();
   if (($operation =~ m/enable/i && $vsanStatus =~ /enable/i) ||
       ($operation =~ m/disable/i && $vsanStatus =~ /disable/i)) {
      $vdLogger->Info("VSAN status for $interface on $host is already $vsanStatus");
      return SUCCESS;
   }
   if ($operation =~ m/enable/i) {
      $command = "add";
   } else {
      $command = "remove";
   }
   $command = "esxcli vsan network ipv4 ". $command ." -i $interface";
   $result = $stafHelper->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to $operation VSAN for $interface " .
                       Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vsanStatus = $self->GetVSANStatus();
   if (($operation =~ m/enable/i && $vsanStatus =~ /enable/i) ||
       ($operation =~ m/disable/i && $vsanStatus =~ /disable/i)) {
      $vdLogger->Info("VSAN status for $interface on $host is $vsanStatus");
   } else {
      $vdLogger->Error("Failed to set VSAN status for $interface on $host");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetVSANStatus
#     Method to get VSAN status for given interface.
#
# Input:
#     none
#
# Results:
#     enabled/disabled, if able to get vmknic vsan status successfully
#     FAILURE, in case of any errors
#
# Side effects:
#     None
#
########################################################################

sub GetVSANStatus
{
   my $self       = shift;
   my $interface  = $self->{deviceId};
   my $stafHelper = $self->{hostObj}->{stafHelper};
   my $host       = $self->{hostObj}->{hostIP};
   my $result;
   my $command;

   $command = "esxcli vsan network list";
   $result = $stafHelper->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to get VSAN status for $interface " .
                       Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Trace("GetVSANStatus() result:" . Dumper($result));
   if ($result->{stdout} =~ /$interface/) {
      return "enabled";
   } else {
      return "disabled";
   }
}

########################################################################
#
# Getdvport
#     Method to get dvport number of the vmknic interface
#
# Input:
#     none
#
# Results:
#     The dvport number which connect to the vmknic interface
#     When you launch command 'esxcfg-vswitch -l' on host,
#     you get, say dvport 9, connect to host.1.vmknic.2. Then '9'
#     will return as result.
#
# Side effects:
#     None
#
########################################################################

sub Getdvport
{
   my $self = shift;

   if (not defined $self->{'hostObj'}) {
      $vdLogger->Error("Host object not defined!");
      return FAILURE;
   }
   my $hostObj  = $self->{'hostObj'};

   if (not defined $self->{macAddress}) {
      $vdLogger->Error("This vmknic has no mac address!");
      return FAILURE;
   }

   my $result = $hostObj->GetvNicDVSPortID($self->{macAddress});
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get dvport number of the vmknic");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return $result;
}

1;
