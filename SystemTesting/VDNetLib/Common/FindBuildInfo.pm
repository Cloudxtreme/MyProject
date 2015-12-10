#!/usr/bin/env perl -w
package VDNetLib::Common::FindBuildInfo;
########################################################################
# Copyright 2012 VMware, Inc.  All rights reserved.
# -- VMware Confidential
########################################################################

use warnings;
use strict;
use Data::Dumper;
use POSIX qw(SIGALRM);

use VDNetLib::Common::GlobalConfig qw ($vdLogger );
use VDNetLib::Common::VDErrorno qw( FAILURE SUCCESS VDSetLastError
                                    VDGetLastError );
BEGIN {
   $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = "IO::Socket::SSL";
   $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
   eval "require IO::Socket::SSL"; # not using Crypto::SSLeay see PR 998526
}
my $ob_bld_url  = "http://buildapi.eng.vmware.com/ob/build";
my $sb_bld_url  = "http://buildapi.eng.vmware.com/sb/build";
use constant BUILDAPI_PATH  =>
  'http://buildapi.eng.vmware.com/';

##  The data obtained from the above url comes in json format, which
##  looks like this:
##
##     {"key": "value", "foo": bar, "product": "server"}
##
##  All in a single line. Some values have double quotes, some don't.
##  Here is a sample of the data obtained:
##
##     backedup              false
##     branch                vmcore-main
##     bugid                 null
##     buildstate            succeeded
##     buildsystem           ob
##     buildtree             /build/storage17/release/bora-296596
##     buildtree_size_in_mb  24773
##     buildtype             beta
##     changeset             1146450
##     endtime               2010-09-06 19:22:26.845436
##     id                    296596
##     locales               en
##     ondisk                true
##     prodbuildnum          19642
##     product               server
##     progress              null
##     releasetype           beta
##     saved                 false
##     starttime             2010-09-06 18:30:11.180879
##     version               5.0.0

sub getOfficialBuildInfo($)
{
  my $buildNumber = shift;

  return GetBuildInfo($buildNumber, "official");
}

sub getSandboxBuildInfo($)
{
  my $buildNumber = shift;

  return GetBuildInfo($buildNumber, "sandbox");
}


########################################################################
#
# GetBuildInfo--
#      Routine to get all information available on buildweb about the
#      given build
#
# Input:
#      buildNumber : build number (required)
#      buildType   : official or sandbox (default is official)
#
# Results:
#      Reference to a hash containing build information. Some of the
#      keys are product, branch, ondisk etc. Refer to buildapi
#      documentation for more details
#
# Side effects:
#      None
#
########################################################################

sub GetBuildInfo
{
   my $buildNumber = shift;
   my $buildType   = shift ;
   my $originalType = $buildType;

   if ($buildNumber eq FAILURE) {
      $vdLogger->Error("Build number not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ($buildNumber =~ /ob-/i) {
      $buildType = "official";
   } elsif ($buildNumber =~ /sb-/i) {
      $buildType = "sandbox";
   }

   $buildNumber =~ s/ob-|sb-//g; # remove any prefix
   my $options = {
      id => $buildNumber,
   };

   if(not defined $originalType){
      $buildType = "official";
   }
   my $result = GetBuilds($options, $buildType);
   if ($result ne FAILURE) {
      # If getting build result is empty, the $result is as follow:
      #
      #  $VAR1={
      #    '_previous_url' => 'null}',
      #    '_list' => '[]',
      #    '_page_count' => '0',
      #    '_next_url' => 'null',
      #    '{_total_count' => '0'
      #  };
      #
      my $buildInfo = @{$result}[0];
      if(($buildInfo->{_list} eq '[]') && (not defined $originalType)){
         # Try to find build from sandbox
         $result = GetBuilds($options, "sandbox");
         if($result eq FAILURE){
            $vdLogger->Error("Failed to get build for $buildNumber");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
   } else {
         $vdLogger->Error("Failed to get build for $buildNumber");
         VDSetLastError(VDGetLastError());
         return FAILURE;
   }
   return @{$result}[0];
}

########################################################################
#
# GetBuilds--
#     Routine to get build information for any product from buildweb
#
# Input:
#     options: reference to a hash containing all the query fields
#              supported by buildapi, for example:
#              product, branch, ondisk etc. Refer to
#              http://buildapi.eng.vmware.com for detailed information
#     buildType: "official" or "sandbox" (default is official)
#
# Results:
#     Reference to an array in which each element is a reference
#     to a hash containing a build;s information. Again, refer
#     to buildapi documentation for details;
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetBuilds
{
   my $options   = shift;
   my $buildType = shift || "official";

   my $url = ($buildType =~ /official|ob/i) ? $ob_bld_url : $sb_bld_url;

   my $query = $url . '/?';
   foreach my $opt (keys %$options) {
      if ( $opt eq 'id') {
         my @vals = split /:/, $options->{$opt};
         my $size = @vals;
         if ($size > 1) {
            $query = $query . "product=" . $vals[0];
            $query = $query . "&branch=" . $vals[1];
            $query = $query . "&buildtype=" . $vals[2];
            $query = $query . "&buildstate=succeeded&ondisk=true&_limit=1";
            $query = $query . "&_order_by=-build";
         } else {
            if ($query =~ /\?$/) {
               # do not add & immediately after ? in the url
               $query = $query . $opt . '=' . $options->{$opt};
            } else {
               $query = $query . '&' . $opt . '=' . $options->{$opt};
            }
         }
      } else {
         if ($query =~ /\?$/) {
            # do not add & immediately after ? in the url
            $query = $query . $opt . '=' . $options->{$opt};
         } else {
            $query = $query . '&' . $opt . '=' . $options->{$opt};
         }
      }
   }

   $vdLogger->Info("Executing query: $query");
   my (%buildInfo, $key, $value);
   my @builds = ();
   my $agent = LWP::UserAgent->new();
   my $request = HTTP::Request->new("GET", $query);
   my $response = $agent->request($request);
   unless ($response->is_success()) {
      $vdLogger->Error("$query returned code:".$response->code());
      $vdLogger->Debug("$query returned the following response : ".
			Dumper($response));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   my $data = $response->content();

   # Get the list of builds that satisfied the query given above
   if ($data =~ /\"_list\": \[{(.*)}\]/) {
      $data = $1;
   }

   ## All the pairs are separated with a comma and a space.
   foreach my $build (split /}, {/, $data) {
      my $buildInfo;
      foreach (split /, /, $build) {
         ## The key-value pair is separated with a colon and a space.
         if (/([^:]*): (.*)/) {
            $key   = $1;
            $value = $2;
            ## remove double quotes
            $key   =~ s/"//g;
            $value =~ s/"//g;
            $buildInfo->{$key} = $value;
         }
      }
      push(@builds, $buildInfo);
   }
   return \@builds;
}


########################################################################
#
# GetSTAFSDKBLDs--
#     Routine to get staf sdk builds
#
# Input:
#     branch: staf sdk branch, (optional)
#            for example, VC6X_STAFSDK, VC5X_STAFSDK. default is
#            VC6X_STAFSDK;
#     buildType: official or sandbox build (default is official)
#
# Results:
#     Reference to array in which each element is reference to a hash
#     containing staf sdk build's information;
#     FAILURE in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetSTAFSDKBLDs
{
   my $branch = shift || VDNetLib::Common::GlobalConfig::DEFAULTSTAFSDKBRANCH;
   my $buildType = shift || "official";

   my $options = {
      product => "staf",
      branch  => $branch,
      ondisk  => "true",
      _limit  => "5",
      _order_by => "-id"
   };
   return GetBuilds($options, $buildType);
}

#######################################################################
#
# GetBuildDetails --
#     Method to get the build details 
#     like branch, change of the build etc.
#
# Input:
#     build - build number for which info is required.
#
# Results:
#     buildinfo, in case of success.
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
# Note:
#    This API is just used by ATS.pm. Consider removing this API 
#    and start using GetBuildInfo().
#
#########################################################################

sub GetBuildDetails
{
   my $build = shift;
   my $stafHelper = shift;
   my $buildType;
   my $buildInfo;
   my $command;
   my $result;

   if ( not defined $build ) {
      $vdLogger->Error("Build number is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # check the build types.
   if ($build =~ /sb-/i) {
      $buildType = "sb";
   } else {
      $buildType = "ob";
   }
   $build =~ s/ob-|sb-//g; # remove any prefix

   $command = "/build/apps/bin/bld --build-kind=$buildType info $build";
   $result = $stafHelper->STAFSyncProcess("local", $command);
   if (($result->{rc} != 0 ) || ($result->{exitCode} != 0)) {
      $vdLogger->Error("Failed to get the build information for $build");
      $vdLogger->Error(Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   my @buildData = split(/\n/, $result->{stdout});
   foreach my $line (@buildData) {
      $line =~ s/^\s+|\s+$//g;
      my ($key, $value) = split(/:/, $line);
      $key =~ s/^\s+|\s+$//g;
      $value =~ s/^\s+|\s+$//g;
      $buildInfo->{$key} = $value;
   }
   return $buildInfo;
}


########################################################################
#
# GetHostVMODLChecksum --
#     Method to get the vmodl checksum value of the given ESX host
#
# Input:
#     host: ip address of the host (Required)
#
# Results:
#     vmodl checksum value, if successful;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetHostVMODLChecksum
{
   my $host = shift;

   my $query = 'https://' . $host . '/sdk/vim.xml';
   my $httpResponse = HTTPQuery($query);
   if ($httpResponse eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $data = $httpResponse->content();
   $data =~ /<checksum>(.*)<\/checksum>/;
   my $checksum = $1;

   if ((not defined $checksum) || ($checksum eq "")) {
      $vdLogger->Error("Unable to find VMODL checksum of $host");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   return $checksum;
}


########################################################################
#
# GetMatchingSTAFBuild --
#     Routine to get STAF SDK build matching the given vmodl checksum
#
# Input:
#     vmodl: vmodl checksum  value (Required)
#     buildType: "ob" for official or "sb" for sandbox
#               (Optiona, default is "ob")
#
# Results:
#     staf sdk build number matching the given checksum;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetMatchingSTAFBuild
{
   my $vmodl      = shift;
   my $buildType  = shift || "ob";

   my $query = "http://engweb.eng.vmware.com/~nathanp/vmodl.php?" .
               "action=getMatchChecksum&service=" . $buildType .
               "&product=staf&checksum=" . $vmodl .
               "&limit=50";

   my $httpResponse = HTTPQuery($query);
   if ($httpResponse eq FAILURE) {
      $vdLogger->Error("HTTP query $query returned failure");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $data = $httpResponse->content();

   my @temp = split(/\s/, $data);
   if ((not defined $temp[0]) || ($temp[0] eq "")) {
      $vdLogger->Debug("Unable to find vmodl matching STAF SDK build");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return $temp[0];
}


########################################################################
#
# HTTPQuery--
#     Routine to request the given query and send the response back
#
# Input:
#     query: complete query string (Required)
#     timeout: max timeout for the response (Optional, default 30s)
#
# Results:
#     http response hash (refer to LWP::UserAgent), if successful;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub HTTPQuery
{
   my $query   = shift;
   my $timeout = shift;

   # Save https_proxy value
   my $httpProxyEnv = $ENV{https_proxy};
   # Set the http_proxy value to NULL to avoid the error:Bug872265
   # The script was not able to connect to remote Host when the
   # http_proxy is set to 'proxy.vmware.com:3128'
   $ENV{https_proxy}='';

   $timeout = (defined $timeout) ? $timeout : 30;

   if (not defined $query) {
      $vdLogger->Error("Query not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $signal = POSIX::SigSet->new(SIGALRM);

   $vdLogger->Debug("Sending HTTP query: $query");
   my $action = POSIX::SigAction->new(sub {
                                         $vdLogger->Error("HTTPQuery timeout");
                                         VDSetLastError("ETIMEDOUT");
                                         return FAILURE;
                                     },
                                     $signal);

   #
   # LWP::UserAgent does not have max timeout value for response.
   # So, we use alarm to quit the request after given timeout.
   # Otherwise, the request will hang forever
   #
   POSIX::sigaction(SIGALRM, $action);
   alarm ($timeout);
   my $agent = LWP::UserAgent->new(timeout => 10);
   my $request = HTTP::Request->new("GET", $query);
   my $response = $agent->request($request);

   # Restore the http_proxy to initial value
   $ENV{https_proxy} = $httpProxyEnv if defined $httpProxyEnv;
   alarm (0); # reset the alarm
   unless ($response->is_success()) {
      $vdLogger->Warn("$query returned code:".$response->code());
      $vdLogger->Debug("$query returned the following response : ".
			Dumper($response));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return $response;
}


########################################################################
#
# GetLatestSTAFSDK--
#     Routine to get latest and successful STAF SDK build from the
#     given branch
#
# Input:
#     branch: name of the branch. Example: vmkernel-main, vsphere5x etc
#             (Optional, default is vmkernel-main)
#
# Results:
#     undef, if no STAF SDK build is found;
#     staf build, if a staf sdk build is found successfully;
#     "FAILURE", in case of any other error
#
# Side effects:
#     None
#
########################################################################

sub GetLatestSTAFSDK
{
   my $branch = shift;

   #
   # For prod2013-stage ESX builds, prod2013-vsan, vsphere-2015, 
   # vsphere-2015-rel, vmkernel-main is the branch
   #
   # If the given branch does not exist in the following map, then
   # use the default branch: vmkernel-main
   #
   my $branchMap = {
      'prod2013-stage' => 'prod2013-vsan',
      'prod2013-vsan'  => 'prod2013-vsan',
      'vsphere-2015'   => 'vsphere-2015',
      'vsphere-2015-rel' => 'vsphere-2015-rel',
      'vmkernel-main'   => 'vmkernel-main'
   };
   if (not exists $branchMap->{lc($branch)}) {
      $branch = VDNetLib::Common::GlobalConfig::DEFAULTSTAFSDKBRANCH;
   } else {
      $branch = $branchMap->{lc($branch)};
   }

   $vdLogger->Info("Getting STAF SDK from $branch branch");
   my $builds = VDNetLib::Common::FindBuildInfo::GetSTAFSDKBLDs($branch);

   if ($builds eq FAILURE) {
      $vdLogger->Error("Failed to get staf sdk builds");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $stafBldToUse = undef;
   foreach my $build (@{$builds}) {
      if ($build->{buildstate} =~ /succeeded/i) {
         $stafBldToUse = $build->{id};
         last;
      }
   }
   return $stafBldToUse;
}


########################################################################
#
# FindMatchingESXFromCloudbuild --
#      Find ESX build
#
# Input:
#      vcvaBuild: vcva Build number
#      buildType
#
# Results:
#      return: ESX build number if SUCCESS
#      else return: FAILURE
#
# Side effects:
#      None
#
########################################################################

sub FindMatchingESXFromCloudbuild
{
   my $vcvaBuild  = shift;  #mandatory
   my $buildType  = shift;  #Option, default is ob: official build
   my $esxBldToUse;

   if (not defined $vcvaBuild) {
      $vdLogger->Error("vcva Build number is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $vcvaBuild) {
      $buildType = "ob";
   }

   # Get the VMODL checksum of the vcva under test
   my $vcvaChecksum =
      VDNetLib::Common::FindBuildInfo::GetCloudVMChecksum($vcvaBuild,$buildType);
   if ($vcvaChecksum eq FAILURE) {
      $vdLogger->Error("Failed to find the vmodl of $vcvaBuild");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("vcvaBuild $vcvaBuild VMODL checksum: $vcvaChecksum");

   # find the ESXi build matching the vcva's vmodl checksum
   $esxBldToUse =
         VDNetLib::Common::FindBuildInfo::GetMatchingESXBuild($vcvaChecksum);
   if ((not defined $esxBldToUse) || (FAILURE eq $esxBldToUse)) {
      $vdLogger->Error("No ESX build defined/found");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $vdLogger->Info("Using esx build $esxBldToUse");
   return $esxBldToUse;
}


########################################################################
#
# GetCloudVMChecksum --
#     Method to get the vmodl checksum value of the given CloudVM
#
# Input:
#     cloudVM: Mandatory
#     build type
# Results:
#     vmodl checksum value, if successful;
#     FAILURE, in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetCloudVMChecksum
{
   my $cloudVM = shift; # mandatory
   my $buildType  = shift || "ob";

   my $checksum = undef;
   my $queryweb;
   my $query;

   if ($cloudVM eq undef) {
     $vdLogger->Error("Failed to define cloudVM");
     return FAILURE;
   }
   if ($buildType eq "ob"){
      $queryweb = BUILDAPI_PATH  . 'ob/deliverable/' . '?build=' . $cloudVM;
   } else {
      $queryweb = BUILDAPI_PATH  . 'sb/deliverable/' . '?build=' . $cloudVM;
   }
   $vdLogger->Info("query buildweb: $queryweb");
   my $httpResponse = HTTPQuery($queryweb);

   $vdLogger->Info("httpResponse: $httpResponse");
   if ($httpResponse eq FAILURE) {
      $vdLogger->Error("Failed to get the vmodl checksum of vcva $cloudVM");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $data = $httpResponse->content();
   #
   # Matching:  publish/VMware-VmodlChecksum-xxxxx
   #
   if ($data =~ /(VMware-VmodlChecksum-\S+)/) {
      my $path = $1;
      $path =~ s/",//g;
      if ($buildType eq "ob") {
        $query = 'http://buildweb.eng.vmware.com/ob/api/' . $cloudVM .
                 '/deliverable/?file=publish/' . $path;
      } else {
        $query = 'http://buildweb.eng.vmware.com/sb/api/' . $cloudVM .
                 '/deliverable/?file=publish/' . $path;
      }
      $vdLogger->Debug("query buildweb: $query");
      $httpResponse = HTTPQuery($query);
      $vdLogger->Debug("httpResponse: $httpResponse");
      if ($httpResponse eq FAILURE) {
        $vdLogger->Error("Failed to get the vmodl checksum of vcva $cloudVM");
        VDSetLastError(VDGetLastError());
        return FAILURE;
      }
      #  #define VIM_VERSION_DEV_VMODL_CHECKSUM
      #  "9b29ca14b8eb187bedc8b387f7c6a966"
      $data = $httpResponse->content();
      $vdLogger->Debug("http data: $data");
      if ($data =~ /VIM_VERSION_DEV_VMODL_CHECKSUM\s+"(\S+)"/) {
        $vdLogger->Info("checksum: $1");
        $checksum = $1;
      }
   }

   if ((not defined $checksum) || ($checksum eq "")) {
      $vdLogger->Error("Unable to find VMODL checksum of vcva $cloudVM");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

  $vdLogger->Debug("vcva CloudVM vmodl checksum: $checksum");
   return $checksum;
}


########################################################################
#
# GetMatchingESXBuild --
#     Routine to get ESX build matching the given vmodl checksum
#
# Input:
#     vmodl: vmodl checksum  value (Required)
#     buildType: "ob" for official or "sb" for sandbox
#               (Option, default is "ob")
#
# Results:
#     esx build number matching the given checksum;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetMatchingESXBuild
{
   my $vmodl      = shift;
   my $buildType  = shift || "ob";

   my $query = "http://engweb.eng.vmware.com/~nathanp/vmodl.php?" .
               "action=getMatchChecksum&service=" . $buildType .
               "&product=server&checksum=" . $vmodl .
               "&limit=50";

   my $httpResponse = HTTPQuery($query);
   if ($httpResponse eq FAILURE) {
      $vdLogger->Error("HTTP query $query returned failure");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $data = $httpResponse->content();

   my @temp = split(/\s/, $data);
   if ((not defined $temp[0]) || ($temp[0] eq "")) {
      $vdLogger->Debug("Unable to find vmodl matching ESXi build");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return $temp[0];
}


########################################################################
#
# FindPowerCLIBuild--
#     Routine to get latest and successful PowerCLI build from the
#     given branch
#
# Input:
#     branch: name of the branch. powershell-box
#
# Results:
#     undef, if no PowerCLI build is found;
#     PowerCLI build, if a PowerCLI build is found successfully;
#     "FAILURE", in case of any other error
#
# Side effects:
#     None
#
########################################################################

sub FindPowerCLIBuild
{
   my $branch = shift || "powershell-box";
   my $builds = VDNetLib::Common::FindBuildInfo::GetPowerCLIBLDs($branch);

   if ($builds eq FAILURE) {
      $vdLogger->Error("Failed to get staf sdk builds");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   my $powerCLIBldToUse = undef;
   foreach my $build (@{$builds}) {
      if ($build->{buildstate} =~ /succeeded/i) {
         $powerCLIBldToUse = $build->{id};
         last;
      }
   }
   return $powerCLIBldToUse;
}


########################################################################
#
# GetPowerCLIBLDs--
#     Routine to get powercli builds
#
# Input:
#     branch: powercli branch, (powershell-box)
#
#     buildType: release or beta
#
# Results:
#     Reference to array in which each element is reference to a hash
#     containing PowerCLI build's information;
#     FAILURE in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub GetPowerCLIBLDs
{
   my $branch = shift || "powershell-box";
   my $buildType = shift || "official";

   my $options = {
      product => "vim4ps",
      branch  => $branch,
	  ondisk  => "true",
      _limit  => "5",
      _order_by => "-id"

   };
   return GetBuilds($options, $buildType);
}


########################################################################
#
# GetBuildNumber --
#     Get build number from given host/vc IP
#
# Input:
#     ipaddress: ip address of ESX or VC
#
# Results:
#     Build number, if successful;
#     FAILURE, in case of error
#
# Side effects:
#     None
#
########################################################################

sub GetBuildNumber
{
   my $ipaddress      = shift;
   my $result;
   my $getBuildScript = "$FindBin::Bin/../scripts/getVimBuild.py";


   #
   # check if host is reachable, else return failure.
   #
   $result = VDNetLib::Common::Utilities::Ping($ipaddress);
   if ($result ne 0) {
      $vdLogger->Debug("host $ipaddress is not reachable");
      VDSetLastError("ENETDOWN");
      return FAILURE;
   }
   my $build = `python $getBuildScript -s $ipaddress`;
   if ($build !~ /\d+/) {
      $vdLogger->Warn("Failed to get build number from ip $ipaddress");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   } else {
      chomp($build);
      return $build;
   }
}


########################################################################
#
# GetBranchNameFromIP --
#     Get branch name from given host/vc IP
#
# Input:
#     ipaddress: ip address of ESX or VC
#
# Results:
#     Branch name, if successful;
#     FAILURE, in case of error
#
# Side effects:
#     None
#
########################################################################

sub GetBranchNameFromIP
{
   my $ipaddress  = shift;

   my $build = GetBuildNumber($ipaddress);
   if ($build eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $buildInfo = GetBuildInfo($build);

   if (defined $buildInfo->{'branch'}) {
      return $buildInfo->{'branch'};
   } else {
      $vdLogger->Debug("Couldn't get build info for $build:" .
         Dumper($buildInfo));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
}
1;
