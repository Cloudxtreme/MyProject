########################################################################
#  Copyright (C) 2014 VMware, Inc.
#  All Rights Reserved
########################################################################

package VDNetLib::NSXController::NSXController;

use strict;
use warnings;
use Data::Dumper;
use VDNetLib::Common::GlobalConfig qw($vdLogger $sshSession);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              ConfigureLogger
                                              CallMethodWithKWArgs);
use base qw(VDNetLib::Root::Root VDNetLib::VM::ESXSTAFVMOperations);

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
   my $class      = shift;
   my %args       = @_;
   my $self = {};
   $self->{ip}       = $args{ip};
   $self->{username}     = $args{username};
   $self->{password} = $args{password};
   $self->{cmd_username}     = $args{cmd_username};
   $self->{cmd_password} = $args{cmd_password};
   $self->{cert_thumbprint} = $args{cert_thumbprint};
   $self->{build} = $args{build};
   $self->{_pyIdName} = 'id_';
   $self->{_pyclass} = 'vmware.nsx.controller.controller_facade.ControllerFacade';
   bless $self;
   return $self;
}
#####################################################################
#
# GetInlinePyObject --
#     Method to get Python equivalent object of this class
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
                                              $self->{password},
                                              $self->{cmd_username},
                                              $self->{cmd_password},
                                              $self->{cert_thumbprint},
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

   # Use host user and password in order to get InlineVMObj
   if (not defined $self->{'hostObj'}) {
      $vdLogger->Error("Host obj not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $user   = $self->{'hostObj'}->{'userid'};
   my $passwd = $self->{'hostObj'}->{'sshPassword'};
   my $inlineVMObj =
         VDNetLib::InlineJava::VM->new('host'     => $self->{'host'},
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
#           TestVM: 'nsxcontroller.[1]'
#           vnic:
#              '[1]':
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


########################################################################
#
# GetNSXControllerLog --
#     Method to get NSX controller logs (Tech support Bundle)
#
# Input:
#     LogDir : Log directory to which NSXController logs have to be copied
#              on master controller.
#     localIP: IP for MC
#
# Results:
#     "SUCCESS", if all the logs get copied to the specific directory
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetNSXControllerLog
{
   my $self = shift;
   my $logDir = shift;
   my $localIP = shift;
   my $result;

   if (not defined $logDir) {
      $vdLogger->Error("Destination dir for storing NSXController logs " .
                 "not provided");
      VDSetLastError("ENODEF");
      return FAILURE;
   }
   if (not defined $localIP) {
      $vdLogger->Error("Local IP not provided");
      VDSetLastError("ENODEF");
      return FAILURE;
   }

   my $componentPyObj = $self->GetInlinePyObject();
   if ($componentPyObj eq FAILURE) {
      $vdLogger->Error("Failed to get inline python object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $method = "copy_tech_support";
   my $args;
   $args->{execution_type} = 'cli';
   $args->{logdir} = $logDir;
   $args->{collectorIP} = $localIP;

   $result = CallMethodWithKWArgs($componentPyObj, $method, $args);
   if ((defined $result) && ($result eq FAILURE)) {
      $vdLogger->Error("Copy tech support file returned FAILURE: " .
      Dumper(VDGetLastError()));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}
1;
