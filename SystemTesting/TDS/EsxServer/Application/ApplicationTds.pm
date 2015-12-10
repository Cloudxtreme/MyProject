#!/usr/bin/perl
########################################################################
#
#  The file includes the automation of Application TDS
#
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
package TDS::EsxServer::Application::ApplicationTds;

use FindBin;
use lib "$FindBin::Bin/../..";
use TDS::Main::VDNetMainTds;
use Data::Dumper;

@ISA = qw(TDS::Main::VDNetMainTds);
{
   # List of tests in this test category, refer the excel sheet TDS
   @TESTS = ("SNA");

   %Application = (
      'SNA' => {
        'Component' => 'network tools',
        'Category' => 'ESX Server',
        'TestName' => 'ESX::Network.Applications::Functional::SNA',
        'Summary' => 'Test SNA frame on ESX',
        'ExpectedResult' => 'PASS',
        'AutomationStatus'  => 'Automated',
        'Tags' => 'CAT_P0',
        'Version' => '2',
        'TestbedSpec' => {
          'vm' => {
            '[2]' => {
              'vnic' => {
                '[1]' => {
                  'portgroup' => 'host.[2].portgroup.[1]',
                  'driver' => 'e1000'
                }
              },
              'host' => 'host.[2].x.[x]'
            },
            '[1]' => {
              'vnic' => {
                '[1]' => {
                  'portgroup' => 'host.[1].portgroup.[1]',
                  'driver' => 'e1000'
                }
              },
              'host' => 'host.[1].x.[x]'
            }
          },
          'host' => {
            '[1]' => {
              'portgroup' => {
                '[1]' => {
                  'vss' => 'host.[1].vss.[1]'
                }
              },
              'vss' => {
                '[1]' => {
                  'configureuplinks' => 'add',
                  'vmnicadapter' => 'host.[1].vmnic.[1]'
                }
              },
              'vmnic' => {
                '[1]' => {
                  'driver' => 'any'
                }
              }
            },
            '[2]' => {
              'portgroup' => {
                '[1]' => {
                  'vss' => 'host.[2].vss.[1]'
                }
              },
              'vss' => {
                '[1]' => {
                  'configureuplinks' => 'add',
                  'vmnicadapter' => 'host.[2].vmnic.[1]'
                }
              },
              'vmnic' => {
                '[1]' => {
                  'driver' => 'any'
                }
              }
            }
          }
        },
        'WORKLOADS' => {
          'Sequence' => [
            [
              'SNATest'
            ]
          ],
          'Duration' => 'time in seconds',
          'Iterations' => '1',
          'SNATest' => {
            'Type' => 'Traffic',
            'toolname' => 'tcpreplay',
            'noofinbound' => '1',
            'packetfile' => '/automation/bin/x86_32/linux/tcpreplay/test.pcap',
            'packettype' => 'SNA',
            'testadapter' => 'vm.[1].vnic.[1]',
            'supportadapter' => 'vm.[2].vnic.[1]'
          }
        }
      },
   );
} # End of ISA.


#######################################################################
#
# new --
#       This is the constructor for Application.
#
# Input:
#       None.
#
# Results:
#       An instance/object of Application class.
#
# Side effects:
#       None.
#
########################################################################

sub new
{
   my ($proto) = @_;
   # Below way of getting class name is to allow new class as well as
   # $class->new.  In new class, proto itself is class, and $class->new,
   # ref($class) return the class
   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%Application);
   return (bless($self, $class));
}

1;
