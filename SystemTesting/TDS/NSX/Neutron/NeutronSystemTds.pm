#!/usr/bin/perl
########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::NSX::Neutron::NeutronSystemTds;

@ISA = qw(TDS::Main::VDNetMainTds);
#
# This file contains the structured hash for category, Sample tests
# The following lines explain the keys of the internal
# Hash in general.
#

use FindBin;
use lib "$FindBin::Bin/..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

my $neutronTestbedSpec = {
};

#
# Begin test cases
#
{
   %NeutronSystem = (
      'TZStress' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "APIPrecheckIn",
         Version           => "2",
         Tags              => "unit,precheckin",
         Summary           => "This test case verifies behaviour of iterator" .
                              " and constraint database code.",
         ExpectedResult    => "PASS",
         TestbedSpec       => {
            'neutron' => {
               '[1]' => {
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                                ["Stress"],
                            ],
            "Stress" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportzone => {
                  '[1]' =>  {
                     name      => "tz_1",
                     schema    => "/v1/schema/TransportZone",
                     transport_zone_type   => "Gre",
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "tz_1"
                     },
                  },
               },
            },
         },
      },

      'LSStress' => {
         Component         => "Infrastructure",
         Category          => "vdnet",
         TestName          => "APIPrecheckIn",
         Version           => "2",
         Tags              => "unit,precheckin",
         Summary           => "This test case verifies behaviour of iterator" .
                              " and constraint database code.",
         ExpectedResult    => "PASS",
         TestbedSpec       => {
            'neutron' => {
               '[1]' => {
               },
            },
         },
         WORKLOADS => {
            Sequence     => [
                                ["TZSetup"],
                                ["TNSetup"],
                                ["Stress"],
                            ],
            "TZSetup" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportzone => {
                  '[1-2]' =>  {
                     name      => "tz_1",
                     schema    => "/v1/schema/TransportZone",
                     transport_zone_type   => "Gre",
                     metadata => {
                        expectedresultcode => "201",
                        keyundertest => "display_name",
                        expectedvalue => "tz_1"
                     },
                  },
               },
            },
            "TNSetup" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               transportnode => {
                  '[1]' => {
                     name    => "autogenerate",
                     schema  => "TransportNode",
                     admin_status_enabled => "true",
                     zone_end_points => [
                        {
                            "schema"            => "TransportZoneEndpoint",
                            "transport_zone_id" => "neutron.[1].transportzone.[1]",
                            "transport_type"    => {
                                "type"              => "Gre",
                                "internal_port"     => {
                                    "ip_address"            => "10.24.20.216",
                                },
                            },
                        },
                     ],
                     "credential"  =>  {
                            "type"              =>  "SecurityCertificateCredential",
                            "pem_encoded"       => "-----BEGIN CERTIFICATE-----MIIDjTCCAnUCAQYwDQYJKoZIhvcNAQEEBQAwgYkxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJDQTEVMBMGA1UEChMMT3BlbiB2U3dpdGNoMRUwEwYDVQQLEwxjb250cm9sbGVyY2ExPzA9BgNVBAMTNk9WUyBjb250cm9sbGVyY2EgQ0EgQ2VydGlmaWNhdGUgKDIwMTMgSmFuIDE0IDIzOjE2OjExKTAeFw0xMzA4MjMwMDEyNDRaFw0xNDA4MjMwMDEyNDRaMIGOMQswCQYDVQQGEwJVUzELMAkGA1UECBMCQ0ExFTATBgNVBAoTDE9wZW4gdlN3aXRjaDEfMB0GA1UECxMWT3BlbiB2U3dpdGNoIGNlcnRpZmllcjE6MDgGA1UEAxMxb3ZzY2xpZW50IGlkOjEzODRmZmNmLWM5OWQtNDQ0YS04YTZjLTYxMDQ5ZjAyNTQ0NzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKNUQiv5fhdquYzx8g8ODcvrUXlPdcvwgEI+Jr71SpKoZgZhIPN3vLNUCdQxvjRffevxU24vD9+L+GLdyTSPsXYoyEzbf4/VgvEJNnOWwPFYQAhwOQWTroXFoTVRq3peeg2c8Cauy1hornbwpaRDv7JuZvNQVcy3GOwVOp5jHhxUV7GMhhkVO0GUyIBNGf8E8suGuMxP12w8T9YUOnvUn5GMXxG37CN2h2ZWzKgysNQve74KBr83PhaeuCQR4DggIrspNJ05XWVJvq8cE/aEFDQhB6coIWshL+DVI87lkEtYbaEs1cNiJi/ufnk2/cd/0GgpFMqridBZz9YZoWiKTtcCAwEAATANBgkqhkiG9w0BAQQFAAOCAQEAIVrnuwnzQvdz5NIoK5wPWsqAlP90F3zqOax3oTJaPjhOiY6WWnpso4fOJtPONVeTBqqot8mZsNgyLf7Z0Q9z261oeBMO6R35vYpLqA7NmcxQrypKiIUifKp5DXUe9rykiIGVXvsgr0nhnuMwueaO3iGFienVztBA3ZQiwSEHBvZYQSE+v4Q/U8O/GFlG3aI4qIR4Vi5zZJR0cVz1TiHL9dA1Xow447HxE0z0nq/daMekaOloTxK9MTn808nW85kEFqbY3IndkJiWHbW/BnOuw0sUna9siXEIlYZKkWKGzcQrPHPERLmV8lvvJP5uRM9jqndwmtePoR2jmCD5/TzrGA==-----END CERTIFICATE-----",
                     },
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
            "Stress" => {
               Type          => "NSX",
               TestNSX       => "neutron.[1]",
               logicalswitch => {
                  '[1]' =>  {
                     name      => "autogenerate",
                     schema    => "/v1/schema/LogicalSwitch",
                     transport_zone_binding   => [
                        {
#                            "transport_zone_id" => "tz-17358463-27cd-4752-86c4-4fba6da077a8"
                            "transport_zone_id" => "neutron.[1].transportzone.[1]",
                        }
                     ],
                     metadata => {
                        expectedresultcode => "201",
                     },
                  },
               },
            },
         },
      },

   );
}


########################################################################
#
# new --
#       This is the constructor for NeutronTds
#
# Input:
#       none
#
# Results:
#       An instance/object of SampleTds class
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
   my $self = $class->SUPER::new(\%NeutronSystem);
   return (bless($self, $class));
}

1;

