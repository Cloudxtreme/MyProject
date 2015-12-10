#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::Upgrade::ESXTds;

#
# This file contains the structured hash for ESX Upgarde category,
# Sample tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);

{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = ( );

   %ESX = (
       'Upgrade' => {
         Category         => 'ESX',
         Component        => 'Upgrade',
         Product          => 'ESX',
         QCPath           => 'ESX/ESX/Upgrade',
         TestName         => 'Upgrade',
         Summary          => 'To Upgrade ESX server ' ,
         ExpectedResult   => 'PASS',
         Tags             => 'sanity',
         PMT              => '',
         Procedure        => 'Upgrade ESX using ESXCli commands',
         Status           => '',
         AutomationLevel  => 'Manual',
         FullyAutomatable => 'Y',
         Duration         => '',
         TestcaseLevel    => 'Functional',
         TestcaseType     => 'Functional',
         Priority         => 'P0',
         Developer        => 'lkutik',
         Testbed          => '',
         Version          => '2',
         TestbedSpec   => {
          host  => {
               '[1]'   => {
               },
          },
        },

        WORKLOADS => {
           Sequence => [
                        ['UpgradeESX'],
                        ],

           UpgradeESX => {
                 Type => "Host",
                 TestHost =>  "host.[1]",
                 Profile => "Update",
                 Build   => "1395035",
                 SignatureCheck => 0,
            },
         },
       },


   );
}


########################################################################
#
# new --
#       This is the constructor for ESXTds
#
# Input:
#       none
#
# Results:
#       An instance/object of ESXTds class
#
# Side effects:
#       None
#
########################################################################

sub new
{
   my ($proto) = @_;
   # Below way of getting class name is to allow new class as well as
   # $class->new.  In new class, proto itself is class, and $class->new,
   # ref($class) return the class
   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%ESX);
   return (bless($self, $class));
}
1;
