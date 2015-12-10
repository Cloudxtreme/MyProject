########################################################################
#  Copyright (C) 2015 VMware, Inc.
#  All Rights Reserved
########################################################################

package VDNetLib::TORGateway::TORGateway;
use strict;
use warnings;
use Data::Dumper;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sshSession OVS_VS_CTL
                                      OVS_VTEP_CTL OVS_VTEP_BIN);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use base qw(VDNetLib::Root::Root VDNetLib::VM::ESXSTAFVMOperations);
use vars qw{$AUTOLOAD};
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              Boolean
                                              ConfigureLogger);
use VDNetLib::Switch::TORSwitch::TORSwitch;
use VDNetLib::NetAdapter::Pnic::PIF;
use constant VTEP_CONFIG_FILE => "/etc/default/openvswitch-vtep";


########################################################################
#
# new --
#     Constructor to create an instance of this class
#
# Input:
#     named hash parameter with following keys:
#     hostOpsObj  : reference to host object
#
# Results:
#     bless hash reference to instance of this class
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class = shift;
   my %args = @_;
   my $self = {};
   ## point to the python class of torgateway
   $self->{ip}       = $args{ip};
   $self->{username} = $args{username};
   $self->{password} = $args{password};
   $self->{build}    = $args{build};
   $self->{_pyclass}  = 'vmware.torgateway.torgateway_facade.TORGatewayFacade';
   $self->{_pyIdName} = 'id_';

   bless $self;
   return $self;
}


########################################################################
#
# DiscoverPIF --
#     Method to discover physical nics on the KVM host
#
# Input:
#     nicsSpec: Reference to an array of hash with each hash containing following
#     keys:
#               interface : <eth0>
#
# Results:
#     Adapter object array for a successful operation;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub DiscoverPIF
{
   my $self     = shift;
   my $nicsSpec = shift;

   my @arrayOfVNicObjects;

   foreach my $element (@$nicsSpec) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("nicSpec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my %args = %$element;
      # Create vdnet vnic object and store it in array of vnicobjects
      $args{controlIP}  = $self->{ip};
      $args{hostObj} = $self;
      $args{noDriver} = 1;
      my $vnicObj = VDNetLib::NetAdapter::Pnic::PIF->new(%args);
      if ($vnicObj eq "FAILURE") {
         $vdLogger->Error("Failed to initialize vnic obj on VM: $self->{vmx}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      push @arrayOfVNicObjects, $vnicObj;
   }
   return \@arrayOfVNicObjects;
};

#####################################################################
#
# GetInlinePyObject --
#     Methd to get Python equivalent object of this class
#
# Input:
#     None
#
# Results:
##     Reference to Inline Python object of this class
#
# Side effects:
#     None
#
#######################################################################

sub GetInlinePyObject
{
   my $self = shift;
   my $inlinePyObj;
   eval {
      $inlinePyObj = CreateInlinePythonObject($self->{_pyclass},
                                              $self->{ip},
                                              $self->{username},
                                              $self->{password});
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while creating " .
                       "inline component of $self->{_pyclass}:\n". $@);
      return FAILURE;
   }
   if (exists $self->{id}) {
      $inlinePyObj->{id} = $self->{id};
   }
   return $inlinePyObj;
}


######################################################################
#
# get_tor_emulator_bfd_params --
#     Method to get tor emulator BFD config parameters
#
# Input:
#     serverForm : hash generate from userData, like
#                   {
#                     'bfd_enabled_unique_count: undef
#                     'bfd_state_up_unique_count: undef
#                     'bfd_remote_state_up_unique_count: undef
#                   }
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub get_tor_emulator_bfd_params
{
   my $self           = shift;
   my $serverForm     = shift;
   my $resultHash = {
     'status'      => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };
   my $errorInfo  = undef;

   my $command = OVS_VTEP_CTL . " list tunnel";
   my $torIP = $self->{vmIP};
   my $result = $self->{stafHelper}->STAFSyncProcess($torIP,
                                                      $command);

   # check for success or failure of the command executed using staf
   if (($result->{rc} != 0) || ($result->{exitCode})) {
       $vdLogger->Error("Failed to get TOR gateway vtep tunnel info
                         on $torIP. $command");
       VDSetLastError("EOPFAILED");
       $vdLogger->Error(Dumper($result));
       return FAILURE;
   }

   my $parsedData = VDNetLib::Common::Parsers::ParseTorEmulatorOutput(
                    $result->{stdout});
   if ($parsedData eq FAILURE) {
       return FAILURE;
   }
   my @uniqueBfdEnabledArray = ();
   my @uniqueBfdStateUpArray = ();
   my @uniqueBfdRemoteStateUpArray = ();
   foreach my $hashRef (@$parsedData) {
      my $currentID = $hashRef->{local} . $hashRef->{remote};
      if (exists $serverForm->{bfd_enabled_unique_count}) {
          if ($hashRef->{bfd_status}->{enabled} eq 'true') {
             push(@uniqueBfdEnabledArray, $currentID) unless grep{$_ eq $currentID} @uniqueBfdEnabledArray;
          }
      }
      if (exists $serverForm->{bfd_state_up_unique_count}) {
          if ($hashRef->{bfd_status}->{state} eq 'up') {
             push(@uniqueBfdStateUpArray, $currentID) unless grep{$_ eq $currentID} @uniqueBfdStateUpArray;
          }
      }
      if (exists $serverForm->{bfd_remote_state_up_unique_count}) {
          if ($hashRef->{bfd_status}->{remote_state} eq 'up') {
             push(@uniqueBfdRemoteStateUpArray, $currentID) unless grep{$_ eq $currentID} @uniqueBfdRemoteStateUpArray;
          }
      }
   }

   my $uniqueBfdEnabledCount = @uniqueBfdEnabledArray;
   my $uniqueBfdStateUpCount = @uniqueBfdStateUpArray;
   my $uniqueBfdRemoteStateUpCount = @uniqueBfdRemoteStateUpArray;
   if (exists $serverForm->{bfd_enabled_unique_count}) {
      $resultHash->{response}->{bfd_enabled_unique_count} = $uniqueBfdEnabledCount;
   }

   if (exists $serverForm->{bfd_state_up_unique_count}) {
      $resultHash->{response}->{bfd_state_up_unique_count} = $uniqueBfdStateUpCount;
   }

   if (exists $serverForm->{bfd_remote_state_up_unique_count}) {
      $resultHash->{response}->{bfd_remote_state_up_unique_count} = $uniqueBfdRemoteStateUpCount;
   }

   $vdLogger->Debug("serverData got from the server: " . Dumper($result->{response}));
   $resultHash->{status}   = "SUCCESS";
   return $resultHash;
}


######################################################################## #
# network_partitioning
#     Method to block/unblock BFD tunnel from TOR emulator to PTEPS
#
# Input:
#     spec: spec with local emulator VTEP ip address and BFD port number
#
# Results:
#     SUCCESS, if succesfully block/unblock BFD tunnels
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub network_partitioning
{
   my $self = shift;
   my $spec = shift;

   if ((not defined $spec->{'ip_address'}) || (not defined $spec->{'port'})) {
      $vdLogger->Error("local ip address or destination port not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $protocol = $spec->{'protocol'} || 'tcp';
   my $ipAddress = $spec->{'ip_address'};
   my $operation = $spec->{'operation'} || 'set';
   my $port = $spec->{'port'};

   my $command = undef;
   if ($operation eq 'set') {
       $command = "iptables -I OUTPUT -p $protocol --dport $port -s $ipAddress -j DROP;
                    iptables -I INPUT -p $protocol --sport $port -d $ipAddress -j DROP";
   } elsif ($operation eq 'unset') {
       $command = "iptables -D OUTPUT -p $protocol --dport $port -s $ipAddress -j DROP;
                    iptables -D INPUT -p $protocol --sport $port -d $ipAddress -j DROP";

   } else {
      $vdLogger->Error("operation param should be either 'set' or 'unset'");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $torIP = $self->{vmIP};
   my $result = $self->{stafHelper}->STAFSyncProcess($torIP,
                                                      $command);

   # check for success or failure of the command executed using staf
   if (($result->{rc} != 0) || ($result->{exitCode})) {
       $vdLogger->Error("Failed to set TOR gateway network partitioning
                         on $torIP. $command");
       VDSetLastError("EOPFAILED");
       $vdLogger->Error(Dumper($result));
       return FAILURE;
   }
   return SUCCESS;
}
1;
