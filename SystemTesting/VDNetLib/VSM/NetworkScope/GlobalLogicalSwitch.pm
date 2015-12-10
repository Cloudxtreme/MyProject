package VDNetLib::VSM::NetworkScope::GlobalLogicalSwitch;

use base qw(VDNetLib::VSM::NetworkScope::VirtualWire VDNetLib::Root::GlobalObject);

use strict;
use vars qw{$AUTOLOAD};
use Data::Dumper;
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              LoadInlinePythonModule
                                              Boolean
                                              ConfigureLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);

use VDNetLib::InlineJava::Portgroup::VirtualWire;

use constant attributemapping => {};

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::VSM::NetworkScope::GlobalLogicalSwitch
#
# Input:
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::VSM::NetworkScope::GlobalLogicalSwitch
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class = shift;
   my %args  = @_;
   my $self;
   $self->{id} = $args{id};
   $self->{globaltransportzone} = $args{globaltransportzone};
   $self->{type} = "vsm";
   bless $self, $class;
   return $self;
}


########################################################################
#
# GetInlinePyObject --
#     Methd to get Python equivalent object of this class
#
# Input:
#     None
#
# Results:
#     Reference to Inline Python object of this class
#
# Side effects:
#     None
#
########################################################################

sub GetInlinePyObject
{
   my $self = shift;
   my $inlinePyNWScopeObj = $self->{globaltransportzone}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('virtual_wire.VirtualWire',
                                              $inlinePyNWScopeObj,
                                              "global"
                                             );
   if (!$inlinePyObj) {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   if (defined $self->{id}) {
      $inlinePyObj->{id} = $self->{id};
   }
   return $inlinePyObj;
}


#######################################################################
#
# GetObjectParentAttributeName--
#     Returns the Attribute this class is using to store its parent
#
# Input:
#     None
#
# Results:
#     SUCCESS
#
########################################################################

sub GetObjectParentAttributeName
{
   return "globaltransportzone";
}

1;
