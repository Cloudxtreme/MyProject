package perl::foundryqasrc::ManagedBase;
use strict;
use warnings;
no warnings 'redefine';

use perl::foundryqasrc::ManagedUtil;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw();
use VMware::Vix::Simple;
use VMware::Vix::API::Constants;
use perl::foundryqasrc::ConnectAnchor;


#  constructor
sub new() {
   my $class = shift;
   my $self = {
      connectAnchor => shift
   };
   return bless $self, $class;
};

1;