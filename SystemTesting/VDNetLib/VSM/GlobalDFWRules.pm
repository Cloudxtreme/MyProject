########################################################################
# Copyright (C) 2015 VMware, Inc.
# All Rights Reserved
########################################################################

package VDNetLib::VSM::GlobalDFWRules;
#
# This package allows creation of empty sections in
#
use base qw(VDNetLib::InlinePython::AbstractInlinePythonClass VDNetLib::Root::GlobalObject);

use strict;
use Switch;
use vars qw{$AUTOLOAD};
use Data::Dumper;
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              LoadInlinePythonModule
                                              Boolean
                                              ConfigureLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use Inline::Python qw(eval_python
                     py_bind_class
                     py_eval
                     py_study_package
                     py_call_function
                     py_call_method
                     py_is_tuple);

# Database of attribute mappings

use constant attributemapping => {};

########################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#
# Input:
#      vsm : vsm ip(Required)
#
# Results:
#      An object of VDNetLib::VSM::GlobalDFWRules
#
# Side effects:
#      None
#
########################################################################

sub new
{
   my $class = shift;
   my %args  = @_;
   my $self;
   $self->{id} = $args{id};
   $self->{vsm} = $args{vsm};
   bless $self, $class;

   # Adding AttributeMapping
   $self->{attributemapping} = $self->GetAttributeMapping();

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
   my $inlinePyVSMObj = $self->{vsm}->GetInlinePyObject(endpoint_version => "4.0");
   my $inlinePyObj = CreateInlinePythonObject('dfw_rule.DFWRule',
                                               $inlinePyVSMObj,
                                               'universal',
                                             );
   if (!$inlinePyObj) {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   $inlinePyObj->{id} = $self->{id};
   return $inlinePyObj;
}


########################################################################
#
# ProcessSpec --
#     Method to process the given array of rule spec and convert them
#     to a single hash form required Inline Python API
#     for bulk config. Overrides the method in AbstractInlinePythonClass
#
# Input:
#     Reference to an array of hash:
#
#        '[1]' => {
#              layer => "layer3",
#              name    => 'Allow_Traffic_OnlyBetween_VM1_VM2',
#              action  => 'allow',
#              sources => [
#                            {
#                               type  => 'VirtualMachine',
#                               value	=> "vm.[1]",
#                            },
#                         ],
#              destinations => [
#                                 {
#                                    type  => 'VirtualMachine',
#                                    value	=> "vm.[2]",
#                                 },
#                              ],
#              affected_service => [
#                                     {
#                                        protocolname => 'ICMP',
#                                     },
#                                  ],
#        },
#
# Results:
#     Reference to an array of hash (processed hash);
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ProcessSpec
{
   my $self = shift;
   my $arrayOfSpec = shift;

   my @processedArrayOfSpec;
   my $index = 0;

   foreach my $spec (@$arrayOfSpec) {

      # Skip all if hash is empty
      last if(!keys %{$spec});

      # Else start processing
      my $tempRule = {};
      $tempRule->{index} = $index++;
      if(exists $spec->{sources}) {
         $tempRule->{sources}->{source} = ResolveMembersArray($self, $spec->{sources});
         $tempRule->{sources}->{_tag_excluded} = "false";
         if(exists $spec->{sourcenegate}) {
             $tempRule->{sources}->{_tag_excluded} = $spec->{sourcenegate};
          }
      }
      if(exists $spec->{destinations}) {
         $tempRule->{destinations}->{destination} = ResolveMembersArray($self, $spec->{destinations});
         $tempRule->{destinations}->{_tag_excluded} = "false";
         if(exists $spec->{destinationnegate}) {
            $tempRule->{destinations}->{_tag_excluded} = $spec->{destinationnegate};
         }
      }

      if(exists $spec->{appliedto}) {
         $tempRule->{appliedtolist}->{appliedto} = ResolveMembersArray($self, $spec->{appliedto});
      }

      if(exists $spec->{siprofile}) {
         $tempRule->{siprofile}->{objectid} = $spec->{siprofile}->{objectid}{id};
         $tempRule->{siprofile}->{name} = $spec->{siprofile}->{name};  # Temporary Fix to accomodate bug #1288673
      }

      if(exists $spec->{affected_service}) {
         $tempRule->{services}->{service} = ResolveMembersArray($self, $spec->{affected_service});
      }

      $tempRule->{sectionid} = "default";
      if(exists $spec->{section} and $spec->{section} !~ /default/i) {
         $tempRule->{sectionid} = $spec->{section}{id};
         if($tempRule->{sectionid} =~ /l3redirect_/i) {
            $spec->{layer} = "layer3redirect";
         }
         elsif($tempRule->{sectionid} =~ /l3_/i) {
            $spec->{layer} = "layer3";
         }
         elsif($tempRule->{sectionid} =~ /l2_/i) {
            $spec->{layer} = "layer2";
         }
      }

      if($tempRule->{sectionid} =~ /default/i
         and $spec->{layer} !~ /layer(2|3)/i) {
         $vdLogger->Error("Layer information not given ",
                           "or incorrect for default rule");
         VDSetLastError("EFAILED");
         return FAILURE;
      }

      $tempRule->{action} = "allow";
      if(exists $spec->{action}) {
          $tempRule->{action} = $spec->{action};
      }

      $tempRule->{name} = "Rule$$";
      if(exists $spec->{name}) {
          $tempRule->{name} = $spec->{name};
      }

      $tempRule->{_tag_disabled} = "false";
      if(exists $spec->{disabled}) {
          $tempRule->{_tag_disabled} = $spec->{disabled};
      }

      $tempRule->{_tag_logged} = "false";
      if(exists $spec->{logging_enabled}) {
          $tempRule->{_tag_logged} = $spec->{logging_enabled};
      }

      push(@processedArrayOfSpec, $tempRule);
   }

   $vdLogger->Info ("Processed arrayOfSpec".Dumper(\@processedArrayOfSpec));

   return \@processedArrayOfSpec;
}


########################################################################
#
# ResolveMembersArray --
#     Method to process the given array of rule spec
#     and convert them to a single hash form required Inline Python API
#     for bulk config
#
# Input:
#     Reference to an array of hash  in the form:
#     {
#        type  => 'VirtualMachine',
#        value  => "vm.[1]",
#     }
#
# Results:
#     Reference to an array of hash (processed hash);
#     FAILURE, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub ResolveMembersArray
{
   my $self = shift;
   my $memberArray = shift;

   foreach my $member (@$memberArray) {
      my $moid = FAILURE;

      if(exists $member->{protocolname} || exists $member->{protocol}) {
          next;
      }

      switch ( $member->{type} ) {
          case /virtualmachine/i {
             $moid = $member->{value}->GetVMMoID;
          }
          case /vnic/i {
             $moid = $member->{value}->GetUUID;
             $moid =~ s/(-)(\d)$/\.00\2/;
          }
          case /distributedvirtualportgroup/i {
             $moid = $member->{value}->GetMORId;
          }
          case /clustercomputeresource/i {
             $moid = $member->{value}->GetClusterMORId;
          }
          case /datacenter/i {
             $moid = $member->{value}->GetMORId;
          }
          case /ipv4address/i {
             if(ref(\$member->{value} eq 'SCALAR')) {
                $moid = $member->{value};
             } else {
                $moid = $member->{value}->GetIPv4;
             }
          }
          case /ipv6address/i {
             if(ref(\$member->{value} eq 'SCALAR')) {
                $moid = $member->{value};
             } else {
                $moid = $member->{value}->GetIPv6Local;
             }
          }
          case /(application|securitygroup|virtualwire|macset|ipset)/i {
             $moid = $member->{value}->{id};
          }
      }

      if($moid eq FAILURE) {
          $vdLogger->Error("Failed to resolve member ID for type $member->{type}");
          VDSetLastError("EFAILED");
          return FAILURE;
      }

      $member->{value} = $moid;
   }
   return $memberArray;
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
#     vsm
#
########################################################################

sub GetObjectParentAttributeName
{
   return "vsm";
}

1;
