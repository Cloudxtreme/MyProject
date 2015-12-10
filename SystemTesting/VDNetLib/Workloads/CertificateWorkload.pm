########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################

###############################################################################
#
# package VDNetLib::Workloads::CertificateWorkload;
# This package is used to run Certificate workload that involves
#  -- Creating and deleting CSR, CRL, CA-Certificate, Self-signed Certificates
#
#
###############################################################################

package VDNetLib::Workloads::CertificateWorkload;

use strict;
use warnings;
use Data::Dumper;

# Inherit the parent class.
use base qw(VDNetLib::Workloads::ParentWorkload);

use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(SUCCESS FAILURE VDSetLastError VDGetLastError
                                   VDCleanErrorStack);
use VDNetLib::Common::Utilities;


########################################################################
#
# new --
#      Method which returns an object of
#      VDNetLib::Workloads::CertificateWorkload
#      class.
#
# Input:
#      A named parameter hash with the following keys:
#      testbed  - reference to testbed object
#      workload - reference to workload hash (supported key/values
#                 mentioned in the package description)
#
# Results:
#      Returns a VDNetLib::Workloads::CertificateWorkload object, if successful;
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
      'targetkey'    => "testcertificate",
      'managementkeys' => ['type', 'iterations','testcertificate','expectedresult','sleepbetweencombos'],
      'componentIndex' => undef
      };

    bless ($self, $class);

   # Adding KEYSDATABASE
   $self->{keysdatabase} = $self->GetKeysTable();

   return $self;
}

1;
