#######################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::Filter::Rule;

#
# This package is responsible for handling all the interaction with
# Rules for TrafficFiltering
#

use strict;
use warnings;
use Data::Dumper;

use VDNetLib::Common::Utilities;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS
                                   VDSetLastError VDGetLastError);

#######################################################################
#
# new --
#      Constructor for Rules class
#
# Input:
#      A named parameter list, in other words a hash with following keys:
#      'filterObj': Object of the switch(vDS)
#      Below are all optional params that can be set while creating rules
#           srcip           : <192.168.2.1>
#           srcport         : <17000>
#           srcmac          : <00:0c:29:c3:6a:b8>
#           srcipnegation   : <yes/no>
#           srcportnegation : <yes/no>
#           srcmacnegation  : <yes/no>
#           dstip           : <192.168.0.3>
#           dstport         : <17000>
#           dstmac          : <00:0c:29:c8:6a:b4>
#           dstipnegation   : <yes/no>
#           dstportnegation : <yes/no>
#           dstmacnegation  : <yes/no>
#           qostag          : <0-7>
#           dscptag         : <0-63>
#           ruleaction      : <Accept/drop/punt>
#           ruledirection   : <incoming/outgoing/both>
#           vlan            : <0-1045>
#
# Results:
#      An object of rule class, if successful
#      FAILURE, in case of any error.
#
# Side effects:
#      None
#
#######################################################################

sub new
{
   my $class = shift;
   my %args  = @_;
   my $filterObj       = $args{filterObj};
   my $rulename        = $args{'name'};
   my $trafficrule     = $args{'trafficrule'};
   my $ruleaction      = $args{action};
   my $srcip           = $args{sourceip};
   my $srcport         = $args{sourceport};
   my $srcmac          = $args{sourcemac};
   my $srcmacmask      = $args{sourcemacmask};
   my $srcipnegation   = $args{sourceipnegation};
   my $srcmacnegation  = $args{sourcemacnegation};
   my $srcportnegation = $args{sourceportnegation};
   my $dstip           = $args{destinationip};
   my $dstport         = $args{destinationport};
   my $dstmac          = $args{destinationmac};
   my $dstmacmask      = $args{dstmacmask};
   my $dstipnegation   = $args{destinationipnegation};
   my $dstmacnegation  = $args{destinationmacnegation};
   my $dstportnegation = $args{destinationportnegation};
   my $costag          = $args{qostag};
   my $dscptag         = $args{dscptag};
   my $ruledirection   = $args{direction};
   my $vlan            = $args{vlan};
   my $protocol        = $args{protocol};
   my $protocoltype        = $args{protocoltype};
   my $slowpathvmip    = $args{slowpathvmip};

   if (not defined($ruleaction)) {
      $vdLogger->Error("Rule action is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $self;
   $self->{filterObj}   = $filterObj;
   $self->{name}        = $rulename;
   $self->{action}      = $ruleaction;
   $self->{trafficrule} = $trafficrule;
   $self->{sourceip}    = $srcip;
   $self->{sourceport}  = $srcport;
   $self->{sourcemac}   = $srcmac;
   $self->{sourcemacmask}      = $srcmacmask;
   $self->{sourceipnegation}   = $srcipnegation;
   $self->{sourcemacnegation}  = $srcmacnegation;
   $self->{sourceportnegation} = $srcportnegation;
   $self->{destinationip}    = $dstip;
   $self->{destinationport}  = $dstport;
   $self->{destinationmac}   = $dstmac;
   $self->{destinationmacmask}      = $dstmacmask;
   $self->{destinationipnegation}   = $dstipnegation;
   $self->{destinationmacnegation}  = $dstmacnegation;
   $self->{destinationportnegation} = $dstportnegation;
   $self->{costag}      = $costag;
   $self->{dscptag}     = $dscptag;
   $self->{vlan}        = $vlan;
   $self->{protocol}    = $protocol;
   $self->{protocoltype} = $protocoltype;
   $self->{direction}   = $ruledirection;
   $self->{slowpathvmip} = $slowpathvmip;
   bless($self, $class);
   return $self;
}

1;
