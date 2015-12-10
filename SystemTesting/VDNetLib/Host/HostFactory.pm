
package VDNetLib::Host::HostFactory;
#
# This package is only concerned with creation host Objects based on
# user input. No host initialization should be in this package, only
# createion related APIs.
#

use strict;
use warnings;
use FindBin;
use Data::Dumper;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/";

use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger $sshSession);


########################################################################
#
# CreateHostObject--
#      Factory to create an object of Host/KVM Operations
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
#      hosttype: esx or kvm or zen etc
#      password: password for host OS
#
# Results:
#      An object of VDNetLib::Host::*Operations package.
#
# Side effects:
#      None
#
########################################################################

sub CreateHostObject
{
   my %args          = @_;
   my $hostIP        = $args{hostip};
   my $stafObj       = $args{stafhelper};
   my $vdnetSource   = $args{vdnetsrc} . ':' . $args{vdnetshare};
   my $vmRepository  = $args{vmserver} . ':' . $args{vmshare};
   my $sharedStorage = $args{sharedstorage};
   my $hostType      = $args{hosttype};
   my $password      = $args{password};

   if (not defined $hostIP) {
      $vdLogger->Error("Need Host IP/name to create host Object in Factory");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   #
   # Create a VDNetLib::Common::STAFHelper object with default if it not
   # provided in the input parameters.
   #
   if (not defined $stafObj) {
      my $options;
      $options->{logObj} = $vdLogger;
      my $temp = VDNetLib::Common::STAFHelper->new($options);
      if (not defined $temp) {
         $vdLogger->Error("Failed to create VDNetLib::Common::STAFHelper object");
         VDSetLastError("ETAF");
         return FAILURE;
      }
      $stafObj = $temp;
   }

   #
   #Creating child object for hosted if host is not esx/vmkernel.
   #
   my $createObjectOf = undef;
   # my $hostType = $stafObj->GetOS($hostIP) || $;
   if (not defined $hostType) {
      # For backward compatabilty
      $createObjectOf = "VDNetLib::Host::HostOperations";
   } elsif ($hostType !~ /vmkernel|esx/i) {
      $createObjectOf = "VDNetLib::Host::KVMOperations";
   } else {
      $createObjectOf = "VDNetLib::Host::HostOperations";
   }
   if ((not defined $createObjectOf) || (not defined $hostType)){
      $vdLogger->Error("Not sure which host object to create for $hostType ".
                       "with IP:$hostIP");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   eval "require $createObjectOf";
   if ($@) {
      $vdLogger->Error("unable to load module $createObjectOf:$@");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Trace("Creating object of $createObjectOf for $hostIP as OS is $hostType");
   my $hostObject = $createObjectOf->new( $hostIP,
                                          $stafObj,
                                          $vdnetSource,
                                          $vmRepository,
                                          $sharedStorage,
                                          $password);
   if ($hostObject eq FAILURE) {
      $vdLogger->Error("Failed to create $createObjectOf object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $hostObject;
}

1;
