#/* **********************************************************
# * Copyright 2009 VMware, Inc.  All rights reserved.
# * -- VMware Confidential
# * **********************************************************/

package perl::foundryqasrc::TestOutput;
use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(TestInfo TestError TestWarning);

use VDNetLib::Common::GlobalConfig qw($vdLogger);

sub TestInfo($) {
   my $str = shift;
   if (defined $vdLogger) {
      $vdLogger->Trace($str);
   } else {
      my $t = localtime( );
      #printf "%s::%s\n", $t, $str;
      return undef;
   }
}

sub TestWarning($) {
   my $str = shift;
   if (defined $vdLogger) {
      $vdLogger->Warn($str);
   } else {
      my $t = localtime( );
      printf "%s::Warning: %s\n", $t, $str;
      return undef;
   }
}

sub TestError($) {
   my $str = shift;
   if (defined $vdLogger) {
      $vdLogger->Error($str);
   } else {
      my $t = localtime( );
      printf "%s::Error: %s\n", $t, $str;
      return undef;
   }
}

1;
