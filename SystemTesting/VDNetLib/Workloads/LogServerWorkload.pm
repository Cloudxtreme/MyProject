package VDNetLib::Workloads::LogServerWorkload;

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
#      VDNetLib::Workloads::LogServerWorkload class
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (of above mentioned format)
#
# Results:
#      Returns VDNetLib::Workloads::LogServerWorkload object, if successful;
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
      'targetkey'      => "testlogserver",
      'managementkeys' => ['type', 'iterations', 'testlogserver',
                          'expectedresult'],
      'componentIndex' => undef
      };

   bless ($self, $class);
   $self->{keysdatabase} = $self->GetKeysTable();

   return $self;
}

1;
