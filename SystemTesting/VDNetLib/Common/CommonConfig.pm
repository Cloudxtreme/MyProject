package VDNetLib::Common::CommonConfig;

use strict;
use warnings;
use Carp;
use Data::Dumper;

use constant WINDOWS_OS => 2;
use constant LINUX_OS => 1;
use constant VM_KERNEL => 0;

my %BIN_PATH = (
 1 => "/automation/bin/",
 2 => "m:\\\\bin\\\\",
);

my %SCRIPTS_PATH = (
 1 => "/automation/scripts/",
 2 => "m:\\\\scripts\\\\",
);

sub new {
   my $class = shift;
   my $self = {};
   $self->{OS} = shift;
   return  bless ($self, $class);
}

sub BinPath {
  my $self = shift;
  my $bin_path = $BIN_PATH{$self->{OS}};
   unless ($bin_path) {
      croak("This system isn't supported: $self->{OS}\n");
   }
   return $bin_path;
}

sub ScriptsPath {
  my $self = shift;
  my $scripts_path = $SCRIPTS_PATH{$self->{OS}};
   unless ($scripts_path) {
      croak("This system isn't supported: $self->{OS}\n");
   }
   return $scripts_path;
}
