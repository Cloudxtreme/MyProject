########################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::Host::HostOperations;
#
# This package allows to perform various operations on an ESX/ESXi host
# and retrieve status related to these operations. An object of this
# class refers to one ESX/ESXi host.
#
use base qw(VDNetLib::Host::HypervisorOperations);

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/";
use lib "$FindBin::Bin/../VDNetLib/VIX/";

use VDNetLib::DHCPServer::DHCPServer;
use VDNetLib::Common::Utilities;
use VDNetLib::Workloads::Utilities;
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::EsxUtils;
use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJava CreateInlineObject
                                         InlineExceptionHandler NewDataHandler
                                         LoadInlineJavaClass);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              ConfigureLogger
                                              CallMethodWithKWArgs);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger $sshSession);
use VDNetLib::Common::ParseFile;
use VDNetLib::Common::FindBuildInfo;
use VDNetLib::Common::Compare;
use VDNetLib::InlineJava::Host;
use VDNetLib::InlineJava::SessionManager;
use VDNetLib::Switch::OpenVswitch::OpenVswitch;
use VDNetLib::TestData::TestConstants;
use VDNetLib::Switch::Port::Cisco;
use Data::Dumper;
use XML::Simple;
use VDNetLib::TestData::TestConstants;
use VDNetLib::Common::PacketCapture;

use constant NETDVSPATH => "/usr/lib/vmware/bin/";
use constant MODPATH => "/usr/lib/vmware/vmkmod/";
use constant DVFILTERCTL => "dvfilter_ctl";
use constant DVFILTERFWSLOW => "dvfilter-fw-slow";
use constant DVFILTERCHARDEVLOC => "/vmfs/devices/char/vmkdriver/";
use constant DVFILTER_FW_CHRNO => 200;
use constant SYSLOGPATH => '/var/run/log/';
use constant VMKRNLLOGFILE => '/var/log/vmkernel.log';
use constant LACPLOGFILE => '/var/log/lacp.log';
use constant DVFWORLDIDVSINODE => "/net/dvFilter/filter/worldid/";
use constant CMD_NEW_STOP_VISOR_FIREWALL => 'esxcli network firewall set -e false';
use constant CMD_NEW_START_VISOR_FIREWALL => 'esxcli network firewall set -e true';
use constant CMD_GET_FIREWALL => 'esxcli network firewall get';
use constant SSHSERVICENAME => "TSM-SSH";
use constant SSH_START => "start";
use constant ESXSTAFFIREWALLVIB => "/var/log/vmware/stafFirewall.vib";
use constant STAFFIREWALLVIBSRC => "$FindBin::Bin/../bin/vibs/stafFirewall.vib";
use constant ESXTESTCERTSVIB => "/var/log/vmware/test-certs.vib";
use constant TESTCERTVIBSRC => "$FindBin::Bin/../bin/vibs/test-certs.vib";
use constant FUSION_DEFAULT_NETWORKING_PATH => '/Library/Preferences/VMware\ ".
             "Fusion/';
use constant WAIT_FOR_DRIVER_TO_READY => 20;
use constant WAIT_FOR_HOSTD_TO_READY => 15;
use constant HOSTD_CONFIG_FILE => "/etc/vmware/hostd/config.xml";
use constant SRIOV_CONFIG_NODE_PATH => "/config/plugins/hostsvc/sriov";
use constant TRUE    => VDNetLib::Common::GlobalConfig::TRUE;
use constant FALSE   => VDNetLib::Common::GlobalConfig::FALSE;
use constant WAIT_FOR_HOST_TO_BOOT => 900;
use constant VMFS_BASE_PATH => "/vmfs/volumes/";
use constant VDNET_LOCAL_MOUNTPOINT => "vdtest";
use constant VSAN_LOCAL_PATH => "/vmfs/volumes/vsanDatastore";
use constant VDNET_SHARED_MOUNTPOINT => "vdnetSharedStorage";
use constant IGNORE_CORE_DUMP_LIST => ['sfcb-vmware_bas-zdump'];
use constant SCRATCH_CORE => "/scratch/core/";
our @vsishConfigNodes = ('/reliability/vmkstress/',);
use constant checkupRecoveryMethods => [
   {
      'checkupmethod' => 'CheckHostUsingPing',
      'recoverymethod' => 'RecoverHostFromPSOD',
   },
   {
      'checkupmethod' => 'CheckHostUsingHostd',
      'recoverymethod' => 'RecoverFromHostdCrash',
   },
   {
      'checkupmethod' => 'DetectCoreDump',
      'recoverymethod' => 'CopyCoreDumpFile',
   },
];

my $vmklogEOF  = undef;
my $vmkloglastEOF = undef;
our $vmknicEsxcli = "/sbin/esxcli network ip";
our $vmknicEsxcliJSON = "/sbin/esxcli --debug --formatter=json network ip";
our $vswitchEsxcli = "/sbin/esxcli network vswitch standard";
our $vdswitchEsxcli = "/sbin/esxcli network vswitch dvs vmware";
our $vmnicEsxcli = "/sbin/esxcli network nic";

use constant HOST_SETUP_SCRIPT => "vdnet_esx_setup.py";

use constant attributemapping => {
   'ptep_cluster_entries' => {
      'payload' => 'ptepclusterentries',
      'attribute' => undef
   },
   'ptep_cluster_entry' => {
      'payload' => 'ptepclusterentry',
      'attribute' => 'GetMORId'
   },
   'build' => {
         'payload'   => 'build',
         'attribute' => undef,
   }
};


########################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#      (VDNetLib::Host::HostOperations).
#
# Input:
#      hostIP : IP address of the host. hostname is also accepted.
#               (Required)
#      stafObj: an object of VDNetLib::Common::STAFHelper.
#               If not provided, a new object with default options
#               will be created. (optional)
#      vdnetSource: vdnet source code to mount (<server>:/<share>)
#      vmRepository: vdnet vm repository to mount (<server>:/<share>)
#      sharedStorage: shared storage to mount (<server>:/<share>)
#
# Results:
#      An object of VDNetLib::Host::HostOperations package.
#
# Side effects:
#      None
#
########################################################################

sub new {
   my $class         = shift;
   my $hostIP        = shift;
   my $stafObj       = shift;
   my $vdnetSource   = shift;
   my $vmRepository  = shift;
   my $sharedStorage = shift;
   my $password = shift;

   my $self = {
      # IP address of ESX machine
      hostIP => $hostIP,

      # Obtain Staf handle of the process from VDNetLib::Common::STAFHelper module
      stafHelper => $stafObj,
      userid     => "root",
      vcObj	 => undef,
      password   => $password,
      os         => undef,
      arch       => undef,
      hostType   => undef,
      portgroups => undef,
      switches   => undef,
      vmtree     => undef,
      build      => undef,
      buildType  => undef,
      branch     => undef,
      vmklogEOF  => undef,
      sriovHash  => undef,
      runtimeDir => undef,
      fptNicList => undef,
      vdnetSource => $vdnetSource,
      vmRepository => $vmRepository,
      sharedStorage => $sharedStorage,
      ovfDiskMode => "thin",
      vmkloglastEOF => undef,
      _pyIdName => 'id_',
      _pyclass      => "vmware.vsphere.esx.esx_facade.ESXFacade", # python path
      DVFilterHostSetup => 0, # means, DVFilterHostSetup is not done
                             # this way it needs to setup everytime
                             # new on HostOps is done, need to
                             # make it global var such that all the
                             # instances can see if it is setup.

   };

   bless($self);

   if (not defined $self->{hostIP}) {
      $vdLogger->Error("Host IP/name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   #
   # Create a VDNetLib::Common::STAFHelper object with default if it not
   # provided in the input parameters.
   #
   if (not defined $self->{stafHelper}) {
      my $options;
      $options->{logObj} = $vdLogger;
      my $temp = VDNetLib::Common::STAFHelper->new($options);
      if (not defined $temp) {
         $vdLogger->Error("Failed to create VDNetLib::Common::STAFHelper object");
         VDSetLastError("ETAF");
         return FAILURE;
      }
      $self->{stafHelper} = $temp;
   }
   #
   #Creating child object for hosted if host is not esx/vmkernel.
   #
   my $childObjType = undef;
   my $hostType = $self->{stafHelper}->GetOS($self->{hostIP});
   if ((defined $hostType) && ($hostType !~ /vmkernel|esx/i)){
      $childObjType = "VDNetLib::Host::HostedHostOperations";
   }
   if (defined $childObjType){
      eval "require $childObjType";
      if ($@) {
         $vdLogger->Error("unable to load module $childObjType:$@");
         VDSetLastError("EOPFAILED");
         return "FAIL";
      }
      $self = $childObjType->new($self->{hostIP}, $self->{stafHelper});
      if ($self eq FAILURE) {
         $vdLogger->Error("Failed to create $childObjType");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      bless $self, $childObjType;
      return $self;
   }
   #
   # Host's password is needed to create a STAF anchor for Host service.
   # So, trying the default passwords one by one until successful.
   #
   my @passwords;
   if (defined $self->{'password'}) {
       push (@passwords, $self->{'password'});
   } else {
      @passwords = ('ca\$hc0w', 'vmw@re', '');
   }
   foreach my $pwd (@passwords) {
      my $command = "CONNECT AGENT $self->{hostIP} SSL USERID \"root\" " .
                    "PASSWORD \"$pwd\"";
      my $result = $self->{stafHelper}->STAFSubmitHostCommand("local",
                                                            $command);
      if ($result->{rc} == 0) {
         $self->{stafHostAnchor} = $result->{result};
         $self->{'password'} = $pwd;
         $pwd =~ s/\\//g; # ssh doesn't like escape \
         $self->{sshPassword} = $pwd;
         last;
      }
   }
   if (not defined $self->{stafHostAnchor}) {
      $vdLogger->Error("Failed to create staf anchor to $self->{hostIP}");
      $vdLogger->Error("Either $self->{hostIP} is unreachable ".
	               "or password is incorrect");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if (FAILURE eq $self->ConfigureHostForVDNet($vdnetSource,
                                               $vmRepository,
                                               $sharedStorage)) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $self->{hostType} = $self->{os};

   #
   # Some of the esx utility functions are available in EsxUtils package,
   # creating an object of the same.
   #
   my $esxUtilObj = VDNetLib::Common::EsxUtils->new($vdLogger,
                                                    $self->{stafHelper});
   if (not defined $esxUtilObj) {
      $vdLogger->Error("Failed to create EsxUtils object");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $self->{esxutil} = $esxUtilObj;

   # Determine the build Information
   ($self->{build},$self->{branch},$self->{buildType},$self->{version}) =
   VDNetLib::Common::Utilities::GetBuildInfo($self->{hostIP}, $self->{stafHelper});

   if (not defined $self->{build} || not defined $self->{branch}
      || not defined $self->{buildType} ) {
      $vdLogger->Error("Unknown build information, not supported");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }

   #
   # The STAF anchor for host staf service will not work for VM staf service,
   # hence creating another anchor.
   #
   $vdLogger->Trace("Doing the connect agent call now");
   my $command = "CONNECT AGENT $self->{hostIP} SSL USERID \"root\" " .
                 "PASSWORD \"$self->{password}\"";
   my $result = $self->{stafHelper}->STAFSubmitVMCommand("local",
                                                         $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to create staf anchor");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $self->{stafVMAnchor}        = $result->{result};
   $vdLogger->Trace("Created a stafVMAnchor successfully");

   #bless self to HostOperation2015 class based on version
   my $childClass = undef;
   if ((defined $self->{version}) && ($self->{version} =~ /^6/)){
      $childClass = "VDNetLib::Host::HostOperations2015";
   }
   if (defined $childClass){
      eval "require $childClass";
      if ($@) {
         $vdLogger->Error("unable to load module $childObjType:$@");
         VDSetLastError("EOPFAILED");
         return "FAIL";
      }
      $vdLogger->Trace("Created a version 6 host");
      bless $self, $childClass;
   }
   return $self;
}


########################################################################
#
# CreateVSS --
#      This method creates a vSwitch with a given name.
#      The created vSwitch will not have any uplink
#      by default.
#
# Input:
#      arrayOfSpecs: array of spec for vss
#      vswitch: name of the vSwitch to be created (required) in each spec
#
# Results:
#      Returns array of of vss objects if created successfully
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub CreateVSS
{
   my $self         = shift;
   my $arrayOfSpecs = shift;
   my @arrayOfVSSObjects;
   my $iteration = 0;

   foreach my $element (@$arrayOfSpecs) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("VSS spec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $iteration++;
      my %options = %$element;
      my $vswitch = $options{name};# mandatory

      if (not defined $vswitch) {
         $vswitch = "vss";
         $vswitch = VDNetLib::Common::Utilities::GenerateNameWithRandomId(
                                                                    $vswitch,
                                                                    $iteration);
      }

      if ($vswitch ne "vSwitch0") {
         my $command = "esxcli network vswitch standard add -v $vswitch";
         my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                        $command);
         if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
            $vdLogger->Error("Unable to create vswitch $vswitch: " .
                             Dumper($result));
            VDSetLastError("ESTAF");
            return FAILURE;
         }
      }

      my $vssObj = VDNetLib::Switch::Switch->new(
                                   'switch'     => $vswitch,
                                   'switchType' => "vswitch",
                                   'host'	=> $self->{hostIP},
                                   'hostOpsObj' => $self,
                                   'stafHelper' => $self->{stafHelper});
      if ($vssObj eq FAILURE) {
         $vdLogger->Error("Failed to create VSS $vswitch for $self->(hostIP)");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Trace("Created VSS $vswitch on " . $self->{hostIP} );
      push @arrayOfVSSObjects, $vssObj;
   }

   return \@arrayOfVSSObjects;
}


########################################################################
#
# CreatePort --
#      This method creates a pswitch port.
#
# Input:
#      arrayOfSpecs: array of spec for vss
#
# Results:
#      Returns arra of of vss objects if created successfully
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub CreatePort
{
   my $self = shift;
   my $arrayOfSpecs = shift;
   my @arrayOfPortObjects;

   foreach my $element (@$arrayOfSpecs) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("Standard PG spec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my %options    = %$element;
      my $vmnicObj   = $options{vmnic};    # mandatory
      my $portid     = $options{portid};
      my $pswitchObj = $options{pswitch};  # optional

      if (not defined $vmnicObj) {
         $vdLogger->Error("vmnic object not provided");
         VDSetLastError("EINVALID");
         return FAILURE;
      }

      # This discovers the pswitch port on the pswitch corresponding to this vmnic
      my $result = $vmnicObj->GetPhysicalSwitchInfo();
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to get physical switch information");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      if (not defined $pswitchObj) {
         # If code flow comes inside this if blocks it means
         # user has not given pswitch as a param to this API
         # which means user wants vdnet to figure out the corresponding
         # pswitch for this vmnic
         #
         # Get the physical switch information from
         # vmnic/uplink
         #
         $pswitchObj = VDNetLib::Switch::Switch->new(
                                  switchType    => "pswitch",
                                  switchAddress => $vmnicObj->{switchAddress});
      }

      if ((not defined $pswitchObj) || ($pswitchObj eq FAILURE)) {
         $vdLogger->Error("Failed to create physical switch object for " .
                          $vmnicObj->{switchAddress});
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      my $pgObj =
         VDNetLib::Switch::Port::Cisco->new('vmnicObj'   => $vmnicObj,
                                            'portid'     => $portid,
                                            'switchObj'  => $pswitchObj->{switchObj},
                                            'stafHelper' => $self->{stafHelper});
      if ($pgObj eq FAILURE) {
         $vdLogger->Error("Failed to create Port object for $portid");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      foreach my $key (keys %$vmnicObj) {
         if (not defined $pgObj->{$key}) {
            $pgObj->{$key} = $vmnicObj->{$key};
         }
      }
      push @arrayOfPortObjects, $pgObj;
   }
   return \@arrayOfPortObjects;
}



########################################################################
#
# DeleteVSS --
#      This method deletes the given vswitch
#
# Input:
#      arrayOfVSSObjects: array of spec for vss
#
# Results:
#      Returns "SUCCESS" if the given vswitch is deleted successfully
#      Returns "FAILURE" in case of any errror.
#
# Side effects:
#      None
#
########################################################################

sub DeleteVSS
{
   my $self = shift;
   my $arrayOfVSSObjects = shift;

   foreach my $vssObject (@$arrayOfVSSObjects) {
      my $vswitch;
      if (defined $vssObject->{'switch'}) {
         $vswitch = $vssObject->{'switch'};
      } elsif (defined $vssObject->{'name'}) {
         $vswitch = $vssObject->{'name'};
      }
      # command to delete a vswitch on ESX/ESXi
      my $command = "esxcli network vswitch standard remove -v $vswitch";
      my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                        $command);
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         $vdLogger->Error("STAF command to delete vswitch failed:" .
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      # Update the vswitch list on the given host and verify that the given
      # vswitch is not present in the list.
      my $resultHash = ();
      $resultHash = $self->UpdatePGHash();
      if (exists $resultHash->{switches}{$vswitch}) {
         $vdLogger->Error("Delete $vswitch failed:" . Dumper($result));
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $vdLogger->Info("Delete VSS $vswitch passed");
   }
   return SUCCESS;
}


########################################################################
#
# DeletevSwitch --
#      This method deletes the given vswitch
#
# Input:
#      vswitch: name of the vswitch to be deleted (required)
#
# Results:
#      Returns "SUCCESS" if the given vswitch is deleted successfully or
#      if the vswitch by the given name does not exist;
#      Returns "FAILURE" in case of any errror.
#
# Side effects:
#      None
#
########################################################################

sub DeletevSwitch
{
   my $self          = shift;
   my $vswitch       = shift;# mandatory

   if (not defined $vswitch) {
      $vdLogger->Error("vswitch name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Find the updated information about vswitches on the given host
   my $resultHash = $self->UpdatePGHash();

   #
   # If the given vswitch does not exist, then there is nothing to delete.
   # So returning SUCCESS here.
   #
   if (not exists $resultHash->{switches}{$vswitch}) {
      $vdLogger->Debug("vSwitch $vswitch does not exist");
      return SUCCESS; # why instead of failure? because it causes tests to fail
                      # when both sut and helpers are same and same switches
                      # are created.
                      #
   }

   # command to delete a vswitch on ESX/ESXi
   my $command = "esxcli network vswitch standard remove -v $vswitch";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("STAF command to delete vswitch failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   #
   # Update the vswitch list on the given host and verify that the given
   # vswitch is not present in the list.
   #
   $resultHash = ();
   $resultHash = $self->UpdatePGHash();
   if (exists $resultHash->{switches}{$vswitch}) {
      $vdLogger->Error("Delete $vswitch failed:" . Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   } else {
      $vdLogger->Debug("Successfully deleted the vswitch $vswitch");
      return SUCCESS;
   }
   return SUCCESS;
}


########################################################################
#
# CreateStandardPortGroup
#      To create a port group on a given vSwitch
#
# Input:
#      arrayOfSpecs: array of spec for portgroups
#      vswitch: name of the vswitch on which the portgroup has to be
#               created. (required)
#
# Results:
#      Returns array of pg objects
#      Returns "FAILURE" in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub CreateStandardPortGroup
{
   my $self = shift;
   my $arrayOfSpecs = shift;
   my @arrayOfPGObjects;
   my $iteration = 0;

   foreach my $element (@$arrayOfSpecs) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("Standard Portgroup spec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $iteration++;
      my %options       = %$element;
      my $vswitchObj    = $options{vss};
      my $portgroup     = $options{name};
      my $vswitch;
      if (not defined $portgroup) {
         $portgroup = "pg";
         $portgroup =
            VDNetLib::Common::Utilities::GenerateNameWithRandomId($portgroup, $iteration);
      }

      if (not defined $vswitchObj) {
         $vdLogger->Error("Portgroup and/or vswitch name not provided");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      if (defined $vswitchObj->{'switch'}) {
         $vswitch = $vswitchObj->{'switch'};
      } elsif (defined $vswitchObj->{'name'}) {
         $vswitch = $vswitchObj->{'name'};
      }

      # For Rollback testing, vmk0 is in portgroup VMKernel and this portgroup
      # can't be removed at cleanup. If we create it in testbed init, it will
      # be failed.
      #
      my $command = "esxcli network vswitch standard portgroup list";
      my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                        $command);
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         $vdLogger->Error("STAF command to list portgroup failed:" .
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if (($portgroup =~ /vmkernel/i)
          && ($result->{stdout} =~ /$portgroup\s+$vswitch/i)) {
         $vdLogger->Debug("Found destination portgroup $portgroup in " .
                          "vswitch $vswitch.");
      } else {
         # command to add a portgroup to the vswitch
         $command = "esxcli network vswitch standard portgroup add ".
                       " -v $vswitch -p $portgroup";
         my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                           $command);
         if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
            $vdLogger->Error("STAF command to create portgroup failed:" .
                             Dumper($result));
            VDSetLastError("ESTAF");
            return FAILURE;
         }
         $vdLogger->Debug("Successfully to created portgroup $portgroup" .
                          "on swithc $vswitch under host $self->{hostIP}");
      }

      my $pgObj =
         VDNetLib::Switch::VSSwitch::PortGroup->new('hostip'     => $self->{hostIP},
                                                    'pgName'     => $portgroup,
                                                    'switchObj'  => $vswitchObj,
                                                    'hostOpsObj' => $self,
                                                    'stafHelper' => $self->{stafHelper});
      if ($pgObj eq FAILURE) {
         $vdLogger->Error("Failed to create PortGroup object for $portgroup");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      push @arrayOfPGObjects, $pgObj;
   }
   return \@arrayOfPGObjects;
}


########################################################################
#
# DeleteStandardPortGroup --
#      To Delete a port group on a given vSwitch
#
# Input:
#      arrayOfPGObjects: array of pgobjects to be deleted
#
# Results:
#     Returns "SUCCESS" if the given portgroup is deleted successfully
#     Returns "FAILURE" in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub DeleteStandardPortGroup
{
   my $self = shift;
   my $arrayOfPGObjects = shift;

   foreach my $pgObject (@$arrayOfPGObjects) {
      my $portgroup  = $pgObject->{'pgName'};
      my $vswitchObj = $pgObject->{'switchObj'};
      my $vswitch;
      if (defined $vswitchObj->{'switch'}) {
         $vswitch = $vswitchObj->{'switch'};
      } elsif (defined $vswitchObj->{'name'}) {
         $vswitch = $vswitchObj->{'name'};
      }
      if (not defined $portgroup || not defined $vswitch) {
         $vdLogger->Error("Portgroup and/or vswitch name not provided");
         VDSetLastError("EINVALID");
         return FAILURE;
      }

      # command to delete a portgroup from vswitch
      my $command = "esxcli network vswitch standard portgroup remove" .
                           " -p $portgroup -v $vswitch";
      my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                        $command);
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         $vdLogger->Error("STAF command to delete portgroup failed:" .
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      #
      # Get the updated portgroup list on the given host and ensure that the
      # given portgroup does not exist.
      #

      my $resultHash = $self->UpdatePGHash();
      if (exists $resultHash->{portgroups}{$portgroup}) {
         $vdLogger->Error("Delete portgroup failed");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }
   return SUCCESS;
}
########################################################################
#
# configure_stress --
#      the method for the key configure_stress
#
# Input:
#      operation: "Enable" or "Disable" (required)
#      stress_options: 'ref: stress_options':
#
#      **Note: NA
#
# Results:
#      Returns "SUCCESS" if the given operation is successful;
#      Returns "FAILURE" in case of any error.
#
# Side effects:NA
#
########################################################################
sub configure_stress {
   my $self = shift;             # Required
   my $param = shift;

   if ((not defined $param) ||
       (not exists  $param->{stress_options}) ||
       (not exists  $param->{operation})){
       $vdLogger->Error("Insufficient parameters passed");
       VDSetLastError("EINVALID");
       return FAILURE;
   }

   my $operation = $param->{operation};
   if (($operation !~ /enable/i) &&
       ($operation !~ /disable/i)){
       $vdLogger->Error("In the key of configure_stress ," .
          "the operation  need to be 'enable' or 'disable'");
       VDSetLastError("EINVALID");
       return FAILURE;
   }
   $vdLogger->Info("Need $operation stress $param->{stress_options}");

   # Int he key "configure_stress", we supposed that "stressoptions "
   # and "iperation" should be set all the time. So we delete the
   # conditions of "default stressoptions "
   my %temp; # temporary hash variable to store stress options hash

   # If the 'stressoption' key (which has a hash variable in a string) is
   # specified in the param, then eval that string to store the
   # actual hash content (not variable) in a temporary variable. Then,
   # assign the the reference to the temporary variable for
   # 'stressoptions' key in param.

   if($param->{'stress_options'} =~ /^\%/i) {
      %temp = eval($param->{'stress_options'});
      $param->{'stress_options'} = \%temp;
   } else {
      # User can also supply a single hash value as stressOptions
      # E.g. stressoptions => "{NetCopyToLowSG => 150}",
      $param->{'stress_options'} =~ s/[\{>\}\s+]//g;
      my @stress_options = split(/=/,$param->{'stress_options'});
      if ((not defined $stress_options[1]) || (not defined $stress_options[0])) {
         $vdLogger->Error("Cannot understand stress_options format:".
                          "$param->{'stress_options'}");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      my $hash;
      $hash->{$stress_options[0]} = $stress_options[1];
      $param->{'stress_options'} = $hash;
   }

   $vdLogger->Info("Use VMKConfig to $operation $param->{'stress_options'}");
   my $result = $self->VMKConfig($operation, $param->{'stress_options'});
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to $operation arp inspection");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}
########################################################################
#
# VMKConfig --
#      To enable/disable vmkernel config option using vsish command
#
# Input:
#      operation: "Enable" or "Disable" (required)
#      options  : reference to a hash with the following format,
#                 {
#                    <configOption1> => <configValue>,
#                    <configOption2> => <configValue>,
#                    .
#                    .
#                    <configOptionN> => <configValue>,
#                 }
#                 Here <configOption> could be a just the config option
#                 name or absolute path in the vsish node;
#                 <configValue> is valid integer in double quotes.
#                 If the config value is not given then the default
#                 value will be used.
#
#      **Note: This method currently supports config options under
#              the /reliability/vmkstress/ node in vsish.
#              To enable/disable any new config options using this
#              method, add the prefix tree structure (similar to the one
#              above) to the array vsishConfigNodes (global variable
#              defined at the beginning of this package). If the
#              <configOption> is an absolute path, then this step can be
#              avoided.
#
# Results:
#      Returns "SUCCESS" if the given operation is successful;
#      Returns "FAILURE" in case of any error.
#
# Side effects:
#      Depends on the config option.
#
########################################################################

sub VMKConfig {
   my $self      = shift;
   my $operation = shift;
   my $options   = shift;

   if (not defined $operation || not defined $options) {
      $vdLogger->Error("operation and/or config options hash not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # make sure vsish is installed on the given host
   my $command = "vsish -e ls";
	my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("vsish command not installed on $self->{hostIP}");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if (($self->{buildType} = $self->GetBuildType()) eq FAILURE) {
      $vdLogger->Error("HostOperations->GetBuildType returned FAILURE");
      VDSetLastError("EFAIL");
      $self->{buildType} = undef;
      return FAILURE;
   }

   foreach my $configOpt (keys %{$options}) {
      # store the configvalue for each config option
      my $configValue= $options->{$configOpt};
      #
      # For each config option in the given hash, find the absolute path in the
      # vsish tree.
      #
      my $temp = $configOpt;
      $configOpt = $self->FindVMKConfigAbsPath($configOpt);
      if ($configOpt eq FAILURE) {
         if ($self->{buildType} =~  /opt|release/i) {
            #
            # If buildType is opt or release, then return skip/unsupported.
            # The given stress node is not available on these build types
            #
            $vdLogger->Warn("Stress option $temp is not supported on release " .
                            "or opt builds. Hence skipping this test case...");
            VDCleanErrorStack();
            return "SKIP";
         } else {
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }

      #
      # If the given operation is 'disable', then the config value is 0.
      # If the config value is not defined, then the default value for each
      # config option is used.
      #
      if ($operation =~ /disable/i) {
         $configValue = 0;
      #
      # Get the Hit Count  value before we reset the Hit count
      #
         $result = $self->GetVMKConfigInfo($configOpt);
         if ($result eq FAILURE) {
             $vdLogger->Error("Failed to get config option $configOpt details");
              VDSetLastError(VDGetLastError());
              return FAILURE;
          }
         if( defined $result->{HitCount} ) {
             $vdLogger->Info("$result->{Name} Hit count:$result->{HitCount}");
         }
      } elsif (not defined $configValue) {
         # find the default value
         my $temp = $self->GetVMKConfigInfo($configOpt);
         if ($temp eq FAILURE) {
            $vdLogger->Error("Failed to get config option $configOpt details");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $configValue = $temp->{Recommended};
         $vdLogger->Info("Taking Recommended value $configValue for $configOpt");
      }

      # Run the following vsish command to set the given config option
      $command = "vsish -e set $configOpt $configValue";
	   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                           $command);
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to execute command $command on " .
                          $self->{hostIP});
          VDSetLastError("ESTAF");
          return FAILURE;
      }

      #
      # Get the current value of the given config option and ensure the given
      # config value matches
      #

      $result = $self->GetVMKConfigInfo($configOpt);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to get config option $configOpt details");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      if ($result->{Current} ne $configValue) {
         $vdLogger->Error("Mismatch between request:$configValue and " .
                          "current:$result->{Current} values");
         VDSetLastError("EMISMATCH");
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# FindVMKConfigAbsPath --
#      This method finds the absolute path for the given config option.
#      This method currently searches for the given config option
#      under the list of vsish nodes in $vsishConfigNodes.
#
# Input:
#      configOpt (scalar): name of the config option
#
# Results:
#      Returns the absolute path (scalar variable) for the given config
#      option;
#      Returns "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub FindVMKConfigAbsPath
{
   my $self      = shift;
   my $configOpt = shift;
   my $absconfigPath;

   if ($configOpt =~ /\//) {
      my $result = $self->GetVMKConfigInfo($configOpt);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to get info about stress option $configOpt");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         return $configOpt;
      }
   }

   #
   # the array @vsishConfigNodes is a global variable
   # search for the given config option one by one under the vsish nodes
   # in @vsishConfigNodes
   #
   # TODO - store vsishConfigNodes as a hash variable and implement a utility
   # function which takes a portHash and an array with keys from the hash as
   # elements. This utility function should return the hash in a format such
   # that when foreach() is called on this hash, the order of keys returned is
   # same as the order of elements in the array. This function will help to
   # improve the search of a particular config option from a set of vsish
   # config nodes.
   #
   foreach my $prefix (@vsishConfigNodes) {
      my $command = "vsish -e ls $prefix" . $configOpt;
	   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                        $command);
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to execute command $command on " .
                          $self->{hostIP});
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      $result->{stdout} =~ s/\n//g;
      if ($result->{stdout} eq $configOpt) {
         $absconfigPath = "$prefix" . "$configOpt";
         last;
      }
   }

   if (not defined $absconfigPath) {
      $vdLogger->Error("Unable to find the absolute path of config option " .
                       $configOpt);
      VDSetLastError("ENOTDEF");
      return FAILURE;
   } else {
      return $absconfigPath;
   }
}


########################################################################
#
# GetVMKConfigInfo --
#      This method returns a hash which has the information about the
#      given config option.
#
# Input:
#      configOpt (scalar): absolute path of a config option (required)
#
# Results:
#      Returns a hash with keys 'Default', 'Min', 'Max', 'Current'
#      'Name', 'Hit', 'Recommended' with values corresponding to the
#      given config option;
#      Returns "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetVMKConfigInfo
{
   my $self = shift;
   my $configOpt = shift;
   my $config;
   my $command = "vsish -e get $configOpt";
	my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to execute command $command on " .
                       $self->{hostIP});
       VDSetLastError("ESTAF");
       return FAILURE;
   }

   if ($result->{stdout} =~ /Default value:(.*)/i) {
      $config->{Default} = $1;
   }
   if ($result->{stdout} =~ /Min value:(.*)/i) {
      $config->{Min} = $1;
   }
   if ($result->{stdout} =~ /Max value:(.*)/i) {
      $config->{Max} = $1;
   }
   if ($result->{stdout} =~ /Current value:(.*)/i) {
      $config->{Current} = $1;
   }

   if ($result->{stdout} =~ /Hit count:(.*)/i) {
      $config->{HitCount} = $1;
   }
   if ($result->{stdout} =~ /Recommended value:(.*)/i) {
      $config->{Recommended} = $1;
   }
   if ($result->{stdout} =~ /Name:(.*)/i) {
      $config->{Name} = $1;
   }
   return $config;
}


########################################################################
#
# UpdatePGHash --
#      To update the port group and vswitch list in the given host.
#
# Input:
#      None
#
# Results:
#      None (just updates the class attributes
#      'switches' and 'portgroups')
#
# Side effects:
#      None
#
########################################################################

sub UpdatePGHash {

   my $self  = shift;
   my $debug = 0;
   my $command;
   my $res;
   my $data;

   # initialise the contents of hash elements
   my $resultHash;
   $resultHash->{portgroups} = ();
   $resultHash->{switches} = ();

   # Array declaration to store port group information
   my @tempArray;
   my @newArray; # holds the information without newlines and spaces
   my $el;       # defined for for/foreach loop variable
   my $tempdata;
   my $iSize;
   my $switch;
   my $numports;
   my $usedports;
   my $confports;
   my $mtu;
   my $pgName;
   my $vlanid;
   my $usedport;
   my $uplink;

   #
   # Fill up port group, vswitch info into hash
   # Command esxcfg-vswitch -l will list all switches and associated
   # information such as port group name/network/vlan used ports etc.
   #
   $command = "esxcfg-vswitch -l";
   $command = "start shell command $command wait returnstderr returnstdout";
   ($res, $data) = $self->{stafHelper}->runStafCmd($self->{hostIP},
                                                   "Process",
                                                   "$command");

   if ($res eq "FAILURE") {
      $vdLogger->Error("Failed to execute $command on $self->{hostIP}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Convert the output of esxcfg-vswitch -l into an array
   @tempArray = split(/(\n+)/, $data);

   # Filter out un-necessary spaces
   foreach $el (@tempArray) {
      if ($el =~ m/\S+/i) {
         $el =~ s/^\s+//;
         $el =~ s/\s+$//;
         push(@newArray, $el);
      }
   }

   # Following lines will filterout the required contents
   # from esxcfg-vswitch -l output
   my $size = @newArray;

   #
   # For each line in the output of the esxcfg-vswitch -l command
   # Collect the switch name, uplink adapter,number of ports to that
   # switch, use portd, configured ports etc.
   #
   for (my $i = 0; $i < $size; $i++) {
      if (defined $newArray[$i] && $newArray[$i] =~ m/Switch Name|Dvs Name/i) {
         $newArray[$i+1] =~ s/\s{2,}/:/g;
         ($switch, $numports, $usedports, $confports, $mtu, $uplink) =
            split(/:/,$newArray[$i+1]);
         if (defined $switch) {
            $switch =~ s/^\s+//;#tws
            $switch =~ s/\s+$//;#tws
            $resultHash->{switches}{$switch}{numports}       = $numports;
            $resultHash->{switches}{$switch}{usedports}      = $usedports;
            $resultHash->{switches}{$switch}{configuredport} = $confports;
            $resultHash->{switches}{$switch}{mtu}            = $mtu;
            $resultHash->{switches}{$switch}{name}           = $switch;
            $resultHash->{switches}{$switch}{uplink}         = $uplink;
            if ($newArray[$i] =~ m/Dvs Name/i) {
               $resultHash->{switches}{$switch}{type} = "dvs";
            } else {
               $resultHash->{switches}{$switch}{type} = "vswitch";
            }
         }

         if ((defined $newArray[$i+2]) &&
            ($newArray[$i+2] =~ /PortGroup Name/i)) {
            my $count = $i+3;
            while (defined $newArray[$count] &&
                  $newArray[$count] !~ m/Switch Name|Dvs Name/i) {
               $newArray[$count] =~ s/\s{2,}/:/g;
               ($pgName, $numports, $usedports, $confports, $mtu, $uplink) =
                  split(/:/,$newArray[$count]);
               if (defined $pgName) {
                  $resultHash->{portgroups}{$pgName}{'switch'} = $switch;
                  if ($newArray[$i] =~ m/Dvs Name/i) {
                     $resultHash->{portgroups}{$pgName}{'type'} = "dvs";
                  } else {
                     $resultHash->{portgroups}{$pgName}{'type'} = "vswitch";
                  }
               }
               $count = $count+1;
            }
         }
      }
   }
   return $resultHash;
}


########################################################################
#
# GetHostUPT --
#     Method to get the UPT status on the given host
#
# Input:
#     None
#
# Results:
#     0, if UPT is disabled on the host
#     1, if UPT is enabled on the host
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetHostUPT
{
   my $self = shift; # Required

   #
   # "vsish -e get /config/Net/intOpts/AllowPT" command is used to get the
   # passthrough status on the host. The output of this command would be:
   #    Vmkernel Config Option {
   #       Default value:1
   #       Min value:0
   #       Max value:1
   #       Current value:0
   #       hidden config option:0
   #       Description:Whether to enable UPT/CDPT
   #    }
   #
   # The data across "Current value:" is parsed to get the UPT status
   #
   my $result = $self->GetVMKConfigInfo("/config/Net/intOpts/AllowPT");
   if ($result eq FAILURE) {
      $vdLogger->Error("failed to obtain UPT stats on given host");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return $result->{'Current'};
}


########################################################################
#
# SetHostUPT --
#     Method to change the UPT status (Enable/Disable) on the given host
#
# Input:
#     <operation> - "Enable" or "Disable"
#
# Results:
#     "SUCCESS" - if the UPT status is changed successfully
#     "FAILURE" - in case of any error
# Side effects:
#     None
########################################################################

sub SetHostUPT
{
   my $self = shift;       # Required
   my $operation = shift;  # Required

   if ((not defined $operation) ||
      ($operation !~ /Enable|Disable/i)) {
      $vdLogger->Error("Operation not specified or invalid value given");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $value = ($operation =~ /Enable/i) ? "1" : "0";

   # "vsish -e get /config/Net/intOpts/AllowPT (1|0)" command is used to
   # set the passthrough status on the host. The output of this
   # command would be 1 or 0 in case of successful operation
   #

   my %tempHash = (
      '/config/Net/intOpts/AllowPT' => $value,
   );

   my $result = $self->VMKConfig($operation, \%tempHash);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to set UPT status on given host");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Make sure that the UPT status is changed by verifying with GetHostUPT()
   # method
   $result = $self->GetHostUPT();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to host UPT status");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($result !~ $value) {
      $vdLogger->Error("Mismatch between Host UPT set:$value ".
                   "and get:$result");
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetvNicVSIPort --
#     Method to get network adapter's VSI port number which would help
#     get the adapter's statistics, UPT status etc.
#
# Input:
#     vnic - mac or ip address of the virtual network adapter # required
#     switch - name of the switch (example vSwitch1), if switch name is
#              given the port can be found faster # Optional
#
#
# Results:
#     Entire path to the network adpater's port in vsi node, for example,
#     1) "/net/portsets/vSwitch0/ports/16777218".
#     2) Hash containing vswitch name portgroup name
#     "FAILURE" - in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetvNicVSIPort
{
   my $self    = shift;  # Required
   my $vnic    = shift;  # Required
   my $switch  = shift;  # Optional
   my ($portHash, $command);

   if (not defined $vnic) {
      $vdLogger->Error("VNIC mac or ip address not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my ($mac, $ipAddress);
   #
   # This routine can be used to find the VSI port of a vnic using either mac
   # or ip address.
   #
   # Check for mac address format else assume ip address is given
   #
   if ($vnic =~ /(([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2})/i) {
      $mac = $1;
   } else {
      $ipAddress = $vnic;
   }

   my @switchList;
   my @portList;

   if (defined $switch) {
      # may be check if switch exists
      push(@switchList, $switch);
   } else {
      # First the list of switches (vSwitches or dvs) on the host are captured
      # The command "vsish -e ls /net/portsets" will list all switches. For
      # example, the output would look like:
      # >vsish -e ls /net/portsets
      # vSwitch0/
      # vSwitch1/
      # pts-ps/
      #
      $command = "vsish -e ls /net/portsets";
      my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                        $command);

      # check for success or failure of the command executed using staf
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to launch vsish command " . Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      if ($result->{stdout} !~ /[A-Za-z0-9]+\/\n/) {
         $vdLogger->Error("Failed to obtain the list of switches".
                          Dumper($result));
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      # Under each switch, there will be a list of ports. The mac address of each
      # port under vsi node is checked against the given mac address at the input
      # If there is match, the entire path to the port in vsi node is returned.
      # Otherwise, "FAILURE" is returned.
      #
      @switchList = split(/\n/, $result->{stdout});
   }
   foreach my $switch (@switchList) {
      $switch =~ s/\///;
      # Following command will get the list of port under each switch.
      # Sample output:
      # >vsish -e ls /net/portsets/vSwitch0/ports
      #  16777217/
      #  16777218/
      #  16777219/
      #
      $command = "vsish -e ls /net/portsets/$switch/ports";
      my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                        $command);

      # check for success or failure of the command executed using staf
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to obtain the vnic pts ports Error" .
                          Dumper($result));
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      if ($result->{stdout} !~ /\d+\/\n/) {
         $vdLogger->Error("Failed to obtain the vnic pts ports Error" .
                          Dumper($result));
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      # Get the list of ports from the string and store them in an array
      @portList = split(/\n/, $result->{stdout});

      # UPT setup has multiple nodes under /net/portsets/<switch>/ports/
      # with bogus values. Unlike vSwitch where we have say 10 nodes for
      # say 10 vNICS, here we have 200 nodes for say just 50 vNICs. Rest all
      # 150 have bogus values. And these actual 50 nodes are always at the end.
      # Reversing the Array so that the search always begins from the end.
      my @reversetmp2 = reverse(@portList);

      #
      # For each port under a switch, read the status to get the mac address.
      # The command "vsish -e get /net/portsets/<switch>/ports/<port>/status"
      #

      foreach my $port (@reversetmp2) {
         $port =~ s/\///;  # The trailing "/" is removed
         #
         # The command used to look for matching mac address is different from
         # the command for ip address.
         #
         if (defined $mac) {
            $command = "vsish -e get /net/portsets/$switch/ports/$port/status";
         } else {
            $command = "vsish -e get /net/portsets/$switch/ports/$port/ip";
         }
         $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                        $command);
         if ($result->{rc} != 0) {
            $vdLogger->Error("Failed to obtain the vnic pts ports Error" .
                             Dumper($result));
            VDSetLastError("ESTAF");
            return FAILURE;
         }

         # check for a line that matches unicastAddr: to get MAC address of
         # vnic
         #
         $result->{stdout} =~ s/\n//g;
         #
         # Just like the difference in command, the processing of the command's
         # output is also different for mac and ip address.
         #
         if (defined $mac) {
            if ($result->{stdout} =~ /accepted:.*?unicastAddr:($mac):|fixed Hw Id:($mac):/i) {
               # if the mac address matches with given mac address then return
               # path to the adapter's port
               $portHash->{vswitch} = $switch;
               $portHash->{vsishportnum} = $port;
               #
               # stdout looks like 'port {   portCfg:vdtest   dvPortId:
               #
               $result->{stdout} =~ /portCfg:(.*?)[\s+\t\n]/;
               $portHash->{pgname} = $1 if defined $1;
               # Caching the info before returning.
               foreach my $key (keys %$portHash) {
                  $self->{vsishmacinfo}->{$mac}->{$key} = $portHash->{$key};
               }
               my $ret = "/net/portsets/$switch/ports/$port";
               $self->{vsishmacinfo}->{$mac}->{path} = $ret;
               return $portHash, $ret;
            }
         } else {
            my $tempIP = $result->{stdout};
            # Fetch the ip address hex string
            if ($tempIP =~ m/address:(0x.*)/) {
               $tempIP = $1;
            }
            $tempIP =~ s/0x|\n//g; # remove hex prefix
            my @array = ( $tempIP =~ m/../g ); # split into 2 characters
            my $ip = undef;
            foreach my $octet (@array) {
               $ip = (defined $ip) ? hex($octet) . "." . $ip : hex($octet);
            }
            if ($ip eq $ipAddress) {
               return "/net/portsets/$switch/ports/$port";
            }
         } # end of condition for ip address
      } # end of ports loop
   } # end of vswitches loop

   $vdLogger->Debug("Failed to find the VSIPort for the given adapter:$mac");
   VDSetLastError("ENOTDEF");
   return FAILURE;
}


########################################################################
# GetvNicUPTStatus --
#     Method to get virtual network adapter's UPT status.
#
# Input:
#     <mac> - mac address of the network adapter
#     <port> - vsi port (entire path) of the network adapter (optional)
#
#
# Results:
#     Any valid status (like OK, VNIC_FEATURES, DISABLED_BY_HOST,
#     DISABLED_BY_PG etc )
#     "FAILURE" in case of any error
#
# Side effects:
#     None
########################################################################

sub GetvNicUPTStatus
{
   my $self = shift;    # Required
   my $mac = shift;     # Required
   my $port = shift;    # Optional

   if (not defined $mac) {
      $vdLogger->Error("MAC address not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # If the entire path to adapter's port in vsi node is given, then the
   # following block of code will be skipped. This saves time from parsing
   # through all ports under all switches to match for the given mac address
   #
   if (not defined $port) {
      $port = $self->GetvNicVSIPort($mac);

      if ($port eq FAILURE) {
         $vdLogger->Error("Error getting pts port for given adapter $mac");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   my $command;
   # Making sure that the path does not contain double slashes "//"
   $port =~ s/\/\//\//;
   # Passthru status of the given adapter can be found by running the vsish
   # command "vsish -e get /net/portsets/<switch>/ports/<port>/status"
   # The output of this command has a field "Passthru status::" to indicate
   # current status
   #
   $command = "vsish -e get $port/status";
   $command = "start shell command $command".
              " wait returnstdout returnstderr";
   my ($result, $data) = $self->{stafHelper}->runStafCmd($self->{hostIP},
                                                         "Process",
                                                         "$command");

   # check for success or failure of the command
   if ($result eq "FAILURE") {
      $vdLogger->Error("Failed to obtain the vnic pts ports Error:$data");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Parse the vsish command output and pick the value after
   # "Passthru status::"
   #
   if ($data =~ /Passthru status::\s(.+?)\n/i) {
      return $1;
   } else {
      $vdLogger->Error("Unexpected output returned:$data");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}


########################################################################
#
# SetvNicUPTStatus --
#     Method to change the UPT status (enable/disable) on the given
#     network adapter on the given host.
#
# Input:
#     A valid HostOperations object
#     <operation> - "Enable" or "Disable"
#     <mac> - mac address of the network adapter
#     <port> - vsi port (entire path) of the network adapter (optional)
#
# Results:
#     "SUCCESS", if the UPT status is changed successfully
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub SetvNicUPTStatus
{
   my $self = shift;       # Required
   my $operation = shift;  # Required
   my $mac = shift;        # Required
   my $port = shift;       # Optional

   if ((not defined $mac) ||
      (not defined $operation)) {
      $vdLogger->Error("Insufficient arguments provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # If the entire path to adapter's port in vsi node is given, then the
   # following block of code will be skipped. This saves time from parsing
   # through all ports under all switches to match for the given mac address
   #

   if (not defined $port) {
      $port = $self->GetvNicVSIPort($mac);

      if ($port eq FAILURE) {
         $vdLogger->Error("Error getting pts port for given adapter $mac");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   my $command;
   $port =~ s/\/\//\//; # remove any double slashes in the path
   # The UPT status of a network adapter is done using the command
   # "net-dvs -s com.vmware.common.port.ptAllowed=<value> -p <dvs.PortID>
   # <dvs-name>", where <value> is 0 or 1.
   # In order to execute this command, dvs port id and dvs-name corresponding
   # to the given virtual network adapter is found using GetvNicDVSPortID() and
   # GetvNicDVSName() methods respectively.
   #

   # Get the dvs port ID
   my $portID = $self->GetvNicDVSPortID($mac, $port);

   if ($portID eq FAILURE) {
      $vdLogger->Error("Failed to get vNic port id");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Get the dvs name to which the vNic is connected to
   my $dvsName = $self->GetvNicDVSName($mac, $port);
   if ($dvsName eq FAILURE) {
      $vdLogger->Error("Failed to get vNic dvsName id");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # Compute the net-dvs command (string) to change UPT status
   if ($operation =~ /Enable/i) {
      $command = NETDVSPATH ."net-dvs -s com.vmware.common.port.ptAllowedRT=1" .
                 " -p $portID $dvsName";
   } elsif ($operation =~ /Disable/i) {
      $command = NETDVSPATH . "net-dvs -s com.vmware.common.port.ptAllowedRT=0" .
                 " -p $portID $dvsName";
   } else {
      $vdLogger->Error("Invalid operation specified for SetvNicUPTStatus");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Execute the net-dvs command on the given host
   $command = "start shell command $command".
              " wait returnstdout returnstderr";
   my ($result, $data) = $self->{stafHelper}->runStafCmd($self->{hostIP},
                                                         "Process",
                                                         "$command");

   # check for success or failure of the command
   if (($result eq "FAILURE") ||
      ($data ne "")) {
      $vdLogger->Error("Failed to change vNic UPT status:$data");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   # The change in UPT status of the given adapter is verified using
   # GetvNicUPTStatus() method. It takes few seconds (15 secs max) to reflect
   # the change on vsi node. So, sleep() is called to make the change is
   # effective and reflected.
   #
   # TODO - use while loop?
   #
   sleep(10);
   $result = $self->GetvNicUPTStatus($mac,$port);

   # If the operation is "Enable", then the UPT status should be "0 -> OK".
   # Otherwise, return FAILURE.
   #
   if ((($operation =~ /Enable/i) &&
        ($result !~ /0 -> OK/i)) ||
       (($operation =~ /Disable/i) &&
        ($result =~ /0 -> OK/i))) {
      $vdLogger->Error("Mismatch in set:$operation and get:$result " .
                       "vNicUPT status");
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetvNicDVSPortID --
#     Method to get DVS port ID for the given network adapter on the host.
#
# Input:
#     <mac> - mac address of the network adapter
#     <port> - vsi port (entire path) of the network adapter (optional)
#
# Results:
#     A valid port (integer), if success.
#     "FAILURE" in case of any error
#
# Side effects:
#     None
#
########################################################################

# *** Note **  Don't use this method, its inefficient.
# Use GetDVSPortIDForClient in VDSwitch.pm
sub GetvNicDVSPortID
{
   my $self = shift;
   my $mac = shift;
   my $port = shift;
   if (not defined $mac) {
      $vdLogger->Error("MAC address not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # If the entire path to adapter's port in vsi node is given, then the
   # following block of code will be skipped. This saves time from parsing
   # through all ports under all switches to match for the given mac address
   #
   my ($result, $command);
   if (defined $port) {
      # The dvs port ID can be found from the field "dvPortId:" after running
      # the command "vsish -e get /net/portsets/<switch>/ports/<port>/status"
      # on the esx host
      #
      $command = "vsish -e get $port/status";
      $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);

      # check for success or failure of the command
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to obtain the vnic pts ports Error:" .
                          Dumper($result));
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      if ($result->{stdout} =~ /dvPortId:(\d+)/i) {
         $vdLogger->Debug("dvPort ID returned from vsish is $1");
         return $1;
      }
      $vdLogger->Error("Unexpected output returned: $result->{stdout} for" .
                       " command: $command");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $command = "vsish -e ls /net/portsets";
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                  $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to launch vsish command " . Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($result->{stdout} !~ /[A-Za-z0-9]+\/\n/) {
      $vdLogger->Error("Failed to obtain the list of switches".
                        Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my @switchList = split(/\n/, $result->{stdout});
   foreach my $switch (@switchList) {
      $port = $self->GetvNicVSIPort($mac, $switch);
      if ($port eq FAILURE) {
         $vdLogger->Warn("Error getting pts port for given adapter $mac " .
                          "in $switch");
         next;
      }

      my $command = "vsish -e get $port/status";
      my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                        $command);
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to obtain the vnic pts ports. Error: " .
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      if ($result->{stdout} =~ /dvPortId:(\d+)/i) {
         $vdLogger->Debug("dvPort ID returned from vsish is $1");
         return $1;
      }
      $vdLogger->Debug("Unexpected output returned: $result->{stdout} for" .
                       " command:$command");
   }

   $vdLogger->Error("Unable to find dvport ID for mac $mac");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


########################################################################
#
# GetvNicIP --
#     Method to get IP address of the given network adapter on the host.
#     Note: vsish -e set /config/Net/intOpts/GuestIPHack must be set to
#           1 for this method to work correctly.
#
# Input:
#     <mac> - mac address of the network adapter
#     <port> - vsi port (entire path) of the network adapter (optional)
#
# Results:
#     IP address, if success.
#     "FAILURE" in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetvNicIP
{
   my $self = shift;
   my $mac = shift;
   my $port = shift;
   # If the entire path to adapter's port in vsi node is given, then the
   # following block of code will be skipped. This saves time from parsing
   # through all ports under all switches to match for the given mac address
   #
   if (not defined $port) {
      if (not defined $mac) {
         $vdLogger->Error("MAC address not provided");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $port = $self->GetvNicVSIPort($mac);

      if ($port eq FAILURE) {
         $vdLogger->Debug("Error getting pts port for given adapter $mac");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   #
   # The ip address can be found from the field "address:" after running
   # the command "vsish -e get /net/portsets/<switch>/ports/<port>/ip"
   # on the esx host
   #
   my $command;
   $command = "vsish -e get $port/ip";
   $command = "start shell command $command".
              " wait returnstdout returnstderr";
   my ($result, $data) = $self->{stafHelper}->runStafCmd($self->{hostIP},
                                                       "Process",
                                                       "$command");
   # check for success or failure of the command
   if ($result eq "FAILURE") {
      $vdLogger->Error("Failed to obtain the vnic pts ports Error:$data");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $ip;
   if ($data =~ /address:(.*)/i) {
      $ip = $1;
   } else {
      $vdLogger->Debug("Unexpected output returned:$data for command:$command");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $ip =~ s/0x|\n//g; # remove hex prefix
   my @array = ( $ip =~ m/../g ); # split into 2 characters
   if ($ip eq "00000000") {
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $ip = undef;

   foreach my $octet (@array) {
      $ip = (defined $ip) ? hex($octet) . "." . $ip : hex($octet);
   }
   return $ip;
}


########################################################################
#
# GetvNicDVSName --
#     Method to get the DVS name to which the given network adapter is
#     associated.
#
# Input:
#     A valid HostOperations object
#     <mac> - mac address of the network adapter
#     <port> - vsi port (entire path) of the network adapter (optional)
#
# Results:
#     A valid dvs name (string), if success
#     "FAILURE" in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetvNicDVSName
{
   my $self = shift;
   my $mac = shift;
   my $port = shift;
   if (not defined $mac) {
      $vdLogger->Error("MAC address not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # If the entire path to adapter's port in vsi node is given, then the
   # following block of code will be skipped. This saves time from parsing
   # through all ports under all switches to match for the given mac address
   #
   if (not defined $port) {
      $port = $self->GetvNicVSIPort($mac);

      if ($port eq FAILURE) {
         $vdLogger->Error("Error getting pts port for given adapter $mac");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   my $command;
   my $switch;
   my $dvsName;
   $port =~ s/\/\//\//; # remove all double slashes in the path
   if ($port =~ /\/net\/portsets\/(.+?)\//i) {
      $switch = $1;
   }

   if (not defined $switch) {
      $vdLogger->Error("Failed to get Switch name of the given vNic $mac");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # mac address of the dvs switch can be found from the field "dvsName:" after
   # running the command "vsish -e get /net/portsets/<switch>/properties"
   # on the esx host. The value across the field "dvsName:" is currently mac
   # address of the dvs
   #
   $command = "vsish -e get /net/portsets/$switch/properties";
   $command = "start shell command $command".
              " wait returnstdout returnstderr";
   my ($result, $data) = $self->{stafHelper}->runStafCmd($self->{hostIP},
                                                         "Process",
                                                         "$command");

   # check for success or failure of the command
   if ($result eq "FAILURE") {
      $vdLogger->Error("Failed to switch properties:$data");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   if ($data =~ /dvsName:([A-Za-z0-9-\s]+)/i) {
      $dvsName = $1;
   } else {
      $vdLogger->Error("Unexpected output returned:$data");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   # From the mac address of the switch obtained above, parse through the list
   # of dvs available and get the actual dvs name that corresponds to the
   # switch<->host
   #
   $command = NETDVSPATH . "net-dvs -l | grep -i -A 5 \'$dvsName\'";
   $command = "start shell command $command".
              " wait returnstdout returnstderr";
   ($result, $data) = $self->{stafHelper}->runStafCmd($self->{hostIP},
                                                         "Process",
                                                         "$command");

   # check for success or failure of the command
   if ($result eq "FAILURE") {
      $vdLogger->Error("Failed to get dvs name:$data");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # The output of "net-dvs -l | grep -i -A 5 <dvs mac address>" would look
   # like:
   # ~ # net-dvs -l | grep -i -A 5 "70 61 6c 6f 2d 64 76 73-00 00 00 00 00 00
   # 00 00"
   # switch 70 61 6c 6f 2d 64 76 73-00 00 00 00 00 00 00 00 (etherswitch)
   #   global properties:
   #               com.vmware.common.alias = palo-dvs
   #               com.vmware.common.uplinkPorts:
   #                       uplink0, uplink1
   #   host properties:
   #
   # Capture the value of "com.vmware.common.alias" to get the dvs name
   #
   if ($data !~ /com.vmware.common.alias = (\S+)/i) {
      $vdLogger->Error("Unexpected output returned:$data");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return $1;
}


########################################################################
#
# GetPGNameFromMAC --
#      Method to get portgroup name for the given MAC address.
#
# Input:
#      vmx: absolute vmx path (Required)
#      mac: MAC address of an adapter whose portgroup has to be found
#           (Required)
#
# Results:
#      Portgroup name (a scalar string) of the given mac address, if
#      successful;
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub GetPGNameFromMAC
{
   my $self = shift;
   my $vmx  = shift;
   my $mac  = shift;

   if (not defined $vmx || not defined $mac) {
      $vdLogger->Error("vmx and/or mac address not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $portgroup;
   #
   # STAF SDK primarily uses registered name of a VM, so getting that
   # name from the given absolure vmx path.
   #
   my $vmName = VDNetLib::Common::Utilities::GetRegisteredVMName($self->{hostIP},
                                                                 $vmx,
                                                                 $self->{stafHelper},
                                                                 $self->{stafAnchor});
   if ($vmName eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $command = "VMNICINFO ANCHOR $self->{stafVMAnchor} VM \"$vmName\"";
   my $result = $self->{stafHelper}->STAFSubmitVMCommand("local",
                                                         $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to get VM info of $vmx");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $vmInfo = $result->{result};
   my $version = `STAF local vm version`;
   if ($version =~ /vc4x-testware/i) {
      $vdLogger->Debug("Hash is in vc4x-testware format");
      # This is how the dump of $result->{result} looks like
      # VM NETWORK 1
      # MACADDRESS: 00:50:56:97:63:cc
      # PortGroup: VM Network
      # NETWORK: VM Network
      # Label: Network adapter 1
      # ADAPTER CLASS: VirtualE1000
      #
      # VM NETWORK 2
      # MACADDRESS: 00:0c:29:25:a6:10
      # PortGroup: vswitchpg-0-20694
      # NETWORK: vswitchpg-0-20694
      # Label: Network adapter 3
      # ADAPTER CLASS: VirtualVmxnet3

      # Split this data according to \n. Create a hash out of it
      # which will have key and value corresponding to this data
      my $vmInfoHash;
      my @vmInfoArray = split('\n\n',$vmInfo);
      foreach my $element (@vmInfoArray) {
         my @vmInfoSubArray = split('\n',$element);
         foreach my $line (@vmInfoSubArray) {
            if ($line =~ /: /i) {
               my @values = split(/: /, $line);
               $vmInfoHash->{$values[0]} = $values[1];
            } else {
               next;
            }
         }
         if((defined $vmInfoHash->{'MAC Address'} &&
             $vmInfoHash->{'MAC Address'} =~ /$mac/i) ||
            (defined $vmInfoHash->{'MACADDRESS'} &&
             $vmInfoHash->{'MACADDRESS'} =~ /$mac/i)) {
            $portgroup = $vmInfoHash->{'PortGroup'};
            last;
         }
      }
   } else {
      $vdLogger->Debug("Hash is in vc5x-testware format");
      foreach my $adapter (@$vmInfo) {
         if ($adapter->{'MAC Address'} =~ /$mac/i) {
            $portgroup = $adapter->{'PortGroup'};
            last;
         }
      }
   }

   if (not defined $portgroup) {
      $vdLogger->Error("Failed to get portgroup name for $mac");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return $portgroup;
}


########################################################################
#
# TestEsxSetup --
#      This method setup TestEsx environment on System Under Test (SUT)
#
# Input:
#      None
#
# Results:
#      Returns "SUCCESS", if TestEsx environment is created successfully or
#      if TestEsx environment already exists;
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub TestEsxSetup
{
   my $self = shift;
   my $cmd;
   my $command;
   my $storage;
   my $result;
   my $data;

   if ($self->GetVMTree() eq FAILURE) {
      $vdLogger->Error("TestEsxSetup: GetVMtree failed.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # set the current EOF file of the vmkernel log, this is the
   # beginning point of the log file for this session
   my %parseFileIn = (
           'ip' => $self->{hostIP},
           'file' => VMKRNLLOGFILE,
   );
   my $p = new VDNetLib::Common::ParseFile(\%parseFileIn);
   # $self->{vmklogEOF} always points of the EOF when this session
   # started precisely, when the TestESXSetup is called
   #$self->{vmkloglastEOF} = $self->{vmklogEOF};
   $vmkloglastEOF = $vmklogEOF;
   if (($vmklogEOF = $p->GetCurrentPos()) eq FAILURE) {
      $vdLogger->Error("TestEsxSetup: ParseFile::GetCurrentPos failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my %vmkloginfo = (vmkloglastEOF => $vmkloglastEOF, vmklogEOF =>  $vmklogEOF);
   if (!open(FP, ">/tmp/vmkloginfo")) {
      $vdLogger->Warn("TestEsxSetup: Unable to save vmklog EOF " .
                      "information in /tmp/vmklog");
   } else {
      my  $d = Data::Dumper->new([\%vmkloginfo], ['vmkloginfo']);
      print FP $d->Dump;
      $vdLogger->Debug("TestEsxSetup: writing to ". Dumper(\%vmkloginfo) .
                      "/tmp/vmklog");
      close FP;
   }

   return SUCCESS;
}


#########################################################################
#
#  TestEsxCommand
#      Get hostname and execute test-esx command
#
# Input:
#      hostname
#
# Results:
#      Returns "SUCCESS", if TestEsx command finished successful
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub TestEsxCommand
{
   my $self = shift;
   my $host   =$self->{hostIP};
   my $cmd = shift;
   my $data;
   my $buildType;

   my $result = $self->TestEsxSetup();
   if ($result eq "FAILURE") {
      return(FAILURE);
   }

   if (($buildType = $self->GetBuildType()) eq FAILURE) {
      $vdLogger->Error("HostOperations->GetBuildType returned FAILURE");
      VDSetLastError("EFAIL");
      $self->{buildType} = undef;
      return FAILURE;
   }

   my $command = "$self->{vmtree}/support/scripts/test-esx --vmtree $self->{vmtree} $cmd";

   $vdLogger->Info("Executing $command");
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                  $command);
   # check for success or failure of the command
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to execute $command");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }
   $vdLogger->Info(Dumper($result));
   # Search for test result pattern in stdout - $2 is the test script and $1 either FAILED/passed
   #
   if($result->{stdout} =~ m/(FAILED|passed) - (\w+\/\S+)/i) {
     $vdLogger->Info("----- $2 test $1 ------ ");
   }
   if($1  =~ m/FAILED/i) {
      return FAILURE;
   } elsif ($1 =~ m/passed/i) {
      return SUCCESS;
   }
   return SUCCESS;
}

#########################################################################
#
#  DVFilterHostSetup
#      Copies dvfilter-ctl binary from build tree to /bin and sets up sym
#      link in /sbin
#      Sets a flag to indicate the DVFilter host is setup
#
#  Input:
#      As of now we cannot pass ref from workload hash and therefore
#      one agent is setup at a time.
#      Agent name - optional, if not given, build tree and
#      dvfilter_ctl binary is setup.
#
#  Results:
#      Returns "SUCCESS", if all the steps succeed
#      Returns "FAILURE", in case of any error.
#
#  Side effects:
#      None.
#
#########################################################################

sub DVFilterHostSetup
{
   my $self = shift;
   # TODO, take reference to list whenever iterator is fixed
   my %args = @_;
   my $agenttype = $args{dvfiltertype};
   my @agents = eval($args{dvfilterhostsetup});
   if ($@) {
      $vdLogger->Error("Failed to load dvfilter array $@");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $host = $self->{hostIP};
   my $result;
   $vdLogger->Info("HostOperations->DVFilterHostSetup parms: @agents");

   # Set the vmtree for the host build
   $result = $self->GetVMTree();

   if ($result eq "FAILURE") {
      $vdLogger->Error("Getting VM Tree failed");
      VDSetLastError(VDGetLastError());
      return(FAILURE);
   }

   my $vmtree =  $self->{vmtree};
   my @commandtools = (DVFILTERCTL);
   if (defined $agenttype && ($agenttype eq "slow")) {
      push (@commandtools, DVFILTERFWSLOW);
   }
   foreach my $commandtool (@commandtools) {
      my @dvfilterctlsetup = ("cp $vmtree/build/scons/package/devel/".
                      "linux32/" . lc($self->{buildType}) . "/esx/apps/$commandtool/" .
                      "$commandtool /bin",
                      "chmod +x /bin/$commandtool",
                      "ln -s /bin/$commandtool /sbin/$commandtool");

      # Setup dvfilter_ctl by executing the commands in @commands on the host
      foreach my $cmd (@dvfilterctlsetup) {
         $vdLogger->Info("Executing $cmd");
         $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                        $cmd);
         # Process the result
         if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
            $vdLogger->Error("Failed to execute $cmd");
            VDSetLastError("ESTAF");
            $vdLogger->Error(Dumper($result));
            return FAILURE;
         }
      }
   }

   # if agents are provided, then set them up too
   if (scalar(@agents)) {
      foreach my $agent (@agents) {
         if ($self->AddRemDVFAgentsOnHost($agent) eq FAILURE) {
            $vdLogger->Error("AddRemDVFAgentsOnHost returnted FAILURE");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
   }

   #Saving whether the host is setup or not doesn't work if it is not done
   # across different workloads because of PR 627979
   $self->{DVFilterHostSetup} = 1;
   return SUCCESS;
}


#########################################################################
#
#  AddRemDVFAgentsOnHost
#      Unload if the filter(s) is already loaded
#      Load the given filter agent(s)
#
#  Input:
#      As of now we cannot pass ref from workload hash and therefore
#      one agent is setup at a time. In future it should take list
#      of agents
#      agentname:operation (operation is add/rem)
#
#  Results:
#      Returns "SUCCESS", if no errors
#      Returns "FAILURE", in case of any error.
#
#  Side effects:
#      None.
#
#########################################################################

sub AddRemDVFAgentsOnHost
{
   my $self = shift;
   my $agent = shift;

   my $host = $self->{hostIP};
   my $result;
   my @agents = ();

   if (not defined $agent ||  !($self->{DVFilterHostSetup})) {
      $vdLogger->Error("No agent name provided or host setup is not done");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (not defined $self->{branch} ||
         (($self->{branch} !~ /esx41/i) &&
          ($self->{branch} !~ /esx[56]/i))) {
      $vdLogger->Error("undefined or unsupported branch");
      VDSetLastError("EiNVALID");
      return FAILURE;
   }

   if (ref($agent) eq "ARRAY") {
      @agents = @$agent;
   } else {
      push(@agents, $agent);
   }

   my $gConfig = new VDNetLib::Common::GlobalConfig();
   my $dvfagents = $gConfig->GetDVFilterAgents($self->{branch}, $self->{buildType});
   if (not defined $dvfagents) {
      $vdLogger->Error("DVfilter agent info is not found for " .
                       "branch $self->{branch}");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $vdLogger->Debug(Dumper($dvfagents));
   my $vmtree =  $self->{vmtree};

   # For each agent, perform the setup
   foreach my $agentInfo (@agents) {
      my ($idx, $operation) = split(/:/,$agentInfo);
      if (not defined $idx || not defined $operation) {
         $vdLogger->Error("Unknown DVfilter agent or operation");
         VDSetLastError("EiNVALID");
         return FAILURE;
      }
      if ($operation eq "") {
         $vdLogger->Error("empty operation passed");
         VDSetLastError("EiNVALID");
         return FAILURE;
      }

      # Get the agent name from the GlobalConfig::DVFilterAgents
      my $actualModName;
      my ($modInstance, $chrDevNum, $options);
      my $agentName;
      my $charDevName;

      $actualModName = $idx;
      $modInstance = ($idx =~ /(\d+$)/) ? $1 : undef;
      $idx =~ s/\-\d+$//;

      $agentName = $dvfagents->{$idx}{'name'};
      if (defined $dvfagents->{$idx}{'chardevname'}) {
         $charDevName = $dvfagents->{$idx}{'chardevname'};
         $charDevName = &$charDevName($agentName);
      }

      $vdLogger->Info("HostOperations->DVFilterHostSetup mod and agent" .
                      " name $actualModName $agentName");
      # unload the agent if it is already loaded
      # TODO: need to find what kind of errors an unload might throw
      # and process them
      if ($self->VMKModule("unload", $actualModName) eq FAILURE) {
         $vdLogger->Error("HostOperations->DVFilterHostSetup returned FAILURE");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      if ($self->RemoveDVFilterModFiles($agentName) eq FAILURE) {
         $vdLogger->Error(
               "HostOperations->DVFilterHostSetup returned FAILURE");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      # check char device corresponding to this agent is gone
      if (defined $charDevName) {
         $result = $self->{stafHelper}->STAFFSGetNodeType($self->{hostIP},
                                                          "$charDevName");
         if (defined $result) {
            $vdLogger->Warn("$charDevName is not removed, it might be okay");
         }
      }

      next if($operation eq "rem");
      next if($operation ne "add");

      # copy the agent module from build tree and load it
      # TODO: need to re-org this code here

      if (defined $modInstance) {
         $chrDevNum = DVFILTER_FW_CHRNO + $modInstance;
      }

      my $agentLoc = $dvfagents->{$idx}{'location'};
      my $command = "mkdir -p " . MODPATH . ';cp ' . $vmtree . $agentLoc .
                    "/$agentName " . MODPATH;

      $vdLogger->Info("Executing $command");
      $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
      # Process the result
      if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to execute $command");
         VDSetLastError("ESTAF");
         $vdLogger->Error(Dumper($result));
         return FAILURE;
      }

      if ($self->{branch} =~ /esx[56]/i) {
         if (defined $modInstance) {
            $options = "-m $actualModName $agentName " .
                       "DVFGENERIC_AGENT_DUMMY_NAME=dvfilter-dummy-$modInstance".
                       " DVFGENERIC_AGENT_FW_NAME=dvfilter-fw-$modInstance";
         } else {
            $options = " $agentName";
         }
      } elsif (($self->{branch} =~ /esx41/i) && (defined $modInstance)) {
         if (defined $modInstance) {
            $options = "-m $actualModName $agentName " .
                       "DVFILTERFW_NAME=dvfilter-fw--$modInstance".
                       " charDevMajor=$chrDevNum";
         } else {
            $options = " $agentName";
         }
      }

      if ($self->VMKModule(undef, $options) eq FAILURE) {
         $vdLogger->Error("HostOperations->DVFilterHostSetup returned FAILURE");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      # check char device corresponding to this agent is created
      if (defined $charDevName) {
         $result = $self->{stafHelper}->STAFFSGetNodeType($self->{hostIP},
                                                          "$charDevName");

         if (not defined $result) {
            $vdLogger->Error("$charDevName is not created");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }
   }
}


#########################################################################
#
#  VMKModule
#      Load/Unload vmkernel module using vmkload_mod command
#
# Input:
#      Module Name that needs to be loaded or unloaded or other op
#      Operation - could be undef if the caller passes all the input
#      options - optional options
#
# Results:
#      Returns "SUCCESS", if the module is unloaded successfully
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub VMKModule
{
   my $self = shift;
   my $operation= shift;
   # TODO: need to redo this functions interface after completely
   # finding out how different dvfilter agents are loaded/unloaded
   my $options = shift;

   my $host = $self->{hostIP};
   my $command;
   my $gConfig = new VDNetLib::Common::GlobalConfig();
   my $vmkloadOps = $gConfig->GetVMKLoadModOps();
   my $rsub;

   # allow this method to accept the complete input vmkload_mod from
   # the caller and just call vmkload_mod with this string
   if ((not defined $operation) ||
       (!exists($vmkloadOps->{$operation}))) {
      if (exists $vmkloadOps->{'_default_'}) {
            $rsub = $vmkloadOps->{'_default_'};
      }
   } else {
      $rsub = $vmkloadOps->{$operation};
   }

   $command = &$rsub($options);

   if (not defined $command) {
      $vdLogger->Error("Unknown operation or invalid parms passed");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $vdLogger->Info("VMKModule: Executing $command");
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   # Process the result
   # return SUCCESS if the unload operation fails because the module
   # isn't loaded
   # TODO: map the string values to SUCCESS in the vmkloadops hash
   if ((defined $result->{stdout}) &&
         ($result->{stdout} =~ /module not found/i)) {
      return SUCCESS;
   }

   if ((defined $result->{stdout}) &&
         ($result->{stdout} =~ /module symbols in use/i)) {
      # TODO: make it as error later if it has to be hard failure
      $vdLogger->Warn("unable to perform the operation " .
                       "$result->{stdout}");
      #VDSetLastError("EOPFAILED");
      #return FAILURE;
   }

   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to execute $command");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }
   return SUCCESS;

}


#########################################################################
#
#  RemoveDVFilterModFiles
#      Remove the module files
#
# Input:
#      vmkernel module name
#
# Results:
#      Returns "SUCCESS", if no STAF error
#      Returns "FAILURE", in case of STAF any error.
#
# Side effects:
#      None.
#
#########################################################################

sub RemoveDVFilterModFiles
{
   my $self = shift;
   my $moduleName = shift;
   my $host = $self->{hostIP};

   my $command = "rm -rf " . MODPATH . "$moduleName";
   $vdLogger->Info("Executing $command");
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   # Process the result
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to execute $command");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }
   return SUCCESS;
}

#########################################################################
#
#  GetBuildInfoForRacetrack --
#      Gets Build Information for racetrack
#
# Input:
#      None
#
# Results:
#      Returns "buildID, ESX Branch (like vsphere-2015) and buildType"
#      if there was no error executing the command
#      "FAILURE", in case of any error.
#
# Side effects:
#      Thie is a module function, not a class method. It is only used
#      in Session::Initialize to SetRacetrackBuildInfo
#
#########################################################################

sub GetBuildInfoForRacetrack
{
   my $hostIP = shift;
   my ($cmd, $result, $output, $stdout);

   my ($build, $branch, $version, $buildType);
   $cmd = "vmware -v";
   $branch = VDNetLib::Common::FindBuildInfo::GetBranchNameFromIP($hostIP);
   if ($branch eq FAILURE) {
      $vdLogger->Warn("Failed to get branch name from host $hostIP, " .
                      "continue to get it with $cmd");
   }

   if(VDNetLib::Common::Utilities::CreateSSHSession($hostIP,
         VDNetLib::Common::GlobalConfig::DEFAULT_ESX_USER,
         VDNetLib::Common::GlobalConfig::DEFAULT_ESX_PASSWD) eq FAILURE) {
      $vdLogger->Error("Create ssh session failed to host $hostIP");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   ($result, $output) = $sshSession->{$hostIP}->SshCommand($cmd);
   if ($result ne "0") {
      $vdLogger->Debug("SSH command $cmd failed:". Dumper($output));
      return FAILURE;
   }
   $stdout = join("", @$output);
   my $test;
   ($test, $build) = split(/-/,$stdout);
   chomp($build);

   # only first two digits of the version number is used, for example
   # for MN, it will be ESX5.0
   $output =~ /.*\s((\d\.\d)(\.\d)*)\s.*/;
   if (defined $2) {
      $version = $2;
      $vdLogger->Debug("Version = $version");
   }
   if (($branch eq FAILURE) && (defined $1)) {
      $branch = $1;
      $branch = 'ESX'."$branch";
   }

   $vdLogger->Debug("Build $build installed on host $hostIP " .
                    "is from branch $branch");
   $cmd = "vsish -e get /system/version";
   ($result, $output) = $sshSession->{$hostIP}->SshCommand($cmd);
   if ($result ne "0") {
      $vdLogger->Debug("SSH command $cmd failed:". Dumper($output));
      return FAILURE;
   }
   $stdout = join("", @$output);

   if ($stdout =~ /.*buildType\:(.*)\n.*/){
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


#########################################################################
#
#  GetBuildType
#      Get the build type of the host
#
# Input:
#      none
#
# Results:
#      Returns "BuildType" if there was no error executing vsish
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub GetBuildType
{
   my $self = shift;
   my $host = $self->{hostIP};

   my $command = "vsish -e get /system/version";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   # Process the result
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to execute $command");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }

   if ($result->{stdout} =~ /.*buildVersion\:(.*)\n.*/) {
      my $buildType = $1;
      $buildType =~ s/\d//g;
      $buildType =~ s/build-//g;
      if ($buildType !~ /beta|obj|release|debug/i) {
         $vdLogger->Warn("Unknown build or new build type");
         $vdLogger->Debug("unknown build type $buildType");
         $vdLogger->Debug("BuildType is $buildType");
      }
      $buildType = lc($buildType);
      # ESX "DEBUGbuild-XXXXXX" builds are actually obj
      $buildType =~ s/debug/obj/;
      $self->{buildType} = $buildType;
      return $buildType;
   } else {
      $vdLogger->Info("Can't find buildType");
      return FAILURE;
   }
}


#########################################################################
#
#  AddRemDVFilterToVM
#      Update vmx file of the VM with dvfilter
#
# Input:
#      adapter - The vm nic which will be added dvfilter
#      Colon separated filterstring with filter name, parms, and value
#
# Results:
#      Returns "SUCCESS" if there was no error updating vmx
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub AddRemDVFilterToVM
{
   my $self = shift;
   my %args = @_;
   my $vmAdapterObjArr = $args{adapters};
   my @filterString = eval($args{adddvfilter});
   if ($@) {
      $vdLogger->Error("Failed to load dvfilter array $@");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if (not defined $vmAdapterObjArr) {
      $vdLogger->Error("AddRemDVFilterToVM: invalid or undefined params passed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $host = $self->{hostIP};
   my ($mac, @lines);
   my $vmObj = $vmAdapterObjArr->[0]->{vmOpsObj};
   my $vmxFile =$vmObj->{vmx};
   foreach my $vmAdapterObj (@$vmAdapterObjArr) {
      my $eth = $vmAdapterObj->{macAddress};

      if ((not defined $vmxFile) || (not defined $eth) || (not @filterString)) {
         $vdLogger->Error("AddRemDVFilterToVM: invalid or undefined params passed");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      $vdLogger->Info("Entered AddRemDVFilterToVM params: $vmxFile, $eth, @filterString");
      # if eth is in MAC address format,
      if ($eth =~ /([0-9a-fA-F]{2}[:-]{1}){5}([0-9a-fA-F]{2})$/) {
         $mac = $eth;
         # get the ethernet unit number from MAC address
         if (($eth = VDNetLib::Common::Utilities::GetEthUnitNum($host, $vmxFile,
                      $mac, $self->{stafHelper})) eq FAILURE) {
            $vdLogger->Error("AddRemDVFilterToVM: GetEthUnitNum failed");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
      # filter is filter:param:value format, this is done as workload keys
      # cannot be set to single set of values
      foreach my $f (@filterString) {
         my ($filter, $parms, $value) = split(/:/,$f);
         if ((not defined $filter) || (not defined $parms) || (not defined $value)) {
            $vdLogger->Error("AddRemDVFilterToVM: filterString:$f" .
                             "passed is incorrect");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
         push(@lines, "$eth.$filter.$parms = $value");
      }
   }
   # prepare the string that needs to be added to the vmxfile
   #my @lines = ("$eth.$filter.$parms = $value");
   $vdLogger->Info("AddRemDVFilterToVM: Adding @lines to $vmxFile");
   if (VDNetLib::Common::Utilities::UpdateVMX($host,
                                              \@lines, $vmxFile,
                                              $self->{stafHelper}) eq
                                              FAILURE) {
      $vdLogger->Error("AddRemDVFilterToVM: UpdateVMX failed");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}

########################################################################
#
# ConfigureFirewallRule--
#     Method to configure firewall on the given host
#     This method will call specific function according differnet
#     action name.
#
# Input:
#     A hash containing firewall configure parameters.
#
# Results:
#     SUCCESS, if firewall is configured correctly;
#     FAILURE, in case of any error;
#
########################################################################

sub ConfigureFirewallRule
{
   my $self = shift;
   my %args = @_;
   my $action = $args{firewall};
   my $result = FAILURE;
   $vdLogger->Debug("action:$action");
   my %operationNames = (
      'list'  => {
         'method'           => '$self->FirewallRulesList($args{service_name})',
      },
      'ListAllowedIPInvalidValue'  => {
         'method'           => '$self->ListAllowedIPInvalidValue($args{service_name})',
      },
      'invalidsetdisabled'  => {
         'method'           => '$self->FirewallinvalidSetDisabledRule($args{service_name}, $args{operation})',
      },
      'setenabled'  => {
          'method'           => '$self->FirewallSetEnabledRule($args{service_name}, $args{operation})',
      },
      'setallowedall'  => {
         'method'           => '$self->FirewallSetAllowedAll($args{service_name}, $args{operation})',
      },
      'setstatus'  => {
         'method'           => '$self->FirewallSetStatus($args{status})',
      },
      'CheckIPExist'  => {
         'method'           => '$self->FirewallCheckIPExist($args{service_name}, $args{ipaddress})',
      },
      'CheckRule'  => {
         'method'           => '$self->FirewallCheckRule($args{service_name}, $args{operation})',
      },
      'IPSet'  => {
         'method'           => '$self->FirewallIPSet($args{service_name}, $args{operation}, $args{ipaddress})',
      },
      'CheckDupService'  => {
         'method'           => '$self->FirewallCheckDupService($args{service_name})',
      },
      'CheckDaemonStatus'  => {
         'method'           => '$self->FirewallCheckDaemonStatus($args{service_name}, $args{status})',
      },
      'checkconflictrule'  => {
         'method'           => '$self->FirewallCheckConflictRule($args{service_name}, $args{ipaddress})',
      },
      'checkallowedall'  => {
         'method'           => '$self->FirewallCheckAllowedAll($args{service_name}, $args{operation})',
      },
      'InvalidIPSet'  => {
         'method'           => '$self->FirewallInvalidIPSet($args{service_name}, $args{operation}, $args{ipaddress}, $args{check})',
      },
      'InvalidSrvName'  => {
         'method'           => '$self->FirewallInvalidSrvName($args{service_name}, $args{operation}, $args{ipaddress})',
      },
      'InvalidService'  => {
         'method'           => '$self->FirewallInvalidService($args{service_name}, $args{operation})',
      },
      'ConfigureService'  => {
         'method'           => '$self->FirewallConfigureService($args{service_name}, $args{direction}, $args{l4protoco}, $args{porttype}, $args{portnumber}, $args{operation})',
      },
      'InvalidXMLTagConfig'  => {
         'method'           => '$self->FirewallInvalidXMLTagConfig($args{service_name}, $args{direction}, $args{l4protoco}, $args{porttype}, $args{portnumber}, $args{operation})',
      },
   );

   $vdLogger->Debug("function : " . Dumper($operationNames{$action}));
   if ( not defined $operationNames{$action}{method} ) {
      $vdLogger->Error("Invalid input action : $action");
      return FAILURE;
   }
   $result = eval $operationNames{$action}{method};

   return $result;
}

########################################################################
#
# FirewallRulesList --
#      This method List the service status which include inbound/outbound
#      TCP/UDP port range,enabled/disabled,service name and dameon status.
#
# Input:
#      servicename: name of the firewall rule (optional)
#
# Results:
#      Returns "SUCCESS", if list rule is successfull
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub FirewallRulesList {
   my $self          = shift;
   my $servicename   = shift;
   my $command;
   # command to list the firewall rule set.
   if (not defined $servicename) {
      $command = "esxcli network firewall ruleset list";
   } else {
		$command = "esxcli network firewall ruleset list -r $servicename";
   }
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if (($result->{rc} != 0) || ($result->{stderr} =~ m/.*Errors:.*/i)){
		$vdLogger->Error("STAF command to list firewall rule set failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $vdLogger->Info("Successfully list the default firewall rule");
   $vdLogger->Info(Dumper($result));
   return SUCCESS;

}


########################################################################
#
# FirewallSetEnabledRule --
#      This method enables/disables the service based on the flag
#      (disabled/enabled) passed to it.
#
# Input:
#      servicename: name of the service (required)
#      flag       : enabled or disabled (required)
#
# Results:
#      Returns "SUCCESS", if the setting successfully or the given name of
#               service already disable or enabled.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub FirewallSetEnabledRule {
   my $self          = shift;
   my $servicename   = shift;
   my $flag          = shift;
   my $command;
   # command to set firewall rule enable or disable
   my $status;
   if ($flag=~ m/disabled/i) {
	$status="false";
   }
   if ($flag=~ m/enabled/i) {
      $status="true";
   }
   $command = "esxcli network firewall ruleset set -e $status -r $servicename";

   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to set firewall rule set failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($result->{stderr} =~ m/.*Already enabled.*/i){
      $vdLogger->Info("The service of $servicename has already $flag");
      return SUCCESS;
   }
   if ($result->{stderr} =~ m/.*Invalid Ruleset Id.*/i){
      $vdLogger->Error("The service name $servicename is invalid or unsupport:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($self->FirewallCheckRule($servicename,$flag) eq SUCCESS) {
			$vdLogger->Info("Successfully set the firewall rule $servicename to $flag");
			$vdLogger->Info(Dumper($result));
			return SUCCESS;
	} else {
			$vdLogger->Error("Failed set the firewall rule $servicename to $flag");
			$vdLogger->Info(Dumper($result));
			return FAILURE;
	}
}


########################################################################
#
# ListAllowedIPInvalidValue --
#      This method Tries to list an invalid service, and fails as expected
#
# Input:
#      servicename: name of the service (required)
##
# Results:
#      Returns "SUCCESS", if the setting successful(most unlikely)
#      Returns "FAILURE", since the passed service name is invalid
#
# Side effects:
#      None.
#
########################################################################

sub ListAllowedIPInvalidValue {
  my $self          = shift;
   my $servicename   = shift;
    my $command;
   # command to set firewall rule enable or disable
   my $status;
   my $check;
   if ($servicename=~ m/multiple/i) {
       $servicename="sshClient,WOL";
     }
   $vdLogger->Info("The service name is $servicename");
   $command = "esxcli network firewall ruleset allowedip list -r $servicename";

   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

 if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to list the rules failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
    }

  if ($result->{stdout} =~ m/.*Ruleset Not Found.*/i){
      $vdLogger->Error("The  is invalid or unsupport ruleset id:" .
                       Dumper($result));
      return SUCCESS;
   }
  return FAILURE;

}

########################################################################
#
# FirewallinvalidSetDisabledRule --
#      This method Tries to enable/disable a invalid service, and fails as expected
#
# Input:
#      servicename: name of the service (required)
#      flag       : enabled/disabled (required)
#
# Results:
#      Returns "SUCCESS", if the setting successful(most unlikely)
#      Returns "FAILURE", since the passed service name is invalid
#
# Side effects:
#      None.
#
########################################################################



sub FirewallinvalidSetDisabledRule {
   my $self          = shift;
   my $servicename   = shift;
   my $flag          = shift;
   my $command;
   # command to set firewall rule enable or disable
   my $status;
   my $check;
   if ($servicename=~ m/multiple/i) {
       $servicename="sshClient,WOL";
     }
   if ($flag=~ m/disabled/i) {
        $status="false";
   }
   elsif ($flag=~ m/enabled/i) {
      $status="true";
   } else {
       $status="falsevalue";
   }

   $vdLogger->Info("The service name is $servicename");
   $command = "esxcli network firewall ruleset set -e $status -r $servicename";

   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

 if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to firewall failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
    }

   if ($result->{stdout} =~ m/.*Already enabled.*/i){
      $vdLogger->Info("The service of $servicename has already $flag");
      return FAILURE;
   }
  if ($result->{stdout} =~ m/.*Invalid Ruleset Id.*/i){
      $vdLogger->Error("The service name $servicename is invalid or unsupport:" .
                       Dumper($result));
      $vdLogger->Info("The service could not be disabled as the serice name was invalid : $result->{stdout}");
      return SUCCESS;
   }
   if ($result->{stdout} =~ m/.*Error: While processing.*/i){
      $vdLogger->Error("The service name argument to enable a service is true and disable a service is false, you have supplied $flag which is unsupported:" .
                       Dumper($result));
      $vdLogger->Info("There was an error as the supplied parameter was invalid : $result->{stdout}");
      return SUCCESS;
   }
  return FAILURE;

}


########################################################################
#
# FirewallSetAllowedAll --
#      This method Set allowed all ip address flag for service ruleset
#
# Input:
#      servicename: name of the firewall rule (required)
#      flag       : true or false (required)
#
# Results:
#      Returns "SUCCESS", if the setting for given service name
#                       successfully.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub FirewallSetAllowedAll {
   my $self          = shift;
   my $servicename   = shift;
   my $flag          = shift;
   my $command;

   $command = "esxcli network firewall ruleset set -a $flag -r $servicename";

   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if ($result->{rc} != 0){
      $vdLogger->Error("STAF command to set allowed all ip address failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($result->{stderr} =~ m/.*already.*/i){
      $vdLogger->Info("This rule set has been already allowed all ip $flag");
      return SUCCESS;
   }
   $vdLogger->Info("Successfully set allowed all ip address for given firewall rule");
   $vdLogger->Info(Dumper($result));
   return SUCCESS;

}


########################################################################
#
# FirewallSetStatus --
#      This method will set firewall status(disable/enabled)
#
# Input:
#      status     : enalbed/disabled (required)
#
# Results:
#      Returns "SUCCESS", if the setting successfully.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub FirewallSetStatus{
   my $self          = shift;
   my $status        = shift;
   my $command;
   if ($status=~ m/disabled/i) {
      $status="false";
   }
   if ($status=~ m/enabled/i) {
      $status="true";
   }
   $command = "esxcli network firewall set -e $status";

   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if (($result->{rc} != 0) || ($result->{stderr} =~ m/.*Errors:.*/i)){
      $vdLogger->Error("STAF command to set firewall status failed" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

	if ($self->FirewallCheckStatus($status) eq FAILURE) {
			$vdLogger->Error("Failed set the firewall status to $status");
			return SUCCESS;
	}

   $vdLogger->Info("Successfully set the firewall status to $status");
   $vdLogger->Info(Dumper($result));
   return SUCCESS;

}


########################################################################
#
# FirewallCheckIPExist --
#      This method check ip addresses exist in allowed list
#      for the given service name.
#
# Input:
#      servicename: name of the firewall rule (required)
#      IP         : IP address (required)
#
# Results:
#      Returns "SUCCESS", if the IP address in allowed list
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub FirewallCheckIPExist {
   my $self          = shift;
   my $servicename   = shift;
   my $ip            = shift;
   my $command;

   $command = "esxcli network firewall ruleset allowedip list -r $servicename";

   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if (($result->{rc} != 0) || ($result->{stderr} =~ m/.*Errors:.*/i)){
      $vdLogger->Error("STAF command to list allowed ip failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   my @tmpRes = split("\n",$result->{stdout});
   foreach my $res (@tmpRes) {
      if ($res=~ m/.*$servicename\s+(.*)/i) {
         if (not defined $1){
            $vdLogger->Warn("The IP $ip doesn't exist in allowed ip list");
            return FAILURE;
         } else {
            my @ipLists = split(",",$1);
            foreach my $myip (@ipLists) {
               if ($myip=~ m/\b$ip\b/i) {
                  $vdLogger->Info("The IP $ip has already exist in allowed ip list");
                  return SUCCESS;
               }
            }
         }
      }
   }
   $vdLogger->Error("The IP $ip doesn't exist in allowed ip list");
   return FAILURE;

}


########################################################################
#
# FirewallCheckRule --
#      This method check the rule status(disabled or enabled)
#                                  for the given service name.
#
# Input:
#      servicename: name of the firewall rule (required)
#      flag       : enabled or disabled (required)
#
# Results:
#      Returns "SUCCESS", if the IP address in allowed list
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub FirewallCheckRule {
   my $self          = shift;
   my $servicename   = shift;
   my $flag          = shift;
   my $command;

   $command = "esxcli network firewall ruleset list -r $servicename";
   my $status;
   if ($flag=~ m/disabled/i) {
		$status="false";
   }
   if ($flag=~ m/enabled/i) {
		$status="true";
   }
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if (($result->{rc} != 0) || ($result->{stderr} =~ m/.*Errors:.*/i)){
      $vdLogger->Error("STAF command to list firewall rule failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   my @tmpRes = split("\n",$result->{stdout});
   foreach my $res (@tmpRes) {
		if ($res=~ m/.*$servicename\s+$status.*/i) {
			$vdLogger->Info("The firewall service rule matched");
			return SUCCESS;
		}
   }

   $vdLogger->Info(Dumper($result));
   return FAILURE;

}


########################################################################
#
# FirewallIPSet --
#      This method set ip related configure(add/remove/list)
#
# Input:
#      servicename: name of the firewall rule (required)
#      action     : add/remove/list (required)
#      IP         : IP address or IP subnet
#                   action is add/remove (required)
#
# Results:
#      Returns "SUCCESS", if setting successfully.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub FirewallIPSet {
   my $self          = shift;
   my $servicename   = shift;
   my $action        = shift;
   my $ip            = shift;
   my $command;
   my $checkforlimit;
   my $i;
   my $startip;
   my $endip;
   my $fthreeoctet;
	if ($ip =~ m/((\d+.\d+.\d+).(\d+))-(\d+)/i){
	$startip = $3;
	$endip = $4;
	$ip = $1;
	$checkforlimit = $endip - $startip + 1;
        $fthreeoctet = $2;
     if ($action =~ m/remove/i){
              $checkforlimit = $endip -$startip;
		}
	}
	else {
        $checkforlimit = 1;
          $startip = 1;
        }
for ($i = $startip; $i <= $checkforlimit; $i++){
    if ($i > $startip){
	$ip = $fthreeoctet.".".$i;
	}
if ($action =~ m/add/i) {

                $command = "esxcli network firewall ruleset allowedip add -i $ip -r $servicename";
 }
   if ($action =~ m/remove/i) {
                $command = "esxcli network firewall ruleset allowedip remove -i $ip -r $servicename";
   }
   if ($action =~ m/list/i) {
      $command = "esxcli network firewall ruleset allowedip list -r $servicename";
   }
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if (($result->{rc} != 0) || ($result->{stderr} =~ m/.*Errors:.*/i)){
      $vdLogger->Error("STAF command to $action allowed ip for firewall rule set failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($result->{stderr} =~ m/.*limit exceeded*/i)
   {
   $vdLogger->Info("The ip address $ip can not be added to service $servicename allowed ip list as the limit has exeeded at $checkforlimit");
   }


   if (($result->{stderr} =~ m/.*Invalid Ruleset Id.*/i) || ($result->{stderr} =~ m/.*Ruleset Not Found.*/i)){
      $vdLogger->Error("The service name $servicename is invalid or unsupport:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

        if ($action =~ m/add/i) {

                if ($self->FirewallCheckIPExist($servicename,$ip) eq SUCCESS) {
                        $vdLogger->Info("The ip address $ip has been added to service $servicename allowed ip list.");

                } else {
                        $vdLogger->Error("The ip address $ip has Not been added to service $servicename allowed ip list.");
                 if ($checkforlimit == 129){
                                    $vdLogger->Info("The limit exceeded the number of ips in the allowed list, that is 128. So this failure is expected");
	             } else {
				return FAILURE;
				}
                }
        }
   if ($action =~ m/remove/i) {
                if ($self->FirewallCheckIPExist($servicename,$ip) eq FAILURE) {
                        $vdLogger->Info("The ip address $ip has been removed from service $servicename allowed ip list.");
                } else {
                        $vdLogger->Error("The ip address $ip has Not been removed from service $servicename allowed ip list.");                return FAILURE;

                }
   }
}
   return SUCCESS;

}

########################################################################
#
# FirewallCheckDupService --
#      This method check whether has duplicate service
#
# Input:
#      servicename: name of the firewall rule (required)
#
# Results:
#      Returns "SUCCESS", if setting successfully.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub FirewallCheckDupService {
   my $self          = shift;
   my $servicename   = shift;
   my $command;

	$command = "esxcli network firewall ruleset list";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if (($result->{rc} != 0) || ($result->{stderr} =~ m/.*Errors:.*/i)){
		$vdLogger->Error("STAF command to list firewall rule set failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   my @tmpRes = split("\n",$result->{stdout});
   my $count=0;
	foreach my $res (@tmpRes) {
		if ($res=~ m/$servicename\s+.*/i) {
			$vdLogger->Info("The firewall service name matched");
			$count++;
		}
   }

   if ($count ==0) {
      $vdLogger->Error("Doesn't find service name:$servicename in service list.");
      return FAILURE;
   }
   if ($count > 1) {
      $vdLogger->Error("Has duplicate service name:$servicename in service list.");
      return FAILURE;
   }

   $vdLogger->Info("Has Not duplicate service name:$servicename in service list.");
   $vdLogger->Info(Dumper($result));
   return SUCCESS;

}


########################################################################
#
# FirewallCheckStatus --
#      This method check Firewall status
#
# Input:
#      status     : enabled/disabled (required)
#
# Results:
#      Returns "SUCCESS", if setting successfully.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub FirewallCheckStatus {
   my $self          = shift;
   my $status        = shift;
   my $command;

   $command = "esxcli network firewall get";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if (($result->{rc} != 0) || ($result->{stderr} =~ m/.*Errors:.*/i)){
      $vdLogger->Error("STAF command to get firewall status failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my @tmpRes = split("\n",$result->{stdout});
	foreach my $res (@tmpRes) {
		if ($res=~ m/.*Enabled: $status/i) {
			$vdLogger->Info("The firewall status is $status");
			return SUCCESS;
		}
   }

   $vdLogger->Error("The firewall status is not $status.");
   $vdLogger->Info(Dumper($result));
   return FAILURE;

}


########################################################################
#
# Reconnect --
#      Reconnect esx host after rebooting
#
# Input:
#      retries : number of retries (Optional, default is 1)
#
# Results:
#      Returns "SUCCESS", if reboot successfully.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub Reconnect {
   my $self                = shift;
   my $retry               = shift;
   my $useExistingPassword = shift;
   my $sleepInterval       =  shift;

   $useExistingPassword = (defined $useExistingPassword) ?
                           $useExistingPassword : 0;
   $sleepInterval = (defined $sleepInterval) ? $sleepInterval : 30;

   my @passwords;
   if ($useExistingPassword) {
      push (@passwords, $self->{'password'});
   } else {
      @passwords = ('','ca\$hc0w', 'vmw@re');
   }
   $retry = (defined $retry) ? $retry : 1;

   # Disconnect the stale anchors before trying to reconnect
   my $anchor = $self->{hostIP} . ":root";
   $self->{stafHelper}->STAFDisconnectAllAnchors($anchor);

   my $command;
   my $result;
   $self->{stafHostAnchor} = undef; # clear any staf anchor set
   while ($retry && (not defined $self->{stafHostAnchor})) {
      $vdLogger->Debug("Trying to create staf anchor...");
      foreach my $pwd (@passwords) {
         $command = "CONNECT AGENT $self->{hostIP} SSL USERID \"root\" " .
                    "PASSWORD \"$pwd\"";
         $result = $self->{stafHelper}->STAFSubmitHostCommand("local",
                                                              $command);
         if ($result->{rc} == 0) {
            $self->{stafHostAnchor} = $result->{result};
            $self->{'password'} = $pwd;
            $pwd =~ s/\\//g; # ssh doesn't like escape \
                  $self->{sshPassword} = $pwd;
            last;
         }
      }
      sleep $sleepInterval;
      $retry--;
   }

   if (not defined $self->{stafHostAnchor}) {
      $vdLogger->Error("Failed to create staf anchor");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   #
   # The STAF anchor for host staf service will not work for VM staf service,
   # hence creating another anchor.
   #
   $command = "CONNECT AGENT $self->{hostIP} SSL USERID \"root\" " .
              "PASSWORD \"$self->{password}\"";
   $result = $self->{stafHelper}->STAFSubmitVMCommand("local",
                                                      $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to create staf anchor");
      $vdLogger->Debug("Error" . Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $self->{stafVMAnchor} = $result->{result};
   return SUCCESS;

}


########################################################################
#
# AsyncReboot --
#      Start ESX Reboot asynchronously.
#      Note: This method only starts the reboot process, it does not monitor
#      the hosts or try to make the host recover from the reboot process. For
#      that you have to make seperate calls to the methods: IsAccessible() and
#      ReceoverFromReboot().
#
# Input:
#      None
#
# Results:
#      Returns "SUCCESS", if reboot initiated successfully.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub AsyncReboot
{
   my $self = shift;
   my $pyObj = $self->GetInlinePyObject();
   my $result = CallMethodWithKWArgs($pyObj, 'async_reboot', {'force' => 1});
   if($result eq FAILURE){
       $vdLogger->Error("Could not perform async reboot on $self->{hostIP}");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
   $vdLogger->Info("Async reboot on $self->{hostIP} has started");
   return SUCCESS;
}


########################################################################
#
# IsAccessible --
#      Checks to see if ESX is up
#
# Input:
#      None
#
# Results:
#      Returns "SUCCESS", if ESX is accessible.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub IsAccessible
{
   my $self = shift;
   if (VDNetLib::Common::Utilities::Ping($self->{hostIP})) {
      $vdLogger->Debug("$self->{hostIP} not accessible");
      return FAILURE;
   }
   $vdLogger->Info("Host is accessible.");
   return SUCCESS;
}


########################################################################
#
# RecoverFromReboot --
#      Does reconnection and recovery of ESX after reboot
#
# Input:
#      None
#
# Results:
#      Returns "SUCCESS", if recovery successfully.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub RecoverFromReboot
{
   my $self = shift;
   if ($self->Reconnect(30) eq FAILURE) {
      $vdLogger->Error("The host reboot failed since staf anchor can not create.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # PR 1122233 ConfigureHostForVDNet is enough for reboot. Since our test cases are for
   # pxeinstall, not pxe boot. For pxe boot cases, user should have way to save runtime
   # objects before reboot.
   if (FAILURE eq $self->ConfigureHostForVDNet()) {
      $vdLogger->Error("Host configuration for vdnet on $self->{hostIP}");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   #PR 1127475
   if (FAILURE eq $self->SetPSODTimeout(1)) {
      $vdLogger->Error("Set PSOD timeout failed on host $self->{hostIP}");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $vdLogger->Info("The host reboot successfully.");
   return SUCCESS;
}


########################################################################
#
# Reboot --
#      Reboot esx host forcefully irrespective of whether the host
#      is in maintenance mode or not
#
# Input:
#      None
#
# Results:
#      Returns "SUCCESS", if reboot successfully.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub Reboot {
   my $self	= shift;
   my $command;
   my $pyObj = $self->GetInlinePyObject();
   my $result = CallMethodWithKWArgs($pyObj,
                                     'reboot',
                                     {'force' => 1});

   if ($result ne "success") {
      $vdLogger->Error("reboot api task did not return success");
      VDSetLastError("EOPFAILED");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Waiting for ESX host rebooting.
    $vdLogger->Info("Waiting for the Host to Reboot...");
    sleep(120);
    my $inputHash;
    $inputHash->{'method'} = 'IsAccessible';
    $inputHash->{'obj'} = $self;
    $inputHash->{'param'} = undef;
    $inputHash->{'timeout'} = 20*60;
    $inputHash->{'sleep'} = 60;
    VDNetLib::Common::Utilities::RetryMethod($inputHash);

   # Recovering from reboot
   if ($self->RecoverFromReboot() eq FAILURE) {
      $vdLogger->Error("$self->{hostIP} didnot recover from reboot");
   }

   return SUCCESS;
}


#########################################################################
#
# GetVMIIndexInfo --
#      This method returns an array which contains the vmi entry index
#      for vmi summary information.
#
# Input:
#      vmiPath (scalar): absolute path of a vmi path (required)
#
# Results:
#      Returns the VMI index info output
#      Returns "FAILURE" in case of any error.
#
# Side effects:
#      None
#
#########################################################################

sub GetVMIIndexInfo
{
   my $self = shift;
   my $vmiPath = shift;
   my $command = "vsish -e ls $vmiPath";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if ($result->{rc} != 0) {
      $vdLogger->Debug("STAF returned result is  " . Dumper($result));
      $vdLogger->Error("Failed to execute command $command on " .
                       $self->{hostIP});
       VDSetLastError("ESTAF");
       return FAILURE;
   }
   return $result->{stdout};
}


########################################################################
#
# GetVMISummary --
#      This method returns a hash reference which has the information
#      about the vmi summary information.
#
# Input:
#      vmiPath (scalar): absolute path of a vmi path (required)
#
# Results:
#      Returns the VMI summary hash reference corresponding to the
#              given vmi path;
#      Returns "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetVMISummary
{
   my $self = shift;
   my $vmiPath = shift;
   my $summary;
   my $command = "vsish -e get $vmiPath";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if ($result->{rc} != 0) {
      $vdLogger->Debug("STAF returned result is  " . Dumper($result));
      $vdLogger->Error("Failed to execute command $command on " .
                       $self->{hostIP});
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   foreach my $line (split("\n", $result->{stdout})) {
      if ($line =~ /:/) {
         my ($key, $value) = split(":", $line, 2);
         $key =~ s/(^\s+|\s+$)//g;
         $value =~ s/(^\s+|\s+$)//g;
         if ((not defined $key) or (not defined $value) or ($key eq "")) {
            next;
         }
         $vdLogger->Debug("The VMI key " . $key . " holds value equals to" .
                          $value);
         $summary->{$key} = $value;
      }
   }
   return $summary;
}


#########################################################################
#
#  VerifyVMKLog --
#      Verify the vmkernel log for a given pattern from the
#      $self->{vmklogEOF} position in the /var/log/vmkernel.log
#
# Input:
#      pattern string to be searched for
#
# Results:
#      Returns "SUCCESS" if there was no error while searching
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub VerifyVMKLog
{
   my $self = shift;
   my $pattern = shift;
   my $file = shift;

   my $host = $self->{hostIP};
   $file = (defined $file) ? $file : VMKRNLLOGFILE;

   if (not defined $pattern) {
      $vdLogger->Error("VerifyVMKLog: pattern not defined");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my %parseFileIn = (
           'ip' => $host,
           'file' => $file,
   );


   my $ret;
   my $p = new VDNetLib::Common::ParseFile(\%parseFileIn);
   my $in;
   if (!open $in, '<', '/tmp/vmkloginfo') {
      $vdLogger->Error("VerifyVMKLog: open /tmp/vmkloginfo failed");
      return FAILURE;
   }

   my $vmkloginfo;
   {
       local $/;    # slurp mode
       $vmkloginfo = eval <$in>;
   }
   close $in;
   if (not defined $vmkloginfo->{vmklogEOF}) {
      $vdLogger->Info("vmklogEOF is undefined, will search for " .
                      "the pattern the whole file");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $vdLogger->Info("VerifyVMKLog: searching pattern in $file\n");
   if (($ret = $p->SearchPattern($vmkloginfo->{vmklogEOF},
                                 ${pattern})) eq FAILURE) {
      $vdLogger->Error("ParseFile::SearchPattern returned failure");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($ret eq VDNetLib::Common::GlobalConfig::TRUE) {
      $vdLogger->Info("Pattern:$pattern found in $file");
      return SUCCESS;
   } else {
      return FAILURE;
   }
   # save the current EOF to $self{vmkloglastEOF}, not used
   # currently, but can be used later, the next log can be
   # searched started from the current EOF as opposed to the
   # session's EOF -- the below stmt is useless
   $self->{vmkloglastEOF} if (($ret = $p->GetCurrentPos()) ne FAILURE);

}


#########################################################################
#
#  GetBranchInfo --
#      Gets branch information from vmware -v command output
#
# Input:
#      vmware -v command output optional arg
#
# Results:
#      Returns "branch" if there was no error executing the command
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub GetBranchInfo
{
   my $self = shift;
   my $vmwareCmdOut = shift;
   my ($cmd, $result);

   if (not defined $vmwareCmdOut) {
      # if the cmd output is not provided then execute the vmware -v command
      $cmd = "vmware -v";

      $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $cmd);
      if ($result->{rc} != 0) {
         $vdLogger->Error("STAF command $cmd failed:" .
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      $vmwareCmdOut = $result->{stdout};
   }

   # only first two digits of the version number is used, for example
   # for MN, it will be esx50
   if (defined $vmwareCmdOut) {
      $vdLogger->Info("vmware -v output is $vmwareCmdOut");
      $self->{branch} = ($vmwareCmdOut =~ /.*(\d\.\d)\..*/) ? $1 : undef;
      if (defined $self->{branch}) {
         $self->{branch} =~ s/\.//g;
         $self->{branch} = 'esx'."$self->{branch}";
         $vdLogger->Info("branch is $self->{branch}");
      }
      return $self->{branch};
   }
   $vdLogger->Error("Unable to get branch info");
   VDSetLastError("EFAIL");
   return FAILURE;
}



########################################################################
#
# GetVMTree --
#      This method returns the build tree for the ESX host
#
# Input:
#      $build, the number of ESX build; (OPTIONAL)
#
# Results:
#      Returns path to the build tree, if we were able to find it.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      Build tree may be mounted if it wasn't already.
#
########################################################################

sub GetVMTree
{
   my $self = shift;
   my $build = shift;
   my $cmd;
   my $command;
   my $storage;
   my $result;
   my $data;

   if (defined $self->{vmtree} ) {
      $vdLogger->Info("VMTREE=$self->{vmtree}");
      return $self->{vmtree};
   }

   # Try to use VMTREE from ESX host
   $cmd = "echo -n \$VMTREE";
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                  $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command $cmd failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $vmtree = $result->{stdout};
   if ($vmtree ne "") {
      # Check if ESX host has VMTREE already mounted
      $cmd = "ls -d $vmtree";
      $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $cmd);
      if ($result->{rc} != 0) {
         $vdLogger->Error("STAF command $cmd failed:" .
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{exitCode} == 0) {
         $self->{vmtree} = $vmtree;
         $vdLogger->Info("VMTREE=$self->{vmtree}");
         if (($self->{buildType} = $self->GetBuildType()) eq FAILURE) {
            $vdLogger->Error("HostOperations->GetBuildType returned FAILURE");
            VDSetLastError("EFAIL");
            $self->{buildType} = undef;
            return FAILURE;
         }
         return $vmtree;
      }
   }

   if ((not defined $build) || ($build =~ /default/i)) {
      # Find the build number
      #
      $cmd = "vmware -v";
      $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                        $cmd);
      if ($result->{rc} != 0) {
         $vdLogger->Error("STAF command $cmd failed:" .
                         Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      ($build, $build) = split(/-/, $result->{stdout});
      my $vmwareCmdOut = $result->{stdout};
      chomp($build);
   }

   #
   # Find build tree
   #
   my $buildinfo =
       VDNetLib::Common::FindBuildInfo::getOfficialBuildInfo($build);
   if ($buildinfo eq FAILURE) {
       return FAILURE;
   }

   if (!defined($buildinfo->{product}) || $buildinfo->{product} ne "server") {
       # seems like this build is wrong, try a sandbox build
       $vdLogger->Debug("trying to query for sandbox build.");
       $buildinfo =
          VDNetLib::Common::FindBuildInfo::getSandboxBuildInfo($build);
       if ($buildinfo eq FAILURE) {
           return FAILURE;
       }
   }

   if (!defined($buildinfo->{buildtree}) || !defined($buildinfo->{buildtype}) ||
       !defined($buildinfo->{product}) || $buildinfo->{product} ne "server") {
      $vdLogger->Error("Unable to get build tree from buildweb, and ESX " .
                       "host does not already have VMTREE mounted. If this " .
                       "is a developer build, make sure the build tree is ".
                       "already mounted." .
                       "result: " . Dumper($buildinfo));
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   if ($buildinfo->{ondisk} eq "false") {
      $vdLogger->Error("Build $build needs to be restored from tape. " .
                       "Please make the request through buildweb.");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $vmtree       = $buildinfo->{buildtree} . "/bora";
   my $buildtype = $buildinfo->{buildtype};

   $vdLogger->Info("vmtree=$vmtree" );

   if ($vmtree =~ m/^\/build\/(\w+)\//) {
     $storage = $1;
   } else {
     $vdLogger->Error("Unknown build type or build query failed: $vmtree" );
     VDSetLastError("EFAIL");
     return FAILURE;
   }

   my $storage_host = "build-".$storage;
   my $cmd_storage  = "esxcfg-nas -a -o $storage_host -s /$storage $storage ";
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                  $cmd_storage);

   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to create $cmd_storage failed:" .
                      Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   #
   # if $result->{exitCode} == 1 means the mount point already exported, which
   # is ok
   #
   if ($result->{exitCode} != 0 && $result->{exitCode} != 1){
       $vdLogger->Error("STAF command $cmd_storage failed:" .
                       Dumper($result));
       VDSetLastError("ESTAF");
       return FAILURE;
   }

   $vdLogger->Info("build-storage is successfully mounted");

   $cmd  = "readlink -f /vmfs/volumes/$storage";
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                  $cmd);

   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to create $cmd_storage failed:" .
                      Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $storage_uuid = $result->{stdout};
   chomp($storage_uuid);

   my $cmd_ln_storage =  "ln -sf $storage_uuid /build/$storage";
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                  $cmd_ln_storage);

   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to create $cmd_ln_storage failed:" .
                      Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $vdLogger->Info("VMTREE Path = $vmtree");
   $self->{build} = $build;
   $self->{vmtree} = $vmtree;
   $self->{buildtype} = $buildtype;

   return $vmtree
}

#########################################################################
#
#  DVFilterCtl --
#      Execute dvfilter_ctl command on the host with the options given
#      in the workload hash.
#      This workload should be called after calling DVFilterHostSetup
#      workload.
#
# Input:
#      DVfilter Agent name
#      testbed hash
#      A hash containing command option and value of the option
#
# Results:
#      Returns "SUCCESS" if there was no error executing the command
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub DVFilterCtl
{
   my $self = shift;
   my %args = @_;
   my $vmObj = $args{vm};
   my $vmName = $vmObj->{displayName};
   my $tested_ref = undef;
   my ($options, $command, $result);
   my $filterName;
   my $gConfig = new VDNetLib::Common::GlobalConfig();
   my $dvfCtl = $gConfig->DVFilterCtlOps();

   $self->GetBranchInfo() if (not defined $self->{branch});
   # assuming -D option is required for any option, if the assumption is
   # incorrect then we will take -D also from the workload hash
   my $rsub = $dvfCtl->{device}{method};

   my $agentName = $args{dvfilterctl};

   my $modInstance = ($agentName =~ /(\d+$)/) ? $1 : "";
   $agentName =~ s/\-\d+$//;

   $options = "";
   if (!$args{vmip}) {  # fastpath dvfilter-fw or dvfilter-fw-xx
      $options = &$rsub(lc($self->{branch}), $agentName);
      if ($modInstance =~ /^\d+$/) {
         $options = $options . '-' . $modInstance;
      }
      if ((not defined $options) || ($options eq FAILURE)) {
         $vdLogger->Error("Unable to find the device ID");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   } else { # slowpath forwarder dvfilter-dummy or dvfilter-dummy-xx
         $options =  $options . " -H $args{vmip} ";
   }

   # TODO, if the filtername is applicable to both kl next and MN
   # then remove the below branch check.
   if ($self->{branch} =~ /esx[56]/i) {
      $filterName = $self->GetFilterName($args{dvfilterctl}, $vmName);
      if ((defined $filterName) && ($filterName ne FAILURE) &&
          ($filterName ne VDNetLib::Common::GlobalConfig::FALSE)) {
         $options =  $options . " -N $filterName ";
      } else {
         $vdLogger->Error("Unable to get filterName " .
                          "for $args{dvfilterctl}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $vdLogger->Error("Unknown/Unsupported branch $self->{branch}");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $vdLogger->Debug("options" .  $options);

   foreach my $opt (keys %args) {
      if (exists $dvfCtl->{$opt}) {
         if (not defined $args{$opt}) {
            $args{$opt} = 0;
         }
         $vdLogger->Debug("opt: $opt, $args{$opt}, $dvfCtl->{$opt}{option}");
         $options = " " . $options . " " . $dvfCtl->{$opt}{option} .
                    " $args{$opt} ";
      }
   }

   $command = "dvfilter_ctl $options";

   $vdLogger->Info("Executing command $command");

   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                  $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command $command failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if (($result->{exitCode} != 0) || ($result eq FAILURE)) {
      VDSetLastError(VDGetLastError());
      $vdLogger->Error("DVFilterCtl failed" . Dumper($result));
      return FAILURE;
   }

   return SUCCESS;
}


#########################################################################
#
#  GetFilterName --
#      Given the dvfilter agent module name, it returns the filterName
#      from the vsish
#      TODO: this kind of method should be launched via remote agent
#      to reduce no. of STAF calls.
#
# Input:
#      DVfilter module name
#
# Results:
#      Returns "SUCCESS" if there was no error executing the command
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub GetFilterName
{
   my $self = shift;
   my %args = @_;
   my $vmObj = $args{vm};
   my $dvfModName = undef;
   my $vmName = undef;
   if (defined $vmObj) {
      $dvfModName = $args{getdvfiltername};
      $vmName = $vmObj->{displayName};
   } else {
      $dvfModName = shift;
      $vmName = shift;
   }
   $vdLogger->Debug("dvfname".Dumper($dvfModName));
   $vdLogger->Debug("vmname".Dumper($vmName));

   my ($command, $result);
   my $filterName;

   if (not defined $dvfModName) {
      $vdLogger->Error("Invalid Parms");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $self->GetBranchInfo() if (not defined $self->{branch});
   # The dvfilter-generic will be named as dvfilter-fw on esx50/esx51/esx60
   $dvfModName =~ s/generic/fw/g if ($self->{branch} =~ /esx[56]/i);

   $command = 'vsish -e ls ' . DVFWORLDIDVSINODE . '| sed -re \'s,/,,g\'';
   $vdLogger->Info("Executing command $command");
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                  $command);
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("STAF command $command failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $vdLogger->Debug("print stdout: $result->{stdout}");
   my @worlds = split(/\n/, $result->{stdout});
   foreach my $world (@worlds) {
      $command ='vsish -e ls ' . DVFWORLDIDVSINODE .
                "$world/portid | sed -re \'s,/,,g\'";
      $vdLogger->Info("Executing command $command");
      $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
      if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
         $vdLogger->Error("STAF command $command failed:" .
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $vdLogger->Debug("print stdout: $result->{stdout}");
      my @ports = split(/\n/, $result->{stdout});
      foreach my $port (@ports) {
         $command = 'vsish -e ls ' . DVFWORLDIDVSINODE .
                    "$world/portid/$port/filterIndex | sed -re \'s,/,,g\'";
         $vdLogger->Info("Executing command $command");
         $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                        $command);
         if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
            $vdLogger->Error("STAF command $command failed:" .
                              Dumper($result));
            VDSetLastError("ESTAF");
            return FAILURE;
         }
         $vdLogger->Debug("print stdout: $result->{stdout}");
         my @slots = split(/\n/, $result->{stdout});
         foreach my $slot (@slots) {
            $command = 'vsish -e get ' . DVFWORLDIDVSINODE .
                       "$world/portid/$port/filterIndex/$slot/properties ";
                       #"| grep \'name:\' \| cut \-f 2 \-d \:";
            $vdLogger->Info("Executing command $command");
            $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                           $command);
            if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
               $vdLogger->Error("STAF command $command failed:" .
                                Dumper($result));
               VDSetLastError("ESTAF");
               return FAILURE;
            }
            # result->stdout should have something like
            # nic-2666945-eth0-dvfilter-fw-1.1
            $vdLogger->Debug("print stdout: $result->{stdout}");
            $vmName =~ s/\n//g;
            if ($result->{stdout} =~
                  m/.*worldName.*\:\Q$vmName\E\n\s+agentName\:(.*)\n\s+name\:(.*)\n/) {
               $filterName = $2;
            $vdLogger->Info("print filtername: $filterName");
               # remove trailing new line
               #$filterName =~ s/\n$//;
               if ($filterName =~ /nic\-\d+\-eth\d+\-(.*)\.\d+.*/) {
                  return $filterName if ($1 eq "$dvfModName");
               }
            }
         }
      }
   }
   $vdLogger->Error("Unable to find the filterName for $dvfModName");
   VDSetLastError("EFAIL");
   return FAILURE;
}


#######################################################################
#
#  SendLroCommand
#      Send LRO  command to host (SUT)
#
# Input:
#      Lro:enable, disable
#      LroType: Hw, Sw
#      VnicType: vmxnet2, vmxnet3
#      TcpipLro:enable,disable
#      hostname
#
# Results:
#      Returns "SUCCESS", if TestEsx command finished successful
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub SendLroCommand
{
   my $self = shift;
   my $lro  = shift;
   my $lrotype = shift;
   my $vnictype = shift;
   my $tcpiplro = shift;
   my $host = $self->{hostIP};
   my $command;

   if (not defined $lrotype){
      $vdLogger->Error("Invalid Parms");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $vnictype){
      $vdLogger->Error("Invalid Parms");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $lro) {
      $vdLogger->Error("Invalid Parms");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (not defined $tcpiplro ){
      $tcpiplro = "enable";
   }
   if ($tcpiplro =~ m/enable/i) {
      $command = "vsish -e set /config/Net/intOpts/TcpipDefLROEnabled 1";
   } elsif ($tcpiplro =~ m/disable/i){
      $command = "vsish -e set /config/Net/intOpts/TcpipDefLROEnabled 0";
   }
   $vdLogger->Info("Executing $command");
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to execute $command");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }

   if ($lrotype =~ m/hw/i) {
      $lrotype = "Hw";
   } elsif ($lrotype =~ m/sw/i) {
      $lrotype = "Sw";
   } else {
      $vdLogger->Error("Invalid lrotype $lrotype");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ($vnictype =~ m/vmxnet3/i) {
      $vnictype = "Vmxnet3";
   } elsif ($vnictype =~ m/vmxnet2/i) {
      $vnictype = "Vmxnet2";
   } else {
      $vdLogger->Error("Invalid vnictype $vnictype");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ($lro =~ m/enable/i) {
      $command = "vsish -e set /config/Net/intOpts/$vnictype$lrotype"."LRO 1";
   } elsif ($lro =~ m/disable/i) {
      $command = "vsish -e set /config/Net/intOpts/$vnictype$lrotype"."LRO 0";
   } else {
      $vdLogger->Error("Invalid lro $lro");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $vdLogger->Debug("Executing $command");
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to execute $command");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# HostNetRefresh --
#      Method to refresh networking configuration in a esx host.
#
# Input:
#      None
#
# Results:
#      "SUCCESS", if the network configuration is refreshed successfully,
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub HostNetRefresh
{
   my $self = shift;

   my $command = "vim-cmd hostsvc/net/refresh";

   $vdLogger->Debug("Refreshing network configuration on $self->{hostIP}");
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                  $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command $command failed:" .
                      Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# AddVmknic --
#      Method to add a vmknic on a given vmkernel portgroup with given
#      network settings.
#
# Input:
#      named hash parameter with following keys:
#      arrayOfSpecs - array of vmknic spec
#      pgName: name of the vmkernel portgroup (Required)
#      ip: a valid ip address or "dhcp" or "autoconf" or "dhcpv6"
#          (Required)
#      netmask: subnet mask, Required if ipv4 setting is required
#      prefixLen: prefix length, required if dhcpv6 setting is required
#      mtu: maximum frame size (Optional)
#      Instance: Name of the tcpip instance.
#
# Results:
#      An instance of VDNetLib::NetAdapter::NetAdapter,
#      if the vmknic has been added properly;
#      "FAILURE", in case of any error.
#
# Side effects:
#  None
#
########################################################################

sub AddVmknic
{
   my $self = shift;
   my $arrayOfSpecs = shift;
   my @arrayOfVMKNicObjects;

   foreach my $element (@$arrayOfSpecs) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("Vmknic spec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my %args = %$element;
      my $ip            = $args{ipv4address};
      my $macAddress    = $args{macaddress};
      my $netmask       = $args{netmask};
      my $prefixLen     = $args{prefixLen};
      my $mtu           = $args{mtu};
      my $portgroupObj  = $args{portgroup};
      my $deviceId      = $args{deviceid} || $args{interface};
      my $netstackObj   = $args{netstack};
      my $vmkservicesref = $args{configureservices};
      my $instance      = (defined $netstackObj) ? $netstackObj->{'netstackName'} :
                          undef;
      my $interface;
      my $result;
      my $command;
      my $pgName;
      my $host = $self->{hostIP};

      if (not defined $portgroupObj) {
         $vdLogger->Error("PortGroup Obj missing for adding Vmknic");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      } else {
         $pgName = $portgroupObj->{'pgName'};
      }

      if (not defined $ip) {
         $ip = "dhcp";
      }

      #
      # If user want to just create vdnet object then we will pass deviceID
      # This is mostly to create vdnet object for vmk0 or interfaces which
      # already exist on the sytem
      #
      if (not defined $deviceId) {
         my $inlineHostObject = $self->GetInlineHostObject();
         my $inlinePortgroupObject = $portgroupObj->GetInlinePortgroupObject();
         $deviceId = $inlineHostObject->AddVMKNIC(portgroup => $inlinePortgroupObject,
                                                ip => $ip,
                                                netmask => $netmask,
                                                prefixLen => $prefixLen,
                                                macaddress => $macAddress,
                                                mtu => $mtu,
                                                netstack => $instance,
                                                vmkservices => $vmkservicesref);
         if (!$deviceId) {
            $vdLogger->Error("Failed to create vmknic");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
         $vdLogger->Debug("Newly Added deviceId is:" . $deviceId);
	 #
	 # In case of virtualwire 'name' attribute is virtualwire-ID
	 # For VC, virtualwire-ID is of no use as its a VSM id
	 # For VC its the dvpgBacking of virtualwire which is of interest
	 #
	 if (defined $inlinePortgroupObject->{dvpgBacking}) {
            $pgName = $inlinePortgroupObject->{dvpgBacking};
	 }
      }

      # initialize the vmknic object.
      my $switchObj = $portgroupObj->{'switchObj'};
      # Create NetAdapter object and store in the testbed hash.
      my $vmknicObj = VDNetLib::NetAdapter::NetAdapter->new(
   		  controlIP  => $host,
   	          pgObj	     => $portgroupObj,
                  pgName     => $pgName,
                  interface  => $pgName,
                  deviceId   => $deviceId,
                  intType    => "vmknic",
                  switchObj  => $switchObj,
                  hostObj    => $self,
                  netstackObj => $netstackObj,
      );
      if ($vmknicObj eq FAILURE) {
         $vdLogger->Error("Failed to create vmknic object for $pgName");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      push @arrayOfVMKNicObjects, $vmknicObj;
   }

   return \@arrayOfVMKNicObjects;
}


#######################################################################
#
# DeleteVmknic -
#      Method to delete a given vmknic.
#
# Input:
#    arrayOfObjects: Array of vmknic objects to be deleted
#
# Results:
#      "SUCCESS", if given vmknic is deleted successfully;
#      "FAILURE", in case of any error while deleting any of the vmknics.
#
# Side effects:
#  None
#
#######################################################################

sub DeleteVmknic
{
   my $self = shift;
   my $arrayOfObjects = shift;
   my $result;
   my $inlineHostObject;
   my $errorCount = 0;

   if (not defined $arrayOfObjects) {
      $vdLogger->Error("No vmknics defined for deletion");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $inlineHostObject = $self->GetInlineHostObject();
   foreach my $vmknicObj (@$arrayOfObjects) {
      my $device = $vmknicObj->{deviceId};
      $result = $inlineHostObject->RemoveVMKNIC(vmknic => $device);
      if (! $result) {
         $vdLogger->Error("Failed to remove vmknic $device");
         VDSetLastError("EOPFAILED");
         $errorCount++
      }
   }
   if ($errorCount > 0) {
      return FAILURE;
   } else {
     $vdLogger->Debug("Removing vmknic is successful");
     return SUCCESS;
   }
}

#######################################################################
#
# ListVmknics -
#      Method to list the available vmknics in a given host.
#
# Input:
#      None
#
# Results:
#      An array of objects of type HostVirtualNic
#
# Side effects:
#  None
#
#######################################################################

sub ListVmknics
{
   my $self = shift;

   my $pyObj = $self->GetInlinePyObject();
   my $result = CallMethodWithKWArgs($pyObj, 'list_vnic', {});
   if ($result eq FAILURE) {
      $vdLogger->Error("Could not list Vmknics on $self->{hostIP}");
      return FAILURE;
   }
   return $result;
}

#########################################################################
#
#  EnableFPT --
#      Given the physical nics intefaces ike vmnic4 or vmnic5,this method
#      puts the device in passthrugh mode
#
# Input:
#      physical Nics Interface array like ['vmnic4','vmnic5'] passed as
#      reference
#
# Results:
#      Returns "SUCCESS" if there was no error executing the command
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub EnableFPT
{
   my $self    = shift;
   my $nics    = shift;
   my @pnics   = @$nics;

   if (!@pnics){
     $vdLogger->Error("Physical Nic to Enable passthru mode is not defined");
     VDSetLastError("EINVALID");
     return FAILURE;
   }

   foreach my $nic (@pnics){
       if ($nic !~ m/vmnic\d+/){
           $vdLogger->Error("The $nic is not a valid interface name");
           VDSetLastError("EINVALID");
           return FAILURE;
       }
       if($self->VerifyPassthruNics($nic) eq "SUCCESS"){
           $vdLogger->Info("$nic is in passthrough mode on host: $self->{hostIP}");
       }
   }
   my $pyObj = $self->GetInlinePyObject();
   my $result = CallMethodWithKWArgs($pyObj, 'update_pci_passthru',
                                     {'vmnic_list'=> $nics, 'enable'=>1});
   if ($result eq FAILURE){
      $vdLogger->Error("Could not enable pci passthru on $self->{hostIP}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #Reboot host
   $vdLogger->Info("Rebooting the host $self->{hostIP}" .
                   ", will take few mins");
   if($self->Reboot() eq FAILURE){
       $vdLogger->Error("Reboot failed on host: $self->{hostIP}");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }

   #verify if the nics are in passthrough mode
   foreach my $nic (@pnics){
       if($self->VerifyPassthruNics($nic) eq "FAILURE"){
           $vdLogger->Error("$nic is NOT in PASSTHRU mode".
                            " on host: $self->{hostIP}");
           VDSetLastError("EFAIL");
           return FAILURE;
       }
   }
   return SUCCESS;
}


#########################################################################
#
#  GetPCIID --
#      Given the physical nic intefaces ike vmnic4 or vmnic5,this method
#      returns the pci ID of the interface
#
# Input:
#      physical Nic interface like 'vmnic4'
#
# Results:
#      Returns the PCI ID of the given interface,
#      if there was no error executing the command
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub  GetPCIID
{
   my $self =shift;
   my $nic  = shift;
   my $pciid = undef;

   if (not defined $nic) {
      $vdLogger->Error("Physical Nic is not provided to obtain PCIID");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $pyObj = $self->GetInlinePyObject();
   my $pnicList = CallMethodWithKWArgs($pyObj, 'get_pnics', {});
   if($pnicList eq FAILURE){
       $vdLogger->Error("Could not get list of pnics on host $self->{hostIP}");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
   for my $pnic (@$pnicList) {
     if ($pnic->{device} eq $nic) {
         $pciid = $pnic->{pci};
         $vdLogger->Info("PCI ID of $nic is $pciid");
         return $pciid;
     }
   }
   $vdLogger->Error("Could not find $nic on host $self->{hostIP}");
   return FAILURE;
}


#########################################################################
#
#  VDNetESXSetup --
#      This method will set up the ESX host to run vdNet
#
# Input:
#      automationServer : name/ip of where vdNet automation (Required)
#      automationShare  : share folder of vdNet src (Required)
#
# Results:
#      Returns "SUCCESS" if there was no error in setting up host
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub VDNetESXSetup
{
   #TODO: deprecate this by 2/28/2014, if no regressions found
   my $self             = shift;
   my $automationServer = shift;
   my $automationShare  = shift;

   if ((not defined $automationServer) || (not defined $automationShare)) {
      $vdLogger->Error("VDNet automation source details not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $self->{vdNetSrc}   = $automationServer;
   $self->{vdNetShare} = $automationShare;

   my $command;
   my $folder="toolchain";
   my $share="/toolchain";
   my $serverIP="build-toolchain.eng.vmware.com";
   my @setupCommands;
   my $result;
   my $data;
   my $toolchain = "toolchain";
   my $automation = "automation";
   my $trees = "trees";
   my $apps  = "apps";
   my ($toolchainServer, $toolchainShare);

   my $toolchainMirror = $ENV{VDNET_TOOLCHAIN_MIRROR};
   if (defined $toolchainMirror) {
      ($toolchainServer, $toolchainShare) = split(":", $toolchainMirror);
   } else {
      ($toolchainServer, $toolchainShare) = ("build-toolchain.eng.vmware.com",
                                             "/toolchain");
   }
   if (FAILURE eq $self->ConfigureHostForVDNet()) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #
   # Collect all different datastore to be mounted in an array and do the mount
   # operation in a loop.
   #
   my @datastoreArray = (
          {
             'server'       => $toolchainServer,
             'share'        => $toolchainShare,
             'mountpoint'   => "build-toolchain.eng.vmware.com_0",
             'variableName' => \$toolchain, # note: reference to $toolchain
         },
         {
            'server'       => "$automationServer",
            'share'        => "$automationShare",
            'mountpoint'   => "automation",
            'variableName' => \$automation,
         },
   );
   foreach my $item (@datastoreArray) {
      $vdLogger->Debug("Mounting $item->{'server'}:$item->{'share'} " .
                       "on $self->{hostIP}");
      #
      # Get the address of each datastore variable and de-reference to store
      # the new value.
      #
      # Sometimes, the given server and share folder might be mounted on the
      # given machine already with a different local datastore name. In that
      # case, the datastore name should be retrieved and any symlinks should be
      # created with respect to that.
      # For example, toolchain can be mounted already as datastore
      # build-toolchain. In that case, the actual path to toolchain is
      # /vmfs/volumes/build-toolchain not /vmfs/volumes/toolchain
      #
      my $datastoreName = $item->{variableName};

      $$datastoreName = $self->{esxutil}->MountDatastore($self->{hostIP},
                                                            $item->{'server'},
                                                            $item->{'share'},
                                                            $item->{mountpoint});

      if ($$datastoreName eq FAILURE) {
         $vdLogger->Error("Failed to mount $item->{'server'}:" .
                          "$item->{'share'} as $item->{mountpoint} " .
                          "on $self->{hostIP}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      $$datastoreName = "/vmfs/volumes/" . "$$datastoreName";
      #
      # Get the datastore path in UUID format which works better than datastore
      # names, especially when the datastore names get modifed when added to a
      # VC. Any reference to datastore name will be broken. Using UUID avoids
      # that issue.
      #

      my $timeout = 20;
      while ($timeout > 0) {
         $$datastoreName = VDNetLib::Common::Utilities::GetActualVMFSPath(
                                                         $self->{hostIP},
                                                         $$datastoreName,
                                                         $self->{stafHelper});
         if ($$datastoreName eq FAILURE) {
            # Sometimes after adding datastore it is taking time to show up
            # in /vmfs/volumes
            $vdLogger->Debug("Failed to get real path of datastore..
                              sleeping for 5s");
            sleep 5;
         } else {
            $vdLogger->Debug("Found datastore vmfs path.. $$datastoreName");
            last;
         }
         $timeout -= 5;
      }
      if ($$datastoreName eq FAILURE) {
         $vdLogger->Error("Failed to get real path of " .
                          "$$datastoreName datastore");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

   }

   #
   # Setup the host to use necessary files to run perl and staf
   #
   my @perlCommands = ("ln -sf /build/toolchain/lin32/perl-5.10.0/bin/perl /bin",
                       "perl -v",
                       );

   #
   # libPLSTAF.so used here is assuming perl5.10.0 would be installed on the
   # host.
   #
   @setupCommands = ("mkdir -p /build",
                     "rm -f /build/toolchain",
                     "ln -sf $toolchain /build/toolchain",
                     "ln -sf /build/toolchain/lin32/perl-5.10.0/lib /lib",
                     "ln -sf " .
                     "/build/toolchain/lin32/perl-5.10.0/lib/5.10.0/" .
                     "i686-linux-thread-multi/CORE/libperl.so /lib",
                     "ln -sf $automation /automation",
                     "cp /automation/certs/vmware.cert /usr/share/certs/vmware.cert",
                     "ln -sf /automation/VDNetLib/CLIB/x86_32/esx/libPLSTAF.so /lib",
                     "esxcli system settings advanced set -o /NFS/MaxVolumes --int-value " .
                     VDNetLib::TestData::TestConstants::DEFAULT_NFS_MAXVOLUMES,
   );
   $result = VDNetLib::Common::Utilities::GetPerlVersion($self->{hostIP},
                                                         $self->{stafHelper});
   if ($result eq FAILURE) {
      $vdLogger->Trace("Unable to find perl version on $self->{hostIP}, " .
                       "may be not installed");
      VDCleanErrorStack();
      @setupCommands = (@setupCommands, @perlCommands);
   } elsif ($result !~ /5.10.0/i) {
      $vdLogger->Warn("Unsupported perl version $result on $self->{hostIP}");
   }

   foreach my $command (@setupCommands) {
      my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                        $command);
      if ($result->{rc} != 0) {
         $vdLogger->Error("STAF command $command failed");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      if ($result->{exitCode} != 0 && $result->{exitCode} != 1){
         $vdLogger->Error("STAF command $command failed:" .
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $vdLogger->Debug("STAF Command -$command");
   }
   $vdLogger->Debug("Update hosts lookup table: " .
      VDNetLib::Common::Utilities::UpdateLauncherHostEntry($self->{hostIP},
                                                           $self->{hostType},
                                                           $self->{stafHelper}));

   # Enable ARP inspection to find ip address of a VM
   my $temp;
   $temp->{'/config/Net/intOpts/GuestIPHack'} = 1;
   #
   # IMPORTTANT:
   # Disable stress option at global level. This was one of the
   # pain points in getting stable runs, a simple disk fault
   # injection could cause a test case to fail. While it is
   # important for dev to enable it default so that SOMEONE would
   # hit a bug, for functional testing we should have better control
   # over the test environment. Tests can always be added to verify
   # the stress options
   #
   $temp->{'/config/Misc/intOpts/VmkStressEnable'} = 0;
   my $operation = "Enable";
   $vdLogger->Debug("$operation arp inspection and disable stress option " .
                    "on $self->{hostIP}");
   $result = $self->VMKConfig($operation, $temp);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to $operation arp inspection");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #PR 1127475
   if (FAILURE eq $self->SetPSODTimeout(1)) {
     $vdLogger->Error("Set PSOD timeout failed on host $self->{hostIP}");
     VDSetLastError("EFAIL");
     return FAILURE;
   }

   $vdLogger->Info("Setup for vdNet environment passed on $self->{hostIP}");

   return SUCCESS;

}


#########################################################################
#
#  GetPassthruNics --
#      This method returns the passthru Nics available in the host
#
# Input:
#      None
#
# Results:
#      Returns physical nic array like ['vmnic4','vmnic5'] which is in the
#      passthrough mode in the host.if there was no error executing the
#      command.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub GetPassthruNics
{
   my $self   = shift;
   my @pcinic = ();
   my $data   = undef;
   my $result = undef;
   my $index  = 0;
   my $command;

   $command = "vmkchdev -l|grep passthru";
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                       "$command");
   #check for failure of the command
   if ($result->{exitCode} != 0) {
       $vdLogger->Error("Failed to obtain passthru NIC details Error:");
       VDSetLastError("EFAIL");
       return FAILURE;
    }
    $data=$result->{stdout};
    my @vmnics=split("\n",$data);

    foreach my $nic(@vmnics){
      my @values=split(' ',$vmnics[$index]);
      $pcinic[$index]=$values[4];
      $index++;
    }

   return @pcinic;
}

#########################################################################
#
#  VerifyPassthruNics--
#      Verify's if a particular physical Nic Interface is in passthrough
#      mode or not
#
# Input:
#      physical Nic interface like 'vmnic4'
#
# Results:
#      Returns "SUCCESS" if the PNIC is in passthrough mode and
#      if there was no error executing the command.
#      Returns "FAILURE", in case of any error or if the PNIC is not
#      in passthrough mode.
#
# Side effects:
#      None.
#
#########################################################################

sub VerifyPassthruNics
{
   my $self   = shift;
   my $nic    = shift;
   my $command;
   $command = "vmkchdev -l|grep passthru.$nic";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                       $command);
   #check for failure of the command
   if ($result->{exitCode} != 0) {
       $vdLogger->INFO("$nic is not in passthrough mode");
       return FAILURE;
    }
   return SUCCESS;

}


#########################################################################
#
#  GetPassthruNICPCIID --
#      Given the physical Nic intefaces ike vmnic4 or vmnic5 in passthrough
#      mode,this method returns the pci ID of the interface.
#
# Input:
#      physical Nic interface like 'vmnic4'
#
# Results:
#      Returns PCI ID of the interface given,
#      if there was no error executing the command.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub GetPassthruNICPCIID
{

   my $self   = shift;
   my $host   = shift;
   my $nic    = shift;

   my $command;
   my $pciid;

   if (not defined $nic) {
      $vdLogger->Error("Physical Nic is not provided to obtain PCIID");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $command = "vmkchdev -l|grep passthru\.$nic";
   my $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                       $command);
   # check for failure of the command

   if ($result->{rc} != 0) {
       $vdLogger->Error("$nic is not in passthrough mode");
       return FAILURE;
     }

   if ($result->{stdout} eq ""){
      $vdLogger->Error("No STAF result is returned for :$nic");
      VDSetLastError("EINVALID");
      return FAILURE;
    }

   my @pcivalue=split(' ',$result->{stdout});
    #The PCI ID should be like this 00:06:00.0
   if ($pcivalue[0]=~m/\d\d:([0-9][a-z0-9]:\d\d.\d)/) {
          $pciid=$1;
     } else {
       $vdLogger->Error("Not a valid PCI value :$pcivalue[0]");
       VDSetLastError("EINVALID");
       return FAILURE;
     }

   return $pciid;
}

#########################################################################
#
#  DisableFPT --
#      Given the physical nics intefaces ike vmnic4 or vmnic5,this method
#      dsable the passthrugh mode of the interface
#
# Input:
#     None
#
# Results:
#      Returns "SUCCESS" if there was no error executing the command
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub DisableFPT
{
   my $self    =   shift;

   my @pcinic  =   $self->GetPassthruNics();

   #Checking if there is no nic in passthrough mode
   if(scalar(@pcinic) == 0){
      $vdLogger->Error("No nics vailable in passthru mode on host: ".
                                                   "$self->{hostIP}");
      VDSetLastError("EFAIL");
      return FAILURE;
    }

   my $pyObj = $self->GetInlinePyObject();
   my $result = CallMethodWithKWArgs($pyObj, 'update_pci_passthru',
                                     {'vmnic_list'=> \@pcinic, 'enable'=>0});
   if ($result eq FAILURE){
      $vdLogger->Error("Could not disable pci passthru on $self->{hostIP}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #Reboot host
   $vdLogger->Info("Rebooting the host : $self->{hostIP}");
   if ($self->Reboot() eq "FAILURE" ) {
         $vdLogger->Error("Reboot failed on host:$self->{hostIP}");
         VDSetLastError("EFAIL");
         return FAILURE;
   }

   foreach my $nic (@pcinic) {
         if($self->VerifyPassthruNics($nic) eq "SUCCESS"){
            $vdLogger->Error("$nic is in PASSTHRU mode".
                                               " on host:$self->{hostIP}");
            VDSetLastError("EFAIL");
            return FAILURE;
           }
   }
  return SUCCESS;
}


########################################################################
#
# IsMounted --
#	Checks if a given share on given server is mounted on the
#	remote machine
#
# Input:
#       Server IP address
#       Mount/Share name on server
#       folder name on remote machine where it has to be mounted
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
   my $self = shift;
   my $serverIP = shift; # mount server IP address
   # folder name on remote machine where it has to be mounted
   my $share = shift;
   my $folder = shift;

   my ($command, $result, $data);

   $folder =~ s/^\///;
   $command = "esxcfg-nas -l | grep \"$folder is $share from\"";

   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("$command failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $data = $result->{stdout};
   $vdLogger->Debug("data: $data");
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
# CheckNetFence --
#      This method execute net-fence command and check result on VM.
#
# Input:
#      vdsName: name of the vds (required)
#      fenceid: fence id number (required)
#
# Results:
#      Returns "SUCCESS", if setting successfully.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub CheckNetFence {
   my $self          = shift;
   my $vdsName       = shift;
   my $fenceId       = shift;
   my $command;
   my $result;
   my $resultOut;

   $command = "net-fence -l -s $vdsName -f $fenceId ";

   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},$command);
   $resultOut = $result->{stdout};

   if ($result->{rc} != 0){
      $vdLogger->Error("STAF command failed: \$command=$command " .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($resultOut =~ m/fence network:*\s$fenceId/) {
      # Successful
   }else{
      $vdLogger->Error(" Checking net-fence function failed! ");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

########################################################################
#
# CheckCHFEsxcli --
#      This method execute net-fence command and check result on VM.
#
# Input:
#      vdsName: name of the vds (required)
#      fenceid: fence id number (required)
#
# Results:
#      Returns "SUCCESS", if setting successfully.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################
sub CheckCHFEsxcli {
   my $self          = shift;
   my $vdsName       = shift;
   my $fenceId       = shift;
   my $command;
   my $result;
   my $resultOut;

   $command = "esxcli network fence network list -s $vdsName -f $fenceId ";
   $vdLogger->Debug(" HostOperations.pm CheckCHFEsxcli : \$command = ".$command);
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},$command);
   $resultOut = $result->{stdout};

   if ($result->{rc} != 0){
      $vdLogger->Error("STAF command failed: \$command=$command " .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($resultOut =~ m/Fence Id:*\s$fenceId/) {
      # Successful
   }else{
      $vdLogger->Error(" Command esxcli network fence network list failed! ");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   return SUCCESS;
}


################################################################################
#
# AbleIPv6 --
#      Method to enable / disable IPv6 on ESX TCPIP stack
#
# Input:
#      "Enable / Disable" - enable or disable IPv6 [Mandatory]
#
# Results:
#      "SUCCESS", if ipv6 is enabled / disabled
#      "FAILURE", in case of any error
#
#
# Side effects:
#      None
#
################################################################################

sub AbleIPv6
{
   my $self = shift;
   my $action = shift;

   if (not defined $action) {
      $vdLogger->Error("Action not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Creating command
   my $command = "$vmknicEsxcli set -e";

   if ($action =~ m/enable/i) {
      $command .= " true";
   } elsif ($action =~ m/disable/i) {
      $command .= " false";
   } else {
      $vdLogger->Error("IPv6 action not specified as either \"enable\" or ".
                       "\"disable\"");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   if ($result->{rc} != 0) {
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $vdLogger->Info("For the change to take effect, system has to be rebooted");
   return SUCCESS;
}


########################################################################
#
# GetActiveVMNicOfvNic --
#     Method to get active pnic/vmnic of the given vNic.
#
# Input:
#      vNic - mac or ip address or portid of the vNic (Required)
#             (Giving portid will return the active vmnic quickly)
#
# Results:
#      Active vmnic (scalar string) for the given vNic, if successful;
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub GetActiveVMNicOfvNic
{
   my $self = shift;
   my $vNic = shift;

   if (not defined $vNic) {
      $vdLogger->Info("Either port id or mac or ip address of vnic " .
                      "should be provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my ($portid, $mac, $ip);

   #
   # If the given vNic format is not mac or ip address then assume
   # port id is given.
   #
   if (($vNic !~ /(([0-9a-fA-F]{2}[:-]){5}[0-9a-fA-F]{2})/i) &&
      ($vNic !~ /([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/i)) {
      $portid = $vNic;
   }

   if (not defined $portid) {
      # Find the port id of the given vnic
      $portid = $self->GetvNicVSIPort($vNic);
      if ($portid eq FAILURE) {
         $vdLogger->Error("Failed to get VSI port id of $mac");
         return FAILURE;
      }
   }

   $portid =~ s/\/$//; #remove any trailing /

   #
   # Execute the command
   # "vsish -e get /net/portsets/<switch>/ports/<portid>/teamUplink"
   #  to find the active vmnic of the given vnic
   #
   my $command = "vsish -e get " . $portid . "/" . "teamUplink";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to obtain the vnic pts ports Error" .
                       Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   if ((not defined $result->{stdout}) || ($result->{stdout} eq "")) {
      $vdLogger->Error("Failed to find the active vmnic of given vnic $vNic");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $result->{stdout} =~ s/\n//g;
   return $result->{stdout}; #TODO check for "void"
}


########################################################################
#
# GetActiveVMNicUsingIP --
#      Method to find active VMNic of a vnic using its ip address.
#      This method is better than GetvNicVSIPort() because to find ip
#      port using that method, arp inspection have to be enabled.
#      This method does not require any such condition except staf.
#
# Input:
#      ipAddress: ip address of the vnic (Required)
#      controlIP: if the ip address given above cannot be reached
#                 directly (Optional)
#
# Results:
#      Active vmnic (scalar string) of the given vnic, if successful;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetActiveVMNicUsingIP
{
   my $self      = shift;
   my $ipAddress = shift;
   my $controlIP = shift || $ipAddress;

   if (not defined $ipAddress) {
      $vdLogger->Error("Ip address not given provided at input");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # First, get the mac address of the given ip address.
   my $mac =
      VDNetLib::Common::Utilities::GetMACFromIP($ipAddress, $self->{stafHelper},
                                                $controlIP);
   if ($mac eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return $self->GetActiveVMNicOfvNic($mac);
}


################################################################################
#
# GetAllVMNames --
#      Method to get all VM names in a host
#
# Input:
#      "Y" - If "Y" is mentioned, all the VM names will be returned. Else, only
#            first Name is returned
#
# Results:
#      Array reference to list of VM names is returned if "Y" is mentioned.
#      First VM name is returned in case "Y" is not mentioned.
#      "FAILURE", in case of any error
#
#
# Side effects:
#      None
#
################################################################################

sub GetAllVMNames
{
   my $self = shift;
   my $param = shift || "N";
   my (@vmNames) = ();

   if($param !~ m/^[YN]$/i){
      $vdLogger->Error("Parameter not mentioned as Y or N");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Creating command
   my $command = "vim-cmd /vmsvc/getallvms";

   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   if ($result->{rc} != 0) {
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   if (defined $result->{stdout}) {
      my $k = 0;
      my @tmp1 = split(/\n/, $result->{stdout});
      foreach my $name (@tmp1) {
         my @tmp2 = split(/\s+/, $name);
         if ($tmp2[1] ne "Name") {
            $vmNames[$k] = $tmp2[1];
            if ($param =~ m/^N$/i) {
               return $vmNames[$k];
            }
            $k++;
         }
      }
      return \@vmNames;
   }
   $vdLogger->Error("Unable to retrieve all VM names");
   VDSetLastError("EFAIL");
   return FAILURE;
}


################################################################################
#
# GetAllvSwitchNames --
#      Method to get all vSwitch names in a host
#
# Input:
#      None.
#
# Results:
#      Array reference to list of vSwitch names is returned
#      "FAILURE", in case of any error
#
#
# Side effects:
#      None
#
################################################################################

sub GetAllvSwitchNames
{
   my $self = shift;
   my (@vSwNames) = ();

   # Creating command
   my $command = "esxcli network vswitch standard list";

   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   if ($result->{rc} != 0) {
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   if (defined $result->{stdout}) {
      my $k = 0;
      my @tmp1 = split(/\n/, $result->{stdout});
      foreach my $name (@tmp1) {
         if ($name =~ m/Name:/) {
            my @tmp2 = split(/\s+/, $name);
            $vSwNames[$k] = $tmp2[2];
            chomp($vSwNames[$k]);
            $k++;
         }
      }
      return \@vSwNames;
   }
   $vdLogger->Error("Unable to retrieve all vSwitch names");
   VDSetLastError("EFAIL");
   return FAILURE;
}


################################################################################
#
# AnalyzeTxRxQ --
#      Method to analyze TxRx queues for Networking Datapath. The method has
#      been included in the Vmnic.pm module because most of the methods are
#      functionally congruent to the physical NIC since that's where NetQueue
#      actually works. This method can be used in any host that's running 3 VMs
#      with netperf / netserver running between them through NetQueue supported
#      pNICs.
#
# Input:
#      TeamPolicy - Parameter for taking in NIC teaming policy for test case.
#                   Accepts the values "LB_IP", "SRC_MAC", "SRC_ID",
#                   "FO_EXPLICIT", "FO_ROLLING". In case test is to be run with
#                   a single NIC, parameter should have value "NULL".
#                   [Mandatory]
#      HostType   - Type of host on which the analysis is to be done i.e. "SUT"
#                   or "Helper#" [Mandatory]
#      TestBed    - TestBed hash on which the test is running [Mandatory]
#      SleepBetweenCombos - Parameter for taking in the sleep period, afer
#                           which the NetQueue analysis wil start. This period
#                           should be set by the user and will be a number to
#                           indicate start of NetQueue analysis AFTER all the
#                           queues have been populated. [Optional]
#
# Results:
#      SUCCESS if NetQueue is working fine on host
#      FAILURE if NetQueue is not working find on host
#
# Side effects:
#      None.
#
# Notes:
#      The following assumptions have been made for this module to be run on any
#      setup that has NetQueue supported NICs-
#      1. 2 ESX hosts in the setup
#      2. Each ESX host will have at least ONE NetQueue supported NIC and both
#         NICs should be of the same type i.e. only ixgbe or only bnx2x on each
#         side
#      3. The NetQueue supported NICs should be connected to each other via a
#         10G setup
#      4. Each ESX host will host 1 VM, each of which will have 9 vNICs - eth0
#         connected to vSwitch0 (by default) and eth1 - eth9 connected to the
#         new vSwitch that contains the NetQueue supported pNICs
#      5. Each of the 9 vNICs on each of the VMs will send / receive traffic
#         such that each host has 9 (1VM x 9vNICs) unique ports transmitting /
#         receiving traffic
#      6. Setup should be as shown below:
#
#   ESX 1                                                               ESX 2
# --------- eth1 <----------netperf/netserver traffic-----------> eth1 --------
# |TestVM1| eth2 <----------netperf/netserver traffic-----------> eth2 |AuxVM1|
# |       | eth3 <----------netperf/netserver traffic-----------> eth3 |      |
# --------- eth4 <----------netperf/netserver traffic-----------> eth4 --------
#           eth5 <----------netperf/netserver traffic-----------> eth5
#           eth6 <----------netperf/netserver traffic-----------> eth6
#           eth7 <----------netperf/netserver traffic-----------> eth7
#           eth8 <----------netperf/netserver traffic-----------> eth8
#           eth9 <----------netperf/netserver traffic-----------> eth9
#
################################################################################

sub AnalyzeTxRxQ
{
   my $self = shift;
   my $args = shift;
   my $nicId1 = $args->{nic1};
   my $nicId2 = $args->{nic2} || undef;
   my $sleepBetweenCombos = $args->{sleepbetweencombos} || undef;
   my $teamPolicy = $args->{teampolicy};
   my $vSwNames = $args->{vswname};
   my $nic1 = $args->{vmnic}{$nicId1}{name};
   my $nic2 = undef;
   if (defined $nicId2) {
      $nic2 = $args->{vmnic}{$nicId2}{name};
   }

   if ($teamPolicy ne "LB_IP" &&
       $teamPolicy ne "SRC_MAC" &&
       $teamPolicy ne "SRC_ID" &&
       $teamPolicy ne "FO_EXPLICIT" &&
       $teamPolicy ne "FO_ROLLING" &&
       $teamPolicy ne "FO_EXPLICIT_BEACON" &&
       $teamPolicy ne "FO_ROLLING_BEACON" &&
       $teamPolicy ne "NULL") {
      $vdLogger->Error("AnalyzeTxRxQ: Incorrect value for \"TeamPolicy\" ".
                       "param");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (defined $sleepBetweenCombos) {
      $vdLogger->Info("Sleeping for $sleepBetweenCombos seconds before starting".
                      " NetQueue analysis on host $self->{hostIP}");
      sleep($sleepBetweenCombos);
   }

   # Variables required for functioning of this API
   my @portIdNic2 = undef; # All port IDs connected to NIC2
   my @portIdNic1 = undef; # All port IDs connected to NIC1
   my $portArray = undef; # All the ports connected to vSwitch
   my $numOfPorts = undef; # All number of ports connected to vSwitch
   my $totalNumOfPorts = 0; # Total number of ports connected to vSwitch
   my $portCountNic2 = 0; # Number of ports connected to NIC2
   my $portCountNic1 = 0; # Number of ports connected to NIC1
   my $actTxQNic2 = undef; # Number of active Tx queues for NIC2
   my $actTxQNic1 = undef; # Number of active Tx queues for NIC1
   my $defQIdNic2 = undef; # Default Queue ID for NIC2
   my $defQIdNic1 = undef; # Default Queue ID for NIC1
   my $actualTxQNic2 = undef; # Actual number of Tx queues for NIC2
   my $actualTxQNic1 = undef; # Actual number of Tx queues for NIC1
   my $pktSchedAlgoNic2 = undef; # Pkt Sched Algorithm for NIC2
   my $pktSchedAlgoNic1 = undef; # Pkt Sched Algorithm for NIC1
   my $totalFilterCntNic2 = undef; # Total filter count for NIC2
   my $totalFilterCntNic1 = undef; # Total filter count for NIC1
   my $rxParamsHashNic2 = undef; # Hash to store Rx param info for NIC2
   my $rxParamsHashNic1 = undef; # Hash to store Rx param info for NIC1

   # Retrieving the object of the vmnics to which the vSwitch is
   # connected
   $self->{vmnicObj}->{$nicId1} =
      VDNetLib::NetAdapter::Vmnic::Vmnic->new(interface => "$nic1",
                                              hostObj => $self,
                                              controlIP => $self->{hostIP});
   if ($self->{vmnicObj}->{$nicId1} eq FAILURE) {
      $vdLogger->Error("Unable to create $nicId1 vmnic object");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   if (defined $nic2) {
      $self->{vmnicObj}->{$nicId2} =
      VDNetLib::NetAdapter::Vmnic::Vmnic->new(interface => "$nic2",
                                              hostObj => $self,
                                              controlIP => $self->{hostIP});
      if ($self->{vmnicObj}->{$nicId2} eq FAILURE) {
         $vdLogger->Error("Unable to create $nicId2 vmnic object");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }

   # Retrieving the object of the vSwitch under test
   $self->{vSwitchObj} = VDNetLib::Switch::Switch->new(switch => $vSwNames,
                                                       switchType => "vswitch",
                                                       host => $self->{hostIP});
   if ($self->{vSwitchObj} eq FAILURE) {
      $vdLogger->Error("Unable to retrieve vSwitch object");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Checking the portIDs connected to the vSwitch
   $vdLogger->Debug("Checking the portIDs connected to the vSwitch $vSwNames");
   $portArray = $self->GetVnicPortIds($vSwNames);
   if ($portArray eq FAILURE) {
      $vdLogger->Error("Unable to retrieve Port IDs for switch".
                       " $vSwNames");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Getting total number of ports connected
   $vdLogger->Debug("Getting total number of ports");
   $numOfPorts = @{$portArray};
   $vdLogger->Debug("Number of ports in switch $vSwNames = $numOfPorts");

   # Getting total number of ports of all VMs connected
   $vdLogger->Debug("Getting total number of ports of all VMs connected");
   $totalNumOfPorts+=$numOfPorts;

   $vdLogger->Debug("Total number of ports of all VMs connected = ".
                   "$totalNumOfPorts");

   # Get port uplinks for each port that is connected to the vSwitch
   # and count the number of ports connected to each uplink
   my $ai = 0;
   if (($teamPolicy ne "LB_IP") && ($teamPolicy ne "SRC_MAC")) {
      $vdLogger->Debug("Getting port uplinks for each port connected to the".
                      " vSwitch and count the number of ports connected to".
                      " each uplink");
      for (my $lc = 0; $lc < $numOfPorts; $lc++) {
         my $portUplink = $self->{'vSwitchObj'}->GetTeamUplink(
                                 $portArray->[$lc],
                                 $vSwNames);
         if ($portUplink eq FAILURE) {
           $vdLogger->Error("Unable to retrieve uplink for port ".
                             "$portArray->[$lc] vSwitch ".
                             "$vSwNames");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
         $vdLogger->Debug("Uplink for port $portArray->[$lc] = $portUplink");
         if (defined $nic2) {
            if ($portUplink eq $nic2) {
              $portIdNic2[$portCountNic2] = $portArray->[$lc];
               $portCountNic2++;
            } elsif ($portUplink eq $nic1) {
               $portIdNic1[$portCountNic1] = $portArray->[$lc];
               $portCountNic1++;
            } else {
               $vdLogger->Error("Retrieved uplink $portUplink doesn't match".
                                " with any of the uplinks connected to ".
                                " $vSwNames");
               VDSetLastError("EFAIL");
               return FAILURE;
            }
         } elsif ($portUplink eq $nic1) {
            $portCountNic1++;
         } else {
            $vdLogger->Error("Retrieved uplink $portUplink doesn't match".
                             " with any of the uplinks connected to ".
                             " $vSwNames");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }
      $vdLogger->Debug("Number of ports connected to Uplink $nic1 = ".
                      "$portCountNic1");
      if (defined $nic2) {
         $vdLogger->Debug("Number of ports connected to Uplink $nic2 = ".
                         "$portCountNic2");
      }
   }

   ################################
   # Analyzing Tx params for host #
   ################################

   # Get number of active Tx queues for pNICs and the default Queue IDs
   $vdLogger->Info("Get number of active Tx queues for pNICs and the default".
                   " queue IDs");
   if (defined $nic2) {
      $actTxQNic2 = $self->{vmnicObj}->{$nicId2}->TxQueueInfo("numQueues",$nic2);
      $defQIdNic2 = $self->{vmnicObj}->{$nicId2}->TxQueueInfo("defaultQid",$nic2);
      if ($actTxQNic2 eq FAILURE) {
         $vdLogger->Error("Unable to retrieve number of active Tx queues for".
                          " NIC $nic2");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      if ($defQIdNic2 eq FAILURE) {
         $vdLogger->Error("Unable to retrieve default queue ID for".
                          " NIC $nic2");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      $vdLogger->Debug("Number of active Tx queues for NIC $nic2 = ".
                      "$actTxQNic2");
      $vdLogger->Debug("Default Queue ID for NIC $nic2 = ".
                      "$defQIdNic2");
   }
   $actTxQNic1 = $self->{vmnicObj}->{$nicId1}->TxQueueInfo("numQueues",$nic1);
   $defQIdNic1 = $self->{vmnicObj}->{$nicId1}->TxQueueInfo("defaultQid",$nic1);
   if ($actTxQNic1 eq FAILURE) {
      $vdLogger->Error("Unable to retrieve number of active Tx queues for".
                       " NIC $nic1");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   if ($defQIdNic1 eq FAILURE) {
      $vdLogger->Error("Unable to retrieve default queues ID for".
                       " NIC $nic1");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $vdLogger->Debug("Number of active Tx queues for NIC $nic1 = ".
                   "$actTxQNic1");
   $vdLogger->Debug("Default Queue ID for NIC $nic1 = ".
                   "$defQIdNic1");

   # Getting number of Tx queues actually present
   $vdLogger->Debug("Getting number of Tx queues actually present for each".
                   "NIC");
   if (defined $nic2) {
      $actualTxQNic2 = $self->{vmnicObj}->{$nicId2}->GetTxNumOfQueues($nic2);
      if ($actualTxQNic2 eq FAILURE) {
         $vdLogger->Error("Unable to retrieve actual number of Tx queues for".
                          " NIC $nic2");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      if ($actualTxQNic2 != $actTxQNic2) {
         $vdLogger->Error("Actual number of Tx queues does not match with ".
                          " active number of Txqueues for $nic2");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }
   $actualTxQNic1 = $self->{vmnicObj}->{$nicId1}->GetTxNumOfQueues($nic1);
   if ($actualTxQNic1 eq FAILURE) {
      $vdLogger->Error("Unable to retrieve actual number of Tx queues for".
                       " NIC $nic1");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   if ($actualTxQNic1 != $actTxQNic1) {
      $vdLogger->Error("Actual number of Tx queues does not match with ".
                       " active number of Txqueues for $nic1");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Getting packet scheduled algo defined on each NIC
   $vdLogger->Debug("Getting packet scheduled algo defined on each NIC");
   if (defined $nic2) {
      $pktSchedAlgoNic2 = $self->{vmnicObj}->{$nicId2}->GetPktSchedAlgo($nic2);
      if ($pktSchedAlgoNic2 eq FAILURE) {
         $vdLogger->Error("Unable to retrieve pkt sched algorithm for ".
                          " NIC $nic2");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }
   $pktSchedAlgoNic1 = $self->{vmnicObj}->{$nicId1}->GetPktSchedAlgo($nic1);
   if ($pktSchedAlgoNic1 eq FAILURE) {
      $vdLogger->Error("Unable to retrieve pkt sched algorithm for ".
                       " NIC $nic1");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Getting Tx Queue ID for each port connected to the vSwitch and checking
   # whether ports are transmitting / receiving traffic.
   if (($teamPolicy ne "LB_IP") && ($teamPolicy ne "SRC_MAC")) {
      $vdLogger->Debug("Getting  Tx Queue ID for each port connected to the vSwitch".
                      " and checking whether ports are transmitting / receiving ".
                      "traffic.");
      if (defined $nic2) {
         if (!$pktSchedAlgoNic2) {
            if ($self->ValidTxQueue({
                       'PORTCOUNT' => $portCountNic2,
                       'PORTID' => \@portIdNic2,
                       'NUMACTQ' => $actTxQNic2,
                       'NIC' => $nicId2,}) eq FAILURE) {
               $vdLogger->Error("Tx queue values not valid for $nic2");
               VDSetLastError("EFAIL");
               return FAILURE;
            }
         }
         if (!$pktSchedAlgoNic1) {
            if ($self->ValidTxQueue({
                       'PORTCOUNT' => $portCountNic1,
                       'PORTID' => \@portIdNic1,
                       'NUMACTQ' => $actTxQNic1,
                       'NIC' => $nicId1,}) eq FAILURE) {
               $vdLogger->Error("Tx queue values not valid for $nic1");
               VDSetLastError("EFAIL");
               return FAILURE;
            }
         }
      } else {
         # This part of the code is run in case the second NIC isn't present
         if (!$pktSchedAlgoNic1) {
            if ($self->ValidTxQueue({
                       'PORTCOUNT' => $numOfPorts,
                       'PORTID' => $portArray,
                       'NUMACTQ' => $actTxQNic1,
                       'NIC' => $nicId1,}) eq FAILURE) {
               $vdLogger->Error("Tx queue values not valid for $nic2");
               VDSetLastError("EFAIL");
               return FAILURE;
            }
         }
      }
   }

   ################################
   # Analyzing Rx params for host #
   ################################

   # Retrieving number of Rx supported queues, filters and active filters
   $vdLogger->Info("Retrieving number of Rx supported queues, filters and active filters".
                   " per NIC");
   if (defined $nic2) {
      $rxParamsHashNic2 = $self->CollectRxParams({'NIC' => $nic2,
                                                  'NICID' => $nicId2,});
      if ($rxParamsHashNic2 eq FAILURE) {
         $vdLogger->Error("Unabled to retrieve Rx parameters for NIC".
                          " $nic2");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }
   $rxParamsHashNic1 = $self->CollectRxParams({'NIC' => $nic1,
                                               'NICID' => $nicId1,});
   if ($rxParamsHashNic1 eq FAILURE) {
      $vdLogger->Error("Unabled to retrieve Rx parameters for NIC".
                       " $nic1");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Checking the validity of the values retrieved
   if (($teamPolicy ne "LB_IP") && ($teamPolicy ne "SRC_MAC")) {
      # Number of ports retrieved from Rx queues for both NICs should be equal to
      # the number of ports connected to vSwitch
      $vdLogger->Debug("Number of ports retrieved from Rx queuesfor both NICs ".
                       "should be equal to the number of ports connected to ".
                       "vSwitch");
      if (defined $nic2) {
         if (($rxParamsHashNic1->{validRxFilterHash}->{rxPortCnt} !=
              $rxParamsHashNic2->{validRxFilterHash}->{rxPortCnt}) ||
             ($rxParamsHashNic1->{validRxFilterHash}->{rxPortCnt} !=
              $totalNumOfPorts)) {
            $vdLogger->Error("Number of ports retrieved from Rx queues doesn't ".
                             "equal the number of ports retrieved from Tx ".
                             "queues");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      } else {
         if ($rxParamsHashNic1->{validRxFilterHash}->{rxPortCnt} != $totalNumOfPorts) {
            $vdLogger->Error("Number of ports retrieved from Rx queues doesn't ".
                             "equal the number of ports retrieved from Tx ".
                             "queues for $nic1");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }
      # Number of active and default loads retrieved from Rx queues of both NICs
      # should be equal to number of ports connected to vSwitch
      $vdLogger->Debug("Number of active and default loads retrieved from Rx".
                       " queues of both NICs should be equal to number of ".
                       "ports connected to vSwitch");
      $totalFilterCntNic1 = $rxParamsHashNic1->{validRxFilterHash}->{defFilterCnt} +
                            $rxParamsHashNic1->{validRxFilterHash}->{actFilterCnt};
      if (defined $nic2) {
         $totalFilterCntNic2 = $rxParamsHashNic2->{validRxFilterHash}->{defFilterCnt} +
                               $rxParamsHashNic2->{validRxFilterHash}->{actFilterCnt};
         if (($totalFilterCntNic2 != $totalNumOfPorts) ||
             ($totalFilterCntNic1 != $totalNumOfPorts)) {
            $vdLogger->Error("Total filter count for both NICs does not equal ".
                             "number of ports connected to the vSwitch");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      } else {
         if ($totalFilterCntNic1 != $totalNumOfPorts) {
            $vdLogger->Error("Total filter count for $nic1 does not equal ".
                             "number of ports connected to the vSwitch");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }

      # Checking validity of the Rx queue numbers retrieved
      $vdLogger->Debug("Checking validity of the Rx queue numbers retrieved");
      if ($self->{vmnicObj}->{$nicId1}->{driver} =~ /ixgbe/i) {
         if (defined $nic2) {
            if ($self->ValidRxQueue({
               'numofq' => $rxParamsHashNic2->{rxNumOfQ},
               'rxqid' => $rxParamsHashNic2->{validRxFilterHash}->{rxQId},
               'nic' => $nicId2,
               'rxqcnt' => $rxParamsHashNic2->{validRxFilterHash}->{rxQCnt},}) eq FAILURE) {
               $vdLogger->Error("Rx queue IDs that have been retrieved are ".
                                "not valid for NIC $nic2");
               VDSetLastError("EFAIL");
               return FAILURE;
            }
         }
         if ($self->ValidRxQueue({
            'numofq' => $rxParamsHashNic1->{rxNumOfQ},
            'rxqid' => $rxParamsHashNic1->{validRxFilterHash}->{rxQId},
            'nic' => $nicId1,
            'rxqcnt' => $rxParamsHashNic1->{validRxFilterHash}->{rxQCnt},}) eq FAILURE) {
            $vdLogger->Error("Rx queue IDs that have been retrieved are ".
                             "not valid for NIC $nic1");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }
   }
   return SUCCESS;
}


################################################################################
#
# ValidRxQueue --
#      Method to check if valid Rx queues have been retrieved for each NIC in
#      Network Datapath functionality.
#
# Input:
#      numofq - number of queues in NIC [Mandatory]
#      rxqid  - Rx queue ID for which validity has to be checked [Mandatory]
#      rxqcnt - count of Rx queues that are allegedly valid [Mandatory]
#      nic    - vmnic number. If not passed, vmnic number "1" will be used
#               [Optional]
#
# Results:
#      SUCCESS if NetQueue is working fine on host
#      FAILURE if NetQueue is not working find on host
#
# Side effects:
#      None.
#
# Notes:
#      This is an INTERNAL method for internal method calls only
#
################################################################################

sub ValidRxQueue
{
   my $self = shift;
   my $args = shift;

   if (not defined $args->{numofq} ||
       not defined $args->{rxqid} ||
       not defined $args->{rxqcnt}) {
      $vdLogger->Error("numofq / rxqid / rxqcnt not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $rxNumOfQueues = $args->{numofq};
   my $rxQueueCount = $args->{rxqcnt};
   my $rxQueueId = $args->{rxqid};
   my $nic = $args->{nic} || 1;
   my $vmnic = $self->{vmnicObj}->{$nic}->{vmnic};
   my $ai; # Array index
   my $lc; # Loop count
   my $firstRxQPktCnt = 0;
   my $lastRxQPktCnt = 0;

   foreach $ai (@{$rxNumOfQueues}) {
      $firstRxQPktCnt = $self->{vmnicObj}->{$nic}->GetQueuePktCount({
                                                 'txrxqueueid' => $ai,
                                                 'transtype' => "Rx",
                                                 'vmnic' => $vmnic,});
      if ($firstRxQPktCnt eq FAILURE) {
         $vdLogger->Error("Unable to retrieve first Rx queue packet count for ".
                          "$vmnic");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      # Sleeping for 2 seconds before retrieving the next Rx queue packet count
      sleep(2);
      $lastRxQPktCnt = $self->{vmnicObj}->{$nic}->GetQueuePktCount({
                                                 'txrxqueueid' => $ai,
                                                 'transtype' => "Rx",
                                                 'vmnic' => $vmnic,});
      if ($lastRxQPktCnt eq FAILURE) {
         $vdLogger->Error("Unable to retrieve last Rx queue packet count for ".
                          "$vmnic");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      for ($lc = 0; $lc < $rxQueueCount; $lc++) {
         if ($rxQueueId->[$lc] == $ai) {
            if ($lastRxQPktCnt > $firstRxQPktCnt) {
               $vdLogger->Debug("Correct Rx queue retrieved for queue $ai");
            } else {
               $vdLogger->Error("Incorrect Rx queue retrieved for queue $ai");
               VDSetLastError("EFAIL");
               return FAILURE;
            }
         }
      }
   }
   return SUCCESS;
}


################################################################################
#
# ValidTxQueue --
#      Method to check if valid Tx queues have been retrieved for each NIC in
#      Network Datapath functionality.
#
# Input:
#      PORTCOUNT - number of ports connected to NIC [Mandatory]
#      PORTID    - PortId array [Mandatory]
#      NUMACTQ   - Number of active queues in NIC [Mandatory]
#      NIC       - vmnic number. If not passed, vmnic number "1" will be used
#                  [Optional]
#
# Results:
#      SUCCESS if valid Tx Queues are bring used on host
#      FAILURE if any error
#
# Side effects:
#      None.
#
# Notes:
#      This is an INTERNAL method for internal method calls only
#
################################################################################

sub ValidTxQueue
{
   my $self = shift;
   my $args = shift;
   my $portCount = $args->{PORTCOUNT};
   my @portId = @{$args->{PORTID}};
   my $actTxQ = $args->{NUMACTQ};
   my $nic = $args->{NIC} || 1;
   my $vmnic = $self->{vmnicObj}->{$nic}->{vmnic};
   my $vSwNames = $self->{vSwitchObj}->{name};
   my @txQId = undef; # All Tx queues IDs
   my $firstPortStats = undef; # clientStats value for port - first retrieval
   my $lastPortStats = undef; # clientStats value for port - last retrieval
   my $firstTxQPktCnt = undef; # First instance of Tx queue packet count
   my $lastTxQPktCnt = undef; # Last instance of Tx queue packet count

   # Beginning the analysis
   for (my $ai = 0; $ai < $portCount; $ai++) {
      $txQId[$ai] = $self->{vmnicObj}->{$nic}->GetTxQueueId({
                               'portid' => $portId[$ai],
                               'numactq' => $actTxQ,
                               });
      if ($txQId[$ai] eq FAILURE) {
         $vdLogger->Error("Unable to retrieve Tx Queue ID for port ".
                          "$portId[$ai] active Tx queue $actTxQ");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      # Creating vsish path to access port clientstats information from
      # VDNetLib::Verification::StatsVerification::GetVSISHStats for the
      # first instance of Tx and Rx
      $firstPortStats = $self->{'vSwitchObj'}->GetPortClientStats(
                                     "$portId[$ai]",
                                    $vSwNames);

      if ($firstPortStats eq FAILURE) {
         $vdLogger->Error("Unable to retrieve client stats for the port id ".
                          "$portId[$ai]");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      # Sleep for 2 seconds before retrieving last packet values
      sleep(2);
      $lastPortStats = $self->{'vSwitchObj'}->GetPortClientStats(
                                     "$portId[$ai]",
                                     $vSwNames);

      if ($lastPortStats eq FAILURE) {
         $vdLogger->Error("Unable to retrieve client stats for the port id ".
                          "$portId[$ai]");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      # Checking validity of the port values retrieved
      if ($lastPortStats->{pktsTxOK} > $firstPortStats->{pktsTxOK}) {
         $vdLogger->Debug("Correct port Tx packet values retrieved for port".
                         " $portId[$ai]");
      } else {
         $vdLogger->Error("Incorrect port Tx packet values retrieved for port".
                          " $portId[$ai]");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      if ($lastPortStats->{pktsRxOK} > $firstPortStats->{pktsRxOK}) {
         $vdLogger->Debug("Correct port Rx packet values retrieved for port".
                         " $portId[$ai]");
      } else {
         $vdLogger->Error("Incorrect port Rx packet values retrieved for port".
                          " $portId[$ai]");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }
   # Checking if correct Tx queues have been allocated for each NIC
   $vdLogger->Debug("Checking if correct Tx queues have been allocated for ".
                   "$vmnic");
   if ($self->{vmnicObj}->{$nic}->{driver} =~ /ixgbe/i) {
      for (my $ai = 0; $ai < $actTxQ; $ai++) {
         $firstTxQPktCnt = $self->{vmnicObj}->{$nic}->GetQueuePktCount({
                                                    'txrxqueueid' => $ai,
                                                    'transtype' => "Tx",
                                                    'vmnic' => $vmnic,});
         if ($firstTxQPktCnt eq FAILURE) {
            $vdLogger->Error("Unable to retrieve Tx queue pkt count for queue ".
                             "$ai");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
         # Sleeping for 2 seconds between packet retrievals
         sleep(2);
         $lastTxQPktCnt = $self->{vmnicObj}->{$nic}->GetQueuePktCount({
                                                   'txrxqueueid' => $ai,
                                                   'transtype' => "Tx",
                                                   'vmnic' => $vmnic,});
         if ($lastTxQPktCnt eq FAILURE) {
            $vdLogger->Error("Unable to retrieve Tx queue pkt count for queue ".
                             "$ai");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
         for (my $lc = 0; $lc < $portCount; $lc++) {
            if ($txQId[$lc] == $ai) {
               if ($lastTxQPktCnt > $firstTxQPktCnt) {
                  $vdLogger->Debug("Correct Tx queue ID retrieved for queue $ai".
                                   " NIC $vmnic");
               } else {
                  $vdLogger->Error("Incorrect Tx queue ID retrieved for queue $ai".
                                   " NIC $vmnic");
                  VDSetLastError("EFAIL");
                  return FAILURE;
               }
            }
         }
      }
   }
   return SUCCESS;
}

################################################################################
#
# ValidRxFilter --
#      Method to check if valid Rx filters are being used for each NIC w.r.t.
#      Network Datapath functionality.
#
# Input:
#      NUMOFQ    - Number of queues in NIC [Mandatory]
#      NIC       - vmnic number. If not passed, vmnic number "1" will be used
#                  [Optional]
#
# Results:
#      Hash of values / counts that will be used later to determine Networking
#      Datapath functionality in the host
#      FAILURE if any error
#
# Side effects:
#      None.
#
# Notes:
#      This is an INTERNAL method for internal method calls only
#
################################################################################

sub ValidRxFilter
{
   my $self = shift;
   my $args = shift;
   my $numOfQ = $args->{NUMOFQ};
   my $nic = $args->{NIC} || 1;
   my $vmnic = $self->{vmnicObj}->{$nic}->{vmnic};
   my $vSwNames = $self->{vSwitchObj}->{name};
   my $rxQFilter = undef; # Rx queue filter IDs for NIC
   my $filterId = undef; # Rx filter ID
   my $rxPortCnt = 0; # Rx port count for NIC
   my $actFilterCnt = 0; # Rx active filter count for NIC
   my $rxQCnt = 0; # Count of non-default Rx queues for NIC
   my @rxQId = undef; # All non-default Rx queue Ids for NIC
   my $defFilterCnt = 0; # Rx active filter count for NIC
   my $rxFilterHash = undef; # Hash to store Rx Filter info
   my @rxFilterPort = undef; # All Rx filter ports in NIC
   my @rxFilterMac = undef; # All Rx filter MAC addresses in NIC
   my $rxClass = undef; # Rx filter class ID
   my $rxVlan = undef; # Rx filter Vlan ID
   my $rxFeat = undef; # Rx filter features
   my $rxProp = undef; # Rx filter properties
   my $rxFilterLoad = undef; # Rx filter load

   foreach my $ai (@{$numOfQ}) {
      chop($ai);
      $rxQFilter = $self->{vmnicObj}->{$nic}->GetRxQueueFilters($ai,$vmnic);
      if (defined @{$rxQFilter}) {
         for (my $lc = 0; $lc < @{$rxQFilter}; $lc++) {
            $filterId = $rxQFilter->[$lc];
            chop($filterId);
            $rxFilterHash = $self->{vmnicObj}->{$nic}->RxFilterInfo({
                                   'rxqid' => $ai,
                                   'rxfilterid' => $filterId,
                                   'vmnic' => $vmnic,});
            if ($rxFilterHash eq FAILURE) {
               $vdLogger->Error("Unable to retrieve Rx Filter info for NIC ".
                                "$vmnic");
               VDSetLastError("EFAIL");
               return FAILURE;
            }
            # Counting the ports only for VMM ports (clientType = 5)
            my $portProperties = $self->CheckPortProperties($vSwNames,
                                                            $rxFilterHash->{portID});
            if ($portProperties ne FAILURE) {
               if ($portProperties->{clientType} == 5) {
                  $rxFilterLoad = $rxFilterHash->{load};
                  $rxFilterPort[$rxPortCnt] = $rxFilterHash->{portID};
                  $rxFilterMac[$rxPortCnt] = $rxFilterHash->{unicastAddr};
                  $rxClass = $rxFilterHash->{fclass};
                  $rxVlan = $rxFilterHash->{vlanid};
                  $rxFeat = $rxFilterHash->{features};
                  $rxProp = $rxFilterHash->{prop};
                  if ($rxFilterLoad > 0) {
                     $actFilterCnt++;
                     $rxQId[$rxQCnt] = $ai;
                     $rxQCnt++;
                  } else {
                     $defFilterCnt++;
                  }
                  $rxPortCnt++;
                  $vdLogger->Debug("Current port count for NIC $vmnic = ".
                                  "$rxPortCnt");
               }
            } else {
               $vdLogger->Error("Unable to retrieve port properties for ".
                                "port $rxFilterHash->{portID}");
               VDSetLastError("EFAIL");
               return FAILURE;
            }
         }
      } else {
         $vdLogger->Debug("No filter found for queue $ai NIC $vmnic");
      }
   }
   # Creating hash to return to function caller
   my %returnHash = ("actFilterCnt" => $actFilterCnt,
                     "rxPortCnt" => $rxPortCnt,
                     "rxFilterLoad" => $rxFilterLoad,
                     "rxClass" => $rxClass,
                     "rxVlan" => $rxVlan,
                     "rxFeat" => $rxFeat,
                     "rxProp" => $rxProp,
                     "defFilterCnt" => $defFilterCnt,
                     "rxFilterPort" => \@rxFilterPort,
                     "rxFilterMac" => \@rxFilterMac,
                     "rxQId" => \@rxQId,
                     "rxQCnt" => $rxQCnt);
   return \%returnHash;
}

################################################################################
#
# GetVnicPortIds --
#      Method to get array of Vnic port Ids that are connected to any vSwitch
#
# Input:
#      switch    - name of vSwitch [Mandatory]
#
# Results:
#      Array reference of port Ids
#      FAILURE if any error
#
# Side effects:
#      None.
#
# Notes:
#      This is an INTERNAL method for internal method calls only
#
################################################################################

sub GetVnicPortIds
{
   my $self = shift;
   my $switch = shift;
   my @vNicPortList = ();

   $switch =~ s/\///;
   # Following command will get the list of port under each switch.
   # Sample output:
   # >vsish -e ls /net/portsets/vSwitch0/ports
   #  16777217/
   #  16777218/
   #  16777219/
   #
   my $command = "vsish -e ls /net/portsets/$switch/ports";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   # check for success or failure of the command executed using staf
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to obtain the vnic pts ports Error" .
                       Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   if ($result->{stdout} !~ /\d+\/\n/) {
      $vdLogger->Error("Failed to obtain the vnic pts ports Error" .
                       Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Get the list of ports from the string and store them in an array
   my @portList = split(/\n/, $result->{stdout});

   # Check port if it's a vnic and then return only those port Ids
   my $k = 0;
   foreach my $portId (@portList) {
      chomp($portId);
      $command = "vsish -pe get /net/portsets/$switch/ports/$portId"."status";
      $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to obtain the port status" .
                          Dumper($result));
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      $result->{stdout} = VDNetLib::Common::Utilities::ProcessVSISHOutput(
                                            RESULT => $result->{stdout}
                                            );
      if ($result->{stdout} ne FAILURE) {
         if ($result->{stdout}{clientType} == 5) {
            $vNicPortList[$k] = $portId;
            $vNicPortList[$k] =~ s/\///;
            $k++;
         }
      } else {
         $vdLogger->Error("Unable to change output to hash");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }
   if ((scalar @vNicPortList) > 0) {
      return \@vNicPortList;
   }
   $vdLogger->Error("Unable to retrieve ports connected to vSwitch $switch");
   VDSetLastError("EFAIL");
   return FAILURE;
}


################################################################################
#
# CollectRxParams --
#      Method to collect / retrieve Rx Params for host
#
# Input:
#      NIC    - NIC name [Mandatory]
#      NICID  - NIC ID [Mandatory]
#
# Results:
#      Hash reference of Rx params, if successful
#      FAILURE if any error
#
# Side effects:
#      None.
#
# Notes:
#      This is an INTERNAL method for internal method calls only
#
################################################################################

sub CollectRxParams
{
   my $self = shift;
   my $args = shift;
   my $nic = $args->{NIC};
   my $nicId = $args->{NICID};
   my $rxSupQ = undef; # Number of Rx supported queues
   my $rxSupFilter = undef; # Number of Rx supported filters
   my $rxActFilter = undef; # Number of Rx active filters
   my $rxNumOfQ = undef; # Number of Rx queues
   my $validRxFilterHash = undef; # Hash to store valid Rx Filter info

   $rxSupQ = $self->{vmnicObj}->{$nicId}->RxQueueInfo("maxQueues",$nic);
   if ($rxSupQ eq FAILURE) {
      $vdLogger->Error("Unable to retrieve Rx supported queues for NIC $nic");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $rxSupFilter = $self->{vmnicObj}->{$nicId}->RxQueueInfo("numFilters",$nic);
   if ($rxSupFilter eq FAILURE) {
      $vdLogger->Error("Unable to retrieve Rx supported filters for NIC $nic");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $rxActFilter = $self->{vmnicObj}->{$nicId}->RxQueueInfo("numActiveFilters", $nic);
   if ($rxActFilter eq FAILURE) {
      $vdLogger->Error("Unable to retrieve Rx active filters for NIC $nic");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Retrieving the number of Rx queues per NIC
   $vdLogger->Debug("Retrieving the number of Rx queues per NIC");
   $rxNumOfQ = $self->{vmnicObj}->{$nicId}->GetRxQueues($nic);
   if ($rxNumOfQ eq FAILURE) {
      $vdLogger->Error("Unable to retrieve Rx number of queues for NIC $nic");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Checking if correct Rx filters are being used in the non-default queues
   # with the total number of ports being used
   $vdLogger->Debug("Checking if correct Rx filters are being used in the non-".
                   "default queues with the total number of ports being used");
   $validRxFilterHash = $self->ValidRxFilter({'NUMOFQ' => $rxNumOfQ,
                                              'NIC' => $nicId});
   if ($validRxFilterHash eq FAILURE) {
      $vdLogger->Error("Unable to retrieve Rx Filter info for NIC ".
                       "$nic");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   my %returnHash = ("rxSupQ" => $rxSupQ,
                     "rxSupFilter" => $rxSupFilter,
                     "rxActFilter" => $rxActFilter,
                     "rxNumOfQ" => $rxNumOfQ,
                     "validRxFilterHash" => $validRxFilterHash);
   return \%returnHash;
}


################################################################################
#
# CheckPortProperties --
#      Method to check Port properties
#
# Input:
#      switch    - name of vSwitch [Mandatory]
#      portId    - port Id [Mandatory]
#
# Results:
#      Hash of port properties
#      FAILURE if any error
#
# Side effects:
#      None.
#
# Notes:
#      This is an INTERNAL method for internal method calls only
#
################################################################################

sub CheckPortProperties
{
   my $self = shift;
   my $switch = shift;
   my $portId = shift;
   my @vNicPortList = ();

   $switch =~ s/\///;
   # Following command will get the properties of each port under each switch.
   # Sample output:
   # vsish -e get /net/portsets/vswitch-0-6979/ports/50336303/status
   # port {
   # portCfg:vswitchpg-0-6979
   # dvPortId:
   # clientName:AuxVM1
   # clientType:port types: 5 -> VMM Virtual NIC
   # clientSubType:port types: 9 -> Vmxnet3 Client
   # world leader:1094565
   # flags:port flags: 0x1003a3 -> IN_USE ENABLED WORLD_ASSOC RX_COALESCE TX_COALESCE TX_COMP_COALESCE CONNECTED
   # Passthru status:: 0x4 -> NO_IOMMU
   # ethFRP:frame routing {
   #    requested:filter {
   #       flags:0x0000000b
   #       unicastAddr:00:0c:29:e7:d2:d6:
   #       LADRF:[0]: 0x0
   #       [1]: 0x0
   #    }
   #    accepted:filter {
   #       flags:0x0000000b
   #       unicastAddr:00:0c:29:e7:d2:d6:
   #       LADRF:[0]: 0x0
   #       [1]: 0x0
   #    }
   #  }
   #  filter supported features:features: 0x1 -> LRO
   #  filter properties:properties: 0 -> NONE
   # }
   #
   my $command = "vsish -pe get /net/portsets/$switch/ports/$portId/status";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   # check for success or failure of the command executed using staf
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to obtain the vnic pts ports Error" .
                       Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Return port properties as a hash
   $result->{stdout} = VDNetLib::Common::Utilities::ProcessVSISHOutput(
                                         RESULT => $result->{stdout}
                                         );
   if ($result->{stdout} ne FAILURE) {
      return $result->{stdout};
   } else {
      $vdLogger->Error("Unable to change output to hash");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}

#########################################################################
#
#  GetHostMemInfo --
#      Given the host Info this method returns the memory
#
# Input:
#      physical host info
#
# Results:
#      Returns Memory Info of the host given,
#      if there was no error executing the command.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################
sub GetHostMemInfo
{
   my $self   = shift;
   my $host   = shift;
   my $mem    = 0;
   my $data   = 0;
   my $command;

   $command = "esxcli hardware memory get|grep 'Memory'";
   my $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                       $command);
   #check for failure of the command
   if ($result->{exitCode} != 0) {
       $vdLogger->INFO("GetHostMemInfo:Could not get the Meminfo");
       return FAILURE;
    }
   $data=$result->{stdout};
    if($data =~ m/(\d+)/){
       $mem=$1;
    }
   #convert bytes to megabytes
   $mem = int($mem/1048576);
   return $mem;
}


################################################################################
#
# CheckIPv6Host --
#      Method to check if IPv6 is enabled on ESXi host
#
# Input:
#      None.
#
# Results:
#      "SUCCESS", if ipv6 is enabled
#      "FAILURE", in case of any error
#
#
# Side effects:
#      None
#
################################################################################

sub CheckIPv6Host
{
   my $self = shift;

   # Creating command
   my $command = "$vmknicEsxcli get";

   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if ($result->{rc} != 0) {
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Parsing output
   my @temp = split(':\s+',$result->{stdout});
   if ($temp[$#temp] =~ /true/i) {
      $vdLogger->Debug("IPv6 is enabled on host");
      return SUCCESS;
   } elsif ($temp[$#temp] =~ /false/i) {
      $vdLogger->Warn("IPv6 is disabled on host");
      return FAILURE;
   }
   $vdLogger->Debug("Unable to determine if IPv6 is enabled / disabled on host");
   return FAILURE;
}


########################################################################
#
# GetDVSNameFromPortset --
#      Method to get dvs name from the dv portset name seen on the host.
#
# Input:
#      portset : name of the dv portset (Required)
#
# Results:
#      dvs name (scalar string) corresponding to the given
#      dv portset name, if successful;
#      FAILURE, in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetDVSNameFromPortset {
   my $self = shift;
   my $portset = shift;

   if (not defined $portset) {
      $vdLogger->Error("portset name not provided to get dvsname");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $command = "net-dvs -l | grep -B 50 -i $portset";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   # check for success or failure of the command executed using staf
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to obtain the portset info");
      VDSetLastError("ESTAF");
      return FAILURE;
   }


   my $dvsname;
    #com.vmware.common.alias = dvSwitch2
   if ($result->{stdout} =~ /com\.vmware\.common\.alias = (.*)/i) {
      my $type;
      $dvsname = $1;
      ($dvsname, $type) = split(/ ,/, $dvsname);
   }

   if (not defined $dvsname) {
      $vdLogger->Error("No information available about portset $portset" .
                       " : $result->{stdout}");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   return $dvsname;
}


########################################################################
#
# GetPortSetNamefromDVS --
#      Method to get portset name of a dv switch as seen on vsish.
#
# Input:
#      dvsName : name of the dvSwitch (Required)
#
# Results:
#      dv portset name (scalar string) corresponding to the given
#      dv switch, if successful;
#      FAILURE, in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetPortSetNamefromDVS
{
   my $self = shift;
   my $dvsName = shift;

   if (not defined $dvsName) {
      $vdLogger->Error("dvsName not provided at GetPortSetNamefromDVS method");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $command = "net-dvs -l $dvsName";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   # check for success or failure of the command executed using staf
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to obtain the portset info");
      VDSetLastError("ESTAF");
      return FAILURE;
   }


   my $portsetName;
   # The portset information is available in net-dvs output as
   # 'com.vmware.common.host.portset = dvSwitch<X>'.
   # Collect the dvSwitch name.
   #
   if ($result->{stdout} =~ /com\.vmware\.common\.host\.portset = (.*)/i) {
      my $type;
      $portsetName = $1;
      ($portsetName, $type) = split(/ ,/, $portsetName);
   }

   if (not defined $portsetName) {
      $vdLogger->Error("No information available about dvs $dvsName" .
                       " : $result->{stdout}");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   return $portsetName;
}


########################################################################
#
# SetDVSUplinkPortStatus --
#      Method to set the uplink port status of the dvs to "down" or
#      "up".
#
#
# Input:
#      vmnicObjsRef: Reference to vmnic object array to be checked,
#                    but one object is allowed.
#      status : status to be set for the dvs uplink port.
#      switchObjRef: dvs switch object to be checked.
#
# Results:
#      SUCCESS if setting uplink status successful;
#      FAILURE if setting uplink status fails;
#
# Side effects:
#      The dvport status is either set to down or up, which causes the
#      pnic connected to it go down or up respectively.
#
########################################################################

sub SetDVSUplinkPortStatus
{
   my $self = shift;
   my %args = @_;
   my $vmnicObjsRef = $args{vmnicadapter};
   my $status = $args{port_status} || "up";
   my $switchObjRef = $args{switch};
   my $activePorts;
   my $portID;
   my $command;
   my $result;

   if ((not defined $switchObjRef) || (not defined $vmnicObjsRef) ){
      $vdLogger->Error("Parameter switch or vmnicadapter not specifed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $dvsName = $switchObjRef->{name};
   my $vmnic = $vmnicObjsRef->[0]->{interface};
   if ((not defined $vmnic) || (not defined $dvsName)) {
      $vdLogger->Error("Uplink and/or dvs not passed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($status !~ m/up|down/i) {
      $vdLogger->Error("Invalid status $status defined, valid" .
                       "values are up and down");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   #
   # Get the list of ports on the given dv switch.
   # This list will include both vmnic uplinks and VM clients.
   #
   $activePorts = $self->GetActiveDVPorts($dvsName);

   if ($activePorts eq FAILURE) {
      $vdLogger->Error("Failed to get active ports " .
                       " on $dvsName");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # get the dvport id corresponding to pnic.
   $portID = $activePorts->{$vmnic}{'Port ID'};
   if (not defined $portID) {
      $vdLogger->Error("Failed to get port id " .
                       " of $vmnic on $dvsName");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # command to set the uplink port status.
   $command = NETDVSPATH ."net-dvs -M $status -p $portID $dvsName";
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                  $command);
   # check for success or failure of the command
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to set uplink port status using $command");
      VDSetLastError("ESTAF");
      $vdLogger->Error(Dumper($result));
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# DVPortGroupIDFromName --
#      Method to get the dvportgroup id (string not the port id like 0,
#      1, 2,..N) of the dv portgroup. dv portgroup id, dv portgroup name
#      and port id are alias to each other.
#
# Input:
#      dvsName : nameof the dvswitch (Required)
#      dvPGName : name of the dv portgroup whose alias portgroup id
#                 need to be found (Required)
#
# Results:
#      dv portgroup id (scalar string), if successful;
#      FAILURE, in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub DVPortGroupIDFromName
{
   my $self = shift;
   my $dvsName = shift;
   my $dvPGName = shift;

   if ((not defined $dvsName) || (not defined $dvPGName)) {
      $vdLogger->Error("dvsName and/or dvPGName not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $pyObj = $self->GetInlinePyObject();
   my $result = CallMethodWithKWArgs($pyObj, 'get_dvpg_id_from_name',
                             {'dvs'=> $dvsName, 'dvpg'=> $dvPGName});
   if($result eq FAILURE){
      $vdLogger->Error("Could not retrieve ID of $dvPGName on $dvsName");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $result;
}


########################################################################
#
# GetNetVSICacheFile --
#      Gets the vsi cache (of networking )from host and copies to the
#      master controller.
#
# Input:
#      logDir : Name of the directory on master controller where
#                directory is to be copied.
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

sub GetNetVSICacheFile
{
   my $self = shift;
   my $logDir = shift;
   my $hostIP = $self->{hostIP};
   my $file = "/var/core/vsi-net-cache-$hostIP";
   my $command = "vsi_traverse -o $file";
   my $localIP = VDNetLib::Common::Utilities::GetLocalIP();
   my $result;
   my $ret = SUCCESS;

   if (not defined $logDir) {
      $vdLogger->Error("Log Directory not defined to copy the logs");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($localIP eq FAILURE) {
      $vdLogger->Error("Failed to get the ip address of ".
                       "Master Controller");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # first create the vsi cache file.
   $result = $self->{stafHelper}->STAFAsyncProcess($hostIP, $command);
   if ($result->{rc} != 0)  {
      $vdLogger->Error("Failed to run vsi_traverse on host $hostIP");
      $vdLogger->Debug(Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   # if error is failed to open then remove the old file.
   if (defined ($result->{stderr}) &&
      $result->{stderr} =~ m/"Failed to open cache file"/i) {
      $result = $self->{stafHelper}->STAFFSDeleteFileOrDir($hostIP,
                                                        $file
                                                        );

      if (not defined $result) {
         $vdLogger->Error("Failed to remove $file on host $hostIP");
         $vdLogger->Debug(Dumper($result));
         VDSetLastError("ESTAF");
         $ret = FAILURE;
      }
      # create the cache file again.
      $result = $self->{stafHelper}->STAFAsyncProcess($hostIP, $command);
      if ($result->{rc} != 0)  {
         $vdLogger->Error("Failed to run vsi_traverse on host $hostIP");
         $vdLogger->Debug(Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }

   # copy the vsi cache file from host to MC.
   $result = $self->{stafHelper}->STAFFSCopyFile($file,
                                                 $logDir,
                                                 $hostIP,
                                                 $localIP
                                                 );
   if ($result ne 0) {
      $vdLogger->Error("Failed to copy vsicache file $file from host ".
                       " $hostIP to Master Controller");
      $vdLogger->Debug(Dumper($result));
      VDSetLastError("ESTAF");
      $ret = FAILURE;
   }

   # remove the file on esx host.
   $result = $self->{stafHelper}->STAFFSDeleteFileOrDir($hostIP,
                                                        $file
                                                        );

   if (not defined $result) {
      $vdLogger->Error("Failed to remove $file on host $hostIP");
      $vdLogger->Debug(Dumper($result));
      VDSetLastError("ESTAF");
      $ret = FAILURE;
   }
   return $ret;
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
   my $hostIP = $self->{hostIP};
   my $file = $logDir."/"."NetConfiguration"."_".$hostIP.".txt";
   my ($vswitch, $vmknic, $vdswitch, $vmnic, $netDVS, $esxcfg_vswitch);
   my $command;
   my $result;
   my $ret = SUCCESS;

   # list the vswitch.
   $command = "$vswitchEsxcli list";
   $result = $self->{stafHelper}->STAFSyncProcess($hostIP, $command);
   if (($result->{rc} !=0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to list vswitch on host $hostIP");
      VDSetLastError("ESTAF");
      $ret = FAILURE;
   }
   $vswitch = $result->{stdout};

   # list the vswitch.
   $command = "esxcfg-vswitch -l";
   $result = $self->{stafHelper}->STAFSyncProcess($hostIP, $command);
   if (($result->{rc} !=0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to do esxcfg-vswitch -l on host $hostIP");
      VDSetLastError("ESTAF");
      $ret = FAILURE;
   }
   $esxcfg_vswitch = $result->{stdout};

   # list the vmknic
   $command = "$vmknicEsxcli interface list";
   $result = $self->{stafHelper}->STAFSyncProcess($hostIP, $command);
   if (($result->{rc} !=0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to list vmknic on host $hostIP");
      VDSetLastError("ESTAF");
      $ret = FAILURE;
   }
   $vmknic = $result->{stdout};

   # list the vdswitch
   $command = "$vdswitchEsxcli list";
   $result = $self->{stafHelper}->STAFSyncProcess($hostIP, $command);
   if (($result->{rc} !=0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to list vdswitch on host $hostIP");
      VDSetLastError("ESTAF");
      $ret = FAILURE;
   }
   $vdswitch = $result->{stdout};

   # list pnics.
   $command = "$vmnicEsxcli list";
   $result = $self->{stafHelper}->STAFSyncProcess($hostIP, $command);
   if (($result->{rc} !=0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to list pnic on host $hostIP");
      VDSetLastError("ESTAF");
      $ret = FAILURE;
   }
   $vmnic = $result->{stdout};

   $command = NETDVSPATH . "net-dvs -l";
   $result = $self->{stafHelper}->STAFSyncProcess($hostIP, $command);
   if (($result->{rc} !=0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to get the vds configuration on host $hostIP");
      VDSetLastError("ESTAF");
      $ret = FAILURE;
   }
   $netDVS = $result->{stdout};

   open FILE, ">" ,$file;
   print FILE "Virtual Switch List\n\n";
   print FILE "$vswitch\n\n\n";
   print FILE "Virtual Switch Configuration\n\n";
   print FILE "$esxcfg_vswitch\n\n\n";
   print FILE "Vmknic List\n\n";
   print FILE "$vmknic\n\n\n";
   print FILE "VDS Configuration\n\n";
   print FILE "$vdswitch\n\n\n";
   print FILE "VMkernel NIC Configuration\n\n";
   print FILE "$vmknic\n\n\n";
   print FILE "Physical NIC Configuration\n\n";
   print FILE "$vmnic\n\n\n";
   if (defined $netDVS) {
      print FILE "net-dvs configuration\n\n";
      print FILE "$netDVS\n\n\n";
   }
   close (FILE);

   return $ret;
}

########################################################################
#
# GetVMKernelLog--
#      Get the networking config on the esx host, vswitch, vds and vmknic
#      output.
#
# Input:
#      logDir : Name of the directory on master controller where
#                directory are to be copied.
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

sub GetVMKernelLog
{
   my $self = shift;
   my $logDir = shift;
   my $hostIP = $self->{hostIP};
   my $stafHelper = $self->{stafHelper};
   my $localIP = VDNetLib::Common::Utilities::GetLocalIP();
   my $result;

   if (not defined $logDir) {
      $vdLogger->Error("Log Directory not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($localIP eq FAILURE) {
      $vdLogger->Error("Failed to get the ip address of ".
                       "Master Controller");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # copy vmkernel log's to log directory.
   $result = $stafHelper->STAFFSCopyFile(VMKRNLLOGFILE,
                                         $logDir,
                                         $hostIP,
                                         $localIP);
   if ($result ne 0) {
      $vdLogger->Warn("Failed to copy " . VMKRNLLOGFILE .
	              " from $hostIP");
      $vdLogger->Debug(Dumper($result));
      VDSetLastError("ESTAF");
   #   return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetLACPLog--
#      Get the lacp log file
#
# Input:
#      logDir : Name of the directory on master controller where
#                directory are to be copied.
#
#
# Results:
#     SUCCESS if lacp log file gets copied to master controller
#     FAILURE if there are errors during VSI cache file generation or while
#             copying it.
#
# Side effects:
#      None
#
########################################################################

sub GetLACPLog
{
   my $self = shift;
   my $logDir = shift;
   my $hostIP = $self->{hostIP};
   my $stafHelper = $self->{stafHelper};
   my $localIP = VDNetLib::Common::Utilities::GetLocalIP();
   my $result;

   if (not defined $logDir) {
      $vdLogger->Error("Log Directory not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($localIP eq FAILURE) {
      $vdLogger->Error("Failed to get the ip address of ".
                       "Master Controller");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # copy vmkernel log's to log directory.
   $result = $stafHelper->STAFFSCopyFile(LACPLOGFILE,
                                         $logDir,
                                         $hostIP,
                                         $localIP);
   if ($result ne 0) {
      $vdLogger->Error("Failed to copy LACPLOGFILE");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}


#######################################################################
#
# GetSysLogs--
#      Copy the log files under /var/log form the host to specified
#      directory.
#
# Input:
#      logDir : Name of the directory on master controller where
#                directory are to be copied.
#
# Results:
#     SUCCESS if host agent logs are copied successfully.
#     FAILURE if there are errors while copying the host agent logs.
#
# Side effects:
#      None
#
########################################################################

sub GetSysLogs
{
   my $self = shift;
   my $logDir = shift;
   my $hostIP = $self->{hostIP};
   my $stafHelper = $self->{stafHelper};
   my $localIP = VDNetLib::Common::Utilities::GetLocalIP();
   my $result;

   if (not defined $logDir) {
      $vdLogger->Error("Log Directory not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($localIP eq FAILURE) {
      $vdLogger->Error("Failed to get the ip address of ".
                       "Master Controller");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (VDNetLib::Common::Utilities::CreateSSHSession($hostIP,
      $self->{userid}, $self->{sshPassword}) eq FAILURE) {
      $vdLogger->Error("Create ssh session failed to host $hostIP");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # copy system log files to log directory.
   # Replace STAFFSCopyDirectory with VDNetLib::Common::Utilities::CopyDirectory
   # since log collection hangs at this function
   $result = VDNetLib::Common::Utilities::CopyDirectory(srcDir => SYSLOGPATH,
        dstDir => $logDir, srcIP => $hostIP, stafHelper => $self->{stafHelper});

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to copy SYSLOGPATH log");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Debug("Successfully copy SYSLOGPATH log to $logDir from $hostIP");
   return SUCCESS;
}


#######################################################################
#
# GetHostAgentLog--
#      Copy the host agent log form the host to specified directory.
#
# Input:
#      logDir : Name of the directory on master controller where
#                directory are to be copied.
#
# Results:
#     SUCCESS if host agent logs are copied successfully.
#     FAILURE if there are errors while copying the host agent logs.
#
# Side effects:
#      None
#
########################################################################

sub GetHostAgentLog
{
   my $self = shift;
   my $logDir = shift;
   my $hostIP = $self->{hostIP};
   my $hostAgent = "/var/log/hostd.log";
   my $stafHelper = $self->{stafHelper};
   my $localIP = VDNetLib::Common::Utilities::GetLocalIP();
   my $result;

   if (not defined $logDir) {
      $vdLogger->Error("Log Directory not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($localIP eq FAILURE) {
      $vdLogger->Error("Failed to get the ip address of ".
                       "Master Controller");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # copy hostd log file to log directory.
   $result = $stafHelper->STAFFSCopyFile($hostAgent,
                                         $logDir,
                                         $hostIP,
                                         $localIP);
   if ($result ne 0) {
      $vdLogger->Error("Failed to copy VMKRNLLOGFILE");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}


#######################################################################
#
# GetVPXAgentLog--
#      Copy the host agent log form the host to specified directory.
#
# Input:
#      logDir : Name of the directory on master controller where
#                directory are to be copied.
#
# Results:
#     SUCCESS if VPX agent logs are copied successfully.
#     FAILURE if there are errors while copying the VPX agent logs.
#
# Side effects:
#      None
#
########################################################################

sub GetVPXAgentLog
{
   my $self = shift;
   my $logDir = shift;
   my $hostIP = $self->{hostIP};
   my $vpxAgent = "/var/log/vpxa.log";
   my $stafHelper = $self->{stafHelper};
   my $localIP = VDNetLib::Common::Utilities::GetLocalIP();
   my $result;

   if (not defined $logDir) {
      $vdLogger->Error("Log Directory not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($localIP eq FAILURE) {
      $vdLogger->Error("Failed to get the ip address of ".
                       "Master Controller");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # copy vpx agent log file to log directory.
   $result = $stafHelper->STAFFSCopyFile($vpxAgent,
                                         $logDir,
                                         $hostIP,
                                         $localIP);
   if ($result ne 0) {
      $vdLogger->Error("Failed to copy VMKRNLLOGFILE");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetDVSInfo --
#      One of the most important method to retrieve all information
#      about of a dvswitch using net-dvs command on the given host
#
# Input:
#      dvsName : Name of the dvswitch (Required)
#
# Results:
#      Reference to a hash with keys as different port ids available
#      on the dvswitch (example, Port 0, Port 2, Port 10 etc).
#      Each port is reference to a hash which contains all properties
#      of the dv port.
#      Each line of information about a port is captured in the hash.
#      For example, "load balancing = source virtual port id",
#      is stored with key as 'load balancing' and value as
#      'source virtual port id'.
#
#      ForFor all the properties of dv portgroup, refer
#      to net-dvs command help.
#
# Side effects:
#      None
#
########################################################################

sub GetDVSInfo
{
   my $self = shift;
   my $dvsName = shift;

   if (not defined $dvsName) {
      $vdLogger->Error("dvsName not provided at GetDVSInfo method");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $command = "net-dvs -l $dvsName";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   # check for success or failure of the command executed using staf
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to obtain the net-dvs info for $dvsName" .
                       $result->{rc});
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   #
   # Store each line of net-dvs -l <dvsName> in an array.
   # Process each line. Look for 'Port <id>' and store every line
   # under each port in a hash (key/value).
   #
   my @tempArray = split(/\n/, $result->{stdout});

   my $portgroup = undef;
   my $dvpgHash;
   foreach my $line (@tempArray) {
      if ($line =~ /port (\d+):/i) {
         $portgroup = $1;
      }
      if (not defined $portgroup) {
         next;
      }
      if ($line =~ /com\.vmware\.common\.port\.portgroupid = (.*) ,/i) {
         $dvpgHash->{$portgroup}{'dvpgID'} = $1;
      }
      if ($line =~ /=/){
         my ($key, $value) = split(/=/, $line);
         $key =~ s/^\s+|\s+$//g; # remove any spaces before and after stats name
         $value =~ s/^\s+|\s+$//g; # remove any spaces before and after value
         $dvpgHash->{$portgroup}{$key} = $value;
      }
   }
   return $dvpgHash;
}


########################################################################
#
# GetDVSTeamPolicy --
#      Method to get the team policy settings on the given dv portgroup.
#      TODO: This method should go VDSwitch.pm or DVPortGroup.pm
#      Since Session.pm is does not pass testbed object, there is a
#      limitation to create switch object of type vdswitch in
#      ActiveVMNicVerification.pm.
#
# Input:
#      dvsName : name of the dvSwitch (Required)
#      dvPGName: dv portgroup name whose team policy need to be
#                retrieved (Required)
#
# Results:
#      Reference to a hash with following keys:
#      'Load Balancing' : /srcmac/srcport/iphash/loadbased/explicit
#      'ActiveAdapters' : Reference to an array of dvUplink ports
#      'Standby Adapters' : List of standby adapters on the portgroup
#      'Failback'       : yes/no
#      'NotifySwitch'   : yes/no
#
#      This method is vdswitch version of GetvSwitchNicTeamingPolicy()
#      in VSSwitch.pm
#
# Side effects:
#      None
#
########################################################################

sub GetDVSTeamPolicy
{
   my $self     = shift;
   my $dvsName  = shift;
   my $dvPGName = shift;

   if ((not defined $dvsName) || (not defined $dvPGName)) {
      $vdLogger->Error("dvsName and/or dvPGName not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # First step, get all the information about the given dvs.
   #
   my $dvsInfo = $self->GetDVSInfo($dvsName);

   if ($dvsInfo eq FAILURE) {
      $vdLogger->Error("Failed to get information about $dvsName");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $portID = $dvPGName;

   #
   # GetDVSInfo() returns a hash reference with different ports available
   # as keys of that hash. Retrieve the information of the key corresponding
   # to the given portid of the given dvPGName.
   #
   my $dvpgInfo = $dvsInfo->{$portID};
   $vdLogger->Debug(Dumper($dvpgInfo));

   my $lbPolicy = $dvpgInfo->{'load balancing'};

   my $teamPolicy;
   if (defined $lbPolicy) {
      #
      # Converting the loading balancing and other teaming policy information
      # to be similar to vSwitch's team policy information.
      #
      if ($lbPolicy =~ /source virtual port id/i) {
         $teamPolicy->{'Load Balancing'}  = "srcport";
      } elsif ($lbPolicy =~ /source mac address/) {
         $teamPolicy->{'Load Balancing'} = "srcmac";
      } elsif ($lbPolicy =~ /source ip address/) {
         $teamPolicy->{'Load Balancing'} = "iphash";
      } elsif ($lbPolicy =~ /source port traffic load/) {
         $teamPolicy->{'Load Balancing'} = "loadbased";
      } else {
        $teamPolicy->{'Load Balancing'} = "explicit";
      }
   } else {
      $teamPolicy->{'Load Balancing'} = undef;
   }

   #
   # Get the list of active uplinks
   my $activeUplinks = $dvpgInfo->{active};

   if (not defined $activeUplinks) {
      $vdLogger->Error("Active uplinks information is missing for $portID");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # Store the active adapters in an array (reference)
   #
	my @tmp = split(/;\s?/, $activeUplinks);
   $teamPolicy->{"ActiveAdapters"} = \@tmp;

   my $stanbyNics = $dvpgInfo->{standby};
   $stanbyNics =~ s/;\s/ /g;
   $teamPolicy->{'Standby Adapters'} = $stanbyNics;

   my $notifySwitch = $dvpgInfo->{'link behavior'};

   if ($notifySwitch =~ /notify/i) {
      $teamPolicy->{'NotifySwitches'} = "yes";
   } else {
      $teamPolicy->{'NotifySwitches'} = "no";
   }

   if ($notifySwitch =~ /rolling failover/) {
      $teamPolicy->{'Failback'} = "no";
   } else {
      $teamPolicy->{'Failback'} = "yes";
   }

   return $teamPolicy;
}


########################################################################
#
# GetActiveDVPorts --
#      Method to get the list of all active ports (vmnic + vm) of the
#      host on the given dv switch.
#
# Input:
#      dvsName : name of the dvSwitch (Required)
#
# Results:
#      Reference to a hash with client names (example, vmnic1, vmnic2,
#        "<vmName> <ethernetX>")  as keys. Each keys is a reference to
#        a hash which has the following keys:
#        'Port ID' : integer that represents the port occupied by this
#                    client on dvSwitch
#        'DVPortgroup ID': portgroup id/name for this port
#        'In Use'  : true/fase depending on the usage.
#
# Side effects:
#      None
#
########################################################################

sub GetActiveDVPorts
{
   my $self = shift;
   my $dvsName = shift;

   if (not defined $dvsName) {
      $vdLogger->Error("dvsName not provided at GetActiveDVPorts method");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # Using the following esxcli command, get the port information of
   # dvswitches.
   # Then, collect the ports information of switches whose name matches
   # the given vds.
   #
   my $command = 'esxcli network vswitch dvs vmware list';
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   # check for success or failure of the command executed using staf
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to obtain the net-dvs info for $dvsName" .
                       $result->{rc});
   }

   my @tempArray = split(/\n/, $result->{stdout});

   my $client = undef;

   my $portHash;
   my $name = undef;
   foreach my $line (@tempArray) {
      $line =~ s/^\s+|\s+$//g; # remove any spaces before and after stats name
      if ($line =~ /^Name: (.*)/i) {
         if ($1 eq $dvsName) {
            $name = $1;
         } else {
            $name = undef;
         }
      }
      if (not defined $name) {
         next;
      }
      if ($line =~ /Client: (.*)/i) {
         $client = $1;
         next;
      } elsif ($line =~ /Client:$/i) {
         $client = undef;
      }
      if (not defined $client) {
         next;
      }
      if ($line =~ /:/) {
         my ($key, $value) = split(/:/, $line);
         $key =~ s/^\s+|\s+$//g; # remove any spaces before and after stats name
         $value =~ s/^\s+|\s+$//g; # remove any spaces before and after value
         $portHash->{$client}{$key} = $value;
      }
   }

   if (not defined $portHash) {
      $vdLogger->Error("Failed to get the ports information of dvsName " .
                       "available on the host $self->{hostIP}");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   return $portHash;
}


########################################################################
#
# GetActiveDVUplinkPort --
#      Method to get the vmnic name on a host from the given dvUplink
#      port name. This is opposite to GetDVUplinkNameOfVMNic()
#
# Input:
#      dvsName : name of the dvswitch (Required)
#      dvUplinkName: name of the dvUplink port from which the vmnic
#                    name on the host need to be found (Required)
#
# Results:
#      vmnic name (scalar string), if successful;
#      FAILURE, in case of any error
#
# Side effects:
#      None
#
########################################################################

sub GetActiveDVUplinkPort
{
   my $self = shift;
   my $dvsName = shift;
   my $dvUplinkName = shift;

   my $dvsInfo = $self->GetDVSInfo($dvsName);

   if ($dvsInfo eq FAILURE) {
      $vdLogger->Error("Failed to get information about $dvsName");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #
   # Find the port id corresponding to the given dvUplink name.
   #
   my $portID;
   foreach my $dvport (keys %$dvsInfo) {
      my $alias = $dvsInfo->{$dvport}{'com.vmware.common.port.alias'};
      if (defined $alias) {
         my ($uplink, $type) = split(/,/,$alias);
         $uplink =~ s/^\s|\s$//g;
         if ($uplink eq $dvUplinkName) {
            $portID = $dvport;
            last;
         }
      }
   }

   if (not defined $portID) {
      $vdLogger->Error("Failed to get the port id of $dvUplinkName " .
                       " on $dvsName");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $vdLogger->Info("Port ID: $portID");

   #
   # The active client on the dvs (seen on the host) whose portid
   # matches the id obtained above is the client/vmnic corresponding to the
   # given dvUplink.
   #
   my $activePorts = $self->GetActiveDVPorts($dvsName);

   foreach my $client (keys %$activePorts) {
      if ($activePorts->{$client}{'Port ID'} eq $portID) {
         return $client;
      }
   }
   return FAILURE;
}


########################################################################
#
# GetDVUplinkNameOfVMNic --
#      Method to get the dvuplink port name to which a vmnic is
#      connected.
#
# Input:
#      dvsName : name of the dv switch (Required)
#      vmnic   : name of the vmnic, example vmnic1, vmcni2 etc.
#                (Required)
#
# Results:
#      dvUplink port name (scalar string) to which the given vmnic is
#      connected on the given dv switch, if successful;
#      FAILURE, in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetDVUplinkNameOfVMNic
{
   my $self    = shift;
   my $dvsName = shift;
   my $vmnic   = shift;

   if ((not defined $dvsName) || (not defined $vmnic)) {
      $vdLogger->Error("GetDVUplinkNameFromVMNic: dvsName and/or vmnic " .
                       "not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # Get the list of ports on the given dv switch.
   # This list will include both vmnic uplinks and VM clients.
   #
   my $activePorts = $self->GetActiveDVPorts($dvsName);

   if ($activePorts eq FAILURE) {
      $vdLogger->Error("GetDVUplinkNameFromVMNic: Failed to get active ports " .
                       " on $dvsName");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Debug("Active ports on $dvsName: $activePorts");

   my $portID = $activePorts->{$vmnic}{'Port ID'};

   if (not defined $portID) {
      $vdLogger->Error("GetDVUplinkNameFromVMNic: Failed to get port id " .
                       " of $vmnic on $dvsName");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $vdLogger->Debug("Port id of $vmnic on $dvsName: $portID");
   my $dvsInfo = $self->GetDVSInfo($dvsName);

   if ($dvsInfo eq FAILURE) {
      $vdLogger->Error("Failed to get dvs info for $dvsName on " .
                       $self->{hostIP});
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $dvUplink = $dvsInfo->{$portID}{'com.vmware.common.port.alias'};
   my $type;
   ($dvUplink, $type) = split(/,/,$dvUplink);
   $dvUplink =~ s/^\s|\s$//g;

   if (not defined $dvUplink) {
      $vdLogger->Error("dvuplink name not defined for $vmnic on ".
                       $self->{hostIP});
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   return $dvUplink;
}


#########################################################################
#
#  GetVmknicList --
#      Given the host info this method returns the vmknics present in the
#      host
#
# Input:
#      Hostname like 'prme-vmkqa-XX.eng.vmware.com'
#
# Results:
#      Returns the vmknics present in the host as a array reference to Hash,
#       sample output.
#$VAR1 = {
#          'MAC Address' => 'f0:4d:a2:40:79:15',
#          'VDS Name' => 'N/A',
#          'Portset' => 'vSwitch0',
#          'Enabled' => 'true',
#          'TSO MSS' => '65535',
#          'VDS Port' => 'N/A',
#          'MTU' => '1500',
#          'VDS Connection' => '-1',
#          'Port ID' => '16777219',
#          'Name' => 'vmk0',
#          'Portgroup' => 'Management Network'
#        };
#$VAR2 = {
#          'MAC Address' => '00:50:56:79:59:8e',
#          'VDS Name' => 'N/A',
#          'Portset' => 'vss-0-355',
#          'Enabled' => 'true',
#          'TSO MSS' => '65535',
#          'VDS Port' => 'N/A',
#          'MTU' => '1500',
#          'VDS Connection' => '-1',
#          'Port ID' => '50332005',
#          'Name' => 'vmk1',
#          'Portgroup' => 'vmk1-pg-6355'
#        };
#      if there was no error executing the command.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub GetVmknicList
{

   my $self   = shift;
   my $host   = $self->{hostIP};
   my $command;

   $command = "/sbin/esxcli network ip interface list";
   my $result = $self->{stafHelper}->STAFSyncProcess($host,$command);

   # check for failure of the command
   if ($result->{rc} != 0) {
       $vdLogger->Error("command not executed Successfully");
      $vdLogger->Debug("The result is :Dumper($result)");
       return FAILURE;
     }

   if ($result->{stdout} eq ""){
      $vdLogger->Error("Command did not return any result:$command");
      VDSetLastError("EINVALID");
      return FAILURE;
    }
   #Processing the result output.And storing the
   # result in Array of hashes
   my @vmknicArray;
   my @newArray;
   my @vmkList;
   my @rec= {};
   my $vmknicListResult;
   my $key= undef;
   my $value= undef;

   @vmknicArray=split('\\n\\n',$result->{stdout});
   my  $j=0;
   foreach my $vmknicListResult (@vmknicArray){
        $vmknicListResult=~ s/^vmk\d//g;
        @newArray =split('\\n',$vmknicListResult);
        foreach my $item (@newArray){
             ($key,$value)=split(/:\s/,$item);
             if (not defined $key) {
              next;
             } else {
                $key =~ s/^\s+|\s$//g;
                $value =~ s/^\s+|\s$//g;
                $rec[$j]->{$key}=$value;
              }
         }#end of foreach of @newarray
          push(@vmkList,$rec[$j]);
          $j++;
      }#end of foreach of @vmknicArray
     return \@vmkList;
}


########################################################################
#
# DisconnectSTAFAnchor--
#      Method to disconnect the staf anchor used for
#      STAF SDK HOST services on the given host.
#
# Input:
#      None
#
# Results:
#      SUCCESS, if staf anchor is disconnected successfully;
#      FAILURE, in case of any error;
#      Also, the class attribute 'stafHostAnchor' will be set to undef;
#
# Side effects:
#      Any operation relying on 'stafHostAnchor' attribute will not
#      work. This method should be called as part of cleanup.
#
########################################################################

sub DisconnectSTAFAnchor
{
   my $self = shift;

   if (not defined $self->{stafHostAnchor}) {
      return SUCCESS; # if anchor not defined, then nothing to do
   }

   $vdLogger->Debug("Disconnect host $self->{hostIP} STAF anchor");
   my $command = "DISCONNECT ANCHOR $self->{stafHostAnchor} ".
                 "HOST $self->{hostIP}";

   my $result = $self->{stafHelper}->STAFSubmitHostCommand("local",
                                                           $command);
   if ($result->{rc} != 0) {
      $vdLogger->Debug("Failed to disconnect host STAF anchor".
                       " of $self->{hostIP}");
      $vdLogger->Debug(Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $self->{stafHostAnchor} = undef;
   return SUCCESS;
}

########################################################################
#
# CheckAndInstallVDL2--
#     Method to check if VDL2 module is loaded, else install it. installing
#     VDL2 involves STAF.
#
# Input:
#     None
#
# Results:
#     SUCCESS, if VDL2 is installed successfully;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub CheckAndInstallVDL2
{
   my $self = shift;
   my $vmk_command;
   my $result;
   #
   # Check if vdl2 module is installed
   #
   $vmk_command = 'vmkload_mod -l | grep vdl2';
   $vdLogger->Debug(" Look for vdl2 module : vmk_command = $vmk_command");
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $vmk_command);
   if ( ($result->{rc} != 0) or ($result->{exitCode} != 0) ) {

      #load vdl2 moudle
      $vdLogger->Info("Loading vdl2 module on $self->{hostIP}");
      if (FAILURE eq $self->LoadVDL2Module()) {
         $vdLogger->Error("Failed to load vdl2 module on $self->{hostIP}");
	 VDSetLastError(VDGetLastError());
	 return FAILURE;
      }
   } else {
      $vdLogger->Debug("VDL2 moudle is loaded on $self->{hostIP}");
   }
}

########################################################################
#
# LoadVDL2Module--
#     Method to install VDL2 module.
#
# Input:
#     None
#
# Results:
#     SUCCESS, VDL2 is installed successfully;
#     FAILURE, in case of any error
#
# Side effects:
#     None.
#
########################################################################

sub LoadVDL2Module
{
   my $self    = shift;
   my $esxBuild;
   my $esxVersion;
   my $vxlanVIB ;
   my $buildInfo;
   my $url;

   $esxBuild = $self->{build};
   $esxVersion = $self->{version}.'.0';
   $vxlanVIB = "/var/tmp/VMware-ESXi-$esxVersion-$esxBuild-vsip.zip";
   $vdLogger->Debug("esxBuild is $esxBuild, esxVersion is $esxVersion");
   #get sandbox buildinfo
   my $command = 'grep /build/mts/release /etc/vmware/esx.conf';
   my $result  = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);

   # Here in order to improve the tolerance of LoadVDL2Module, we change the
   # condition from "($result->{rc} != 0) or ($result->{exitCode} != 0)" to
   # "($result->{rc} != 0) && ($result->{exitCode} != 0)" in that case the failure
   # will happen when both of them fail.
   # The return value of the command is always changed because the VDL2 module is in
   # the sandbox or not in the sandbox.
   # We'll process the return result of the command by the following 'else'.
   # The PR is 1146295.
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Cannot get build number of sandbox in $self->{hostIP}" .
                       Dumper($result));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   } else {
      $_ = $result->{stdout};
      if (m#(\d{6,})#) {
	 $esxBuild  = $1;
	 $buildInfo = VDNetLib::Common::FindBuildInfo::getSandboxBuildInfo($esxBuild);
	 $vdLogger->Debug("buildInfo is $buildInfo,esxBuild is $esxBuild");
      } else {
	 # get offical buildinfo
	 $buildInfo = VDNetLib::Common::FindBuildInfo::getOfficialBuildInfo($esxBuild);
      }
   }

   if ($buildInfo->{'_buildtree_url'} eq "") {
      $vdLogger->Debug("Couldn't get buildtree info" . Dumper($buildInfo));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $url =  $buildInfo->{'_buildtree_url'} .
             "/publish/comp/VMware-ESXi-$esxVersion-$esxBuild-vsip.zip";

   $vdLogger->Info("Downloading VXLAN VIB Module from $url to $self->{hostIP}");

   # wget file
   my $cmd = "rm -f /var/tmp/*vsip.zip";
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $cmd);
   $vdLogger->Debug("Deleting existing vib files on $self->{hostIP}:" .
                   " command = $cmd");
   if (($result->{rc} != 0) or ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to delete vdl2.vib file on $self->{hostIP}" .
                        Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $cmd = "wget -P /var/tmp $url";
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $cmd);
   $vdLogger->Debug("Download VXLAN VIB Module to $self->{hostIP}:" .
                   " command = $cmd");
   if ( ($result->{rc} != 0) or ($result->{exitCode} != 0) ) {
      $vdLogger->Error("Failed to download vdl2.vib file to $self->{hostIP}" .
                        Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # install VDL2 module
   $vxlanVIB = "/var/tmp/VMware-ESXi-$esxVersion-$esxBuild-vsip.zip";
   $cmd = "esxcli software vib install -d $vxlanVIB";
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $cmd);
   $vdLogger->Debug("Install VXLAN VIB Module : command = $cmd");
   if ( ($result->{rc} != 0) or ($result->{exitCode} != 0) ) {
      $vdLogger->Error("Failed to install vdl2.vib file to $self->{hostIP}" .
                        Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# ConfigureFirewall--
#     Method to configure firewall on the given host
#
# Input:
#     sshSession : reference to VDNetLib::Common::SshHost object (Required)
#     action  : enable/disable (Optional, default is enable)
#     ruleset : firewall rules (Optional) #TODO: fix this
#
# Results:
#     SUCCESS, if firewall is configured correctly;
#     FAILURE, in case of any error;
#
# Side effects:
#     May impact access to the host completely or specific ports
#
########################################################################

sub ConfigureFirewall
{
   my $self    = shift;
   my $sshHost = shift;
   my $action  = shift;
   my $ruleset = shift;
   my $output;
   my $firewallCmd = CMD_NEW_STOP_VISOR_FIREWALL;

   if ((not defined $sshHost) || (not defined $action)) {
      $vdLogger->Error("SshHost object and/or action not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $rcStaf = 0;
   my $rcRP = 0;
   my $rcLocal = "";

   my $dstFile = ESXSTAFFIREWALLVIB;
   my $vibFile = STAFFIREWALLVIBSRC;
   my ($rc, $out) = $sshHost->ScpToCommand($vibFile, $dstFile);
   if ($rc ne "0") {
      $vdLogger->Error("Failed to copy stafFirewall.vib file " .
                       " to $self->{hostIP}");
      $vdLogger->Debug("ERROR:$rc " . Dumper($out));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   #
   # New vib installation policy with --no-sig-check option
   # PR http://bugzilla.eng.vmware.com/show_bug.cgi?id=1197025#c6
   #
   my $cmd = "esxcli software acceptance set --level=CommunitySupported";
   my $counter = 0;
   my $retry = 10;
   while (1) {
      $vdLogger->Debug("Sleep 20 seconds before set the acceptance level");
      sleep(5);
      ($rc, $out) = $sshHost->SshCommand($cmd);
      if ($rc ne "0") {
         $vdLogger->Warn("Failed to set software acceptance level " .
                       " to $self->{hostIP}");
         $vdLogger->Debug("Return code = $rc " . Dumper($out));
      } else {
         last;
      }
      $counter++;
      if ($counter >= $retry) {
           $vdLogger->Error("Failed $retry times to set acceptance level.");
           VDSetLastError("EOPFAILED");
           return FAILURE;
      }
   }
   $cmd = "esxcli software vib install -f --no-sig-check -v $dstFile";
   ($rc, $out) = $sshHost->SshCommand($cmd);
   if ($rc ne "0") {
      $vdLogger->Error("Failed to install stafFirewall.vib file " .
                       " to $self->{hostIP}");
      $vdLogger->Debug("Command \"$cmd\" returns ERROR:$rc " . Dumper($out));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $cmd = "esxcli network firewall refresh";
   ($rc, $out) = $sshHost->SshCommand($cmd);
   if ($rc ne "0") {
      $vdLogger->Error("Failed to refresh firewall on $self->{hostIP}");
      $vdLogger->Debug("ERROR:$rc " . Dumper($out));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   #
   # TODO: Do not disable firewall completely, instead to configure rules based
   # on vdnet requirements PR687626
   #

   if ($action =~ /disable/i) {
      $firewallCmd = CMD_NEW_STOP_VISOR_FIREWALL;
   }

   ($rc, $out) = $sshHost->SshCommand($firewallCmd);
   $vdLogger->Debug("Ran command: $firewallCmd, RC: $rc, output: @$out");

   ($rc, $out) = $sshHost->SshCommand(CMD_GET_FIREWALL);
   if ($out =~ /Enabled: $action/i) {
      $vdLogger->Debug("Mismatch in firewall configuration: $firewallCmd, " .
                       "RC: $rc, output: @$out");
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# ConfigureServiceSystemAnchor--
#     Method to configure given host service (example: tsm-ssh)
#
# Input:
#     serviceName: tsm-ssh/dcui/tsm/lbtd/lsassd/lwiod/ntpd/vmware-fdm/
#                  vpxa (Required)
#     action     : start/stop (Required)
#
# Results:
#     SUCCESS, if the service is configured successfully;
#     FAILURE, in case of any error
#
# Side effects:
#     refer to the documentation on host services
#
########################################################################

sub ConfigureServiceSystemAnchor
{
   my $self = shift;
   my $serviceName = shift;
   my $action = shift;

   my $temp = "_service";
   $action .= $temp;
   my $pyObj = $self->GetInlinePyObject();
   my $result = CallMethodWithKWArgs($pyObj, $action, {'key' => $serviceName});
   if(defined $result and $result eq FAILURE){
      $vdLogger->Error("Could not $action $serviceName on host: $self->{hostIP}");
      return FAILURE;
   }
   $vdLogger->Info("Success: $action $serviceName on host: $self->{hostIP}");
   return SUCCESS;
}


################################################################################
#  StartDHCPProcess
#      Starts the vmnet dhcp process relevant any of the bridges, namely
#      vmnet1, vmnet8 and so on....
#
#  Input:
#      vmnet name for eg: vmnet8 or vmnet1 etc, that needs to be started.
#
#
#  Output:
#       1 if pass
#       0 if fail
#
#  Side effects:
#       none
#
################################################################################

sub StartDHCPProcess()
{
   my $self = shift;
   my $processName = shift;
   my @result;
   if(not defined $processName) {
      $vdLogger->Error("Process name to be started, not defined");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # Checking if STAF is running on the host. Staf is used to send hot add command
   if ( $self->{stafHelper}->CheckSTAF( $self->{_justHostIP} ) eq FAILURE ) {
      $vdLogger->Error("STAF is not running on $self->{_justHostIP} \n");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $vdLogger->Info("Starting the DHCP process for $processName");
   my ($globalConfigObj);
   $globalConfigObj = new VDNetLib::Common::GlobalConfig;
   my $binPath = $globalConfigObj->VmwareLibPath(VDNetLib::Common::GlobalConfig::OS_MAC);
   my $binary = $binPath."vmnet-dhcpd";
   my $vmNetworkPath = FUSION_DEFAULT_NETWORKING_PATH.$processName."/dhcpd.conf";

   my $wincmd = STAF::WrapData("$binary -cf $vmNetworkPath -lf /var/db/vmware/vmnet-dhcpd-$processName-leases.pf".
               "/var/run/vmnet-dhcpd-$processName.pid $processName");
   my $command ="start shell command $wincmd " .
             " wait returnstdout stderrtostdout";

   my $service = "process";
   (my $result, my $data) =
   $self->{stafHelper}->runStafCmd( $self->{_justHostIP}, $service, $command );
   if($result eq FAILURE) {
      $vdLogger->Error("Error processing STAF command");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   if( $data =~ m/There is already a DHCP server running/i ) {
      $vdLogger->Error("First kill the running DHCP server");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
#  KillVMProcess
#      Returns the list of VMs that are powered ON.
#
#  Input:
#      The name of the process with which it'll be searched for in the ouput of
#      ps aux. For example ps aux | grep <process name>
#
#
#  Output:
#       1 if pass
#       0 if fail
#
#  Side effects:
#       none
#
################################################################################

sub KillVMProcess()
{
   my $self = shift;
   my $processName = shift;
   my @result;
   if(not defined $processName) {
      $vdLogger->Info("Process grep string not defined");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # $self->{stafHelper} = new VDNetLib::Common::STAFHelper();
   # Checking if STAF is running on the host.
   if ( $self->{stafHelper}->CheckSTAF( $self->{_justHostIP} ) eq FAILURE ) {
      $vdLogger->Error("STAF is not running on $self->{_justHostIP} \n");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Not specifying the user here , assuming we would need to kill all the
   # vmnet processes irrespective of the user.
   my $wincmd = STAF::WrapData("ps aux | grep $processName");
   my $command ="start shell command $wincmd " .
             " wait returnstdout stderrtostdout";

   my $service = "process";
   (my $result, my $data) =
   $self->{stafHelper}->runStafCmd( $self->{_justHostIP}, $service, $command );
   if($result eq FAILURE) {
      $vdLogger->Error("Error processing STAF command");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   } else {
      @result = split(/\n/, $data);
   }

   my $count = 0;
   while($count<@result) {
      my @subArray = split(" ", $result[$count]);
      if($subArray[1] =~ /\d*/) {
         $subArray[1] =~ s/^\s+//;
         $subArray[1] =~ s/\s+$//;
         $vdLogger->Info("About to kill process $subArray[1] ...");
         $wincmd = STAF::WrapData("kill $subArray[1]");
         $command ="start shell command $wincmd " .
                   " wait returnstdout stderrtostdout";

         $service = "process";
         ($result, $data) =
         $self->{stafHelper}->runStafCmd( $self->{_justHostIP}, $service, $command );
         if($result eq FAILURE) {
            $vdLogger->Error("Error processing STAF command");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }

         my @checkResult;
         $wincmd = STAF::WrapData("ps -p $subArray[1]");
         $command ="start shell command $wincmd " .
                   " wait returnstdout stderrtostdout";
         $service = "process";
         ($result, $data) =
         $self->{stafHelper}->runStafCmd( $self->{_justHostIP}, $service, $command );
         if($result eq FAILURE) {
            $vdLogger->Error("Error processing STAF command");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         } else {
            @checkResult = split(/\n/, $data);
         }

         # The first line returned by the ps -p <process-id> looks like below:
         # PID TTY           TIME CMD
         if(@checkResult>1) {
            $vdLogger->Error("Could not kill the process with the process id".
                             "$subArray[1]");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
         $count ++;
      } else {
         $count++;
      }
   }
   return SUCCESS;
}


################################################################################
#  ChangeNetworkServiceOrder
#      Returns the list of VMs that are powered ON.
#
#  Input:
#     ServiceName that needs to be dragged to the top.
#
#
#  Output:
#       1 if pass
#       0 if fail
#
#  Side effects:
#       none
#
################################################################################

sub ChangeNetworkServiceOrder()
{
   my $self = shift;
   my $networkName = shift;
   if (not defined $networkName) {
      $vdLogger->Error("Network Name not specified");
      VDSetLastError("EOPFAILED");
      return FAILURE
   }

   # $self->{stafHelper} = new VDNetLib::Common::STAFHelper();
   # Checking if STAF is running on the host.
   if ( $self->{stafHelper}->CheckSTAF( $self->{_justHostIP} ) eq FAILURE ) {
      $vdLogger->Error("STAF is not running on $self->{_justHostIP} \n");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $wincmd = STAF::WrapData("networksetup -listnetworkserviceorder");
   my $command ="start shell command $wincmd " .
             " wait returnstdout stderrtostdout";

   my @result;
   my $service = "process";
   (my $result, my $data) =
   $self->{stafHelper}->runStafCmd( $self->{_justHostIP}, $service, $command );
   if($result eq FAILURE) {
      $vdLogger->Error("Error processing STAF command");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   } else {
      @result = split(/\n/, $data);
   }

   my @networkNameArray = ();
   my $count = 1;
   my $networkNameActual;
   my $indexOfNetworkName;
   while($count<@result) {
      if($result[$count] =~ /\((.*)\)/) {
         my @subArray = split(/\((.*)\)/, $result[$count]);
         if(@subArray>1) {
            $subArray[@subArray -1] =~ s/^\s+//;
            $subArray[@subArray -1] =~ s/\s+$//;
            push(@networkNameArray, $subArray[@subArray -1]);
            if($networkName =~ $subArray[@subArray -1]) {
               $networkNameActual = "\"".$subArray[@subArray - 1]."\"";
               $indexOfNetworkName = @networkNameArray - 1;
            }
         }
         $count = $count + 3;
      } else {
         $count = $count + 3;
      }
   }
   $count = 0;
   while($count < @networkNameArray) {
      if($count eq $indexOfNetworkName) {
         $count++;
         next;
      }
      $networkNameActual = $networkNameActual." "."\"".$networkNameArray[$count]."\"";
      $count++;
   }

   $wincmd = STAF::WrapData("networksetup -ordernetworkservices $networkNameActual");
   $command ="start shell command $wincmd " .
             " wait returnstdout stderrtostdout";

   $service = "process";
   ($result, $data) =
   $self->{stafHelper}->runStafCmd( $self->{_justHostIP}, $service, $command );
   if($result eq FAILURE) {
      $vdLogger->Error("Error processing STAF command");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   if(!($data eq "")) {
      $vdLogger->Error("Error occured while changing the service order");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
#  VMOpsEnablePortForwarding
#      makes the appropriate entry in the nat.conf file in order to enable
#      port forwarding for VMs having NIC in the NAT mode.
#
#  Input:
#      Adapter type: bridged, hostonly, nat (any 1 required)
#
#
#  Output:
#       1 if pass along with MAC address of vNIC hot added
#       0 if fail
#
#  Side effects:
#       none
#
################################################################################

#TODO: This method will be added to HostOperations.pm
sub VMOpsEnablePortForwarding()
{
   my $self = shift;
   my ($trafficType, $hostPort ,$vmIP, $vmPort) = @_;
   my $arg;
   my $ret;
   my @contents;

   if (not defined $trafficType) {
      $vdLogger->Error("Specify whether the traffic type is tcp or udp");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if (not defined $hostPort) {
      $vdLogger->Error("Host Port not supplied");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if (not defined $vmIP) {
      $vdLogger->Error("VM IP not supplied");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # $self->{stafHelper} = new VDNetLib::Common::STAFHelper();
   # Checking if STAF is running on the host. Staf is used to send hot add command
   if ( $self->{stafHelper}->CheckSTAF( $self->{_justHostIP} ) eq FAILURE ) {
      print STDERR "STAF is not running on $self->{_justHostIP} \n";
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $natConf = "\\\"".FUSION_DEFAULT_NETWORKING_PATH."vmnet8/nat.conf"."\\\"";
   my $command = "start shell command \"grep -i \\\"$hostPort = \\\" \\\"$natConf\\\"\"
      wait returnstdout stderrtostdout";
   my $service = "process";
   ($ret,my $data ) = $self->{stafHelper}->runStafCmd( $self->{_justHostIP}, $service, $command );
   if ( $ret eq FAILURE ) {
      $vdLogger->Error("Error with staf $command \n");
      VDSetLastError("ESTAF");
      return FAILURE;
   } else {
      @contents = split( /\n/, $data );
   }

   if((@contents > 0) && !($contents[0] =~ m/No|such|file|ordirectory/i)) {
      $vdLogger->Error("Port entry already exists");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $trafficTypeString = ($trafficType =~ m/tcp/i) ? "[incomingtcp]": "[incomingudp]";
   $arg = (defined $vmPort) ? ("$natConf"."\*"."'modify'"."\*"."\\\""."$trafficTypeString"."\n"."$hostPort = $vmIP:$vmPort"."\\\""."\*".$trafficTypeString."\*")
                            : ("$natConf"."\*"."'modify'"."\*"."\\\""."$trafficTypeString"."\n"."$hostPort = $vmIP"."\\\""."\*".$trafficTypeString."\*");

   $ret = VDNetLib::Common::Utilities::ExecuteMethod($self->{_justHostIP}, "EditFile", $arg);
   if($ret eq FAILURE) {
      $vdLogger->Error("Error enabling port forwarding");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
#
# CheckHealthcheckModule
#   Checks whether the host supports the healthcheck framework
#
# Input:
#   None
#
# Results:
#   SUCCESS, if the healthcheck framework is supported
#   FAILURE, in case of any error / if the framework is not supported
#
# Side effects:
#   none
#
################################################################################

sub CheckHealthcheckModule ()
{
   my $self = shift;

   # Creating command to check whether healthcheck module has been loaded
   my $command = "vmkload_mod -l | grep -i healthchk";

   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Unable to retrieve healthcheck module status");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   if (defined $result->{stdout}) {
      if ($result->{stdout} !~ m/healthchk/i) {
         $vdLogger->Error("$result->{stdout}: Healthcheck module not loaded");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }

   # Creating command to check whether CBEventsSummary can be retrieved
   $command = "vsish -pe get /vmkModules/healthchk/CBEventsSummary";

   # Submit STAF command
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Unable to retrieve healthcheck=>CBEventsSummary".
                       " module status");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   if (defined $result->{stdout}) {
      if ($result->{stdout} !~ m/ackedEvents/i) {
         $vdLogger->Error("$result->{stdout}: CBEventsSummary not retrieved");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }

   # Creating command to check whether totalTicketsSummary can be retrieved
   $command = "vsish -pe get /vmkModules/healthchk/totalTicketsSummary";

   # Submit STAF command
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Unable to retrieve healthcheck=>totalTicketsSummary".
                       " module status");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   if (defined $result->{stdout}) {
      if ($result->{stdout} !~ m/timeoutSeqs/i) {
         $vdLogger->Error("$result->{stdout}: totalTicketsSummary not retrieved");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }

   $vdLogger->Info("Healthcheck module is loaded");
   return SUCCESS;
}


################################################################################
#
# GetHealthCheckInfo
#   Gets the teamcheck / VLANMTUcheck / VLANMTUUplink information, as passed by
#   user
#
# Input:
#   SwName  : Name of the DVS
#   Param   : Param to be retrieved. Acceptable values are:
#             TEAM - teamcheck
#             VLANMTU - VLANMTUcheck
#             VLANMTUUPLINK - VLANMTUUplink
#
# Results:
#   Information hash, on success
#   FAILURE, in case of any error / if the teamcheck could not be retrieved
#
# Side effects:
#   none
#
################################################################################

sub GetHealthCheckInfo
{
   my $self = shift;
   my $swName = shift;
   my $param = shift;

   if (not defined $swName) {
      $vdLogger->Error("Parameter Switch name not passed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (($param !~ /TEAM/) && ($param !~ /VLANMTU/) && ($param !~ /VLANMTUUPLINK/)) {
      $vdLogger->Error("Parameter name not passed correctly");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   # Retrieving portset name of DVS
   my $portSet = $self->GetPortSetNamefromDVS($swName);
   if ($portSet eq FAILURE) {
      $vdLogger->Error("Failed to retrieve portset name of DVS $swName");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Creating command as per user input
   my $command = undef;
   if ($param =~ /TEAM/) {
      $command = "vsish -pe get /vmkModules/teamcheck/requests/".$portSet."/info";
   } elsif ($param =~ /VLANMTUUPLINK/) {
      $command = "vsish -pe ls /vmkModules/vlanmtucheck/portsetReqs/".
                 $portSet."/uplinks/";
   } elsif ($param =~ /VLANMTU/) {
      $command = "vsish -e ls /vmkModules/vlanmtucheck/portsetReqs/";
   }

   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to run command \"$command\" on host $self->{hostIP}");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Parsing vsish output into a hash
   $result->{stdout} = VDNetLib::Common::Utilities::ProcessVSISHOutput
                       (RESULT => $result->{stdout});
   if ($result->{stdout} eq FAILURE) {
      $vdLogger->Error("Unable to parse vsish output");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return $result->{stdout};
}


################################################################################
#
# GetVLANMTUUplinkInfo
#   Gets the VLANMTU uplink information
#
# Input:
#   SwName  : Name of the DVS
#   Uplink  : Name of the uplink
#
# Results:
#   Information hash, on success
#   FAILURE, in case of any error / if the VLANMTU uplink info could not be
#            retrieved
#
# Side effects:
#   none
#
################################################################################

sub GetVLANMTUUplinkInfo
{
   my $self = shift;
   my $swName = shift;
   my $uplink = shift;

   if ((not defined $swName) || (not defined $uplink)) {
      $vdLogger->Error("Parameter Switch name / uplink not passed ".
                       "correctly");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Retrieving portset name of DVS
   my $portSet = $self->GetPortSetNamefromDVS($swName);
   if ($portSet eq FAILURE) {
      $vdLogger->Error("Failed to retrieve port set name of DVS $swName");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Creating command to retrieve VLANMTU uplink info
   my $command = "vsish -e get /vmkModules/vlanmtucheck/portsetReqs/".$portSet.
                 "/uplinks/".$uplink."/info";

   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   if ($result->{rc} != 0
    || $result->{exitCode} != 0
    || $result->{stdout} !~ /vlan/i) {
      $vdLogger->Error("Failed to retrieve VLANMTU check uplink info on host ".
                       "$self->{hostIP} command $command" . Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   return $result->{stdout};
}


################################################################################
#
# ConfigureHealthcheck
#   Set the VLAN MTU or Teaming values used in Healthcheck feature
#
# Input:
#   args  : Reference to below parameters
#   healthcheck_type : vlanmtu or teaming
#
# Results:
#   SUCCESS, if the action is successful
#   FAILURE, in case of any error
#
# Side effects:
#   none
#
################################################################################

sub ConfigureHealthcheck
{
   my $self = shift;
   my $args = shift;

   my $healthcheck_type = $args->{healthcheck_type};
   if (not defined $healthcheck_type) {
      $vdLogger->Error("Healthcheck type not specified.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ($healthcheck_type =~ /teaming/i ) {
      $vdLogger->Error("Configure teaming on ESXi is not supported");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }

   return $self->ConfigureHealthcheckVLANMTU($args);
}


################################################################################
#
# ConfigureHealthcheckVLANMTU
#   Set the VLAN MTU values used for VLAN MTU Check in Healthcheck feature
#
# Input:
#   args  : Reference to below parameters
#   trunked_vlans: Values are numeric and are accepted as "10,20-50,100", etc.
#            Hence, user has to enter the value as  "10_20to50_100"
#   SwObj : dvSwitch object to be checked
#
# Results:
#   SUCCESS, if the action is successful
#   FAILURE, in case of any error
#
# Side effects:
#   none
#
################################################################################

sub ConfigureHealthcheckVLANMTU
{
   my $self = shift;
   my $args = shift;

   my $trunked_vlans = $args->{trunked_vlans};
   my $swObj = $args->{switch};
   if (not defined $swObj) {
      $vdLogger->Error("Parameter Switch is not specified.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $swName = $swObj->{name};
   if ((not defined $swName) ||
       (not defined $trunked_vlans)) {
      $vdLogger->Error("Parameter Switch name / trunked_vlans not passed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Parsing the parameter for values passed
   $trunked_vlans =~ s/\_/\,/g;
   $trunked_vlans =~ s/to/\-/g;

   # Checking whether values are in correct format
   my @contents = split (/,/,$trunked_vlans);
   foreach my $value (@contents) {
      if ($value !~ m/(\d+)-(\d+)/) {
         if ($value !~ m/(\d+)/) {
            $vdLogger->Error("Error in entering VLAN values in test hash");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }
   }

   # Creating command to set the VLANMTU check param value
   my $command = NETDVSPATH . "net-dvs --vlanMTUChkParam \"$trunked_vlans\" $swName";

   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   if ($result->{rc} != 0
    || $result->{exitCode} != 0
    || $result->{stdout} !~ /set/i) {
      $vdLogger->Error("Failed to set VLANMTU check param value on host ".
                       "$self->{hostIP}");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
#
# CheckLocalMTUMatch
#   Changes the local MTU match between server and VDS configuration
#
# Input:
#   args    : Reference to below parameters
#   Action  : "MATCH" / "MISMATCH" to be checked
#   SwObj   : dvSwitch object to be checked
#   VmnicObjsRef   : Reference to vmnic object array to be checked, but
#                    only one object is allowed.
#
# Results:
#   SUCCESS, if the match parameter matches with the action specified
#   FAILURE, in case of any error
#
# Side effects:
#   none
#
################################################################################

sub CheckLocalMTUMatch
{
   my $self = shift;
   my $args = shift;
   my $action = $args->{expected_match_result};
   my $swObj = $args->{switch};
   my $vmnicObjsRef = $args->{vmnicadapter};

   if ((not defined $swObj) ||
       (not defined $vmnicObjsRef)) {
      $vdLogger->Error("Parameter switch / vmnic not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $swName = $swObj->{name};
   my $vmnic = $vmnicObjsRef->[0]->{interface};

   if ((not defined $action) ||
       (not defined $swName) ||
       (not defined $vmnic)) {
      $vdLogger->Error("Parameter Switch name / action / vmnic not passed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $count = 0;
   while ($count < 6) {
      $count++;
      # Retrieving value of uplink info
      my $result = $self->GetVLANMTUUplinkInfo($swName, $vmnic);

      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to set VLANMTU Uplink info");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      # Checking whether retrieved result matches with intended result (action)
      if ($action eq "MATCH") {
         if ($result =~ /MTUMATCHEVENT/i) {
            $vdLogger->Info("MTU local match successful as intended");
            return SUCCESS;
         } else {
            $vdLogger->Error("MTU is a match locally, not as intended");
            if ($count < 6) {
               $vdLogger->Info("Sleeping for 5 seconds to try again");
               sleep 5;
               next;
            }
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      } elsif ($action eq "MISMATCH") {
         if ($result =~ /MTUMISMATCHEVENT/i) {
            $vdLogger->Info("MTU local mismatch successful, as intended");
            return SUCCESS;
         } else {
            $vdLogger->Error("MTU is a mismatch locally, not as intended");
            if ($count < 6) {
               $vdLogger->Info("Sleeping for 5 seconds to try again");
               sleep 5;
               next;
            }
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      } else {
         $vdLogger->Error("Value of action passed incorrect");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   }
}


################################################################################
#
# CheckTeamingMatch
#   Checks the teaming match between servers based on requried action
#
# Input:
#   args    : Reference to below parameters
#   Action  : "MATCH" / "MISMATCH" to be checked
#   SwObj   : dvSwitch object to be checked
#
# Results:
#   SUCCESS, if the match parameter matches with the action specified
#   FAILURE, in case of any error
#
# Side effects:
#   none
#
################################################################################

sub CheckTeamingMatch
{
   my $self = shift;
   my $args = shift;
   my $action = $args->{expected_match_result};
   my $swObj   = $args->{switch};

   if (not defined $swObj) {
      $vdLogger->Error("Parameter switch object not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $swName   = $swObj->{name};

   if ((not defined $action) ||
       (not defined $swName)) {
      $vdLogger->Error("Parameter Switch name / action not passed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $count = 0;
   while ($count < 2) {
      $count++;
      # Retrieving teamcheck info
      my $result = $self->GetHealthCheckInfo($swName,"TEAM");

      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to get teamcheck info");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      # Checking whether retrieved result matches with intended result (action)
      if ($action eq "MATCH") {
         if ($result->{result} == 1) {
            $vdLogger->Info("Teamcheck match successful as intended");
            return SUCCESS;
         } else {
            $vdLogger->Error("Teamcheck is a mismatch, not as intended");
            if ($count < 2) {
               $vdLogger->Info("Sleeping for 90 seconds to try again");
               sleep 90;
               next;
            }
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      } elsif ($action eq "MISMATCH") {
         if ($result->{result} == 2) {
            $vdLogger->Info("Teamcheck mismatch successful, as intended");
            return SUCCESS;
         } else {
            $vdLogger->Error("Teamcheck is a match, not as intended");
            if ($count < 2) {
               $vdLogger->Info("Sleeping for 90 seconds to try again");
               sleep 90;
               next;
            }
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      } else {
         $vdLogger->Error("Value of action passed incorrect");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   }
}


################################################################################
#
# GetVLANChkResult
#   Gets the VLAN Check results from the node
#   com.vmware.common.port.volatile.vlanchkresult
#
# Input:
#   SwName  : Name of the DVS
#   DVPort  : DVPort ID of the vmnic being checked
#
# Results:
#   Information list, on success
#   FAILURE, in case of any error / if the VLANChkresult could not be retrieved
#
# Side effects:
#   none
#
################################################################################

sub GetVLANChkResult
{
   my $self = shift;
   my $swName = shift;
   my $dvPort = shift;

   if (not defined $swName ||
       not defined $dvPort) {
      $vdLogger->Error("Parameter Switch name / DVPort ID not passed ".
                       "correctly");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Creating command to retrieve VLAN check result info
   my $command = NETDVSPATH . "net-dvs -r ".
                 "com.vmware.common.port.volatile.vlanchkresult -p ".
                 "$dvPort $swName";

   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   if (($result->{rc} != 0) || ($result->{exitCode} != 0) ||
       ($result->{stdout} !~ /trunked vlan/i)) {
      $vdLogger->Error("Failed to retrieve VLAN check result for DVPort ID $dvPort");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   return $result->{stdout};
}


################################################################################
#
# CheckHealthcheckVLANMTU
#   Checks the trunked / untrunked results of the VLAN MTU healthcheck result
#
# Input:
#   args:   : Reference to below paramters
#   Trunk   : Trunked VLAN values to be checked. Values are numeric and are accepted as
#             "10,20-50,100", etc. Hence, user has to enter the value as
#             "10_20to50_100"
#   Untrunk : Untrunked VLAN values to be checked. Same as above - the values are
#             numeric and are accepted as "10,20-50,100", etc. Hence, user has
#             to enter the value as "10_20to50_100"
#   SwObj   : dvSwitch object to be checked
#   VmnicObjsRef   : Reference to vmnic object array to be checked, but
#                    only one object is allowed.
#
# Results:
#   SUCCESS, if the match parameter matches with the action specified
#   FAILURE, in case of any error
#
# Side effects:
#   none
#
################################################################################

sub CheckHealthcheckVLANMTU
{
   my $self = shift;
   my $args = shift;
   my $trunk = $args->{trunked_vlans};
   my $unTrunk = $args->{untrunked_vlans};
   my $swObj = $args->{switch};
   my $vmnicObjsRef = $args->{vmnicadapter};

   if ((not defined $swObj) ||
       (not defined $vmnicObjsRef)) {
      $vdLogger->Error("Parameter switch / vmnic not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $swName = $swObj->{name};
   my $vmnic = $vmnicObjsRef->[0]->{interface};
   my $dvPort = undef;

   if ((not defined $trunk) ||
       (not defined $unTrunk) ||
       (not defined $swName) ||
       (not defined $vmnic)) {
      $vdLogger->Error("Parameter trunk / untrunk / switch name / vmnic not".
                       " passed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Parsing the parameter for values passed
   $trunk =~ s/\_/\,/g;
   $trunk =~ s/to/\-/g;
   $unTrunk =~ s/\_/\,/g;
   $unTrunk =~ s/to/\-/g;

   # Checking validity of the values passed
   my @contents = split (/,/,$trunk);
   foreach my $value (@contents) {
      if ($value !~ m/(\d+)-(\d+)/) {
         if ($value !~ m/(\d+)/) {
            $vdLogger->Error("Error in entering Trunk VLAN values in test hash");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }
   }

   @contents = split (/,/,$unTrunk);
   foreach my $value (@contents) {
      if ($value !~ m/(\d+)-(\d+)/) {
         if ($value !~ m/(\d+)/) {
            $vdLogger->Error("Error in entering UnTrunk VLAN values in test hash");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }
   }

   # Retrieving the DVPort ID for the NIC used
   my $result = $self->GetDVSListInfo();
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get DVS List info");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Convert the output to an array
   my @tempArray1 = split(/(\n+)/, $result);

   # Filter out unnecessary spaces
   my @newArray;
   foreach my $el (@tempArray1) {
      if ($el =~ m/\S+/i) {
         $el =~ s/^\s+//;
         $el =~ s/\s+$//;
         push(@newArray, $el);
      }
   }

   # Getting the DVPort ID from the previous result
   my $count = 0;
   foreach my $value (@newArray) {
      $count++;
      if ($value =~ /Client:/) {
         my @tempArray2 = split (/:/, $value);
         if ($tempArray2[1] =~ /$vmnic/i) {
            my $i = $count+2;
            if ($newArray[$i] =~ /Port ID:/) {
               my @tempArray3 = split (/:/, $newArray[$i]);
               $dvPort = $tempArray3[1];
               last;
            } else {
               $vdLogger->Error("Unable to parse DVPort ID from esxcli output for".
                                " Client: $vmnic");
               VDSetLastError("EFAIL");
               return FAILURE;
            }
         }
         next;
      }
   }

   # Getting the VLANMTU Check result for the dvPort retrieved
   $count = 0;
   while ($count < 2) {
      $count++;
      # Retrieving VLANMTU check result info
      my $result = $self->GetVLANChkResult($swName,$dvPort);

      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to get VLANMTU check result info");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      $vdLogger->Debug("Retrieved VLAN check result: $result");

      my @tempArray4 = split(/(\n+)/, $result);
      # Checking whether retrieved result matches with intended result for trunked values
      if ($tempArray4[0] =~ /Trunked VLAN:/) {
         my @tempArray5 = split (/:/, $tempArray4[0]);
         if ($tempArray5[1] =~ $trunk) {
            $vdLogger->Info("Trunked VLAN check result match successful");
         } else {
            $vdLogger->Error("Trunked VLAN check result match is a mismatch");
            if ($count < 2) {
               $vdLogger->Info("Sleeping for 90 seconds to try again");
               sleep 90;
               next;
            }
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      } else {
         $vdLogger->Error("Unable to parse output from net-dvs for VLANMTU check result");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      # Checking whether retrieved result matches with intended result for untrunked values
      if ($tempArray4[2] =~ /Untrunked VLAN:/) {
         my @tempArray5 = split (/:/, $tempArray4[2]);
         if ($tempArray5[1] =~ $unTrunk) {
            $vdLogger->Info("Untrunked VLAN check result match successful");
            return SUCCESS;
         } else {
            $vdLogger->Error("Untrunk VLAN check result is a mismatch");
            if ($count < 2) {
               $vdLogger->Info("Sleeping for 90 seconds to try again");
               sleep 90;
               next;
            }
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      } else {
         $vdLogger->Error("Unable to parse output from net-dvs for VLANMTU check result");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }
}


################################################################################
#
# GetDVSListInfo
#   Gets the DVS list information from esxcli command:
#   esxcli network vswitch dvs vmware list
#
# Input:
#   None.
#
# Results:
#   Information list, on success
#   FAILURE, in case of any error / if the DVS info list could not be retrieved
#
# Side effects:
#   none
#
################################################################################

sub GetDVSListInfo
{
   my $self = shift;

   # Creating command to retrieve VLAN check result info
   my $command = "esxcli network vswitch dvs vmware list";

   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to retrieve DVS list info");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   return $result->{stdout};
}


########################################################################
#
# GetManagementInterfaceName--
#    This method returns the management interface for the esx host,
#    typically it is vmk0 but in some cases it might be different.
#
# Input:
#    None.
#
# Results:
#      Name of the interface (vmk<X>).
#      "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetManagementInterfaceName
{
   my $self = shift;
   my $host = $self->{hostIP};
   my $stafHelper = $self->{stafHelper};
   my $result;
   my $interface;
   my $cmd;

   $cmd = "vsish -pe get /config/Net/strOpts/ManagementIface";
   $result = $stafHelper->STAFSyncProcess($host, $cmd);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to get Management Interface for $host ");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $interface = VDNetLib::Common::Utilities::ProcessVSISHOutput(
                                             RESULT => $result->{stdout}
                                             );
   if ($interface->{"cur"} =~ m/vmk/i) {
      return $interface->{"cur"};
   } else {
      $vdLogger->Error("The Management interface name is not valid $interface->{cur}");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
}


################################################################################
#
# SetNetdump
#   Setting the Netdump Parameters on the ESX host.
#   Parameters like : Interface on which Network core dump need to be sent.
#	              Netdump Server IP and Server Port.
#
# Input:
#   VMKernelNIC       : VMKernel NIC as Netdump Interface (Required)
#   NetdumpServerIP   : Netdump Server IP Address. (Required)
#   NetdumpServerPort : Netdump Server Port to dump. (Required)
#
# Results:
#   SUCCESS, if the netdump parameters are set successfully
#   FAILURE, in case of any error, in setting the Netdump Configuration.
#
# Side effects:
#   none
#
################################################################################

sub SetNetdump {

    my $self              = shift;
    my $NetdumpVMKNIC     = shift;
    my $NetdumpServerIP   = shift;
    my $NetdumpServerPort = shift;
    my $netdumpEsxcliSet  = "/sbin/esxcli system coredump network set".
			    " --interface-name ";

    my $commandSet = "$netdumpEsxcliSet ". "$NetdumpVMKNIC ";
    $commandSet = "$commandSet". " --server-ipv4 ". " $NetdumpServerIP ";
    $commandSet = "$commandSet". " --server-port ". " $NetdumpServerPort ";

    my $resultSet = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
							 $commandSet);
    if (($resultSet->{rc} != 0)||
	($resultSet->{'stdout'} =~ m/No VM kernel NIC/) ||
	($resultSet->{exitCode} != 0)) {
	$vdLogger->Error("STAF command to Set Netdump Client".
			 " failed:". Dumper($resultSet));
        VDSetLastError("ESTAF");
        return FAILURE;
    }
    return SUCCESS;
}


################################################################################
#
# ConfigureNetdump
#   Enable/Disable the Netdump on ESX Host.
#
# Input:
#   NetdumpStatus	: Value to either enable/disable the netdump.(Required)
#
# Results:
#   SUCCESS, if the netdump is enabled/disabled successfully on ESX Host
#   FAILURE, in case of any error, in enabling/disabling the network core
#	        dump to the server
#
# Side effects:
#   none
#
################################################################################

sub ConfigureNetdump {

    my $self                 = shift;
    my $NetdumpStatus        = shift;
    my $netdumpEsxcliEnable  = "/sbin/esxcli system coredump network".
			       " set --enable";
    chomp ($NetdumpStatus);

    # Phrase proper Netdump status
    my $command = "";
    if (defined $NetdumpStatus) {
        if (($NetdumpStatus =~ m/TRUE/i) ||
	    ($NetdumpStatus =~ m/ON/i)   ||
	    ($NetdumpStatus eq "t")      ||
	    ($NetdumpStatus eq "1")) {
            $command = "$netdumpEsxcliEnable". " $NetdumpStatus";
        }
        elsif (($NetdumpStatus =~ m/FALSE/i) ||
	       ($NetdumpStatus =~ m/OFF/i)   ||
	       ($NetdumpStatus eq "f")       ||
	       ($NetdumpStatus eq "0")) {
            $command = "$netdumpEsxcliEnable". " $NetdumpStatus";
        }
        else {
            $vdLogger->Error("The Netdump status is not sent properly".
                             "for configuration.");
            VDSetLastError("ENOTDEF");
            return FAILURE;
        }
    }
    else {
        $vdLogger->Error("The Netdump status is not sent properly".
			 "for configuration.");
        VDSetLastError("ENOTDEF");
        return FAILURE;
    }

    my $resultConfigure = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
							       $command);
    if (($resultConfigure->{rc} != 0)||($resultConfigure->{exitCode} != 0)) {
        $vdLogger->Error("STAF command to $NetdumpStatus Netdump Client".
			 " failed:". Dumper($resultConfigure));
        VDSetLastError("EFAIL");
        return FAILURE;
    }
    return  SUCCESS;
}


################################################################################
#
# NetdumpPanicAndReboot
#   Generate the Panic and allow the system to be rebooted and wait for the
#   host to get reconnected.
#
# Input:
#   PanicLevel      : Panic Level set to the ESX Host (Required)
#   PanicType       : Type of Panic. This is kept for future use.(Not Required)
#
# Results:
#   SUCCESS, if the Netdump client i.e Host of Crashed and
#	     Rebooted Successfully.
#   FAILURE, in case of any error, in Crashing or rebooting the Host.
#
# Side effects:
#   none
#
################################################################################

sub NetdumpPanicAndReboot {

    my $self                = shift;
    my $PanicLevel          = shift || 1;
    my $PanicType           = shift;
    my $netdumpVsishPanic   = "vsish -e set /reliability/crashMe/Panic ";
    my $netdumpBSODTimeOut  = "vsish -e set".
			      " /config/Misc/intOpts/BlueScreenTimeout 1";

    if ($PanicLevel !~ /^\d+$/) {
        $vdLogger->Error("Panic value for the Netdump is not set properly");
        VDSetLastError("EINVALID");
        return FAILURE;
    }
    if ($PanicType !~ /normal/i) {
        $vdLogger->Error("Panic Type for Netdump is not set properly");
        VDSetLastError("EINVALID");
        return FAILURE;
    }
    my $commandBSODTimeout = "$netdumpBSODTimeOut";
    my $resultBsod = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
							  $commandBSODTimeout);
    if ($resultBsod->{rc} != 0) {
        $vdLogger->Error("STAF command to Generate the panic Netdump".
			 "Client failed:". Dumper($resultBsod));
        VDSetLastError("ESTAF");
        return FAILURE;
    }

    my $commandPanic = "$netdumpVsishPanic ". "$PanicLevel";
    my $resultPanic = $self->{stafHelper}->STAFAsyncProcess($self->{hostIP},
							    $commandPanic);
    if ($resultPanic->{rc} != 0) {
        $vdLogger->Error("STAF command to Generate the panic Netdump Client".
			 " failed:". Dumper($resultPanic));
        VDSetLastError("ESTAF");
        return FAILURE;
    }
    $vdLogger->Info("System Panic is Generated...!!!");

    #Waiting for ESX host rebooting.
    $vdLogger->Info("Waiting for the Host to Reboot...");
    my $counter=1;
    my $retry = 60;
    my $result = '';
    while (1) {
        sleep(20);
        if (VDNetLib::Common::Utilities::Ping($self->{hostIP})) {
            $vdLogger->Debug("$self->{hostIP} not accessible, still trying...");
        } else {
	    $vdLogger->Info("Host reboot successful and is accessible now.");
            sleep(20);
	    last;
        }
        $counter++;
        if ($counter > $retry) {
            $vdLogger->Error("The host is not accessible at iteration:".
			     "$counter");
            VDSetLastError("ESTAF");
            return FAILURE;
        }
    }

    # Reconnect to the Host
    if ($self->Reconnect(10) eq FAILURE) {
        $vdLogger->Error("The host reboot failed since".
			 " staf anchor can not create.");
        VDSetLastError(VDGetLastError());
        return FAILURE;
    }

    $vdLogger->Info("Configuring $self->{hostIP} for vdnet");
    if (FAILURE eq $self->ConfigureHostForVDNet()) {
        VDSetLastError(VDGetLastError());
        return FAILURE;
    }
    $vdLogger->Info("The host reconnect is successful.");
    return SUCCESS;
}


################################################################################
#
# VerifyNetdumpClient
#   To verify if the Netdump is properly configured with given parameters.
#
# Input:
#   VMKernelNIC        : VMKernel NIC as Netdump Interface (Required)
#   NetdumpServerIP    : Netdump Server IP Address. (Required)
#   NetdumpiServerPort : Netdump Server Port to dump (Required)
#   NetdumpStatus      : Netdump Status for verification. (Required)
#
# Results:
#   SUCCESS, if the Netdump status provided is Successfully Verified.
#   FAILURE, in case of Netdump status given as input is not properly
#                validated with existing configuration.
#
# Side effects:
#   none
#
################################################################################

sub VerifyNetdumpClient {

    my $self               = shift;
    my $NetdumpVMKNIC      = shift;
    my $NetdumpServerIP    = shift;
    my $NetdumpiServerPort = shift;
    my $NetdumpStatus      = shift;
    my $netdumpEsxcliGet   = "/sbin/esxcli system coredump network get";
    chomp ($NetdumpStatus);

    my $commandGet = "$netdumpEsxcliGet";
    my $resultGet = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
							 $commandGet);
    if ($resultGet->{rc} != 0) {
        $vdLogger->Error("STAF command to Get Netdump client".
			 " failed:". Dumper($resultGet));
        VDSetLastError("ESTAF");
        return FAILURE;
    }
    if (($NetdumpStatus eq "true") &&
	($resultGet->{stdout} =~ m/Enabled: $NetdumpStatus/i) &&
	($resultGet->{stdout} =~ m/Network Server IP: $NetdumpServerIP/i) &&
	($resultGet->{stdout} =~ m/Host VNic: $NetdumpVMKNIC/i) &&
	($resultGet->{stdout} =~ m/Network Server Port: $NetdumpiServerPort/i)){
        $vdLogger->Info("Netdump is Successfully Verified".
			" for its configurations");
        return SUCCESS;
    }
    elsif (($NetdumpStatus eq "false") &&
	($resultGet->{stdout} =~ m/Enabled: $NetdumpStatus/i)) {
        $vdLogger->Info("Netdump is Successfully Verified".
			" for its configurations");
        return SUCCESS;
    }
    else {
        $vdLogger->Error("Verification failed. Not retaining the Netdump".
			 " configuration Parameters:". Dumper ($resultGet));
        VDSetLastError("ESTAF");
        return FAILURE;
    }
}


################################################################################
#
# CheckCommandNetdump
#   This command is dry run test utility command for checking the Netdump.
#   To verify if the Netdump works properly by sending Netdump hello check
#   packets to Netdump Server.
#
# Input:
#   None.
#
# Results:
#   SUCCESS, if the command is executed successfully.
#   FAILURE, in case of Netdump command is not properly executed,
#            with the existing Netdump configurations.
#
# Side effects:
#   none
#
################################################################################

sub NetdumpCheckCommand {

    my $self                = shift;
    my $netdumpEsxcliCheck  = "/sbin/esxcli system coredump network check";
    my $commandCheck        = "$netdumpEsxcliCheck";
    my $netdumpEsxcliGet   = "/sbin/esxcli system coredump network get";

    my $resultCheck = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
							 $commandCheck);
    $vdLogger->Debug("STAF Command to Check Netdump $commandCheck".
		     " output:". Dumper($resultCheck));

    if (($resultCheck->{rc} != 0)||
	($resultCheck->{stdout} =~ m/Network coredump not enabled/i) ||
        ($resultCheck->{stdout} =~ m/Attempt to contact configured netdump server failed/i) ||
	($resultCheck->{exitCode} != 0)) {
	$vdLogger->Error("STAF command to Check Netdump ".
			 " failed:". Dumper($resultCheck));
        VDSetLastError("ESTAF");
        return FAILURE;
    }
    return SUCCESS;
}


################################################################################
#
# DeleteNetdumpVMK
#   Delete The VMKNIC configured from the testbed.
#
# Input:
#   Vmknic name
#
# Results:
#   SUCCESS, if the command is executed successfully.
#   FAILURE, in case of VMKNIC is not properly deleted.
#
# Side effects:
#   none
#
################################################################################

sub DeleteNetdumpVMK {

    my $self          = shift;
    my $NetdumpVMKNIC = shift;

    if (not defined $NetdumpVMKNIC) {
        $vdLogger->Error("No vmknic id provided to delete");
        VDSetLastError("ENOTDEF");
        return FAILURE;
    }
    my $pyObj = $self->GetInlinePyObject();
    my $result = CallMethodWithKWArgs($pyObj, "remove_vnic", {'name' => $NetdumpVMKNIC});
    if($result eq FAILURE){
        $vdLogger->Error("Could not remove $NetdumpVMKNIC on $self->{hostIP}");
        VDSetLastError(VDGetLastError());
        return FAILURE;
    }
    return SUCCESS
}


########################################################################
#
# BackupHostConfigurations --
#    Executes the backup.sh command to write configurations to DB.
#
# Input:
#     Cmd: To execute the backup.sh command.
#
# Results:
#     'SUCCESS', if the command is successful
#     'FAILURE', in case of any error
#
# Side effects:
#     None
#
########################################################################

sub BackupHostConfigurations
{
    my $self   = shift;
    my $cmd    = "/sbin/backup.sh 0";
    my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
							 $cmd);
    $vdLogger->Debug("Backup Command Executed and result:".
						Dumper($result));
    if (($result->{rc} != 0)||
	($result->{exitCode} != 0)) {
	$vdLogger->Error("STAF command to execute backup command".
			 " failed:". Dumper($result));
        VDSetLastError("ESTAF");
        return FAILURE;
    }
    return SUCCESS;
}


########################################################################
#
# GetRouteEntries--
#     Method to get the entries on the host's routing table
#
# Input:
#     protocol: "ipv4" or "ipv6" # Optional, default is ipv4
#
# Results:
#     reference to a array of hash with the following keys in the hash:
#     network: network address
#     netmask: subnet mask
#     gateway: gateway address to reach the network
#     interface: interface name;
#
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################


sub GetRouteEntries
{
   my $self = shift;
   my $protocol = shift || "ipv4";

   my $command = "esxcli network ip route $protocol list";

   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to retrieve DVS list info");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $data = $result->{stdout};
   my @temp = split(/\n/, $data);

   shift(@temp); # removes header: Network Netmask Gateway Interface
   shift(@temp); # removes ------ below the header

   my $routeList = [];
   foreach my $line (@temp) {
      my $route = {};
      ($route->{network}, $route->{netmask},
       $route->{gateway}, $route->{interface}) = split(/\s+/, $line);
       push (@{$routeList}, $route);
   }
   return $routeList;
}


########################################################################
#
# DeleteRoute--
#     Method to delete the given route.
#
# Input:
#     route: reference to hash with following keys
#            network: network address
#            netmask: subnet mask
#            gateway: gateway address to reach the network
#            interface: interface name
#     protocol: "ipv4" or "ipv6" # Optional, default is ipv4
#
# Results:
#     SUCCESS, if the given route is deleted;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub DeleteRoute
{
   my $self = shift;
   my $route = shift;
   my $protocol = shift || "ipv4";

   my $command = "esxcli network ip route $protocol remove " .
                 "-g $route->{gateway} -n $route->{network}";

   $vdLogger->Debug("Delete route command: $command");

   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   $vdLogger->Debug("Routing table:" . Dumper($result));
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to delete given route");
      $vdLogger->Debug("Existing route:" . Dumper($self->GetRouteEntries("ipv6")));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}


########################################################################
#
# GetNetworkPortStat--
#     Method to get network-port statistics
#     command used: esxcli network port stats get -p <portid>
#
# Input:
#     portId : Switch port id.
#
# Results:
#     Returns array reference of network port stats output.
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetNetworkPortStat
{
   my $self   = shift;
   my $portId = shift;

   my $command = "esxcli network port stats get -p $portId";
   $vdLogger->Debug("command to get the port statistics: $command");

   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   $vdLogger->Debug("Port stats:" . Dumper($result));
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to get the port statistics");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   return $result->{stdout};
}


########################################################################
#
# GetVMNicPacketStat--
#     Method to get vmnic packet statistics.
#     command used: esxcli network nic stats get -n <vmnic>
#
# Input:
#     vmnic : vnmic name on which packets to be retrieved.
#
# Results:
#     returns array reference to vmnic packet statistics;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetVMNICPacketStat
{
   my $self  = shift;
   my $vmnic = shift;

   # Get the vmnic packet stats
   my $command = "esxcli network nic stats get -n $vmnic";
   $vdLogger->Debug("command to get the vmnic stats: $command");

   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   $vdLogger->Debug("vmnic stats:" . Dumper($result));
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to get the vmnic stats on the $vmnic");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   return $result->{stdout};
}


########################################################################
#
# EnableVLANPacketStat--
#     Method to enable VLAN packet statistics.
#     command used: esxcli network nic vlan stats set -n <vmnic> -e true
#
# Input:
#     vmnic:  vnmic name on which VLAN stats to be enabled.
#
# Results:
#     SUCCESS in case of VLAN stats enabled;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub EnableVLANPacketStat
{
   my $self   = shift;
   my $vmnic  = shift;

   my $command = "esxcli network nic vlan stats set -n $vmnic -e true";
   $vdLogger->Debug("Command to enable VLAN stats on the given vmnic: $command");

   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   $vdLogger->Debug("Enable VLAN stats on vmnic:" . Dumper($result));
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      return FAILURE;
   }

   return SUCCESS;
}


########################################################################
#
# GetPerVLANPacketStat--
#     Method to get VLAN packet statistics.
#     command used: esxcli network nic vlan stats get -n <vmnic>
#
# Input:
#     vmnic:  vnmic name on which VLAN packets to be retrieved.
#
# Results:
#     returns array reference to vlan packet statistics;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetPerVLANPacketStat
{
   my $self   = shift;
   my $vmnic  = shift;

   my $command = "esxcli network nic vlan stats get -n $vmnic";
   $vdLogger->Debug("command to get the VLAN stats: $command");

   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   $vdLogger->Debug("VLAN stats on vmnic:" . Dumper($result));
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to get the VLAN stats on the $vmnic");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   return $result->{stdout};
}


########################################################################
#
# ParseVlanStat--
#     Method to extract VLAN Packets count.
#
# Input:
#     vlanStat: String which contains the output of -
#     "esxcli network nic vlan stats get -n <vmnic>" command.
#     vlanStat would have something like:
#     VLAN 3002
#        Packets received: 95
#        Packets sent: 0
#
#     VLAN 4000
#        Packets received: 95
#        Packets sent: 0
#
#     vlanId: VLAN id.
#
# Results:
#     returns Packets sent count and Packets received count;
#     undefined, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub ParseVlanStat
{
   my $self     = shift;
   my $vlanStat = shift;
   my $vlanId   = shift;

   my $packetReceived = undef;
   my $packetSent = undef;

   my @vlanArray = split(/\n\n/, $vlanStat);
   my $vlanIdStat;
   foreach my $val (@vlanArray) {
      if ($val =~ m/VLAN $vlanId/) {
         $vlanIdStat = $val;
      }
   }

   if($vlanIdStat =~ m/Packets received: (\d+)/) {
      $packetReceived = $1;
   }

   if($vlanIdStat =~ m/Packets sent: (\d+)/) {
      $packetSent = $1;
   }

   return ("PacketReceived" => $packetReceived, "PacketSent" => $packetSent);
}


########################################################################
#
# GetDVFilterPortStat--
#     Method to get network-port filter statistics.
#     command used: esxcli network port filter stats get -p <portid>
#
# Input:
#     portId : Switch Port Id.
#
# Results:
#     returns array reference to DVFilter statistics;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetDVFilterPortStat
{
   my $self   = shift;
   my $portId = shift;

   my $command = "esxcli network port filter stats get -p $portId";
   $vdLogger->Debug("command to get the port filter statistics: $command");

   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   $vdLogger->Debug("Port stats:" . Dumper($result));
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to get the port statistics");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   return $result->{stdout};
}


########################################################################
#
# MonitorNetworkPortStat--
#     Method to check whether network-port statistics are updating
#     Properly or not.
#
# Input:
#     switch    : Switch Object to which VM is connected.
#
# Results:
#     SUCCESS, if the network-port statistics are updating properly;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub MonitorNetworkPortStat
{
   my $self = shift;
   my $args = shift;
   my $switch  = $args->{switch};

   if (not defined $switch)  {
      $vdLogger->Error("Failed to retrieve switch object.");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   my $dvs = $switch->{name};

   my $firstPktsReceived;
   my $lastPktsReceived;
   my $firstPktsSent;
   my $lastPktsSent;

   # Retrieving portset name of DVS
   my $portSet = $self->GetPortSetNamefromDVS($dvs);
   if ($portSet eq FAILURE) {
      $vdLogger->Error("Failed to retrieve portset name of DVS $dvs");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $portArray = undef; # All the ports connected to VDS
   $portArray = $self->GetVnicPortIds($portSet);
   if ($portArray eq FAILURE) {
      $vdLogger->Error("Unable to retrieve Port IDs for switch $dvs");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $portStat = $self->GetNetworkPortStat($portArray->[0]);
   if ($portStat eq FAILURE) {
      $vdLogger->Error("Failed to get the initial port statistics");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   if($portStat =~ m/Packets received: (\d+)/) {
      $firstPktsReceived = $1;
   }

   if($portStat =~ m/Packets sent: (\d+)/) {
      $firstPktsSent = $1;
   }

   $vdLogger->Debug("Sleep for 3 seconds to get packets sent/received counters updated");
   sleep(3);

   $portStat = $self->GetNetworkPortStat($portArray->[0]);
   if ($portStat eq FAILURE) {
      $vdLogger->Error("Failed to get the final port statistics");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   if($portStat =~ m/Packets received: (\d+)/) {
      $lastPktsReceived = $1;
   }

   if($portStat =~ m/Packets sent: (\d+)/) {
      $lastPktsSent = $1;
   }

   # Check if Packets sent and Packets received values are updated.
   $vdLogger->Debug("Initial value: Packets sent = $firstPktsSent");
   $vdLogger->Debug("Final value: Packets sent = $lastPktsSent");
   if ($lastPktsSent > $firstPktsSent) {
      $vdLogger->Debug("Packets sent counter updated successfully");
   } else {
      $vdLogger->Debug("Packets sent counter not updated");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $vdLogger->Debug("Initial value: Packets received = $firstPktsReceived");
   $vdLogger->Debug("Final value: Packets received = $lastPktsReceived");
   if ($lastPktsReceived > $firstPktsReceived) {
      $vdLogger->Debug("Packets received counter updated successfully");
   } else {
      $vdLogger->Debug("Packets received counter not updated");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# MonitorVMNicPacketStat--
#     Method to check whether vmnic packet statistics are updating
#     Properly or not.
#
# Input:
#     vmnic:  vnmic Object on which packets to be monitored.
#
# Results:
#     SUCCESS, if the vmnic packet statistics are updating properly;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub MonitorVMNicPacketStat
{
   my $self = shift;
   my $args = shift;

   my $vmnic = $args->{adapter};
   if (not defined $vmnic)  {
      $vdLogger->Error("Failed to retrieve vmnic object.");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $vmnicName = $vmnic->{vmnic};

   my $firstPktsReceived;
   my $lastPktsReceived;
   my $firstPktsSent;
   my $lastPktsSent;

   # Get the vmnic packet stats - initial
   my $vmnicStat = $self->GetVMNICPacketStat($vmnicName);
   if ($vmnicStat eq FAILURE) {
      $vdLogger->Error("Failed to get the vmnic stats on the $vmnicName - initial");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   if($vmnicStat =~ m/Packets received: (\d+)/) {
      $firstPktsReceived = $1;
   }

   if($vmnicStat =~ m/Packets sent: (\d+)/) {
      $firstPktsSent = $1;
   }

   $vdLogger->Debug("Sleep for 3 seconds to get packets sent/received counters updated");
   sleep(3);

   # Get the vmnic packet stats - final
   $vmnicStat = $self->GetVMNICPacketStat($vmnicName);
   if ($vmnicStat eq FAILURE) {
      $vdLogger->Error("Failed to get the vmnic stats on the $vmnicName - final");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   if($vmnicStat =~ m/Packets received: (\d+)/) {
      $lastPktsReceived = $1;
   }

   if($vmnicStat =~ m/Packets sent: (\d+)/) {
      $lastPktsSent = $1;
   }

   # Check if the vmnic packets sent and packets received values are updated.
   $vdLogger->Debug("Initial value: Packets sent = $firstPktsSent");
   $vdLogger->Debug("Final value: Packets sent = $lastPktsSent");
   if ($lastPktsSent > $firstPktsSent) {
      $vdLogger->Debug("Packets sent counter updated successfully");
   } else {
      $vdLogger->Debug("Packets sent counter not updated");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $vdLogger->Debug("Initial value: Packets received = $firstPktsReceived");
   $vdLogger->Debug("Final value: Packets received = $lastPktsReceived");
   if ($lastPktsReceived > $firstPktsReceived) {
      $vdLogger->Debug("Packets received counter updated successfully");
   } else {
      $vdLogger->Debug("Packets received counter not updated");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# MonitorPerVLANPacketStat--
#     Method to check whether VLAN packet statistics are updating
#     Properly or not.
#     command used: esxcli network nic vlan stats get -n <vmnic>
#
# Input:
#     vmnic:  vnmic Object on which VLAN packets to be monitored.
#     vlanid: VLAN ID to be monitored.
#
# Results:
#     SUCCESS, if the VLAN packet statistics are updating properly;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub MonitorPerVLANPacketStat
{
   my $self   = shift;
   my $args = shift;

   my $vmnic = $args->{adapter};
   my $vlanId = $args->{vlan};
   if (not defined $vmnic || not defined $vlanId)  {
      $vdLogger->Error("Failed to retrieve vmnic object or vlan ID.");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   my $vmnicName  = $vmnic->{vmnic};
   my $firstPktsReceived;
   my $lastPktsReceived;
   my $firstPktsSent;
   my $lastPktsSent;

   if (not defined $vmnicName) {
      $vdLogger->Error("Vmnic not provided");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Enable VLAN stats on the given vmnic
   my $result = $self->EnableVLANPacketStat($vmnicName);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to enable the VLAN stats on the $vmnicName");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Get the VLAN stats - initial
   my $vlanStat = $self->GetPerVLANPacketStat($vmnicName);
   if ($vlanStat eq FAILURE) {
      $vdLogger->Error("Failed to get the VLAN stats on the $vmnicName - initial");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my (%packetsCount) = $self->ParseVlanStat($vlanStat, $vlanId);
   $firstPktsReceived = $packetsCount{"PacketReceived"};
   $firstPktsSent = $packetsCount{"PacketSent"};

   $vdLogger->Debug("Sleep for 3 seconds to get packets sent/received counters updated");
   sleep(3);

   # Get the VLAN stats - final
   $vlanStat = $self->GetPerVLANPacketStat($vmnicName, $vlanId);
   if ($vlanStat eq FAILURE) {
      $vdLogger->Error("Failed to get the VLAN stats on the $vmnicName - final");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   (%packetsCount) = $self->ParseVlanStat($vlanStat, $vlanId);
   $lastPktsReceived = $packetsCount{"PacketReceived"};
   $lastPktsSent = $packetsCount{"PacketSent"};

   # Check if the VLAN Packets sent and Packets received values are updated.
   $vdLogger->Debug("Initial value: Packets received = $firstPktsReceived");
   $vdLogger->Debug("Final value: Packets received = $lastPktsReceived");
   if ($lastPktsReceived > $firstPktsReceived) {
      $vdLogger->Debug("Packets received counter updated successfully");
   } else {
      $vdLogger->Debug("Packets received counter not updated");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $vdLogger->Debug("Initial value: Packets sent = $firstPktsSent");
   $vdLogger->Debug("Final value: Packets sent = $lastPktsSent");
   if ($lastPktsSent > $firstPktsSent) {
      $vdLogger->Debug("Packets sent counter updated successfully");
   } else {
      $vdLogger->Debug("Packets sent counter not updated");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# MonitorDVFilterPortStat--
#     Method to check whether network-port filter statistics
#     are updating Properly or not.
#
# Input:
#     switch    : switch Obj on which VM is connected.
#
# Results:
#     SUCCESS, if the network-port filter statistics are updating
#     properly; FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub MonitorDVFilterPortStat
{
   my $self = shift;
   my $args = shift;

   my $switch =  $args->{switch};
   if (not defined $switch)  {
      $vdLogger->Error("Failed to retrieve switch object.");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   my $dvs  = $switch->{name};

   my $firstPktsIn;
   my $lastPktsIn;
   my $firstPktsOut;
   my $lastPktsOut;

   # Retrieving portset name of DVS
   my $portSet = $self->GetPortSetNamefromDVS($dvs);
   if ($portSet eq FAILURE) {
      $vdLogger->Error("Failed to retrieve portset name of DVS $dvs");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $portArray = undef; # All the ports connected to vSwitch
   $portArray = $self->GetVnicPortIds($portSet);
   if ($portArray eq FAILURE) {
      $vdLogger->Error("Unable to retrieve Port IDs for switch $dvs");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $portStat = $self->GetDVFilterPortStat($portArray->[1]);
   if ($portStat eq FAILURE) {
      $vdLogger->Error("Failed to get the initial port statistics");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   if($portStat =~ m/Packets in: (\d+)/) {
      $firstPktsIn = $1;
   }

   if($portStat =~ m/Packets out: (\d+)/) {
      $firstPktsOut = $1;
   }

   $vdLogger->Debug("Sleep for 3 seconds to get packets in/out counters updated");
   sleep(3);

   $portStat = $self->GetDVFilterPortStat($portArray->[1]);
   if ($portStat eq FAILURE) {
      $vdLogger->Error("Failed to get the final port statistics");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   if($portStat =~ m/Packets in: (\d+)/) {
      $lastPktsIn = $1;
   }

   if($portStat =~ m/Packets out: (\d+)/) {
      $lastPktsOut = $1;
   }

   # Check if Packets in and Packets out values are updated.
   $vdLogger->Debug("Initial value: Packets-in = $firstPktsIn");
   $vdLogger->Debug("Final value: Packets-in = $lastPktsIn");
   if ($lastPktsIn > $firstPktsIn) {
      $vdLogger->Debug("Packets-in counter updated successfully");
   } else {
      $vdLogger->Debug("Packets-In counter not updated");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $vdLogger->Debug("Initial value: Packets-out = $firstPktsOut");
   $vdLogger->Debug("Final value: Packets-out = $lastPktsOut");
   if ($lastPktsOut > $firstPktsOut) {
      $vdLogger->Debug("Packets-out counter updated successfully");
   } else {
      $vdLogger->Debug("Packets-out counter not updated");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# LoadDriver--
#     Method to load vmkernel module/driver on the the host
#
# Input:
#     driver: name of the driver/module (Required)
#     moduleParams : module params as a string (Optional)
#
# Results:
#     "SUCCESS", if the driver/module is loaded successfully;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub LoadDriver
{
   my $self    = shift;
   my $driver  = shift;
   my $moduleParams = shift || "";

   if (not defined $driver) {
      $vdLogger->Error("Driver/module name to loaded not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $command = "vmkload_mod $driver $moduleParams";
   $vdLogger->Info("Loading module/driver: $command on $self->{hostIP}");
   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to load driver $driver on $self->{hostIP}");
      $vdLogger->Debug("Error" . Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}


########################################################################
#
# UnloadDriver--
#     Method to unload the given vmkernel module/driver
#
# Input:
#     driver: name of the module/driver to unload (Required)
#
# Results:
#     "SUCCESS", if the given driver is unloaded successfully;
#     "FAILURE", in case of any error;
#
# Side effects:
#     All network adapters that were initialized using the given driver
#     will get de-activated. Call LoadDriver() method to enable these
#     adapters again
#
########################################################################

sub UnloadDriver
{
   my $self = shift;
   my $driver = shift;
   my $command = "vmkload_mod -u $driver";
   # Submit STAF command
   $vdLogger->Info("Unloading module/driver: $command on $self->{hostIP}");
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Debug("Failed to unload driver $driver on $self->{hostIP}");
      $vdLogger->Debug("Error" . Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}

########################################################################
#
# ConfigureSRIOV--
#     Method to configure SR-IOV on the given adapters
#
# Input:
#     sriovAdapters: Reference to a hash with following keys:
#                    adapter : an instance of
#                              VDNetLib::NetAdapter:Vmnic::Vmnic class
#                    maxvfs  : number of virtual functions (VFs) to
#                              create on the given adapter
#
# Results:
#     "SUCCESS", if SRIOV is enabled successfully on the given adapters;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ConfigureSRIOV
{
   my $self          = shift;
   my $sriovAdapters = shift;

   if (not defined $sriovAdapters) {
      $vdLogger->Error("Reference to sriov adapters hash is not provided");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (FAILURE eq $self->EnableSRIOVRefreshInHostdConfig()) {
      $vdLogger->Error("Unable to change the config.xml for hostd to support SRIOV refresh");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $sriovConfigs = $self->PrepareSRIOVConfigs($sriovAdapters);
   if ($sriovConfigs eq FAILURE) {
      $vdLogger->Error("Failed to prepare SRIOV configurations " .
                       "for the given adaperters list " .
                       Dumper($sriovAdapters));
   }
   my $inlineHostObject = $self->GetInlineHostObject();
   if (!$inlineHostObject->ConfigureSRIOV($sriovConfigs)) {
      $vdLogger->Error("Failed to configure SRIOV on the host");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   #
   # Verify expected number of VFs are created on all the given adapters
   #
   foreach my $item (@{$sriovConfigs}) {
      my $availableVFs = $self->GetVirtualFunctions($item->{'interface'});
      if ($availableVFs eq FAILURE) {
         $vdLogger->Error("Failed to get virtual functions");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Debug("Configured ".keys(%$availableVFs)." vfs on ".$item->{'interface'});
      if (keys(%$availableVFs) != int($item->{'vfs'})) {
            $vdLogger->Error("Failed to configure vfs:
                              want $item->{'vfs'},
                              but ".keys(%$availableVFs)." configured");
            VDSetLastError("EMISMATCH");
            return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# PrepareSRIOVConfigs--
#     Method to prepare SIROV configurations before invoke inline java
#     to configure SRIOV on vmnics.
#
# Input:
#     sriovAdapters: Reference to a hash with following keys:
#                    adapter : an instance of
#                              VDNetLib::NetAdapter:Vmnic::Vmnic class
#                    maxvfs  : number of virtual functions (VFs) to
#                              create on the given adapter
# #
# Results:
#      sriovConfigs, Reference to an array of SRIOV configurations;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub PrepareSRIOVConfigs
{
   my $self          = shift;
   my $sriovAdapters = shift;

   if (not defined $sriovAdapters) {
      $vdLogger->Error("Reference to sriov adapters hash is not provided");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #
   # For all the adapters in the given list ($sriovAdapters), use the
   # corresponding maxvfs value to prepare SRIOV configurations
   #
   my @sriovConfigs = ();
   foreach my $item (@{$sriovAdapters}) {
      my $config = {};
      $config->{'interface'} = $item->{'adapter'}{'interface'};
      $config->{'vfs'} = int($item->{maxvfs});
      $config->{'pci_id'} = $self->GetPCIID($config->{'interface'});
      if ($config->{'vfs'} == 0) {
         $config->{'sriov_enabled'} = 0;
      } else {
         $config->{'sriov_enabled'} = 1;
      }
      push(@sriovConfigs,$config);
   }
   $vdLogger->Debug("Prepared SRIOV configurations are".Dumper(\@sriovConfigs));
   return \@sriovConfigs;
}

########################################################################
#
# GetPCIDevices--
#     Method to get the list of PCI devices on the ESX host
#
# Input:
#     None
#
# Results:
#     Reference to array of hash which has the following keys:
#     'bdf'    : BDF (Bus, Device, Function) number
#     'class'  : class of the PCI device
#     'name'   : interface name of PCI device on the host
#     'vendorDevId': vendor and device ID
#
# Side effects:
#     None
#
########################################################################

sub GetPCIDevices
{
   my $self = shift;

   my $command = "lspci -n";

   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to get the list of PCI devices " .
                       "on $self->{hostIP}");
      $vdLogger->Debug("Error" . Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my @lines = split (/\n/, $result->{stdout});

   my @pciList;
   foreach my $line (@lines) {
      #
      # 00:00:07.0 Class 0604: 8086:340e [PCIe RP[00:00:07.0]]
      # 00:00:14.0 Class 0800: 8086:342e
      # 00:00:1f.0 Class 0601: 8086:2918
      # 00:00:1f.2 Class 0101: 8086:2921 [vmhba0]
      #

      # regex to parse a line similar to the example given above
      $line =~ /(.*)\sClass\s(.*):\s(.*?)\s\[(.*)\]/;

      my $pciHash;
      ($pciHash->{bdf}, $pciHash->{class}, $pciHash->{vendorDevId}, $pciHash->{name}) =
        ($1, $2, $3, $4);
      push(@pciList, $pciHash);
   }
   return \@pciList;
}


################################################################################
#
# GetEsxcliNetworkVMList--
#     Method to get network vm list through esxcli command:
#     esxcli network vm list
#
# Input:
#     None.
#
# Results:
#     Returns array reference to network vm list
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
################################################################################

sub GetEsxcliNetworkVMList
{
   my $self   = shift;

   my $command = "esxcli network vm list";
   $vdLogger->Debug("command to get the network vm list through cmd: $command");

   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   $vdLogger->Debug("Network vm list stats:" . Dumper($result));
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to get the network VM statistics");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   return $result->{stdout};
}


################################################################################
#
# GetEsxcliNetworkVMPortList--
#     Method to get network vm port list through esxcli command:
#     esxcli network vm port list
#
# Input:
#     WorldId: World ID for which port list is to be retrieved.
#
# Results:
#     Returns array reference to network vm list
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
################################################################################

sub GetEsxcliNetworkVMPortList
{
   my $self = shift;
   my $worldId = shift;

   if (not defined $worldId) {
      $vdLogger->Error("Workd Id not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $command = "esxcli network vm port list -w $worldId";
   $vdLogger->Debug("command to get the network vm port list through cmd: $command");

   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   $vdLogger->Debug("Network vm port list stats:" . Dumper($result));
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to get the network VM port statistics");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   return $result->{stdout};
}


################################################################################
#
# VerifyEsxcliNetworkVMPortList--
#     Method to verify whether the esxcli command for retrieving network VM port
#     list is accurate
#
# Input:
#     VMName: Name of the VM for which port list is to be verified
#
# Results:
#     SUCCESS, on successful verification
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
################################################################################

sub VerifyEsxcliNetworkVMPortList
{
   my $self = shift;
   my $VMName = shift;

   if (not defined $VMName) {
      $vdLogger->Error("VM Name is not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Retrieving the world Id for the VM name given
   my $result = $self->GetEsxcliNetworkVMList();

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get the VM statistics");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my @lines = split (/\n/, $result);
   my $worldId;

   foreach my $item (@lines) {
      if ($item =~ m/$VMName/) {
         my @vmDetails = split (' ', $item);
         $worldId = $vmDetails[0];
      }
   }

   # Passing world ID to retrieve port list information
   $result = $self->GetEsxcliNetworkVMPortList($worldId);

   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to get the VM port list details");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   #
   # Parsing the output for checking each of the parameters as given below:
   # ~ # esxcli network vm port list -w 133710
   #   Port ID: 33554472
   #   vSwitch: vSwitch0
   #   Portgroup: VM Network
   #   DVPort ID:
   #   MAC Address: 00:0c:29:34:17:ab
   #   IP Address: 10.112.26.14
   #   Team Uplink: vmnic0
   #   Uplink Port ID: 33554434
   #   Active Filters:
   #
   #   Port ID: 50331680
   #   vSwitch: vSwitch1
   #   Portgroup: vdtest
   #   DVPort ID:
   #   MAC Address: 00:50:20:ae:43:e8
   #   IP Address: 0.0.0.0
   #   Team Uplink: void
   #   Uplink Port ID: 0
   #   Active Filters:
   #

   my @output = split (/\n/, $result);

   my $count = 0;
   my $tmpCount;
   my $portId = undef;
   my $vSwitch = undef;
   my $vdsName = undef;
   my $portGroup = undef;
   my $dvPortId = undef;
   my $macAdd = undef;
   my $ipAdd = undef;
   my $teamUplink = undef;
   my $uplinkPortId = undef;
   my $activeFilter = undef;

   while ($output[$count] =~ / Port ID: (\d+)/) {
      $portId = $1;
      my $vds = 0;
      $tmpCount = $count;

      if ($output[$tmpCount+1] =~ / vSwitch: (.*)/) {
         $vSwitch = $1;
      }

      # Checking if portset, port and worlds retrieved are correct
      my $command = "vsish -pe ls /net/portsets/$vSwitch/ports/$portId/worlds/$worldId";
      $vdLogger->Debug("Checking whether the following command is executed: $command");

      $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

      $vdLogger->Debug("World Id info:" . Dumper($result));
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         $vds = 1;
         $vdsName = $vSwitch;
         $vdLogger->Warn("Failed to list the world Id with the given vSwitch name and portId");
         #
         # It could be that the switch name retrieved belongs to a vDS. Checking with its
         # portset name
         #
         $vdLogger->Debug("Retrieving portset name of switch, if exists");
         $vSwitch = $self->GetPortSetNamefromDVS($vSwitch);
         if ($vSwitch eq FAILURE) {
            $vdLogger->Error("No portset exists with the DVS name $vSwitch");
            $vdLogger->Error("Failed to list the world Id with the given vSwitch name and portId");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
         # Checking again, if portset, port and worlds retrieved are correct
         $command = "vsish -pe ls /net/portsets/$vSwitch/ports/$portId/worlds/$worldId";
         $vdLogger->Debug("Checking whether the following command is executed: $command");

         $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                        $command);

         $vdLogger->Debug("World Id info:" . Dumper($result));
         if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
            $vdLogger->Error("Failed to list the world Id with the given vSwitch name and portId");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }

      if ($output[$tmpCount+2] =~ / Portgroup: (.*)/) {
         $portGroup = $1;
      } else {
         $vdLogger->Error("Failed to retrieve port group name from esxcli cmd");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      if ($output[$tmpCount+3] =~ / DVPort ID: (.*)/) {
         $dvPortId = $1;
      } else {
         $vdLogger->Error("Failed to retrieve DVPort ID from esxcli cmd");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      if ($output[$tmpCount+4] =~ / MAC Address: (.*)/) {
         $macAdd = $1;
      } else {
         $vdLogger->Error("Failed to retrieve MAC Address from esxcli cmd");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      # Checking if DVPort ID, PortGroup and MAC Address retrieved are correct
      $command = "vsish -e get /net/portsets/$vSwitch/ports/$portId/status";
      $vdLogger->Debug("Retrieving the correct DVPortID, PortGroup and MAC Address ".
                       "from the following command: $command");

      $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

      $vdLogger->Debug("VSI node info:" . Dumper($result));
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to retrieve DVPortID, PortGroup and MAC Address");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      if ($vds == 1) {
         # Retrieving portgroup name from VDS
         $command = "net-dvs -l $vdsName";
         my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                           $command);

         if ($result->{rc} != 0) {
            $vdLogger->Error("Failed to obtain the net-dvs info for $vSwitch");
            VDSetLastError("ESTAF");
            return FAILURE;
         }

         #
         # The portgroup name information is available in net-dvs output
         #
         if ($result->{stdout} !~ $portGroup) {
            $vdLogger->Error("Failed to retrieve port group name from net-dvs cmd");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      } else {
         # Checking portgroup name of legacy vSwitch
         if ($result->{stdout} =~ / portCfg:(.*)/) {
            if ($portGroup ne $1) {
               $vdLogger->Error("Retrieved portGroup is incorrect");
               VDSetLastError("EFAIL");
               return FAILURE;
            }
         }
      }
      if ($result->{stdout} =~ / dvPortId:(.*)/) {
         if ($dvPortId ne $1) {
            $vdLogger->Error("Retrieved DVPortID is incorrect");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }
      if ($result->{stdout} =~ / fixed Hw Id:(.*)/) {
         if ($1 !~ /$macAdd/i) {
            $vdLogger->Error("Retrieved MAC Address is incorrect");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }

      if ($output[$tmpCount+5] =~ / IP Address: (.*)/) {
         $ipAdd = $1;
      } else {
         $vdLogger->Error("Failed to retrieve IP Address from esxcli cmd");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      # Checking if IP retrieved is correct
      $command = "vsish -e get /net/portsets/$vSwitch/ports/$portId/ip";
      $vdLogger->Debug("Retrieving the correct IP".
                       "from the following command: $command");

      $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

      $vdLogger->Debug("Retrieved IP info:" . Dumper($result));
      my $hexIP;
      if ($result->{stdout} =~ / address:(.*)/) {
         $hexIP = $1;
      } else {
         $vdLogger->Error("Failed to retrieve the correct IP");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      my @esxcliIP = split (/\./, $ipAdd);
      my $octet = 0;
      for (my $i = 8; $i > 1; $i-=2) {
         if ($esxcliIP[$octet] != hex(substr($hexIP,$i,2))) {
            $vdLogger->Error("Octet ".($octet+1)." is incorrect");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
         $octet++;
      }

      if ($output[$tmpCount+6] =~ / Team Uplink: (.*)/) {
         $teamUplink = $1;
      } else {
         $vdLogger->Error("Failed to retrieve team uplink from esxcli cmd");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      # Checking if team uplink retrieved is correct
      $command = "vsish -e get /net/portsets/$vSwitch/ports/$portId/teamUplink";
      $vdLogger->Debug("Retrieving the correct team uplink ".
                       "from the following command: $command");

      $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

      $vdLogger->Debug("Team uplink node info:" . Dumper($result));
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to retrieve correct uplink");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      chomp($result->{stdout});

      if ($teamUplink ne $result->{stdout}) {
         $vdLogger->Error("Retrieved uplink is incorrect");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      if ($output[$tmpCount+7] =~ / Uplink Port ID: (\d+)/) {
         $uplinkPortId = $1;
      } else {
         $vdLogger->Error("Failed to retrieve team uplink port ID from esxcli cmd");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      # Checking if Uplink Port ID retrieved is correct
      $command = "vsish -pe get /net/portsets/$vSwitch/uplinks/$teamUplink/portID";
      $vdLogger->Debug("Retrieving the correct uplink port ID ".
                       "from the following command: $command");

      $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

      $vdLogger->Debug("Team uplink port ID info:" . Dumper($result));
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to retrieve correct uplink port ID");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      chomp($result->{stdout});

      if ($uplinkPortId ne $result->{stdout}) {
         $vdLogger->Error("Retrieved uplink port ID is incorrect");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      #
      # Adding 10 to the counter since the esxcli command displays the next port
      # number after 10 lines
      #
      $count += 10;
   }

   if ($count == 0) {
     $vdLogger->Error("Failed to verify esxcli commands for checking vm port list".
                      " details");
     VDSetLastError("EFAIL");
     return FAILURE;
   }
   return SUCCESS;
}

################################################################################
#
# CreateTCPIPInstance--
#     Method to add a tcpip instance to the host.
#
# Input:
#     arrayOfSpecs: array of spec for netstack
#     Instance: Name of the tcpip instance.
#
# Results:
#     SUCCESS if instance gets created successfully in the host,
#     FAILURE if instance creation fails.
#
# Side effects:
#     A new tcpip instance gets added to the esx host.
#
################################################################################

sub CreateTCPIPInstance
{
   my $self         = shift;
   my $arrayOfSpecs = shift;
   my @arrayOfNetstackObjects;
   my $iteration = 0;

   foreach my $element (@$arrayOfSpecs) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("Netstack spec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $iteration++;
      my %args = %$element;
      my $instance = $args{netstackname} || $args{name};
      my $host = $self->{hostIP};
      my $result;
      my $command;
      if (defined $element->{discover} and $element->{discover} =~ /true/i) {
          if (not defined $instance) {
             $vdLogger->Error("Netstack name is not provided. Need a name " .
                              "to discover it");
             VDSetLastError("ENODEF");
             return FAILURE;
          }
          $command = "$vmknicEsxcliJSON netstack list";
          my $ret = $self->{stafHelper}->STAFSyncProcess($host, $command);
          if (($ret->{rc} != 0) || ($ret->{exitCode} != 0)) {
             $vdLogger->Error("Failed to get the netstack list on host $host");
             $vdLogger->Error(Dumper($ret));
             VDSetLastError("EFAIL");
             return FAILURE;
          }
          my $parsedData = VDNetLib::Common::Utilities::ConvertJSONDataToHash(
             $ret->{stdout});
          my $discovered = 0;
          foreach my $hash (@$parsedData) {
              if ($hash->{Key} eq $instance) {
                  $discovered = 1;
                  last;
              }
          }
          if (not $discovered) {
             $vdLogger->Error("Netstack instance $instance is not found on " .
                              "the host $host");
             return FAILURE;
          }
      } else {
          if (not defined $instance) {
             $instance = VDNetLib::Common::Utilities::GenerateName(
                 "netstack-vdtest", "$iteration-" . int(rand(100)));
          }
          $command = "$vmknicEsxcli netstack add -N $instance";
          $vdLogger->Debug("Execute command $command on host $host");
          $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
          if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
             $vdLogger->Error("Failed to create new tcpip instance " .
                              "$instance on host $host");
             $vdLogger->Error(Dumper($result));
             VDSetLastError("EFAIL");
             return FAILURE;
          }
      }
      my $netstackObj = VDNetLib::Host::Netstack->new(
                                           'hostObj'    => $self,
                                           'netstack'   => $instance,
                                           'stafHelper' => $self->{stafHelper}
                                           );
      if ($netstackObj eq FAILURE) {
         $vdLogger->Error("Failed to creat VDNetLib::Host::Netstack for: ".
                          $instance);
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      push @arrayOfNetstackObjects, $netstackObj;
   }
   return \@arrayOfNetstackObjects;
}


################################################################################
#
# RemoveTCPIPInstance--
#     Method to remove a tcpip instance to the host.
#
# Input:
#     arrayOfObjects: Array of netstack objects.
#     remove        : flag to specify if we really want to delete netstack.
#
# Results:
#     SUCCESS if instance gets removed successfully in the host,
#     FAILURE if instance creation fails.
#
# Side effects:
#     A new tcpip instance gets removed from the esx host.
#
################################################################################

sub RemoveTCPIPInstance
{
   my $self = shift;
   my $arrayOfObjects = shift;
   my $host = $self->{hostIP};
   my $errorCount = 0;
   my $result;
   my $command;

   if (not defined $arrayOfObjects) {
      $vdLogger->Error("Tcpip instance to be removed not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   foreach my $netstackObj(@$arrayOfObjects) {
      my $instance = $netstackObj->{netstackName};
      $command = "$vmknicEsxcli netstack remove -N $instance";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to remove tcpip instance $instance");
         $vdLogger->Error(Dumper($result));
         VDSetLastError("EFAIL");
         $errorCount++;
         next;
      }
   }
   if ($errorCount ne 0) {
      return FAILURE;
   } else {
      $vdLogger->Debug("Removing TCPIP instances successful");
      return SUCCESS;
   }
}

################################################################################
#
# UpdateVCObj--
#     Method to update the VC information accosicated with this host.
#
# Input:
#     vcObj: VC Object or undef.
#
# Results:
#     SUCCESS if vcObj gets updated successfully in the host,
#     FAILURE if any error occurs.
#
# Side effects:
#     None
#
################################################################################

sub UpdateVCObj
{
   my $self  = shift;
   my $vcObj = shift;

   $self->{vcObj} = $vcObj;

   return SUCCESS;
}


################################################################################
#
# UpdateCurrentVMAnchor--
#     Method to update the current STAF VM anchor information
#     accosicated with this host.
#
# Input:
#     stafAnchor: STAF Anchor.
#
# Results:
#     SUCCESS if Current STAF VM anchor gets updated successfully in the host,
#     FAILURE if any error occurs.
#
# Side effects:
#     None
#
################################################################################

sub UpdateCurrentVMAnchor
{
   my $self       = shift;
   my $stafAnchor = shift;

   if (defined $stafAnchor) {
      $self->{stafVMAnchor} = $stafAnchor;
   }

   return SUCCESS;
}


################################################################################
#
# GetInlineHostObject--
#     Method to get inline host object.
#
# Input:
#     None
#
# Results:
#     returns object of VDNetLib::InlineJava::Host.
#
# Side effects:
#     None
#
################################################################################

sub GetInlineHostObject
{
   my $self   = shift;
   my $anchor = shift;
   if (not defined $anchor) {
      if (defined $self->{vcObj}) {
         my $inlineVCSession = $self->{vcObj}->GetInlineVCSession();
         $anchor = $inlineVCSession->{'anchor'};
      } else {
         my $inlineHostSession = $self->GetInlineHostSession();
         $anchor = $inlineHostSession->{'anchor'};
      }
   }
   return VDNetLib::InlineJava::Host->new(host => $self->{hostIP},
                                          user => $self->{userid},
                                          anchor => $anchor,
                                          password => $self->{sshPassword}
                                          );
}


########################################################################
#
# GetInlineHostSession --
#     Method to create an instance of
#     VDNetLib::InlineJava::SessionManager based on Host parameters
#
# Input:
#     None
#
# Results:
#     return value of new() in VDNetLib::InlineJava::SessionManager
#
# Side effects:
#     None
#
########################################################################

sub GetInlineHostSession
{
   my $self = shift;
   return VDNetLib::InlineJava::SessionManager->new($self->{hostIP},
                                                    $self->{userid},
                                                    $self->{sshPassword}
                                                   );
}


################################################################################
#
# VerifyRSSFunctionality --
#      Method to verify whether the VMKTCPIP RSS functionality on a vmnic
#      present in an ESX host is working as expected.
#
# Input:
#      vmnicArray - List of pNIC obj refs to be worked upon. [MANDATORY]
#      vmknicArray- Either a list of MAC Addresses of the vmknics that are
#                   receiving traffic OR a list of the indexes (obtained from
#                   the VDNetv2 framework) of the vmknics that are receiving
#                   traffic, separated by a double semi-colon (";;") [MANDATORY]
#      RSSQueue   - RSS supported queue number, that is a constant across the
#                   NICs being checked. [MANDATORY]
#      SleepBetweenCombos - Parameter for taking in the sleep period, afer
#                           which the RSS verification will start. This period
#                           should be set by the user and will be a number to
#                           indicate start of the RSS analysis AFTER all the
#                           filters / queues have been populated. [OPTIONAL]
#
# Results:
#      SUCCESS if RSS is working fine on host
#      FAILURE, if any error
#
# Side effects:
#      None.
#
# Notes:
#      The following assumptions have been made for this module to be run on any
#      setup that has RSS supported NICs-
#      1. RSS should be tested with traffic flowing towards vmknics on the
#         receive side, so it's recommended to have at least 2 streams of
#         traffic flowing during verification of the feature.
#      2. The RSS supported NICs should be connected to each other via a
#         10G setup
#
################################################################################

sub VerifyRSSFunctionality
{
   my $self = shift;
   my $vmnicArray = shift; # Taking in NIC obj refs as an array
   my $vmknicArray = shift; # Taking in vmknics as an array
   my $rssQueueNum = shift; # Taking RSS queue number as a scalar
   my $sleepBetweenCombos = shift || undef;
   my $singleQueue = undef; # Denotes if single RSS queue is to be used
   my @RSSQueueMACCount = (); # Stores number of RSS MACs for each NIC
   my @defQueueMACCount = (); # Stores number of def queue MACs for each NIC
   my @nonDefQueueMACCount = (); # Stores number of non-def queue MACs for each NIC
   my @RSSDetectedMACCount = (); # Stores number of RSS queue detected vmknics
   my @totalMACCount = (); # Stores number of total MACs in all queues for each NIC
   my $numFilters = undef; # Stores number of total filters in each NIC
   my $maxQueues = undef; # Stores number of max supported queues in each NIC
   my $totalRSSQueueMACCount = 0; # Stores total # of MACs carried by RSS queues

   if ((not defined $vmnicArray) || (not defined $vmknicArray) ||
       (not defined $rssQueueNum)) {
      $vdLogger->Error("Parameters not passed to VerifyRSSFunctionality method");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (defined $sleepBetweenCombos) {
      $vdLogger->Info("Sleeping for $sleepBetweenCombos seconds before starting".
                      " RSS analysis on host $self->{hostIP}");
      sleep($sleepBetweenCombos);
   }

   # Storing total number of adapters
   my $numVmknic = $#$vmknicArray+1;
   my $numVmnic = $#$vmnicArray+1;
   my $lc = 0;

   # Verifying RSS functionality for all vmnics
   my $rssFuncResults = $self->VerifyRSSFunctionalityForVmnics({
                                  'vmnicArray' => $vmnicArray,
                                  'rssQueueNum' => $rssQueueNum,
                                  'vmknicArray' => $vmknicArray,});
   if ($rssFuncResults eq FAILURE) {
      $vdLogger->Error("Verification of RSS functionality for Vmnics failed");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # Storing returned variables in local variables, for easy management
   @totalMACCount = @{$rssFuncResults->{totalMACCount}};
   $numFilters = $rssFuncResults->{numFilters};
   $maxQueues = $rssFuncResults->{maxQueues};
   @RSSDetectedMACCount = @{$rssFuncResults->{RSSDetectedMACCount}};
   @RSSQueueMACCount = @{$rssFuncResults->{RSSQueueMACCount}};
   @defQueueMACCount = @{$rssFuncResults->{defQueueMACCount}};
   @nonDefQueueMACCount = @{$rssFuncResults->{nonDefQueueMACCount}};
   $totalRSSQueueMACCount = $rssFuncResults->{totalRSSQueueMACCount};

   # Checking whether all the NICs have retrieved the same number of MACs
   if ($numVmnic > 1) {
      @totalMACCount = sort(@totalMACCount);
      if ($totalMACCount[0] != $totalMACCount[-1]) {
         $vdLogger->Error("Number of MACs retrieved in all the vmnics are not ".
                          "the same");
         for ($lc = 0; $lc < $numVmnic; $lc++) {
            $vdLogger->Error("Number of MACs for vmnic $vmnicArray->[$lc]->{vmnic} = ".
                             "$totalMACCount[$lc]");
         }
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }

   #
   # If there's only 1 uplink that's carrying the load, then checking whether all
   # vmknics should be receiving through 1 single RSS queue, assuming that the number
   # of RSS filters is more than the number of vmknics. If the number of vmknics is
   # more than the number of RSS supported filters, then vmknics
   # can receive through multiple queues even though the RSS queue isn't saturated.
   #
   # However, if the number of uplinks is more than 1, then we have to check whether
   # the number of vmknics receiving traffic is more or less than the number of
   # RSS filters. If less, then none of the non-RSS queues should be populated. If
   # more, then the non-RSS filters can get populated.
   #
   my $numFiltersPerQ = $numFilters / ($maxQueues - 1);
   my $rssParamCountResults = $self->VerifyRSSParamCounts({
                                 'RSSDetectedMACCount' => \@RSSDetectedMACCount,
                                 'RSSQueueMACCount' => \@RSSQueueMACCount,
                                 'vmnicArray' => $vmnicArray,
                                 'numFiltersPerQ' => $numFiltersPerQ,
                                 'numVmknic' => $numVmknic,
                                 'totalMACCount' => \@totalMACCount,
                                 'defQueueMACCount' => \@defQueueMACCount,
                                 'nonDefQueueMACCount' => \@nonDefQueueMACCount,
                                 'totalRSSQueueMACCount' => $totalRSSQueueMACCount,});
   if ($rssParamCountResults eq FAILURE) {
      $vdLogger->Error("Verification of RSS parameter counts failed");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}


################################################################################
#
# GetOpenPortType --
#      Method to retrieve open port type from vsish node after taking port num
#      as an input
#
# Input:
#      PortNum    - Number of port from which the port type is to be retrieved
#                   [MANDATORY]
#
# Results:
#      Hash with the port type information, if successful
#      FAILURE, if any error
#
# Side effects:
#      None.
#
################################################################################

sub GetOpenPortType
{
   my $self = shift;
   my $portNum = shift;

   if (not defined $portNum) {
      $vdLogger->Error("Port number not passed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # command to retrieve port type
   my $command = "vsish -pe get /net/openPorts/$portNum/type";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to retrieve port type failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Return port type as a hash
   $result->{stdout} = VDNetLib::Common::Utilities::ProcessVSISHOutput(
                                         RESULT => $result->{stdout}
                                         );
   if ($result->{stdout} ne FAILURE) {
      return $result->{stdout};
   } else {
      $vdLogger->Error("Unable to change output to hash");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}


################################################################################
#
# VerifyRSSParamCounts --
#      Method to check whether the retreived RSS parameter values / counts are
#      authentic and correct.
#
# Input:
#      RSSDetectedMACCount   - number of MACs detected on an RSS supported pNIC.
#                              [MANDATORY]
#      RSSQueueMACCount      - number of MACs detected over RSS queues, taken as
#                              an array over all pNICs. [MANDATORY]
#      vmnicArray            - array of vmnic objects used here. [MANDATORY]
#      numFiltersPerQ        - number of filters per queue. [MANDATORY]
#      numVmknic             - number of vmknics receiving traffic. [MANDATORY]
#      totalMACCount         - total number of MACs detected over all pNICs.
#                              [MANDATORY]
#      defQueueMACCount      - number of MACs detected in the default queues.
#                              [MANDATORY]
#      nonDefQueueMACCount   - number of MACs detected in the non-default queues.
#                              [MANDATORY]
#      totalRSSQueueMACCount - total number of MACs detected over all RSS queues.
#                              [MANDATORY]
#
# Results:
#      SUCCESS, if successful
#      FAILURE, if any error
#
# Side effects:
#      None.
#
################################################################################

sub VerifyRSSParamCounts
{
   my $self = shift;
   my $args = shift;
   my @RSSDetectedMACCount = @{$args->{RSSDetectedMACCount}};
   my @RSSQueueMACCount = @{$args->{RSSQueueMACCount}};
   my $vmnicArray = $args->{vmnicArray};
   my $numFiltersPerQ = $args->{numFiltersPerQ};
   my $numVmknic = $args->{numVmknic};
   my @totalMACCount = @{$args->{totalMACCount}};
   my @defQueueMACCount = @{$args->{defQueueMACCount}};
   my @nonDefQueueMACCount = @{$args->{nonDefQueueMACCount}};
   my $totalRSSQueueMACCount = $args->{totalRSSQueueMACCount};
   my $numVmnic = $#$vmnicArray+1;

   #
   # If there's only 1 uplink that's carrying the load, then checking whether all
   # vmknics should be receiving through 1 single RSS queue, assuming that the number
   # of RSS filters is more than the number of vmknics. If the number of vmknics is
   # more than the number of RSS supported filters, then vmknics
   # can receive through multiple queues even though the RSS queue isn't saturated.
   #
   # However, if the number of uplinks is more than 1, then we have to check whether
   # the number of vmknics receiving traffic is more or less than the number of
   # RSS filters. If less, then none of the non-RSS queues should be populated. If
   # more, then the non-RSS filters can get populated.
   #
   if ($numVmnic == 1) {
      if ($RSSDetectedMACCount[0] != $RSSQueueMACCount[0]) {
         $vdLogger->Error("Number of MACs of vmknics $numVmknic present in the ".
                          "RSS Queue $RSSQueueMACCount[0] is not equal to the number of ".
                          "vmknics detected in the RSS queue $RSSDetectedMACCount[0], ".
                          "for vmnic $vmnicArray->[0]->{vmnic}");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      if ($numFiltersPerQ > $numVmknic) {
         if ($totalMACCount[0] != $RSSQueueMACCount[0]) {
            $vdLogger->Error("Since the # of RSS filters $numFiltersPerQ is more than ".
                             "the # of vmknics $numVmknic, the total MAC count ".
                             "$totalMACCount[0] should be equal to the # of MACs ".
                             "in the RSS queue $RSSQueueMACCount[0] for vmnic $vmnicArray->[0]->{vmnic}");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      } elsif ($numFiltersPerQ < $numVmknic) {
         if ($totalMACCount[0] != $RSSQueueMACCount[0] + $defQueueMACCount[0] + $nonDefQueueMACCount[0]) {
            $vdLogger->Error("Since the # of RSS filters $numFiltersPerQ is lesser than ".
                             "the # of vmknics $numVmknic, the total MAC count ".
                             "$totalMACCount[0] should be equal to the # of MACs ".
                             "in the RSS queue $RSSQueueMACCount[0] plus the # of MACs ".
                             "in the default queue $defQueueMACCount[0] plus the # of ".
                             "MACs in the non-def queue $nonDefQueueMACCount[0], for vmnic ".
                             "$vmnicArray->[0]->{vmnic}");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }
   } else {
      # Checking for results when # of vmnics > 1
      for (my $lc = 0; $lc < $numVmnic; $lc++) {
         if ($RSSDetectedMACCount[$lc] != $RSSQueueMACCount[$lc]) {
            $vdLogger->Error("Number of MACs of vmknics $numVmknic present in the ".
                             "RSS Queue $RSSQueueMACCount[$lc] is not equal to the number of ".
                             "vmknics detected in the RSS queue $RSSDetectedMACCount[$lc], ".
                             "for vmnic $vmnicArray->[$lc]->{vmnic}");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
         if (($numFiltersPerQ * $numVmnic) > $numVmknic) {
            #
            # Since the total # of RSS filters over all vmnics is more than the # of
            # vmknics receiving traffic, each NIC should carry the vmknics MACs only
            # in the RSS supported queues
            #
            if ($totalMACCount[$lc] != $totalRSSQueueMACCount) {
               $vdLogger->Error("Since the total # of RSS filters ".($numFiltersPerQ * $numVmnic)." is more than ".
                                "the # of vmknics $numVmknic, the total MAC count ".
                                "$totalMACCount[$lc] per vmnic should be equal to the # of MACs ".
                                "for all the RSS queues $totalRSSQueueMACCount for vmnic ".
                                "$vmnicArray->[$lc]->{vmnic}");
               VDSetLastError("EFAIL");
               return FAILURE;
            }
         } else {
            #
            # Since the total # of RSS filters over all vmnics is lesser than the # of
            # vmknics receiving traffic, each NIC can carry the vmknic MACs over RSS and
            # non-RSS queues. Therefore, the total number of MACs over each NIC should equal
            # the total number of vmknics receiving traffic
            #
            if ($totalMACCount[$lc] != $numVmknic) {
               $vdLogger->Error("Since the total # of RSS filters $numFiltersPerQ is lesser than ".
                                "the # of vmknics $numVmknic, the total MAC count ".
                                "$totalMACCount[$lc] per vmnic should be equal to the # of vmknics ".
                                "receiving traffic, for vmnic $vmnicArray->[$lc]->{vmnic}");
               VDSetLastError("EFAIL");
               return FAILURE;
            }
         }
      }
   }
   return SUCCESS;
}


################################################################################
#
# VerifyRSSFunctionalityForVmnics --
#      Method to verify whether the VMKTCPIP RSS functionality on a vmnic
#      present in an ESX host is working as expected.
#
# Input:
#      vmnicArray  - List of pNIC names in an array, passed from function
#                    "VerifyRSSFunctionality". [MANDATORY]
#      vmnicObj    - Objects of the vmnics that are being worked upon. [MANDATORY]
#      rssQueueNum - RSS supported queue number, that is a constant across the
#                    NICs being checked. [MANDATORY]
#      vmknicArray - Array of MACs of vmknics, passed from function
#                    "VerifyRSSFunctionality". [MANDATORY]
#
# Results:
#      If successful, returns the following values in a hash under the respective
#      keys:
#         totalMACCount         - total number of MACs detected per pNIC
#         numFilters            - Number of filters detected over all pNICs
#         maxQueues             - Max queues detected over all pNICs
#         RSSDetectedMACCount   - number of RSS supported MACs detected
#         RSSQueueMACCount      - number of MACs detected over all RSS queues
#         defQueueMACCount      - number of MACs detected over all default queues
#         nonDefQueueMACCount   - number of MACs detected over all non-default queues
#         totalRSSQueueMACCount - total number of MACs detected on RSS supported pNICs
#
#      FAILURE, if any error
#
# Side effects:
#      None.
#
# Notes:
#      Currently, this function is an internal function that's being called by
#      its parent function "VerifyRSSFunctionality", so if the RSS functionality
#      is to be verified, only the parent function is to be called externally.
#
################################################################################

sub VerifyRSSFunctionalityForVmnics
{
   my $self = shift;
   my $args = shift;
   my $vmnicArray = $args->{vmnicArray};
   my $rssQueueNum = $args->{rssQueueNum};
   my $vmknicArray = $args->{vmknicArray};
   my $numVmknic = $#$vmknicArray+1;
   my $resultsHash = {};
   my @RSSQueueMACCount = (); # Stores number of RSS MACs for each NIC
   my @defQueueMACCount = (); # Stores number of def queue MACs for each NIC
   my @nonDefQueueMACCount = (); # Stores number of non-def queue MACs for each NIC
   my @RSSDetectedMACCount = (); # Stores number of RSS queue detected vmknics
   my @totalMACCount = (); # Stores number of total MACs in all queues for each NIC
   my $numFilters = undef; # Stores number of total filters in each NIC
   my $maxQueues = undef; # Stores number of max supported queues in each NIC
   my $totalRSSQueueMACCount = 0; # Stores total # of MACs carried by RSS queues
   my $lc = 0; # Initializing loop count

   # Verifying RSS functionality for all vmnics
   foreach my $vmnicObj (@{$vmnicArray}) {
      #
      # Checking whether the NICs support RSS
      #
      my $supportRSS = $vmnicObj->GetRSSInfo("supported",$rssQueueNum);
      if ($supportRSS eq FAILURE) {
         $vdLogger->Error("Vmnic $vmnicObj->{vmnic} does not support RSS");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      chomp($supportRSS);

      #
      # Checking basic RSS support values on each vmnic
      # Retrieving Ind table values
      #
      my $indTable = $vmnicObj->GetRSSInfo("indTable",$rssQueueNum);
      if ($indTable eq FAILURE) {
         $vdLogger->Error("Unable to retrieve indTable for Vmnic $vmnicObj->{vmnic}");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      # Counting the number of entries in the indTable
      my $indTableCount = 0;
      my @indTable = split(/\n/,$indTable);
      foreach my $tmp (@indTable) {
         if ($tmp =~ /Idx/i) {
            $indTableCount++;
         }
      }

      # Retrieving Ind table size
      my $indTableSize = $vmnicObj->GetRSSInfo("indTableSize",$rssQueueNum);
      if ($indTableSize eq FAILURE) {
         $vdLogger->Error("Unable to retrieve indTableSize for Vmnic $vmnicObj->{vmnic}");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      chomp($indTableSize);
      if ($indTableSize != $indTableCount) {
         $vdLogger->Error("Retrieved indTable size $indTableCount doesn't match with the one ".
                          "printed in the vsi node: $indTableSize");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      # Retrieving Hash key values
      my $hashKey = $vmnicObj->GetRSSInfo("hashKey",$rssQueueNum);
      if ($hashKey eq FAILURE) {
         $vdLogger->Error("Unable to retrieve hashKey for Vmnic $vmnicObj->{vmnic}");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      # Counting the number of entries in the hashKey table
      my $hashKeyCount = 0;
      my @hashKey = split(/ /,$hashKey);
      foreach my $tmp (@hashKey) {
         if ($tmp =~ /.x./i) {
            $hashKeyCount++;
         }
      }

      # Retrieving hash key size
      my $hashKeySize = $vmnicObj->GetRSSInfo("hashKeySize",$rssQueueNum);
      if ($hashKeySize eq FAILURE) {
         $vdLogger->Error("Unable to retrieve hashKey size for Vmnic $vmnicObj->{vmnic}");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      chomp($hashKeySize);
      if ($hashKeySize != ($hashKeyCount)) {
         $vdLogger->Error("Retrieved hashKey size $hashKeyCount doesn't match with the one ".
                          "printed in the vsi node: $hashKeySize");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      # Retrieving the number of Hw RSS queues
      my $numHwRSSQueues = $vmnicObj->GetRSSInfo("numHwRSSQueues",$rssQueueNum);
      if ($numHwRSSQueues eq FAILURE) {
         $vdLogger->Error("Unable to retrieve numHwRSSQueues for Vmnic $vmnicObj->{vmnic}");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      chomp($numHwRSSQueues);

      # Initializing filter counters for all the queues
      $RSSQueueMACCount[$lc] = 0;
      $defQueueMACCount[$lc] = 0;
      $nonDefQueueMACCount[$lc] = 0;
      $RSSDetectedMACCount[$lc] = 0;
      #
      # Checking RSS support values on each vmnic
      # Retrieving Rx Queue info from each vmnic
      #
      $maxQueues = $vmnicObj->RxQueueInfo("maxQueues",$vmnicObj->{vmnic});
      if ($maxQueues eq FAILURE) {
         $vdLogger->Error("Unable to retrieve max Rx queues for $vmnicObj->{vmnic}");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      $numFilters = $vmnicObj->RxQueueInfo("numFilters",$vmnicObj->{vmnic});
      if ($numFilters eq FAILURE) {
         $vdLogger->Error("Unable to retrieve num of filters for $vmnicObj->{vmnic}");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      my $numActiveFilters = $vmnicObj->RxQueueInfo("numActiveFilters",
                                                    $vmnicObj->{vmnic});
      if ($numActiveFilters eq FAILURE) {
         $vdLogger->Error("Unable to retrieve num of active filters for $vmnicObj->{vmnic}");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      # Retrieving the queues being used for this NIC
      my $rxQueueNum = $vmnicObj->GetRxQueues($vmnicObj->{vmnic});
      if ($rxQueueNum eq FAILURE) {
         $vdLogger->Error("Unable to retrieve Rx queue numbers for NIC $vmnicObj->{vmnic}");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      # Checking whether the MAC is present in the non-RSS supported queues
      foreach my $queueNum (@{$rxQueueNum}) {
         chop($queueNum);
         # Getting a list of the filters present per queue
         my $listFilters = $vmnicObj->GetRxQueueFilters($queueNum,$vmnicObj->{vmnic});
         if ($listFilters eq FAILURE) {
            $vdLogger->Error("Unable to retrieve list of filters for ".
                             "$vmnicObj->{vmnic}");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
         # Checking each filter for the MAC
         foreach my $filter (@{$listFilters}) {
            # Retrieving the MAC for this filter
            chop($filter);
            my $rxFilterHash = $vmnicObj->RxFilterInfo({
                                   'rxqid' => $queueNum,
                                   'rxfilterid' => $filter,
                                   'vmnic' => $vmnicObj->{vmnic},});
            if ($rxFilterHash eq FAILURE) {
               $vdLogger->Error("Unable to retrieve Rx Filter info for NIC ".
                                "$vmnicObj->{vmnic}");
               VDSetLastError("EFAIL");
               return FAILURE;
            }
            #
            # Checking port type of filter retrieved and counting for RSS queue
            # detected vmknics
            #
            my $portType = $self->GetOpenPortType($rxFilterHash->{portID});
            if ($portType eq FAILURE) {
               $vdLogger->Error("Unable to retrieve port type for NIC ".
                                "$vmnicObj->{vmnic}");
               VDSetLastError("EFAIL");
               return FAILURE;
            }
            # Port type 3 denotes vmknic
            if (($portType->{portType} == 3) &&
                ($queueNum == $rssQueueNum)) {
               $RSSDetectedMACCount[$lc]++;
            }
            my $retrievedMAC = undef;
            # Converting MAC from Dec to Hex
            foreach my $tmp (@{$rxFilterHash->{unicastAddr}}) {
               my $hexValue = substr((sprintf("%x",$tmp)),-2);
               if (length($hexValue) < 2) {
                  $hexValue = "0".$hexValue;
               }
               $retrievedMAC .= $hexValue.":";
            }
            chop($retrievedMAC);

            # Checking whether the retrieved MAC is one of the vmknics
            foreach my $vmknicMac (@{$vmknicArray}) {
               if ($retrievedMAC =~ /$vmknicMac/i) {
                  if ($queueNum == $rssQueueNum) {
                     if ($portType->{portType} != 3) { # Port type 3 denotes vmknic
                        $vdLogger->Error("Detected non-RSS port type for port $portType->{portType}".
                                         " in filter $filter queue $queueNum vmnic $vmnicObj->{vmnic}");
                        VDSetLastError("EFAIL");
                        return FAILURE;
                     }
                     $RSSQueueMACCount[$lc]++;
                  } elsif ($queueNum == 0) {
                     $defQueueMACCount[$lc]++;
                  } else {
                     $nonDefQueueMACCount[$lc]++;
                  }
               }
            }
         }
      }

      # Checking whether all MACs retrieved account for all the vmknics
      if ($numVmknic != ($RSSQueueMACCount[$lc] + $defQueueMACCount[$lc] + $nonDefQueueMACCount[$lc])) {
         $vdLogger->Error("Number of MACs of vmknics $numVmknic present is not ".
                          "equal to the number of MACs $RSSQueueMACCount[$lc] present in ".
                          "the RSS queue plus the number of MACs $nonDefQueueMACCount[$lc] ".
                          "present in the non-default queue plus the number of MACs ".
                          "$defQueueMACCount[$lc] present in the default queue in vmnic ".
                          "$vmnicObj->{vmnic}");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      $vdLogger->Debug("Number of MACs of vmknics $numVmknic present is ".
                       "equal to the number of MACs $RSSQueueMACCount[$lc] present in ".
                       "the RSS queue plus the number of MACs $nonDefQueueMACCount[$lc] ".
                       "present in the non-default queue plus the number of MACs ".
                       "$defQueueMACCount[$lc] present in the default queue in vmnic ".
                       "$vmnicObj->{vmnic}");

      # Storing the numbers in separate variables to be used later
      $totalMACCount[$lc] = $RSSQueueMACCount[$lc] + $defQueueMACCount[$lc] + $nonDefQueueMACCount[$lc];
      $totalRSSQueueMACCount = $totalRSSQueueMACCount + $RSSQueueMACCount[$lc];
      $lc++;
   }
   $resultsHash->{totalMACCount} = \@totalMACCount;
   $resultsHash->{numFilters} = $numFilters;
   $resultsHash->{maxQueues} = $maxQueues;
   $resultsHash->{RSSDetectedMACCount} = \@RSSDetectedMACCount;
   $resultsHash->{RSSQueueMACCount} = \@RSSQueueMACCount;
   $resultsHash->{defQueueMACCount} = \@defQueueMACCount;
   $resultsHash->{nonDefQueueMACCount} = \@nonDefQueueMACCount;
   $resultsHash->{totalRSSQueueMACCount} = $totalRSSQueueMACCount;

   return $resultsHash;
}


########################################################################
#
# AddLocalVDR
#      This method adds one local vdr instance. Takes either array of spec or
#      just one spec and creates vdr instances accordingly.
#
# Input:
#      Below are all optional params that can be set while creating vdr
#      name
#
# Results:
#      "vdrObject", if vdr creation is successful
#      "FAILURE", in case of any error,
#
# Side effects:
#      the mirror session gets created for the vds.
#
########################################################################

sub AddLocalVDR
{
   my $self = shift;
   my $firstElement = $_[0];
   my @specArray;
   if ((defined $firstElement) && ($firstElement =~ /ARRAY/)) {
      @specArray = @$firstElement;
   } else {
      my %options = @_;
      @specArray = (\%options);
   }
   my ($vdrObject, @arrayOfVDRObjects);

   foreach my $element (@specArray) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("VDR spec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my %options = %$element;
      #
      # 1) Create a VDR.pm vdnet Object
      # 2) Add the vdr instance on host using AddInstanceOnHost()
      # 3) return the vdnet vdr object.
      #
      $options{hosts} = [$self->{hostIP}];
      $options{hostObj} = $self;
      $options{stafHelper} = $self->{stafHelper};

      my $vdrModule = "VDNetLib::Router::VDR";
      eval "require $vdrModule";
      if ($@) {
         $vdLogger->Error("Failed to load package $vdrModule $@");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $vdrObject = $vdrModule->new(%options);
      if (not defined $vdrObject) {
         $vdLogger->Error("Not able to create VDNetLib::Router::VDR obj");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      $vdLogger->Debug("VDR Object is created, now creating VDR physically");
      my $ret = $vdrObject->AddInstanceOnHost();
      if ($ret ne SUCCESS) {
         $vdLogger->Error("AddPhysicalInstance failed");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      $vdLogger->Info("Added vdr:$vdrObject->{name} to host:$self->{hostIP}");
      push(@arrayOfVDRObjects, $vdrObject);
   }
   return \@arrayOfVDRObjects;
}


########################################################################
#
# RemoveLocalVDR
#      This method add local vdr instance.
#
# Input:
#      Below are all optional params that can be set while creating vdr
#      name
#
# Results:
#      "vdrObject", if vdr creation is successful
#      "FAILURE", in case of any error,
#
# Side effects:
#      the mirror session gets created for the vds.
#
########################################################################

sub RemoveLocalVDR
{
   my $self = shift;
   my $firstElement = $_[0];
   my @specArray;
   if ($firstElement =~ /ARRAY/) {
      @specArray = @$firstElement;
   } else {
      my $obj = shift;
      @specArray = ($obj);
   }
   my ($vdrObject, @arrayOfVDRObjects);
   foreach my $element (@specArray) {
      my $vdrObject = $element;
      my $ret = $vdrObject->DeleteInstanceOnHost();
      if ($ret ne SUCCESS) {
         $vdLogger->Error("DeleteInstanceOnHost failed");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      $vdLogger->Info("Removed vdr:$vdrObject->{name} from host:" .
                      $self->{hostIP});
   }
   return SUCCESS;
}


########################################################################
#
# GetAdapterInfo --
#      Method to get everything about vmknic
#
# Input:
#      deviceId: vmkX of which to get info
#
# Results:
#      A hash of vmknic
#      "FAILURE", in case of any error.
#
# Side effects:
#  None
#
########################################################################

sub GetAdapterInfo
{
   my $self = shift;
   my %args = @_;
   my $deviceId = $args{deviceId};

   if (not defined $deviceId) {
      $vdLogger->Error("vmknic not passed");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $inlineHostObject = $self->GetInlineHostObject();
   my $vmknicInfoHash = $inlineHostObject->GetHostVirtualNic(
						deviceId => $deviceId
							    );
   if (!$vmknicInfoHash) {
      $vdLogger->Error("Failed to get info for vmknic:$deviceId");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return $vmknicInfoHash;
}


########################################################################
#
# DestroyVMs --
#     Method to destroy all VMs matching the given pattern in name.
#     If matchingName pattern is not given, then all VMs will be
#     destroyed.
#
# Input:
#     matchingNames  : pattern/string that should be matched
#
# Results:
#     SUCCESS, if all VMs are destroyed successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     All the VMs on the host will be deleted
#
########################################################################

sub DestroyVMs
{
   my $self          = shift;
   my $matchingNames = shift;

   $vdLogger->Debug("Destroying VMs matching $matchingNames");
   my $inlineHostObject = $self->GetInlineHostObject();
   if (!$inlineHostObject->DestroyVMs($matchingNames)) {
      $vdLogger->Error("Failed to delete VMs matching $matchingNames");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return SUCCESS;
};


#######################################################################
#
# ReturnVMXPathIfVMExists --
#   For a given vm name, return the vmx path
#     e.g.: /vmfs/volumes/datastore1/vdtest-007/VM-1/rhel-53-srv-XYZ.vmx
#
# Input:
#   matchingNames: find the vmx path for the vm name.
#
# Results:
#     SUCCESS, retuns the constructed path of vmx;
#     FAILURE, in case of any error;
#
# Side effects:
#
#########################################################################

sub ReturnVMXPathIfVMExists
{
   my $self          = shift;
   my $matchingNames = shift;
   my $vmxPath = "FAILURE";

   my $inlineHostSession = $self->GetInlineHostSession();
   my $anchor = $inlineHostSession->{'anchor'};
   my $inlineHostObject = $self->GetInlineHostObject($anchor);
   $vmxPath = $inlineHostObject->ReturnVMXPathIfVMExists($matchingNames);
   if (!$vmxPath) {
      $vdLogger->Error("Failed to find vmx path matching $matchingNames");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return $vmxPath;
};


########################################################################
# SetMaintenanceMode --
#      This method enable/disable Maintenance Mode on Host
#
# Input:
#      MaintenanceMode (true/false)
#
# Results:
#      Return  "SUCCESS" if command pass
#      Returns "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub SetMaintenanceMode
{
   my $self = shift;
   my $maintenanceMode  = shift;

   # if not defined, we will enable maintenance mode
   if ((not defined $maintenanceMode)){
      $maintenanceMode = "true";
   }

   my $command = "esxcli system maintenanceMode get";
   $vdLogger->Debug("command:" .$command );
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
     $vdLogger->Error("Failed to execute command $command on " .
                       Dumper($result));
     return FAILURE;
   }
   # check  maintenance mode before enable/disable
   if ( ($result->{stdout} =~ /Enabled/i) && ($maintenanceMode eq "true")) {
      $vdLogger->Debug("MaintenanceMode already set to true" . Dumper($result) );
      return SUCCESS;
   } elsif ( ($result->{stdout} =~ /Disabled/i) && ($maintenanceMode eq "false") ){
      $vdLogger->Debug("MaintenanceMode already set to false" . Dumper($result) );
      return SUCCESS;
   }

   $command = "esxcli system maintenanceMode set --enable $maintenanceMode ";

   $vdLogger->Debug("Set MaintenanceMode on " . $self->{hostIP} . ":". $command );
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to execute command $command on " .
                    Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}

########################################################################
#
# ConfigureIPSecSecurityAssociation --
#      Method to configure the ipsec SA
#
# Input:
#  A named hash containing following parameters.
#   encryptionAlgorithm - Name of the encryption algorithm to be used.
#   encryptionKey       - Encryption key.
#   IntegrityAlgorithm  - Integrity Algorithm
#   integrityKey        - Integrity key.
#   destination         - destination ipv6 address along with prefixlength
#                         specify 'any' for any ipv6 address.
#   mode                - specify the mode transport or tunnel mode.
#   name                - Name of the Security Association.
#   source              - source ipv6 address along with the prefixlength
#                         specify 'any' for any ipv6 address.
#   spi                 - SPI value for the security association (hex).
#
# Results:
#      "SUCCESS", if configuring security association is success
#      "FAILURE", in case of any error.
#
# Side effects:
#  None
#
########################################################################

sub ConfigureIPSecSecurityAssociation
{
   my $self = shift;
   my %args = @_;
   my $operation = $args{operation};
   my $result;

   if (not defined $operation) {
      $operation = "add";
   }

   if ($operation =~ m/add/i) {
      $result = $self->AddIPSecSecurityAssociation(%args);
   } else {
      $result = $self->RemoveIPSecSecurityAssociation(%args);
   }
   if ($result eq FAILURE) {
      $vdLogger->Error("Failure while configuring IPSec SA");
      VDSetLastError("EFAIL");
      return FAILURE;
   } else {
      return SUCCESS;
   }
}

########################################################################
#
# AddIPSecSecurityAssociation --
#      Method to add the ipsec SA
#
# Input:
#  A named hash containing following parameters.
#   encryptionAlgorithm - Name of the encryption algorithm to be used.
#   encryptionKey       - Encryption key.
#   IntegrityAlgorithm  - Integrity Algorithm
#   integrityKey        - Integrity key.
#   destination         - destination ipv6 address along with prefixlength
#                         specify 'any' for any ipv6 address.
#   mode                - specify the mode transport or tunnel mode.
#   name                - Name of the Security Association.
#   source              - source ipv6 address along with the prefixlength
#                         specify 'any' for any ipv6 address.
#   spi                 - SPI value for the security association (hex).
#
# Results:
#      "SUCCESS", if adding security association is success
#      "FAILURE", in case of any error.
#
# Side effects:
#  None
#
########################################################################

sub AddIPSecSecurityAssociation
{
   my $self = shift;
   my %args = @_;
   my $encryptionAlgorithm = $args{encryptionAlgorithm} || "null";
   my $encryptionKey       = $args{encryptionKey};
   my $integrityAlgorithm  = $args{integrityAlgorithm} || "hmac-sha1";
   my $integrityKey        = $args{integrityKey};
   my $destination         = $args{destination} || "any";
   my $mode                = $args{mode} || "transport";
   my $name                = $args{name};
   my $source              = $args{source} || "any";
   my $spi                 = $args{spi};
   my $host                = $self->{hostIP};
   my $command;
   my $result;

   if ((not defined $integrityKey) || (not defined $name)
       || (not defined $spi)) {
      $vdLogger->Error("One or parameter to add SA is not defined");
      $vdLogger->Error(Dumper(\%args));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # command to add ipsec SAD
   $command = "$vmknicEsxcli ipsec sa add -e $encryptionAlgorithm ".
              " -i $integrityAlgorithm -K $integrityKey -d $destination ".
              "-m $mode -n $name -s $source -p $spi ";
   if (defined $encryptionKey) {
      $command = "$command -k $encryptionKey ";
   }

   $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                  $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
     $vdLogger->Error("Failed to set ipsec SA $command on $host");
     $vdLogger->Error(Dumper($result));
     VDSetLastError("EFAIL");
     return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# RemoveIPSecSecurityAssociation --
#      Method to remove the ipsec SA
#
# Input:
#  A named hash containing following parameters.
#   Name           - Name of of the SA.
#   destination    - destination ipv6 address.
#   source         - source ipv6 address.
#   spi            - SPI valued for SA.
#
# Results:
#      "SUCCESS", if removing security association is success
#      "FAILURE", in case of any error.
#
# Side effects:
#  None
#
########################################################################

sub RemoveIPSecSecurityAssociation
{
   my $self = shift;
   my %args = @_;
   my $name = $args{name};
   my $destination = $args{destination};
   my $source = $args{source};
   my $spi = $args{spi};
   my $host = $self->{hostIP};
   my $result;
   my $command;

   if (not defined $name) {
      if ((not defined $source) || (not defined $spi) ||
          (not defined $destination)) {
          $vdLogger->Error("Parameters to automatically select SA not defined");
          VDSetLastError("ENOTDEF");
          return FAILURE;
       }
    }


   #
   # if name is defined remove that sa,
   # else find the sa name automatication
   # from sa and destination.
   #
   $command = "$vmknicEsxcli ipsec sa remove ";
   if (defined $name) {
      if ($name =~ m/all/i) {
         $command = "$command -a ";
      } else {
         $command = "$command -n $name ";
      }
   } else {
      $command = "$command -n auto -d $destination -s $source -p $spi ";
   }

   $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                  $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
     $vdLogger->Error("Failed to remove ipsec SA $command on $host");
     $vdLogger->Error(Dumper($result));
     VDSetLastError("EFAIL");
     return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# ConfigureIPSecSecurityPolicy --
#      Method to configure the ipsec SP
#
# Input:
#  A named hash containing following parameters.
#  SAName         - Name of the security association this SP will use.
#  SPName         - Name of the security policy to be added.
#  action         - specifies what action should be taken for the traffic
#                  should be [ipsec,discard,node].
#  destinationPort - destination port number. 0 means any port.
#  direction       - direction of the traffic, 'in' or 'out'.
#  sourcePort      - source port number, 0 means any port.
#  destination     - destination ipv6 address.
#  source          - source ipv6 address.
#  protocol        - upper layer protocol, should be tcp, udp, icmp6 and any.
#  mode            - transport or tunnel.
#
# Results:
#      "SUCCESS", if configuring security policy is success
#      "FAILURE", in case of any error.
#
# Side effects:
#  None
#
########################################################################

sub ConfigureIPSecSecurityPolicy
{
   my $self = shift;
   my %args = @_;
   my $operation = $args{operation};
   my $result;

   if (not defined $operation) {
      $operation = "add";
   }

   if ($operation =~ m/add/i) {
      $result = $self->AddIPSecSecurityPolicy(%args);
   } else {
      $result = $self->RemoveIPSecSecurityPolicy(%args);
   }
   if ($result eq FAILURE) {
      $vdLogger->Error("Failure while configuring IPSec SP");
      VDSetLastError("EFAIL");
      return FAILURE;
   } else {
      return SUCCESS;
   }
}


########################################################################
#
# AddIPSecSecurityPolicy --
#      Method to add the ipsec SP
#
# Input:
#  A named hash containing following parameters.
#  SAName         - Name of the security association this SP will use.
#  SPName         - Name of the security policy to be added.
#  action         - specifies what action should be taken for the traffic
#                  should be [ipsec,discard,node].
#  destinationPort - destination port number. 0 means any port.
#  direction       - direction of the traffic, 'in' or 'out'.
#  sourcePort      - source port number, 0 means any port.
#  destination     - destination ipv6 address.
#  source          - source ipv6 address.
#  protocol        - upper layer protocol, should be tcp, udp, icmp6 and any.
#  mode            - transport or tunnel.
#
# Results:
#      "SUCCESS", if adding security policy is success
#      "FAILURE", in case of any error.
#
# Side effects:
#  None
#
########################################################################

sub AddIPSecSecurityPolicy
{
   my $self = shift;
   my %args = @_;
   my $SAName = $args{SAName};
   my $SPName = $args{SPName};
   my $action = $args{action} || "ipsec";
   my $destinationPort = $args{destinationPort} || "0";
   my $sourcePort = $args{sourcePort} || "0";
   my $direction = $args{direction} || "in";
   my $destinationAddress = $args{destinationAddress} || "any";
   my $sourceAddress = $args{sourceAddress} || "any";
   my $mode = $args{mode} || "transport";
   my $protocol = $args{protocol} || "any";
   my $host = $self->{hostIP};
   my $command;
   my $result;

   if ((not defined $SAName) || (not defined $SPName)) {
      $vdLogger->Error("Security Association and/or Security Policy Name not specified");
      $vdLogger->Error(Dumper(\%args));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # command to add SP
   $command = "$vmknicEsxcli ipsec sp add -A $action -P $destinationPort ".
              "-w $direction -a $SAName -p $sourcePort -d $destinationAddress ".
              "-m $mode -n $SPName -s $sourceAddress -u $protocol ";

   $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                     $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
     $vdLogger->Error("Failed to add ipsec SP $command on $host");
     $vdLogger->Error(Dumper($result));
     VDSetLastError("EFAIL");
     return FAILURE;
   }
   return SUCCESS;

}


########################################################################
#
# RemoveIPSecSecurityPolicy --
#      Method to remove the ipsec SP
#
# Input:
#   A named hash containing following parameters
#      SPName - Name of the security policy to be removed.
#
# Results:
#      "SUCCESS", if remove security policy is success
#      "FAILURE", in case of any error.
#
# Side effects:
#  None
#
########################################################################

sub RemoveIPSecSecurityPolicy
{
   my $self = shift;
   my %args = @_;
   my $name = $args{SPName} || "all";
   my $host = $self->{hostIP};
   my $command;
   my $result;

   if($name =~ m/all/i) {
      $command = "$vmknicEsxcli ipsec sp remove -a ";
   } else {
      $command = "$vmknicEsxcli ipsec sp remove -n $name ";
   }

   $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                     $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
     $vdLogger->Error("Failed to remove ipsec SP $command on $host");
     $vdLogger->Error(Dumper($result));
     VDSetLastError("EFAIL");
     return FAILURE;
   }
   return SUCCESS;

}


########################################################################
#
# ConfigureVIB --
#     Method to install/remove/update the given VIB(s)
#
# Input:
#     named hash with following keys:
#     vib    : install/update/remove
#     vibfile: http url to vib
#     signaturecheck: 1/0 to enable/disable sigcheck
#     maintenance: 1/0 to enable/disable maintenance mode
#
# Results:
#     SUCCESS, if given VIB is installed succesfully on ESX
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ConfigureVIB
{
   my $self = shift;
   my %args    = @_;

   # change parameters to lower case
   %args = (map { lc $_ => $args{$_}} keys %args);

   my $operation  = $args{vib};
   my $operationsList = {
      install  => 'InstallOrUpdateVIB',
      remove   => 'RemoveVIB',
      update   => 'InstallOrUpdateVIB',
   };
   my $method = $operationsList->{$operation};
   if (not defined $method) {
      $vdLogger->Error("Unknown VIB operation specified: $operation");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return $self->$method(%args);
}


########################################################################
#
# InstallOrUpdateVIB --
#     Method to install or update the given VIB(s)
#
# Input:
#     named hash with following keys:
#     vibfile: http url to vib
#     signaturecheck: 1/0 to enable/disable sigcheck
#     maintenance: 1/0 to enable/disable maintenance mode
#
# Results:
#     SUCCESS, if given VIB is installed succesfully on ESX
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub InstallOrUpdateVIB
{
   my $self = shift;
   my %args = @_;

   my $vibFiles  = $args{'vibfile'};
   my $operation = $args{'vib'};

   foreach my $vib (@$vibFiles) {
      my $command = "esxcli software vib " . $operation;
      if ((defined $args{'maintenance'}) &&
          ($args{'maintenance'})) {
         $command .= " --maintenance-mode";
      }
      if ((defined $args{'signaturecheck'}) &&
          (!$args{'signaturecheck'})) {
         $command .= " --no-sig-check";
      }
      $command .= " -v $vib";
      $vdLogger->Info("VIB install command: $command");
      my $host = $self->{hostIP};
      my $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                        $command);
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to install $vib on $host");
         $vdLogger->Error(Dumper($result));
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      if (($result->{stdout} !~ /VIBs Installed: \S+/i) &&
          ($result->{stdout} !~ /Host is not changed/i)){
         $vdLogger->Warn("No change after $vib $operation operation on $host");
         $vdLogger->Debug(Dumper($result));
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# RemoveVIB --
#     Method to Remove VIB
#
# Input:
#     named hash with following keys:
#     vibfile: http url to vib
#
# Results:
#     SUCCESS, if vib files are removed successfully;
#     FAILURE, in case of any error;
#
# Side effects:
#     None of the configurations relying on VIBs would work.
#
########################################################################

sub RemoveVIB
{
   my $self = shift;
   my %args = @_;

   my $vibFiles = $args{'vibfile'};

   foreach my $vib (@$vibFiles) {
      my $command = "esxcli software vib list | grep $vib";
      my $host = $self->{hostIP};
      my $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                        $command);
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      if ($result->{stdout} =~ /$vib/i) {
         my $actualVIBName = $vib;
         $vdLogger->Debug("Found $actualVIBName installed on $host");
         $vdLogger->Debug("UnInstalling $actualVIBName on $host");
         $command = "esxcli software vib remove -n $actualVIBName";
         $vdLogger->Info("VIB uninstall command: $command");
         my $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                           $command);
         if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
            $vdLogger->Error("Failed to uninstall $actualVIBName on $host");
            $vdLogger->Debug(Dumper($result));
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      } else {
         $vdLogger->Info("No VIB $vib installed on the host $host");
      }
   }
   return SUCCESS;
}


########################################################################
#
# CreateOVS --
#     Method to create OVS on the ESX host
#
# Input:
#     Array of hashes with following keys:
#     switch: unique name for the ovs on the host
#
# Results:
#     Reference to array of VDNetLib::Switch::Switch objects
#
# Side effects:
#     None
#
########################################################################

sub CreateOVS
{
   my $self         = shift;
   my $arrayOfSpecs = shift;
   my @arrayOfObjects;

   foreach my $spec (@$arrayOfSpecs) {
      my %options = %$spec;
      if (not defined $options{'switch'}) {
         $vdLogger->Error("OVS name not provided");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      my $ovsObj = VDNetLib::Switch::OpenVswitch::OpenVswitch->new(
                                   'switch'     => $options{'switch'},
                                   'hostOpsObj' => $self,
                                   'stafHelper' => $self->{stafHelper},
                                   'switchType' => "ovs",
                                   );
      push(@arrayOfObjects, $ovsObj);
   }
   return \@arrayOfObjects;
};


########################################################################
#
# CreateNVPNetwork --
#     Method to create NVP network on the host
#
# Input:
#     Reference to array of specs/hashes with following keys:
#     network: unique name to identify a ovs network on host
#
# Results:
#     Reference to an array of VDNetLib::Switch::OpenVswitch::Network
#     objects
#
# Side effects:
#     None
#
########################################################################

sub CreateNVPNetwork
{
   my $self         = shift;
   my $arrayOfSpecs = shift;
   my @arrayOfObjects;

   my @finalSpec;
   my  $options;
   foreach my $spec (@$arrayOfSpecs) {
      %{$options} = %$spec;
      $options->{network} = $options->{name};
      if (not defined $options->{'network'}) {
         $vdLogger->Error("OVS network name not provided");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      $options->{'type'} = "nsx.network";
      my $networkId = $options->{'network'};
      my $command = "nsxcli network/add " . $networkId .
                    " $options->{'network'} $options->{'type'} manual";
      $vdLogger->Info("Creating NSX Opaque network: $command");
      my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                        $command);
      if (($result->{rc} != 0) || ($result->{stdout} !~ /success/i)) {
         $vdLogger->Error("Failed to execute command $command");
         $vdLogger->Debug("Error:" . Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      my $nvpNetworkObj = VDNetLib::Switch::OpenVswitch::Network->new(
                                          'network'    => $options->{'network'},
                                          'id'         => $networkId,
                                          'switchObj'  => $options->{'ovs'},
                                          'hostOpsObj' => $self,
                                          'stafHelper' => $self->{stafHelper});
      if ($nvpNetworkObj eq FAILURE) {
         $vdLogger->Error("Failed to create nvp network object");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      push (@arrayOfObjects, $nvpNetworkObj);
   }
   return \@arrayOfObjects;
}


########################################################################
#
# RemoveNVPNetwork --
#     Method to remove NVP from the host
#
# Input:
#     arrayOfObjects : reference to array of NVP network objects
#
# Results:
#     "SUCCESS", if the given NVP networks are removed successfully;
#     "FAILURE", in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub RemoveNVPNetwork
{
   my $self           = shift;
   my $arrayOfObjects = shift;

   foreach my $item (@$arrayOfObjects) {
      $item->{'type'} = "nsx.network";
      my $command = "nsxcli network/del $item->{'network'} $item->{'type'}";
      $vdLogger->Debug("Deleting nsx opaque network: $command");
      my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                        $command);
      if (($result->{rc} != 0) || ($result->{stdout} !~ /success/i)) {
         $vdLogger->Error("Failed to execute command $command");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   return SUCCESS;
}


########################################################################
#
# GetVirtualFunctions --
#     Method to get a list of "virtual functions" (VFs) fo given vmnic. It
#     is assumed that SR-IOV is enabled on the adapter before calling this
#     method.
#
# Input:
#     interface : Name of vmnic interface. (e.g. vmnic1)
#
# Results:
#     Reference to a hash of hash where the outer hash has
#     keys representing VF index and value is a hash with following
#     keys:
#
#     'bdf'    : BDF (Bus, Device, Function) number
#     'active' : "true" or "false"
#     'owner'  : world id that is using this VF
#
#     Each element of the array is a virtual function
#
# Side effects:
#     None
#
########################################################################

sub GetVirtualFunctions
{
   my $self      = shift;
   my $interface = shift;

   my $virtualFunctionsHash = {};
   my $command = "esxcli network sriovnic vf list -n $interface";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if (($result->{rc} != 0)) {
      $vdLogger->Error("Failed to execute command $command");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($result->{stdout} =~ /no SRIOV nic/i) {
      $vdLogger->Info("SRIOV is disabled on $interface");
      return $virtualFunctionsHash; #  empty hash should be returned
   }

   #
   # Process the output which looks like the following sample:
   # VF ID  Active  PCI Address  Owner World ID
   # -----  ------  -----------  --------------
   # 0   false  006:16.0      -
   # 1   false  006:16.2      -
   # 2   false  006:16.4      -
   #

   my @lines = split(/\n/, $result->{stdout});
   shift(@lines); # ignore first 2 lines of esxcli stdout
   shift(@lines);
   foreach my $line (@lines) {
      $line =~ s/^\s+//g; # remove any spaces in the beginning
      $line =~ s/\s+/;/g; # replace spaces in between with ;
      my ($vfIndex, $state, $bdf, $owner)  = split(/;/, $line);
      $virtualFunctionsHash->{$vfIndex}{'active'} = $state;
      $virtualFunctionsHash->{$vfIndex}{'bdf'} = $bdf;
      $virtualFunctionsHash->{$vfIndex}{'owner'} = $owner;
   }
   return $virtualFunctionsHash;
}


################################################################################
#
# GetNetworkNeighborList--
#     Method to retrieve the list of neighbors attached to vmknics in a host
#
# Input:
#     Param - one of the following params is supported: [OPTIONAL]
#        deviceid : Name of the interface
#        netstack : Network stack instance name
#        version  : IP version (supported values "4","6","all"
#
# Results:
#     List of neighbors is returned, upon sucessful retrieval
#     FAILURE, in case of any errors
#
# Side effects:
#     None
#
################################################################################

sub GetNetworkNeighborList
{
   my $self = shift;
   my %args = @_;
   my $deviceId = $args{deviceid};
   my $netstack = $args{netstack};
   my $version = $args{version};
   my $stafHelper = $self->{stafHelper};
   my $host = $self->{hostIP};
   my $command;
   my $result;

   $command = "$vmknicEsxcli neighbor list";

   # Checking for different options tat have been passed
   if (defined $deviceId) {
      $command = $command." -i $deviceId";
   } elsif (defined $netstack) {
      $command = $command." -N $netstack";
   } elsif (defined $version) {
      if ($version !~ /4|6|all/i) {
         $vdLogger->Error("Incorrect value for version passed: $version\n".
                          "Accepted values are: 4, 6 or all");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      $command = $command." -v $version";
   }

   $result = $stafHelper->STAFSyncProcess($host,$command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to retrieve the neighbor list for host $host");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return $result->{stdout};
}

################################################################################
#
# EnableSRIOVRefreshInHostdConfig--
#     Step1:download the config.xml file;
#     Step2:add a node
#           <reloadModulesOnConfigChange>true</reloadModulesOnConfigChange>
#           in the path /config/plugins/hostsvc/sriov;
#     Step3:upload it back to host.
#
# Input:
#     None
#
# Results:
#     SUCCESS, if the operation is SUCCESS
#     FAILURE, in case of any errors
#
# Side effects:
#     After change the hostd configure file, we don't need to reboot host for
#     the sriov configuration to work
#
################################################################################

sub EnableSRIOVRefreshInHostdConfig
{
   my $self = shift;
   my $stafHelper = $self->{stafHelper};
   my $hostIP = $self->{hostIP};
   my $localIP = VDNetLib::Common::Utilities::GetLocalIP();
   my $srcFile = HOSTD_CONFIG_FILE;
   my $destFile;
   my $parentPath = SRIOV_CONFIG_NODE_PATH;
   my $childNode = {
                     tag   => "reloadModulesOnConfigChange",
                     text  => "true"
                   };

   my $myLogDir = VDNetLib::Common::GlobalConfig::GetLogsDir();
   $destFile = $myLogDir.VDNetLib::Common::Utilities::GetTimeStamp()."config.xml";
   $vdLogger->Debug("Trying to download the $srcFile from the host to MC $destFile");
   my $result = $stafHelper->STAFFSCopyFile($srcFile,
                                         $destFile,
                                         $hostIP,
                                         $localIP);
   if ($result ne 0) {
      $vdLogger->Error("Unable to download file from the host $hostIP to $localIP");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if (FAILURE eq VDNetLib::Common::Utilities::AddNodeToXml($destFile,
                                                  $parentPath,$childNode)) {
      $vdLogger->Error("Unable to add node to the xml path");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Debug("Try to upload the $destFile from the MC to host $srcFile");
   $result = $self->{stafHelper}->STAFFSCopyFile($destFile,
                                         $srcFile,
                                         $localIP,
                                         $hostIP);
   if ($result ne 0) {
      $vdLogger->Error("Unable to upload file back to the host $hostIP");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   # command to restart hostd on ESX/ESXi
   my $command = "/etc/init.d/hostd restart";
   $result = $self->{stafHelper}->STAFSyncProcess($hostIP,
                                                        $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to restart hostd failed:" .
                        Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Wait a few seconds for Hostd to restart");
   sleep WAIT_FOR_HOSTD_TO_READY;
   # command to check the status of hostd on ESX/ESXi
   $command = "/etc/init.d/hostd status";
   $result = $self->{stafHelper}->STAFSyncProcess($hostIP,
                                                        $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to get the hostd status:" .
                        Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($result->{stdout} !~ /hostd is running/i) {
      $vdLogger->Error("hostd isn't running:" .
                        Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if ($self->Reconnect(5) eq FAILURE) {
      $vdLogger->
      Error("The hostd restart failed since staf anchor can not create.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


#############################################################################
#
# GetMORId--
#     Method to get the Host's Managed Object Ref ID.
#
# Input:
#
# Results:
#     hostMORId,
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub GetMORId
{
   my $self   = shift;
   my $hostMORId;

   my $inlineHostObj = $self->GetInlineHostObject();
   if (!($hostMORId = $inlineHostObj->GetMORId())) {
      $vdLogger->Error("Failed to get the Managed Object ID for ".
	               "the Host: $self->{hostIP}");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $vdLogger->Debug("Managed Object Ref ID for the Host:". $self->{hostIP} .
                    " is MORId:". $hostMORId);
   return $hostMORId;
}


#############################################################################
#
# IsHostConnectedToVC--
#     Method to check if the host is connected to the VCenter Server.
#
# Input:
#     None
#
# Results:
#     1, if host is already connected
#     0, if host is not yet connected
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub IsHostConnectedToVC
{
   my $self   = shift;
   my $result;

   my $inlineHostObj = $self->GetInlineHostObject();
   $result = $inlineHostObj->IsHostConnectedToVC();

   if (not defined $result) {
      $vdLogger->Error("Failed to check if the host ".$self->{hostIP}.
                       " is already connected to VC or not");
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   ($result == 0) ? $vdLogger->Debug("Host : ".$self->{hostIP}." is not connected to VC"):
                $vdLogger->Debug("Host : ".$self->{hostIP}." is connected to VC");

   return $result;
}


#############################################################################
#
# IsStandaloneHost--
#     Method to check if the host is a standalone host or part of cluster
#
# Input:
#     hostMor : Managed Object Reference of the host
#
# Results:
#     1, if host is standalone
#     0, if host is not standalone and in cluster environment
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub IsStandaloneHost
{
   my $self   = shift;
   my $result;

   my $inlineHostObj = $self->GetInlineHostObject();
   $result = $inlineHostObj->IsStandaloneHost();

   if (not defined $result) {
      $vdLogger->Error("Failed to check if the host ".$self->{hostIP}.
                       " is standalone or part of a cluster");
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   (!$result) ? $vdLogger->Debug("Host : ".$self->{hostIP}." is part of a cluster"):
                $vdLogger->Debug("Host : ".$self->{hostIP}." is a standalone host");

   return $result;
}


#############################################################################
#
# GetDatastoreMORId--
#     Method to get the datastore Managed Object Ref ID.
#
# Input:
#     datastoreName : Datastore name as in the inventory
#
# Results:
#     datastoreMORId, if SUCCESS
#     FAILURE, if datastore is not found or in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub GetDatastoreMORId
{
   my $self          = shift;
   my $datastoreName = shift;

   my $datastoreMORId;

   my $inlineHostObj = $self->GetInlineHostObject();
   if (!($datastoreMORId = $inlineHostObj->GetDatastoreMORId($datastoreName))) {
      $vdLogger->Error("Failed to get the Managed Object ID for the datastore:"
                       . $datastoreName);
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $vdLogger->Debug("Managed Object Ref ID for the datastore:".$datastoreName.
                    " is MORID:". $datastoreMORId);
   return $datastoreMORId;
}


########################################################################
#
# GetNetVDL2Config--
#      Get the networking config for vxlan using net-vdl2 -l on the esx host
#
# Input:
#      logDir : Name of the directory on master controller where
#               logs are to be copied.
#
#
# Results:
#     SUCCESS
#     FAILURE if there are errors
#
# Side effects:
#      None
#
########################################################################

sub GetNetVDL2Config
{
   my $self = shift;
   my $logDir = shift;
   my $hostIP = $self->{hostIP};
   my $file = $logDir."/"."net-vdl2-Configuration"."_".$hostIP.".txt";
   my $netVDL2;
   my $command;
   my $result;
   my $ret = SUCCESS;

   $command = "net-vdl2 -l";
   $result = $self->{stafHelper}->STAFSyncProcess($hostIP, $command);
   if (($result->{rc} !=0) || ($result->{exitCode} != 0)) {
      $vdLogger->Debug("Failed to get the vds configuration on host $hostIP ".
	                Dumper($result));
      VDSetLastError("ESTAF");
   }
   $netVDL2 = $result->{stdout};
   if (defined $netVDL2) {
      open FILE, ">" ,$file;
      print FILE "VXLAN configuration using net-vdl2 -l\n\n";
      print FILE "$netVDL2\n\n\n";
      close (FILE);
   }

   $command = "cat /etc/vmware/netcpa/config-by-vsm.xml";
   $result = $self->{stafHelper}->STAFSyncProcess($hostIP, $command);
   if (($result->{rc} !=0) || ($result->{exitCode} != 0)) {
      $vdLogger->Debug("Failed to get config-by-vsm.xml on host $hostIP ".
	                Dumper($result));
      VDSetLastError("ESTAF");
   }
   my $confiByVSM = $result->{stdout};
   if (defined $confiByVSM) {
      open FILE, ">" , $logDir."/"."config-by-vsm.xml"."_".$hostIP.".txt";
      print FILE "Config-by-vsm.xml is -l\n\n";
      print FILE "$confiByVSM\n\n\n";
      close (FILE);
   }

   return $ret;
}


########################################################################
#
# GetNetVDRConfig--
#      Get the networking config for vdr using net-vdr on the esx host
#
# Input:
#      logDir : Name of the directory on master controller where
#               logs are to be copied.
#
#
# Results:
#     SUCCESS
#     FAILURE if there are errors
#
# Side effects:
#      None
#
########################################################################

sub GetNetVDRConfig
{
   my $self = shift;
   my $logDir = shift;
   my $hostIP = $self->{hostIP};
   my $file = $logDir."/"."net-vdr-Configuration"."_".$hostIP.".txt";
   my $netVDR;
   my $command;
   my $result;
   my $ret = SUCCESS;

   $command = "net-vdr -C -l; net-vdr -I -l";
   $result = $self->{stafHelper}->STAFSyncProcess($hostIP, $command);
   if (($result->{rc} !=0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to get the vds configuration on host $hostIP ".
	                Dumper($result));
      VDSetLastError("ESTAF");
   }
   $netVDR = $result->{stdout};

   if (defined $netVDR) {
      open FILE, ">" ,$file;
      print FILE "VDR configuration using net-vdr -I -l\n\n";
      print FILE "$netVDR\n\n\n";
      close (FILE);
      my $hash = VDNetLib::Common::Utilities::ConvertRawDataToHash($result->{stdout});
      if (not defined $hash) {
         $vdLogger->Trace("ConvertRawDataToHash returned undef for".  Dumper($result));
         return $ret;
      }
      $command = "net-vdr -L -l " . $hash->{'Vdr Name'};
      $result = $self->{stafHelper}->STAFSyncProcess($hostIP, $command);
      if (($result->{rc} !=0) || ($result->{exitCode} != 0)) {
         $vdLogger->Error("Failed to get the vds configuration on host $hostIP ".
                           Dumper($result));
         VDSetLastError("ESTAF");
      }
      $netVDR = $result->{stdout} if defined $result->{stdout};
      open FILE, ">>" ,$file;
      print FILE "VDR LIF configuration using net-vdr -L -l $hash->{'Vdr Name'} \n\n";
      print FILE "$netVDR\n\n\n";
   }
   close (FILE);

   return $ret;
}


########################################################################
#
# InstallTestCerts
#      Install test-certs on host to turn off signing to install any vib
#      and skip signing.
#
# Input:
#     sshSession : reference to VDNetLib::Common::SshHost object (Required)
#
# Results:
#     SUCCESS
#     FAILURE if there are errors
#
# Side effects:
#      None
#
########################################################################

sub InstallTestCerts
{
   my $self    = shift;
   my $sshHost = shift;
   my $output;

   $vdLogger->Info("Installing test-certs on $self->{hostIP}");
   if (not defined $sshHost) {
      $vdLogger->Error("SshHost object and/or action not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $dstFile = ESXTESTCERTSVIB;
   my $vibFile = TESTCERTVIBSRC;
   my ($rc, $out) = $sshHost->ScpToCommand($vibFile, $dstFile);
   if ($rc ne "0") {
      $vdLogger->Error("Failed to copy test-certs.vib file " .
                       " to $self->{hostIP}");
      $vdLogger->Debug("ERROR:$rc " . Dumper($out));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $command = "esxcli software vib install -f --no-sig-check -v $dstFile";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to install vib failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}


#######################################################################
#
# GetNetCPALog--
#      Copy the netcpa agent log form the host to specified directory.
#
# Input:
#      logDir : Name of the directory on master controller where
#                directory are to be copied.
#
# Results:
#     SUCCESS if netcpa logs are copied successfully.
#     FAILURE if there are errors while copying the VPX agent logs.
#
# Side effects:
#      None
#
########################################################################

sub GetNetCPALog
{
   my $self = shift;
   my $logDir = shift;
   my $hostIP = $self->{hostIP};
   my $netCPA = "/var/log/netcpa.log";
   my $stafHelper = $self->{stafHelper};
   my $localIP = VDNetLib::Common::Utilities::GetLocalIP();
   my $result;

   if (not defined $logDir) {
      $vdLogger->Error("Log Directory not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($localIP eq FAILURE) {
      $vdLogger->Error("Failed to get the ip address of ".
                       "Master Controller");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # copy vpx agent log file to log directory.
   $result = $stafHelper->STAFFSCopyFile($netCPA,
                                         $logDir,
                                         $hostIP,
                                         $localIP);
   if ($result ne 0) {
      $vdLogger->Warn("Failed to copy $netCPA");
   }
   return SUCCESS;
}


#######################################################################
#
# GetVSFWDLog--
#      Copy the vsfwd log form the host to specified directory.
#
# Input:
#      logDir : Name of the directory on master controller where
#                directory are to be copied.
#
# Results:
#     SUCCESS if netcpa logs are copied successfully.
#     FAILURE if there are errors while copying the VPX agent logs.
#
# Side effects:
#      None
#
########################################################################

sub GetVSFWDLog
{
   my $self = shift;
   my $logDir = shift;
   my $hostIP = $self->{hostIP};
   my $vsfwd = "/var/log/vsfwd.log";
   my $stafHelper = $self->{stafHelper};
   my $localIP = VDNetLib::Common::Utilities::GetLocalIP();
   my $result;

   if (not defined $logDir) {
      $vdLogger->Error("Log Directory not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($localIP eq FAILURE) {
      $vdLogger->Error("Failed to get the ip address of ".
                       "Master Controller");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # copy vpx agent log file to log directory.
   $result = $stafHelper->STAFFSCopyFile($vsfwd,
                                         $logDir,
                                         $hostIP,
                                         $localIP);
   if ($result ne 0) {
      $vdLogger->Warn("Failed to copy $vsfwd");
   }
   return SUCCESS;
}


########################################################################
#
# DeleteConnectionVDRPortToVDS
#       This is to delete a connection between VDR Port and VDS
#
# Input:
#       dvsname(mandatory)
#       host: host on which to do operation(optional)
#
# Results:
#       A hash of VDR instance information
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub DeleteConnectionVDRPortToVDS
{

   my $self    = shift;
   my %args    = @_;
   my $vdrPortNumber = $args{vdrportnumber} || "vdrPort";
   my $dvsname = $args{dvsname};
   my ($command, $result);

   if (not defined $dvsname) {
      $vdLogger->Error("dvsname not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   #
   # --connection -d -s dvsName
   # Delete the existing connection of vdr port with dvs switch
   #

   $command =  "net-vdr -C -d -s " .$dvsname;

   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Debug("Failed to run command:$command on host:$self->{hostIP}".
                       Dumper($result));
      VDSetLastError("ESTAF");
   }
   $vdLogger->Info("*** Hack due to PR 1075998 Successfully deleted vdrport connection from " .
                   "DVS: $dvsname");
   return SUCCESS;
}


sub CreateDestroyVDRPort
{
   my $self          = shift;
   my %args          = @_;
   my $operation     = $args{vdrport} || "delete";
   my $dvsname       = $args{dvsname};
   my $vdrPortNumber = $args{vdrportnumber} || "vdrPort";
   my ($result);
   my $command;

   #
   # Create/Destroy VDR Port
   #
   if ($operation =~ /create/i) {
      $operation = "created";
      $command = "net-dvs -A -p $vdrPortNumber $dvsname";
   } else {
      $operation = "deleted";
      $command = "net-dvs -D -p $vdrPortNumber $dvsname";
   }

   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Debug("Failed to run command:$command on host:$self->{hostIP}".
                       Dumper($result));
      VDSetLastError("ESTAF");
   }
   $vdLogger->Info("*** Hack due to PR 1075998 Successfully $operation vdrport: $vdrPortNumber " .
                   "on DVS: $dvsname");
   return SUCCESS;
}
################################################################################
#
# GetActivePortsSystemWide:
#     get number of ActivePortsSystemWide
#
# Input:
#     None
#
# Results: Return active port number
#          FAILURE on failure
#
################################################################################

sub GetActivePortsSystemWide
{
   my $self = shift;

   # Get number of Active Ports in ESXi System (an integer number)
   my $command = "vsish -pe get /net/numActivePortsSystemWide";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
							$command);
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to get numActivePortsSystemWide");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $result->{stdout} =~ /(\d+)/;
   my $numActivePortsSystemWide = $1;
   $vdLogger->Debug("numActivePortsSystemWide = $numActivePortsSystemWide");
   return  $numActivePortsSystemWide;
}


################################################################################
#
# GetMaxPortsSystemWide:
#     get max PortsSystemWide
#
# Input:
#      None
#
# Results: Return max Ports SystemWide number
#          FAILURE on failure
#
################################################################################

sub GetMaxPortsSystemWide
{
   my $self = shift;

   # Get Max number of Ports the ESXi can handle. (an integer number)
   my $command = "vsish -pe get /net/maxPortsSystemWide";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
							$command);
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to get maxPortsSystemWide");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $result->{stdout} =~ /(\d+)/;
   my $maxPortsSystemWide = $1;
   $vdLogger->Debug("maxPortsSystemWide = $maxPortsSystemWide");
   return  $maxPortsSystemWide;

}


################################################################################
#
# MaxPortsCheck:
#    Create  a vswitch and  Check error "Out of resources"
#    If ActivePortsSystemWide < MaxPortsSystemWide, return SUCCESS
#    else FAILURE
#
# Input:
#   none
#
# Results: SUCCESS if the vswitch is autoscale
#          FAILURE on failure
#
################################################################################

sub MaxPortsCheck
{
   my $self = shift;
   my $vswitch = "autoscale-switch";

   my $activeports = $self->GetActivePortsSystemWide();

   # Create a vswitch and expected it failed
   my $result = $self->AddOneVSwitch($vswitch-$$);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to to Create vSwitch$$");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($result->{exitCode} == 1) {
      if(($result->{stdout} =~ m/Out of resources/i) || ($result->{stdout} =~ m/Unable to set/i)) {
	my $maxport = $self->GetMaxPortsSystemWide();
	my $activeport = $self->GetActivePortsSystemWide();
	if ($activeport < $maxport) {
	   $vdLogger->Debug("MaxPorts Check passed");
	   return SUCCESS;
	}
      } else {
	VDSetLastError("EFAIL");
	return FAILURE;
      }
   }
   $vdLogger->Debug("Host still have resources to create vswitch");
   return FAILURE;
}

################################################################################
#
# ActiveDVPortsCheck:
#    Use below command to get actually active dvport and compare it
#    to expect value
#    vsish -e get /net/numActiveDVSPortsSystemWide
#
# Input:
#   expect active dvport value
#
# Results: SUCCESS if the actual active value equal to expect active value
#          FAILURE if not
#
################################################################################

sub ActiveDVPortsCheck
{
   my $self = shift;
   my $expectactiveDVportnum = shift;

   my $command = "vsish -pe get /net/numActiveDVPortsSystemWide";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                           $command);
   if (($result->{rc} != 0) && ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to get numActiveDVPortsSystemWide");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $result->{stdout} =~ /(\d+)/;
   my $actualactiveDVportnum = $1;
   if ($expectactiveDVportnum == $actualactiveDVportnum) {
      $vdLogger->Debug("ActiveDVPorts Check passed");
      return SUCCESS;
   } else {
      return FAILURE;
   }
}

##############################################################################
#
# GetActivePortStats:
#    Get activePortsSystemWide stats
#
# Input:
#   none
#
# Results: ireturn stats hash if success
#          FAILURE on failure
#
###############################################################################

sub GetActivePortStats
{
   my $self = shift;
   my $activeports = $self->GetActivePortsSystemWide();
   $vdLogger->Debug("Active port num = $activeports");
   if ($activeports ne  FAILURE ){
      my $hash->{activeportstats} = $activeports;
      return $hash;
   }
   return FAILURE;
}


##############################################################################
#
# AddOneVSwitch:
#    Add one vSwitch
#
# Input: name    VSwitch name
#   none
#
# Results: ireturn stats hash if success
#          FAILURE on failure
#
###############################################################################

sub AddOneVSwitch
{
   my $self = shift;
   my $name = shift;
   my $command = "esxcli network vswitch standard add -v $name";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},$command);
   return $result;
}


########################################################################
#
# CreateProfile --
#      This method will create hostprofile from ESXi
#
# Input:
#      hostprofilefile: host profile file with absolute path
#
# Results:
#      Return  "SUCCESS" if extract command pass
#      Returns "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub CreateProfile
{
  my $self = shift;
  my %args = @_;
  my $hostprofilefile = $args{hostprofilefile};
  my $command;

  if( $hostprofilefile ne "default" ) {
     $command = "esxhpcli extractprofile -o " . $hostprofilefile;
  } else {
     $command = "esxhpcli extractprofile -o " .
                VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE;
  }
  $vdLogger->Debug("Create Profile on " . $self->{hostIP} . ":". $command );
  my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
  if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
     $vdLogger->Error("Failed to execute command $command on " .
                       $self->{hostIP});
     VDSetLastError("ESTAF");
     return FAILURE;
  }
  return SUCCESS;
}


########################################################################
#
# GenerateAnswerFile --
#      This method will generate answer file from hostprofile
#
# Input:
#      hostprofilefile: host profile file (with absolute path)
#      answerFile: answer file (with absolute path)
#
# Results:
#      Return  "SUCCESS" if generate answerfile command pass
#      Returns "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GenerateAnswerFile
{
  my $self = shift;
  my %args = @_;
  my $hostprofilefile = $args{hostprofilefile};
  my $answerFile = $args{answerfile};
  my $command;

  if( ( $answerFile ne "default" ) && ( $hostprofilefile ne "default" ) ) {
     $command = "esxhpcli genanswerfile -o " .
                $answerFile . " " .
                $hostprofilefile;
  } else {
     $command = "esxhpcli genanswerfile -o " .
                VDNetLib::TestData::TestConstants::ANSWER_FILE . " " .
                VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE;
  }
  $vdLogger->Debug("Generate answer file on " . $self->{hostIP} . ":". $command );
  my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
  if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
     $vdLogger->Error("Failed to execute command $command on " .
                       $self->{hostIP});
     VDSetLastError("ESTAF");
     return FAILURE;
  }
  return SUCCESS;
}


########################################################################
#
# GenerateTaskList --
#      This method will generate tasklist file from hostprofile
#
# Input:
#      hostprofilefile: host profile file (with absolute path)
#      answerFile: answer file (with absolute path)
#      taskFile: task file (with absolute path)
#
# Results:
#      Return  "SUCCESS" if generate tasklist file command pass
#      Returns "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GenerateTaskList
{
  my $self = shift;
  my %args = @_;
  my $hostprofilefile = $args{hostprofilefile};
  my $answerFile = $args{answerfile};
  my $taskFile = $args{taskfile};
  my $command;

  if( ( $answerFile eq "default" ) && ( $hostprofilefile eq "default" )  &&
      ( $taskFile eq "default" ) ) {
     $taskFile = VDNetLib::TestData::TestConstants::TASKLIST_FILE;
     $hostprofilefile = VDNetLib::TestData::TestConstants::HOSTPROFILE_FILE;
     $answerFile = VDNetLib::TestData::TestConstants::ANSWER_FILE;
  }
  $command = "esxhpcli tasklist -o " .
              $taskFile . " -a " .
              $answerFile . " " .
              $hostprofilefile;
  $vdLogger->Debug("Generate task list on " . $self->{hostIP} . ":". $command );
  my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
  if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
     $vdLogger->Error("Failed to execute command $command on " .
                       $self->{hostIP});
     VDSetLastError("ESTAF");
     return FAILURE;
  }
  return SUCCESS;
}


########################################################################
#
# ApplyTaskList --
#      This method will apply task list from hostprofile
#
# Input:
#      taskFile: task file name(with absolute path)
#
# Results:
#      Return  "SUCCESS" if apply tasklist command pass
#      Returns "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub ApplyTaskList
{
  my $self = shift;
  my %args = @_;
  my $taskFile = $args{taskfile};
  my $command;

  if ( $taskFile ne "default" ) {
     $command = "esxhpcli applytasklist " .
                $taskFile;
  } else {
     $command = "esxhpcli applytasklist  " .
                VDNetLib::TestData::TestConstants::TASKLIST_FILE;
  }
  $vdLogger->Debug("Apply task list on " . $self->{hostIP} . ":". $command );
  my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
  if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
     $vdLogger->Error("Failed to execute command $command on " .
                       $self->{hostIP});
     VDSetLastError("ESTAF");
     return FAILURE;
  }
  return SUCCESS;
}




########################################################################
#
#  HostSetupPostProcess
#      This method will write set up file after host setup
#
# Input:
#      seedOfFileName : a tring that contained in file name
#
# Results:
#      Return  "SUCCESS" if succeed
#      Returns "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub HostSetupPostProcess
{
  my $self = shift;
  my $seedOfFileName = shift;
  my $cmd;
  my $result;

  # if file does not exist, return TRUE
  $cmd = "touch /tmp/vdnet-" . $seedOfFileName;
  $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $cmd);
  if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
     $vdLogger->Error("STAF command $cmd failed on host " . $self->{hostIP} .
                      Dumper($result));
     VDSetLastError("ESTAF");
     return FAILURE;
  }
  return SUCCESS;
}

########################################################################
#
# ReconfigureFirewall --
#      This method will Change Firewall RuleSet
#
#      reconfigurefirewall:  true/false
#      ruleset: name of the firewall rule (required)
#
# Results:
#      Returns "SUCCESS", if the setting successfully.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub ReconfigureFirewall
{
   my $self    = shift;
   my $reconfigurefirewall   = shift;
   my $ruleset = shift;
   my $result;

   if ( defined $ruleset ){
      $result = $self->ConfigureRuleSet($ruleset);
      return $result;
   } else {
      $vdLogger->Error("Ruleset not defined");
      return FAILURE;
   }
}


########################################################################
#
# ConfigureRuleSet --
#      This method will Change Firewall RuleSet
#
#      ruleset: name of the firewall rule (required)
#
# Results:
#      Returns "SUCCESS", if the setting successfully.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
########################################################################

sub ConfigureRuleSet
{
   my $self    = shift;
   my $ruleset = shift;
   my $command;
   my $status;
   my $result;

   $command = "esxcli network firewall ruleset list | grep $ruleset";
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if (($result->{rc} != 0) || ($result->{stderr} =~ m/.*Errors:.*/i)){
      $vdLogger->Error("STAF command to list firewall rule failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ( $result->{stdout} =~ /true/i) {
       $status = "false";
   } else {
       $status = "true";
   }
   $vdLogger->Info("reault :  $result->{stdout} status: $status");
   $command = "esxcli network firewall ruleset set -e $status -r $ruleset";
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if (($result->{rc} != 0) || ($result->{stderr} =~ m/.*Errors:.*/i)){
      $vdLogger->Error("STAF command to set firewall status failed" .
                     Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Successfully set the firewall ruleset $ruleset to $status");
   return SUCCESS;
}


#############################################################################
#
# GetDatastore--
#     Method to get the datastore object.
#
# Input:
#     arrayOfSpecs: array of specs where each spec contains datastore name
#
# Results:
#     array references of datastore objects, if SUCCESS
#     FAILURE, if datastore is not found or in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub GetDatastore
{
  my $self = shift;
  my $arrayOfSpecs = shift;
  my $inlineHostObject = $self->GetInlineHostObject();

  my @resultArray;
  foreach my $element (@$arrayOfSpecs) {

     my %options = %$element;
     my $name = $options{name};

     my $datastoreObj = VDNetLib::Host::Datastore->new(
                                           'hostObj'    => $self,
                                           'datastore'   => $name,
                                           'stafHelper' => $self->{stafHelper}
                                           );
     if ($datastoreObj eq FAILURE) {
         $vdLogger->Error("Failed to create VDNetLib::Host::Datastore".
                          $name);
         VDSetLastError("EOPFAILED");
         return FAILURE;
     }
     push @resultArray, $datastoreObj;
  }

  return  \@resultArray;
}

##############################################################################
#
# GetMaintenanceModeRequireStatus --
#    Get MaintenanceMode requirement status
#
# Input:
#      maintenancemodestatus: true/false
#      hostprofilefile: host profile file (with absolute path)
#      answerFile: answer file (with absolute path)
#
# Results: return status  hash if success
#          FAILURE on failure
#
###############################################################################

sub GetMaintenanceModeRequireStatus
{
   my $self            = shift;
   my %args            = @_;
   my $status          = $args{maintenancemodestatus};
   my $hostprofilefile = $args{hostprofilefile};
   my $answerFile      = $args{answerfile};
   my $command;

   $command = "esxhpcli gtlr -a " .
               $answerFile . " " .
               $hostprofilefile;
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                      $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to execute command $command on " .
                        $self->{hostIP} . Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ( $status eq "true" ) {
     if ( $result->{stdout} =~ /(maintenanceModeRequired|rebootRequired)/i ) {
        $vdLogger->Debug("Found the correct status: $result->{stdout}");
        return SUCCESS;
     } else {
        $vdLogger->Debug("Can't find the correct status: $result->{stdout}");
        return FAILURE;
     }
   } else {
     if ( $result->{stdout} =~ /(maintenanceModeRequired|rebootRequired)/i ) {
        $vdLogger->Debug("Can't find the correct status: $result->{stdout}");
        return FAILURE;
     } else {
        $vdLogger->Debug("Found the correct status: $result->{stdout}");
        return SUCCESS;
     }
  }
}


########################################################################
#
# ConfigurePCIPassThru --
#      This method configure PCIPassThru or PCIPassThru config profile
#
# Input:
#      hostprofilefile: hostprofile file
#      configure: pci key (true/false/ignore/apply)
#      id: pci device id
#
# Results:
#      Return "SUCCESS" if command pass
#      Return "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub ConfigurePCIPassThru
{
   my $self            = shift;
   my %args            = @_;
   my $configure       = $args{configurepcipassthru};
   my $hostprofilefile = $args{hostprofilefile};
   my $id              = $args{id};
   my $result;

   my $hash = {
     'hostprofilefile' => $hostprofilefile,
     'configure' => $configure,
     'id'        => $id,
   };
   if ($configure =~ /(true|false)/i) {
      if (not defined $id) {
         $result = $self->ConfigurePCIPassThruConfigProfile($hash);
         return $result;
      } else {
         $result = $self->SetPCIPassThruDeviceById($hash);
         return $result;
      }
   } elsif ($configure =~ /(ignore|apply)/i) {
      $result = $self->ConfigurePCIPassThruProfile($hash);
      return $result;
   } else {
      $vdLogger->Error("PCIPassThru Key not specified $configure");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
}


########################################################################
#
# ConfigurePCIPassThruConfigProfile --
#      This method will edit PCI PassThru device parameters
#
# Input:
#      hostprofilefile: hostprofile file
#
# Results:
#      Return "SUCCESS" if profile command pass
#      Return "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub ConfigurePCIPassThruConfigProfile
{
   my $self            = shift;
   my $hash_ref        = shift;
   my %args            = %$hash_ref;
   my $hostprofilefile = $args{hostprofilefile};
   my $pcihash;
   my $set;

   if (not defined $hostprofilefile){
      $vdLogger->Error("hostprofile file not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $pcihash = $self->GetFirstPCIPassThruInformation($hostprofilefile);

   if ($pcihash eq FAILURE) {
      $vdLogger->Error("This is not a PCI PASS Through Device " );
      return FAILURE;
   }
   my $enable = $pcihash->{enable};
   if ($enable =~  /True/i ) {
      $set = "False";
   } elsif ($enable =~ /False/i) {
      $set = "True";
   }
   my $path = $pcihash->{path};
   my $hash = {
     'hostprofilefile' => $hostprofilefile,
     'path'    => $path,
     'policy'  => VDNetLib::TestData::TestConstants::PCI_CONFIG_POLICY,
     'policyOption' => VDNetLib::TestData::TestConstants::PCI_CONFIG_OPTION,
     'params'  => "enabled=$set"
   };
   my $result = $self->EditProfileInformation($hash);
   if ($result eq "FAILURE") {
      $vdLogger->Error("Fail to Configure PCIPassThruConfig Profile");
      return FAILURE;
   }
   $vdLogger->Debug("Configured PCIPassThruConfig Profile");
   return SUCCESS;
}


########################################################################
#
# ConfigurePCIPassThruProfile --
#      This method apply  PCI PassThru Options and parameters
#
# Input:
#      hostprofilefile: Host profile file
#      configure: PASSTHRU Parameter
#
# Results:
#      Return "SUCCESS" if profile command pass
#      Return "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub ConfigurePCIPassThruProfile
{
   my $self            = shift;
   my $hash_ref        = shift;
   my %args            = %$hash_ref;
   my $hostprofilefile = $args{hostprofilefile};
   my $configure       = $args{configure};
   my $policyOption;

   if ((not defined $hostprofilefile) || (not defined $configure)){
      $vdLogger->Error("hostprofile file or policy option not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($configure  eq "ignore") {
      $policyOption = VDNetLib::TestData::TestConstants::PCI_IGNORE_OPTION;
   } else {
      $policyOption = VDNetLib::TestData::TestConstants::PCI_APPLY_OPTION;
   }
   my $hash = {
      'hostprofilefile' => $hostprofilefile,
      'path' => VDNetLib::TestData::TestConstants::PCI_PROFILE,
      'policy' => VDNetLib::TestData::TestConstants::PCI_APPLY_POLICY,
      'policyOption' =>  $policyOption
   };
   my $result = $self->EditProfileInformation($hash);
   return $result;
}


########################################################################
#
# GetFirstPCIPassThruInformation --
#      This method apply  PCI PassThru Options and parameters
#
# Input:
#      Host profile file
#
# Results:
#      Return First PCIPassThru Info if SUCCESS
#      Return "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetFirstPCIPassThruInformation
{
   my $self            = shift;
   my $hostprofilefile = shift;

   my $paththru = {
      'hostprofilefile' => $hostprofilefile,
      'path' => VDNetLib::TestData::TestConstants::PCI_PROFILE . "." .
                  VDNetLib::TestData::TestConstants::PCI_CONFIG_PROFILE
   };
   my $pcihash = $self->FindFirstPCIDevicePath($paththru);
   if ( not defined $pcihash->{path} ) {
      $vdLogger->Error("Can't Find PCI PassThrough Info");
      return FAILURE;
   }
   my $newpath = $pcihash->{path};
   my $newhash = {
      'hostprofilefile' => $hostprofilefile,
      'path' =>  $newpath
   };
   my $hash;
   my $result = $self->GetProfileInformation($newhash);
   my @info = split(/\n/, $result);
   foreach my $pci (@info) {
      if ($pci =~ /deviceId = (\S+)/) {
         $hash->{id} = $1;
         next;
      }
      if ($pci =~ /enabled = (\w+)/) {
         $hash->{enable} = $1;
         $hash->{path} = $newpath;
         return $hash;
      }
   }
   $vdLogger->Debug("Can't find PCI device from hostprofile $hostprofilefile");
   return FAILURE;
}


########################################################################
#
# FindFirstPCIDevicePath --
#      Find the firest PCIDevice and Path in PCI hostprofile
#
# Input:
#      hostprofilefile: hostprofile file
#      path: profile path
#
# Results:
#      Return pcihash with Device, enable, path if SUCCESS
#      Return "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub FindFirstPCIDevicePath
{
   my $self            = shift;
   my $hash_ref        = shift;
   my %args            = %$hash_ref;
   my $hostprofilefile = $args{hostprofilefile};
   my $path            = $args{path};
   my @pciinfo;
   my $pcihash;

   my $hash = {
      'hostprofilefile' => $hostprofilefile,
      'path' =>  $path
   };
   my $result = $self->GetProfileInformation($hash);
   @pciinfo = split(/\n/, $result);
   foreach my $pci (@pciinfo) {
      if ($pci =~ /PCI Device\s+\"(\S+)\"/) {
         next;
      } elsif ($pci =~ /Enabled =\s+(\w+)/) {
         $pcihash->{enable} = $1;
         next;
      } elsif ($pci =~ /Path =/) {
         my ($name, $path) = split('=', $pci);
         $pcihash->{path} = $path;
         last;
      } else {
         $vdLogger->Debug("Can't Find PCI Path Through Device and Path");
         return FAILURE;
      }
   }
   $vdLogger->Debug("PCI hash: $pcihash");
   return $pcihash;
}


########################################################################
#
# GetPCIIdInfo --
#      Find the firest PCIDevice and Path in PCI hostprofile
#
# Input:
#      pciID:  PCI ID
#
# Results:
#      Return pcihash with Device, enable, path if pass
#      Return "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetPCIIdInfo
{
   my $self = shift;
   my $pciID = shift;
   my $pcihash;

   my $command = "localcli --plugin-dir /usr/lib/vmware/esxcli/int". " ".
                 " hardwareinternal pci listpassthru";
   $vdLogger->Debug("command:" .$command . " ". $self->{hostIP});
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   $vdLogger->Debug("GetFirstPCIID Result: " .
                       Dumper($result));
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to execute command $command on " .
                       $self->{hostIP});
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   my @pcilist = split(/\n/, $result->{stdout});
   foreach my $pci (@pcilist) {
      if ($pci =~ /Device ID\s+Enabled/) {
         next;
      } elsif ($pci =~ /----/) {
         next;
      } elsif ($pci =~ /\d+:\d+/) {
         my ($id, $enabled) = split(' ', $pci);
         if ($id =~ /$pciID/i) {
            $pcihash->{id} = $id;
            $pcihash->{enabled} = $enabled;
            last;
         } else {
            next;
         }
      } else {
         $vdLogger->Debug("Can't Find PCI PassThrough ID");
         return FAILURE;
      }
   }
   $vdLogger->Debug("PCI hash: $pcihash");
   return $pcihash;
}


########################################################################
#
# GetFirstPCIPassSThruInfo --
#      This method apply  PCI PassThru Options and parameters
#
# Input:
#      hostprofilefile: Host profile file
#      path: profile path
#
# Results:
#      Return First PCIPassThru Info if SUCCESS
#      Return "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetProfileInformation
{
   my $self            = shift;
   my $hash_ref        = shift;
   my %args            = %$hash_ref;
   my $hostprofilefile = $args{hostprofilefile};
   my $path            = $args{path};

   my $command = "esxhpedit dp " . $hostprofilefile . " -p " . $path;
   $vdLogger->Debug("command:" . $command );
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to execute command $command on " .
                       $self->{hostIP});
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Debug("Profile Information :" . $result->{stdout});
   return  $result->{stdout};
}


########################################################################
#
# EditProfileInformation --
#      This method will edit profile information
#
# Input:
#      hash with key: hostprofilefile
#      path:  profile path
#      policy: profile policy
#      policyOption: profile policy option
#      params: profile policy option parameter
#
# Results:
#      Return "SUCCESS" if profile command pass
#      Return "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub EditProfileInformation
{
   my $self            = shift;
   my $hash_ref        = shift;
   my %args            = %$hash_ref;
   my $hostprofilefile = $args{hostprofilefile};
   my $path            = $args{path};
   my $policy          = $args{policy};
   my $policyOption    = $args{policyOption};
   my $params          = $args{params};

   if ( ($path =~ /PnicUplinkProfile/i) ||
        ($path =~ /GenericStaticRouteProfile/i) ) {
      $path = $self->FindPathForHostProfile($hash_ref);
   }
   my $command = "esxhpedit editpolicy " .
                 $hostprofilefile . " " .  $path . " " .
                 $policy . " --setopt " . $policyOption;
   if (defined $params) {
      $command = $command . " --setparam " . $params;
   }
   $vdLogger->Debug("command:" . $command );
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   $vdLogger->Debug("result: $result->{exitCode} :  $result->{stdout}");
   if( ($result->{rc} != 0) || ($result->{exitCode} != 0) ){
      $vdLogger->Error("Failed to execute command $command on " .
                       $self->{hostIP});
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}


#######################################################################
#
# FindPathForHostProfile --
#      Find path for  hostprofile
#
# Input:
#      hostprofilefile: hostprofile file
#      path: profile path  search key
#
# Results:
#      Return Static Route Profile path if SUCCESS
#      Return "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub FindPathForHostProfile
{
   my $self            = shift;
   my $hash_ref        = shift;
   my %args            = %$hash_ref;
   my $hostprofilefile = $args{hostprofilefile};
   my $pathkey         = $args{path};
   my $vmkObj          = $args{adapter};

   if ( (not defined $hostprofilefile) || (not defined $pathkey ) ){
      $vdLogger->Error("hostprofile file or path not specified");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $vmknic = $vmkObj->{deviceId};
   my $command = 'esxhpedit dp ' .
               $hostprofilefile . ' ' .  '-p network -r | grep ' .
               $pathkey;
   if($pathkey =~ /GenericStaticRouteProfile/i){
      $command = $command . " | grep " . $vmknic;
   }
   $vdLogger->Debug("command:" . $command . " ". $self->{hostIP});
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                         $command);
   $vdLogger->Debug("result: $result->{exitCode} :  $result->{stdout}");
   if( ($result->{rc} != 0) || ($result->{exitCode} != 0) ){
      $vdLogger->Error("Failed to execute command $command on " .
      $self->{hostIP});
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   my($temp, $path) = split( /: /, $result->{stdout});
   chop($path);
   if ($path eq "") {
      $vdLogger->Error("Can't find hostprofile path" . Dumper($result));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   return $path;
}


########################################################################
#
# SetPCIPassThruDeviceById --
#      This method will enable/disable PCI PassThru device by PCI Id
#
# Input:
#      pciId:  pci id
#      enable: PASSTHRU Parameter (true/false)
#
# Results:
#      Return  "SUCCESS" if command pass
#      Returns "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub SetPCIPassThruDeviceById
{
   my $self     = shift;
   my $hash_ref = shift;
   my %args     = %$hash_ref;
   my $pciId    = $args{id};
   my $enable   = $args{configure};

   my $pcihash = $self->GetPCIIdInfo($pciId);
   if (not defined $pcihash->{id}) {
      $vdLogger->Error("This is not a PCI PassThrough Device " );
      return FAILURE;
   }
   if (not defined $enable){
      $vdLogger->Error("PCI Device command not specified");
      return FAILURE;
   }
   $enable = lc($enable);
   if ( $pcihash->{enabled} !~ /$enable/) {
      my $command = "localcli --plugin-dir /usr/lib/vmware/esxcli/int ".
                    "hardwareinternal pci setpassthru --device-id ".
                     $pciId . " --enable ". $enable;
      $vdLogger->Debug("command:" .$command . " ". $self->{hostIP});
      my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                        $command);
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to execute command $command on " .
                          $self->{hostIP});
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      return SUCCESS;
   }
   $vdLogger->Debug("PCI Device $pciId already set to  $pcihash->{enabled}");
   return SUCCESS;
}


########################################################################
#
# GetComplianceStatus --
#      This method will get Compliance Status
#
# Input:
#      hostprofilefile: host profile file (with absolute path)
#      answerFile: answer file (with absolute path)
#      status: true/false
#
# Results:
#      Return  "SUCCESS" if generate answerfile command pass
#      Returns "FAILURE" in case of any error.
#
# Side effects:
#      None
#
########################################################################

sub GetComplianceStatus
{
  my $self            = shift;
  my %args            = @_;
  my $hostprofilefile = $args{hostprofilefile};
  my $answerFile      = $args{answerfile};
  my $status          = $args{compliancestatus};
  my $command;
  my $output;

  if((not defined $hostprofilefile) || (not defined  $answerFile ) ||
    (not defined $status)) {
    $vdLogger->Error("HostProfile File, AnswerFile or Status not provided ");
    VDSetLastError("ENOTDEF");
    return FAILURE;
  }
  $command = "esxhpedit cc -a $answerFile $hostprofilefile";
  $vdLogger->Debug("command:" .$command . " ". $self->{hostIP});
  my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
  $vdLogger->Debug("result: $result->{exitCode} :  $result->{stdout}");
  if ( $result->{rc} != 0 ) {
     $vdLogger->Error("Failed to execute command $command on " .
                       $self->{hostIP});
     VDSetLastError("ESTAF");
     return FAILURE;
  }
  if ($result->{stdout} =~ /Command checkcompliance status: (\w+)/) {
     $output = $1;
  } else {
     $vdLogger->Debug("Can't find compliance status");
     return FAILURE;
  }
  if (( $status =~ /true/i ) && ($output eq "compliant")) {
     $vdLogger->Debug("Found correct status: $output ");
     return SUCCESS;
  } elsif (( $status =~ /false/i ) && ($output eq "nonCompliant" )){
     $vdLogger->Debug("Found correct status: $output");
     return SUCCESS;
  } else {
     $vdLogger->Debug("Can't find the correct status: $result->{stdout}");
     return FAILURE;
  }
}


#######################################################################
#
# ConfigureProfile--
#       Method to perform actions on software profile
#
# Input:
#       Operation : Update
#       BuildNumber:1337676
#       SignatureCheck:1/0
#
#
# Results:
#        SUCCESS if the profile is updated
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub ConfigureProfile
{
  my $self = shift;
  my $specs  = shift;
  my %args = %$specs;

  #changing parameters to lower case
  %args = (map { $_ => lc  $args{$_}} keys %args);

   my $operation = $args{profile};

   if (not defined $args{profile}) {
      $args{profile} = "update";
   }

   my $operationList = {
      update => 'UpdateProfileandReboot',
   };

   my $method = $operationList->{$operation};
   if(not defined $method) {
      $vdLogger->Error("Unknown Profile Operation specified: $operation");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return $self->$method(%$specs);
}


#######################################################################
#
# UpdateProfileandReboot--
#       Update ESX with the build number given
#
# Input:
#       BuildNumber:1337676
#       Signaturecheck:1/0
#
# Results:
#        SUCCESS upon completion
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub UpdateProfileandReboot
{

   my $self    = shift;
   my %args    = @_;

   my $builds = $args{build};
   my $sigcheck = $args{signaturecheck};
   my ($command, $result);
   my $host = $self->{hostIP};
   my $buildNumber;

   foreach $buildNumber (@$builds) {
      if (not defined $buildNumber) {
         $vdLogger->Error("Buildnumber not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      if ($sigcheck) {
         $sigcheck = "";
      } else {
         $sigcheck = "  --no-sig-check";
      }

      #checking the valididty of the build number
      if ($buildNumber !~ m/\d{6,}/) {
         $vdLogger->Error("Not a valid ESX BuildNumber:$buildNumber");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      my $sandboxBuild = 0;
      if ($buildNumber =~ /sb-/i) {
         $sandboxBuild = 1;
         $buildNumber =~ s/sb-//g;
      } elsif ($buildNumber =~ /ob-/i) {
         $sandboxBuild = 0;
         $buildNumber =~ s/ob-//g;
      }

      my $buildNum = $self->GetESXBuildNumber();
      $buildNum =~ s/sb-//g;

      if ($buildNum == $buildNumber) {
         $vdLogger->Warn("The current build number of the " .
                         "Host:$buildNum is SAME as Given " .
                         "UpgradeBuild:$buildNumber ");
         return SUCCESS;
      }
      if ($buildNumber < $buildNum) {
         $vdLogger->Warn("The current build number of the " .
                         "Host:$buildNum is GREATER than the Given  " .
                         "UpgradeBuild:$buildNumber ");
      }

      $vdLogger->Info("Current ESX build is:$buildNum " .
                      "upgrading to build: $buildNumber ... " );

      my $globalConfigObj = new VDNetLib::Common::GlobalConfig;
      my $buildpath1 = $globalConfigObj->BUILDWEB;
      my $buildpath2 = $globalConfigObj->BUILDWEB_INDEX;

      my $path;
      if ($sandboxBuild) {
         $path = $buildpath1 . "sb-" . $buildNumber . $buildpath2;
      } else {
         $path = $buildpath1 . "bora-" . $buildNumber . $buildpath2;
      }

      #
      #command example: esxcli software profile update
      #-d http://build-squid.eng.vmware.com/build/mts/
      #release/bora-1363779/publish/CUR-depot/ESXi/index.xml -p ESXi-
      #6.0.0-1363779-standard --no-sig-check
      #
      my $profile = $self->GetProfile($path);
      $command =  "esxcli software profile update";
      $command .=  " --depot " . $path;
      $command .=  " --profile " . $profile ;
      $command .=  $sigcheck;
      $vdLogger->Debug("Uprading ESX command: $command");
      $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

      if (($result->{rc} != 0) || ($result->{exitCode} != 0) ||
          ($result->{stdout} =~  m/Error/)) {
         $vdLogger->Debug("Failed to run command:$command on host " .
                          ":$self->{hostIP} " .Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/Reboot Required: true/) {
         $vdLogger->Info("Rebooting ESX Host to update the build");

         if ($self->Reboot() eq "FAILURE" ) {
            $vdLogger->Error("Reboot failed on host:$self->{hostIP}");
            VDSetLastError("EFAIL");
            return FAILURE;
         }
      }

      $buildNum = $self->GetESXBuildNumber();
      $buildNum =~ s/sb-//g;

      if ($buildNumber != $buildNum) {
         $vdLogger->Error("Upgrade host failed with Build:$buildNumber ");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      $vdLogger->Info("Upgraded host with Build:$buildNumber " .
                      "Successfully " );
   }
   return SUCCESS;
}


######################################################################
#
# GetESXBuildNumber --
#     Method to validate whther a given build number is valid
#
#
# Input:
#     Buildnumber : ESX build number
#
#
# Results:
#     Return buildNumber if success
#     Failure,In case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetESXBuildNumber
{
  my $self = shift;

  my $command = "vmware -v";
  my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to get build version failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $build;
   if ($result->{stdout} =~ m/(\d{6,})/) {
      $build = $1;
   } else {
      $vdLogger->Error("Build number not found :" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;

   }
   return $build;
}


######################################################################
#
# GetProfile --
#     Method to get build profile
#
#
# Input:
#     path : http path for the build
#
#
# Results:
#     Return buildprofile if success
#     Failure,In case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetProfile
{
  my $self = shift;
  my $path = shift;
  my $profile;
  my ($command,$result);

  $command = " esxcli software sources profile list ";
  $command .= "-d " . $path;

  $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
  if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Debug("Failed to run command:$command" .
                        " on host:$self->{hostIP}".
                        Dumper($result));
      VDSetLastError("ESTAF");
  }

  if($result->{stdout} =~ m/((.*)standard)/) {
      $profile = $1;
  }

  return $profile;
}


###############################################################################
#
# GetVMDisplayName --
#       API returns the VM diaplay name, for example:
#       NSX_Controller_c254667d-dac4-4860-9cf9-390c899fb403
#
# Input:
#       vmxName - controller VM vmxname is requested (Mandatory)
#
# Results:
#       VM Display name if found
#       FAILURE - In case of error
#
# Side effects:
#       None
#
###############################################################################

sub GetVMDisplayName
{
   my $self      =  shift;
   my %args      = @_;
   my $vmxName     = $args{vmxname};
   my $ret = $self->CheckForPatternInVMX($vmxName,
                                         "^displayName",
                                         $self->{stafHelper},
                                         $self->{hostType});
    if ((not defined $ret) or ($ret eq FAILURE)) {
       $vdLogger->Error("STAF error while retrieving display name of " .
                        "$vmxName, on $self->hostIP");
       VDSetLastError(VDGetLastError());
       return FAILURE;
    }

    if ($ret eq "") {
       $vdLogger->Error("Display name is empty for $vmxName, on $self->hostIP");
       VDSetLastError("ENOTDEF");
       return FAILURE;
    }

    $ret =~ s/\s*//g;
    $ret =~ s/\n//g;
    # On ESX its displayName and on WS its displayname.
    $ret =~ s/displayName=//ig;
    $ret =~ s/\"//g;
    my $vmDisplayName = $ret;
    $vdLogger->Info("Display name is $vmDisplayName for $vmxName, on $self->hostIP");
    return $vmDisplayName;
}


########################################################################
#
# GetVMXFile --
#      Returns VMX file as, [Storage] WinXP/WinXP.vmx, given the VM IP
#      and the corresponding hostObj in the testbed.
#
# Input:
#      mac     : MAC address of VM (Mandatory)
#
# Results:
#      VMX file name relative to its DataStore and vm IP as mentioned above
#      FAILURE in case of any error
#
# Side effects:
#      None
#
########################################################################

sub GetVMXFile
{
   my $self    = shift;
   my $mac     = shift;
   my $hostIP  = $self->{hostIP};

   if ((not defined $mac) || ($mac eq FAILURE)) {
      $vdLogger->Error("parameter \$mac is mandatory");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $mac =~ s/-/:/g;

   # first seach vmx based on vim-cmd
   my $result = $self->GetVMXBasedOnVimCmd($hostIP, $mac);
   if ($result ne FAILURE) {
      return $result;
   }
   #
   # in case of the vms are powered on using /bin/vmx command then
   # vim-cmd will not list un-registered VMs hence use vsish to get it.
   #
   $result = $self->GetVMXBasedOnVsish($hostIP, $mac);
   if ($result ne FAILURE) {
      return $result;
   }

   $vdLogger->Error("Failed to fetch VMX file name for ip: " .  $hostIP);
   VDSetLastError(VDGetLastError());
   return FAILURE;
}


########################################################################
#
# GetVMXFileByDisplayName --
#      Returns VMX file as, [Storage] WinXP/WinXP.vmx, given the VM IP
#      and the corresponding hostObj in the testbed.
#
# Input:
#      vmDisplayName  : like mqing-vdnet-nsxcontroller-ob-2148051-1-rtqa3-mqing
#
# Results:
#      VMX file name relative to its DataStore as mentioned above
#      FAILURE in case of any error
#
# Side effects:
#      None
#
########################################################################

sub GetVMXFileByDisplayName
{
   my $self    = shift;
   my $displayName  = shift;
   my $hostIP  = $self->{hostIP};

   my $command = "esxcli vm process list | grep $displayName | grep '\/vmfs\/'";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Debug("Failed to run command:$command" .
                        " on host:$self->{hostIP}".
                        Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   #
   # sample output of esxcli vm process list
   # esxcli vm process list
   # mqing-vdnet-nsxcontroller-ob-2148051-1-rtqa3-mqing
   #    World ID: 1000018660
   #    Process ID: 0
   #    VMX Cartel ID: 1000018645
   #    UUID: 56 4d 9f 28 d9 46 72 d5-80 09 f5 b2 64 70 44 0a
   #    Display Name: mqing-vdnet-nsxcontroller-ob-2148051-1-rtqa3-mqing
   #    Config File: /vmfs/volumes/5420e3f3-9c62bd07-cbc9-0050569d7415/mqing-vdnet-nsxcontroller-ob-2148051-1-rtqa3-mqing/mqing-vdnet-nsxcontroller-ob-2148051-1-rtqa3-mqing.vmx

   #
   my $line = $result->{stdout};
   if ($line =~ m/(\/vmfs\/.*vmx)/i) {
        $vdLogger->Debug("Fetched vmx name is $1");
        return $1;
   }
   $vdLogger->Error("Failed to fetch VMX file name for ip: " .  $hostIP);
   VDSetLastError(VDGetLastError());
   return FAILURE;
}


########################################################################
#
# GetVMXBasedOnVimCmd --
#      Returns VMX file as, [Storage] WinXP/WinXP.vmx, given the VM IP
#      and the corresponding hostObj in the testbed.
#           1. Get VMX files of all the VMs using vim-cmd.
#           2. Grep the MAC address in each of the vmxFile
#           3. If the MAC is found return the VMX
#           4. If it is not found in any of the VMX files, return
#              undef
#
# Input:
#      hostIP  : IP address of host (Mandatory)
#      mac     : MAC address of VM (Mandatory)
#
# Results:
#      VMX file name relative to its DataStore and vm IP as mentioned above
#      FAILURE in case of any error
#
# Side effects:
#      None
#
########################################################################

sub GetVMXBasedOnVimCmd
{
   my $self   = shift;
   my $hostIP = shift;
   my $mac    = shift;
   my $vmxFile;
   my $storage;
   my $vmx;
   my $command = "vim-cmd vmsvc/getallvms ";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Debug("Failed to run command:$command" .
                        " on host:$self->{hostIP}".
                        Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   #
   # sample output of vim-cmd vmsvc/getallvms
   # Vmid Name      File               Guest OS Version   Annotation
   # 112 sles11-64 [Storage1] sles11-32/sles11-32.vmx sles10Guest vmx-07
   #
   my @vimcmd = split(/\n/, $result->{stdout});
   if ( scalar(@vimcmd) > 1 ) {
      foreach my $vmline (@vimcmd) {
         $vmline =~ s/\s+/ /g;
         $vmline =~ s/\t|\n|\r//g;
         # find out the matched vm infomation line
         if ( $vmline =~ /.* (\[.*\]) (.*\.vmx) .*/ )  {
            $storage = $1;
            $vmx     = $2;
            $vmxFile = "$storage "."$vmx";
            $vdLogger->Debug("vmxFile: $vmxFile");
            if ((defined $storage) && (defined $vmx)) {
               $vdLogger->Debug("Got storage name and vmx file name, " .
                               "begin to use mac address to get the nic name");
               my $eth = VDNetLib::Common::Utilities::GetEthUnitNum(
                         $hostIP,
                         VDNetLib::Common::Utilities::GetAbsFileofVMX($vmxFile),
                         $mac);
               if ( $eth eq FAILURE ) {
                  #
                  # ignore the error as it is possible not to find the mac
                  # address in this vmxFile
                  #
                  $vdLogger->Debug("not found the mac address in the $vmxFile");
                  VDCleanErrorStack();
                  next;
               } elsif ($eth =~ /^ethernet/i) {
                  # storing the vmx path in absolute file format
                  $vmxFile = VDNetLib::Common::Utilities::GetAbsFileofVMX($vmxFile);
                  $vdLogger->Debug("ethernet type nic, the vmx absolute " .
                                   "file path is $vmxFile");
                  return $vmxFile;
               } else {
                  $vdLogger->Info("nic type is $eth, maybe used in future");
               }
            }
         }
      }
   }

   $vdLogger->Error("Not found the vmx file name for the mac $mac");
   VDSetLastError(VDGetLastError());
   return FAILURE;
}


########################################################################
#
# GetVMXBasedOnVsish --
#      Returns VMX file as, [Storage] WinXP/WinXP.vmx, given the VM IP
#      and the corresponding hostObj in the testbed.
#
# Input:
#      hostIP  : IP address of host (Mandatory)
#      mac     : MAC address of VM (Mandatory)
#
# Results:
#      VMX file name relative to its DataStore and vm IP as mentioned above
#      FAILURE in case of any error
#
# Side effects:
#      None
#
########################################################################

sub GetVMXBasedOnVsish
{
   my $self = shift;
   my $hostIP = shift;
   my $mac    = shift;
   my $vmxFile;
   #
   # in case of the vms are powered on using /bin/vmx command then
   # vim-cmd will not list un-registered VMs hence use vsish to get it.
   #
   my $command = "vsish -e ls /vm";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Debug("Failed to run command:$command" .
                        " on host:$self->{hostIP}".
                        Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my @vimcmd = split(/\n/, $result->{stdout});
   foreach my $vmline (@vimcmd) {
      $command = "vsish -e get /vm/$vmline" .
                             "vmmGroupInfo | grep \"vmx\" ";
      my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
         $vdLogger->Debug("Failed to run command:$command" .
                        " on host:$self->{hostIP}".
                        Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ /\s*config file path:(.*)/ ) {
         $vmxFile = $1;
         chomp($vmxFile);
      } else {
         next;
      }

      if ( (defined $vmxFile) && ($vmxFile =~ /\.vmx/) ) {
         # if MAC address is found then we found vmx
         my $eth = VDNetLib::Common::Utilities::GetEthUnitNum($hostIP,
                                                              $vmxFile, $mac);
         if ($eth eq FAILURE) {
            # ignore the error as it is possible not to find the mac
            # address in this vmxFile
            VDCleanErrorStack();
            next;
         } elsif  ($eth =~ /^ethernet/i) {
            #
            # vsish reports the vmx file in canonical format, change
            # it to storage format as required by VMOperations module
            # The way it is done, is get the ls -l /vmfs/volumes output
            # match the symlink pointer of the storage with the canonical
            # directory in the path reported by vsish.
            #
            $command = "ls parms -l " .
                        VDNetLib::Common::GlobalConfig::VMFS_BASE_PATH;
            my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
            if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
               $vdLogger->Debug("Failed to run command:$command" .
                                " on host:$self->{hostIP}".
                                Dumper($result));
               VDSetLastError("ESTAF");
               return FAILURE;
            }

            my @listOfFiles = split(/\n/, $result->{stdout});
            foreach my $line (@listOfFiles) {
               # lrwxr-xr-x    1 root     root         35 Aug  6 18:21
               # Storage-1 -> 495028af-13fdc8af-c0e7-00215a47b2ce
               if ( $line =~ /.*\d+\:\d+ (.*?) -> (.*)/ ) {
                  my $storage = $1;
                  my $datastore = $2;
                  if ( $vmxFile =~ /$datastore/ ) {
                     $vmxFile =~ s/\/vmfs\/volumes\/$datastore\//\[$storage\] /;
                  }
               }
            }
            # storing the vmx path in absolute file format
            $vmxFile = VDNetLib::Common::Utilities::GetAbsFileofVMX($vmxFile);
            return $vmxFile;
         }
      }
   }

   $vdLogger->Error("Failed to fetch VMX file name based on vsish for the mac $mac");
   VDSetLastError(VDGetLastError());
   return FAILURE;
}


########################################################################
#
# GetVmMac --
#     Method to get vm mac address based on the ip address, this method
#     not need vm staf tool installed.
#
# Input:
#     vmIP         : vm ip address
#
# Results:
#     return vxlan controller mac address;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetVmMac
{
   my $self = shift;
   my $vmIP = shift;
   my $vmAdapterVSIPort;
   my $vmAdapterPortID;
   my $vmAdapterMac;
   my $vmAdapterSwitchName;
   my $portStatus;

   $vmAdapterVSIPort = $self->GetvNicVSIPort($vmIP);
   if (not defined $vmAdapterVSIPort) {
      $vdLogger->Error("Fetch VM net adapter VSI port info failed ");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("vsi port index is ".$vmAdapterVSIPort);
   #vmAdapterVSIPort value should be like "/net/portsets/vSwitch0/ports/16777218"
   if ($vmAdapterVSIPort =~ /\/net\/portsets\/(.*)\/ports\/(.*)/i) {
      $vmAdapterSwitchName = $1;
      $vmAdapterPortID = $2;
   }
   if (not defined $vmAdapterSwitchName) {
      $vdLogger->Error("Fetch VM net adapter switch name failed ");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if (not defined $vmAdapterPortID) {
      $vdLogger->Error("Fetch VM net adapter port ID failed ");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $statusPath = "/net/portsets/" . $vmAdapterSwitchName . "/ports/" .
                    $vmAdapterPortID . "/status";
   my $command = "vsish -e get $statusPath";
   $vdLogger->Info("will execute command $command on host " . $self->{hostIP});
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if ($result->{rc} != 0) {
      $vdLogger->Debug("STAF returned result is  " . Dumper($result));
      $vdLogger->Error("Failed to execute command $command on " .
                       $self->{hostIP});
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($result->{stdout} =~ /fixed Hw Id:(.*):/i) {
      $vmAdapterMac = $1;
   }
   if (not defined $vmAdapterMac) {
      $vdLogger->Error("Unable to get mac address for vm $vmIP from vsish node");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $vmAdapterMac;
}


######################################################################
#
# VerifyControllerInfoOnHost --
#      Method to verify controller info on host
# Input:
#      None
#
# Results:
#      A result hash containing the following attribute
#         status_code => SUCCESS/FAILURE
#         response    => array consisting of serverdata
#         error       => error code
#         reason      => error reason
#
# Side effects:
#      None
#
########################################################################

sub VerifyControllerInfoOnHost
{
   my $self = shift;
   my @serverData;
   my $resultHash = {
     'status' => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };
   my $command = "cat /etc/vmware/netcpa/config-by-vsm.xml";
   my $hostIP = $self->{hostIP};
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $command);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
       $vdLogger->Debug("Failed to run command:$command" .
                         " on host:$self->{hostIP}".
                         Dumper($result));
       VDSetLastError("ESTAF");
       $resultHash->{reason} = "Failed to run command " .
                             "cat /etc/vmware/netcpa/config-by-vsm.xml";
       return $resultHash;
   }
   my $ref = XMLin($result->{stdout},ForceArray => 1);
   my $connection = $ref->{connectionList}->[0]->{connection};
   my ($key,$value,$sslenable,$port,$server);
   while (($key,$value) = each %$connection) {
         $sslenable = $connection->{$key}{'sslEnabled'}->[0];
         $port = $connection->{$key}{'port'}->[0];
         $server = $connection->{$key}{server}->[0];
         push @serverData, {'port'  => $port, 'sslenabled' => $sslenable , server => $server};
   }

   $vdLogger->Debug("serverData got from the server: " . Dumper(@serverData));
   $resultHash->{status}   = "SUCCESS";
   $resultHash->{response} = \@serverData;
   return $resultHash;
}


###############################################################################
#
# GetVxlanSegmentIDOnHost --
#      This method will get segment id of vxlan from a host.
#
# Input:
#      None.
#
# Results:
#      Returns a segment id string, if succeeded.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub GetVxlanSegmentIDOnHost
{
   my $self = shift;
   my $cmd;
   my $result;
   my $segmentid;

   $result = $self->HostdRestart();
   if ($result eq FAILURE) {
      $vdLogger->Error("Hostd restart failed on host $self->{hostIP}");
      return FAILURE;
   }

   $cmd = "esxcli network vswitch dvs vmware vxlan list" .
          "|grep :|awk -F' ' '{print \$18}'";
   # this command above is used to get "SegmentID" section of it's output:
   #~ # esxcli network vswitch dvs vmware vxlan list
   #VDS ID                                          VDS Name  MTU  SegmentID  ..
   #----------------------------------------------- --------- ---- ---------- --
   #63 1c 23 50 6c 31 17 21-04 b9 e4 3f e3 3e b7 6f 1-vds-814 1600 172.19.0.0 ..

   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $cmd);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to run command: $cmd". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $segmentid = $result->{stdout};
   chomp ${segmentid};
   if ($segmentid =~ m/^\d+\.\d+\.\d+\.\d+/s) {
      $vdLogger->Info("Segment id on host $self->{hostIP} is $segmentid");
      return $segmentid;
   } else {
      $vdLogger->Error("Esxcli output incorrect:". Dumper($result->{stdout}));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}


###############################################################################
#
# GetVxlanVDSNameOnHost --
#      This method will get the name of DVS which used for vxlan on a host.
#
# Input:
#      None.
#
# Results:
#      Returns a dvs name string, if succeeded.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub GetVxlanVDSNameOnHost
{
   my $self = shift;
   my $cmd;
   my $result;
   my $dvsname = '';

   $result = $self->HostdRestart();
   if ($result eq FAILURE) {
      $vdLogger->Error("Hostd restart failed on host $self->{hostIP}");
      return FAILURE;
   }

   $cmd = "esxcli network vswitch dvs vmware vxlan list" .
          "|grep :|awk -F' ' '{print \$16}'";
   # this command above is used to get "VDS Name" section of it's output:
   #~ # esxcli network vswitch dvs vmware vxlan list
   #VDS ID                                          VDS Name  MTU  SegmentID  ..
   #----------------------------------------------- --------- ---- ---------- --
   #63 1c 23 50 6c 31 17 21-04 b9 e4 3f e3 3e b7 6f 1-vds-814 1600 172.19.0.0 ..

   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $cmd);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to run command: $cmd". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $dvsname = $result->{stdout};
   chomp ${dvsname};
   if ($dvsname ne '') {
      $vdLogger->Info("dvs name on host $self->{hostIP} is $dvsname");
      return $dvsname;
   } else {
      $vdLogger->Error("Esxcli output incorrect:" . Dumper($result->{stdout}));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}


###############################################################################
# GetVxlanContollerOnHost --
#      Method to get the controller info for a specified vxlan from host
#
# Input:
#      vxlanid : the id of the vxlan(required).
#
# Results:
#      Returns an string of controller info, if succeeded.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub GetVxlanContollerInfoOnHost
{
   my $self    = shift;
   my $vxlanid = shift;

   if (not defined $vxlanid) {
      $vdLogger->Error("vxlanid not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $dvsname = $self->GetVxlanVDSNameOnHost();
   if (FAILURE eq $dvsname) {
      $vdLogger->Error("Failed to get dvs name on: $self->{hostIP}");
      VDSetLastError(EFAIL());
      return FAILURE;
   }

   #esxcli --formatter=csv --format-param=show-header=false
   #--format-param=fields='Controller Connection' network
   #vswitch dvs vmware vxlan network list --vds-name  1-vds-851
   # --vxlan-id 5729
   #the output of the command above looks like below:
   #10.144.136.205 (up),
   my $cmd = "esxcli --formatter=csv --format-param=show-header=false " .
             "--format-param=fields='Controller Connection' network " .
             "vswitch dvs vmware vxlan network list --vds-name  $dvsname " .
             "--vxlan-id $vxlanid";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},$cmd);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to run command: $cmd". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($result->{stdout} eq '') {
      $vdLogger->Error("No controller info for vxlan: $vxlanid " .
                       "on host: $self->{hostIP}" . Dumper($result->{stdout}));
      VDSetLastError(EFAIL());
      return FAILURE;
   }

   chomp $result->{stdout};
   $vdLogger->Info("controller info for vxlan:$vxlanid on $self->{hostIP} is:" .
                    Dumper($result->{stdout}));

   return $result->{stdout};
}


###############################################################################
#
# GetVxlanMacEntryOnHost --
#      Method to get MAC entry from a host
#
# Input:
#      vxlanid : the id of the vxlan to the MAC entry from(required).
#
# Results:
#      Returns SUCCESS, if succeeded.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub GetVxlanMacEntryOnHost
{
   my $self    = shift;
   my $vxlanid = shift;

   if (not defined $vxlanid) {
      $vdLogger->Error("vxlanid not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $dvsname = $self->GetVxlanVDSNameOnHost();
   if (FAILURE eq $dvsname) {
      $vdLogger->Error("Failed to get dvs name on: $self->{hostIP}");
      VDSetLastError(EFAIL());
      return FAILURE;
   }

   #'esxcli --formatter=csv --format-param=show-header=false
   #  --format-param=fields=InnerMAC network vswitch dvs vmware vxlan network
   #  mac list --vds-name 1-vds-876 --vxlan-id 6847'
   #the output of the command above looks like below:
   #00:50:56:99:e7:08,
   #00:50:56:99:fb:af,
   my $cmd = "esxcli --formatter=csv --format-param=show-header=false " .
             "--format-param=fields=InnerMAC network vswitch dvs vmware " .
             "vxlan network mac list --vds-name $dvsname --vxlan-id $vxlanid";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},$cmd);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to run command: $cmd". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($result->{stdout} eq '') {
      $vdLogger->Error("No mac list on host $self->{hostIP}" .
                        Dumper($result->{stdout}));
      VDSetLastError(EFAIL());
      return FAILURE;
   }

   $result->{stdout} =~ s/\n//g;
   my @tempMacArray = split(/\,/, $result->{stdout});
   my $count = 0;
   foreach my $tmpline (@tempMacArray) {
      $count = 0;
      foreach my $tmplineB (@tempMacArray) {
         if ($tmplineB eq $tmpline) {
            $count++;
         }
      }

      if ($count > 1) {
         $vdLogger->Error("found more than one mac entry for mac:$tmpline");
         VDSetLastError(EFAIL());
         return FAILURE;
      }
   }

   $vdLogger->Info("mac entry is: " . Dumper(@tempMacArray));

   return \@tempMacArray;
}


###############################################################################
#
# GetAllVxlanVtepDetailOnHost --
#      Method to get all VTEP details from a host
#
# Input:
#      None.
#
# Results:
#      Returns FAILURE, if failed.
#      Returns vtep list in format below if succeeded.
#      IP              Segment         MAC
#      172.19.144.118  172.19.0.0     00:50:56:65:e1:81
#      172.19.144.115  172.19.0.0     00:50:56:6d:05:6e
#      ...
#
# Side effects:
#      None.
#
###############################################################################

sub GetAllVxlanVtepDetailOnHost
{
   my $self = shift;
   my $pyObj = $self->GetInlinePyObject();
   my $args->{'execution_type'} = 'cli';
   my $result = CallMethodWithKWArgs($pyObj, 'get_vtep_detail', $args);
   if ($result eq FAILURE) {
      $vdLogger->Error("Could not get vxlan vtep information on $self->{hostIP}");
      return FAILURE;
   }

   return $result->{'table'};
}

###############################################################################
#
# GetVxlanVtepEntryOnHost --
#      Method to get VTEP entry from a host
#
# Input:
#      vxlanid : the id of the vxlan to the VTEP entry from(required).
#
# Results:
#      Returns SUCCESS, if succeeded.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub GetVxlanVtepEntryOnHost
{
   my $self    = shift;
   my $vxlanid = shift;

   if (not defined $vxlanid) {
      $vdLogger->Error("vxlanid not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $dvsname = $self->GetVxlanVDSNameOnHost();
   if (FAILURE eq $dvsname) {
      $vdLogger->Error("Failed to get dvs name on: $self->{hostIP}");
      VDSetLastError(EFAIL());
      return FAILURE;
   }

   # localcli network vswitch dvs  vmware vxlan network vtep list --vds-name 1-vds-1541 --vxlan-id 10000
   # IP              Segment ID  Is MTEP
   # -----------------------------------
   # 172.19.128.254  172.19.0.0  false
   # 172.19.128.251  172.19.0.0  true
   # 172.18.128.2    172.18.0.0  true

   my $cmd = "localcli network vswitch dvs vmware vxlan network vtep list " .
             " --vds-name $dvsname --vxlan-id $vxlanid";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},$cmd);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to run command: $cmd". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($result->{stdout} eq '') {
      $vdLogger->Error("No vtep list on host $self->{hostIP}" .
                        Dumper($result->{stdout}));
      VDSetLastError(EFAIL());
      return FAILURE;
   }

   my @tempVtepArray = split(/\n/, $result->{stdout});
   shift(@tempVtepArray);
   shift(@tempVtepArray);
   foreach my $entry (@tempVtepArray) {
       my $vtepip = (split(/\s/, $entry))[0];
       $entry = $vtepip;
   }
   $vdLogger->Info("vtep entry is: " . Dumper(@tempVtepArray));
   return \@tempVtepArray;
}


###############################################################################
#
# GetVxlanArpEntryOnHost --
#      Method to get ARP entry from a host
#
# Input:
#      vxlanid : the id of the vxlan to the MAC entry from(required).
#
# Results:
#      Returns an array of ARP entry, if succeeded.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub GetVxlanArpEntryOnHost
{
   my $self    = shift;
   my $vxlanid = shift;

   if (not defined $vxlanid) {
      $vdLogger->Error("vxlanid not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $dvsname = $self->GetVxlanVDSNameOnHost();
   if (FAILURE eq $dvsname) {
      $vdLogger->Error("Failed to get dvs name on: $self->{hostIP}");
      VDSetLastError(EFAIL());
      return FAILURE;
   }

   #'esxcli --formatter=csv --format-param=show-header=false
   #  --format-param=fields=InnerMAC network vswitch dvs vmware vxlan network
   #  mac list --vds-name 1-vds-876 --vxlan-id 6847'
   #the output of the command above looks like below:
   #192.111.3.1,00:50:56:8e:c0:82,
   #192.111.3.1,00:50:56:8e:c0:82,
   my $cmd = "esxcli --formatter=csv --format-param=show-header=false " .
             "--format-param=fields=IP,MAC network vswitch dvs vmware " .
             "vxlan network arp list --vds-name $dvsname --vxlan-id $vxlanid";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},$cmd);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to run command: $cmd". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($result->{stdout} eq '') {
      $vdLogger->Error("No arp list on host $self->{hostIP}" .
                        Dumper($result->{stdout}));
      VDSetLastError(EFAIL());
      return FAILURE;
   }

   my @tempArpArray = split(/\n/, $result->{stdout});
   my $count = 0;
   foreach my $tmpline (@tempArpArray) {
      $count = 0;
      foreach my $tmplineB (@tempArpArray) {
         if ($tmplineB eq $tmpline) {
            $count++;
         }
      }

      if ($count > 1) {
         $vdLogger->Error("find more than one arp entry for:$tmpline");
         VDSetLastError(EFAIL());
         return FAILURE;
      }
   }

   $vdLogger->Info("arp entry is: " . Dumper(@tempArpArray));

   return \@tempArpArray;
}




###############################################################################
#
# CheckHostUsingPing
#      This method will check the health status of host
#
# Input:
#      None.
#
# Results:
#      TRUE: inventory status is good
#      FALSE: inventory status is bad
#
# Side effects:
#      None.
#
###############################################################################

sub CheckHostUsingPing
{
   my $self = shift;
   my $host = $self->{hostIP};

   if (VDNetLib::Common::Utilities::Ping($host)) {
      $vdLogger->Warn("Host $host not accessible");
      return FALSE;
   }
   return TRUE;
}


###############################################################################
#
# CheckHostUsingHostd
#      This method will check the health status of host
#      If an inline java host object is getting initialized, that means login
#      to host through sslport is successful
#
# Input:
#      None.
#
# Results:
#      TRUE: inventory status is good
#      FALSE: inventory status is bad
#
# Side effects:
#      None.
#
###############################################################################

sub CheckHostUsingHostd
{
   my $self = shift;
   my $host = $self->{hostIP};

   # If hostd stopped or crashed, connect anchor should return failure,
   # as a result, use it to check hostd health
   if (FAILURE eq VDNetLib::Common::Utilities::GetSTAFAnchor($self->{stafHelper},
       $host, "host", $self->{'userid'}, $self->{'password'})) {
      $vdLogger->Error("Hostd health check failed on host $host ");
      VDSetLastError("EHOSTUNREACH");
      return FALSE;
   }
   return TRUE;
}


###############################################################################
#
# RecoverHostFromPSOD
#      This method will wait for host pingable after PSOD, check if there is
#      core dump file. Copy dump files to MC and delete them from host. If no
#      dump file generated, will return SUCCESS. Else, return FAILURE.
#
# Input:
#      None.
#
# Results:
#      SUCCESS: Host recovery is successful
#      FAILURE: Host recovery is failed
#
# Side effects:
#      None.
#
###############################################################################

sub RecoverHostFromPSOD
{
   my $self = shift;
   my $timeout = WAIT_FOR_HOST_TO_BOOT;
   my $ret;
   my $files;
   my $host = $self->{hostIP};

   # Wait 15 minutes for system boot itself.
   while ($timeout > 0) {
      sleep 60;
      $timeout -= 60;
      $ret = VDNetLib::Common::Utilities::Ping($host);
      if ($ret == 0) {
         $vdLogger->Info("Host $host becomes accessible");
         last;
      }
   }

   # if ping failed, return failure
   if ($ret == 1) {
      $vdLogger->Info("Host $host not accessible with ping");
      return FAILURE;
   }

   if ($self->Reconnect(30) eq FAILURE) {
        $vdLogger->Error("The host recovery failed since".
			 " staf anchor can not create.");
        VDSetLastError(VDGetLastError());
        return FAILURE;
   }

   if (FAILURE eq $self->ConfigureHostForVDNet()) {
      $vdLogger->Error("Host configuration for vdnet failed on $host recovery");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   if (FAILURE eq $self->SetPSODTimeout(1)) {
     $vdLogger->Error("Set PSOD timeout failed on host $self->{hostIP}");
     VDSetLastError("EFAIL");
     return FAILURE;
   }


   # check if there is vmkernel dump, if yes then it is a PSOD!
   # need copy dump files back to MC
   $ret = $self->CopyCoreDumpFile([SCRATCH_CORE], $self->CORE_DUMP . "/" . $host);

   if ($ret eq FAILURE) {
      $vdLogger->Error("The host recovery from PSOD failed on host $host " .
                          "since copy core dump file failed.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Info("Host recovered successfully from PSOD");
   return SUCCESS;
}


###############################################################################
#
# HostdRestart
#      This method will restart hostd
#
# Input:
#      None.
#
# Results:
#      SUCCESS: Hostd restart is successful
#      FAILURE: Hostd restart is NOT successful
#
# Side effects:
#      None.
#
###############################################################################

sub HostdRestart
{
   my $self = shift;
   my $host = $self->{hostIP};
   my ($cmd, $ret);
   my $finalResult = FAILURE;

   $cmd = "/etc/init.d/hostd restart";
   $ret = $self->{stafHelper}->STAFSyncProcess($host, $cmd);
   # Process the result
   if (($ret->{rc} ne 0) || ($ret->{exitCode} ne 0)) {
      $vdLogger->Error("Command $cmd failed on host $host " . Dumper($ret));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Wait a few seconds for Hostd to restart");
   sleep WAIT_FOR_HOSTD_TO_READY;

   my $retries = 0;
   while ($retries < 5) {
      $ret = $self->CheckHostdStatus();
      if ($ret eq FAILURE) {
         $vdLogger->Error("Hostd status check failed");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      if ($ret == TRUE) {
         $finalResult = SUCCESS;
         last;
      }
      sleep (WAIT_FOR_HOSTD_TO_READY/5);
      $retries++;
   }
   if ($finalResult eq SUCCESS) {
      $vdLogger->Info("Hostd restart is successful on host $host");
      return SUCCESS;
   }
   $vdLogger->Error("Hostd restart failed on host $host:" .
                        Dumper($ret));
   VDSetLastError("EOPFAILED");
   return FAILURE;
}


###############################################################################
#
# RecoverFromHostdCrash
#      This method will recover hostd from crashes or stoppages
#
# Input:
#      None.
#
# Results:
#      SUCCESS: Host recovery is successful
#      FAILURE: Host recovery is failed
#
# Side effects:
#      None.
#
###############################################################################

sub RecoverFromHostdCrash
{
   my $self = shift;
   my $host = $self->{hostIP};
   my $result;
   my $resultCopy;

   $result = $self->CheckHostdStatus();
   if ($result eq FAILURE) {
      $vdLogger->Error("Hostd status check failed");
      return FAILURE;
   }

   # copy core dump files before host recovery
   $resultCopy = $self->CopyCoreDumpFile([SCRATCH_CORE], $self->CORE_DUMP . "/" . $host);
   if ($resultCopy eq FAILURE) {
      $vdLogger->Error("Copy core dump file failed on host $host");
   }

   if ($result == FALSE) {
      $result = $self->HostdRestart($host);
      if ($result eq FAILURE) {
         $vdLogger->Error("Hostd restart failed on host $host");
         return FAILURE;
      }
   }

   if ($self->Reconnect(5) eq FAILURE) {
      $vdLogger->Error("The hostd recovery failed on host $host " .
                          "since staf anchor can not create.");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $vdLogger->Info("Hostd recovery successfully on host $host");
   return SUCCESS;
}


###############################################################################
#
# SetPSODTimeout
#      This method will change PSODTimeout value
#
# Input:
#      timeout - timeout value used (mandatory)
#
# Results:
#      SUCCESS: change PSOD timeout successful
#      FAILURE: in case any error
#
# Side effects:
#      None.
#
###############################################################################

sub SetPSODTimeout
{
   my $self = shift;
   my $timeout = shift;
   if ((not defined $timeout) || ($timeout < 0) || ($timeout > 65535)) {
      my $errmsg = (not defined $timeout) ? "not defined" : $timeout;
      $vdLogger->Error("Timeout value invalid : $errmsg");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $commandBSODTimeout = "vsish -e set".
                              " /config/Misc/intOpts/BlueScreenTimeout $timeout";
   my $resultBsod = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                          $commandBSODTimeout);
   if ($resultBsod->{rc} != 0) {
      $vdLogger->Error("STAF command to set PSOD timeout failed" .
                        Dumper($resultBsod));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}


###############################################################################
#
# CheckHostdStatus
#      This method check hostd status
#
# Input:
#      None
#
# Results:
#      TRUE: hostd is running
#      FALSE: hostd not running
#      FAILURE: in case any error
#
# Side effects:
#      None.
#
###############################################################################

sub CheckHostdStatus
{
   my $self = shift;
   my $host = $self->{hostIP};
   my ($cmd, $ret);

   $cmd = "/etc/init.d/hostd status";
   $ret = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

   # only need check rc here,  as if hostd stopped, $ret->{exitcode} will be
   # non-zero value while rc is 0, should not return failure in this situation
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to get the hostd status:" .
                     Dumper($ret));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ((defined $ret->{stdout}) && ($ret->{stdout} =~ /hostd is running/i)) {
      return TRUE;
   }
   $vdLogger->Info("Hostd is not running on host $host as command \"$cmd\" " .
                   "returns " . Dumper($ret));
   return FALSE;
}




########################################################################
#
# RemoveControllerInfoFile--
#      Routine to remove a controller info file on the given host.
#
# Input:
#      fileName: Controller info file /etc/vmware/netcpa/config-by-vsm.xml
#
# Results:
#      "SUCCESS", if a controller info file is removed from the given host;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub RemoveControllerInfoFile
{
   my $self = shift;
   my $fileName = shift;
   my $host = $self->{hostIP};

   my $result = $self->{stafHelper}->STAFFSDeleteFileOrDir($host, $fileName);
   if (not defined $result) {
      $vdLogger->Error("Failed to delete $fileName on $host");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}


###############################################################################
#
# GetVTEPDefaultGateway --
#      Method to get VTEP default gateway
#
# Input:
#      None
#
# Results:
#      Returns VTEP default gateway, if succeeded.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub GetVTEPDefaultGateway
{
   my $self    = shift;

   my $result = $self->HostdRestart();
   if ($result eq FAILURE) {
      $vdLogger->Error("Hostd restart failed on host $self->{hostIP}");
      return FAILURE;
   }

   #'esxcli --formatter=csv --format-param=show-header=false
   #  --format-param=fields='Gateway IP' network vswitch dvs vmware vxlan list
   #the output of the command above looks like below:
   #172.26.0.1,

   my $cmd = "esxcli --formatter=csv --format-param=show-header=false " .
             "--format-param=fields='Gateway IP' network vswitch " .
             "dvs vmware vxlan list ";
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},$cmd);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to run command: $cmd". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($result->{stdout} eq '') {
      $vdLogger->Error("Didn't find VETP gateway on host $self->{hostIP}" .
                        Dumper($result->{stdout}));
      VDSetLastError(EFAIL());
      return FAILURE;
   }

   $result->{stdout} =~ s/\,//g;
   $result->{stdout} =~ s/\n//g;
   $vdLogger->Debug("The VTEP default gateway IP is $result->{stdout}");
   return $result->{stdout};
}


########################################################################
#
# GetVmknicByIPAddress --
#      Method to get the vmknic name by its ip address, for example vmknic1
#
# Input:
#      ip : vmknic ip address
#      internetProtocal : ipv4 or ipv6
#
# Results:
#      Return vmknic name if succesfully get the vmknic name;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub GetVmknicByIPAddress
{
   my $self   = shift;
   my $ip     = shift;
   my $internetProtocol = shift || 'ipv4';
   my $vmknic = undef;

   my $command = "esxcli network ip interface $internetProtocol get " .
                 "| grep $ip | awk '{print \$1}' ";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if ($result->{rc} != 0) {
      $vdLogger->Debug("STAF returned result is  " . Dumper($result));
      $vdLogger->Error("Failed to execute command $command on " .
                       $self->{hostIP});
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($result->{stdout} ne "") {
      $vmknic = $result->{stdout};
      chomp $vmknic;
   } else {
      $vdLogger->Error("Not find vmknic interface by ip address");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $vmknic;
}


########################################################################
#
# SetVmknicIpAddress --
#      Method to set the vmknic ip address, either static ip address or
#             dynamic dhcp mode
#
# Input:
#      vmknic      : vmknic name, like vmk1
#      mode        : static/dhcp
#      ipv4        : vmknic ip address which will to configure
#      netmask     : ip address netmask
#
# Results:
#      "SUCCESS", if succesfully set the vmknic ip address;
#      "FAILURE", in case of any error;
#
# Side effects:
#      None
#
########################################################################

sub SetVmknicIpAddress
{
   my $self       = shift;
   my %args       = @_;
   my $vmknic     = $args{'vmknic'};
   my $mode       = $args{'mode'};
   my $ipAddress  = $args{'ipv4'};
   my $netmask    = $args{'netmask'};
   my $command    = "esxcli network ip interface ipv4 set " .
                    "-i $vmknic -t $mode";

   if ($mode eq "static") {
      $command = "$command --ipv4 $ipAddress --netmask $netmask";
   }

   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);
   if ($result->{rc} != 0) {
      $vdLogger->Debug("STAF returned result is  " . Dumper($result));
      $vdLogger->Error("Failed to execute command $command on " .
                       $self->{hostIP});
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($result->{exitCode} != 0) {
      $vdLogger->Error("Failed to configure $vmknic ip address");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Info("Successfully configure $vmknic ip address");
   return SUCCESS;
}


######################################################################
#
# VerifyTSOCKOOnHost --
#     Method to check TSO(tcp segment offload) CKO(checksum offload)
#     status by pktcap-uw output
#
# Input:
#     serverForm : entry hash array generate from userData, like
#                  [
#                     { tso => undef }
#                  ],
#     vwireObj: reference to vwire object
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub VerifyTSOCKOOnHost
{
   my $self           = shift;
   my $emptyForm     = shift;
   my $vwireObj       = shift;
   my @serverData;

   my $resultHash = {
     'status'      => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };
   my $vxlanId;

   if ($vwireObj->{vxlanId}) {
      $vxlanId = $vwireObj->{vxlanId};
   } else {
      $vxlanId = VDNetLib::Workloads::Utilities::GetAttrFromPyObject(
                 '', [$vwireObj], "switch_vni");
   }
   $vdLogger->Debug("vxlanId is $vxlanId .");
   my $captureType = "Dynamic";
   my $function   = "UplinkDevTransmit";
   my $numOfPackets = "5";
   my $pattern = "TSO";
   my $hostObj = $self;
   my $result = VDNetLib::Common::PacketCapture::ESXUWPacketCapture(
                                                        $captureType,
                                                        $function,
                                                        $vxlanId,
                                                        $numOfPackets,
                                                        $pattern,
                                                        $hostObj);

   if ($result eq "FAILURE") {
      $vdLogger->Debug("Failed to get pktcap-uw output" .
                       " on host:$self->{hostIP}".
                         Dumper($result));
       VDSetLastError("ESTAF");
       $resultHash->{reason} = "Failed to get pktcap-uw output";
       return $resultHash;
   }
   my @tempArray = split(/\n/, $result);
   foreach my $line (@tempArray) {
      my @el = split(/\,/, $line);
      my $length;
      if ($line =~ /.*length\s(\d+)/) {
         $length = $1;
      }
      push @serverData, {'tso' => $el[1],'cko' => $el[2],'length' => $length};
   }
   $vdLogger->Debug("serverData got from the server: " . Dumper(@serverData));
   $resultHash->{status}   = "SUCCESS";
   $resultHash->{response} = \@serverData;
   return $resultHash;
}


#############################################################################
#
# UpdateComponent --
#     Method to update the advanced config options on a specified host, this
#     method may be used as a replacement for esxcfg-advcfg.
#
# Input:
#     reconfigure     : TRUE/FALSE
#     advancedoptions : hash may contain key/value pairs,
#                     : its format looks like below,
#                     : advancedoptions => {
#                     :   "Net.IGMPVersion" => 3,
#                     :   "Net.MLDVersion"  => 2,
#                     :   ...,
#                     : },
#
# Results:
#	SUCCESS, if succeeds to update the config option
#	FAILURE, if in case of any error
#
# Side effects:
#     None
#
########################################################################

sub UpdateComponent
{
   my $self            = shift;
   my %args            = @_;
   my $advancedoptions;

   if (exists $args{'advancedoptions'}) {
      $advancedoptions = $args{'advancedoptions'};
   } else {
      $vdLogger->Error("advancedoptions not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my %advoptsHash = %$advancedoptions;
   my $inlineHostSession = $self->GetInlineHostSession();
   my $anchor = $inlineHostSession->{'anchor'};
   my $inlineHostObject = $self->GetInlineHostObject($anchor);
   my $result = $inlineHostObject->UpdateConfigOption(\%advoptsHash);
   if ($result eq FALSE) {
      $vdLogger->Error("Failed to update VMkernel advanced config options");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return SUCCESS;
};


###############################################################################
#
# ClearVxlanEntryOnHost --
#      This method will clear the assigned entry for a vxlan on host.
#
# Input:
#     vxlanid : the id of the vxlan
#     entry   : which entry(arp or mac or vtep) to be clearn for the vxlan
#
# Results:
#      Returns SUCCESS, if clear the entry successfully.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub ClearVxlanEntryOnHost
{
   my $self    = shift;
   my $vxlanid = shift;
   my $entry   = shift;

   my $dvsname = $self->GetVxlanVDSNameOnHost();
   if (FAILURE eq $dvsname) {
      $vdLogger->Error("Failed to get dvs name on: $self->{hostIP}");
      VDSetLastError(EFAIL());
      return FAILURE;
   }

   my $cmd = "localcli network vswitch dvs vmware vxlan network $entry reset" .
             " --vds-name $dvsname --vxlan-id $vxlanid";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},$cmd);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to run command: $cmd". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $vdLogger->Info("Successfully cleaned the $entry entry for vxlan: $vxlanid" .
                    " on host: $self->{hostIP}");
   return SUCCESS;
}

########################################################################
#
# ConfigureLLDPIPv6Addr --
#     Method to configure IPv6 address advertised by LLDP.
#
# Input:
#     dvs - the dvs this host connected to(required)
#     lldpipv6addr - the IPv6 address advertised out(required)
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
   my $dvs          = shift;
   my $lldpipv6addr = shift;

   if ((not defined $dvs)||(not defined $lldpipv6addr)) {
      $vdLogger->Error("dvs or lldp ipv6 address not provided.");
      return FAILURE;
   }

   #On sourcehost configuring the following:
   #vsish -pe set /vmkModules/cdp/portsets/DvsPortset-0/mgmtIPv6Gaddr/
   #$lldpipv6addr
   my $portsetname = $self->GetPortSetNamefromDVS($dvs->{switch});
   if ($portsetname eq FAILURE) {
      $vdLogger->Error("Failed to get port set name for $dvs->{switch}");
      return FAILURE;
   }
   my $cmd = "vsish -pe set /vmkModules/cdp/portsets/$portsetname/mgmtIPv6Gaddr $lldpipv6addr";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},$cmd);
   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Unable to set lldp ipv6 address: " .
                        Dumper($result));
      return FAILURE;
   }
   return SUCCESS;
}

######################################################################
#
# GetLLDPIPv6Info --
#     Method to get LLDP IPv6 information
#
# Input:
#     serverForm : entry hash generate from userData, like
#                     [{ ipv6 => undef }]
#     dvsname: name of dvs this host connecting to
#
# Results:
#     Return a result hash which include the return status and server data
#
# Side effects:
#     None
#
########################################################################

sub GetLLDPIPv6Info
{
   my $self          = shift;
   my $emptyForm     = shift;
   my $dvsname       = shift;
   my @serverData;
   my $ipv6addr;

   my $resultHash = {
     'status'      => "FAILURE",
     'response'    => undef,
     'error'       => undef,
     'reason'      => undef,
   };

   my $vmnic = $self->GetActiveDVUplinkPort($dvsname,'uplink1');

   if ($vmnic eq FAILURE) {
      $vdLogger->Error("Unable to get uplink vmnic for $dvsname" );
      $resultHash->{reason} = "Failed to get uplink vmnic";
      return $resultHash;
   }
   $vdLogger->Debug("The uplink vmnic for $dvsname is $vmnic");

   my $cmd = "vim-cmd hostsvc/net/query_networkhint --pnic-names=$vmnic";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},$cmd);

   if (($result->{rc} != 0) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Unable to get lldp information: " .
                        Dumper($result));
      $resultHash->{reason} = "Failed to get lldp information";
      return $resultHash;
   }
   $vdLogger->Debug("The lldp information get from $dvsname is:
                     $result->{stdout}");

   my $regex = 'value = "(([0-9a-fA-F]{4}[:]){7}[0-9a-fA-F]{4})"';
   my @tempArray = split(/\n/, $result->{stdout});
   foreach my $line (@tempArray) {
     if ($line =~ /$regex/i) {
         $ipv6addr = $1;
         push @serverData, {'ipv6' => $ipv6addr};
      }
   }
   $vdLogger->Debug("serverData got from the server: " . Dumper(\@serverData));
   $resultHash->{status}   = "SUCCESS";
   $resultHash->{response} = \@serverData;
   return $resultHash;
}


###############################################################################
#
# CheckServiceStatus
#      This method check Service status
#
# Input:
#     params  : the hash table containing the service name and expected status
#
# Results:
#      SUCCESS: service is running
#      FAILURE: service not running
#
# Side effects:
#      None.
#
###############################################################################

sub CheckServiceStatus
{
   my $self          = shift;
   my $params        = shift;
   my $service       = $params->{'service'};
   my $expectestatus = $params->{'expectestatus'};
   my $host          = $self->{hostIP};
   my ($cmd, $ret);

   $cmd = "/etc/init.d/$service status";
   $ret = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

   # only need check rc here,  as if service stopped, $ret->{exitcode} will be
   # non-zero value while rc is 0, should not return failure in this situation
   if ($ret->{rc} != 0) {
      $vdLogger->Error("STAF command to get the $service status:" .
                     Dumper($ret));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ((defined $ret->{stdout}) && ($ret->{stdout} =~ /$expectestatus/i)) {
      return SUCCESS;
   }

   return FAILURE;
}


###############################################################################
#
# ConfigService
#      This method will configure a particular service on a host.
#
# Input:
#     operation: the operation(restart/stop/start) for the service.
#     service  : the service name to be configured
#
# Results:
#      SUCCESS: service configured is successful
#      FAILURE: service configured is NOT successful
#
# Side effects:
#      None.
#
###############################################################################

sub ConfigService
{
   my $self      = shift;
   my $operation = shift;
   my $service   = shift;
   if (($operation ne "restart") and ($operation ne "stop")
        and ($operation ne "start")) {
      $vdLogger->Error("Parameter operation name is wrong: $operation");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ((not defined $service)) {
      $vdLogger->Error("Parameter service name not passed: $service");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $host    = $self->{hostIP};
   my ($cmd, $ret);
   my $finalResult = FAILURE;

   $cmd = "/etc/init.d/$service $operation";
   $ret = $self->{stafHelper}->STAFSyncProcess($host, $cmd);
   # Process the result
   if (($ret->{rc} ne 0) || ($ret->{exitCode} ne 0)) {
      $vdLogger->Error("Command $cmd failed on host $host " . Dumper($ret));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Wait a few seconds for $service to $operation");

   my $expectestatus = "is running";
   if (($operation eq "start") or ($operation eq "restart")) {
      $expectestatus = "is running";
   } else {
      $expectestatus = "is not running";
   }

   my $params = {'service' => "$service",'expectestatus'=>"$expectestatus"};
   $finalResult = VDNetLib::Common::Utilities::RetryMethod({
                  'obj'    => $self,
                  'method' => 'CheckServiceStatus',
                  'param1' => $params,
                  'timeout' => 160,
                  'sleep' => 10,
                  });

   if ($finalResult eq SUCCESS) {
      $vdLogger->Info("$service $operation is successful on host $host");
      return SUCCESS;
   }
   $vdLogger->Error("$service $operation failed on host $host:" . Dumper($ret));
   VDSetLastError("EOPFAILED");
   return FAILURE;
}

###############################################################################
#
# ConfigureVSANDiskGroup--
#      This method makes all ssd and hdd join or leave the VSAN group.
#      Contributes disks to the disk group
#
# Input:
#      operation(required): join/leave
#
# Results:
#      Returns SUCCESS, if succeeded.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub ConfigureVSANDiskGroup
{
   my $self = shift;
   my $operation = shift;
   my $cmd;
   my $result;

   if ($operation =~ /join/i) {
      $operation = "add";
   } elsif ($operation =~ /leave/i) {
      $operation = "remove";
   } else {
      $vdLogger->Error("Unsupported operation:$operation passed");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   # Step 1) Query the disk states w.r.t VSAN
   $cmd = "vdq -q -H";
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $cmd);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to run command: $cmd ". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my @allDisks = split('\n\n', $result->{stdout});
   $vdLogger->Trace("List of hdds and ssd to $operation using $cmd on ".
                    "$self->{hostIP}\n" .  Dumper($result->{stdout}));

   my $hashOfVSANDisks;
   foreach my $disk (@allDisks) {
      my @lines = split('\n', $disk);
      my $diskNum = $lines[0];
      $hashOfVSANDisks->{$diskNum} =
         VDNetLib::Common::Utilities::ConvertRawDataToHash($disk);
      if ($operation =~ /add/i ) {
         # If the disk is not Eligible for VSAN to consume then move on to
         # next disk
         if ($hashOfVSANDisks->{$diskNum}->{'State'} !~ /Eligible for use by VSAN/i) {
            next;
         }
         if ($hashOfVSANDisks->{$diskNum}->{'IsSSD'} eq "1") {
            $hashOfVSANDisks->{$diskNum}->{stafcommand} =
               " -s $hashOfVSANDisks->{$diskNum}->{'Name'}";
         } else {
            $hashOfVSANDisks->{$diskNum}->{stafcommand} =
               " -d $hashOfVSANDisks->{$diskNum}->{'Name'}";
         }
      } else {
         # If the disk is not In-Use then move on to next disk as there is
         # nothing to remove
         if ($hashOfVSANDisks->{$diskNum}->{'State'} !~ /In-use for VSAN/i) {
            next;
         }
         if ($hashOfVSANDisks->{$diskNum}->{'IsSSD'} eq "1") {
            $hashOfVSANDisks->{$diskNum}->{stafcommand} =
               " -s $hashOfVSANDisks->{$diskNum}->{'Name'}";
         }
      }
   }

   # Step 4) Create the command by appending all HDD and SSD disks
   $cmd = "";
   foreach (values %$hashOfVSANDisks){
      $cmd = $cmd . $_->{stafcommand} if defined $_->{stafcommand};
   }
   $cmd = " esxcli vsan storage " . $operation . $cmd;
   if ($cmd !~ /-d|-s/) {
      $vdLogger->Info("Nothing to add/remove to the VSAN disk group on $self->{hostIP}");
      return SUCCESS;
   }
   $vdLogger->Trace("Disk Group command: $cmd");

   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $cmd);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to run command: $cmd on $self->{hostIP}". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}


###############################################################################
#
# GetVSANDiskGroupList
#      This method gets all disks in the vsan group
#
# Input:
#      None.
#
# Results:
#      Returns a hash of VSAN disks, if succeeded.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub GetVSANDiskGroupList
{
   my $self = shift;
   my $cmd;
   my $result;

   $cmd = "esxcli vsan storage list";
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $cmd);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to run command: $cmd ". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   my @allDisks = split('\n\n', $result->{stdout}) if $result->{stdout} =~ /\w+/;

   my $hashOfVSANDisks;
   foreach my $disk (@allDisks) {
      my @lines = split('\n', $disk);
      my $diskName = $lines[0];
      $hashOfVSANDisks->{$diskName} = VDNetLib::Common::Utilities::ConvertRawDataToHash($disk);
   }

   return $hashOfVSANDisks;
}



###############################################################################
#
# GetAllDisks
#      This method gets all disks on the host, used unused all.
#
# Input:
#      None.
#
# Results:
#      Returns array of all disks, if succeeded.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub GetAllDisks
{
   my $self = shift;
   my $cmd = "ls /vmfs/devices/disks/ ";
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $cmd);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to run command: $cmd ". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $vdLogger->Trace("ls /vmfs/devices/disks/ \n" . Dumper($result->{stdout}));
   return split('\n', $result->{stdout});
}


###############################################################################
#
# GetAllPartitionedDisks
#      This method gets all partitioned disks on the host
#
# Input:
#      None.
#
# Results:
#      Returns an array of all partitioned disks, if succeeded.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub GetAllPartitionedDisks
{
   my $self = shift;
   my @allDisks = $self->GetAllDisks();
   #
   # Example of output under ESXi/ESX 4.0 and later:
   #~  ls /vmfs/devices/disks/
   # mpx.vmhba0:C0:T0:L0 <-- disk device
   # mpx.vmhba0:C0:T0:L0:1 <-- partition 1
   # mpx.vmhba0:C0:T0:L0:2 <-- partition 2
   # mpx.vmhba0:C0:T0:L0:3 <-- partition 3
   # mpx.vmhba0:C0:T0:L0:5 <-- partition 5
   # naa.60060160205010004265efd36125df11 <-- disk device
   # naa.60060160205010004265efd36125df11:1 <-- partition 1
   # mpx.vmhba0:C0:T1:L0 <-- disk device
   #
   my $partitionedFlag;
   my @allPartitionedDisks;
   for (my $i = 0; $i < scalar(@allDisks); $i++) {
      $partitionedFlag = 0;
      for (my $j = $i+1; $j < scalar(@allDisks)-1; $j++) {
         if (($allDisks[$j] =~ $allDisks[$i]) ||
             ($allDisks[$i] =~ $allDisks[$j])) {
            $partitionedFlag = 1;
         }
      }
      if ($partitionedFlag == 1) {
         push(@allPartitionedDisks, $allDisks[$i]);
      }
   }
   $vdLogger->Trace("All Paritioned disks:" . Dumper(@allPartitionedDisks));
   return @allPartitionedDisks;
}



###############################################################################
#
# ConfigureVSANCluster
#      This method configures vsan cluster leading disks to join/leave/get the
#      cluster
#
# Input:
#      operation: join/leave/get
#
# Results:
#      Returns SUCCESS, if succeeded.
#      Returns stdout, if operation is get and operation succeeded.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub ConfigureVSANCluster
{
   my $self = shift;
   my $operation = shift;
   my $cmd;
   my $result;

   if ($operation !~ /(join|leave|get)/i) {
      $vdLogger->Error("Unsupported operation:$operation passed");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }
   $cmd = " esxcli vsan cluster " . $operation;
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP}, $cmd);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to run command: $cmd on $self->{hostIP}". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($operation =~ /get/i) {
      return $result->{stdout};
   }
   return SUCCESS;
}


###############################################################################
#
# GetVSANClusterInfo
#      This method gets vsan cluster information on this host
#
# Input:
#      None.
#
# Results:
#      Returns a hash of vsan cluster info if succeeded.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub GetVSANClusterInfo
{
   my $self = shift;
   return VDNetLib::Common::Utilities::ConvertRawDataToHash($self->ConfigureVSANCluster("get"));
}


#########################################################################
#
#  ConvertBDFtoPCIId --
#      Given the BDF ID
#      returns the PCI ID for configuring passthrough device
#
# Input:
#      BDF ID like 0000:44:1d.4
#
# Results:
#      Returns the PCI ID if there was no error executing the command
#      Returns undef, in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub ConvertBDFtoPCIId
{
   my $self =shift;
   my $bdfInHex  = shift;
   my $pciid = undef;

   if (not defined $bdfInHex) {
      $vdLogger->Error("BDF isn't provided");
      VDSetLastError("EINVALID");
      return undef;
   }
   if ($bdfInHex =~ /[0-9a-f]{4}:([0-9a-f]{2}:[0-9a-f]{2}.\d)$/) {
      $vdLogger->Debug("Set the PCI ID to $1");
      $pciid = $1;
   }
   return $pciid;
}


#########################################################################
#
#  ConvertPCIIdToDecimal --
#      Given the PCI ID in hex format
#      returns the PCI ID in decimal format
#
# Input:
#      PCI ID like 44:1d.4
#
# Results:
#      Returns the PCI ID in decimal
#      Returns undef, in case of any error.
#
# Side effects:
#      None.
#
#########################################################################

sub ConvertPCIIdToDecimal
{
   my $self =shift;
   my $pciIdInHex  = shift;
   my $pciIdInDecimal = undef;

   if (not defined $pciIdInHex) {
      $vdLogger->Error("PCI Id isn't provided");
      VDSetLastError("EINVALID");
      return undef;
   }
   $vdLogger->Debug("The PCI ID is $pciIdInHex");
   if ($pciIdInHex =~ /([0-9a-f]{2}):([0-9a-f]{2}).(\d)$/) {
      $pciIdInDecimal = sprintf("%02d:%02d.%d",hex($1),hex($2),hex($3));
      $vdLogger->Debug("Convert the PCI ID to $pciIdInDecimal");
   }
   return $pciIdInDecimal;
}


###############################################################################
#
# CreateLinkedClone -
#       This method configures the linked Clone for the given VM template.
#
# Input:
#       vmHash  - VM testbed spec hash
#       vmIndex - VM Index
#       lockFileName - local file name
#       uniqueID - unique id for vm name
#       displayName - display name of the vm
#
# Results:
#       vmObj of the VM, in case of SUCCESS.
#       FAILURE, Otherwise.
#
# Side effects:
#       None
#
###############################################################################

sub CreateLinkedClone
{
   my $self         = shift;
   my $vmHash       = shift;
   my $vmIndex	    = shift;
   my $displayName  = shift;
   my $vmType       = shift;
   my $command;
   my $result;
   my $ret;

   $vdLogger->Info("Creating linked clone for VM: $vmIndex,  " .
                   "will take few secs...");

   my $hostIP     = $self->{hostIP};
   my $vmTemplate = $vmHash->{template};


   # Find the VM location
   my $dsPath = VMFS_BASE_PATH . VDNET_LOCAL_MOUNTPOINT;

   #
   # $vdnetMountPoint might have spaces and ( ), so escaping them with \
   #
   $dsPath =~ s/ /\\ /;
   $dsPath =~ s/\(/\\(/;
   $dsPath =~ s/\)/\\)/;

   $command = "cd $dsPath; find . -name $vmTemplate";
   $result  = $self->{stafHelper}->STAFSyncProcess($hostIP,
                                                  $command);
   if ($result eq "FAILURE") {
      $vdLogger->Error("Failed to find the given VM: $vmTemplate in ".
                       "under  $dsPath on $hostIP.");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $path = $result->{stdout};
   $path =~ s/^\.//; # remove dot only in the beginning not everywhere
   $path =~ s/\n//g;
   if ($path eq "") {
      $vdLogger->Error("Failed to find the given VM: $vmTemplate in ".
                       "under  $dsPath on $hostIP.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $src = $dsPath . $path;

   # Check if the source VM directory exists on the host
   my $srcDir = $self->{stafHelper}->DirExists($hostIP, $src);
   if ((not defined  $srcDir) || ($srcDir eq FAILURE)) {
      $vdLogger->Error("Failed to get source VM path $src on $hostIP".
                       Dumper($result));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   $srcDir = VDNetLib::Common::Utilities::ReadLink($src, $hostIP,
                                                   $self->{stafHelper});

   if ($srcDir eq FAILURE) {
      $vdLogger->Info("Failed to find symlink of $srcDir on $hostIP");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Trace("Source VM directory is: $srcDir");

   my $runtimeDir = $self->GetVMRuntimeDir($vmHash->{datastoreType},
                                              $vmIndex,
                                              $vmHash->{prefixDir},
                                              $vmType);

   my $directory = substr($runtimeDir, 0, index($runtimeDir, 'vdtest'));
   my $vdtestDirectory = '"' . $directory . 'vdtest*"';
   $vdLogger->Info("Removing old files from runtime dir $vdtestDirectory" .
                   "on $self->{hostIP}");
   VDNetLib::Common::Utilities::CleanupOldFiles(path    => $vdtestDirectory,
                                             stafhelper => $self->{stafHelper},
                                             systemip   => $self->{hostIP});

   # Copy linked clone from vdNet VM Server to runtime directory
   # created
   #
   $ret = $self->CreateDupDirectory($srcDir,
                                    $runtimeDir,
                                    "True");
   if ($ret eq FAILURE) {
      $vdLogger->Error("Failed to copy $srcDir to $runtimeDir on $hostIP");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   #
   # Get the absolute path to the vmx which would finally be registered
   # and used for running the workloads
   #
   $command = "ls '$runtimeDir'/*.vmx";
   $command = "START SHELL COMMAND " .
              STAF::WrapData($command) .
              " WAIT RETURNSTDOUT STDERRTOSTDOUT";
   my $data;
   ($ret, $data) = $self->{stafHelper}->runStafCmd($hostIP,
                                                   'PROCESS',
                                                   $command);

   if (($ret eq FAILURE) || ($data eq "") || ($data =~ /No such/i)) {
      $vdLogger->Error("Staf error while retreiving vmx path on $hostIP, " .
                       "error:$data");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   chomp($data);
   my $testbedVMX = \$data;

   if ((not defined $$testbedVMX) || ($$testbedVMX eq "")) {
      $vdLogger->Error("$vmTemplate vmx path is invalid");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   #
   # escape spaces and () with \
   #
   if ($$testbedVMX !~ /\\/) { # if already escaped, ignore
      $$testbedVMX =~ s/ /\\ /;
      $$testbedVMX =~ s/\(/\\(/;
      $$testbedVMX  =~ s/\)/\\)/;
   }

   $vdLogger->Debug("Updated vmx path as $$testbedVMX for $vmTemplate");

   # Append UUID to display name
   LoadInlineJavaClass('java.util.UUID');
   my $uuid = VDNetLib::InlineJava::VDNetInterface::java::util::UUID->randomUUID();
   my $vcUUID = $uuid->toString();
   $displayName = $displayName . "-" . $vcUUID;

   # Add snapshot.redoNotWithParent = TRUE for linked clone to work
   my @list = ('snapshot.redoNotWithParent = "TRUE"');

   $vdLogger->Debug("Renaming display name of $$testbedVMX to $displayName");
   push(@list, "displayName = $displayName");

   $ret = VDNetLib::Common::Utilities::UpdateVMX($hostIP,
                                         \@list,
                                         $$testbedVMX);
   if ((not defined $ret) || ($ret eq FAILURE)) {
      $vdLogger->Info("VDNetLib::Common::Utilities::UpdateVMX() " .
                      "failed while update");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   # Create delta disks
   $vdLogger->Debug("Creating delta disks");
   my $vmObj = $self->CreateDeltaDisks($$testbedVMX, $vmIndex, $vmType, $displayName);
   if ($vmObj eq FAILURE) {
      $vdLogger->Error("Failed to create delta disks on $hostIP");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   #
   # NSX products make use of vcUUID of a VM extensively to identify
   # VM and vnic ports. The linked clone method used in vdnet
   # does not create unique UUID for 2 VMs from same template.
   # This conflict is resolved when host is connected to VC, but
   # for cases where no VC is involved this is still a problem.
   # UUID being a standard, it can be generated using open source
   # tools. The following block computes UUID using  Data::UUID
   # package. Use this until https://redmine.nicira.eng.vmware.com/issues/16012
   # is fixed
   #

   if ($vmObj->UpdateVCUUID($vcUUID) eq FAILURE) {
      $vdLogger->Error("Failed to update UUID for VM $vmIndex");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   #
   # Upgrade VM to latest:
   # Since if the given VM is already configured with the latest HW version,
   # the operation will definitelly fail, so we won't check if the upgrade
   # is successful but just print a warning info.
   #
   my $vmVersion = (defined $vmHash->{version}) ? $vmHash->{version} :
                     VDNetLib::TestData::TestConstants::DEFAULT_VM_VERSION;
   $vdLogger->Info("Setting VM hardware version $vmVersion");
   if ($vmObj->UpgradeVM($vmVersion) eq FAILURE) {
      $vdLogger->Warn("Failed to upgrade VM $vmIndex to version $vmVersion");
   }
   delete $vmHash->{version};
   # update VM extra configuration
   my $vncPort = 5909 + int($vmIndex);
   my $temp = int($vmIndex) + 16;
   my $extraConfig = {
      'msg.autoAnswer'              => "TRUE",
      'chipset.onlineStandby'       => "TRUE",
      'log.throttleBytesPerSec'     => "0",
      'log.guestNoLogAfterThreshold'=> "FALSE",
      'log.noLogAfterThreshold'     => "FALSE",
      'RemoteDisplay.vnc.enabled'   => "TRUE",
      'RemoteDisplay.vnc.port'      => $vncPort,
      'tools.skipSigCheck'          => "TRUE",
      # KB2048572: The guest operating system's clock is ahead of the host on
      # which it is running, causing the arping process to become unresponsive
      # during boot. This results in the delayed boot time
      'rtc.diffFromUTC'             => "0",
   };
   if ($vmObj->UpdateVMExtraConfig($extraConfig) eq FAILURE) {
      $vdLogger->Error("Failed to update extra config for VM $vmIndex");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $vmObj;
}


########################################################################
#
# CreateDupDirectory --
#       Method to create a duplicate VM directory.
#
# Input:
#       <sourceDir> - source direcory which needs to be duplicated
#                     (required)
#       <destDir>   - name of the duplicate directory (required)
#       <symlink>   - "True" or "False" (required)
#
# Results:
#       "SUCCESS", if duplicate directory is created;
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub CreateDupDirectory
{
   my $self	 = shift;
   my $sourceDir = shift;
   my $destDir	 = shift;
   my $symlink	 = shift;

   my $hostIP     = $self->{hostIP};
   if ((not defined $hostIP) ||
      (not defined $sourceDir) ||
      (not defined $destDir) ||
      (not defined $symlink)) {
      $vdLogger->Error("Insufficient parameters passed");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my ($command, $ret, $data);
   my @sourceFile = ("*.vmx", "*.vmsn", "*.vmsd");

   if ($symlink =~ /True/i) {
      #
      # If symlink option is given, then copy .vmx files and symlink the vmdk
      # files
      #
      $ret = $self->{stafHelper}->CreateSymlinks($hostIP,
                                                 "$sourceDir/*.vmdk",
                                                 $destDir);
      if ($ret eq FAILURE) {
         $vdLogger->Error("Failed to create vmdk symlinks on $hostIP");
         VDSetLastError("ESTAF");
         return FAILURE;
      }

   } else {
      push(@sourceFile,"*.vmdk");
   }
   #
   # If symlink option is given, $sourceFile would be .vmx and that alone will
   # be copied since .vmdk files are already symlinked in the previous block.
   # If symlink is false, then the entire directory is copied
   #
   foreach my $file (@sourceFile) {
      my $extension = $file;
      $extension    =~ s/\*\.//;
      $command      = "START SHELL COMMAND \"ls $sourceDir/$file\" " .
                 "WAIT RETURNSTDOUT STDERRTOSTDOUT";

      my ($result, $dir) = $self->{stafHelper}->runStafCmd($hostIP,
                                                           'PROCESS',
                                                           $command);
      #
      # The command above returns an array which has list of specified
      # file formats, if successful. Verify that the given format matches
      # with the result. If the given file format does not exist, then skip
      # to the next file format.
      #
      if ($result eq SUCCESS) {
         if ($dir eq "" || $dir =~ /No such/i) {
            # The given file does not exist, so skip copying
            next;
         }
      } else {
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      ($ret, $data) = $self->{stafHelper}->CopyDirectory($hostIP,
                                                         $sourceDir,
                                                         $destDir,
                                                         $file);
      if ($ret eq FAILURE) {
         $vdLogger->Error("Staf error while copying directory $sourceDir" .
                          "on $hostIP, error:$data");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   return SUCCESS;
}

########################################################################
#
# CreateDeltaDisks --
#       Method to create delta disks (to allow writing to vmdk locally)
#
# Input:
#       <vmx>     - VMX File absolute path
#       <vmIndex> - Inventory index of the vm
#       <vmType> - type of the vm  ( possible values: vm/dhcpserver/powerclivm)
#       <displayName> - display name of the vm
# Results:
#       reference to VDNetLib::VM::VMOperations object,
#       if delta disks are created for the VM sepcified at the input;
#       "FAILURE", in case of any error
#
# Side effects:
#       None
#
########################################################################

sub CreateDeltaDisks
{
   my $self    = shift;
   my $vmx     = shift;
   my $vmIndex = shift;
   my $vmType  = shift;
   my $displayName  = shift;
   my $vmOpsObj;

   $vmOpsObj = VDNetLib::VM::VMOperations->new($self, $vmx, $displayName, $vmType);
   if ($vmOpsObj eq FAILURE) {
      $vdLogger->Error("Failed to create $vmType Operations object");
      return FAILURE;
   }
   # One way to create delta disk is to take snapshot of the VM
   if ( $vmOpsObj->VMOpsTakeSnapshot("delta") eq FAILURE ) {
      $vdLogger->Error(" VMOpsTakeSnapshot failed");
      #Unregister VM in case of error.
      $vmOpsObj->VMOpsUnRegisterVM();
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $vmOpsObj;
}

########################################################################
#
# GetVMX --
#      Returns VMX file as, [Storage] WinXP/WinXP.vmx, given the VM IP
#      and the corresponding hostObj in the testbed.
#           1. Get the MAC address corresponding to the IP address of the
#              machine.
#           2. Get VMX files of all the VMs using vim-cmd.
#           3. Grep the MAC found in step1 in each of the vmxFile
#           4. If the MAC is found return the VMX
#           5. If it is not found in any of the VMX files, return
#              undef
#
# Input:
#      ip      : IP address of VM
#      hostObj : Host Object
#
# Results:
#      VMX file name relative to its DataStore and vm IP as mentioned above
#
# Side effects:
#      None
#
########################################################################

sub GetVMX
{
   my $self    = shift;
   my $ip      = shift;

   my $hostIP  = $self->{hostIP};
   my $storage;
   my $vmxFile;
   my $vmx;
   my $mac;
   my $command;

   if ((not defined $ip) ||
	(not defined  $self->{hostType}) ||
	$self->{hostType} !~ /esx|vmkernel/i ) {
      $vdLogger->Error("invalid  VM details: ip, hosttype -" .
            " $ip $self>{hostType}");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   #
   # Get MAC address corresponding to the VM IP address
   # The below mechanism to get IP assume STAF working on the VM
   #
   $mac = VDNetLib::Common::Utilities::GetMACFromIP(
                                            $ip,
                                            $self->{stafHelper});
   if ((not defined $mac) || ($mac eq FAILURE)) {
      $vdLogger->Error("Failed to get the Mac address from IP.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $vdLogger->Debug("MAC address returned by GetMACFromIP is: $mac");

   # replace '-' with ':' as it appears in the vmx file
   $mac =~ s/-/:/g;

   $command = "start shell command vim-cmd vmsvc/getallvms " .
                       "wait returnstdout";
   my ($result, $data) = $self->{stafHelper}->runStafCmd(
                                $hostIP,
                                "process", $command);

   if (($result ne SUCCESS) || (not defined $data)) {
      $vdLogger->Error("Failed to execute: $command on host: $hostIP");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   #
   # sample output of vim-cmd vmsvc/getallvms
   # Vmid Name      File               Guest OS Version   Annotation
   # 112 sles11-64 [Storage1] sles11-32/sles11-32.vmx sles10Guest vmx-07
   #
   my @vimcmd = split(/\n/,$data);
   if ( scalar(@vimcmd) > 1 ) {
      foreach my $vmline (@vimcmd) {
         $vmline =~ s/\s+/ /g;
         $vmline =~ s/\t|\n|\r//g;

         if ( $vmline =~ /.* (\[.*\]) (.*\.vmx) .*/ )  {
            $storage = $1;
            $vmx     = $2;
            $vmxFile = "$storage "."$vmx";
            $vdLogger->Debug("vmxFile: $vmxFile");
            if ((defined $storage) && (defined $vmx)) {
               # if MAC address is found then we found vmx
               my $eth = VDNetLib::Common::Utilities::GetEthUnitNum(
                         $hostIP,
                         VDNetLib::Common::Utilities::GetAbsFileofVMX($vmxFile),
			 $mac);
               if ( $eth eq FAILURE ) {
		  #
                  # ignore the error as it is possible not to find the mac
                  # address in this vmxFile
		  #
                  VDCleanErrorStack();
                  next;
               } elsif ($eth =~ /^ethernet/i) {
                  # storing the vmx path in absolute file format
                  $vmxFile = VDNetLib::Common::Utilities::GetAbsFileofVMX($vmxFile);
                  return $vmxFile;
               }
            }
         }
      }
   }

   #
   # in case of the vms are powered on using /bin/vmx command then
   # vim-cmd will not list un-registered VMs hence use vsish to get it.
   #
   $command = "start shell command vsish -e ls /vm wait returnstdout";

   ($result, $data) = $self->{stafHelper}->runStafCmd($hostIP,
						      "process", $command);
   if (($result ne SUCCESS) || (not defined $data)) {
      $vdLogger->Error("Failed to execute: $command on host: $hostIP");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   @vimcmd = split(/\n/,$data);
   foreach my $vmline (@vimcmd) {
      $command = "start shell command vsish -e get /vm/$vmline" .
                             "vmmGroupInfo | grep \"vmx\" wait returnstdout";
      my ($result, $data) =
            $self->{stafHelper}->runStafCmd($hostIP, "process", $command);
      if (($result ne SUCCESS) || (not defined $data)) {
	 $vdLogger->Error("Failed to execute: $command on host: $hostIP");
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ( $data =~ /\s*config file path:(.*)/ ) {
         $vmxFile = $1;
         chomp($vmxFile);
      } else {
         next;
      }

      if ( (defined $vmxFile) && ($vmxFile =~ /\.vmx/) ) {
         # if MAC address is found then we found vmx
         my $eth = VDNetLib::Common::Utilities::GetEthUnitNum($hostIP,
							      $vmxFile, $mac);
         if ($eth eq FAILURE) {
            # ignore the error as it is possible not to find the mac
            # address in this vmxFile
            VDCleanErrorStack();
            next;
         } elsif  ($eth =~ /^ethernet/i) {
            #
            # vsish reports the vmx file in canonical format, change
            # it to storage format as required by VMOperations module
            # The way it is done, is get the ls -l /vmfs/volumes output
            # match the symlink pointer of the storage with the canonical
            # directory in the path reported by vsish.
            #
            $command = "START SHELL COMMAND ls parms -l " . VMFS_BASE_PATH .
                       " WAIT RETURNSTDOUT STDERRTOSTDOUT";
            my ($result, $data) = $self->{stafHelper}->runStafCmd($hostIP,
							"PROCESS", $command);
            if (($result ne SUCCESS) || (not defined $data)) {
	       $vdLogger->Error("Failed to execute: $command on host: $hostIP");
               VDSetLastError("ESTAF");
               return FAILURE;
            }

            my @listOfFiles = split(/\n/,$data);
            foreach my $line (@listOfFiles) {
               # lrwxr-xr-x    1 root     root         35 Aug  6 18:21
               # Storage-1 -> 495028af-13fdc8af-c0e7-00215a47b2ce
               if ( $line =~ /.*\d+\:\d+ (.*?) -> (.*)/ ) {
                  my $storage = $1;
                  my $datastore = $2;
                  if ( $vmxFile =~ /$datastore/ ) {
                     $vmxFile =~ s/\/vmfs\/volumes\/$datastore\//\[$storage\] /;
                  }
               }
            }
            # storing the vmx path in absolute file format
            $vmxFile = VDNetLib::Common::Utilities::GetAbsFileofVMX($vmxFile);
            return $vmxFile;
         }
      }
   }

   $vdLogger->Error("Failed to find VMX file for the VM IP: $ip");
   VDCleanErrorStack();
   VDSetLastError("ENOTDEF");
   return FAILURE;
}


########################################################################
#
# CheckForPatternInVMX --
#       Looks for the given pattern in the VMX file of the given MACHINE
#	in the testbed
#
# Input:
#       vmxfile - path to vmx file
#	pattern - the pattern to grep in the vmx file
#       ESX host ip, absolute path name of the esx file on the host, and
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
   my $self = shift;
   my $vmxFile = shift;
   my $pattern = shift;
   my $stafHelper = shift;
   my $hostOS = shift || undef;
   my $host = $self->{hostIP};
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


#########################################################################
#
# GetHostSetupScript
#      Path to the host setup script
#
# Input:
#      None
#
# Results:
#      Returns path
#
# Side effects:
#      None.
#
#########################################################################

sub GetHostSetupScript
{
   return HOST_SETUP_SCRIPT;
}


#########################################################################
#
# SSHPreProcess
#      Stuff to do as a pre-req to start ssh on the host
#
# Input:
#      None
#
# Results:
#      Returns SUCCESS
#      Returns FAILURE
#
# Side effects:
#      None.
#
#########################################################################

sub SSHPreProcess
{
   my $self = shift;
   $vdLogger->Info("Starting " . SSHSERVICENAME  . " service on " .
                   $self->{hostIP});
   my $result = $self->ConfigureServiceSystemAnchor(SSHSERVICENAME, SSH_START);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to start SSH service on $self->{hostIP}");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   return SUCCESS;
}



########################################################################
#
# DeployOVF --
#     Method to create a VM using ovf deployment
#
# Input:
#     vmHash: config spec for the vm
#     vmIndex: vm index
#     displayName: display name for the vm
#
#
# Results:
#     returns vm object for the vm created
#
# Side effects:
#     None
#
########################################################################

sub DeployOVF
{
   my $self          = shift;
   my $vmHash        = shift;
   my $vmIndex	      = shift;
   my $displayName   = shift;
   my $vmOpsObj     = shift;
   my $runtimeDir = $self->GetVMRuntimeDir($vmHash->{datastoreType},
                                           $vmIndex,
                                           $vmHash->{prefixDir});

   if ($runtimeDir eq FAILURE) {
      $vdLogger->Error("Failed to get runtime directory for vm $vmIndex deployment");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my @datastore = split("\/", $runtimeDir);
   #
   # use $datastore[3] not $datastore[2] because split would give
   # "", "vmfs", "volumes" since there is preceeding / in
   # /vmfs/volumes
   #
   my $ovfparms = ' ';
   if (defined $vmHash->{ovftool_params}) {
       $ovfparms = ' ' . $vmHash->{ovftool_params};
   }
   my $diskMode = ' --diskMode=';
   if (defined $vmHash->{ovfdiskmode}) {
       $diskMode = $diskMode . $vmHash->{ovfdiskmode};
   } else {
       $diskMode = $diskMode . $self->{ovfDiskMode};
   }
   my $command = 'ovftool --noSSLVerify --name=' . $displayName .
                 $diskMode . $ovfparms .
                 ' --datastore=' . quotemeta($datastore[3]) .
                 ' "' . $vmHash->{ovfurl} . '" "vi://' . $self->{userid} . ':' .
                 quotemeta($self->{sshPassword}) . '@' .
                 $self->{hostIP} . '"';

   $vdLogger->Info("Deploying ovf: $command");
   my $result = `$command`;
   my $vmx = '/vmfs/volumes/' . $datastore[3] . '/' .
            $displayName . '/' . $displayName . '.vmx';

   $vmOpsObj = VDNetLib::VM::VMOperations->new($self, $vmx);
   if ($vmOpsObj eq FAILURE) {
      $vdLogger->Error("Failed to create VMOperations object: $result");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $vmOpsObj;
}


###############################################################################
#
# GetVxlanMacCountOnHost --
#      Method to get MAC count from a host
#
# Input:
#      vxlanid : the id of the vxlan to the MAC count from(required).
#
# Results:
#      Returns the count of mac entry, if succeeded.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub GetVxlanMacCountOnHost
{
   my $self    = shift;
   my $vxlanid = shift;

   if (not defined $vxlanid) {
      $vdLogger->Error("vxlanid not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $dvsname = $self->GetVxlanVDSNameOnHost();
   if (FAILURE eq $dvsname) {
      $vdLogger->Error("Failed to get dvs name on: $self->{hostIP}");
      VDSetLastError(EFAIL());
      return FAILURE;
   }

   #'esxcli --formatter=csv --format-param=show-header=false
   #  --format-param=fields="MAC Entry Count" network vswitch dvs vmware vxlan network
   #  list --vds-name 1-vds-876 --vxlan-id 6847'
   #the output of the command above looks like below:
   #1024,
   my $cmd = "esxcli --formatter=csv --format-param=show-header=false " .
             "--format-param=fields=\"MAC Entry Count\" network vswitch dvs vmware " .
             "vxlan network list --vds-name $dvsname --vxlan-id $vxlanid";
   $vdLogger->Debug("cmd: " . Dumper($cmd));
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},$cmd);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to run command: $cmd". Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($result->{stdout} eq '') {
      $vdLogger->Error("No mac count on host $self->{hostIP}" .
                        Dumper($result->{stdout}));
      VDSetLastError(EFAIL());
      return FAILURE;
   }

   $result->{stdout} =~ s/\n//g;
   $result->{stdout} =~ /(\d+)/;
   my $maccount = $1;
   $vdLogger->Debug("mac count is: " . Dumper($maccount));

   return $maccount;
}


########################################################################
#
# GetVMProcessInfo --
#     Method to get information about the VM Process in the Esx
#
# Input:
#     None
#
# Results:
#     Reference to a hash of hash with following keys:
#     {
#        <vmX> => {
#           'World ID'        => <>,
#           'Process ID'      => <>,
#           'VMX Cartel ID'   => <>,
#           'UUID'            => <>,
#           'Display Name'    => <>,
#           'Config File'     => <>,
#        },
#        <vmY> => {
#        },
#     }   ;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetVMProcessInfo
{
   my $self = shift;
   my $command = 'esxcli vm process list';
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{'hostIP'},
                                                     $command);
   if ($result->{rc} != 0 || $result->{exitCode} != 0) {
      $vdLogger->Error("Failed to execute command $command");
      $vdLogger->Debug("Error:" . Dumper($result));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $data = $result->{stdout};
   my @temp = split(/\n\n/, $data);

   my $vmProcessHash = {};
   foreach my $vmInfo (@temp) {
      my @vmDetails = split(/\n/, $vmInfo);
      my $vm = shift(@vmDetails);
      foreach my $item (@vmDetails) {
         $item =~ s/^\s+//;
         my ($key, $value) = split(/:\s/, $item);
         $key =~ s/^\s+//;
         $vmProcessHash->{$vm}{$key} = $value;
      }
   }
   return $vmProcessHash;
}


###############################################################################
#
# QueryVMs --
#      This method will return a complex data structures about all the
#      VMs in a host with all the attributes
#
# Input:
#      None
#
# Results:
#      Returns array of vms in the host, if operation success
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#      None
#
###############################################################################

sub QueryVMs
{
   my $self         = shift;
   my $payload = $self->GetVMProcessInfo();
   $vdLogger->Debug("VM Process Info" . Dumper($payload));
   my @arrayofVMInformation;
   my $mapperHash = {
      'World ID'        => 'worldid',
      'Process ID'      => 'processid',
      'VMX Cartel ID'   => 'vmxcartelid',
      'UUID'            => 'uuid',
      'Display Name'    => 'displayname',
      'Config File'     => 'configfile',
   };
   foreach my $vm (keys %$payload) {
      my $serverData;
      foreach my $key (keys %{$payload->{$vm}}) {
         if (exists $mapperHash->{$key}) {
            $serverData->{$mapperHash->{$key}} = $payload->{$vm}{$key};
         }
      }
      push @arrayofVMInformation, $serverData;
   }
   print "Dumper" . Dumper(@arrayofVMInformation);
   $vdLogger->Debug("Server form with complete values" . Dumper(\@arrayofVMInformation));
   my $resultHash = {
      'status'      => "SUCCESS",
      'response'    => \@arrayofVMInformation,
      'error'       => undef,
      'reason'      => undef,
   };
   return $resultHash;
}


###############################################################################
#
# FaultToleranceOperation --
#      This method will work on the fault tolerance option for the give VM.
#
# Input: Takes Faulttoleranceopetion hash with
#              faulttoleranceoption - specifying either "CheckFT" or "InjectFT"
#              faulttolerancevm  - specifying the VM on which
#                                  the operation has to be done
#
# Results:
#      Returns "SUCCESS", if operation success
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#      None
#
###############################################################################

sub FaultToleranceOperation
{
  my $self = shift;
  my $ftoperation = shift;
  my $result;
  my $ftoption = $ftoperation->{"faulttoleranceoption"};
  if ($ftoption eq VDNetLib::TestData::TestConstants::CHECK_FAULT_TOLERANCE){
      if ($self->CheckFaultToleranceState($ftoperation)){
         return SUCCESS;
      }
  }elsif ($ftoption eq VDNetLib::TestData::TestConstants::INJECT_FAULT_TOLERANCE){
      if ($result = $self->InjectFaultTolerance($ftoperation)){
         return SUCCESS;
      }
  }
  return FAILURE
}


###############################################################################
#
# CheckFaultTolerancestate --
#      This method will enable/disable fault tolerance for the given VM.
#
# Input:
#      ftvm                 -  Fault Tolerance for the given VM.
#
# Results:
#      Returns "SUCCESS", if operation success
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#      None
#
###############################################################################

sub CheckFaultToleranceState
{
   my $self = shift;
   my $ft = shift;
   my $ftvm = $ft->{"faulttolerancevm"}[0];
   my $vmname = $ftvm->{'displayName'};
   my $ftstate = "notprotected";
   my $ftcounter = 50;
   my $vmx_pid;
   # Creating command to retrieve VLAN check result info
   my $command = "esxcli system process list | grep ". $vmname;
   my $match1 = "vmx-mks:"."$vmname";
   my $match2 = "vmx-svga:"."$vmname";

   while($ftstate eq "notprotected" && $ftcounter != 0){
     $vdLogger->Info("$ftcounter: Checking if secondary VM is created");
     # Submit STAF command
     $vdLogger->Debug("Excuting Command $command");
     my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                       $command);
     my $str = $result->{"stdout"};
     $vdLogger->Debug("data $str");

     if (($str =~ /$match1/) && ($str =~ /$match2/)) {
         $vdLogger->Info("Secondary is created");
         $ftstate = "protected";
     }
     sleep(6);
     $ftcounter = $ftcounter - 1;
   }

   return SUCCESS;
}


#########################################################################
#  InjectFaultTolerance --
#      This method will inject fault tolerance for the given VM.
#
# Input:
#      ftvm                 -  Fault Tolerance for the given VM.
#
# Results:
#      Returns "SUCCESS", if operation success
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#      None
#
#########################################################################

sub InjectFaultTolerance
{
   my $self = shift;
   my $injectft = shift;
   my $ftvm = $injectft->{"faulttolerancevm"}[0];
   my $vmname = $ftvm->{'displayName'};
   my $vmx_pid;
   # Creating command to retrieve VLAN check result info
   my $command = "esxcli vm process list";
   my $match = "VMX Cartel ID:";

   # Submit STAF command
   my $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                     $command);

   my $str = $result->{"stdout"};

   if ($str =~ /\s+$match\s(\d+)\n/) {
       $vmx_pid = $1;
       print "$vmx_pid";
   }

   $vdLogger->Debug("Command $command\ndata $str");
   # Creating command to retrieve VLAN check result info
   $command = "kill -9 ". "$vmx_pid";

   # Submit STAF command
   $result = $self->{stafHelper}->STAFSyncProcess($self->{hostIP},
                                                      $command);

   $vdLogger->Debug("Command $command");

   return SUCCESS;
}


#########################################################################
#  GetAttributeMapping --
#      This method returns the attribute mapping of this method.
#
# Input:
#
# Results:
#      Returns attribute mapping of this object
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#      None
#
#########################################################################

sub GetAttributeMapping
{
   my $self = shift;
   my $currentPackage;
   if (ref($self)) {
      $self =~ /(.*)\=.*/;
      $currentPackage = $1;
   }
   my $package = eval "$currentPackage" . "::" . 'attributemapping';
   if ($@) {
      $vdLogger->Error("Exception thrown getting attribute mapping " .
                       "for class $currentPackage\n". $@);
      return FAILURE;
   }
   return $package
}


#########################################################################
#  ReadPids ---
#      This method returns the process name to pid map for all the
#      processes running on the host.
#
# Input:
#      None
#
# Results:
#      Returns hash of process name to pid of all process on success.
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#      None
#
#########################################################################

sub ReadPids
{
    my $self = shift;
    my $procHash = {};
    my $resultHash = {
       'status' => undef,
       'response' => undef,
       'error' => undef,
       'reason' => undef,
    };
    my $cmd = $self->GetPidCmd();
    my $result = $self->{stafHelper}->STAFSyncProcess(
        $self->{hostIP}, $cmd, undef, undef, 1);
    if (FAILURE eq $result) {
        $vdLogger->Error("Failed to read the PIDs from host: $self->{hostIP}");
        $resultHash->{'status'} = "FAILURE";
        $resultHash->{'error'} = "ps command returned with an error";
        $resultHash->{'reason'} = "UNKNOWN";
        return $resultHash;
    }
    my @lines = split('\n', $result->{stdout});
    foreach my $line (@lines) {
       my @procInfo  = split(' ', $line);
       $procHash->{$procInfo[1]} = $procInfo[0];
    }
    $resultHash->{'status'} = 'SUCCESS';
    $resultHash->{'response'} = $procHash;
    return $resultHash;
}


#########################################################################
#  GetPidCmd ---
#      This method returns the command that can be used to get the PIDs
#      and process names from the host.
#
# Input:
#      None
#
# Results:
#      Returns the command that can be used to get the PIDs and process
#      names  from the host.
#
# Side effects:
#      None

#########################################################################

sub GetPidCmd
{
    return "ps -C | awk \'{print \$1, \$3}\'";
}

1;
