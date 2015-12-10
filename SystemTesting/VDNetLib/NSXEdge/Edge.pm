########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::NSXEdge::Edge;

use strict;
use warnings;
use Data::Dumper;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);

use base qw(VDNetLib::Root::Root VDNetLib::VM::ESXSTAFVMOperations);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              ConfigureLogger);

########################################################################
#
# new --
#     Constructor to create an instance of this class
#     VDNetLib::NSXEdge::Edge
#
# Input:
#     named hash parameter
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NSXEdge::Edge
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
   $self->{ip}       = $args{ip};
   $self->{username} = $args{username};
   $self->{password} = $args{password};
   $self->{build}    = $args{build};
   $self->{_pyIdName} = 'id_';
   $self->{_pyclass}  = 'vmware.nsx.edge.edge_facade.EdgeFacade';
   bless $self;
   return $self;
}

sub GetInlinePyObject
{
   my $self = shift;
   my $inlinePyObj;
   eval {
      $inlinePyObj = CreateInlinePythonObject($self->{_pyclass},
                                              $self->{ip},
                                              $self->{username},
                                              $self->{password},
                                              $self->{build});
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

########################################################################
#
# GetInlineVMObject --
#     Method to get an instance of VDNetLib::InlineJava::VM
#
# Input:
#     None
#
# Results:
#     an instance of VDNetLib::InlineJava::VM class
#
# Side effects:
#     None
#
########################################################################

sub GetInlineVMObject
{
   my $self   = shift;

   my $user;
   my $passwd;
   my $host;
   if (defined $self->{hostObj}{vcObj}) {
       $host   = $self->{hostObj}{vcObj}{vcaddr};
       $user   = $self->{hostObj}{vcObj}{user};
       $passwd = $self->{hostObj}{vcObj}{passwd};
   } else {
       $host   = $self->{'host'};
       $user   = $self->{'hostObj'}->{'userid'};
       $passwd = $self->{'hostObj'}->{'sshPassword'};
   }
   my $inlineVMObj =
         VDNetLib::InlineJava::VM->new('host'     => $host,
                                       'vmName'   => $self->{'vmName'},
                                       'user'     => $user,
                                       'password' => $passwd,
                                      );
   if (!$inlineVMObj) {
      $vdLogger->Error("Failed to create VDNetLib::InlineJava::VM instance");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return $inlineVMObj;
}


########################################################################
#
# DiscoverAdapters --
#     Method to discover vnics of an appliance VM and create vnic objects.
#
# Input:
#     None
#
# Results:
#     return array of vnic objects
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub DiscoverAdapters
{
   my $self = shift;

   my $adaptersInfo = $self->GetAdaptersInfo();
   if ($adaptersInfo eq FAILURE) {
      $vdLogger->Error("Failed to get adapters information on ".
               "VM: $self->{vmName}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my @arrayOfVNicObjects;
   foreach my $adapter (@$adaptersInfo) {
      my %args;
      # Create vdnet vnic object and store it in array of vnicobjects
      $args{intType}  = "vnic";
      $args{vmOpsObj} = $self;
      $args{controlIP} = $self->{'ip'};
      $args{macAddress} = $adapter->{'mac address'};
      $args{pgObj}    = undef;
      $args{deviceLabel} = $adapter->{'label'};
      # To get driver name from 'adapter class', note that 'adapter class'
      # begins with 'Virtual', for example, 'VirtualVmxnet3'.
      my $driver= lc($adapter->{'adapter class'});
      $driver =~ s/virtual//;
      $args{driver} = $driver;
      $args{name} = $driver;
      my $vnicObj = VDNetLib::NetAdapter::Vnic::Vnic->new(%args);
      if ($vnicObj eq "FAILURE") {
         $vdLogger->Error("Failed to initialize vnic obj on VM: $self->{vmx}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      push @arrayOfVNicObjects, $vnicObj;
   }

   return \@arrayOfVNicObjects;
}


########################################################################
#
# AddEthernetAdapters --
#     Method to add or discover vnics for an appliance vm. only discover
# function is supported at present.
#
# Input:
#     Reference to an array of hash as below,
#           Type:  VM
#           TestVM: 'nsxedge.[1]'
#           vnic:
#              '[1-3]':
#                  discover: true
#
# Results:
#     return array of vnic objects
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub AddEthernetAdapters
{
   my $self         = shift;
   my $adaptersSpec = shift;

   if ((not defined $adaptersSpec) || (scalar(@{$adaptersSpec}) == 0)) {
      $vdLogger->Error("Null or empty adapter spec.");
      return FAILURE;
   }
   my $spec = $adaptersSpec->[0];
   if (not exists $spec->{'discover'}) {
       $vdLogger->Error("No discover key was found" );
       return FAILURE;
   }
   my $discover = $spec->{'discover'};
   if (ref($discover) =~ /Boolean/) {
      if($$discover) {
         $discover = 'true';
      } else {
         $discover = 'false';
      }
   }
   if ($discover =~/true/) {
      return $self->DiscoverAdapters();
   }

   # for future work to add adapters.
   $vdLogger->Error("Expected discover value is true, actual is $discover");
   return FAILURE;
}


######################################################################
#
# GetGuestNetInfo --
#     Method to get guest net info through according method in python layer
#
# Input:
#     None
#
# Results:
#     Return a array which includes net info for each network adapter
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetGuestNetInfo
{
   my $self = shift;
   my $args;

   $args->{"execution_type"} = "cli";
   $args->{'host_ip'} = $self->{'esxHost'};
   $args->{'username'} = $self->{hostObj}{userid};
   $args->{'password'} = $self->{hostObj}{sshPassword};
   $args->{'vm_name'} = $self->{'vmName'};
   my $result;
   eval {
      $result = $self->get_guest_net_info($args);
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while calling get_guest_net_info ".
                                                  " for $self->{'vmName'}");
      return FAILURE;
   }
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to call python get_guest_net_info");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   return $result->{'table'};
}


######################################################################
#
# ReadEdgeSouthboundBfdIps --
#     Method to get southbound ip and bfd ip for an edge vm.
#
# Input:
#     serverForm : entry hash array generate from userData, like
#                  [
#                     {
#                       southbound_ip => undef
#                       bfd_ip        => undef
#                     }
#                  ],
#     adapterLabel: network adapter label, sample value, 'Network adapter 3'
#     southbound_subnet: southbound ip subnet, e.g. '169.0.0.0'
#     bfd_subnet: bfd ip subnet, e.g. '169.255.255.0'
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub ReadEdgeSouthboundBfdIps
{
   my $self             = shift;
   my $serverForm       = shift;
   my $adapterLabel     = shift;
   my $southboundSubnet = shift;
   my $bfdSubnet        = shift;

   my $southIpPrefix = undef;
   my $bfdIpPrefix   = undef;
   my @southBoundIpArray;
   my @bfdIpArray;
   if ($southboundSubnet =~ /(\d+.\d+.\d+).\d/) {
      $southIpPrefix = $1;
   }
   if ($bfdSubnet =~ /(\d+.\d+.\d+).\d/) {
      $bfdIpPrefix = $1;
   }
   if ((not defined $southIpPrefix) || (not defined $bfdIpPrefix)) {
      $vdLogger->Error("Invalid southbound subnet $southboundSubnet ".
                                          "or bfd subnet $bfdSubnet");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $arrayOfGuestNetInfo = $self->GetGuestNetInfo();
   if ($arrayOfGuestNetInfo eq FAILURE) {
      $vdLogger->Error("GetGuestNetInfo() failed");
      return FAILURE;
   }
   foreach my $element (@$arrayOfGuestNetInfo) {
      my %options = %$element;
      if ($options{'device_label'} eq $adapterLabel) {
         $vdLogger->Debug("Get ipv4 addresses for $adapterLabel: ".
                                   Dumper($options{'ipv4_array'}));
         foreach my $ipv4 (@{$options{'ipv4_array'}}) {
            if ($ipv4 =~ m/^$southIpPrefix/) {
               push @southBoundIpArray, $ipv4;
            } elsif ($ipv4 =~ m/^$bfdIpPrefix/) {
               push @bfdIpArray, $ipv4;
            }
         }
      }
   }
   if ((scalar(@southBoundIpArray) == 0) || (scalar(@bfdIpArray) == 0)) {
      $vdLogger->Error("southboundIp or bfdIp were not found");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $resultHash = {
      'status'      => undef,
      'response'    => undef,
      'error'       => undef,
      'reason'      => undef,
   };
   my $serverData;
   $serverData->{'southbound_ip'} = \@southBoundIpArray;
   $serverData->{'bfd_ip'} = \@bfdIpArray;
   $resultHash->{status} = "SUCCESS";
   $resultHash->{response} = $serverData;
   $vdLogger->Info("Read edge vnic's southbound ip and bfd ip successfully");
   return $resultHash;
}

1;
