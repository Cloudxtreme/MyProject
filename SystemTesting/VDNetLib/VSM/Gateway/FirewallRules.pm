
########################################################################
# Copyright (C) 2015 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::Gateway::FirewallRules;

use base 'VDNetLib::InlinePython::AbstractInlinePythonClass';
use strict;
use vars qw{$AUTOLOAD};
use Data::Dumper;
use Switch;
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

my $endpoint_version="";

use constant attributemapping => {
   'rules' => {
       'payload' => 'firewallrule',
       'attribute' => undef,
   },
   'sources' => {
       'payload' => 'groupingobjectid',
       'attribute' => undef,
   },
   'destinations' => {
       'payload' => 'groupingobjectid',
       'attribute' => undef,
   },
   'affected_service' => {
       'payload' => 'service',
       'attribute' => undef,
   },
   'destinationport' => {
       'payload' => 'port',
       'attribute' => undef,
   },
   'protocolname' => {
       'payload' => 'protocol',
       'attribute' => undef,
   },
   'application_id'=> {
       'payload' => 'applicationid',
       'attribute' => undef,
   },
   'vnic_group_id' => {
       'payload' => 'vnicgroupid',
       'attribute' => undef,
   },
   'ipv4address' => {
       'payload' => 'ipaddress',
       'attribute' => undef,
   },
   'ip4add' => {
       'payload' => 'ipaddress',
       'attribute' => undef,
   },
   'ip6add' => {
       'payload' => 'ipaddress',
       'attribute' => undef,
   },
   'logging_enabled' => {
       'payload' => 'loggingenabled',
       'attribute' => undef,
   },
};

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::VSM::Gateway::FirewallRules
#
# Input:
#        None
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::VSM::Gateway::FirewallRules
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
   $self->{gateway} = $args{gateway};
   bless $self, $class;
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
   my $inlinePyEdgeObj = $self->{gateway}->GetInlinePyObject();
   my $inlinePyObj = CreateInlinePythonObject('firewall_rules.FirewallRules',
                                               $inlinePyEdgeObj,
                                               $endpoint_version,
                                             );
   $inlinePyObj->{id} = $self->{id};
   if (!$inlinePyObj) {
      $vdLogger->Error("Failed to create inline object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   return $inlinePyObj;
}


########################################################################
#
# ProcessSpec --
#     Methd to read and process the specifications for appending
#     firewall rules
#
# Input:
#     spec: reference to the spec (user spec/testcase spec)
#
# Results:
#    Modified spec to parameters of payload and api version of
#    REST call for appending Firewall Rules
#
# Side effects:
#     None
#
########################################################################

sub ProcessSpec
{
   my $self = shift;
   my $arrayOfSpec = shift;

   my @newarrayOfSpec = {};
   my $index = 0;

   my $mappingDuplicate = shift;

   if (!%$mappingDuplicate) {
      return $arrayOfSpec;
   }

   foreach my $spec (@$arrayOfSpec) {
      if (FAILURE eq $self->RecurseResolveTuple($spec, $mappingDuplicate)) {
         $vdLogger->Error("Error encountered while resolving tuples");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      };

       last if(!keys %{$spec});

       if($spec->{endpoint_version} != ""){
           $endpoint_version = $spec->{endpoint_version};
       }

       my @tempRule = ();
       my $rIndex=0;
       my $fwRules = $spec->{firewallrule};
       foreach my $rule ($fwRules) {
        if(exists $rule->{source}){
            if(exists $rule->{source}->{enabled}) {
                $tempRule[$rIndex]->{source}->{enabled} = $rule->{source}->{enabled};
            }
            if(exists $rule->{source}->{ipaddress}) {
                if(ref $rule->{source}->{ipaddress} eq "ARRAY" || ref $rule->{source}->{ipaddress} eq "HASH") {
                    $tempRule[$rIndex]->{source}->{ipaddress} = ResolveMembersArray($self, $rule->{source}->{ipaddress});
                    $spec->{firewallrule}->{source}->{ipaddress} = $tempRule[$rIndex]->{source}->{ipaddress};
                }
                else{
                    $tempRule[$rIndex]->{source}->{ipaddress} = $rule->{source}->{ipaddress};
                    $spec->{firewallrule}->{source}->{ipaddress} = $tempRule[$rIndex]->{source}->{ipaddress};
                }
            }
            if(exists $rule->{source}->{groupingobjectid}) {
                $tempRule[$rIndex]->{source}->{groupingobjectid} = ResolveMembersArray($self, $rule->{source}->{groupingobjectid});
                $spec->{firewallrule}->{source}->{groupingobjectid} = $tempRule[$rIndex]->{source}->{groupingobjectid};
            }
        }
        if(exists $rule->{destination}) {
            if(exists $rule->{destination}->{enabled}) {
                $tempRule[$rIndex]->{destination}->{enabled} = $rule->{destination}->{enabled};
            }
            if(exists $rule->{destination}->{ipaddress}) {
                if(ref $rule->{destination}->{ipaddress} eq "ARRAY" || ref $rule->{destination}->{ipaddress} eq "HASH") {
                    $tempRule[$rIndex]->{destination}->{ipaddress} = ResolveMembersArray($self, $rule->{destination}->{ipaddress});
                    $spec->{firewallrule}->{destination}->{ipaddress} = $tempRule[$rIndex]->{destination}->{ipaddress};
                }
                else{
                    $tempRule[$rIndex]->{destination}->{ipaddress} = $rule->{destination}->{ipaddress};
                    $spec->{firewallrule}->{destination}->{ipaddress} = $tempRule[$rIndex]->{destination}->{ipaddress};
                }
            }
            if(exists $rule->{destination}->{groupingobjectid}) {
                $tempRule[$rIndex]->{destination}->{groupingobjectid} = ResolveMembersArray($self, $rule->{destination}->{groupingobjectid});
                $spec->{firewallrule}->{destination}->{groupingobjectid} = $tempRule[$rIndex]->{destination}->{groupingobjectid};
            }
        }
        if(exists $rule->{application}) {
            if(exists $rule->{application}->{applicationid}) {
                $tempRule[$rIndex]->{application}->{applicationid} = ResolveMembersArray($self, $rule->{application}->{applicationid});
                $spec->{firewallrule}->{application}->{applicationid} = $tempRule[$rIndex]->{application}->{applicationid};
            }
        }
            $rIndex++;
       }

       push (@newarrayOfSpec, $spec);
       $index++;
   }
   shift @newarrayOfSpec;

   $vdLogger->Info ("FirewallRulesArrayOfSpec".Dumper(\@newarrayOfSpec));

   return \@newarrayOfSpec;
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
   my @tmpArray;

   foreach my $member (@$memberArray) {
      my $moid = FAILURE;

      switch ( $member->{type} ) {
          case /datacenter/i {
             $moid = $member->{value}->GetMORId;
          }
          case /cluster/i {
             $moid = $member->{value}->GetClusterMORId;
          }
          case /distributedvirtualportgroup/i {
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
               $moid = $member->{value}->GetIPv6Global->[0];
               if($moid eq FAILURE) {
                   $vdLogger->Error("No global ipv6 found. Adding \"any\" as address.");
               }
             }
          }
          case /virtualmachine/i {
             $moid = $member->{value}->GetVMMoID;
          }
          case /(application|securitygroup|servicegroup|service|virtualwire|macset|ipset|logicalswitch)/i {
             $moid = $member->{value}->{id};
          }

      }

      if($moid eq FAILURE) {
          $vdLogger->Error("Failed to resolve member ID for type $member->{type}");
          VDSetLastError("EFAILED");
          return FAILURE;
      }

      $member->{value} = $moid;
      push (@tmpArray, $member->{value});
   }
   return \@tmpArray;
}


1;

