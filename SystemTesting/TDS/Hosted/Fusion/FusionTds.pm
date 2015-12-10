#!/usr/bin/perl
########################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::Hosted::Fusion::FusionTds;


use FindBin;
use lib "$FindBin::Bin/..";
use Data::Dumper;
use TDS::Main::VDNetMainTds;

@ISA = qw(TDS::Main::VDNetMainTds);

{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = (ICMPTraffic);
   %Fusion = (
	'ICMPTraffic' => {
         Component         => "Virtual Net Devices",
         Category          => "Hosted Networking",
         TestName          => "ICMPTraffic",
         Summary           => "Run Ping traffic stressing both inbound and " .
                              "outbound path",
         ExpectedResult    => "PASS",
         Parameters        => {
            SUT            => {
               vnic        => ['vmxnet3:1'],
            },
            helper1     => {
               vnic        => ['vmxnet3:1'],
            },
         },

         WORKLOADS => {
            Iterations        => "1",
            Sequence          => [['TRAFFIC_1']],

            "TRAFFIC_1" => {
               Type           => "Traffic",
               ToolName       => "ping",
               NoofInbound    => "3",
               RoutingScheme  => "unicast,broadcast,flood",
               NoofOutbound   => "2",
            },
         },
      },
   );
}
########################################################################
#
# new --
#       This is the constructor for Fusion
#
# Input:
#       none
#
# Results:
#       An instance/object of Fusion class
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
   my $self = $class->SUPER::new(\%Fusion);
   return (bless($self, $class));
}
1;
