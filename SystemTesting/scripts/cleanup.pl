########################################################################
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
#
# cleanup.pl--
#      This method invokes RemoveOldDirectories from Utilities.pl
#      to remove old directories
# Input:
#      dir: Absolute Path
#
# Results:
#
# Side effects:
#
########################################################################
use strict;
use warnings;
use Data::Dumper;
use FindBin;

use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/";

eval "use PLSTAF";
if ($@) {
   use lib "$FindBin::Bin/../VDNetLib/Common";
   use PLSTAF;
}
use lib "$FindBin::Bin/../VDNetLib/CPAN/5.8.8/";
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw( VDSetLastError VDGetLastError );
use VDNetLib::Common::Utilities;
use Net::OpenSSH;

use VDNetLib::Common::Utilities;
VDNetLib::Common::Utilities::RemoveOldDirectories($ARGV[0]);
