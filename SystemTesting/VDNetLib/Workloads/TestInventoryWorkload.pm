########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::TestInventoryWorkload;

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                           VDCleanErrorStack);
use VDNetLib::Common::Iterator;
use VDNetLib::Workloads::Utils;


########################################################################
#
# new --
#      Method which returns an object of
#      VDNetLib::Workloads::TestInventoryWorkload class
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (of above mentioned format)
#
# Results:
#      Returns VDNetLib::Workloads::TestInventoryWorkload object, if successful;
#      "FAILURE", in case of error
#
# Side effects:
#      None
#
########################################################################

sub new
{
   my $class = shift;
   my %options = @_;
   my $self;

   if (not defined $options{testbed} || not defined $options{workload}) {
      $vdLogger->Error("Testbed and/or workload not provided");
      VDSetLastError("EINVALID");
      return "FAILURE";
   }

   $self = {
      'testbed'      => $options{testbed},
      'workload'     => $options{workload},
      'targetkey'      => "testinventory",
      'managementkeys' => ['type', 'iterations', 'testinventory',
                          'expectedresult'],
      'componentIndex' => undef
      };

   bless ($self, $class);
   $self->{keysdatabase} = $self->GetKeysTable();

   return $self;
}

sub ResolveIPv4AddrKey
{
   my $self     = shift;
   my $ipv4Addr = shift;
   my $adapter  = shift;
   my $index    = shift;
   my $componentIndexInArray = shift;
   my $component = shift;

   my $macAddr  = $adapter->{'macAddress'};
   my $ip;
   if ($ipv4Addr =~ /x=/) {
      return $self->GenerateIPUsingEquation(
                                    $ipv4Addr,
                                    $adapter,
                                    $index,
                                    $componentIndexInArray,
                                    $component);
   }
}
1;

