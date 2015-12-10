#!/usr/bin/perl -w

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use VMP;
use PLSTAF;
use vet;

use Getopt::Long qw(GetOptionsFromString);
use Getopt::Long;

# Following are the parameters coming from portable tools framework
# convert these parameters into vdNet command line args

my $vmDisplayName;
my $esxIP;
my $localIP;
my $vmOSType;
my $resultFile;
my $vmIP;
# helper is esxip,vmip of the helper VM
my $helper;

my $portableToolsUsage = "Usage: -vmdisplayname <vmName> -esxip <esxIp> ".
                         "-localip <localIP> -vmostype <ostype> -resultfile ".
                         "<resultfile> -vmip  <vmIP>\n";

my $driverName = "vmxnet3";

#my $vdNetCmd = "/root/sandbox/non-framework/VMCore/departments/automation/harness/vdNet.pl";
my $vdNetCmd = "/automation/main/vdNet.pl";
my $vdNetArgs="";
my $PowMgmt = " -t $driverName:PowerMgmt.WakeOnPktRcv:$driverName " .
              " -t $driverName:PowerMgmt.WoLMagicPktRcv:$driverName ";
my $IPv6Pow = " -t $driverName:IPv6.NetperfTCP:$driverName " .
              " -t $driverName:IPv6.NetperfUDP:$driverName " .
              " -t $driverName:IPv6.TSO6_VM-VM_Basic:$driverName " .
              " -t $driverName:IPv6.TSO6_VM-VM_SR:$driverName " .
              " -t $driverName:IPv6.TSO6_VM-VM_SRD:$driverName " .
              " -t $driverName:IPv6.sVLAN:$driverName " .
              " -t $driverName:IPv6.gVLAN:$driverName " ;

my $JTCL = " -t $driverName:Functional.NetperfIntra:$driverName " .
           " -t $driverName:BasicSanity.PowerOnOff:$driverName " .
           " -t $driverName:BasicSanity.HotAddvNIC:$driverName " .
           " -t $driverName:BasicSanity.SuspendResume:$driverName " .
           " -t $driverName:BasicSanity.SnapshotRevertDelete:$driverName " .
           " -t $driverName:BasicSanity.CableDisconnect:$driverName " .
           " -t $driverName:BasicSanity.DisableEnablevNIC:$driverName " .
           " -t $driverName:LPD.LRO_LPD_Functionality:$driverName " .
           " -t $driverName:CSO.Basic:$driverName " .
           " -t $driverName:Ethtool.DisableCSO:$driverName " .
           " -t $driverName:JumboFrame.JF_VM-VM_Basic:$driverName " .
           " -t $driverName:JumboFrame.JF_VM-VM_SR:$driverName " .
           " -t $driverName:JumboFrame.JF_VM-VM_PingSR:$driverName " .
           " -t $driverName:JumboFrame.JF_VM-VM_SRD:$driverName " .
           " -t $driverName:TSO.TSO_VM-VM_Basic:$driverName " .
           " -t $driverName:Ethtool.DisableTSO:$driverName " .
           " -t $driverName:TSO.TSO_VM-VM_SR:$driverName " .
           " -t $driverName:TSO.TSO_VM-VM_SRD:$driverName " .
           " -t $driverName:VLAN.sVLAN:$driverName " .
           " -t $driverName:VLAN.gVLAN:$driverName " .
           " -t $driverName:JumboFrame.JF_VM-VM_gVLAN:$driverName " .
           " -t $driverName:JumboFrame.JF_VM-VM_sVLAN:$driverName " .
           " -t $driverName:TSO.TSO_VM-VM_gVLAN:$driverName " .
           " -t $driverName:TSO.TSO_VM-VM_sVLAN:$driverName ";

# Not validating GetOptions return value as portable tools could have other 
# options for other FVT tests.

GetOptions (
              "vmdisplayname=s"  => \$vmDisplayName,
              "esxip=s"    => \$esxIP,
              "localip=s"  => \$localIP,
              "vmostype=s" => \$vmOSType,
              "resultfile=s" => \$resultFile,
              "vmip=s" => \$vmIP,
              "helper=s" => \$helper,
              "help|h"       => sub { 
                                  print $portableToolsUsage; 
	                          exit 0;
                                   },
  );

# validate all parameters
if ( (not defined $vmDisplayName) || 
     ($vmDisplayName eq "") ) {
   die "Invalid vmDisplayName \n";
}

if ( (not defined $esxIP) ||
     ($esxIP eq "") ) {
   die "Invalid esxIP \n";
}

if ( (not defined $localIP) ||
     ($localIP eq "") ) {
   die "Invalid localIP \n";
}

if ( (not defined $vmOSType) ||
     ($vmOSType eq "") ) {
   die "Invalid vmostype \n";
}

if ( (not defined $resultFile) ||
     ($resultFile eq "") ) {
   die "Invalid resultFile \n";
}

if ( (not defined $vmIP) ||
     ($vmIP eq "") ) {
   die "Invalid vmIP \n";
}

if ( (not defined $helper) ||
     ($helper eq "") ) {
   die "Invalid helper \n";
}
my @tmpArr = split(/:/,$helper);

#$vdNetArgs .= " -i \"$vmIP,$esxIP\" -i \"$tmpArr[1],$tmpArr[0]\" " .
#              "-t $driverName:BasicSanity.PowerOnOff:$driverName " .
#              "-t $driverName:BasicSanity.SuspendResume:$driverName " .
#              "-t $driverName:BasicSanity.SnapshotRevertDelete:$driverName " .
#              "-resultfile $resultFile";
$vdNetArgs .= " -s -i \"$vmIP,$esxIP\" -i \"$tmpArr[1],$tmpArr[0]\" " . "$JTCL " . "$IPv6Pow " . "$PowMgmt " .  " -resultfile $resultFile";
#              "-t $driverName:BasicSanity.PowerOnOff:$driverName " .
#              "-t $driverName:BasicSanity.SuspendResume:$driverName " .
#              "-t $driverName:BasicSanity.SnapshotRevertDelete:$driverName " .
#              "-resultfile $resultFile";
$vdNetCmd .= $vdNetArgs;
#print "$vdNetCmd\n";
system($vdNetCmd);

