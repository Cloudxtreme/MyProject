########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::NetworkScope::VirtualWire;

use base 'VDNetLib::InlinePython::AbstractInlinePythonClass';

use strict;
use vars qw{$AUTOLOAD};
use Data::Dumper;
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              LoadInlinePythonModule
                                              Boolean
                                              ConfigureLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

use VDNetLib::InlineJava::Portgroup::VirtualWire;

use constant attributemapping => {
   'binding' => {
      'payload' => 'hardwaregatewayid',
      'attribute' => "id"
   },
   'torbindings' => {
      'payload' => 'torbindings',
      'attribute' => undef
   },
 };

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::VSM::VirtualWire
#
# Input:
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::VSM::VirtualWire
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class = shift;
   my %args  = @_;
   my $self;
   $self->{id} = $args{id};
   $self->{networkscope} = $args{networkscope};
   $self->{type} = "vsm";
   bless $self, $class;
   return $self;
}


########################################################################
#
# GetInlinePyObject --
#     Methd to get Python equivalent object of this class
#
# Input:
#     None
#
# Results:
#     Reference to Inline Python object of this class
#
# Side effects:
#     None
#
########################################################################

sub GetInlinePyObject
{
   my $self = shift;
   my $inlinePyNWScopeObj = $self->{networkscope}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('virtual_wire.VirtualWire',
                                              $inlinePyNWScopeObj,
                                             );
   if (defined $self->{id}) {
      $inlinePyObj->{id} = $self->{id};
   }
   if (!$inlinePyObj) {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   return $inlinePyObj;
}


########################################################################
#
# GetInlinePortgroupObject --
#   Implements the method to get inline portgroup object
#   (referring to portgroup since all other inherited classes implements
#   this method)
#
# Input:
#     None
#
# Results:
#     An instance of VDNetLib::InlineJava::Portgroup::VirtualWire
#
# Side effects:
#     None
#
########################################################################

sub GetInlinePortgroupObject
{
   my $self = shift;
   my $vwireId = $self->{id};
   return VDNetLib::InlineJava::Portgroup::VirtualWire->new(
                                                'name' => $self->{'id'});

}


#############################################################################
#
# GetMORId--
#     Method to get the vwire's dvpg Managed Object Ref ID.
#
# Input:
#
# Results:
#     dvportgroupMORId,
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub GetMORId
{
   my $self   = shift;
   my $dvportgroupMORId;

   my $inlinedvportgroupObj = $self->GetInlinePortgroupObject();
   if (!($dvportgroupMORId = $inlinedvportgroupObj->GetMORId())) {
      $vdLogger->Error("Failed to get the Managed Object ID for ".
	               "the vwire's dvportgroup: $self->{id}");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $vdLogger->Debug("Managed Object Ref ID for the dvportgroup:". $self->{id} .
                    " is MORId:". $dvportgroupMORId);
   return $dvportgroupMORId;
}


# TODO: Temp fix for demo Call is not going to python layer, find out why
sub GetId
{
   my $self = shift;
   return $self->{id};
}


###############################################################################
#
# CheckMTEPOnHost --
#      This method will check the VTEP list on all the hosts for a specified
#      Logic switch(VNI).
#
# Input:
#      hosts     - The host list which to be checked(mandatory)
#
# Results:
#      Returns SUCCESS, if succeeded.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub CheckMTEPOnHost
{
   my $self = shift;
   my $hostObjArray = shift;

   if (not defined $hostObjArray) {
      $vdLogger->Error("hosts not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $cmd;
   my $seganddvsHash;
   my $tmpsegmentid;
   my $tmpdvsname;
   my $result;
   my $tmphostIP;

   my $vWireinlineObj = $self->read();
   my $vxlanid = $vWireinlineObj->{vdnId};

   #get segment ID & the name of DVS which used in vxlan for each hosts
   foreach my $hostObj (@$hostObjArray) {
      $tmphostIP = $hostObj->{hostIP};
      $tmpsegmentid = $hostObj->GetVxlanSegmentIDOnHost();
      if (FAILURE eq $tmpsegmentid) {
         $vdLogger->Error("Failed to get segmentid on:" . $tmphostIP);
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      $tmpdvsname = $hostObj->GetVxlanVDSNameOnHost();
      if (FAILURE eq $tmpdvsname) {
         $vdLogger->Error("Failed to get dvs name on:" . $tmphostIP);
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      $seganddvsHash->{$tmphostIP}->{'segmentid'} = $tmpsegmentid;
      $seganddvsHash->{$tmphostIP}->{'dvsname'} = $tmpdvsname;
   }

   foreach my $hostObj (@$hostObjArray) {
      $tmphostIP = $hostObj->{hostIP};
      $tmpsegmentid = $seganddvsHash->{$tmphostIP}->{'segmentid'};
      $tmpdvsname = $seganddvsHash->{$tmphostIP}->{'dvsname'};
      $vdLogger->Info("Checking MTEP list on host $tmphostIP...");
      #get vtep list on target host
      $cmd = "localcli network vswitch dvs vmware vxlan network vtep list " .
             " --vds-name $tmpdvsname --vxlan-id $vxlanid";
      $result = $hostObj->{stafHelper}->STAFSyncProcess($tmphostIP,$cmd);
      if ($result->{rc} != 0 || $result->{exitCode} != 0) {
         $vdLogger->Error("Failed to run command: $cmd". Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      my @tempArray = split(/(\n+)/, $result->{stdout});

      # verify MTEP for each segment(host) in the same VNI on target host
      my $mtepNum = 0;
      my $tmpsegmentidB;
      my $tmphostIPB;
      foreach my $hostObjB (@$hostObjArray) {
         $tmphostIPB = $hostObjB->{hostIP};
         if ($tmphostIP eq $tmphostIPB) {
            next;
         }

         my $tmpsegmentidB = $seganddvsHash->{$tmphostIPB}->{'segmentid'};
         #skip the host which have the same segment ID as the target host
         if ($tmpsegmentid eq $tmpsegmentidB) {
            next;
         }

         $vdLogger->Info("Checking MTEP list for segment $tmpsegmentidB...");
         $mtepNum = 0;
         foreach my $templine (@tempArray) {
            if (($templine =~ /$tmpsegmentidB \s+true/) or
                ($templine =~ /$tmpsegmentidB \s+MTEP/)) {
               $mtepNum++;
            }
         }

         if ($mtepNum == 1) {
            $vdLogger->Info("The MTEP list is correct for segment" .
                            " $tmpsegmentidB");
         } else {
            $vdLogger->Error("The MTEP list is wrong for segment" .
                             "$tmpsegmentidB as MTEP Number is $mtepNum");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }

      $vdLogger->Info("The MTEP list is correct on host $tmphostIP");
   }

   return SUCCESS;
}


###############################################################################
# CheckControllerOnHost --
#      This method will check the controller connection and status on all the
#      hosts for a specified Logic switch(VNI).
#
# Input:
#      expectedstaus - The expected status(up/down) of the controller(mandatory)
#      hosts         - The host list which to be checked(mandatory)
#
# Results:
#      Returns SUCCESS, if succeeded.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub CheckControllerStatusOnHost
{
   my $self = shift;
   my $expectedstaus = shift;
   my $hostObjArray  = shift;

   if (not defined $hostObjArray) {
      $vdLogger->Error("hosts not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $precontrolerinfo = '';
   my $curcontrollerinfo;
   my $curhostIP;
   my $vxlanid = $self->{vxlanId};

   #get vxlan controller information for the same vxlan from each hosts
   foreach my $hostObj (@$hostObjArray) {
      $curhostIP = $hostObj->{hostIP};
      $curcontrollerinfo = $hostObj->GetVxlanContollerInfoOnHost($vxlanid);
      if (FAILURE eq $curcontrollerinfo) {
         $vdLogger->Error("Failed to get controller info on:" . $curhostIP);
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      if ($curcontrollerinfo !~ m/$expectedstaus/s) {
         $vdLogger->Error("Controller status is wrong on host $curhostIP," .
                         "which is:$curcontrollerinfo");
         return FAILURE;
      }

      if ($precontrolerinfo eq '') {
         $precontrolerinfo = $curcontrollerinfo;
         $vdLogger->Info("The controller info for vxlan: $vxlanid " .
                         "is $precontrolerinfo,begainning to check it " .
                         "on all other hosts...");
      } else {
         if ($curcontrollerinfo ne $precontrolerinfo) {
            $vdLogger->Error("The controller info of vxlan:$vxlanid is wrong" .
                             "on:$curhostIP, which is:" . $curcontrollerinfo);
            return FAILURE;
         } else {
            $vdLogger->Info("The controller info on $curhostIP is correct");
         }
      }
   }

   $vdLogger->Info("Controller info of vxlan:$vxlanid is correct on all hosts");
   return SUCCESS;
}


###############################################################################
#
# GetMacEntryHashOnHost --
#      Method to verify MAC entry hash for a particular host
#
# Input:
#      data : an array reference contains user spec and host objs (required)
#             user spec is a result hash contain the following attribute
#             mac => "00:50:56:b2:30:6e"
#             host is the host obj that the MAC entry is to be checked on.
#
# Results:
#      Returns SUCCESS, if succeed.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub GetMacEntryHashOnHost
{
   my $self         = shift;
   my $serverForm   = shift;
   my $inventoryObj = shift;

   my @serverData  = ();
   my $resultHash  = undef;

   my $vWireinlineObj = $self->read();
   my $vxlanid = $vWireinlineObj->{vdnId};

   my $hostObj = $inventoryObj->[0];
   my $macEntryArray = $hostObj->GetVxlanMacEntryOnHost($vxlanid);
   if (FAILURE eq $macEntryArray) {
      $resultHash->{status} = "FAILURE";
      $resultHash->{reason} = "failed to get mac hash on:$hostObj->{hostIP}";
   } else {
      foreach my $tmpline (@$macEntryArray) {
         push @serverData, {'mac' => uc($tmpline)};
      }

      $resultHash->{status} = "SUCCESS";
      $resultHash->{response} = \@serverData;
   }

   return $resultHash;
}


###############################################################################
#
# GetArpEntryHashOnHost --
#      Method to verify ARP entry hash for a particular host
#
# Input:
#     serverForm : entry hash array generate from userData, like
#                  [
#                     {
#                       ip  => undef,
#                       mac => undef
#                     }
#                  ],
#     inventoryObj: reference to an host object array
#
# Results:
#      Returns a hash array with keys of 'status'(SUCCESS) and
#      'response'(the ARP entry array of this VNI on the host),if succeed.
#      Returns a hash array with keys of 'status'(FAILURE) and
#      'reason'(the failed reason),if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub GetArpEntryHashOnHost
{
   my $self         = shift;
   my $serverForm   = shift;
   my $inventoryObj = shift;
   my @serverData;
   my $resultHash  = undef;

   my $vWireinlineObj = $self->read();
   my $vxlanid = $vWireinlineObj->{vdnId};

   my $hostObj = $inventoryObj->[0];
   my $arpEntryArray = $hostObj->GetVxlanArpEntryOnHost($vxlanid);
   if (FAILURE eq $arpEntryArray) {
      $resultHash->{status} = "FAILURE";
      $resultHash->{reason} = "failed to get arp hash on:$hostObj->{hostIP}";
   } else {
      foreach my $tmpline (@$arpEntryArray) {
         if ($tmpline ne '') {
            my ($ip, $mac) = split(/\,/,$tmpline);
            push @serverData, {'ip'  => $ip,'mac' => uc($mac)};
         }
      }

      $resultHash->{status} = "SUCCESS";
      $resultHash->{response} = \@serverData;
   }

   return $resultHash;
}


###############################################################################
#
# GetVtepEntryHashOnHost --
#      Method to verify VTEP entry hash for a particular host
#
# Input:
#     serverForm : entry hash array generate from userData, like
#                  [
#                     {
#                      vtepip  => undef,
#                     }
#                  ],
#     inventoryObj: reference to a host object array
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#      None.
#
###############################################################################

sub GetVtepEntryHashOnHost
{
   my $self         = shift;
   my $serverForm   = shift;
   my $inventoryObj = shift;
   my @serverData;
   my $resultHash  = undef;

   my $vWireinlineObj = $self->read();
   my $vxlanid = $vWireinlineObj->{vdnId};

   my $hostObj = $inventoryObj->[0];
   my $vtepEntryArray = $hostObj->GetVxlanVtepEntryOnHost($vxlanid);
   if (FAILURE eq $vtepEntryArray) {
      $resultHash->{status} = "FAILURE";
      $resultHash->{reason} = "failed to get vtep hash on:$hostObj->{hostIP}";
   } else {
      foreach my $vtepip (@$vtepEntryArray) {
         if ($vtepip ne '') {
            push @serverData, {'vtepip'  => $vtepip};
         }
      }

      $resultHash->{status} = "SUCCESS";
      $resultHash->{response} = \@serverData;
   }

   return $resultHash;
}


######################################################################
#
# GetHorizontalTableFromController --
#     Method to get horizontal table from controllers, it will be used for
#        verification module
#
# Input:
#     controllerObjs: reference to controller objects
#     table         : table types, like arp-table, mac-table ...
#
# Results:
#     Return a result hash which include the return status and response
#
# Side effects:
#     None
#
########################################################################

sub GetHorizontalTableFromController
{
   my $self           = shift;
   my $controllerObjs = shift;
   my $table          = shift;
   my $resultHash = {
     'status' => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };

   my $controller = $self->get_controller_based_on_vni($controllerObjs);
   if ($controller eq "FAILURE") {
       $resultHash->{reason} = "cannot get controller object for a specific vni";
       return $resultHash;
   }

   my $index = 0;
   for ($index = 0; $index < scalar(@$controllerObjs); $index++) {
       if ($controllerObjs->[$index]->get_ip() eq $controller->get_ip()) {
           last;
       }
   }
   splice(@$controllerObjs, $index, 1);
   my $horizontal_table  = $self->get_horizontal_table_from_controllers($table,
                                                $controller, $controllerObjs);
   if ($horizontal_table eq "FAILURE") {
       $resultHash->{reason}  = "meet error while try to fetch " . $table .
                                " from controller";
       return $resultHash;
   }

   $resultHash->{status}   = "SUCCESS";
   $resultHash->{response} = $horizontal_table;
   return $resultHash;
}


######################################################################
#
# GetArpEntriesFromController --
#     Method to get arp entries from controllers, it will be used for
#        verification module
#
# Input:
#     serverForm : entry hash array generate from userData, like
#                  [
#                     {
#                       ip  => undef,
#                       mac => undef
#                     }
#                  ],
#     controllerObjs: reference to controller objects
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub GetArpEntriesFromController
{
   my $self           = shift;
   my $serverForm     = shift;
   my $controllerObjs = shift;
   my @serverData;

   my $resultHash = $self->GetHorizontalTableFromController($controllerObjs,
                                                            "arp-table");
   if ($resultHash->{'status'} eq 'FAILURE') {
      return $resultHash;
   }
   my $arp_table = $resultHash->{response};

   foreach my $arp_entry (@$arp_table) {
      my $ip  = $arp_entry->{'ip'};
      my $mac = uc($arp_entry->{'mac'});
      push @serverData, {'ip'  => $ip, 'mac' => $mac};
   }

   $vdLogger->Debug("serverData got from the server: " . Dumper(@serverData));
   $resultHash->{response} = \@serverData;
   return $resultHash;
}


######################################################################
#
# GetMacEntriesFromController --
#     Method to get mac entries from controllers, it will be used for
#        verification module
#
# Input:
#     serverForm : entry hash array generate from userData, like
#                  [
#                     { mac => undef }
#                  ],
#     controllerObjs: reference to controller objects
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub GetMacEntriesFromController
{
   my $self           = shift;
   my $serverForm     = shift;
   my $controllerObjs = shift;
   my @serverData;

   my $resultHash = $self->GetHorizontalTableFromController($controllerObjs,
                                                            "mac-table");
   if ($resultHash->{'status'} eq 'FAILURE') {
      return $resultHash;
   }
   my $mac_table = $resultHash->{response};
   foreach my $mac_entry (@$mac_table) {
      my $mac = uc($mac_entry->{'mac'});
      push @serverData, {'mac' => $mac};
   }

   $vdLogger->Debug("serverData got from the server: " . Dumper(@serverData));
   $resultHash->{response} = \@serverData;
   return $resultHash;
}


######################################################################
#
# GetConnectionEntriesFromController --
#     Method to get connection entries from controllers, it will be used for
#        verification module
#
# Input:
#     serverForm : entry hash array generate from userData, like
#                  [
#                     { hostip => undef }
#                  ],
#     controllerObjs: reference to controller objects
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub GetConnectionEntriesFromController
{
   my $self           = shift;
   my $serverForm     = shift;
   my $controllerObjs = shift;
   my @serverData;

   my $resultHash = $self->GetHorizontalTableFromController($controllerObjs,
                                                            "connection-table");
   if ($resultHash->{'status'} eq 'FAILURE') {
      return $resultHash;
   }
   my $connection_table = $resultHash->{response};

   foreach my $connection_entry (@$connection_table) {
      my $connection = $connection_entry->{'host_ip'};
      push @serverData, {'hostip' => $connection};
   }

   $vdLogger->Debug("serverData got from the server: " . Dumper(@serverData));
   $resultHash->{response} = \@serverData;
   return $resultHash;
}


######################################################################
#
# GetVtepEntriesFromController --
#     Method to get vtep entries from controllers, it will be used for
#        verification module
#
# Input:
#     serverForm : entry hash array generate from userData, like
#                  [
#                     { vtepip => undef }
#                  ],
#     controllerObjs: reference to controller objects
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub GetVtepEntriesFromController
{
   my $self           = shift;
   my $serverForm     = shift;
   my $controllerObjs = shift;
   my @serverData;

   my $resultHash = $self->GetHorizontalTableFromController($controllerObjs,
                                                            "vtep-table");
   if ($resultHash->{'status'} eq 'FAILURE') {
      return $resultHash;
   }
   my $vtep_table = $resultHash->{response};

   foreach my $vtep_entry (@$vtep_table) {
      my $vtepip = $vtep_entry->{'ip'};
      push @serverData, {'vtepip' => $vtepip};
   }

   $vdLogger->Debug("serverData got from the server: " . Dumper(@serverData));
   $resultHash->{response} = \@serverData;
   return $resultHash;
}


######################################################################
#
# GetVirtualWireInfoFromController --
#     Method to get special virtual wire info from controllers,
#         it will be used for verification module
#
# Input:
#     controllerObjs: reference to controller objects
#
# Results:
#     Return a result hash which include the return status and response
#
# Side effects:
#     None
#
########################################################################

sub GetVirtualWireInfoFromController
{
   my $self           = shift;
   my $serverForm     = shift;
   my $controllerObjs = shift;
   my $serverData = {
      vni => "EXIST",
   };
   my $resultHash = {
     'status'      => "SUCCESS",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };

   my $controller = $self->get_controller_based_on_vni($controllerObjs,
                                                       $self->{vxlanId});
   if ($controller eq "FAILURE") {
       $serverData->{vni} = "NOT_EXIST";
   }
   $resultHash->{response} = $serverData;
   return $resultHash;
}


######################################################################
#
# GetVirtualWireInfoFromHost --
#     Method to get special virtual wire info from host,
#         it will be used for verification module
#
# Input:
#     hostObjs: reference to host objects
#
# Results:
#     Return a result hash which include the return status and response
#
# Side effects:
#     None
#
########################################################################

sub GetVirtualWireInfoFromHost
{
   my $self           = shift;
   my $serverForm     = shift;
   my $hostObjs       = shift;

   my @serverData = ();
   my $resultHash = {
     'status'      => "SUCCESS",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };

   foreach my $hostObj (@$hostObjs) {
      my $hostIP    = $hostObj->{hostIP};
      my $dvsName   = $hostObj->GetVxlanVDSNameOnHost();
      my $cmd = "localcli network vswitch dvs vmware vxlan network vtep list " .
             " --vds-name $dvsName --vxlan-id $self->{vxlanId}";
      my $result = $hostObj->{stafHelper}->STAFSyncProcess($hostIP, $cmd);
      if ($result->{rc} != 0) {
         $resultHash->{reason} = "Failed to run command: $cmd";
         $resultHash->{status} = "FAILURE";
         return $resultHash;
      }
      if ($result->{exitCode} != 0) {
         push @serverData, {'vni' => 'NOT_EXIST'};
      } else {
         push @serverData, {'vni' => 'EXIST'};
      }
   }
   $vdLogger->Info("serverData got from the server: " . Dumper(@serverData));
   $resultHash->{response} = \@serverData;
   return $resultHash;
}


######################################################################
#
# TestGroupConnectivity --
#      Method to test multicast group connectivity in virtual wire
#      or perform a point to point connectivity test between two
#      hosts across which a VXLAN virtual wire
#
# Input:
#      testmethod : p2p or multicast
#      sourceHostObj: reference to soruce host object
#      destinationHostObj: reference to destination host object
#      sourceVlanid: source vtep vlan id
#      destinationVlanid: destination vtep vlan id
#      sourceSwitchObj: reference to soruce switch object
#      destinationSwitchObj: reference to destination switch object
#      packetSize: send check traffic packet size
#
# Results:
#      Returns SUCCESS, if succeed.
#      Returns FAILURE, if failed.
#
# Side effects:
#     None
#
########################################################################

sub TestGroupConnectivity
{
   my $self = shift;
   my %args = @_;
   my $testmethod = $args{testgroupconnectivity};
   my $sourceHostObj = $args{sourcehost};
   my $destinationHostObj = $args{destinationhost};
   my $sourceVlanid = $args{sourcevlanid};
   my $destinationVlanid = $args{destinationvlanid};
   my $sourceSwitchObj = $args{sourceswitch};
   my $destinationSwitchObj = $args{destinationswitch};
   my $packetSize = $args{packetsize};

   my $sourceHostId = $sourceHostObj->GetMORId();
   my $destinationHostId = $destinationHostObj->GetMORId();

   my $sourceSwitchId = $sourceSwitchObj->{'switchObj'}->GetMORId();
   my $destinationSwitchId = $destinationSwitchObj->{'switchObj'}->GetMORId();

   my $sourceGatewayIP = $sourceHostObj->GetVTEPDefaultGateway();
   my $testParameter = {
      sourcehostid => $sourceHostId,
      destinationhostid => $destinationHostId,
      sourceswitchid => $sourceSwitchId,
      destinationswitchid => $destinationSwitchId,
      sourcegateway => $sourceGatewayIP,
      sourcevlanid => $sourceVlanid,
      destinationvlanid => $destinationVlanid,
      packtsize => $packetSize,
      testmethod => $testmethod,
   };
   my $result = $self->test_group_connectivity($testParameter);
   if ($result eq "FAILURE") {
      $vdLogger->Error("Test group connectivity $testmethod failed");
      return FAILURE;
   }
   $vdLogger->Debug("Test group connectivity $testmethod pass");
   return SUCCESS;
}


########################################################################
#
# SetVtepIpAddress --
#     Method to set the vtep ip address to either static ip address or
#         dynamic dhcp mode.
#
# Input:
#     hostObj     : reference to host object
#     clusterObj  : reference to cluster object which the host belongs to
#     vtepipv4    : static/dhcp
#     ipv4address : XX.XX.XX.XX
#     network     : the ip address netmask
#
# Results:
#     SUCCESS if change the vtep ip address succesfully.
#     FAILURE in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetVtepIpAddress
{
   my $self       = shift;
   my %args       = @_;
   my $mode       = $args{'ipv4'};
   my $arrayRefHostObj = $args{'host'};
   my $clusterObj = $args{'cluster'};
   my $ipAddress  = $args{'ipv4address'};
   my $netmask    = $args{'netmask'};

   if (($mode ne "dhcp") && ($mode ne "static")) {
      $vdLogger->Error("Unkown mode for set vtep ip address: $mode");
      VDSetLastError(VDGetLastError);
      return FAILURE;
   }

   my $clusterId    = $clusterObj->GetClusterMORId();
   my $hostObj      = $arrayRefHostObj->[0];
   my $hostId       = $hostObj->GetMORId();
   my $vteplist     = $self->get_vteps($hostId, $clusterId);
   my $elementCount = @$vteplist;
   if ($elementCount > 1) {
      $vdLogger->Warn("current vtep has multiple vtep ip addresses, " .
                      "will only change the first vtep ip address");
   }

   my $vtepIp = $vteplist->[0];
   my $vmknic = $hostObj->GetVmknicByIPAddress($vtepIp);

   if ((not defined $vmknic) || ($vmknic eq 'FAILURE')) {
      $vdLogger->Error("Failed to get vmknic name based on ip address $ipAddress");
      VDSetLastError(VDGetLastError);
      return FAILURE;
   }

   my $result = $hostObj->SetVmknicIpAddress(
                                  'mode'    => $mode,
                                  'vmknic'  => $vmknic,
                                  'ipv4'    => $ipAddress,
                                  'netmask' => $netmask
                                  );
   if ($result eq "FAILURE") {
      $vdLogger->Error("Failed to set $vmknic ip address!");
      VDSetLastError(VDGetLastError);
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# SetMTU --
#     Method to set the vtep vmknic ports mtu size, if multiple vmknic
#        ports exist, then all the vmknic ports mtu will be set.
#
# Input:
#     mtu         : mtu size for the vmknic port for vxlan
#     hostObj     : reference to host object
#     clusterObj  : reference to cluster object which the host belongs to
#
# Results:
#     SUCCESS if change the vtep vmknic ports succesfully.
#     FAILURE in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetMTU
{
   my $self            = shift;
   my $mtu             = shift;
   my $arrayRefHostObj = shift;
   my $clusterObj      = shift;

   return SUCCESS;
}


########################################################################
#
# ClearVWireEntryOnHost --
#     Method to clear the mac/arp/vtep entry on a host.
#
# Input:
#     entry         : reference to the entry to be cleared
#     hostObjArray  : reference to host objects
#
# Results:
#     SUCCESS if clear the assigned entry succesfully.
#     FAILURE in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ClearVWireEntryOnHost
{
   my $self         = shift;
   my %args         = @_;
   my $entry        = $args{'clearvwireentryonhost'};
   my $hostObjArray = $args{'hosts'};

   if (($entry ne 'arp') && ($entry ne 'mac') && ($entry ne 'vtep')) {
      $vdLogger->Error("Unkown entry: $entry to be cleaned");
      VDSetLastError(VDGetLastError);
      return FAILURE;
   }

   my $vxlanid = $self->{vxlanId};
   foreach my $hostObj (@$hostObjArray) {
      if (FAILURE eq $hostObj->ClearVxlanEntryOnHost($vxlanid,$entry)) {
         $vdLogger->Error("Failed to clear $entry entry on host:" .
                          $hostObj->{hostIP});
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }

   return SUCCESS;
}


###############################################################################
#
# GetMacCount --
#      Method to verify MAC count for a particular host
#
# Input:
#      serverForm : entry hash array generate from userData,
#                 [
#                    { maccount => undef }
#                 ],
#      inventoryObj: reference to an host object array
#
# Results:
#      Returns a hash array with keys of 'status'(SUCCESS) and
#      'response'(the count of mac entry of this VNI on the host),if succeed.
#      Returns a hash array with keys of 'status'(FAILURE) and
#      'reason'(the failed reason),if failed.
# Side effects:
#      None.
#
###############################################################################

sub GetMacCount
{
   my $self         = shift;
   my $serverForm   = shift;
   my $inventoryObj = shift;

   my %serverData;
   my $resultHash  = {
      'status' => "FAILURE",
      'response' => undef,
      'error' => undef,
      'reason' => undef,
   };

   my $vWireinlineObj = $self->read();
   my $vxlanid = $vWireinlineObj->{vdnId};

   my $hostObj = $inventoryObj->[0];
   my $maccount = $hostObj->GetVxlanMacCountOnHost($vxlanid);
   if (FAILURE eq $maccount) {
      $resultHash->{status} = "FAILURE";
      $resultHash->{reason} = "failed to get mac hash on:$hostObj->{hostIP}";
   } else {
      $serverData{'count'} = $maccount;
      $resultHash->{status} = "SUCCESS";
      $resultHash->{response} = \%serverData;
   }

   return $resultHash;
}


#######################################################################
#
# GetObjectParentAttributeName--
#     Returns the Attribute this class is using to store its parent
#
# Input:
#     None
#
# Results:
#     SUCCESS
#
########################################################################

sub GetObjectParentAttributeName
{
   return "networkscope";
}


#######################################################################
#
# PortAttach--
#     Attaches TOR binding with virtual wire
#
# Input:
#     key port attach key
#     spec Port attachment spec that is to be processed and passed on to pylib
#
# Results:
#     SUCCESS
#
########################################################################

sub PortAttach
{
   my $self = shift;
   my $key = shift;
   my $spec = shift;

   my $attributeMapping = $self->GetAttributeMapping();
   my $processedSpec = $self->ProcessSpec($spec, $attributeMapping);
   $vdLogger->Info("Doing attachment of vwires with TOR bindings");
   my $result;

   eval {

       my $inlinePyObj = $self->GetInlinePyObject();
       $result = $inlinePyObj->tor_attach(@$processedSpec[0]);
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while attaching vwire " .
                       " to torbinding in python:\n". $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if ($result eq 'FAILURE') {
       $vdLogger->Error("Failed to attach vwire to torbinding");
       VDSetLastError("EOPFAILED");
       return FAILURE;
   } else {
       $vdLogger->Info("successfully attached vwire to torbinding");
   }

   return SUCCESS;
}


#######################################################################
#
# PortDetach--
#     Dettaches TOR binding from virtual wire
#
# Input:
#     key port detach key
#     spec Port detachment spec that is to be processed and passed on to pylib
#
# Results:
#     SUCCESS
#
########################################################################

sub PortDetach
{
   my $self = shift;
   my $key = shift;
   my $spec = shift;

   my $attributeMapping = $self->GetAttributeMapping();
   my $processedSpec = $self->ProcessSpec($spec, $attributeMapping);
   $vdLogger->Info("Doing detachment of vwires from TOR bindings");
   my $result;

   eval {

       my $inlinePyObj = $self->GetInlinePyObject();
       $result = $inlinePyObj->tor_detach(@$processedSpec[0]);
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while detaching vwire " .
                       " for torbinding in python:\n". $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if ($result eq 'FAILURE') {
       $vdLogger->Error("Failed to detach vwire from torbinding");
       VDSetLastError("EOPFAILED");
       return FAILURE;
   } else {
       $vdLogger->Info("successfully detached vwire from torbinding");
   }

   return SUCCESS;
}


1;
