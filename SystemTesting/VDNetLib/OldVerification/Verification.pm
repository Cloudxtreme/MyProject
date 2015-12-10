########################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::OldVerification::Verification;

#
# 1) It acts as an interface to outside world for using any sort of test
# verification like Netstat, vmware.log, dmesg, PacketCapture.
# 2) Interface that any verification technique must adhere to, in order to
# work with vdNet automation.
# 3) Acts as a parent to various traffic tool so that parent provides a
# common interface to all child modules and they only need to implement
# methods which are specific that child.
#

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";
use Data::Dumper;


use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError VDGetLastError );

# Keep these lines as they help in debugging. The issue being When you make
# some change in NetperfTool and it has error doing eval NetperfTool at
# runtime doesnt give proper error message. Just keep these lines as they
# help in debugging.
# use VDNetLib::Verification::PktCapVerification;
# use VDNetLib::Verification::StatsVerification;

###############################################################################
#
# new -
#       This package acts as a parent class of all verification tools and
#       creates object of child classes of this module. It does so
#       by providing a common interface for object creation and object use.
#
# Input:
#       Hash containing traffic keys/value pairs and netadapter key/value pairs
#
# Results:
#       SUCCESS - A pointer to child instance/object of Verification
#       FAILURE - in case of error
#
# Side effects:
#       None
#
###############################################################################

sub new
{

   my $class = shift;
   my %options = @_;

   # Just check if workload is given or not.
   # Checking of testbed will be done by individual child if he needs it.
   if (not defined $options{workload} || not defined $options{verification}) {
      $vdLogger->Error("Workload hash or verification type not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $attrs  = {
     'workload'     => $options{workload},
     'testbed'    => $options{testbed},
   };

   my $hash = {'logObj' => $vdLogger};
   $attrs->{staf} = new VDNetLib::Common::STAFHelper($hash);
   if(not defined $attrs->{staf}) {
      $vdLogger->Error("Is staf running on localhost? staf handle not ".
                       "created");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $verificationType = $options{verification};
   my @supportedVeri = qw(Stats dvPortStats PktCap Dmesg VMwareLog ActiveVMNic);
   my $tool = undef;
   foreach $tool (@supportedVeri)
   {
      if($tool =~ m/$verificationType/i){
         # Overwrite in case user gives a different caps lock.
         $verificationType = $tool;
         last;
      } else {
         $tool = undef;
      }
   }

   if($tool = undef){
      $vdLogger->Error("Verification Type:$tool not supported");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $vdLogger->Debug("Instantiating obj of $verificationType"."Verification");
   # All the tools package name should adhere to the standard name used here.
   # E.g PktCapVerification, DmesgVerification, NetStatVerification
   my $childObjType = "VDNetLib::OldVerification::"."$verificationType"."Verification";
   eval "require $childObjType";
   if ($@) {
      $vdLogger->Error("Failed to load package $childObjType");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   my $self = $childObjType->new(workload => $attrs->{workload});
   if ($self eq FAILURE) {
      $vdLogger->Error("Failed to create obj of package $childObjType");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if (defined $self){
      # Copy the attributes of parent to child object.
      foreach my $key (keys %$attrs){
         $self->{$key} = $attrs->{$key};
      }
      bless $self, $childObjType;

      # Invoke child specific interpretation of testbed to figure out
      # which is source and which is destination OR where to launch
      # the verification binary.
      if ($self->ProcessTestbed() ne SUCCESS) {
         $vdLogger->Error("ProcessTestbed didnt return Success".Dumper($self));
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      # Build command E.g. C:\Tools\WinDump.exe for windows
      if ($self->BuildCommand() ne SUCCESS) {
         $vdLogger->Error("Verification BuildToolCommand didnt return Success");
         $vdLogger->Debug(Dumper($self));
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

      # For each key in hash convert the key into something which the tool
      # understands. E.g. to sniff on source host tcpdump understands it as
      # src host X.X.X.X. For port as "port 21"
      my $workloadPtr = $attrs->{workload};
      foreach my $key (keys %$workloadPtr){
         my $currentTestOption = $self->ProcessVerificationKeys($key,
                                                                $workloadPtr);
         if ($currentTestOption ne 0 ){
            $vdLogger->Trace("Appending $currentTestOption for key ".
                             "$key in filter String");
            $self->AppendTestOptions($currentTestOption);
         }
         # Server and client hashes have values verification might be
         # interested in.
         my $value = $workloadPtr->{$key};
         if ($value =~ /array/i) {
	    next;
         }
         if(ref($workloadPtr->{$key})){
            my $nestedHash = $workloadPtr->{$key};
            foreach my $nestedKey (keys %$nestedHash){
               $currentTestOption = $self->ProcessVerificationKeys($nestedKey,
                                                                   $nestedHash);
               if ($currentTestOption ne 0 ){
                  $vdLogger->Trace("Appending $currentTestOption for key ".
                                   "$nestedKey in filter String");
                  $self->AppendTestOptions($currentTestOption);
               }
            }
         }
      }
   } else {
      $vdLogger->Error("Unable to create child object of $verificationType" .
                       Dumper($self));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }


   return $self;

}

###############################################################################
#
# ProcessTestbed -
#       A void method which the child can override and do things which are
#       specific to that tool
#       Parents leaves a hook so that future childs can make changes without
#       modifying the parent.
#
# Input:
#       none
#
# Results:
#       SUCCESS
#
# Side effects:
#       None
#
###############################################################################

sub ProcessTestbed
{
   return SUCCESS;
}


###############################################################################
#
# AppendTestOptions --
#       Appends the given string to self->{filterString}
#
# Input:
#       String
#
# Results:
#       $self->{testOptions} string
#       FAILURE in case of error
#
# Side effects:
#       none
#
###############################################################################


sub AppendTestOptions
{
   my $self = shift;
   my $option = shift;
   if (not defined $option || $option eq "") {
      $vdLogger->Error("option:$option parameter missing in ".
                       "AppendTestOptions");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   #TODO: Change the name to verificationString when other verification modules
   # are introduced.
   if (defined $self->{filterString}) {
      $self->{filterString} = $self->{filterString} . " $option";
   }
}


###############################################################################
#
# ToolSpecificJob -
#       A void method which the child can override and do things which are
#       specific to that tool
#       Parents leaves a hook so that future childs can make changes without
#       modifying the parent.
#       Parent leaves the hook before calling start on server/client thus
#       will run the client/server with this change.
#
# Input:
#       none
#
# Results:
#       SUCCESS
#
# Side effects:
#       None
#
###############################################################################

sub ToolSpecificJob
{
   # A void method which has to be overridden in child.
   # Even if child doesn't want to implement it parent's method will
   # be called and SUCCESS will be returned.

   return SUCCESS;
}

1;
