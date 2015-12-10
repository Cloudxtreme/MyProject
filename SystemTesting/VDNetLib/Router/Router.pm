########################################################################
# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::Router::Router;

#
# This package has methods which will be common across
# all *Router*.pm modules
#

use strict;
use warnings;
use Data::Dumper;

# Load modules
use FindBin;
use lib "$FindBin::Bin/../../";
use lib "$FindBin::Bin/../../VDNetLib/CPAN/5.8.8/";


use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDLog;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                           VDCleanErrorStack );
use VDNetLib::Common::STAFHelper;


########################################################################
#
# new -
#       This is the constructor module for Router class
#       Parent does one check, if the router name is defined.
#
# Input:
#       A named parameter (hash) with following mandatory keys:
#       name - name of the router
#
# Results:
#       An instance/object of VDR class
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub new
{
   my $class = shift;
   my %args = @_;

   if (not defined $args{name}) {
      $vdLogger->Error("Cannot create a Router obj without name. args:" .
                        Dumper(%args));
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $self;
   $self = {
      'name'   => $args{name},
   };

   #
   # create stafHelper if it is not defined.
   #
   $self->{stafHelper} = $args{stafHelper};
   if (not defined $self->{stafHelper}) {
      $vdLogger->Error("stafHelper missing in new() of Router.pm");
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return bless ($self, $class);
}

1;
