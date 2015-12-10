#######################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Switch::VDSwitch::DVPortGroup;

#
# This package is responsible for handling all the interaction with
# VMware vNetwork Distributed Switch portgroup.
#

use strict;
use warnings;
use Data::Dumper;

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError );
use VDNetLib::Switch::VDSwitch::DVPort;
use VDNetLib::InlineJava::Portgroup::DVPortgroup;
use Data::Dumper;

#######################################################################
#
# new --
#      This is entry point for this package to create an object of
#      VDNetLib::Switch::VDSwitch::DVPortgroup.
#
# Input:
#      A named parameter list, in other word a hash with following keys:
#      'DVPGName': name of the DV portgroup (Required)
#      'switchObj': Object of the switch(vDS) to which the given portgroup
#                  belongs (Required)
#      'stafHelper': Reference to an object of VDNetLib::STAFHelper
#                    (Optional)
#
# Results:
#      An object of VDNetLib::Switch::VDSwitch::DVPortgroup, if successful;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
sub new
{
   my $class      = shift;
   my %args       = @_;
   my $tag = "DVPortgroup : new : ";
   my $self;
   my $switchObj = $args{switchObj};
   my $DVPGName = $args{DVPGName};
   my $stafHelper = $args{stafHelper};
   my $result;

   if (not defined $switchObj) {
      $vdLogger->Error("$tag vds switch object not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $DVPGName) {
      $vdLogger->Error("$tag vds portgroup not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $self->{DVPGName} = $DVPGName;
   $self->{pgName} = $DVPGName; # To be compatible with VSS PortGroup.pm
   $self->{name} = $DVPGName; # Generic param all classes should have
   $self->{stafHelper} = $stafHelper;
   $self->{switchObj} = $switchObj;
   $self->{DVPort} = undef;

   # create stafHelper if it is not defined.
   if (not defined $self->{stafHelper}) {
      my $options;
      $options->{logObj} = $vdLogger;
      my $temp = VDNetLib::Common::STAFHelper->new($options);
      if (not defined $temp) {
         $vdLogger->Error("Failed to create VDNetLib::STAFHelper object");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $self->{stafHelper} = $temp;
   }

   bless($self,$class);
   return $self;
}


#########################################################################
##Attach (%args)
# Attaches a DVPort object to the DVPorgroup hash
#
# Input
#  key A string identifying the object, eg DVPort
#  value A reference to the object to be added
#
# Results
# if successful SUCCESS, else FAILURE.
#
# Side effects:
# None
#
# Note
# None
#
sub Attach
{
   my $self = shift;
   my %arg = @_;
   my $key = $arg{key};
   my $value = $arg{value} || undef;

   if (not defined $key) {
      VDSetLastError("EONOTDEF");
      return FAILURE;
   }
   if (defined $value) {
      if ($value =~ m/VDNetLib::Switch::VDSwitch::DVPort/) {
         ${ $self->{ DVPortGroup } }{ $key } = $value;
         $vdLogger->Debug("DVPort Attached to the DVPortGroup");
         return SUCCESS;
      } else {
        #
        # do nothing,return FAILURE since at this point only
        # dvport can be attached to DVPortgroup. Modify this
        # if more objects need to attached.
        #
        return FAILURE;
     }
   }

   # check for the value and return.
   if ( exists ${ $self->{ DVPort } }{ $key } ) {
      return ${ $self->{ DVPort } }{ $key };
   } else {
      $vdLogger->Error("Key Not Found ($key)");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}


#########################################################################
## Detach (%args)
#
# Detaches a DVPort object from DVPortgroup
#
# Input
# key :  A string identifying the object, eg Port1
# value :  A reference to the object to be added
#
# Results
# if successful SUCCESS,else FAILURE.
#
# Side effects:
# None
#
# Note
# None
#
sub Detach
{
   my $self = shift;
   my %args = @_;
   my $key = $args{key};
   my $value = $args{value} || undef;

   if (not defined $key) {
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (defined $value) {
      #
      # Detach it from the object.
      #
      if($value =~ m/VDNetLib::Switch::VDSwitch::DVPort/) {
         delete ${ $self->{ DVPort} }{ $key };
         if ( ! exists ${ $self->{ DVPort} }{ $key } ) {
            return SUCCESS;
         }
      }
   } else {
      # if only $key is specified.
      if ( exists ${ $self->{ DVPort } }{ $key } ) {
         delete ${ $self->{ DVPort} }{ $key };
         return SUCCESS;
      }
   }
   return FAILURE;
}


########################################################################
#
# AddDVPortToDVPortGroup
#     This method attaches ports to dvports group.
#
# Input:
#      arrayOfSpecs : array of hashes containing dvport spec
#
# Results:
#      return array of dvport objects
#      "FAILURE", in case of any error,
#
# Side effects:
#      None
#
########################################################################

sub AddDVPortsToDVPortGroup
{
   my $self         = shift;
   my $arrayOfSpecs = shift;
   my @arrayOfDVPortObjects;

   my $noOfDVPorts = "0";
   foreach my $element (@$arrayOfSpecs) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("DV Ports spec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my %options = %$element;
      # Collect number of ports so that vdnet can create
      # it one shot.
      $noOfDVPorts++;
   }

   my $inlineDvpgObj = $self->GetInlinePortgroupObject();
   if ((not defined $inlineDvpgObj) || ($inlineDvpgObj == 0)) {
      $vdLogger->Error("GetInlinePortgroupObject failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $result = $inlineDvpgObj->AddPortsToDVPortGroup($noOfDVPorts);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to add $noOfDVPorts to $self->{DVPGName}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   } else {
      $vdLogger->Info("Succesfully created $noOfDVPorts port on $self->{DVPGName}");
   }

   my $portKeysList = $inlineDvpgObj->GetPortKeys();

   foreach my $portKey (@$portKeysList) {
      my $dvPortObj = VDNetLib::Switch::VDSwitch::DVPort->new(
                                   'DVPGObj'    => $self,
                                   'DVPort'     => $portKey,
                                   'stafHelper' => $self->{stafHelper});
      if ($dvPortObj eq FAILURE) {
         $vdLogger->Error("Failed to create port object");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      push @arrayOfDVPortObjects, $dvPortObj;
   }

   return \@arrayOfDVPortObjects;
}


################################################################################
# AddPortToDVPG(%args)
# This method adds port to the DVPortgroup on the specified DVS.
#
# Input:
# DVSNAME DVS namem, if specifies pg11-15 it would add port to pg11,
#                    pg12, pg13, pg14, pg15.
# DCNAME Data Center name (Optional)
# DVPGNAME DVPG name
#
# Results
# Returns SUCCESS if the port is added to DVPG,
# else FAILURE
#
# Side effects:
# dvport is added to the dvportgroup.
#
# note
# None
#
sub AddPortToDVPG
{
   my $self = shift;
   my $dvPg = $self->{DVPGName};
   my $tag = "DVPortGroup : AddPortToDVPG : ";
   my $vds = $self->{switchObj}->{switch};
   my $proxy = $self->{switchObj}->{vcObj}->{proxy};
   my $dvPortObj;
   my $port,
   my $dcName = $self->{switchObj}->{datacenter};
   my $result;
   my $anchor;
   my $cmd;
   my @dvpgs;

   $anchor = $self->{switchObj}->GetAnchor(SERVICE => "setup");
   if ($anchor eq FAILURE) {
      $vdLogger->Error("$tag Failed to create/get the anchor");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   #
   # In case the dvportgroup name was given as "pg23-100"
   # Add support for creating dvports for a bunch of dvpgs in a single workload.
   #

   if ($dvPg =~ m/^([^\-]+[a-zA-Z])(\d+)-(\d+)$/) {
      for (my $i=$2; $i<=$3; $i++) {
         push(@dvpgs,$1.$i);
      }
   } else {
      push(@dvpgs,$dvPg);
   }

   for (my $i = 1; $i <= scalar(@dvpgs); $i++) {
      my $dvpg = $dvpgs[$i-1];
      # command to add dvport to the dvportgroup.
      $cmd = "addporttodvpg anchor $anchor dvsname $vds " .
                     "dvportgroupname $dvpg";
      if (defined $dcName) {
         $cmd = "$cmd  dcName $dcName";
      }

      # run the command to add the port to dvportgroup.
      $vdLogger->Debug("running addporttodvpg command $cmd");
      $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy, $cmd);
      if ($result->{rc} != 0) {
         $vdLogger->Error("$tag Failed to add dvport in dvPortgroup $dvpg ".
                          "for vDS $vds");
         $vdLogger->Error(Dumper($result));
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }

   return SUCCESS;
}


########################################################################
#
# AddVMKNIC
#     This method attaches the vmknic to dvportgroup.
#
#
# Input:
#   A Named hash having following parameters.
#      host : Name of the esx host to which vmknic is to be attached.
#      dvPortgroup : Name of the dvportgroup.
#      IP : IP address of the vmknic to be created (IPv4 or IPv6).
#      netmask : Netmask of the vmknic to be created.
#      prefix  : prefix (default is 64)
#      route   : Router advertisement address (boolean,default is disabled)
#      mtu     : MTU of the vmknic to be created.
#
# Results:
#      "SUCCESS", if vmknic gets created.
#      "FAILURE", in case of any error while creating vmknic,
#
# Side effects:
#      vmknic gets attached to the specified dvport(dvportgroup).
#
########################################################################

sub AddVMKNIC
{
   my $self = shift;
   my %args = @_;
   my $host = $args{HOST};
   my $ip = $args{IP};
   my $netmask = $args{NETMASK};
   my $prefix = $args{PREFIX};
   my $route = $args{ROUTE};
   my $mtu = $args{MTU};
   my $tag = "DVPortGroup : AddVMKNIC : ";
   my $vds = $self->{switchObj}->{switch};
   my $dvPg = $self->{DVPGName};
   my $proxy = $self->{switchObj}->{vcObj}->{proxy};
   my $dcName = $self->{switchObj}->{datacenter};
   my $result;
   my $anchor;
   my $cmd;

   if (not defined $host) {
      $vdLogger->Error("Host to which vmknic is to be attached is not ".
                       "defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($ip !~ m/dhcp/i) {
      if ((not defined $prefix) || (not defined $netmask)) {
         $vdLogger->Error("Either netmask or prefix length must ".
                          "be defined when ip address is not DHCP");
         VDSetLastError("ENOTDEF");
         return FAILURE;
       }
   }

   $anchor = $self->{switchObj}->GetAnchor(SERVICE => "host");
   if ($anchor eq FAILURE) {
      $vdLogger->Error("$tag Failed to create/get the anchor");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # command to add vmknic to dvs.
   $cmd = "addvmknictodvs anchor $anchor host $host dvsname $vds ".
          " DVPORTGROUPNAME $dvPg ";

   if ($ip =~ m/dhcp/i) {
      $cmd = "$cmd setdhcp ";
   } else {
      $cmd = "$cmd ip $ip ";
   }
   if (defined $prefix) {
      $cmd = "$cmd prefixlen $prefix ";
   } elsif(defined $netmask) {
      $cmd = "$cmd netmask $netmask ";
   }
   if (defined $route) {
      $cmd = "$cmd route true ";
   }
   if (defined $mtu) {
      $cmd = "$cmd mtu $mtu ";
   }
   if (defined $dcName) {
      $cmd = "$cmd dcname $dcName ";
   }

   # running command to create vmkernel nic.
   $vdLogger->Debug("running command to create vmknic $cmd");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to create vmknic to $dvPg ".
                       "for host $host as part of vDS $vds");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Info("Created vmknic in host $host to portgroup ".
                   " $dvPg for vds $vds");
   return SUCCESS;
}


################################################################################
# SetForgedTransmit(%args)
#  This method sets the Forged transmit policy for the dvportgroup.
#
# Input:
#  A Named parameter hash having following keys.
#     ENABLE : Flag to indicate the enable disable the forged transmit.
#
# Results
# Returns SUCCESS if the forged transmit is set for the dvportgroup.
# Returns FAILURE otherwise.
#
# Side effects:
# the forged trasmit policy gets set.
#
# note
# None
#
#################################################################################

sub SetForgedTransmit
{
   my $self = shift;
   my %args = @_;
   my $enable = $args{ENABLE} || "Y";
   my $dvPg = $self->{DVPGName};
   my $tag = "DVPortGroup : SetForgedTransmit : ";
   my $vds = $self->{switchObj}->{switch};
   my $proxy = $self->{switchObj}->{vcObj}->{proxy};
   my $dcName = $self->{switchObj}->{datacenter};
   my $result;
   my $anchor;
   my $cmd;

   if ( $enable !~/Y|N/i) {
      $vdLogger->Error("$tag Invalid value for flag");
      VDSetLastError("ENOTDEF");
   }

   $anchor = $self->{switchObj}->GetAnchor(SERVICE => "host");
   if ($anchor eq FAILURE) {
      $vdLogger->Error("$tag Failed to create/get the anchor");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   # command to change the forged transmit policy.
   $cmd = "editdvssecuritypolicy anchor $anchor dvsname $vds ".
          "portgroup $dvPg allowforgetransmit $enable ";
   if (defined $dcName) {
      $cmd = "$cmd  dcname $dcName";
   }

   # run the command to add the port to dvportgroup.
   $vdLogger->Debug("running dvs security command $cmd");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to set forged transmit for $dvPg ".
                       "for vDS $self->{switch}");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
# SetMACAddressChange(%args)
#  This method sets the MAC Address Change policy for the dvportgroup.
#
# Input:
#  A Named parameter hash having following keys.
#     ENABLE : Flag to indicate the enable disable the mac address change
#              policy.
#
# Results
# Returns SUCCESS if mac address change is set for the dvportgroup.
# Returns FAILURE otherwise.
#
# Side effects:
# the mac address change gets modified for the dvportgroup.
#
# note
# None
#
#################################################################################

sub SetMACAddressChange
{
   my $self = shift;
   my %args = @_;
   my $enable = $args{ENABLE} || "Y";
   my $dvPg = $self->{DVPGName};
   my $tag = "DVPortGroup : SetMACAddressChange : ";
   my $vds = $self->{switchObj}->{switch};
   my $proxy = $self->{switchObj}->{vcObj}->{proxy};
   my $dcName = $self->{switchObj}->{datacenter};
   my $result;
   my $anchor;
   my $cmd;

   if ( $enable !~/Y|N/i) {
      $vdLogger->Error("$tag Invalid value for flag");
      VDSetLastError("ENOTDEF");
   }

   $anchor = $self->{switchObj}->GetAnchor(SERVICE => "host");
   if ($anchor eq FAILURE) {
      $vdLogger->Error("$tag Failed to create/get the anchor");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   # command to change the forged transmit policy.
   $cmd = "editdvssecuritypolicy anchor $anchor dvsname $vds ".
          "portgroup $dvPg allowmacaddchange $enable ";
   if (defined $dcName) {
      $cmd = "$cmd  dcname $dcName";
   }

   # run the command to add the port to dvportgroup.
   $vdLogger->Debug("running dvs security command $cmd");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to set mac address change for ".
                       "$dvPg for vDS $self->{switch}");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
# SetPromiscusous(%args)
#  This method sets the promiscusous policy for the dvportgroup.
#
# Input:
#  A Named parameter hash having following keys.
#     ENABLE : Flag to indicate the enable disable the promiscuous mode for
#              the dvportgroup.
#
# Results
# Returns SUCCESS if promiscuous policy is set for the dvportgroup.
# Returns FAILURE otherwise.
#
# Side effects:
# the promiscuous mode policy gets modified for the dvportgroup.
#
# note
# None
#
#################################################################################

sub SetPromiscuous
{
   my $self = shift;
   my %args = @_;
   my $enable = $args{ENABLE} || "N";
   my $dvPg = $self->{DVPGName};
   my $tag = "DVPortGroup : SetPromiscuous : ";
   my $vds = $self->{switchObj}->{switch};
   my $proxy = $self->{switchObj}->{vcObj}->{proxy};
   my $dcName = $self->{switchObj}->{datacenter};
   my $result;
   my $anchor;
   my $cmd;

   if ( $enable !~ /Y|N/i) {
      $vdLogger->Error("$tag Invalid value for flag");
      VDSetLastError("ENOTDEF");
   }

   $anchor = $self->{switchObj}->GetAnchor(SERVICE => "host");
   if ($anchor eq FAILURE) {
      $vdLogger->Error("$tag Failed to create/get the anchor");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   # command to change the promiscuous policy.
   $cmd = "editdvssecuritypolicy anchor $anchor dvsname $vds ".
          "portgroup $dvPg allowprom $enable ";
   if (defined $dcName) {
      $cmd = "$cmd  dcname $dcName";
   }

   # run the command to add the port to dvportgroup.
   $vdLogger->Debug("running dvs security command $cmd");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to set promiscuous policy for $dvPg ".
                       "for vDS $self->{switch}");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
# SetAccessVLAN(%args)
#  This method sets the promiscusous policy for the dvportgroup.
#
# Input:
#  A Named parameter hash having following keys.
#     VLAN : Access vlan id to be set for the dvportgroup.
#
# Results
# Returns SUCCESS if the vlan id gets set for the dvportgroup in access mode.
# Returns FAILURE otherwise.
#
# Side effects:
# the vlan id gets set for the dvs portgroup.
#
# note
# None
#
#################################################################################

sub SetAccessVLAN
{
   my $self = shift;
   my %args = @_;
   my $vlan = $args{VLAN};
   my $dvPg = $self->{DVPGName};
   my $tag = "DVPortGroup : SetAccessVLAN : ";
   my $vds = $self->{switchObj}->{switch};
   my $proxy = $self->{switchObj}->{vcObj}->{proxy};
   my $dcName = $self->{switchObj}->{datacenter};
   my $result;
   my $anchor;
   my $cmd;

   if (not defined $vlan) {
      $vdLogger->Error("$tag Access VLAN ID not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $anchor = $self->{switchObj}->GetAnchor(SERVICE => "host");
   if ($anchor eq FAILURE) {
      $vdLogger->Error("$tag Failed to create/get the anchor");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   # command to set the access vlan id.
   $cmd = "editdvsvlanpolicy anchor $anchor dvsname $vds ".
          "vlanid $vlan portgroup $dvPg ";
   if (defined $dcName) {
      $cmd = "$cmd  dcname $dcName";
   }

   # run the command to set the access vlan id.
   $vdLogger->Debug("setting access vlan on $dvPg with $cmd");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to access vlan id $vlan for $dvPg ".
                       "for vDS $self->{switch}");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
# SetVLANTrunking(%args)
#  This method sets the portgroup into vlan trunking mode.
#
# Input:
#  A Named parameter hash having following keys.
#     RANGE : Range to be created, for now it can have single range since
#             hyphen (-) in workload hash has different meaning.
#
# Result:
# Returns SUCCESS if the dvportgroup gets set in trunk mode.
# Returns FAILURE otherwise.
#
# Side effects:
# dvportgroup gets set in vlan trunk mode.
#
# note
# None
#
#################################################################################

sub SetVLANTrunking
{
   my $self = shift;
   my %args = @_;
   my $range = $args{RANGE};
   my $dvPg = $self->{DVPGName};
   my $tag = "DVPortGroup : SetVLANTrunking : ";
   my $vds = $self->{switchObj}->{switch};
   my $proxy = $self->{switchObj}->{vcObj}->{proxy};
   my $dcName = $self->{switchObj}->{datacenter};
   my $result;
   my $anchor;
   my $cmd;

   if ( not defined $range) {
      $vdLogger->Error("$tag Trunk VLAN range not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $anchor = $self->{switchObj}->GetAnchor(SERVICE => "host");
   if ($anchor eq FAILURE) {
      $vdLogger->Error("$tag Failed to create/get the anchor");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   # command to set the access vlan id.
   $cmd = "editdvsvlanpolicy anchor $anchor dvsname $vds ".
          "vlantrunking $range portgroup $dvPg";
   if (defined $dcName) {
      $cmd = "$cmd  dcname $dcName";
   }

   # run the command to set the trunk range for the portgroup.
   $vdLogger->Debug("setting dvs trunk range $cmd");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to set the trunk range $range ".
                       "for $dvPg for vDS $self->{switch}");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
# EnableShaping (%args)
#  This method enables the traffic shaping for the vds, it can enable IN
#  shaping and OUT shaping.
#
# Input:
#  A Named parameter hash having following keys.
#      AVGBANDWIDTH : parameter to specify the Average Bandwidth in KBytes/sec.
#      PEAKBANDWIDTH : parameter to specify the peak bandwidth in KBytes/sec.
#      BURSTSIZE : parameter to specify the burst size.
#      TYPE : Specifies the type of the shaping to be disabled,
#             it could either be INBOUND or OUTBOUND.
#
# Results
# Returns SUCCESS if the traffic shaping gets enabled for the dvportgroup.
# Returns FAILURE otherwise.
#
# Side effects:
# the shaping gets enabled for the dvportgroup.
#
# note
# None
#
#################################################################################

sub EnableShaping
{
   my $self = shift;
   my %args = @_;
   my $avgBW = $args{AVGBANDWIDTH};
   my $peakBW = $args{PEAKBANDWIDTH};
   my $burstSize = $args{BURSTSIZE};
   my $type = $args{TYPE} || "INBOUND";
   my $tag = "DVPortGroup : EnableShaping : ";
   my $vds = $self->{switchObj}->{switch};
   my $proxy = $self->{switchObj}->{vcObj}->{proxy};
   my $dcName = $self->{switchObj}->{datacenter};
   my $dvPg = $self->{DVPGName};
   my $result;
   my $anchor;
   my $cmd;

   if ( not defined $avgBW || not defined $peakBW ||
        not defined $burstSize) {
      $vdLogger->Error("$tag Shaping parameters not defined");
      VDSetLastError("ENOTDEF");
   }

   $anchor = $self->{switchObj}->GetAnchor(SERVICE => "host");
   if ($anchor eq FAILURE) {
      $vdLogger->Error("$tag Failed to create/get the anchor");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # command to set shaping paramters.
   $cmd = "editdvstrafficshaping anchor $anchor dvsname $vds ".
          "policytype $type enable Y portgroup $dvPg ".
          "avgbandwidth $avgBW peakbandwidth $peakBW ".
          "burstsize $burstSize ";
   if (defined $dcName) {
      $cmd = "$cmd  dcname $dcName";
   }

   # run the command to set the trunk range for the portgroup.
   $vdLogger->Debug("enabling $type shaping with parameters $cmd");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to set shaping parameters ".
                       "for $dvPg for vDS $self->{pgName}");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
# DisableShaping (%args)
#  This method disables the traffic shaping for the vds,
#
# Input:
#  A Named parameter hash having following keys.
#     TYPE : Specifies the type of the shaping to be disabled, it could either
#            be INBOUND or OUTBOUND.
#
# Results
# Returns SUCCESS if the traffic shaping gets disabled for the dvportgroup.
# Returns FAILURE otherwise.
#
# Side effects:
# the shaping gets enabled for the dvportgroup.
#
# note
# None
#
#################################################################################

sub DisableShaping
{
   my $self = shift;
   my %args = @_;
   my $type = $args{TYPE} || "INBOUND";
   my $tag = "DVPortGroup : DisableShaping : ";
   my $vds = $self->{switchObj}->{switch};
   my $proxy = $self->{switchObj}->{vcObj}->{proxy};
   my $dcName = $self->{switchObj}->{datacenter};
   my $dvPg = $self->{DVPGName};
   my $result;
   my $anchor;
   my $cmd;

   $anchor = $self->{switchObj}->GetAnchor(SERVICE => "host");
   if ($anchor eq FAILURE) {
      $vdLogger->Error("$tag Failed to create/get the anchor");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # command to set shaping paramters.
   $cmd = "editdvstrafficshaping anchor $anchor dvsname $vds ".
          "policytype $type enable N portgroup $dvPg ";
   if (defined $dcName) {
      $cmd = "$cmd  dcname $dcName";
   }

   # run the command to disable the shaping.
   $vdLogger->Debug("disabling $type shaping with parameters $cmd");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to disable shaping ".
                       "for $dvPg for vDS $self->{switch}");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}

################################################################################
# SetTeaming (%args)
#  This method configures the nic teaming policies for the dvs portgroup.
#
# Input:
#  A Named parameter hash having following keys.
#     FAILOVER : Specifies the failover detection policy, valid values
#                are BEACONPROBING and LINKSTATUSONLY.
#     NOTIFYSWITCH : parameter to specify the notify switch, valid
#                      values are  Y, N.
#     FAILBACK : parameter to specify the failback setting (boolean).
#     LBPOLICY : parameter to specify the load balancing policy.
#                 valid values are loadbalance_ip, loadbalance_srcmac,
#                 loadbalance_srcid, loadbalance_loadbased,
#                 failover_explicit.
#     STANDBYNICS : Parameter to specify the standby nics.
#
#
# Results
# Returns SUCCESS if nic teaming gets configured successfully for the
#                 dvportgroup.
# Returns FAILURE otherwise.
#
# Side effects:
# teaming configurations gets changed for the dvportgroup.
#
# note
# None
#
#################################################################################

sub SetTeaming
{
   my $self = shift;
   my %args = @_;
   my $tag = "DVPortGroup : SetTeaming : ";
   my $failover = $args{FAILOVER} || "linkstatusonly";
   my $notifySwitch = $args{NOTIFYSWITCH} || undef;
   my $failback = $args{FAILBACK} || undef;
   my $lbPolicy = $args{LBPOLICY} || undef;
   my $standbyNICs = $args{STANDBYNICS} || undef;
   my $vds = $self->{switchObj}->{switch};
   my $proxy = $self->{switchObj}->{vcObj}->{proxy};
   my $dcName = $self->{switchObj}->{datacenter};
   my $dvPg = $self->{DVPGName};
   my $validPolicy = "loadbalance_ip|loadbalance_srcmac|loadbalance_srcid|".
                     "failover_explicit|loadbalance_loadbased";
   my $result;
   my $anchor;
   my $cmd;

   #
   # check the values for failover detection.
   #
   if ($failover !~ m/beaconprobing|linkstatusonly/i) {
      $vdLogger->Error("$tag $failover is not valid parameter");
      VDSetLastError("EINVALID");
      return SUCCESS;
   }

   $anchor = $self->{switchObj}->GetAnchor(SERVICE => "setup");
   if ($anchor eq FAILURE) {
      $vdLogger->Error("$tag Failed to create/get the anchor");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # command to set the nic teaming.
   $cmd = "configdvpgnicteaming anchor $anchor dvsname $vds ".
          "dvportgroupname $dvPg failoverdetection $failover ";
   if (defined $notifySwitch) {
      $notifySwitch = ($notifySwitch =~ /true|yes/i) ? "Y" : "N";
      if($notifySwitch !~ m/Y|N/i) {
         $vdLogger->Error("$tag $notifySwitch is not a valid ".
                          "for notify switch");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $cmd = "$cmd notifyswitches $notifySwitch ";
   }
   if (defined $failback) {
      $failback = ($failback =~ /true|yes/i) ? "true" : "false";
      if ($failback !~ m/true|false/i) {
         $vdLogger->Error("$tag $failback is not value ".
                          "for failback");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $cmd = "$cmd failback $failback ";
   }
   if (defined $lbPolicy) {
      if ($lbPolicy =~ /portid/i) {
         $lbPolicy = "loadbalance_srcid";
      } elsif ($lbPolicy =~ /iphash/i) {
         $lbPolicy = "loadbalance_ip";
      } elsif ($lbPolicy =~ /mac/i) {
         $lbPolicy = "loadbalance_srcmac";
      } elsif ($lbPolicy =~ /loadbalance_loadbased/i) {
         $lbPolicy = "loadbalance_loadbased";
      } else {
         $lbPolicy = "failover_explicit";
      }

      if ($lbPolicy !~ m/$validPolicy/i) {
         $vdLogger->Error("$tag $lbPolicy is not a valid load".
                          "balancing policy");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $cmd = "$cmd lbpolicy $lbPolicy ";
   }
   if (defined $standbyNICs) {
      $cmd = "$cmd standbynics $standbyNICs ";
   }
   if (defined $dcName) {
      $cmd = "$cmd dcname $dcName ";
   }

   # run command to set the nic teaming policy.
   $vdLogger->Info("setting nic teaming with parameters $cmd");
   $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to set nic teaming ".
                       "for $dvPg for vDS $vds");
      $vdLogger->Debug(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
# SetPVLANType (%args)
#  This method sets the pvlan id for the dvportgroup.
#
# Input:
#  A Named parameter hash having following keys.
#     PVLANID : PVLAN id to be set for the dvportgroup.
#
# Results
# Returns SUCCESS if pvlan type gets set for the dvportgroup.
# Returns FAILURE otherwise.
#
# Side effects:
#  vlan property of the dvportgroup gets set to the pvlan type.
#
# note
# None
#
#################################################################################

sub SetPVLANType
{
   my $self = shift;
   my %args = @_;
   my $pvlan = $args{PVLANID};
   my $tag = "VDSwitch : SetPVLANType : ";
   my $vds = $self->{switchObj}->{switch};
   my $proxy = $self->{switchObj}->{vcObj}->{proxy};
   my $dcName = $self->{switchObj}->{datacenter};
   my $dvPg = $self->{DVPGName};
   my $result;
   my $anchor;
   my $cmd;

   $anchor = $self->{switchObj}->GetAnchor(SERVICE => "host");
   if ($anchor eq FAILURE) {
      $vdLogger->Error("$tag Failed to create/get the anchor");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # command to set the pvlan id for the dvportgroup.
   $cmd = "editdvsvlanpolicy anchor $anchor dvsname $vds ".
          "pvlanid $pvlan portgroup $dvPg ";
   if (defined $dcName) {
      $cmd = "$cmd  dcname $dcName";
   }

   # run the command to set the pvlan for the dvportgroup.
   $vdLogger->Debug("setting dvs pvlan $cmd");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to set the pvlan $pvlan ".
                       "for $dvPg for vDS $self->{switch}");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
# MigrateManagementNetToVDS (%args)
#  This method migrates vmknic from legacy portgroup to vds dvportgroup.
#
# Input:
#  A Named parameter hash having following keys.
#     HOST : Name of the ESX host whose management network is to be migrated.
#     PORTGROUP : Portgroup to which vmknic is connected.
#
# Results
# Returns SUCCESS if management network gets migrated to vds dvportgroup.
# Returns FAILURE otherwise.
#
# Side effects:
#  the mangement network is migrated from legacy portgroup to vds dvportgroup.
#
# note
# None
#
#################################################################################

sub MigrateManagementNetToVDS
{
   my $self = shift;
   my %args = @_;
   my $host = $args{HOST};
   my $portgroup = $args{PORTGROUP};
   my $tag = "DVPortGroup : MigrateManagementNetToVDS : ";
   my $vds = $self->{switchObj}->{switch};
   my $proxy = $self->{switchObj}->{vcObj}->{proxy};
   my $dcName = $self->{switchObj}->{datacenter};
   my $dvPg = $self->{DVPGName};
   my $result;
   my $anchor;
   my $cmd;

   $anchor = $self->{switchObj}->GetAnchor(SERVICE => "host");
   if ($anchor eq FAILURE) {
      $vdLogger->Error("$tag Failed to create/get the anchor");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # command to migrate mgmt network to vds.
   $cmd = "migratemgmtnetworktodvs anchor $anchor ".
          "pghost $host dvsname $vds dvportgroupname $dvPg ".
          "portgroup \"$portgroup\" ";
   if (defined $dcName) {
      $cmd = "$cmd  dcname $dcName";
   }

   # run the command to migrate mgmt network to vds
   $vdLogger->Debug("migrating mgmt network $cmd");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to migrate mgmt network to ".
                       "$dvPg in VDS $self->{switch}");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# SetMonitoring -
#      This method would enable/disable the dvportgroup monitoring
#      for the dvportgroup
#
# Input:
#      dvportgroup name of the dvportgroup.
#
# Results:
#      "SUCCESS", if monitoring is set sucessfully for dvportgroup.
#      "FAILURE", in case of any error,
#
# Side effects:
#      None.
#
########################################################################

sub SetMonitoring
{
   my $self = shift;
   my %args = @_;
   my $enable = $args{ENABLE} || "True";
   my $tag = "VDSwitch : SetMonitoring : ";
   my $vds = $self->{switchObj}->{switch};
   my $proxy = $self->{switchObj}->{vcObj}->{proxy};
   my $dcName = $self->{switchObj}->{datacenter};
   my $dvPg = $self->{DVPGName};
   my $result;
   my $anchor;
   my $cmd;

   if ($enable !~ m/True|False/i) {
      $vdLogger->Error("$tag wrong value passed to set monitoring $enable ".
                       "valid values are True or False");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $anchor = $self->{switchObj}->GetAnchor(SERVICE => "setup");
   if ($anchor eq FAILURE) {
      $vdLogger->Error("$tag Failed to create/get the anchor");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # command to set the pvlan id for the dvportgroup.
   $cmd = "editdvportgroup anchor $anchor dvportgroupname $dvPg ".
          "dvsname $vds setmonitoring $enable ";
   # run the command to set monitoring for the dvportgroup.
   $vdLogger->Debug("setting monitoring $cmd");
   $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to set the monitoring to $enable ".
                       "for $dvPg for vDS $vds");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Debug("Successfully set monitoring to $enable for $dvPg");
   return SUCCESS;
}


########################################################################
#
# GetInlinePortgroupObject --
#     Method to get instance of
#     VDNetLib::InlineJava::Portgroup::DVPortgroup corresponding to this
#     portgroup
#
# Input:
#     None
#
# Results:
#     return value of new() in
#     VDNetLib::InlineJava::Portgroup::DVPortgroup
#
# Side effects:
#     None
#
########################################################################

sub GetInlinePortgroupObject
{
   my $self = shift;
   my $inlineSwitchObj = $self->{switchObj}->GetInlineDVS();
   return VDNetLib::InlineJava::Portgroup::DVPortgroup->new(
                                                'name' => $self->{'DVPGName'},
                                                'switchObj' => $inlineSwitchObj
                                                );
}


########################################################################
#
# SetVLAN--
#     Method to select proper API for setting VLAN on PortGroup
#
# Input:
#    vlantype: access, pvlan, trunk
#
# Results:
#    whatever the methods return
#
# Side effects:
#     None
#
########################################################################

sub SetVLAN
{
   my $self = shift;
   my %args = @_;
   my $vlanType = $args{vlantype};
   #
   # We start following the practise to ask user to specify the type
   # Before we use to do $args{vlantype} || "access" but this is not
   # intuitive for a person referrring TDS to set access vlan
   #
   if (not defined $vlanType) {
      $vdLogger->Error("vlantype not defined in SetVLAN()");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ($vlanType =~ /trunk/) {
      $args{RANGE} = $args{vlan};
      $args{RANGE} =~ s/\[|\]//g;
      return $self->SetVLANTrunking(%args);
   } elsif ($vlanType =~ /pvlan/) {
      $args{PVLANID} = $args{vlan};
      return $self->SetPVLANType(%args);
   } elsif ($vlanType =~ /access/) {
      $args{VLAN} = $args{vlan};
      return $self->SetAccessVLAN(%args);
   } else {
      $vdLogger->Error("unknow VLAN type:$vlanType");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
}


########################################################################
#
# SetFailoverOrder --
#     Method to set DVPG's failover order (active|standby uplinks)
#
# Input:
#     Reference of an array containing
#            refArrayofUplink: lag or uplink array
#            failoverType: active or standby
#
# Results:
#     "SUCCESS",if set vds failover order successfully
#     "FAILURE",in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetFailoverOrder
{
   my $self = shift;
   my $refArrayofUplink = shift;
   my $failoverType = shift;
   my $tag = "DVPortGroup : SetFailoverOrder :";

   if (not defined $refArrayofUplink) {
      $vdLogger->Error("$tag Name of the uplink not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   unless ((defined $failoverType) && ($failoverType =~ /active|standby/i)) {
      $vdLogger->Error("$tag Type of failover (active|standby) not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $inlineDvpgObj = $self->GetInlinePortgroupObject();

   if ((not defined $inlineDvpgObj) || ($inlineDvpgObj == 0)) {
      $vdLogger->Error("GetInlinePortgroupObject failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $result = $inlineDvpgObj->SetFailoverOrder($refArrayofUplink, $failoverType);
   if ((not defined $result) || ($result == 0)) {
      $vdLogger->Error("$tag Failed to set dvpg failover order");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Info("$tag Successfully set failover order for $self->{DVPGName}");
   return SUCCESS;
}

########################################################################
#
# SetLoadBalancing --
#     Method to set DVPG's load balancing policy
#
# Input:
#     policy: load balancing policy
#
# Results:
#     "SUCCESS",if set dvpg load balancing successfully
#     "FAILURE",in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetLoadBalancing
{
   my $self = shift;
   my $policy = shift;
   my $tag = "DVPortGroup : SetLoadBalancing :";

   if (not defined $policy) {
      $vdLogger->Error("$tag Load balancing policy not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $inlineDvpgObj = $self->GetInlinePortgroupObject();

   if ((not defined $inlineDvpgObj) || ($inlineDvpgObj == 0)) {
      $vdLogger->Error("GetInlinePortgroupObject failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $result = $inlineDvpgObj->SetLoadBalancing($policy);
   if ((not defined $result) || ($result == 0)) {
      $vdLogger->Error("$tag Failed to set dvpg load balancing");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Info("$tag Successfully set load balancing for $self->{DVPGName}");
   return SUCCESS;
}


#############################################################################
#
# GetMORId--
#     Method to get the dvportgroup's Managed Object Ref ID.
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
	               "the dvportgroup: $self->{name}");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $vdLogger->Debug("Managed Object Ref ID for the dvportgroup:". $self->{name} .
                    " is MORId:". $dvportgroupMORId);
   return $dvportgroupMORId;
}

sub GetId
{
   my $self   = shift;
   return $self->GetMORId();
}


##################################################################
#
# GetInlineObject --
#      Wrapper method for inlinePortgroup object
#
# Input:
#      None
# Results:
#      return value of new() in
#      VDNetLib::InlineJava::Portgroup::DVportGroup
#
# Side effects:
#      None
#
#########################################################################

sub GetInlineObject
{
  my $self = shift;

  my $result = $self->GetInlinePortgroupObject();
  if (not defined $result) {
      $vdLogger->Error("Not able to create inline DVPortGroup obj");
      VDSetLastError("EFAILED");
      return FAILURE;
  }
  return $result;
}


#######################################################################
#
# AddFilter --
#     This method add filter and Rules on DVPG
#
#
# Input:
#     Array of Filter specs.Each spec may contain one or all of these:
#     filtername
#     rule{
#           srcip           : <192.168.2.1>
#           srcport         : <17000>
#           srcmac          : <00:0c:29:c3:6a:b8>
#           srcipnegation   : <yes/no>
#           srcportnegation : <yes/no>
#           srcmacnegation  : <yes/no>
#           dstip           : <192.168.0.3>
#           dstport         : <17000>
#           dstmac          : <00:0c:29:c8:6a:b4>
#           dstipnegation   : <yes/no>
#           dstportnegation : <yes/no>
#           dstmacnegation  : <yes/no>
#           qostag          : <0-7>
#           dscptag         : <0-63>
#           ruleaction      : <Accept/drop/punt>
#           ruledirection   : <incoming/outgoing/both>
#           vlan            : <0-1045>
#        }
#
# Results:
#     Return array of filter and rule objects ,If SUCCESS
#     "FAILURE", in case of any error,
#
# Side effects:
#     None
#
#########################################################################

sub AddFilter
{
   my $self = shift;
   my $arrayOfSpecs = shift;
   my $refToArrayOfRuleObject;
   my (@arrayOfFilterObjects);

   foreach my $element (@$arrayOfSpecs){
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("Filter spec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my $filterHash = {};
      my %options = %$element;
      my ($filterConfig, $filterObject);

      # 1) Create a vdnet Filter.pm vdnet Object
      # 2) Call AddFilter using Inline Java
      # 3) return the vdnet filter object.
      $options{stafHelper} = $self->{stafHelper};
      $options{dvpgObj} = $self;
      $options{operation} = "add";
      my $dvpginlineObj = $self->GetInlinePortgroupObject();
      if (not defined $dvpginlineObj  || ($dvpginlineObj  eq FAILURE)) {
         $vdLogger->Error("Failed to create InlinePortgroupObject");
         VDSetLastError(VDGetlastError());
         return FAILURE;
      }
      my  $inlinefilterObject = $dvpginlineObj->AddFilter(%options);
      if (not defined $inlinefilterObject) {
         $vdLogger->Error("Not able to create VDNetLib::Filter::Filter obj");
         VDSetLastError("EFAILED");
         return FAILURE;
      }

      $options{filterkey} =  $inlinefilterObject->{'filterkey'};
      $filterObject = VDNetLib::Filter::Filter->new(%options);
      $filterHash->{'object'} =   $filterObject;


     if (defined $options{'rule'}) {
         my $ruleHash = {};
         my $arrayOfRuleSpecs = $options{'rule'};
         $filterObject = VDNetLib::Filter::Filter->new(%options);
         $refToArrayOfRuleObject = $filterObject->AddRule($arrayOfRuleSpecs);
         $filterHash->{'rule'} = $refToArrayOfRuleObject;
      }
     push (@arrayOfFilterObjects, $filterHash);
   }
   $vdLogger->Info("Added filter successfully");
   return \@arrayOfFilterObjects;
}


#######################################################################
#
# DeleteFilter --
#     Method to delete filter
#
#
# Input:
#     Object:filter object to be deleted
#
# Results:
#     return SUCCESS upon deleting filter
#     FAILURE in cae of any error
#
# Side effects:
#     None
#
########################################################################

sub DeleteFilter
{
  my $self = shift;
  my $arrayOfFilterObjects = shift ;

  foreach my $element (@$arrayOfFilterObjects) {
      my %options = %$element;
      my $dvpgObj = $self->GetInlinePortgroupObject();
      $options{switchObj} = $self;
      $options{stafHelper} = $self->{stafHelper};
      $options{dvpgObj} = $self;

      my $dvpginlineObj = $self->GetInlinePortgroupObject();
      if (not defined $dvpginlineObj || ($dvpginlineObj eq FAILURE)) {
         $vdLogger->Error("Failed to create InlinePortgroupObject");
         VDSetLastError(VDGetlastError());
         return FAILURE;
      }
      my $result = $dvpginlineObj->RemoveFilter(%options);

      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to remove filter");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   $vdLogger->Debug("Filter removal operation is successful ".
                               "for dvpg:$self->{DVPGName} ");
   return SUCCESS;
}


######################################################################
#
# ConfigureAdvanced --
#     Method to enable/disable overridePort Polices present in
#     Advanced at dvportgroup
#
#
# Input:
#     arrayOfAdvancedSpecs-Reference to hash of advance config spec
#     Hash of Advanced config spec to be overriden
#    overrideport = {
#                      Trafficfilterandmarking = allowed/disabled
#                   }
#
# Results:
#     return SUCCESS upon Configuring the override policy
#     FAILURE in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ConfigureAdvanced
{
   my $self = shift;
   my $arrayOfAdvancedSpecs = shift ;
   my %options = %$arrayOfAdvancedSpecs;
   my $arrayofinlinespec = $options{'overrideport'};
   my $dvpginlineObj = $self->GetInlinePortgroupObject();
   my $result = $dvpginlineObj->ConfigureAdvanced(%$arrayofinlinespec);

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to configure advanced override port " .
                                           " policies for Portgroup");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# ConfigureLAG
#     Method to configure (enable/disable) LACPv1 LAG on DVPG.
#
# Input:
#     lagoperation - enable or disable (mandatory)
#     lagmode - active or passive (option, default is passive)
#
# Results:
#     "SUCCESS", if configure LACPv1 successfully
#     "FAILURE", in case of any error
#
# Side effects:
#
########################################################################

sub ConfigureLAG
{
   my $self = shift;
   my $lagoperation = shift;
   my $lagmode = shift || "passive";

   if (not defined $lagoperation) {
      $vdLogger->Error("lag operation (enable or disable) missing");
      return FAILURE;
   }

   if ($lagoperation !~ /(enable|disable)/) {
      $vdLogger->Error("Unsupported lagoperation");
      return FAILURE;
   }

   my $inlineDvpgObj = $self->GetInlinePortgroupObject();

   if ((not defined $inlineDvpgObj) || ($inlineDvpgObj == 0)) {
      $vdLogger->Error("GetInlinePortgroupObject failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $result = $inlineDvpgObj->ConfigureLAG($lagoperation, $lagmode);
   if ((not defined $result) || ($result == 0)) {
      $vdLogger->Error("Failed to $lagoperation LACPv1 on $self->{DVPGName}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Info("Successfully $lagoperation LACPv1 on $self->{DVPGName}");
   return SUCCESS;
}


########################################################################
#
# ConfigureIpfix
#     Method to configure (enable/disable) Ipfix on DVPG.
#
# Input:
#     ipfixoperation - enable or disable (mandatory)
#
# Results:
#     "SUCCESS", if configure Ipfix successfully
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ConfigureIpfix
{
   my $self = shift;
   my $ipfixoperation = shift;

   if (not defined $ipfixoperation) {
      $vdLogger->Error("Ipfix operation (enable or disable) missing");
      return FAILURE;
   }

   if ($ipfixoperation !~ /(enable|disable)/) {
      $vdLogger->Error("Unsupported ipfixoperation");
      return FAILURE;
   }

   my $inlineDvpgObj = $self->GetInlinePortgroupObject();

   if ((not defined $inlineDvpgObj) || ($inlineDvpgObj == 0)) {
      $vdLogger->Error("GetInlinePortgroupObject failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $result = $inlineDvpgObj->ConfigureIpfix($ipfixoperation);
   if ((not defined $result) || ($result == 0)) {
      $vdLogger->Error("Failed to $ipfixoperation Ipfix on $self->{DVPGName}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Info("Successfully $ipfixoperation Ipfix on $self->{DVPGName}");
   return SUCCESS;
}


1;
