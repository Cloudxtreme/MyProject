package perl::foundryqasrc::ConnectAnchor;
use strict;
use warnings;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(new Connnect Disconnect);
use VMware::Vix::Simple;
use VMware::Vix::API::Constants;
use perl::foundryqasrc::TestOutput;

#  constructor
sub new() {
   my $class = shift;
   my $self = {
      apiVersion => shift,
      hostType => shift,
      hostName => shift,
      port => shift,
      hostHandle => VIX_INVALID_HANDLE
   };
   return bless $self, $class;
};

sub Connect($$$$) {
   TestInfo "Starting ConnectAnchor::Connect()...";

   my $self = shift;
   my $err = VIX_OK;
   my $passed = 0;
   ($err, $self->{hostHandle}) = HostConnect($self->{apiVersion}, $self->{hostType},
                                             $self->{hostName}, $self->{port},
                                             shift, shift,
                                             shift, VIX_INVALID_HANDLE);

   TestInfo "Waiting for Host_Connect...";

   if ((VIX_OK == $err) && (VIX_INVALID_HANDLE != $self->{hostHandle})) {
      TestInfo "Succesfully connected to host";
      $passed = 1;
   }
   else {
      if (VIX_OK != $err) {
         TestWarning "Host_Connect returns err ".$err;
      }

      if (VIX_INVALID_HANDLE == $self->{hostHandle}) {
         TestWarning "Invalid host handle returned from ConnectAnchor::Connect()";
      }

      ReleaseHandle($self->{hostHandle});
   }

   return $passed, $self->{hostHandle};
};

sub Disconnect() {
   my $self = shift;
   TestInfo "Starting ConnectAnchor::Disconnect()...";
   HostDisconnect($self->{hostHandle});
   TestInfo "Host successfully disconnected";
   return 1;
}
1;