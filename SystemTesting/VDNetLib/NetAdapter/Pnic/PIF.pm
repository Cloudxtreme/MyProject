#!/usr/bin/perl
########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
########################################################################
package VDNetLib::NetAdapter::Pnic::PIF;
my $version = "1.0";

use strict;
use warnings;
use Data::Dumper;
use vars qw /@ISA/;
@ISA = qw(VDNetLib::NetAdapter::Vnic::Vnic);
use vars qw{$AUTOLOAD};
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              LoadInlinePythonModule
                                              Boolean
                                              ConfigureLogger);
use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError
                                   VDGetLastError VDCleanErrorStack );
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::NetAdapter::Vnic::Vnic;


########################################################################
#
# new -
#       This is the constructor module for PIF
#
# Input:
#       IP address of a control adapter (required)
#       Interface (ethx in linux, GUID in windows) (Required)
#
# Results:
#       An instance/object of NetAdapter class
#       "FAILURE", in case of error
#
# Side effects:
#       None
#
########################################################################

sub new
{
   my $class = shift;
   my %options = @_;
   $options{vmOpsObj} = $options{hostObj};
   $options{intType} = "pif";
   $vdLogger->Debug('Starting creation of pif');
   my $self = VDNetLib::NetAdapter::Vnic::Vnic->new(%options);
   if ($self eq FAILURE) {
      $vdLogger->Error("Failed to create VDNetLib::NetAdapter::Vnic::Vnic".
                       " object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   bless ($self, $class);
   $self->SetControlIP($options{controlIP});
   $self->SetInterface($options{interface});
   if (not defined $self->{interface}) {
      $vdLogger->Error("Failed to create VDNetLib::NetAdapter::Pnic::PIF".
                       " object");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug('Done with creation of pif');

   if ($options{noDriver} eq undef) {
      $self->{driver} = $self->GetDriverName();
   } else {
      $vdLogger->Debug('Skipping calling GetDriverName()');
   }

   return $self;
}


sub Getname
{
   my $self = shift;
   return $self->{interface};
}

########################################################################
#
# PersistIfaceConfiguration -
#       Routine to persist network iface related configuration.
#
# Input:
#       Config options as key value pairs.
#
# Results:
#       SUCCESS if the config file is written correctly.
#       FAILURE if any exception is met while writing config file.
#
# Side effects:
#       None
#
########################################################################

sub PersistIfaceConfiguration
{
    my $self = shift;
    my @args = @_;
    if (@args != 1) {
        $vdLogger->Error("Expected only 1 hash ref in the array, got: " .
                         Dumper(@args));
        return FAILURE;
    }
    my $args = $args[0];
    if (defined $args and ref($args) ne "HASH") {
        $vdLogger->Error("Expected iface configuration in hash format, got: " .
                         Dumper($args));
        return FAILURE;
    }
    $args->{DEVICE} = $self->{interface};
    return $self->{hostObj}->persist_iface_config({iface_opts => $args});
}
