package VDNetLib::Common::ATSConfig;
use strict;

use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use VDNetLib::Common::VDErrorno qw( FAILURE SUCCESS VDSetLastError VDGetLastError );
use VDNetLib::Common::VDLog;
use Cwd;
use FindBin;
use Data::Dumper;


use constant ATSConfig => "$FindBin::Bin/ATS/config.properties";

################
# Globals state variables
################
use constant baseURL => "http://vshield-test.eng.vmware.com/results" ;
use constant admin => "qa-automation";

################
# External Tools
################
use constant p4 => '/build/toolchain/lin32/perforce-r10.1/p4';
use constant bldtool => "/build/apps/bin/bld";

################
# Perforce Data
################
use constant p4Server => "build-p4proxy.eng.vmware.com:1947";
use constant p4User =>  "qa-automation";
use constant p4Pass =>  "U9NqLq11qjd2u7T" ;

# These two lists must be maintained together
our @branchList= ("vshield-niobe", "vshield-logos-rel", "vshield-main", "vshield-main-rel",
                  "vshield-trinity-next");
our %p4Clients =("vshield-main" => "ats-client-main",
                 "vshield-trinity-rel" => "ats-client-trinity-rel",
                 "vshield-trinity-next" => "ats-client-trinity-next",
                 "vshield-main-rel" => "ats-client-main-rel",
                 "vshield-niobe" => "ats-client-niobe",
                 "vshield-niobe-rel" => "ats-client-niobe-rel",
                 "vshield-logos-rel" => "ats-client-logos-rel",
                 "vshield-sp1-release" => "ats-client-sp1-release");

our %clients = ("vshield-main" => "main",
                "vshield-trinity-rel" => "trinity-rel",
                "vshield-trinity-next" => "trinity-next",
                "vshield-main-rel" => "main-rel",
                "vshield-niobe" => "niobe",
                "vshield-niobe-rel" => "niobe-rel",
                "vshield-logos-rel" => "logos-rel",
                "vshield-sp1-release" => "sp1-release");

sub p4Login
{
   my $cmd = "echo " . p4Pass . "|" . p4 . " -p ". p4Server . " -u " . p4User ." login " ;
   print $cmd;
   my $out = `$cmd`;
   print $out;
   return $out;
}

sub trim
{
   my $string = shift;

   $string =~ s/^\s+//;
   $string =~ s/\s+$//;
   return $string;
}

sub convert_time
{
  my $hr=int($_[0]/3600);
  my $rest=$_[0] % 3600;
  my $min=int($rest/60);
  my $sec=int($rest % 60);

  if ($hr >0) {
     return sprintf ("%02d hrs %02d min  %02d sec", $hr,$min,$sec)
  }     elsif ($min > 0 ) {
     return sprintf ("%02d mins  %02d sec", $min,$sec)
  } else {
     return sprintf ("%02d sec ", $sec)
  }
}

 1;
