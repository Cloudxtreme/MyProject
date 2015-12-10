#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use FindBin;

use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/";
use lib "$FindBin::Bin/../VDNetLib/Workloads/";
use lib "$FindBin::Bin/../VDNetLib/CPAN/5.8.8/";

use VDNetLib::Common::GlobalConfig;
use YAML qw(Dump Bless);
use Text::Table;
use File::Slurp;

VDNetLib::Common::GlobalConfig::CreateVDLogObj('logLevel'    => 7,
                                               # use 9 for full scale logging
                                               # use 7 for INFO level logging
                                               # use 4 for no out puts logging
                                               'logToFile'   => 1,
                                               'logFileName' => "/tmp/vdnet/keyyamldescriptorgenertor.log");
if (not defined $vdLogger) {
   print STDERR "Failed to create VDNetLib::Common::VDLog object";
   exit -1;
}

our $location  = "<local_code_path>/VDNetLib/Workloads/";
# Example
#our $location  = "/dbc/pa-dbc1102/prabuddh/prabuddhmain/vdnet/automation/VDNetLib/Workloads/";

our $yamlLocation = $location . "yaml/";
my ( $workload, $keysdatabase, $workloadObj, $yamlKeysDatabase);

# Get all packages
my $arrayOfWorkloadPackages = GetAllWorkloadPackages();
my $dummyHash = {};
foreach my $workload (@$arrayOfWorkloadPackages) {
   $vdLogger->Info("Loading $workload");
   my $packageName = "VDNetLib::Workloads::" . $workload;
   eval "require $packageName";
   if ($@) {
      $vdLogger->Error("Loading $packageName, failed: $@");
      VDSetLastError("EOPFAILED");
   }
   $workloadObj = $packageName->new(workload => $dummyHash, testbed => $dummyHash);
   $keysdatabase = $workloadObj->GetKeysTable();
   foreach my $key (keys %$keysdatabase) {
      if ((exists $keysdatabase->{$key}{linkedworkload}) &&
          (defined $keysdatabase->{$key}{linkedworkload})) {
           $keysdatabase->{$key}{type} = "component";
      }
   }
   $yamlKeysDatabase = GenerateYamlDescriptor($keysdatabase);
   my $file = $yamlLocation . $workload . '.yml';
   StoreYamlDescriptor($yamlKeysDatabase, $file);
   next;
}


sub GetAllWorkloadPackages
{
   my @files = read_dir $location;
   my @arrayOfWorkloadPackages;
   foreach my $file (@files)
   {
      if (($file eq 'Utils.pm') ||
          ($file eq 'Utilities.pm') ||
          ($file eq 'DVFilterSlowpathWorkload.pm') ||
          ($file eq 'TrafficWorkload.pm') ||
          ($file eq 'WorkloadKeys.pm') ||
          ($file eq 'yaml') ||
          ($file eq 'WorkloadsManager.pm')) {
         next;
      }
      my @array = split ('\.', $file);
      my $workloadName = $array[0];
      push @arrayOfWorkloadPackages, $workloadName;
   }
   return \@arrayOfWorkloadPackages;
}


sub GenerateYamlDescriptor
{
   my $keysdatabase = shift;
   eval {
      Bless ($keysdatabase);
   };
   if ($@) {
      $vdLogger->Error("Unable to convert hash to yaml : $@");
      VDSetLastError("EOPFAILED");
      return "FAILURE";
   }
   return $keysdatabase;
}


sub StoreYamlDescriptor
{
   my $descriptor = shift;
   my $file       = shift;
   eval {
      my $destTdsHandle;
      open($destTdsHandle, ">", $file);
      $vdLogger->Debug("Storing yaml descriptor at $file");
      print $destTdsHandle Dump $descriptor;
   };
   if ($@) {
      $vdLogger->Error("Unable to store yaml descriptor at $file: $@");
      VDSetLastError("EOPFAILED");
      return "FAILURE";
   }
   return "SUCCESS";
}