#####################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
#######################################################################

package VDNetLib::Switch::VDSwitch::VDSwitch;

#
# This package is responsible for handling all the interaction with
# VMware vNetwork Distributed Switch.
#

use strict;
use warnings;

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::Utilities;
use VDNetLib::DVFilter::DVFilter;
use VDNetLib::Switch::VDSwitch::DVPortGroup;
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError );
use VDNetLib::InlineJava::DVS;
use VDNetLib::InlineJava::DVSManager;
use VDNetLib::InlineJava::Portgroup::DVPortgroup;
use Data::Dumper;
use VDNetLib::InlineJava::InlineLAG;
use VDNetLib::Host::HostFactory;
use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJava CreateInlineObject
                                         InlineExceptionHandler ConfigureLogger
                                         StopInlineJVM NewArrayList);
# Inherit the parent class.
use base qw(VDNetLib::Switch::Switch);

# Add JAVA_OPTIONS for PortMirror Java tools after migrate JAX-WS
use constant JAVA_OPTIONS => "-Xmx512m -XX:MaxPermSize=256m -XX:PermSize=256m " .
                             "-XX:+UseConcMarkSweepGC -DUSESSL=true";
use constant ESXCLI_LACP => "esxcli network vswitch dvs vmware lacp";
use constant NET_DVS => "net-dvs";
use constant TRUE => 1;
use constant FALSE => 0;


########################################################################
#
# new --
#      This is the entry point to VDNetLib::Switch::VDSwitch::VDSwitch
#      package.
#      This method created an object of this class.
#
# Input --
#  A named parameter hash with following keys:
#  switch: Name of the vDS (required).
#  vcObj: Reference to the VC object (required).
#  datacenter: Name of the datacenter(required).
#  stafHelper: reference to the staf helper object.
#
# Results:
#      None
#
# Side effects:
#      None
#
########################################################################

sub new
{
   my $class = shift;
   my %args = @_;
   my $self;
   my $result;

   $self->{switch} = $args{switch};
   $self->{vcObj} = $args{vcObj};
   $self->{stafHelper} = $args{stafHelper};
   $self->{datacenter} = $args{datacenter};
   $self->{'switchType'} = "vdswitch";
   $self->{DVPortGroup}  = undef;
   $self->{inlineDVS}    = undef;
   $self->{inlineDVSMgr} = undef;

   if (not defined $self->{switch}) {
      $vdLogger->Error("VDSwitch : switch name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $self->{vcObj}) {
      $vdLogger->Error("VDSwitch : vc object not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $self->{datacenter}) {
      $vdLogger->Error("VDSwitch : datacenter name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   bless ($self,$class);

   #
   # Create a VDNetLib::STAFHelper object with default options
   # if reference to this object is not provided in the input parameters.
   #
   if (not defined $self->{stafHelper}) {
      my $options;
      $options->{logObj} = $vdLogger;
      my $temp = VDNetLib::Common::STAFHelper->new($options);
      if (not defined $temp) {
         $vdLogger->Error("Failed to create VDNetLib::STAFHelper object");
         VDSetLastError("ETAF");
         return FAILURE;
      }
      $self->{stafHelper} = $temp;
   }

   $self->{inlineDVS} = $self->GetInlineDVS();

   if (!$self->{inlineDVS}) {
      $vdLogger->Error("Failed to create VDNetLib::InlineJava::DVS object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $self->{inlineDVSMgr} = $self->GetInlineDVSManager();

   if (!$self->{inlineDVSMgr}) {
      $vdLogger->Error("Failed to create VDNetLib::InlineJava::DVSManager object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   return $self;
}

###############################################################################
#
# Attach --
#      This method attaches a dvportgroup object to the vds object.
#
# Input:
#    key: A string identifying the object, eg vds-switch.
#    value: A reference to the object to be added
#
# Results:
#      Returns "SUCCESS",on success.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub Attach
{
   return SUCCESS;
   my $self = shift;
   my %arg = @_;
   my $key = $arg{key};
   my $value = $arg{value} || undef;

   if (not defined $key) {
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (defined $value) {
      if ($value =~ m/VDNetLib::Switch::VDSwitch::DVPortGroup/) {
         ${ $self->{ DVPortGroup }}{ $key } = $value;
         $vdLogger->Debug("DVPortgroup Attached to the vDS");
         return SUCCESS;
      } else {
        #
        # do nothing,return FAILURE since at this point only
        # dvportgroup can be attached to vDS. Modify this
        # if more objects need to attached.
        #
        return FAILURE;
     }
   }

   # check for the value and return.
   if ( exists ${ $self->{ DVPortGroup } }{ $key } ) {
      return ${ $self->{ DVPortGroup } }{ $key };
   } else {
      $vdLogger->Error("Key Not Found ($key)");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}

###############################################################################
#
# Detach --
#      This method detaches a dvportgroup object to the vds object.
#
# Input:
#    key: A string identifying the object, eg vds-switch.
#    value: A reference to the object to be added
#
# Results:
#      Returns "SUCCESS",on success.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

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
      if($value =~ m/VDNetLib::Switch::VDSwitch::DVPortGroup/) {
         delete ${ $self->{ DVPortGroup } }{ $key };
         if ( ! exists ${ $self->{ DVPortGroup } }{ $key } ) {
            return SUCCESS;
         }
      }
  } else {
      # if only $key is specified.
      if ( exists ${ $self->{ DVPortGroup } }{ $key } ) {
         delete ${ $self->{ DVPortGroup} }{ $key };
         return SUCCESS;
      }
  }
  return FAILURE;
}

########################################################################
#
# DVPortGroupExists
#      This method checks for the esxistence of dvportgroup.
#
#
# Input:
#      DVPORTGROUP : Name of the dvportgroup.
#
# Results:
#      "SUCCESS", if portgroup exists,
#      "FAILURE", in case of any of error,
#
# Side effects:
#      none
########################################################################

sub DVPortGroupExists
{
   my $self = shift;
   my %args = @_;
   my $dvportgroup = $args{DVPG};
   my $tag = "VDSwitch : DVPortGroupExists : ";
   my $anchor = undef;
   my $cmd = undef;
   my $dcName = $self->{datacenter};
   my $proxy = $self->{vcObj}->{proxy};
   my $result;
   my $match = "DVPortgroup Was Not Found";
   my $expectedRC = 8020;

   if (not defined $dvportgroup) {
      $vdLogger->Error("$tag Name of the dvportgroup ".
                       "NOT DEFINED");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Get the anchor
   $anchor = $self->GetAnchor(SERVICE => "setup");
   if ($anchor eq FAILURE) {
      return FAILURE;
   }

   #
   # command to check the existence of dvportgroup.
   #
   $cmd = "dvportgroupexists $dvportgroup anchor $anchor ".
          "dvsname $self->{switch}";
   if (defined $dcName) {
      $cmd = $cmd . " " ." dcname $dcName";
   }
   $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy, $cmd);
   if ($result->{rc} eq $expectedRC) {
      return FAILURE;
   } else {
      return SUCCESS;
   }
}

########################################################################
#
# CreateDVPortgroup
#      This method creates the dv portgroup for the vds.
#
#
# Input:
#      DVPORTGROUP : Name of the dvportgroup.if specifies pg11-15 it would
#                    create 5 dvportgroups - pg11,pg12, pg13, pg14, pg15.
#
# Results:
#      "SUCCESS", if switch port gets disabled
#      "FAILURE", in case of any error,
#
# Side effects:
#      the dv portgroup gets created for the vds.
#########################################################################

sub CreateDVPortgroup
{
   my $self = shift;
   my %args = @_;
   my $dvportgroup = $args{DVPORTGROUP};
   my $nrp         = $args{NRP};
   my $ports       = $args{PORTS};
   my $pgType = $args{PGTYPE} || "earlyBinding";
   my $tag = "VDSwitch : CreateDVPortgroup :";
   my $anchor = undef;
   my $cmd = undef;
   my $dcName = $self->{datacenter};
   my $proxy = $self->{vcObj}->{proxy};
   my $dvPortgroupObj;
   my $result;
   my @dvpgs;

   if (not defined $dvportgroup) {
      $vdLogger->Error("$tag Name of the dvportgroup ".
                       "NOT DEFINED");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Get the anchor
   $anchor = $self->GetAnchor(SERVICE => "setup");
   if ($anchor eq FAILURE) {
      return FAILURE;
   }

   #
   # In case the dvportgroup name was given as "pg23-100"
   # Add support for creating a bunch of dvpgs in a single workload.
   #

   if ($dvportgroup =~ m/^([^\-]+[a-zA-Z])(\d+)-(\d+)$/) {
      for (my $i=$2; $i<=$3; $i++) {
         push(@dvpgs,$1.$i);
      }
   } else {
      push(@dvpgs,$dvportgroup);
   }

   my $inlineVCSession = $self->{vcObj}->GetInlineVCSession();
   $result = $inlineVCSession->LoginVC();
   if (!$result) {
      $vdLogger->Error("Failed to login VC $self->{vcObj}->{vcaddr}");
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   my $inlineDVS  = $self->GetInlineDVS();
   $result = $inlineDVS->AddPG(
                         DVPGTYPE =>$pgType,
                         DVPGNAMES =>\@dvpgs,
                         PORTS     =>$ports);

   if (!$result) {
      $vdLogger->Error("Failed to create dvportgroup for vDS $self->{switch}");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $vdLogger->Info("Created dvportgroup for vDS $self->{switch}");

   # create dvportgroup object.
   for (my $i = 0; $i < scalar(@dvpgs); $i++) {
      my $dvpg = $dvpgs[$i];
      $dvPortgroupObj = new VDNetLib::Switch::VDSwitch::DVPortGroup(
                                                        DVPGName => $dvpg,
                                                        switchObj => $self,
                                                        stafHelper => $self->{stafHelper}
                                                        #TODO: Pass inline PGObj/pgMor
                                                        );
      if ($dvPortgroupObj eq FAILURE) {
         $vdLogger->Error("$tag Failed to create dv portgroup object");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      if (defined $nrp){
         $cmd = "editdvportgroup anchor $anchor dvportgroupname $dvpg".
                " dvsname $self->{switch} setnwrespool $nrp";
         $vdLogger->Info("Run STAF command : $cmd");
         $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy, $cmd);
         if ($result->{rc} != 0) {
            $vdLogger->Error("$tag Failed to attach portgroup $dvpg ".
                          "with nrp $nrp");
            $vdLogger->Error(Dumper($result));
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
         $vdLogger->Info("Attached DVPG($dvpg) with NRP ($nrp)");
      }
   }

   return SUCCESS;
}


########################################################################
#
# DeleteDVPortgroup
#      This method deletes the dv portgroup for the vds.
#
#
# Input:
#      arrayOfDVPG : array of dvpg name to be deleted.
#
# Results:
#      "SUCCESS", if dvportgroup is deleted successfully
#      "FAILURE", in case of any error,
#
# Side effects:
#      the dv portgroup gets created for the vds.
########################################################################

sub DeleteDVPortgroup
{
   my $self = shift;
   my $arrayOfDVPG = shift;

   my $tag = "VDSwitch : DeleteDVPortgroup :";
   my $anchor = undef;
   my $cmd = undef;
   my $dcName = $self->{datacenter};
   my $proxy = $self->{vcObj}->{proxy};
   my $vds = $self->{switch};
   if (not defined $vds) {
      $vdLogger->Error("DVS name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined @$arrayOfDVPG || ((scalar @$arrayOfDVPG) == 0 )) {
      $vdLogger->Error("array of dvpg name not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $result;

   # Get the anchor
   $anchor = $self->GetAnchor(SERVICE => "setup");
   if ($anchor eq FAILURE) {
      return FAILURE;
   }

   foreach my $dvportgroup (@$arrayOfDVPG) {
      # command to remove dvportgroup.
      $cmd = "rmdvpg dvportgroupname $dvportgroup anchor $anchor dvsname $vds ";
      if (defined $dcName) {
         $cmd = $cmd . "dcname $dcName";
      }
      $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy, $cmd);
      if ($result->{rc} != 0) {
         $vdLogger->Error("$tag Failed to delete dvportgroup $dvportgroup".
                          "for vDS $self->{switch}");
         $vdLogger->Error(Dumper($result));
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# UpgradeVDSVersion
#      This method upgrades the vds version.
#
# Input: A Named parameter containing following keys.
#     version : the new version of the vds upgrade to be upgraded.
#
# Results:
#      "SUCCESS", if vds upgrade works fine
#      "FAILURE", in case of any error,
#
# Side effects:
#      the version of the vds gets updated to the one specified.
#
########################################################################

sub UpgradeVDSVersion
{
   my $self = shift;
   my %args = @_;
   my $version = $args{VERSION};
   my $tag = "VDSwitch : UpgradeVDSVersion :";
   my $result;

   if (not defined $version) {
      $vdLogger->Error("$tag vDS version not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($version !~ m/4.1.0|5.0.0|5.1.0|5.5.0/i) {
      $vdLogger->Debug("Warning: $tag Invalid vDS version $version specified." .
                       " Only supported values are: 4.1.0/5.0.0/5.1.0/5.5.0");
   }

   my $inlineDVS  = $self->GetInlineDVS();
   if (!$inlineDVS) {
      $vdLogger->Error("$tag Failed to get VDNetLib::InlineJava::DVS object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   $result = $inlineDVS->UpgradeVDSVersion(version => $version);
   if (!$result) {
      $vdLogger->Error("$tag Failed to upgrade vDS " .
                       "$self->{switch} version to $version");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# RemoveVMKNIC
#     This method removes the vmknic.
#
#
# Input:
#      IP : IP address of the vmknic to be removed.
#      device id : Device id of the vmknic to be removed.
#
# Results:
#      "SUCCESS", if vmknic gets deleted.
#      "FAILURE", in case of any error while deleting vmknic.
#
# Side effects:
#      vmknic gets removed from the specified dvs
#
# Note:
#   This methods currently removes the vmknic from vds.
#
########################################################################

sub RemoveVMKNIC
{
   my $self = shift;
   my %args = @_;
   my $host = $args{HOST};
   my $ip = $args{IP};
   my $deviceID = $args{DEVICEID};
   my $tag = "VDSwitch : RemoveVMKNIC : ";
   my $anchor = undef;
   my $cmd = undef;
   my $dcName = $self->{datacenter};
   my $proxy = $self->{vcObj}->{proxy};
   my $vds = $self->{switch};
   my $result;

   # error checking goes here.
   if (not defined $host) {
      $vdLogger->Error("Host name/ip not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $deviceID) {
      $vdLogger->Error("Either device id or ip address of vmknic ".
                       "should be defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Get the anchor
   $anchor = $self->GetAnchor(SERVICE => "host");
   if ($anchor eq FAILURE) {
      return FAILURE;
   }

   $cmd = "rmvmknic anchor $anchor host $host ";
   if (defined $deviceID) {
      $cmd = "$cmd deviceID $deviceID";
   } else {
      $cmd = "$cmd ip $ip";
   }
   # running command to create vmkernel nic.
   $vdLogger->Debug("running command to remove  vmknic $cmd");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to remove vmknic from host $host ".
                       " connected to vDS $self->{switch}");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Info("Removed vmknic from host $host for ".
                   "vds $self->{switch}");
   return SUCCESS;
}


########################################################################
#
# SetVDSMTU
#      This method sets the mtu for the VDS.
#
#
# Input:
#      MTU : MTU value to be set for the vDS.
#
# Results:
#      "SUCCESS", if mtu is set for the vDS.
#      "FAILURE", in case of any error,
#
# Side effects:
#      the mtu value gets set for the vds.
#
sub SetVDSMTU
{
   my $self = shift;
   my %args = @_;
   my $mtu = $args{MTU};
   my $tag = "VDSwitch : SetMTU :";
   my $anchor = undef;
   my $cmd = undef;
   my $dcName = $self->{datacenter};
   my $proxy = $self->{vcObj}->{proxy};
   my $result;

   if (not defined $mtu) {
      $vdLogger->Error("$tag MTU value not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $anchor = $self->GetAnchor(SERVICE => "setup");
   if ($anchor eq FAILURE) {
      return FAILURE;
   }

   #command to set the mtu.
   $cmd = "setdvsmtu anchor $anchor dvsname $self->{switch} mtu $mtu ";
   if (defined $dcName) {
      $cmd = $cmd . "dcname $dcName";
   }
   $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to set mtu $mtu ".
                       "for vDS $self->{switch}");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}

########################################################################
#
# CreateMirrorSession --
#      This method creates the dvmirror session.
#
# Input:
#     NAME : Name of the mirror session.
#     SRCRXPORT : source output ports.
#     SRCTXPORT : source input ports.
#     DSTUPLINK: Name of uplink port for destination.
#     DESC: Description for the mirror session.
#     DSTPORT: Destination port.
#     STRIPVLAN: Flag for stripping the vlan while mirroring the traffic.
#     ENABLE: Flag whether by default mirror session should be enabled or not.
#     DSTPG: Name of the destination portgroup.
#     LENGTH: Length of the packet to be mirrored at the destination port.
#     SRCRXPG: Source output dvportgroup.
#     SRCTXPG: Source input dvportgroup.
#     TRAFFIC: Flag to specify whether the detination port should be allowed
#              to do the normal traffic or not.
#     ENCAPVLAN: Vlan id which is to be encapsulated while mirroring the traffic.
#     SRCTXWC : Wild card to select the list of source input ports.
#     SRCRXWC: Wild card to select to the list of source output ports.
#     SESSIONTYPE: MN.Next PortMirror has 5 session type:
#                  dvPortMirror, remoteMirrorSource,remoteMirrorDest,
#                  encapsulatedRemoteMirrorSource and mixedDestMirror.
#     VERSION: MN is v1,MN.Next and later is v2.
#     SAMPLINGRATE: one of every n packets is mirrored.
#     SRCVLAN: RSPAN destinaiton session mirrored VLAN ID.
#     ERSPANIP: ESPAN source session defined mirror destination IP address.
#
#
# Results:
#      "SUCCESS", if mirror session is created
#      "FAILURE", in case of any error,
#
# Side effects:
#      None
#
#########################################################################

sub CreateMirrorSession
{
   my $self = shift;
   my $args = shift;
   my $tag = "VDSwitch : CreateMirrorSession: ";

   my $mirrorName = $args->{name} || "Test_Mirror";
   my $srcRxPort = $args->{srcrxport};
   my $srcTxPort = $args->{srctxport};
   my $dstUplink = $args->{dstuplink};
   my $desc = $args->{desc} || "Test_mirror_session";
   my $dstPort = $args->{dstport};
   my $stripVlan = $args->{stripvlan} || "true";
   my $enabled = $args->{enabled} || "true";
   my $dstPG = $args->{dstpg};
   my $mirrorlength = $args->{mirrorlength} || "-1";
   my $srcRxPg = $args->{srcrxpg};
   my $srcTxPg = $args->{srctxpg};
   my $traffic = $args->{normaltraffic} || "false";
   my $encapVlan = $args->{encapvlan};
   my $srcTxWC = $args->{srctxwc};
   my $srcRxWC = $args->{srcrxwc};
   my $sessionType = $args->{sessiontype};
   my $mirrorVersion = $args->{version} || "v1";
   my $samplingRate  = $args->{samplingrate};
   my $erspanIP = $args->{erspanip};
   my $srcVLAN = $args->{srcvlan};
   my $proxy = $self->{vcObj}->{proxy};
   my $vcaddr = $self->{vcObj}->{vcaddr};
   my $vcuser = $self->{vcObj}->{user};
   my $vcpass = $self->{vcObj}->{passwd};
   my $vds = $self->{switch};
   my $dcName = $self->{datacenter};
   my $anchor;
   my $result;
   my $cmd;

   if (defined $srcRxPort) {
      $srcRxPort = join(',', @$srcRxPort);
   }
   if (defined $srcTxPort) {
      $srcTxPort = join(',', @$srcTxPort);
   }
   if (defined $dstPort) {
      $dstPort = join(',', @$dstPort);
   }
   if (defined $dstUplink) {
      $dstUplink = join(',', @$dstUplink);
   }
   if (defined $erspanIP) {
      $erspanIP = join(',', @$erspanIP);
   }

   if ($mirrorVersion !~ m/v1|v2/i) {
      $vdLogger->Error("$tag Failed to create mirror session $mirrorName ".
                          "for vDS $self->{switch} since mirror version is not specified,".
                          "should either be v1 or v2.");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if ($mirrorVersion =~ /v1/i) {
      # Get the anchor
      $anchor = $self->GetAnchor(SERVICE => "setup");
      if ($anchor eq FAILURE) {
         return FAILURE;
      }
      # command to create mirror session.
      $cmd = "adddvsdvmirror anchor $anchor dvsname $vds dvmirrorname ".
             "$mirrorName ";
      if (defined $srcRxPort) {
         $cmd = $cmd . "srcrxport $srcRxPort ";
      }
      if (defined $srcTxPort) {
         $cmd = $cmd . "srctxport $srcTxPort ";
      }

      #
      # add other options while creating a mirror sessoin if specified.
      # If none of the option is specified the mirror session created for
      # vds would be a legacy session i.e. equivalent to promiscusous mode.
      #
      if (defined $dstUplink) {
         $cmd = $cmd . "dstuplink $dstUplink ";
      }
      if (defined $dstPort) {
         $cmd = $cmd . "dstport $dstPort ";
      }
      if (defined $dstPG) {
         $cmd = $cmd . "dstpg $dstPG ";
      }
      if (defined $srcRxPg) {
         $cmd = $cmd . "srcrxpg $srcRxPg ";
      }
      if (defined $srcTxPg) {
         $cmd = $cmd . "srctxpg $srcTxPg ";
      }
      if (defined $encapVlan) {
         $cmd = $cmd . "encapsulationvlanid $encapVlan ";
      }
      if (defined $mirrorlength) {
         $cmd = $cmd . "mirrorpacketlength $mirrorlength ";
      }

      # add other defined flags.
      $cmd = $cmd . "dvmirrordesc $desc striporiginalvlan $stripVlan ".
             "dvmirrorenabled $enabled normaltrafficallowed $traffic";
      $vdLogger->Debug("$tag running STAF setup command $cmd ...");

      # the command will create a mirror session for the vds.
      $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy, $cmd);
      if ($result->{rc} != 0) {
         $vdLogger->Error("$tag Failed to create mirror session $mirrorName".
                          "for vDS $self->{switch}");
         $vdLogger->Error(Dumper($result));
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $vdLogger->Info("Created mirror session $mirrorName for vDS ".
                      "$self->{switch}");
      return SUCCESS;
   }
   if ($mirrorVersion =~ /v2/i) {
      $vcpass =~ s/\$/\\\$/;
      $cmd = "java " . JAVA_OPTIONS . " -cp $ENV{CLASSPATH} com/vmware/vspancfgtool/Main".
              " --operation add --server $vcaddr --user $vcuser --password $vcpass ".
              " --vdsname $vds --sessionName $mirrorName ".
              " --enabled $enabled --normalTrafficAllowed $traffic ";
      if (defined $sessionType) {
         if (defined $srcRxPort) {
            $cmd = $cmd . " --srcRxPortKey \"$srcRxPort\" ";
         }
         if (defined $srcTxPort) {
            $cmd = $cmd . " --srcTxPortKey \"$srcTxPort\" ";
         }
         if (defined $dstPort) {
            $cmd = $cmd . " --destPortKey \"$dstPort\" ";
         }
         if (defined $dstUplink) {
            $cmd = $cmd . " --destUplinkPortName \"$dstUplink\" ";
         }
         if (defined $encapVlan) {
            $cmd = $cmd . " --encapsulationVlanId $encapVlan ";
         }
         if (defined $stripVlan) {
            $cmd = $cmd . " --stripOriginalVlan $stripVlan ";
         }
         if (defined $erspanIP) {
            $cmd = $cmd . " --destIpAddress $erspanIP ";
         }
         if (defined $samplingRate) {
            $cmd = $cmd . " --samplingRate $samplingRate  ";
         }
         if (defined $srcVLAN) {
            $cmd = $cmd . " --srcRxVlans $srcVLAN  ";
         }
         if (defined $mirrorlength) {
            $cmd = $cmd . " --mirroredPacketLength $mirrorlength  ";
         }

         $cmd = $cmd . " --sessionType $sessionType ";
         $vdLogger->Debug(" Call java program : command = $cmd");
         $result = $self->{stafHelper}->STAFSyncProcess("localhost", $cmd);

         if (($result->{rc} == 0) and ($result->{stdout} =~ /Add VSPAN session successfully/i)
              and ($result->{exitCode} == 0)){
            $vdLogger->Info("Create PortMirror : ".$result->{stdout});
            return SUCCESS;
         } else {
            $vdLogger->Error("STAF command to call java program failed".
                              Dumper($result));
            VDSetLastError("ESTAF");
            return FAILURE;
         }
      } else {
         $vdLogger->Error("$tag Failed to create mirror session $mirrorName".
                          "for vDS $self->{switch} since session type is not specified.");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
}

#######################################################################
#
# EditMirrorSession --
#      This method creates the dvmirror session.
#
#
# Input:
#     NAME : Name of the mirror session.
#     SRCRXPORT : source output ports.
#     SRCTXPORT : source input ports.
#     DSTUPLINK: Name of uplink port for destination.
#     DESC: Description for the mirror session.
#     DSTPORT: Destination port.
#     STRIPVLAN: Flag for stripping the vlan while mirroring the traffic.
#     ENABLE: Flag whether by default mirror session should be enabled or not.
#     DSTPG: Name of the destination portgroup.
#     LENGTH: Length of the packet to be mirrored at the destination port.
#     SRCRXPG: Source output dvportgroup.
#     SRCTXPG: Source input dvportgroup.
#     TRAFFIC: Flag to specify whether the detination port should be allowed
#              to do the normal traffic or not.
#     ENCAPVLAN: Vlan id which is to be encapsulated while mirroring the traffic.
#     SRCTXWC : Wild card to select the list of source input ports.
#     SRCRXWC: Wild card to select to the list of source output ports.
#     SESSIONTYPE: MN.Next PortMirror has 5 session type:
#                  dvPortMirror, remoteMirrorSource,remoteMirrorDest,
#                  encapsulatedRemoteMirrorSource and mixedDestMirror.
#     VERSION: MN is v1,MN.Next and later is v2.
#     SAMPLINGRATE: one of every n packets is mirrored.
#     SRCVLAN: RSPAN destinaiton session mirrored VLAN ID.
#     ERSPANIP: ESPAN source session defined mirror destination IP address.
#
#
# Results:
#      "SUCCESS", if mirror session is modified successfully
#      "FAILURE", in case of any error,
#
# Side effects:
#      None
#
#########################################################################

sub EditMirrorSession
{
   my $self = shift;
   my $args = shift;
   my $tag = "VDSwitch : EditMirrorSession: ";

   my $mirrorName = $args->{name};
   my $srcRxPort = $args->{srcrxport};
   my $srcTxPort = $args->{srctxport};
   my $dstUplink = $args->{dstuplink};
   my $desc = $args->{desc};
   my $dstPort = $args->{dstport};
   my $stripVlan = $args->{stripvlan};
   my $enabled = $args->{enabled};
   my $dstPG = $args->{dstpg};
   my $mirrorlength = $args->{mirrorlength};
   my $srcRxPg = $args->{srcrxpg};
   my $srcTxPg = $args->{SRCTXPG};
   my $traffic = $args->{normaltraffic};
   my $encapVlan = $args->{encapvlan};
   my $srcTxWC = $args->{srctxwc};
   my $srcRxWC = $args->{srcrxwc};
   my $sessionType = $args->{sessiontype};
   my $mirrorVersion = $args->{version} || "v1";
   my $samplingRate  = $args->{samplingrate};
   my $erspanIP = $args->{erspanip};
   my $srcVLAN = $args->{srcvlan};
   my $proxy = $self->{vcObj}->{proxy};
   my $vcaddr = $self->{vcObj}->{vcaddr};
   my $vcuser = $self->{vcObj}->{user};
   my $vcpass = $self->{vcObj}->{passwd};
   my $vds = $self->{switch};
   my $dcName = $self->{datacenter};
   my $anchor;
   my $result;
   my $cmd;

   if (defined $srcRxPort) {
      $srcRxPort = join(',', @$srcRxPort);
   }
   if (defined $srcTxPort) {
      $srcTxPort = join(',', @$srcTxPort);
   }
   if (defined $dstPort) {
      $dstPort = join(',', @$dstPort);
   }
   if (defined $dstUplink) {
      $dstUplink = join(',', @$dstUplink);
   }
   if (defined $erspanIP) {
      $erspanIP = join(',', @$erspanIP);
   }

   if ($mirrorVersion !~ m/v1|v2/i) {
      $vdLogger->Error("$tag Failed to edit mirror session $mirrorName ".
                          "for vDS $self->{switch} since mirror version is not specified,".
                          "should either be v1 or v2.");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if ($mirrorVersion =~ /v1/i) {
      # Get the anchor
      $anchor = $self->GetAnchor(SERVICE => "setup");
      if ($anchor eq FAILURE) {
         return FAILURE;
      }
       # command to edit mirror session.
      $cmd = "editdvsdvmirror anchor $anchor dvsname $vds dvmirrorname $mirrorName ";
      if (defined $srcRxPort) {
         $cmd = $cmd . "srcrxport $srcRxPort ";
      }
      if (defined $srcTxPort) {
         $cmd = $cmd . "srctxport $srcTxPort ";
      }

      #
      # add other options while editing a mirror sessoin if specified.
      # If none of the option is specified the mirror session created for
      # vds would be a legacy session i.e. equivalent to promiscusous mode.
      #
      if (defined $dstUplink) {
         $cmd = $cmd . "dstuplink $dstUplink ";
      }
      if (defined $dstPort) {
         $cmd = $cmd . "dstport $dstPort ";
      }
      if (defined $dstPG) {
         $cmd = $cmd . "dstpg $dstPG ";
      }
      if (defined $srcRxPg) {
         $cmd = $cmd . "srcrxpg $srcRxPg ";
      }
      if (defined $srcTxPg) {
         $cmd = $cmd . "srctxpg $srcTxPg ";
      }
      if (defined $encapVlan) {
         $cmd = $cmd . "encapsulationvlanid $encapVlan ";
      }
      if (defined $desc) {
         $cmd = $cmd . "dvmirrordesc $desc ";
      }
      if (defined $stripVlan) {
         $cmd = $cmd . "striporiginalvlan $stripVlan ";
      }
      if (defined $enabled) {
         $cmd = $cmd . "dvmirrorenabled $enabled ";
      }
      if (defined $traffic) {
         $cmd = $cmd . "normaltrafficallowed $traffic ";
      }
      if (defined $mirrorlength) {
         $cmd = $cmd . "mirrorpacketlength $mirrorlength ";
      }

      # the command will edit a mirror session for the vds.
      $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy, $cmd);
      if ($result->{rc} != 0) {
         $vdLogger->Error("$tag Failed to edit mirror session $mirrorName".
                          "for vDS $self->{switch}");
         $vdLogger->Error(Dumper($result));
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $vdLogger->Info("Created mirror session $mirrorName for vDS ".
                      "$self->{switch}");
      return SUCCESS;
   }
   if ($mirrorVersion =~ /v2/i) {
      $vcpass =~ s/\$/\\\$/;
      $cmd = "java " . JAVA_OPTIONS . " -cp $ENV{CLASSPATH} com/vmware/vspancfgtool/Main".
              " --operation edit --server $vcaddr --user $vcuser --password $vcpass ".
              " --vdsname $vds --sessionName $mirrorName ";
      if (defined $sessionType) {
         if (defined $srcRxPort) {
            $cmd = $cmd . " --srcRxPortKey $srcRxPort ";
         }
         if (defined $srcTxPort) {
            $cmd = $cmd . " --srcTxPortKey $srcTxPort ";
         }
         if (defined $dstPort) {
            $cmd = $cmd . " --destPortKey $dstPort ";
         }
         if (defined $dstUplink) {
            $cmd = $cmd . " --destUplinkPortName $dstUplink ";
         }
         if (defined $encapVlan) {
            $cmd = $cmd . " --encapsulationVlanId $encapVlan ";
         }
         if (defined $stripVlan) {
            $cmd = $cmd . " --stripOriginalVlan $stripVlan ";
         }
         if (defined $samplingRate) {
            $cmd = $cmd . " --samplingRate $samplingRate ";
         }
         if (defined $mirrorlength) {
            $cmd = $cmd . " --mirroredPacketLength $mirrorlength ";
         }
         if (defined $enabled) {
            $cmd = $cmd . " --enabled $enabled ";
         }
         if (defined $traffic) {
            $cmd = $cmd . " --normalTrafficAllowed $traffic ";
         }
         if (defined $erspanIP) {
            $cmd = $cmd . " --destIpAddress $erspanIP ";
         }
         if (defined $srcVLAN) {
            $cmd = $cmd . " --srcRxVlans $srcVLAN  ";
         }
         $cmd = $cmd . " --sessionType $sessionType ";
         $vdLogger->Debug(" Call java program : command = $cmd");
         $result = $self->{stafHelper}->STAFSyncProcess("localhost", $cmd);

         if (($result->{rc} == 0) and ($result->{stdout} =~ /Edit VSPAN session successfully/i)
              and ($result->{exitCode} == 0)){
            $vdLogger->Info("Edit PortMirror : ".$result->{stdout});
            return SUCCESS;
         } else {
            $vdLogger->Error("STAF command to call java program failed".
                              Dumper($result));
            VDSetLastError("ESTAF");
            return FAILURE;
         }
      } else {
         $vdLogger->Error("$tag Failed to Edit mirror session $mirrorName".
                          "for vDS $self->{switch} since doesn't provide session type");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
}


########################################################################
#
# ListMirrorSession
#      This method lists all the dvmirror session for a vDS.
#
#
# Input:
#      None.
#
# Results:
#      "SUCCESS", if listing mirror session is successful,
#      "FAILURE", in case of any error,
#
# Note
#
#####################################################################

sub ListDVMirrorSession
{
   my $self = shift;
   my $vds = $self->{switch};
   my $tag = "VDSwitch : ListDVMirrorSession : ";
   my $datacenter = $self->{vcObj}->{datacenter};
   my $proxy = $self->{vcObj}->{proxy};
   my $anchor;
   my $result;
   my $cmd;

   # get anchor.
   $anchor = $self->GetAnchor(SERVICE => "setup");
   if ($anchor eq FAILURE) {
      return FAILURE;
   }

   # command to list the dv mirror session.
   $cmd = "listdvsdvmirror anchor $anchor dvsname $vds ";
   if (defined $datacenter) {
      $cmd = $cmd . "dcname $datacenter";
   }
   $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to list the mirror sessions ".
                       "for vDS $self->{switch}");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


########################################################################
#
# RemoveMirrorSession
#      This method remove specified mirror session for a vDS.
#
#
# Input:
#      NAME : Name of the dvs mirror session.
#      VERSION: MN is v1,MN.Next and later is v2.
#
# Results:
#      "SUCCESS", if listing mirror session is successful,
#      "FAILURE", in case of any error,
#
# Note
#
######################################################################

sub RemoveMirrorSession
{
   my $self = shift;
   my $args = shift;
   my $mirrorName = $args->{name};
   my $mirrorVersion = $args->{version} || "v1";
   my $vds = $self->{switch};
   my $tag = "VDSwitch : RemoveMirrorSession : ";
   my $datacenter = $self->{vcObj}->{datacenter};
   my $proxy = $self->{vcObj}->{proxy};
   my $vcaddr = $self->{vcObj}->{vcaddr};
   my $vcuser = $self->{vcObj}->{user};
   my $vcpass = $self->{vcObj}->{passwd};
   my $anchor;
   my $result;
   my $cmd;

   # get anchor.
   $anchor = $self->GetAnchor(SERVICE => "setup");
   if ($anchor eq FAILURE) {
      return FAILURE;
   }
   if ($mirrorVersion !~ m/v1|v2/i) {
      $vdLogger->Error("$tag Failed to remove mirror session $mirrorName".
                          "for vDS $self->{switch} since mirror version is not specified,".
                          "should either be v1 or v2.");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if ($mirrorVersion =~ /v1/i) {
      # command to remove a dvs mirrror session.
      $cmd = "removedvsdvmirror anchor $anchor dvsname $vds ".
             "dvmirrorname $mirrorName";
      if ( defined $datacenter ) {
         $cmd = $cmd . " dcname $datacenter";
      }
      $vdLogger->Debug("Command to remove mirror - $cmd");
      $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy, $cmd);
      if ($result->{rc} != 0) {
         $vdLogger->Error("$tag Failed to remove the mirror session ".
                          " $mirrorName for vDS $vds");
         $vdLogger->Error(Dumper($result));
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
   if ($mirrorVersion =~ /v2/i) {
      $vcpass =~ s/\$/\\\$/;
      $cmd = "java " . JAVA_OPTIONS . " -cp $ENV{CLASSPATH} com/vmware/vspancfgtool/Main".
              " --operation remove --server $vcaddr --user $vcuser --password $vcpass ".
              " --vdsname $vds --sessionName $mirrorName ";
      $vdLogger->Debug(" Call java program : command = $cmd");
      $result = $self->{stafHelper}->STAFSyncProcess("localhost", $cmd);

      if (($result->{rc} == 0) and ($result->{stdout} =~ /Remove VSPAN session successfully/i)
          and ($result->{exitCode} == 0)){
         $vdLogger->Info("Remove PortMirror : ".$result->{stdout});
         return SUCCESS;
      } else {
         $vdLogger->Error("STAF command to call java program failed".
                              Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
}


#######################################################################
#
#  ConfigDiscoveryProtocol
#      This method configures the discovery protocol, cdp or lldp
#      based on the user parameter.
#
#
# Input:
#   A Named parameter hash containing following keys.
#      MODE: Mode of the discovery protocol (listen, advertise, both
#                                            down).
#      TYPE: Type of the discovery protocol (CDP or LLDP).
#
# Results:
#      protocol info (cdp or lldp) incase of success,
#      "FAILURE", in case of any error,
#
# Note
#
########################################################################

sub ConfigDiscoveryProtocol
{
   my $self = shift;
   my %args = @_;
   my $tag = "VDSwitch : ConfigDiscoveryProtocol : ";
   my $mode = $args{MODE} || "Listen";
   my $type = $args{TYPE} || "cdp";
   my $proxy = $self->{vcObj}->{proxy};
   my $vds = $self->{switch};
   my $datacenter = $self->{datacenter};
   my $cmd;
   my $result;
   my $anchor;

   $anchor = $self->GetAnchor(SERVICE => "setup");
   if (not defined $anchor) {
      return FAILURE;
   }

   # command to configure the discovery protocol for vds.
   $cmd = "configdvsdprotocol anchor $anchor dvsname $vds ".
          "discoverytype $type discoverymode $mode ";
   if (defined $datacenter) {
      $cmd = $cmd . "dcname $datacenter";
   }

   $vdLogger->Debug("Configure discovery with parameters : $cmd");
   $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to list the mirror sessions ".
                       "for vDS $self->{switch}");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
#  GetVDSProtocol
#      This method lists the the current vds discovery protocol.
#
#
# Input:
#      None.
#
# Results:
#      protocol info (cdp or lldp) incase of success,
#      "FAILURE", in case of any error,
#
# Note
#
########################################################################

sub GetVDSProtocol
{
   my $self = shift;
   my $tag = "VDSwitch : GetVDSProtocol :";
   my $vds = $self->{switch};
   my $datacenter = $self->{vcObj}->{datacenter};
   my $proxy = $self->{vcObj}->{proxy};
   my $anchor;
   my $result;
   my $cmd;

   # get anchor.
   $anchor = $self->GetAnchor(SERVICE => "setup");
   if ($anchor eq FAILURE) {
      return FAILURE;
   }

   # command to list the vds protocol.
   $cmd = "getdvsdprotocol anchor $anchor dvsname $vds";
   if (defined $datacenter) {
      $cmd = $cmd . "dcName $datacenter";
   }
   $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to list the mirror sessions ".
                       "for vDS $self->{switch}");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   #
   # this may not be the correct result, at the moment the
   # STAFSubmitSetupCommand doesn't handle 5.x commands well,
   # and this applicable only for 5.x.
   return $result->{result};
}


#######################################################################
#
# ConfigureVDSNetFlow --
#      This method would configure the dvs netflow.
#
#
# Input:
#  A name parameter hash having the following keys.
#  COLLECTORIP : IP address of the ipfix collector,
#  INTERNAL : If set to true the traffic analysis would be limited
#              to the internal traffic i.e. same host. The default
#              is false.
#  IDLETIMEOUT: the time after which idle flows are automatically
#               exported to the ipfix collector, the default is 15
#               seconds.
#  COLLECTORPORT : port for the ipfix collector.
#  VDSIP      : Parameter to specify the (IPv4 )ip address of the vds.
#  ACTIVETIMEOUT : the time after which active flows are automatically
#                 exported to the ipfix collector.default is 60 seconds.
#
#
# Results:
#      "SUCCESS", if switch port gets disabled
#      "FAILURE", in case of any error,
#
# Side effects:
#      None.
#
sub ConfigureVDSNetFlow
{
   my $self = shift;
   my %args = @_;
   my $collectorIP = $args{COLLECTORIP};
   my $internalOnly = $args{INTERNAL} || "false";
   my $idleTimeout = $args {IDLETIMEOUT};
   my $collectorPort = $args{COLLECTORPORT};
   my $vdsIP = $args{VDSIP};
   my $activeTimeout = $args{ACTIVETIMEOUT};
   my $samplingRate = $args{SAMPLING};
   my $tag = "VDSwitch : ConfigureNetFlow : ";
   my $vds = $self->{switch};
   my $dcName = $self->{datacenter};
   my $proxy = $self->{vcObj}->{proxy};
   my $result;
   my $cmd;
   my $anchor;

   $anchor = $self->GetAnchor(SERVICE => "setup");
   if ($anchor eq FAILURE) {
      return FAILURE;
   }
   $cmd = "configdvsnetflow anchor $anchor dvsname $vds ".
          "collectorip $collectorIP dvsip $vdsIP ";

   if (defined $internalOnly && $internalOnly =~ /true/i) {
      $cmd = $cmd . "internalflowsonly ";
   }
   if (defined $idleTimeout) {
      $cmd = $cmd . "idleflowtimeout $idleTimeout ";
   }
   if (defined $collectorPort) {
      $cmd = $cmd . "collectorport $collectorPort ";
   }
   if (defined $activeTimeout) {
      $cmd = $cmd . "activeflowtimeout $activeTimeout ";
   }
   if(defined $samplingRate) {
      $cmd = $cmd . "samplingrate $samplingRate ";
   }
   if(defined $dcName) {
      $cmd = $cmd . "dcname $dcName";
   }

   # run the command to configure netflow.
   $vdLogger->Debug("$tag $cmd");
   $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to list the mirror sessions ".
                       "for vDS $self->{switch}");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


#######################################################################
#
# SetPortState--
#      This method would set the port state for the dvport.
#
#
# Input:
#  A name parameter hash having the following keys.
#    PORT : Name of the dvport for which the state has to be set.
#    BLOCK: State of the dvport to be set.
#
# Results:
#      "SUCCESS", if port state is set,
#      "FAILURE", in case of any error,
#
# Side effects:
#      None.
######################################################################

sub SetPortState
{
   my $self = shift;
   my %args = @_;
   my $tag = "VDSwitch : SetPortState : ";
   my $port = $args{PORT};
   my $state = $args{BLOCK} || "true";
   my $vds = $self->{switch};
   my $dvPortgroup = $args{DVPG};
   my $dcName = $self->{datacenter};
   my $proxy = $self->{vcObj}->{proxy};
   my $anchor;
   my $cmd;
   my $result;

   if ( not defined $dvPortgroup ) {
      $vdLogger->Error("$tag dvPortgroup name not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ( not defined $port ) {
      $vdLogger->Error("$tag dvport name not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ( $state !~ /true|false/i ) {
      $vdLogger->Error("$tag The port state can be either true or false");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # get the anchor.
   $anchor = $self->GetAnchor(SERVICE => "setup");
   if ($anchor eq FAILURE) {
      return FAILURE;
   }

   # command to set the port state.
   $cmd = "blockdvport anchor $anchor portgroup $dvPortgroup ".
          "dvsname $vds port $port ";
   if ($state =~ m/true/i) {
      $cmd = "$cmd block ";
   }
   if ( defined $dcName ) {
      $cmd = $cmd . "dcname $dcName";
   }
   $vdLogger->Debug("Execute STAF command : $cmd");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to set the port state ".
                       "for vDS $self->{switch}");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


#######################################################################
#
# AddPVLANMap--
#      This method would add the pvlan map for vDS.
#
#
# Input:
#  A name parameter hash having the following keys.
#    PVLANTYPE : pvlan type, possible values it could be promiscuous,
#                community and isolated.
#    PRIMARYID : Primary VLAN id.
#    SECONDARYID : Secondary VLAN id.
#
#
# Results:
#      "SUCCESS", if port state is set,
#      "FAILURE", in case of any error,
#
# Side effects:
#      None.
######################################################################

sub AddPVLANMap
{
   my $self = shift;
   my %args = @_;
   my $tag = "VDSwitch : AddPVLANMap : ";
   my $type = $args{PVLANTYPE};
   my $primaryID = $args{PRIMARYID};
   my $secondaryID = $args{SECONDARYID};
   my $dcName = $self->{datacenter};
   my $proxy = $self->{vcObj}->{proxy};
   my $vds = $self->{switch};
   my $anchor;
   my $cmd;
   my $result;

   # validate the parameters.
   if($type !~ m/promiscuous|community|isolated/i) {
      $vdLogger->Error("$tag $type is not valid for pvlan type");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if($primaryID !~ m/\d+/) {
      $vdLogger->Error("$tag $primaryID is not valid vlan id");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if($secondaryID !~ m/\d+/) {
      $vdLogger->Error("$tag $secondaryID is not valid vlan id");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # get the anchor.
   $anchor = $self->GetAnchor(SERVICE => "host");
   if ($anchor eq FAILURE) {
      return FAILURE;
   }
   # command to set the port state.
   $cmd = "addpvlanid anchor $anchor dvsname $vds ".
          "pvlantype $type primary_pvlanid $primaryID ".
          "secondary_pvlanid $secondaryID ";
   if ( defined $dcName ) {
      $cmd = $cmd . "dcname $dcName";
   }
   $vdLogger->Debug("Adding pvlan map with parameters : $cmd");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to add pvlan map ".
                       "for vDS $self->{switch}");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


#######################################################################
#
# MigrateManamgementNetToVSS--
#      This method migrates the managment network to vSS.
#
#
# Input:
#  A name parameter hash having the following keys.
#    HOST : Obj of the ESX host whose management net has to
#           be migrated to vSS.
#    VNICID : Obj of the management interface to be migrated.
#    SWNAME : Obj of the switch.
#
# Results:
#      Newly created PG's object is returned, if managment network
#      gets migrated to vSS,
#      "FAILURE", in case of any error,
#
# Side effects:
#      None.
######################################################################

sub MigrateManagementNetToVSS
{
   my $self = shift;
   my %args = @_;
   my $tag = "VDSwitch : MigrateManamgementNetToVSS : ";
   my $hostObj = $args{HOSTOBJ};
   my $vmknicObj = $args{VMKNICOBJ}->[0];
   my $swObj = $args{SWOBJ}->[0];
   my $proxy = $self->{vcObj}->{proxy};
   my $vds = $self->{switch};
   my $anchor;
   my $cmd;
   my $result;

   # Retriveing Host, vnic, switch and PG names from objs
   my $host = $hostObj->{hostIP};
   my $vnic = $vmknicObj->{deviceId};
   my $swName = $swObj->{name};
   my $pgName = "$vnic-pg";

   # get the anchor.
   $anchor = $self->GetAnchor(SERVICE => "host");
   if ($anchor eq FAILURE) {
      return FAILURE;
   }
   # command to set the port state.
   $cmd = "migratemgmtnettolegswitch anchor $anchor pghost $host ".
          "vnicid $vnic swname $swName pgname \"$pgName\" ";
   $vdLogger->Debug("Migrating management network to vss : $cmd");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to migrate management network".
                       "from vDS $self->{switch} to vSS $swName");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # Creating portgroup obj of newly created PG
   my $pgObj = VDNetLib::Switch::VSSwitch::PortGroup->new(
                  'hostip'     => $host,
                  'pgName'     => $pgName,
                  'switchObj'  => $swObj,
                  'hostOpsObj' => $hostObj,
                  'stafHelper' => $self->{stafHelper});
   if ($pgObj eq FAILURE) {
      $vdLogger->Error("Failed to create PortGroup object for newly created ".
                       "PG $pgName");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vmknicObj->{pgObj} = $pgObj;
   return $vmknicObj;
}


########################################################################
#
# GetAnchor
#      This method returns the anchor name for the specified staf service.
#
#
# Input:
#      SERVICE : name of the service.
#
# Results:
#      Anchor name in case of success.
#      "FAILURE", in case of any error,
#
# Note
# If anchor is not defined it tries to connect to the vc.
#

sub GetAnchor
{
   my $self = shift;
   my %args = @_;
   my $service = $args{SERVICE};
   my $setupAnchor = undef;
   my $hostAnchor = undef;

   # if service is not defined then assume it's setup service.
   if (not defined $service) {
      $service = "setup";
   }

   # check if we are already connected to vc, if not connect again.
   if ((not defined $self->{vcObj}->{setupAnchor}) ||
       (not defined $self->{vcObj}->{hostAnchor})) {
      unless($self->{vcObj}->ConnectVC()) {
         $vdLogger->Error("connecting  to vc failed");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   if (defined $self->{vcObj}->{setupAnchor}) {
      $setupAnchor = $self->{vcObj}->{setupAnchor};
   } else {
      $vdLogger->Error("Setup Anchor not defined for vc $self->{vcObj}->{vcaddr}");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (defined $self->{vcObj}->{hostAnchor}) {
      $hostAnchor = $self->{vcObj}->{hostAnchor};
   } else {
      $vdLogger->Error("Host Anchor not defined for vc $self->{vcObj}->{vcaddr}");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # depending upon the type of service return the appropriate anchor.
   if ($service =~/setup/i) {
      if (defined $setupAnchor) {
         return $setupAnchor;
      } else {
         $vdLogger->Error("Failure to get the anchor for $service");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   } else {
      if (defined $hostAnchor) {
         return $hostAnchor;
      } else {
         $vdLogger->Error("Failure to get the anchor for $service");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   }
}


########################################################################
#
# EnableNetIORM
#      This method enable NetIORM feature in specified VDS.
#
# Input:
#      none
#
# Results:
#      "SUCCESS", if success,
#      "FAILURE", in failed.
#
# Side effects:
#      none
#

sub EnableNetIORM
{
   my $self = shift;
   my $tag = "VDSwitch : Enabel NetIORM :";
   my $anchor = undef;
   my $cmd = undef;
   my $dcName = $self->{datacenter};
   my $proxy = $self->{vcObj}->{proxy};
   my $result;

   $anchor = $self->GetAnchor(SERVICE => "setup");
   if ($anchor eq FAILURE) {
      return FAILURE;
   }
   #command to enable.
   $cmd = "ENABLENETWORKIORM anchor $anchor dvsname $self->{switch} ";
   if (defined $dcName) {
      $cmd = $cmd . "dcname $dcName";
   }
   $vdLogger->Debug("Execute STAF command : $cmd");
   $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to enable NetIORM feature ".
                       "for vDS $self->{switch}");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# DisableNetIORM
#      This method disable NetIORM feature in specified VDS.
#
# Input:
#      none
#
# Results:
#      "SUCCESS", if success,
#      "FAILURE", in failed.
#
# Side effects:
#      none
#

sub DisableNetIORM
{
   my $self = shift;
   my $tag = "VDSwitch : Disable NetIORM :";
   my $anchor = undef;
   my $cmd = undef;
   my $dcName = $self->{datacenter};
   my $proxy = $self->{vcObj}->{proxy};
   my $result;

   $anchor = $self->GetAnchor(SERVICE => "setup");
   if ($anchor eq FAILURE) {
      return FAILURE;
   }
   #command to enable.
   $cmd = "DISABLENETWORKIORM anchor $anchor dvsname $self->{switch} ";
   if (defined $dcName) {
      $cmd = $cmd . "dcname $dcName";
   }
   $vdLogger->Debug("Execute STAF command : $cmd");
   $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to disable NetIORM feature ".
                       "for vDS $self->{switch}");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}

#######################################################################
#
#  GetUplinkPortGroup
#      This method returns the uplink dvportgroup of the specified VDS.
#
# Input: A named hash containing parameters
#   HOST: Name of the ESX host.
#
# Results:
#      Name of the uplink dvportgroup on success
#      FAILURE in case we failed to get the uplink portgroup.
#
# Side effects:
#      None.
#
########################################################################

sub GetUplinkPortGroup
{
   my $self = shift;
   my %args = @_;
   my $host = $args{HOST};
   my $tag = "VDSwitch : GetUplinkDVPortGroup : ";
   my $dcName = $self->{datacenter};
   my $proxy = $self->{vcObj}->{proxy};
   my $VDSName = $self->{switch};
   my $anchor;
   my $cmd;
   my $result;
   my $uplinkPort;

   # get anchor
   $anchor = $self->GetAnchor(Service => "host");
    if ($anchor eq FAILURE) {
      return FAILURE;
   }

   # command to list all the dvportgroups for the dvs
   $cmd = "listdvpg anchor $anchor host $host dvsname $VDSName ";
   if (defined $dcName) {
      $cmd = $cmd . "dcname $dcName";
   }
   $vdLogger->Debug("Execute STAF command : $cmd");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to list the dvportgroups ".
                       "for vDS $VDSName");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if (defined $result->{result}) {
      foreach my $dvpg (@{$result->{result}}) {
         if ($dvpg->{DVPORTGROUPNAME} =~ m/DVUplinks/i) {
            $uplinkPort = $dvpg->{DVPORTGROUPNAME};
            last;
         }
      }
   } else {
      $vdLogger->Error("$tag Failed to list the dvportgroups");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # return the name of uplink port if we found it.
   if (defined $uplinkPort) {
      return $uplinkPort;
   } else {
      return FAILURE;
   }
}


########################################################################
#
# ConfigureProtectedVM--
#      This method configures DVFilter for a vnic on the given SUT VM
#
# Input:
#      slotdetails: Slot details where the filter needs to inserted
#      operation  : add/remove
#      params     : Parameters required for opaque data
#      onFailure  : FailOpen/FailClose
#      filters    : comma separated list of filters
#      portids    : comma separated list of corresponding portids for filters
#
#
# Results:
#      "SUCCESS", if configuring dvfilter is successful.
#      "FAILURE", in case of any error.
#
# Side effects:
#      none
#
########################################################################

sub ConfigureProtectedVM
{
   my $self = shift;
   my $args = shift;

   my @tempArr;
   my $result;
   my $opaqueData;
   my $inlineDVS = $self->GetInlineDVS();
   my $inlineDVSMgr = $self->GetInlineDVSManager();
   my $dvsName = $self->{switch};
   my $key ;

   my $dvsSS = $inlineDVS->SetDVSSelectionSet(
                                           selectionSet => undef,);
   $dvsSS = CreateInlineObject('com.vmware.vc.DVSSelection');
   my $dvsMor = $inlineDVS->{dvsMOR};
   $dvsSS->setDvsUuid($inlineDVS->{dvs}->getConfig($dvsMor)->getUuid());
   my $dvportSS = $inlineDVS->SetDVPortSelectionSet(
                                           selectionSet => undef,);
   my $dvsCfgSelectionSet = [];
   my $dvPortSelectionSet = [];
   push(@$dvsCfgSelectionSet,$dvsSS);

   my $slotinfo  = eval($args->{slotdetails});
   my $operation = eval($args->{dvfilteroperation});
   my $filter    = eval($args->{filters});
   my $onfailure = eval($args->{onfailure});
   my $paraminfo = eval($args->{dvfilterparams});
   my $vnicObj   = $args->{adapter};

   if ((not defined $slotinfo) || ($slotinfo eq "") ||
       (not defined $operation) ||($operation eq "") ||
       (not defined $filter) || ($filter eq "")||
       (not defined $onfailure) || ($onfailure eq "")||
       (not defined $paraminfo) || ($paraminfo eq "")||
       (not defined $vnicObj)) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("ENOTDEF");
       return FAILURE;
    }

   if ($onfailure =~ /failclose/i) {
      $onfailure = 1;
   } else {
      $onfailure = 0;
   }

   my $vmObj = $vnicObj->{vmOpsObj};
   my $hostObj = $vmObj->{hostObj};
   my $portid = $hostObj->GetvNicDVSPortID($vnicObj->{macAddress});
   if ($portid eq FAILURE) {
      $vdLogger->Error("Can't find vds portid for $vnicObj->{macAddress}");
      VDSetLastError("EINVALID");
      return FAILURE;
    }


   # Configure filter for DVS
   $key= 'com.vmware.common.dvfilter-generic';

   $opaqueData = pack("Z40", $filter);
   @tempArr = unpack ("c*", $opaqueData);
   $opaqueData = \@tempArr;

   my %paramHash = (
                   opaquedata => $opaqueData,
                   key        => $key,
                   operation       => $operation,
                   dvsselectionset => $dvsCfgSelectionSet,
                   );
   $result = $self->ConfigureFilter(%paramHash);
   if ($result eq FAILURE){
      $vdLogger->Error("Failed to Configure DVS for dvfilter-generic.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Configure filter for DV PORT
   $key = 'com.vmware.common.port.dvfilter';

   my ($slotIndex,$slotNumParams) = split(':',$slotinfo);
   my $slotName      = $filter;
   my $slotOnFail    = $onfailure;
   my ($param0Num,$param0Val) = split(':',$paraminfo);
   $opaqueData = pack("IIZ40IIIZ256", 1, $slotIndex, $slotName,
                      $slotNumParams, $slotOnFail, $param0Num, $param0Val);
   @tempArr = unpack("c*", $opaqueData);
   $opaqueData = \@tempArr;

   # Fill in the DVPortSelectionSet;get the port key and provide the same here
   my $arrayList = CreateInlineObject('java.util.ArrayList');
   $arrayList->add(0,$portid);
   $dvportSS->setPortKey($arrayList);
   push(@$dvPortSelectionSet, $dvportSS);

   my %Hash = (
               opaquedata => $opaqueData,
               key        => $key,
               operation       => $operation,
               dvsselectionset => $dvPortSelectionSet,
              );
   $result = $self->ConfigureFilter(%Hash);
   if ($result eq FAILURE){
      $vdLogger->Error("Failed to Configure DV port for dvfilter");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Verify the filter has been to added to the VM
   my $vmName = $vmObj->{vmName};
   my $hostIP = $hostObj->{hostIP};
   if ($self->VerifyProctectedVM($vmName,$hostIP) eq FAILURE) {
       $vdLogger->Error("Failed to add filter to the protected VM");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# ConfigureHealthCheck --
#      This method configures the healthcheck for the vds. The user
#      can enable/disable the teaming check or vlanmtu check for the
#      vds. Users can also specify the interval parameter.
#
# Input:
#      Type: Type of the check to configured. It could be either teaming
#            or vlanmtu check or both.
#      Operation: "Enable" if user wants to enable the healthcheck,
#                 "Disable" if user wants to disable the healthcheck.
#      interval:  Specifies the interval of healthcheck for the vds.
#
#
# Results:
#      "SUCCESS", if configuring healthcheck is successful.
#      "FAILURE", in case of any error.
#
# Side effects:
#      healthcheck for the vds gets enabled or disabled for the vds.
#
########################################################################

sub ConfigureHealthCheck
{
   my $self = shift;
   my %args = @_;
   my $type       = $args{type} || "teaming";
   my $operation  = $args{operation} || "Enable";
   my $interval   = $args{interval};
   my $inlineDVS  = $self->GetInlineDVS();
   my $dvsName    = $self->{switch};
   my $result;

   # check the parameters.
   if ($type !~ /vlanmtu|teaming/i) {
      $vdLogger->Error("Invalid healthcheck configuration : $type specified ".
                       "valid values are - vlanmtu, teaming or both");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if ($operation !~ /Enable|Disable/i) {
      $vdLogger->Error("Invalid operation : $operation specified for ".
                       "healthcheck valid values are - Enable or Disable");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   #
   # the method in InlineDVS object accepts true/false instead of
   # Enable/Disable.
   #
   if ($operation =~ m/Enable/i) {
      $operation = "true";
   } else {
      $operation = "false";
   }

   # call the method in inline DVS class to configure healthcheck.
   $result = $inlineDVS->ConfigureDVSHealthCheck(dvsName => $dvsName,
                                                 healthcheck => $type,
                                                 interval => $interval,
                                                 operation => $operation,
                                                 );
   if (!$result) {
      $vdLogger->Error("Failed to configure $type healthcheck operation for ".
                       "dvs $dvsName");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# ExportImportEntity--
#      This method exports/imports the VDS and/or DVPG configuration.
#      This method calls inlineJava function to perform operation.
#
# Input:
#      backuprestore : <exportvds/exportvdsdvpg/exportdvpg
#                      importvds/importvdsdvpg/importdvpg
#                      restorevds/restorevdsdvpg/restoredvpg
#                      importorigvds/importorigvdsdvpg/importorigdvpg>
#
#      dvpgName      : Name of the dvPort-Group.
#
# Results:
#      "SUCCESS", if export operation is successful.
#      "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub ExportImportEntity
{
   my $self = shift;
   my %args = @_;
   my $operation = $args{backuprestore};
   my $dvpgName = $args{dvpgName};
   my $inlineDVS  = $self->GetInlineDVS();
   my $result;

   my $logDir = VDNetLib::Common::GlobalConfig::GetLogsDir();
   my $vdsFileName = $logDir . "vdsCfg.bkp";
   my $dvpgFileName = $logDir . "dvpgCfg.bkp";
   if ($operation =~ m/export/i) {
      $result = $inlineDVS->ExportVDSConfig(backup       => $operation,
                                            dvpgName     => $dvpgName,
                                            vdsFileName  => $vdsFileName,
                                            dvpgFileName => $dvpgFileName);
   } else {
      $result = $inlineDVS->ImportVDSConfig(restore      => $operation,
                                            dvpgName     => $dvpgName,
                                            vdsFileName  => $vdsFileName,
                                            dvpgFileName => $dvpgFileName);
   }

   if (!$result) {
      $vdLogger->Error("Failed to perform export/import operation.");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return SUCCESS;
}

########################################################################
#
# EditMAXProxyPorts
#      This method edits maximum number of dvports for host.
#
# Input:
#      HOST : IP of hostname of the target host.
#      MAXPORTS : Parameter to specify/change max dvports value.
#
# Results:
#      "SUCCESS", if maxports get changed.
#      "FAILURE", in case of any error while set the parameter.
#
# Side effects:
#      None
#
# Notes:
#      This method will not take effect until host reboots
#
########################################################################

sub EditMAXProxyPorts
{
   my $self = shift;
   my %args = @_;
   my $host = $args{HOST};
   my $maxports = $args{MAXPORTS};
   my $tag = "VDSwitch : EditMAXProxyPorts : ";
   my $anchor = undef;
   my $cmd = undef;
   my $dcName = $self->{datacenter};
   my $proxy = $self->{vcObj}->{proxy};
   my $vds = $self->{switch};
   my $result;

   # error checking goes here.
   if (not defined $host) {
      $vdLogger->Error("Host name/ip not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $maxports) {
      $vdLogger->Error("The maximum number of ports not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Get the anchor
   $anchor = $self->GetAnchor(SERVICE => "setup");
   if ($anchor eq FAILURE) {
      $vdLogger->Error("Failed to connect to vc setup with $proxy");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $cmd = "editdvshostmaxpxyswitchport anchor $anchor dvsname $vds" .
          " datacenter $dcName hosts $host maxproxyswitchports $maxports";

   # running command to edit host max dvports.
   $vdLogger->Debug("running command to edit host max proxy ports $cmd");
   $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy, $cmd);

   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to edit max proxy ports on host $host ".
                       " connected to vDS $vds");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return SUCCESS;
}


################################################################################
# SetTeaming (%args)
#  This method configures the nic teaming policies for the dvs.
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
#                 dvs.
# Returns FAILURE otherwise.
#
# Side effects:
# teaming configurations gets changed for the dvs.
#
# note
# None
#
#################################################################################

sub SetTeaming
{
   my $self = shift;
   my %args = @_;
   my $tag = "VDSwitch : SetTeaming : ";
   my $failover = $args{FAILOVER} || "linkstatusonly";
   my $notifySwitch = $args{NOTIFYSWITCH} || undef;
   my $failback = $args{FAILBACK} || undef;
   my $lbPolicy = $args{LBPOLICY} || undef;
   my $standbyNICs = $args{STANDBYNICS} || undef;
   my $vds = $self->{switch};
   my $proxy = $self->{vcObj}->{proxy};
   my $dcName = $self->{datacenter};
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

   $anchor = $self->GetAnchor(SERVICE => "setup");
   if ($anchor eq FAILURE) {
      $vdLogger->Error("$tag Failed to create/get the anchor");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # command to set the nic teaming.
   $cmd = "configdvsnicteaming anchor $anchor dvsname $vds ".
          "failoverdetection $failover ";
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
   $vdLogger->Debug("setting nic teaming with parameters $cmd");
   $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$tag Failed to set nic teaming ".
                       "for vDS $self->{name}");
      $vdLogger->Debug(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}

###############################################################################
#
# GetVDSVmknicName --
#      This method will return vmknic Name by host ip, vds name and vlan id
#
# Input:
#      HostIp               -   host ip
#      VDSName              -   VDS name
#      VlanId               -   Vlan id
#
# Results:
#      Return vmknic name
#      Return "FAILURE", in case of any error,
#
# Side effects:
#      None.
#
###############################################################################

sub GetVDSVmknicName
{
   my $self      = shift;
   my $hostip    = shift;
   my $vdsname   = shift;
   my $vlanid    = shift;

   if (not defined $self) {
      $vdLogger->Error("self not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $hostip) {
      $vdLogger->Error("host ip not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $vdsname) {
      $vdLogger->Error("vds name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $vlanid) {
      $vdLogger->Error("vlan id not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $vmknicname;
   my $command;
   my $result;

   # command to list vmknic
   $command = "net-vdl2 -l -s $vdsname -V $vlanid ";
   $vdLogger->Debug(" Call esxcli : command = $command");
   $result = $self->{stafHelper}->STAFSyncProcess($hostip, $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to run command: $command".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   # /vmfs/volumes # net-vdl2 -l -s vds1 -V 0
   # VXLAN vmknic:   vmk1
   #     VDS port ID:    21
   #     Switch port ID: 50331962
   #     Interface index:        3
   #     VLAN ID:        0
   #     VXLAN IP:       172.16.134.71
   #     IP acquire timeout:     0
   #     Multicast group count:  0
   # /vmfs/volumes #
   if ($result ->{stdout} =~ m/VXLAN vmknic:\s+(vmk\d+)/is) {
      $vmknicname = $1;
   }else {
      $vdLogger->Error("No vmknic found by host: $hostip, vdsname: $vdsname, vlanid: $vlanid".
                        Dumper($result));
      return FAILURE;
   }
   return $vmknicname;
}

###############################################################################
#
# GetVDSVmknicIp --
#      This method will return vmknic ip by host ip, vds name and vlan id
#
# Input:
#      HostIp               -   host ip
#      VDSName              -   VDS name
#      VlanId               -   Vlan id
#
# Results:
#      Return vmknic ip
#      Return "FAILURE", in case of any error,
#
# Side effects:
#      None.
#
###############################################################################

sub GetVDSVmknicIp
{
   my $self      = shift;
   my $hostip    = shift;
   my $vdsname   = shift;
   my $vlanid    = shift;

   if (not defined $self) {
      $vdLogger->Error("self not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $hostip) {
      $vdLogger->Error("host ip not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $vdsname) {
      $vdLogger->Error("vds name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $vlanid) {
      $vdLogger->Error("vlan id not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $vmknicip;
   my $command;
   my $result;

   # command to list vmknic
   $command = "net-vdl2 -l -s $vdsname -V $vlanid ";
   $vdLogger->Debug(" Call esxcli : command = $command");
   $result = $self->{stafHelper}->STAFSyncProcess($hostip, $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to run command: $command".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   # /vmfs/volumes # net-vdl2 -l -s vds1 -V 0
   # VXLAN vmknic:   vmk1
   #     VDS port ID:    21
   #     Switch port ID: 50331962
   #     Interface index:        3
   #     VLAN ID:        0
   #     VXLAN IP:       172.16.134.71
   #     IP acquire timeout:     0
   #     Multicast group count:  0
   # /vmfs/volumes #
   if ($result->{stdout} =~ m/VXLAN IP:\s+(\d+.\d+.\d+.\d+)/is) {
      $vmknicip=$1;
   }else {
      $vdLogger->Error("No vmknic found by host: $hostip, vdsname: $vdsname, vlanid: $vlanid".
                        Dumper($result));
      return FAILURE;
   }
   return $vmknicip;
}

###############################################################################
#
# GetVDSVmknicPort --
#      This method will return vmknic port info by host ip, vds name and vmknic name
#
# Input:
#      HostIp               -   host ip
#      VDSName              -   VDS name
#      vmknicName           -   vmknic name
#
# Results:
#      Returns vmknic port id
#      Returns FAILURE, if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub GetVDSVmknicPort
{
   my $self       = shift;
   my $hostip     = shift;
   my $vdsname    = shift;
   my $vmknicname = shift;

   if (not defined $self) {
      $vdLogger->Error("self not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $hostip) {
      $vdLogger->Error("host ip not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $vdsname) {
      $vdLogger->Error("vds name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $vmknicname) {
      $vdLogger->Error("vvmknic name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $vmknicport = "";
   my $command;
   my $result;
   my @words;
   my @array;

   # command to list VXLAN network info with specified VDS and vmknic name.
   $command = "esxcli network vswitch dvs vmware vxlan vmknic list ".
              "--vds-name=$vdsname --vmknic-name=$vmknicname ";
   $vdLogger->Debug(" Call esxcli : command = $command");
   $result = $self->{stafHelper}->STAFSyncProcess($hostip, $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to run command: $command".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   # /vmfs/volumes # esxcli network vswitch dvs vmware vxlan vmknic list --vds-name=vds1 --vmknic-name=vmk1
   # Vmknic Name  Switch Port ID  VDS Port ID  Interface Index  VLAN ID  VXLAN IP       IP Acquire Timeout  Multicast Group Count
   # -----------  --------------  -----------  ---------------  -------  -------------  ------------------  ---------------------
   # vmk2               67108890  29                         4        0  172.23.146.157                   0                      2
   # /vmfs/volumes #
   @words = split(/\s+/is, $result->{stdout});
   $vmknicport = $words[30];
   if(length($vmknicport) == 0) {
     $vdLogger->Error("No vmknic ip found by host: $hostip, vdsname: $vdsname, vmknicname: $vmknicname".
                        Dumper($result));
     return FAILURE;
   }
   return $vmknicport;
}
########################################################################
#
# VerifyProtectedVM --
#      This method verifies if the filter got added to the protected VM
#
# Input:
#      VMname: protected VM name
#      Host:hostIP
#
# Results:
#     SUCCESS if no error encountered
#     FAILURE if any error
#
# Side effects:
#     None
#
########################################################################

sub VerifyProctectedVM
{
   my $self = shift;
   my $vmName = shift;
   my $host = shift;
   my $command;
   my $result;
   my $ret;

   $vdLogger->Info("Verify the Proctected VM has the filter");
   $command = "summarize-dvfilter";
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if ($result->{rc} != 0) {
       $vdLogger->Error("Failed to execute command $command on " .
                          $host);
       VDSetLastError("ESTAF");
       return FAILURE;
    }

   if ($result->{stdout} =~ m/$vmName/i){
       $vdLogger->Info("The filter got added to the VM: $vmName");
       return SUCCESS;
    }

   return FAILURE;

}

########################################################################
#
# VerifyProtectedVM --
#      This method verifies if the filter got added to the protected VM
#
# Input:
#      VMname: protected VM name
#      Host:hostIP
#
# Results:
#     SUCCESS if no error encountered
#     FAILURE if any error
#
# Side effects:
#     None
#
########################################################################

sub ConfigureFilter
{
  my $self = shift;
  my %args = @_;
  my $isRuntime = 0;
  my $opaqueData  = $args{'opaquedata'};
  my $key = $args{'key'};
  my $operation  = $args{'operation'};
  my $dvsSelectionSet  = $args{'dvsselectionset'};
  my $dvsOpaqueSpecList  = [];
  my $inlineDVS = $self->GetInlineDVS();
  my $inlineDVSMgr = $self->GetInlineDVSManager();
  my $dvsName    = $self->{switch};
  my $result;

  my $keyedOpaqueData = $inlineDVS->SetDVSKeyedOpaqueData(
                                            Inherited => 0,
                                            Key => $key,
                                            OpaqueData => $opaqueData,
                                           );
   $vdLogger->Debug("key is " . $keyedOpaqueData->getKey() . Dumper($opaqueData));
   if ($keyedOpaqueData eq FALSE) {
         $vdLogger->Error("SetDVSKeyedOpaqueData for dvs $dvsName failed");
         VDSetLastError("EINLINE");
         return FAILURE;
      }


    my $opaqueDataSpec = $inlineDVS->SetDVSOpaqueDataConfigSpec(
                                        KeyedOpaqueData => $keyedOpaqueData,
                                        Operation => $operation,
                                                             );
    if ($opaqueDataSpec eq FALSE) {
         $vdLogger->Error("SetDVSOpaqueDataConfigSpec for dvs $dvsName failed");
         VDSetLastError("EINLINE");
         return FAILURE;
      }
    my %options = ('KeyedOpaqueData' => $keyedOpaqueData,
                     'Operation' => $operation,
                    );
    my   $dvsOpaqueDataCS = CreateInlineObject(
                               "com.vmware.vc.DVSOpaqueDataConfigSpec");
    if ($dvsOpaqueDataCS eq FALSE) {
         $vdLogger->Error("$dvsOpaqueDataCS for dvs $dvsName failed");
         VDSetLastError("EINLINE");
         return FAILURE;
      }

    foreach my $prop (keys %options) {
         $vdLogger->Debug("setting the prop, $prop with value $options{$prop}");
         my $method = 'set'.$prop;
         $dvsOpaqueDataCS->$method($options{$prop});
      }

    push(@$dvsOpaqueSpecList,$opaqueDataSpec);

    $result = $inlineDVSMgr->UpdateOpaqueData($dvsSelectionSet,
                                             $dvsOpaqueSpecList,
                                             $isRuntime);
    if (!$result) {
         $vdLogger->Error("Failed to update opaque data for $key for dvs $dvsName");
         VDSetLastError("EINLINE");
         return FAILURE;
      }

    return SUCCESS;

}


########################################################################
#
# ConfigurePortRules--
#      This method compile the rule.txt and generate the opaqueData on the host;
#      Then update these configure to vswitch.
#
# Input:
#      dvfilteroperation  : add/remove
#      filters    : filters name
#      adapter    : adapter that set rules on.
#
#
# Results:
#      "SUCCESS", if rules are applied at the port.
#      "FAILURE", in case of any error.
#
# Side effects:
#      none
#
########################################################################

sub ConfigurePortRules
{
   my $self = shift;
   my $args = shift;
   my $result;
   if ((not exists $self->{switch}) ||
       (not exists $args->{dvfilteroperation}) ||
       (not exists $args->{filters}) ||
       (not exists $args->{adapter})) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   my $dvsName = $self->{switch};
   my $operation = eval($args->{dvfilteroperation});
   my $filter = eval($args->{filters});
   my $vnicObj = $args->{adapter};

   if ((not defined $dvsName) ||
       (not defined $operation) ||($operation eq "") ||
       (not defined $filter) ||
       (not defined $vnicObj)) {
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("ENOTDEF");
       return FAILURE;
    }
   $vdLogger->Info("$operation $filter on $dvsName ");

   my $vmIP = $vnicObj->{controlIP};
   my $vmObj = $vnicObj->{vmOpsObj};
   my $hostObj = $vmObj->{hostObj};
   my $hostIP = $hostObj->{hostIP};
   my $portid = $hostObj->GetvNicDVSPortID($vnicObj->{macAddress});
   if ($portid eq FAILURE) {
      $vdLogger->Error("Can't find vds portid for $vnicObj->{macAddress}");
      VDSetLastError("EINVALID");
      return FAILURE;
    }

   my $inlineDVS = $self->GetInlineDVS();
   my $inlineDVSMgr = $self->GetInlineDVSManager();

   my $dvsSS = $inlineDVS->SetDVSSelectionSet(
                                           selectionSet => undef,);
   $dvsSS = CreateInlineObject('com.vmware.vc.DVSSelection');
   my $dvsMor = $self->GetInlineDVS()->{dvsMOR};
   my $dvsuuid= $inlineDVS->{dvs}->getConfig($dvsMor)->getUuid();
   my $dvportSS = $inlineDVS->SetDVPortSelectionSet(
                                           selectionSet => undef,);
   my $dvPortSelectionSet = [];

   # Fill in the DVPortSelectionSet
   $dvportSS->setDvsUuid($dvsuuid);
   # get the port key and provide the same here
   my $arrayList = CreateInlineObject('java.util.ArrayList');
   $arrayList->add(0,$portid);
   $dvportSS->setPortKey($arrayList);
   push(@$dvPortSelectionSet, $dvportSS);
   my $key = $filter.'.ruleset';
   my $dvfilterObj =  VDNetLib::DVFilter::DVFilter->new(
                                           hostobj  => $hostObj,
                                            );

   # compile the rule.txt on the host; generate the opaqueData
   # that need update to vswitch.
   $result = $dvfilterObj->GenerateRulesParserExec($vmIP);
   if ($result eq FAILURE){
      $vdLogger->Error("Failed to generate the .packetRuleset file on host");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $opaqueData = $dvfilterObj->GetOpaqueData($hostIP);
   my %Hash = (
            opaquedata => $opaqueData,
            key        => $key,
            operation       => $operation,
            dvsselectionset => $dvPortSelectionSet,
            );
   return $self->ConfigureFilter(%Hash);
}


########################################################################
#
# GetLACP
#      This method gets lacp status/config/stats for the given vds on
#      a given host.
#
# Input:
#       configmethod - Which configmethod to use, VIM/ESXCLI to
#                      configure LACP(optional)
#       host - host on which to get the lacp info from(mandatory when
#              configmethod=esxcli)
#       infoType - status/config/stats(mandatory when configmethod=esxcli)
#       uplink - info should be about this uplink only(optional)
#
# Results:
#      Hash containing lacp info - in case of SUCCESS.
#      FAILURE in case of error.
#
# Side effects:
#      None.
#
########################################################################

sub GetLACP
{
   my $self         = shift;
   my %args         = @_;
   my $configmethod = $args{configmethod} || "vim";
   my $host         = $args{host};
   my $infoType     = $args{infotype};
   my $uplink       = $args{uplink};
   my $dvsname      = $args{dvsname};
   my ($command, $result, $data);

   my $lacpInfoHash = {};
   $configmethod = "cli"; # Unit testing
   if ($configmethod =~ /(vim|inline|java)/i) {
      # VIM configmethod Part of GetLACP
   } else {

      if ($infoType !~ /(status|stats|config)/i) {
         $vdLogger->Error("Unsupported lacp info $infoType requested");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      my $command = ESXCLI_LACP . " get " . $infoType;
      my $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
      if ($result->{rc} != 0) {
          $vdLogger->Error("Failed to execute command $command on " . $host);
          VDSetLastError("ESTAF");
          return FAILURE;
      }
      my $data = $result->{stdout};
      my @tmp = split(/(\n+)/, $data);
      if ($infoType =~ /config/i) {
         #
         # We dont need the first two lines of stdout
         # ~ # esxcli network vswitch dvs vmware lacp get config
         # DVS Name           LAG ID  NICs                  Enabled  Mode
         # -----------------  ------  --------------------  -------  ----
         # vdswitch-0-1-1695       0  vmnic1,vmnic2,vmnic3    false
         # vdswitch-1-1-1695       0                          true   Active
         # vdswitch-2-1-1695       0  vmnic4                  true   Passive
         #
         for my $line (@tmp){
            if ($line !~ /(true|false)/i) {
               next;
            }
            if ((defined $dvsname) && ($line !~ /$dvsname/i)) {
               #
               # If dvs name is defined then it means user is only
               # interested to know the config of that switch
               #
               next;
            }
            my @lacpInfo = split(/\s+/, $line);
            $lacpInfoHash->{$lacpInfo[0]}->{dvsname} = $lacpInfo[0];
            $lacpInfoHash->{$lacpInfo[0]}->{lagid} = $lacpInfo[1];
            if ($lacpInfo[2] =~ /vmnic/i) {
               $lacpInfoHash->{$lacpInfo[0]}->{nics} = $lacpInfo[2];
               $lacpInfoHash->{$lacpInfo[0]}->{enabled} = $lacpInfo[3];
               $lacpInfoHash->{$lacpInfo[0]}->{mode} = $lacpInfo[4] || undef;
            } else {
               $lacpInfoHash->{$lacpInfo[0]}->{nics} =  undef;
               $lacpInfoHash->{$lacpInfo[0]}->{enabled} = $lacpInfo[2];
               $lacpInfoHash->{$lacpInfo[0]}->{mode} = $lacpInfo[3] || undef;
            }
         }
      }
      if ($infoType =~ /status/i) {
         #
         # dvs
         #   DVSwitch: dvs
         #   Flags: S - Device is sending Slow LACPDUs,
         #          F - Device is sending fast LACPDUs,
         #          A - Device is in active mode,
         #          P - Device is in passive mode
         #   LAGID: 55555
         #   Mode: Active
         #   Nic List:
         #    Local Information:
         #         Admin Key: 7
         #         Flags: FA
         #         Oper Key: 7
         #         Port Number: 2
         #         Port Priority: 255
         #         Port State: ACT,FTO,AGG,SYN,COL,DIST,
         #         Nic: vmnic3
         #         Partner Information:
         #         Age: 00:00:03
         #         Device ID: 00:04:96:34:c8:4f
         #         Flags: SA
         #         Oper Key: 1039
         #         Port Number: 1039
         #         Port Priority: 0
         #         Port State: ACT,AGG,SYN,COL,DIST,
         #         State: Bundled
         #
         #
         # First split the data according to DVSwitch
         # All DVSwitches will have lagID associated to them
         # Read the DVSwitch name in $vds and read the lagID
         # now split the list of nics based on Location Information
         # and store
         #
         my @switches = split(/(DVSwitch:)/, $data);
         foreach my $str (@switches) {
            if ($str  =~ /Local Information/i) {
               $str =~ /(.*)/;
               my $vds = $1;
               $vds =~ s/^\s+|\s+$//g;
               $str =~ /LAGID: (\d+)/;
               my $lagID = $1;
               my @nics = split(/(Local Information:)/, $str);

               foreach my $str (@nics) {
                  if ($str  =~ /nic: (.*)/i) {
                     my $nic = $1;
                     if ((not defined $vds) || ($vds eq "") ||
                         (not defined $lagID) || ($lagID eq "") ||
                         (not defined $nic) || ($nic eq "")) {
                        $vdLogger->Error("Not able to find vds or lagID or nic:".
                                         Dumper($data));
                        VDSetLastError("EINLINE");
                        return FAILURE;
                     }
                     # If user is interested only in specific nic then just
                     # find that nic
                     if ($nic !~ /$uplink/i) {
                        next;
                     }
                     my @lines = split(/\n/, $str);
                     foreach my $line (@lines) {
                        my ($key , $value) = split(/:/, $line);
                        if ((defined $key) && ($key =~ /(\S+)/)){
                          $key =~ s/^\s+|\s+$//g;
                          $value =~ s/^\s+|\s+$//g if defined $value;
                          $lacpInfoHash->{$vds}->{$lagID}->{$nic}->{$key} =
                                                                $value || undef;
                        }
                     } # end of foreach lines
                  }
               } # end of foreach nics
            } else {
               next;
            }
         } # end of foreach @switches
      }
      if ($infoType =~ /stats/i) {
         #
         # We dont need the first two lines of stdout
         # ~ # esxcli network vswitch dvs vmware lacp get stats
         # DVSwitch  LAGID  NIC     Rx Errors  Rx LACPDUs  Tx Errors  Tx LACPDUs
         # --------  -----  ------  ---------  ----------  ---------  ----------
         # test-2        0  vmnic3          0           0          0         142
         # test-2        0  vmnic2          0           0          0         142
         # test-2        0  vmnic1          0           0          0         142
         #
         for my $line (@tmp){
            if ($line !~ /(vmnic)/i) {
               # we are only interested in lines which show true/false
               # as per the stdout above.
               next;
            }
            my @lacpInfo = split(/\s+/, $line);
            # If user is interested only in specific nic then just
            # find that nic
            if ($lacpInfo[2] !~ /$uplink/i) {
               next;
            }
            my $vmnic = $lacpInfo[2];
            $lacpInfoHash->{$vmnic}->{dvsname} = $lacpInfo[0];
            $lacpInfoHash->{$vmnic}->{lagid} = $lacpInfo[1];
            $lacpInfoHash->{$vmnic}->{nic} = $vmnic || undef;
            $lacpInfoHash->{$vmnic}->{'Rx Errors'} = $lacpInfo[3];
            $lacpInfoHash->{$vmnic}->{'Rx LACPDUs'} = $lacpInfo[4];
            $lacpInfoHash->{$vmnic}->{'Tx Errors'} = $lacpInfo[5];
            $lacpInfoHash->{$vmnic}->{'Tx LACPDUs'} = $lacpInfo[6];
        }
      }
      return $lacpInfoHash;
   }

   return SUCCESS;
}


########################################################################
#
# SetLACP
#      this method sets lacp enable/disable and lacp mode for the
#      given vds.
#      LagID and Uplinks inputs are optional params which user can pass
#      for negative testing. VIM configmethod does not take those params
#      thus for negative testing user will have to use esxcli
#
# Input:
#       configmethod - Which configmethod to use, VIM/CLI to
#                      configure LACP(optional)
#       operation - enable/disable (mandatory)
#       mode - passive/active (mandatory when operation is enable,
#                              optional otherwise)
#       lagID - lagID to create a LAG (optional)
#       uplinks - uplinks which can join the LAG(optional)
#
# Results:
#      SUCCESS in case of SUCCESS.
#      FAILURE in case of error.
#
# Side effects:
#      None.
#
########################################################################

sub SetLACP
{

   my $self         = shift;
   my %args         = @_;
   my $configmethod = $args{configmethod} || "vim";
   my $host         = $args{host};
   my $operation    = $args{operation};
   my $mode         = $args{mode};
   my ($command, $result);

   #
   # This means users wants to use cli to set LACP
   # We setLACP to enable/disable as per user request.
   # We then again GetLACP to verify.
   #
   if ($operation =~ /enable/i) {
      # to enable using cli
      $operation = "1";
      if ($mode =~ /active/i) {
         $mode = "1"; # active mode
      } else {
         $mode = "2"; # passive mode
      }
   } else {
      # to disable using cli
      $operation = "0";
      $mode = "0";
   }

   #
   # Sample lacp set command
   # ~ # net-dvs --setLACP 11 vdswitch-0-1-1197
   #
   $command = NET_DVS . " --setLACP 'v1*" . $operation . ";" . $mode . ";'" .
              " $self->{switch} ";
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if (($result->{rc} != 0) || ($result->{stderr} ne "")) {
       $vdLogger->Error("Failed to execute command $command on $host:" .
                         Dumper($result));
       VDSetLastError("ESTAF");
       return FAILURE;
   }
   return SUCCESS;

}


###############################################################################
#
# AddRemoveVDSUplink --
#      This method adds given uplinks into VDS
#
# Input:
#      Operation         -   add or remove(mandatory)
#      pnic              -   pNIC to be added or removed(mandatory)
#      hostAnchor        -   host anchor required for staf command(mandatory)
#      hostIP            -   IP of host on which pNIC resides(mandatory)
#
# Results:
#      Returns "SUCCESS", if success.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub AddRemoveVDSUplink
{
   my $self         = shift;
   my %args         = @_;
   my $operation    = $args{operation};
   my $pNIC         = $args{vmnic};
   my $hostAnchor   = $args{anchor};
   my $hostIP       = $args{hostIP};

   my $vdsname      = $self->{switch};
   my $vcObj        = $self->{vcObj};
   my $proxy        = $vcObj->{proxy};
   my $result;
   my $command;

   if ((not defined $operation) || (not defined $vdsname) ||
       (not defined $pNIC) || (not defined $hostAnchor) ||
       (not defined $hostIP)) {
      $vdLogger->Error("One or more params missing in AddVDSUplink()".
                        Dumper(@_));
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ($operation =~ /add/i) {
      $operation = "BINDPNICSTODVS";
      $vdLogger->Info("Uplinking pnic:$pNIC of host:$hostIP to vds:$vdsname");
   } else {
      $operation = "UNBINDPNICSFROMDVS";
      $vdLogger->Info("Removing pnic:$pNIC of host:$hostIP from vds:$vdsname");
   }
   $command = " $operation anchor $hostAnchor dvsname \"$vdsname\" ".
              "host $hostIP pnics $pNIC ";
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
   if (((defined $result->{rc}) && ($result->{rc} != 0)) ||
       ((defined $result->{exitCode}) && ($result->{exitCode} != 0))) {
      $vdLogger->Error("Fail to add/remove pnic($pNIC) ".
                       "into vds($vdsname):" . Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}


###############################################################################
#
# AddMultipleHostsToVDS--
#      This method would add multiple esx host to the VDS.
#
# Input:
#      $arrHostVmnicMapping - The input would be in two format:
#                   1. Just reference to array containing host objets
#                   2. Reference to array which will have following values
#                      Ref to array = [
#                                      {
#                                        'hostObj'  => reftohostObj1,
#                                        'vmnicObj' => ["reftoVmnic1",
#                                                       "reftoVmnic2"]
#                                      }
#                                      {
#                                        'hostObj'  => reftohostObj2,
#                                        'vmnicObj' => ["reftoVmnic1",
#                                                       "reftoVmnic2"]
#                                      }
#                                     ]
#
# Results:
#    Returns SUCCESS if adding host to vds is successfull.
#
# Side effects:
#      None.
#
###############################################################################

sub AddMultipleHostsToVDS
{
   my $self                = shift;
   my $refArrHostVmnicMapping = shift;

   # check the values passed.
   if (not defined $refArrHostVmnicMapping) {
      $vdLogger->Error("Reference to host not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $inlineDVS = $self->GetInlineDVS();
   if (!$inlineDVS->AddMultipleHostsToVDS($refArrHostVmnicMapping)) {
      $vdLogger->Error("Failed to Add hosts into dvs.");
      VDSetLastError("EINLINE");
      return FAILURE;
   } else {
      $vdLogger->Debug("Succeeded to add multiple hosts into dvs.");
   }
   return SUCCESS;
}


###############################################################################
#
# AddHostToVDS--
#      This method would add esx host to the VDS.
#
# Input:
#      hostObj          - Host obj to operate on
#      vmnic            - An array of vmnic objects which will be added as
#                         uplinks of the VDS.
#
#
# Results:
#    Returns SUCCESS if adding host to vds is successfull.
#
# Side effects:
#      None.
#
###############################################################################

sub AddHostToVDS
{
   my $self     = shift;
   my %args     = @_;
   my $hostObj  = $args{hostObj};
   my $vmnic    = $args{vmnic}; # an array to vmnicObj

   my $dcname   = $self->{'datacenter'};
   my $vdsName  = $self->{'switch'};
   my $tag      = "VCOperation : AddHostToVDS : ";
   my $vcObj    = $self->{vcObj};
   my $proxy    = $vcObj->{proxy};
   my $vc       = $vcObj->{vcaddr};
   my $command;
   my $result;

   # check the values passed.
   if ((not defined $hostObj) && (not defined $vdsName)) {
      $vdLogger->Error("Either $tag host or vdsname not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # command to add host to vds.
   $command = " addhosttodvs anchor ". $vcObj->{hostAnchor};
   $command = " $command host " . $hostObj->{'hostIP'} . " dvsname " . $vdsName;
   if ((defined $vmnic) && (scalar @$vmnic)) {
      my @adapterList;
      foreach my $adapter (@$vmnic) {
         push @adapterList, $adapter->{'vmnic'};
      }
      $command = " $command pnics " . join(',', @adapterList) . " MAXPROXYSWITCHPORTS 128 ";
   } else {
      $command = " $command nopnics MAXPROXYSWITCHPORTS 128 ";
   }
   $command = " $command dcname $dcname ";
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to add host to vds failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Host ($hostObj->{'hostIP'}) added to ($vdsName)" .
                   " in DC ($dcname).");
   return SUCCESS;
}


###############################################################################
#
# RemoveHostsFromVDS --
#      This method will remove hosts from VDS
#
# Input:
#      hostObjs             -   reference to array of hostObj
#
# Results:
#      Returns "SUCCESS", if removed.
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub RemoveHostsFromVDS
{
   my $self            = shift;
   my $refArrayObjHost = shift;
   my $vdsName         = $self->{'switch'};
   my $vcObj           = $self->{vcObj};
   my $proxy           = $vcObj->{proxy};
   my $cmd;
   my $result;


   if ((not defined $vdsName) && (not defined $refArrayObjHost)) {
      $vdLogger->Error("Either VDS name or Host object not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   foreach my $hashRef (@$refArrayObjHost) {
      my $tmpip = $hashRef->{hostObj}->{hostIP};
      $vdLogger->Info("Begin to remove host($tmpip) from VDS($vdsName)..");
      $cmd = " RMHOSTFROMDVS anchor ".$vcObj->{hostAnchor}." HOST ".$tmpip.
             " DVSNAME \"".$vdsName."\"";
      $vdLogger->Info("Run command : $cmd");
      $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$cmd);
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failure to remove host($tmpip) from ".
                          "VDS ($vdsName)" . Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# ConfigureVDSUplink --
#     This method set vds uplink.
#
# Input:
#     vdsuplink   - the given vds uplink number to be set.
#
# Results:
#     "SUCCESS",if set vds uplink works fine
#     "FAILURE",in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ConfigureVDSUplinkPorts
{
   my $self = shift;
   my %args = @_;
   my $vdsuplink = $args{vdsuplink};
   my $result = undef;

   my $inlineVCSession = $self->{vcObj}->GetInlineVCSession();
   $result = $inlineVCSession->LoginVC();
   if (!$result) {
      $vdLogger->Error("Failed to login VC $self->{vcObj}->{vcaddr}");
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   my $inlineDVS  = $self->GetInlineDVS();
   $result = $inlineDVS->ConfigureVDSUplinkPorts(vdsuplink => $vdsuplink);
   if (!$result) {
      $vdLogger->Error("Failed to set vds uplink " .
                       "$self->{switch} ");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# AddLinkAggregationGroup
#      This method adds LACPv2 LAG on VDS
#
# Input:
#      Array of lag specs. Each spec may contain one or all of these:
#      lagname
#      lagmode
#      lagloadbalancing
#      lagvlantype
#      lagvlantrunkrange
#      lagnetflow
#      lagports
#
# Results:
#      array of lagObjects, if lags are creation successfully
#      "FAILURE", in case of any error,
#
# Side effects:
#      the mirror session gets created for the vds.
#
########################################################################

sub AddLinkAggregationGroup
{
   my $self = shift;
   my $arrayOfSpecs = shift;
   my (@arrayOfLAGObjects);

   foreach my $element (@$arrayOfSpecs) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("LAG spec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my %options = %$element;
      my ($lacpGroupConfig, $lagObject);
      #
      # 1) Create a vdnet LAG.pm vdnet Object
      # 2) Call AddLinkAggregationGroup using Inline Java
      # 3) return the vdnet lag object.
      #
      $options{switchObj} = $self;
      $options{stafHelper} = $self->{stafHelper};
      $lagObject = VDNetLib::InlineJava::InlineLAG->new(%options);
      if (not defined $lagObject) {
         $vdLogger->Error("Not able to create VDNetLib::Switch::VDSwitch::LAG obj");
         VDSetLastError("EFAILED");
         return FAILURE;
      }

      # For LACPv1, there is a default lag. For v2, we have to create one.
      if ($lagObject->{lacpversion} =~ /multiplelag/i) {
         $vdLogger->Debug("Lag Object is created, now creating lag physically");
         my $inlineDVSObj = $self->GetInlineDVS();
         my $ret = $inlineDVSObj->ConfigureInlineLAG($lagObject, "add");
         if ((not defined $ret) || ($ret == 0)) {
            $vdLogger->Error("Add InlineLAG for $lagObject->{lagname} failed");
            VDSetLastError("EFAILED");
            return FAILURE;
         } else {
            $vdLogger->Debug("Successfully add InlineLAG for $lagObject->{lagname}");
         }

         #
         # After creating lag we need to get lag spec from VDS
         # and read lagid assigned by system to the lag we created.
         # We set the lagid in vdnet object which is required for
         # consequtive add/delete operations on that lag
         #
         my $groupConfig = $inlineDVSObj->GetLagGroupConfigFromVDS($lagObject->{lagname});
         if (not defined $groupConfig) {
            $vdLogger->Error("Not able to get laggroupconfig for $lagObject->{lagname}");
            VDSetLastError("EINVALID");
            return FAILURE;
         }
         $lagObject->SetLagId($groupConfig->getKey());
      }

      $vdLogger->Info("Added lag:$lagObject->{lagname} to VDS:$self->{switch}");
      push(@arrayOfLAGObjects, $lagObject);
   }
   return \@arrayOfLAGObjects;
}


########################################################################
#
# DeleteLinkAggregationGroup
#      This method deletes LACPv2 LAG on VDS
#
# Input:
#      Array of lagObject (mandatory) - which needs to be deleted
#
# Results:
#      "SUCCESS", if lag is deleted
#      "FAILURE", in case of any error,
#
# Side effects:
#
########################################################################

sub DeleteLinkAggregationGroup
{
   my $self = shift;
   my $arrayOfLAGObjects = shift;

   foreach my $lagObject (@$arrayOfLAGObjects) {
      if ($lagObject->{lacpversion} =~ /multiplelag/i) {
         my $inlineDVSObj = $self->GetInlineDVS();
         my $ret = $inlineDVSObj->ConfigureInlineLAG($lagObject, "remove");
         if ((not defined $ret) || ($ret == 0)) {
            $vdLogger->Error("Delete InlineLAG for $lagObject->{lagname} failed");
            VDSetLastError("EFAILED");
            return FAILURE;
         }
         $vdLogger->Info("Deleted lag:$lagObject->{lagname} from VDS:$self->{switch}");
      }
   }
   return SUCCESS;
}


########################################################################
#
# GetDVSPortIDForAnyNIC --
#     Method to get DVS port ID for
#     1) vmknic or
#     2) Virtual machine's vnic or
#     3) vmnic
#     For finding the vnic's port id we need to know the VM's name and
#     the ethX associated with the vnic. E.g.
#              Client: 2-rhel53-srv-32-local-18453.eth0
#              DVPortgroup ID: dvportgroup-1129
#              In Use: true
#              Port ID: 9
#
# Input:
#     <client> - Either a vmknic or vNic
#
# Results:
#     A valid port (integer), if success.
#     "FAILURE" in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetDVSPortIDForAnyNIC
{
   my $self    = shift;
   my $hostObj = shift;
   my $client  = shift;
   my $dvsname = $self->{'switch'};
   if (not defined $client) {
      $vdLogger->Error("input params misisng");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   #
   # The dvs port ID can be found from the field "Port ID:"
   # esxcli network vswitch dvs vmware list -v VDS_NAME
   #
   #      Client: vmk6
   #      DVPortgroup ID: dvportgroup-1126
   #      In Use: false
   #      Port ID: 2

   #      Client: vmnic1
   #      DVPortgroup ID: dvportgroup-1126
   #      In Use: true
   #      Port ID: 3

   #      Client: 1-rhel53-srv-32-local-18453.eth0
   #      DVPortgroup ID: dvportgroup-1128
   #      In Use: true
   #      Port ID: 5
   #

   my $command;
   $command = "esxcli network vswitch dvs vmware list -v $dvsname ".
              "| grep -ri -A 4 $client";
   my $result = $self->{stafHelper}->STAFSyncProcess($hostObj->{hostIP},
	                                             $command);
   # check for success or failure of the command
   if ($result->{rc} != 0) {
      $vdLogger->Error("command: $command on host $hostObj->{hostIP} failed".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($result->{stdout} !~ /Port ID: (\d+)/i) {
      $vdLogger->Error("command:$command failed with" . Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return $1; # $1 is the string captured at the above regex
}


########################################################################
#
# GetInlineDVSManager --
#     Method to create an object of VDNetLib::InlineJava::DVSManager
#     based on the DVS attributes
#
# Input:
#     None
#
# Results:
#     return value of new() from VDNetLib::InlineJava::DVSManager
#
# Side effects:
#     None
#
########################################################################

sub GetInlineDVSManager
{
   my $self = shift;
   my $inlineVCSession = $self->{vcObj}->GetInlineVCSession();
   my $inlineVCAnchor = $inlineVCSession->{'anchor'};
   return VDNetLib::InlineJava::DVSManager->new(
                                          'anchor' => $inlineVCAnchor,
                                           'datacenter' => $self->{datacenter},
                                           'dvsName'   => $self->{switch}
                                          );
}


########################################################################
#
# GetInlineDVS --
#     Method to create an object of VDNetLib::InlineJava::DVS
#     based on this VDS attributes
#
# Input:
#     None
#
# Results:
#     return value of new() from VDNetLib::InlineJava::DVS
#
# Side effects:
#     None
#
########################################################################

sub GetInlineDVS
{
   my $self = shift;
   my $inlineVCSession = $self->{vcObj}->GetInlineVCSession();
   my $inlineVCAnchor = $inlineVCSession->{'anchor'};
   return  VDNetLib::InlineJava::DVS->new(
                                          'anchor' => $inlineVCAnchor,
                                          'datacenter' => $self->{datacenter},
                                          'dvsName'   => $self->{switch}
                                          );

}


########################################################################
#
# ConfigureNIOCTraffic --
#     Method to configure NIOC infrastructure traffic
#     with shares, limits and reservation
#
# Input:
#     trafficClassSpec: reference to hash of hash containing following keys
#                        virtualMachine => {
#                           reservation =>
#                           shares      =>
#                           limits      =>
#                        },
#                        ft => {
#                           reservation =>
#                           shares      =>
#                           limits      =>
#                        },
#                        Other supported infrstructure types are
#                        nfs, iscsi, vsan, hbr
#
# Results:
#     1, if configured successfully;
#     0, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigureNIOCTraffic
{
   my $self             = shift;
   my $trafficClassSpec = shift;

   my $inlineDVS = $self->GetInlineDVS();
   if (!$inlineDVS->ConfigureNIOCInfrastructureTraffic($trafficClassSpec)){
      $vdLogger->Error("Failed to configure NIOC");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return SUCCESS;
}


###############################################################################
#
# EnableDisableVXLAN --
#      This method will enable/disable vdl2 on a dedicated virtual switch.
#
# Input:
#      VDS name              -   VDS name
# Results:
#      Returns SUCCESS, if enabled.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub EnableDisableVXLAN
{
   my $self          = shift;
   my $operation     = shift;
   my $vcObj         = $self->{vcObj};
   my $vdsname       = $self->{'switch'};
   my $vcaddr        = $vcObj->{vcaddr};
   my $vcuser        = $vcObj->{user};
   my $vcpass        = $vcObj->{passwd};
   my $gConfig       = new VDNetLib::Common::GlobalConfig();
   my $cfgToolsDir   = $gConfig->GetVDL2ConfigToolPath();
   my $result;
   my $command;
   $vcpass =~ s/\$/\\\$/;

   # sync up VDL2 configuration tool
   $result = $vcObj->SyncVDL2ConfigTool();
   if ($result eq "FAILURE") {
      $vdLogger->Error("Sync up VDL2 config tool failed");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my @name = split /,/, $vdsname;
   for my $tmpname (@name) {
      $command = "java -jar $cfgToolsDir/lib/vdl2.jar";
      if ($operation =~ /enable/i) {
         $command = $command  . " enableVdl2 ";
      } else {
         $command = $command  . " disableVdl2 ";
      }
      $command = $command  . " $tmpname $vcaddr $vcuser $vcpass";
      $vdLogger->Debug(" Call java program : command = $command");
      $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);
      if ( ($result->{rc} != 0) or ($result->{exitCode} != 0) or
           ($result->{stdout} =~ /error|fail|can't/i) ) {
         $vdLogger->Error("STAF command to call java program failed".
                       Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      } elsif ($result->{stdout} =~ /success/i) {
         $vdLogger->Info("VXLAN " . $operation . "d on $tmpname");
         $vdLogger->Trace("VXLAN " . $operation . "d result : ".
                          $result->{stdout});
      } else {
         $vdLogger->Error("Invalid VDL2 configuration result ".
                       Dumper($result));
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }
   return SUCCESS;
}


#############################################################################
#
# GetMORId--
#     Method to get the Switch's Managed Object Ref ID.
#
# Input:
#
# Results:
#     switchMORId, when pass
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub GetMORId
{
   my $self   = shift;
   my $morId;

   my $inlineDVS = $self->GetInlineDVS();
   if (!($morId = $inlineDVS->GetMORId())){
      $vdLogger->Error("Failed to get DVS MOR ID for $self->{switch}");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $vdLogger->Debug("Managed Object Ref ID for this VDS :". $self->{switch} .
                    " is MORId:". $morId);
   return $morId;
}

#######################################################################
#
# ConfigureIpfix --
#  This method would configure the dvs netflow.
#
# Input:
#  A hash with the following values:
#  ipfix	: Add or remove the ipfix configuration,required
#  collector	: Vnic object of the ipfix collector,required
#  addressFamily: ipv6 or ipv4,if set to ipv6, use the ipv6 address of
#                 the collector,else use the ipv6 address,required
#  activetimeout: The time after which active flows are automatically
#                 exported to the ipfix collector.default is 60 seconds,
#                 required.
#  idletimeout	: The time after which idle flows are automatically
#                 exported to the ipfix collector, the default is 15
#                 seconds,required.
#  samplerate	: The Ipfix will sample a packet per samplerate,required
#  vdsip	: Parameter to specify the (IPv4 )ip address of the vds,
#                 optional.
#  collectorport: port for the ipfix collector,optional.
#  domainid	: Parameter to specify the IPv6 domain ID of the vds,
#                 optional.
#  internalonly : If set to true the traffic analysis would be limited
#                 to the internal traffic i.e. same host. The default
#                 is false,optional.
#
# Results:
#		 "SUCCESS", if configure successfully
#		 "FAILURE", in case of any error,
#
# Side effects:
#		 None.
#######################################################################

sub ConfigureIpfix
{
   my $self = shift;
   my %args = @_;
   my $ipfix = $args{ipfix};
   my $collector = $args{collector};
   my $addressFamily = $args{addressfamily};
   my $activeTimeout = $args{activetimeout};
   my $idleTimeout = $args{idletimeout};
   my $sampleRate = $args{samplerate};
   my $vdsIP = $args{vdsip} ||
                  VDNetLib::Common::GlobalConfig::VDNET_VDS_IP_ADDRESS;
   my $collectorPort = $args{collectorport} ||
                  VDNetLib::Common::GlobalConfig::NETFLOW_COLLECTOR_PORT;
   my $domainID = $args{domainid} ||
                  VDNetLib::Common::GlobalConfig::NETFLOW_DOMAIN_ID;
   my $internalOnly = $args{internalonly} || 0;
   my $switchObj = $self->{switchObj};
   my $result;
   my $collectorIP;
   my $findFlag = 0;
   my $testIPv6;

   # IPv6 doesn't have the vdsIP field
   if ($addressFamily eq "ipv6") {
      $collectorIP = $collector->GetIPv6Global();
      foreach my $testip (@$collectorIP) {
         if ($testip eq "NULL") {
            last;
         } elsif ($testip =~ m/^2001:bd6/i) {
            $testIPv6 = $testip;
            $findFlag = 1;
            last;
         }
      }
      if (!$findFlag) {
         $vdLogger->Error("Can't find IPv6 address for the collector");
         return FAILURE;
      }
      if ($testIPv6 =~ m/\//i) {
         my @tempIP = split(/\//, $testIPv6);
         $testIPv6 = $tempIP[0];
      }
      $vdsIP = undef;
   } else {
      # IPv4 doesn't have the domain ID field
      $collectorIP = $collector->GetIPv4();
      $domainID = undef;
   }
   $vdLogger->Debug("Ipfix collector's IP address is $testIPv6");
   my $inlineDVS = $self->GetInlineDVS();
   if (!$inlineDVS->ConfigureIpfix(
                              collectorip => $testIPv6,
                              internal => $internalOnly,
                              idletimeout => $idleTimeout,
                              collectorport => $collectorPort,
                              activetimeout => $activeTimeout,
                              samplerate => $sampleRate,
                              vdsip => $vdsIP,
                              domainid => $domainID)){
      $vdLogger->Error("Failed to configure Ipfix");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# ConfigureMulticastFilteringMode --
#     Method to configure multicast filtering mode on vmwar dvs.
#
# Input:
#     multicastFilteringMode - legacyFiltering/snooping (required)
#
# Results:
#     SUCCESS, if configured successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigureMulticastFilteringMode
{
   my $self                    = shift;
   my $multicastFilterringMode = shift;

   my $inlineDVS = $self->GetInlineDVS();
   if (!$inlineDVS->SetMulticastFilteringMode($multicastFilterringMode)) {
      $vdLogger->Error("Failed to configure multicast filtering mode");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# ConfigureNIOC
#      This method enable/disable NIOC feature in specified VDS.
#
# Input:
#      state: enable or disable NIOC
#      version: NIOC version(version2/version3)
#
# Results:
#      "SUCCESS", if success,
#      "FAILURE", in failed.
#
# Side effects:
#      none
#
#########################################################################

sub ConfigureNIOC
{
  my $self = shift;
  my $state = shift;
  my $version = shift;

  my $inlineDVS = $self->GetInlineDVS();
  if (!$inlineDVS->ConfigureNIOC($state,$version)) {
      $vdLogger->Error("Failed to configure NIOC in VDSwitch");
      VDSetLastError("EINLINE");
      return FAILURE;
  }
  return SUCCESS;
}


########################################################################
#
# SetSecurityPolicy
#     Method to enable/disable portgroup security policy change on the DVS
#
# Input:
#      securitypolicy : enable or disable(required)
#      virtualwire    : virtual wire object used to get id(required)
#      policytype     : ALLOW_PROMISCUOUS, MAC_CHANGE or FORGE_TRANSMITS
#                          (required)
#
# Results:
#      "SUCCESS", if success,
#      "FAILURE", in failed.
#
# Side effects:
#      none
#
#########################################################################

sub SetSecurityPolicy
{
   my $self   = shift;
   my %args   = @_;
   my $flag   = $args{securitypolicy} || "enable";
   my $vWire  = $args{virtualwire};
   my $securitypolicy = $args{policytype};
   my $enable;
   my $policy;
   if ((lc($flag) ne "enable") && (lc($flag) ne "disable")) {
      $vdLogger->Error("unknown policy flag: $flag");
      VDSetLastError(VDGetLastError);
      return FAILURE;
   }
   if ((lc($securitypolicy) ne lc(VDNetLib::TestData::TestConstants::ALLOW_PROMISCUOUS)) &&
       (lc($securitypolicy) ne lc(VDNetLib::TestData::TestConstants::MAC_CHANGE)) &&
       (lc($securitypolicy) ne lc(VDNetLib::TestData::TestConstants::FORGE_TRANSMITS))) {
      $vdLogger->Error("unknown policy: $securitypolicy");
      VDSetLastError(VDGetLastError);
      return FAILURE;
   }

   my $tag       = "VDSwitch : SetSecurityPolicy : ";
   my $vds       = $self->{switch};
   my $vWireId   = $vWire->{id};
   my $inlineDVS = $self->GetInlineDVS();
   my $dvsMor    = $inlineDVS->{dvsMOR};
   my $dvPg      = $inlineDVS->GetVirtualWirePortGroupName($vWireId, $vds);
   if (not defined $dvPg) {
      $vdLogger->Error("cannot find a portgroup related with vds $vds");
      VDSetLastError(VDGetLastError);
      return FAILURE;
   }
   $vdLogger->Info("Will configure $policy change policy on dvs " .
                   "$vds portgroup $dvPg");

   my $inlineDVPG = VDNetLib::InlineJava::Portgroup::DVPortgroup->new(
                                                                  'name'        => $dvPg,
                                                                  'switchObj'   => $inlineDVS
                                                                  );
   my $result = $inlineDVPG->ConfigPortGroupSecurityPolicy($securitypolicy, $flag);
   if ($result eq "FALSE") {
      $vdLogger->Error("invoke inlineJava to reconfigure port group security policy failed!");
      VDSetLastError(VDGetLastError);
      return FAILURE;
   }
   return SUCCESS;
}

########################################################################
#
# ConfigureLLDPIPv6Addr --
#     Method to configure IPv6 address advertised by LLDP.
#
# Input:
#     lldpipv6addr - the IPv6 address advertised out(required)
#     sourcehost - the host sends out the LLDP information(required)
#
# Results:
#     SUCCESS, if configured successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ConfigureLLDPIPv6Addr
{
   my $self         = shift;
   my %args         = @_;
   my $lldpipv6addr = $args{lldpipv6addr};
   my $sourcehost   = $args{sourcehost};

   my $result =
      $sourcehost->ConfigureLLDPIPv6Addr($self,$lldpipv6addr);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to configure
                       IPv6 address advertised by LLDP ");
      return FAILURE;
   }
   return SUCCESS;
}

1;
