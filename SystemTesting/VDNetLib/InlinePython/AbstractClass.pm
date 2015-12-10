########################################################################
# Copyright (C) 2013 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::InlinePython::AbstractClass;

#
# This package is the base class for all VDNetLib::InlinePython::*
# class
#
# Every class that inherits this class must have the following method
#    GetInlinePyObject() : should return reference to inline Python object
#                          which is like an alias to the child Perl class.
#
# All the method calls in the child classes will by default be routed
# to inlinePyObj using the AUTOLOAD functionality.
#
use strict;
use warnings;
use vars qw{$AUTOLOAD};


########################################################################
#
# AUTOLOAD --
#     Implements Perl's standard AUTOLOAD method for this class
#
# Input:
#     Perl's default
#
# Results:
#     Refer to the return value of the actual method in Python layer
#
# Side effects:
#     None
#
########################################################################

sub AUTOLOAD {
   my ($self) = @_;

   return if $AUTOLOAD =~ /::DESTROY$/;
   my $method = $1 if ($AUTOLOAD =~ /.*::(\w+)/);
   # TODO: decide the return values or exceptions from Python layer
   # for which "FAILURE" should be returned from here. This is to
   # make all Inline Python return calls consistent in case of failure
   # situations.
   my $inlinePyObj =  $self->GetInlinePyObject();
   return $inlinePyObj->$method();
}
1;
