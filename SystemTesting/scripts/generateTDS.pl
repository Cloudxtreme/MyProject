use strict;
use warnings;
use Carp;
use FindBin;
use Getopt::Long;
use Data::Dumper;
use LWP::Simple;

use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/";
use lib "$FindBin::Bin/../TDS/";
use VDNetLib::Session::Session;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   SKIP VDCleanErrorStack);
use VDNetLib::HPQC::TestcaseData;
use constant TRUE => VDNetLib::Common::GlobalConfig::TRUE;
use constant FALSE => VDNetLib::Common::GlobalConfig::FALSE;
my $cliParams = {};
unless (GetOptions(
                   "tds|t=s"  => \@{$cliParams->{tdsIDs}},
                   "resultdir|r=s" => \$cliParams->{resultDir}
                  )) {
                     print "Usage: $0 -g <tdsName> -r <resultDir>\n";
                     exit -1;
                  }

#Store session as a global variable
our $session = VDNetLib::Session::Session->new('cliParams' => $cliParams);
if ($session eq FAILURE) {
   $vdLogger->Error("Failed to create VDNet session object");
   $vdLogger->Debug(VDGetLastError());
   exit -1;
}

# Get the complete test list for this session
my $testcaseList = $session->GetTestList();
if ($testcaseList eq FAILURE) {
   $vdLogger->Error("Failed to testcase list");
   $vdLogger->Debug(VDGetLastError());
   exit -1;
}

#
# if user did not pass -r <resultDir> at CLI,
# then use /tmp
#
my $resultDir = $cliParams->{'resultDir'} || '/tmp';
my $jsonFile = $resultDir . '/vdnet-json';
open (FILE, ">$jsonFile") or die "Could not open file $!";

# hpqcExcelGenerator expects json data enclosed as[ ]
print FILE '[';
my $testCount = 1;
foreach my $testcase (@$testcaseList) {
   my $hpqcMap =  VDNetLib::HPQC::TestcaseData->new(
                                             testcaseHash => $testcase);
   my $jsonData = $hpqcMap->ConvertTestToJSON();
   print FILE $jsonData;
   if ($testCount != scalar(@$testcaseList)) {
      print FILE ',';
   }
   $testCount++;
}
print FILE ']';
close(FILE);

my @temp = split(/\./,$cliParams->{tdsIDs}[0]);
my $tds = $temp[-2];
$vdLogger->Info("TDS Name: $tds");
my $excelFile = $resultDir . "/$tds.xls";
if(ExportJSONToExcel($jsonFile, $excelFile)) {
   $vdLogger->Error("Failed to convert vdnet test case");
   exit -1;
} else {
   $vdLogger->Info("Generated file $excelFile");
   `rm -rf $jsonFile`; # remove the temp json file
   exit 0;
}


########################################################################
#
# ExportJSONToExcel--
#     Method to convert given JSON file to Excel file with the
#     format that HPQC can understand
#
# Input:
#     jsonFile: JSON file that follows the spec defined by
#               hpqcTestConverter.py
#     excelFile: Excel file name where the data should be exported
#
# Results:
#     None
#
# Side effects:
#     None
#
########################################################################

sub ExportJSONToExcel
{
   my $jsonFile  = shift;
   my $excelFile = shift;

   my $command = "python $FindBin::Bin/../../../misc/hpqc/hpqcExcelGenerator.py " .
                 "$jsonFile $excelFile";
   return system($command);
}
1;
