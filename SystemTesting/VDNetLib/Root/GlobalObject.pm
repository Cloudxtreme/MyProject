package VDNetLib::Root::GlobalObject;

use strict;
use VDNetLib::InlinePython::VDNetInterface qw(Boolean
                                              ConfigureLogger);
use VDNetLib::Common::GlobalConfig qw($vdLogger);


########################################################################
#
# GetIsGlobal --
#     Method returns true if object can be replicated accross a cluster
#
# Input:
#     None
#
# Results:
#     boolean
#
# Side effects:
#     None
#
########################################################################

sub GetIsGlobal
{
   my $self = shift;
   return VDNetLib::Common::GlobalConfig::TRUE;
}

1;
