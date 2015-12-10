########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
########################################################################

package TDS::Main::VDNetMainTds;

################################################################################
# This file contains the structured hash for TDS entries                       #
# The following lines explain the keys of the internal                         #
# Hash.                                                                        #
#                                                                              #
# =============================================================================#
# Key in hash           Description                                            #
# =============================================================================#
# TestSet             => Test Category name                                    #
# TestName            => Test Name                                             #
# TestMethod          => M for manual and A for automation, A/M for both       #
# SupportedSWPlatforms=> Supported Test platforms(Takes ALL for ALL            #
#                        platforms mentioned in the TDS or specific);          #
# SupportedDrivers    => Supported drivers (Takes ALL for if ALL the drivers   #
#                        supported else takes specific                         #
# Tags                => Marks a test case with part of a particular testing   #
# NOOFMACHINES        => Min no. of machines requried to test                  #
# SETUP               => INTER|INTRA                                           #
# TARGET              => INTERFACE or CONNECTION                               #
# CONNECTION          => has two ends: Source and Destination each with NIC    #
#                        definition                                            #
# WORKLOADS           => modules like netperf iperf or VM operations           #
# VD_PRE              => pointer to pre-processing routine                     #
# VD_POST             => pointer to post-processing routine                    #
# VD_MAIN             => pointer to main                                       #
################################################################################

use FindBin;
use lib "$FindBin::Bin/..";
use Data::Dumper;
use VDNetLib::Common::VDErrorno qw( FAILURE SUCCESS VDSetLastError VDGetLastError );

{
   # Global TDS - it is same as Main sheet in the excel TDS sheet
   @Main = qw(TestEsx Sample SampleVC VirtualNetDevices TestSet NetIORM);
   %TDS = ();
}

########################################################################
# new --
#       This is the constructor for TDS::Main::VDNetMainTds
# Input:
#       Reference to a hash for a given test category, that has
#	testcase hashes for all the tests in that category
#
# Results:
#       An instance/object of TDS::Main::VDNetMainTds class which is
#	the TDS.
#
# Side effects:
#       Fills in the global TDS hash everytime it is called for a
#	a test category.
#
########################################################################

sub new
{

    my ($proto) = shift;
    my $tdsRef = shift;
    my ($class) = ref($proto) || $proto;
    my $setName;

    if ( ( not defined $tdsRef ) || (ref($tdsRef) ne "HASH") ) {
       VDSetLastError("EINVALID");
       return "FAILURE";
    }
    my $temp = $class; # temp variable is used to avoid prefixing TDS::
                       # in front of all Tds.pm files
    if ($class =~ /TDS::/) {
       $temp =~ s/TDS:://g;
    }
    if ( $temp =~ /(.*)Tds$/ ) {
       $setName = $1;
    }

    if ( !exists $TDS->{$setName} ) {
       # next argument should be a ref to hash
       if ( ref($tdsRef) eq 'HASH' ) {
          %{$TDS{$setName}} = %$tdsRef;
       }
    }

    my $self = {};
    $self->{tdsref} = $tdsRef;
    return (bless($self, $class));
}


########################################################################
# GetTDSIDs --
#       This returns all the TDS IDs currently in the object
#	TDS ID is in Category.Testcase format, e.g.
#	TDS::Sample::Sample.TSOTCP
#
# Input:
#       none
#
# Results:
#       Reference to an array that contains list of TDS IDs
#
# Side effects:
#       none
#
########################################################################

sub GetTDSIDs
{
   my $self = shift;
   my @output = ();
   my $tdsHash = $self->{tdsref};
   foreach my $testName (keys %$tdsHash) {
         push(@output, $testName);
   }
   return \@output;
}

########################################################################
# GetConnectionOfTDSID --
#       Returns reference to the CONNECTION corresponding to the given
#       TDS ID
#       TDS ID is in Category.Testcase format, e.g.
#	     TDS::Sample::Sample.TSOTCP
#
# Input:
#       TDS ID string, which is in Category.TestCase format
#
# Result:
#       Reference to an CONNECTION in the TDS hash
#
# Side effects:
#       none
#
########################################################################

sub GetConnectionOfTDSID
{
   shift;
   my $tdsID = shift;

   my ($set, $tds) = split(/\./,$tdsID);
   if ( (not defined $set) || ( ! exists $TDS{$set} ) ) {
      VDSetLastError("EINVALID");
      return "FAILURE";
   }
   if ( (not defined $tds) || ( ! exists $TDS{$set}{$tds} ) ) {
      VDSetLastError("EINVALID");
      return "FAILURE";
   }

   return (\%{$TDS{$set}{$tds}{'CONNECTION'}});
}


########################################################################
# GetTestCaseInfo -
#       Returns reference to the testcase hash corresponding to the
#       given TDS ID, is in Category.Testcase format, e.g.
#	     TDS::Sample::Sample.TSOTCP
#
# Input:
#       testSet: test set name in format Category::Component::Type::Set
#       tdsID  : name of the test case (name of the hash in *Tds.pm)
#
# Results:
#       Reference to an testcase hash from the TDS hash
#
# Side effects:
#       none
#
########################################################################

sub GetTestCaseInfo
{
   my $self = shift;
   my $testSet = shift;
   my $tdsID = shift;


   if (not defined $testSet) {
      VDSetLastError("EINVALID");
      return "FAILURE";
   }
   #
   # This methods expects tds id with no "TDS::" at the beginning and
   # "Tds" at the end
   #
   $testSet =~ s/Tds$//g;
   $testSet =~ s/^TDS:://g;

   if (! exists $TDS{$testSet}) {
      VDSetLastError("EINVALID");
      return "FAILURE";
   }

   if ( (not defined $tdsID) || ( ! exists $TDS{$testSet}{$tdsID} ) ) {
      VDSetLastError("EINVALID");
      return "FAILURE";
   }
   return $self->{tdsref}{$tdsID};

}


########################################################################
# PrintTDS --
#       prints the current TDS hash on to the stdout
#	TODO: enhance it to print it to a given file
#
# Input:
#       None
#
# Results:
#       Prints the hash on to STDOUT
#
# Side effects:
#       none
#
########################################################################

sub PrintTDS
{
   print Dumper(\%TDS);
}


########################################################################
#
# Setup --
#       Do pre-configuration for TDS. Any TDS should implement this
#       interface to do special configuration;
#
# Input:
#       None
#
# Results:
#       SUCCESS always at this moment;
#
# Side effects:
#       none
#
########################################################################

sub Setup
{
   my $self = shift;
   return SUCCESS;
}


########################################################################
#
# Cleanup --
#       Cleanup configurations made in Setup;
#
# Input:
#       None
#
# Results:
#       SUCCESS always at this moment;
#
# Side effects:
#       none
#
########################################################################

sub Cleanup
{
   my $self = shift;
   return SUCCESS;
}


1;
