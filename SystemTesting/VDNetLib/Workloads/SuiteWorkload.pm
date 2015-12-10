########################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Workloads::SuiteWorkload;

#
# This package/module is used to run workload that involves configuring
# a virtual network adapter. The configuration details are given in the
# workload hash and all the configurations are done sequentially by this
# package.
#

use strict;
use warnings;
use Data::Dumper;

use base qw(VDNetLib::Workloads::ParentWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                                   VDCleanErrorStack);
use VDNetLib::Common::Iterator;
use VDNetLib::Common::Utilities;
use VDNetLib::Common::LocalAgent qw( ExecuteRemoteMethod );
use VDNetLib::Workloads::Utils;
use VDNetLib::Suites::TAHI;
use File::Basename;



########################################################################
#
# new --
#      Method which returns an object of
#      VDNetLib::Workloads::SuiteWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (of above mentioned format)
#
# Results:
#      Returns a VDNetLib::Workloads::SuiteWorkload object,
#      if successful;
#      "FAILURE", in case of error
#
# Side effects:
#      None
#
########################################################################

sub new {
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
       'targetkey'    => "testadapter",
       'managementkeys' => ['type', 'iterations', 'timeout',
                            'verification', 'onevent', 'onstate',
                            'expectedresult', 'sleepbetweencombos'],
       'componentIndex' => undef
    };
    bless ($self, $class);

    # Adding KEYSDATABASE
    $self->{keysdatabase} = $self->GetKeysTable();

    return $self;
}

1;
