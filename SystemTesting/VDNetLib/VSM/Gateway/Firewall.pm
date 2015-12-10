########################################################################
# Copyright (C) 2015 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::VSM::Gateway::Firewall;

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
       'payload' => 'firewallrules',
       'attribute' => undef,
   },
   'default_policy' => {
       'payload' => 'defaultpolicy',
       'attribute' => undef,
   },
   'logging_enabled' => {
       'payload' => 'loggingenabled',
       'attribute' => undef,
   },
   'global_config' => {
       'payload' => 'globalconfig',
       'attribute' => undef,
   },
   'tcp_pick_ongoing_conn' => {
       'payload' => 'tcppickongoingconnections',
       'attribute' => undef,
   },
   'tcp_allow_outofwindow_packets' => {
       'payload' => 'tcpallowoutofwindowpackets',
       'attribute' => undef,
   },
   'tcp_send_resets_for_closed_servicerouter_ports' => {
       'payload' => 'tcpsendresetforclosedvseports',
       'attribute' => undef,
   },
   'tcp_timeout_close' => {
       'payload' => 'tcptimeoutclose',
       'attribute' => undef,
   },
   'tcp_timeout_established' => {
       'payload' => 'tcptimeoutestablished',
       'attribute' => undef,
   },
   'tcp_timeout_open' => {
       'payload' => 'tcptimeoutopen',
       'attribute' => undef,
   },
   'icmp_timeout' => {
       'payload' => 'icmptimeout',
       'attribute' => undef,
   },
   'icmp6_timeout' => {
       'payload' => 'icmp6timeout',
       'attribute' => undef,
   },
   'drop_invalid_traffic' => {
       'payload' => 'dropinvalidtraffic',
       'attribute' => undef,
   },
   'log_invalid_traffic' => {
       'payload' => 'loginvalidtraffic',
       'attribute' => undef,
   },
   'udp_timeout' => {
       'payload' => 'udptimeout',
       'attribute' => undef,
   },
   'ip_generic_timeout' => {
       'payload' => 'ipgenerictimeout',
       'attribute' => undef,
   },
   'source_exclude' => {
       'payload' => 'exclude',
       'attribute' => undef,
   },
   'dest_exclude' => {
       'payload' => 'exclude',
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
   'vnic_group_id' => {
       'payload' => 'vnicgroupid',
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
};

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::VSM::Gateway::Firewall
#
# Input:
#        None
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::VSM::Gateway::Firewall
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
   my $inlinePyObj = CreateInlinePythonObject('firewall.Firewall',
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
#     Methd to read and process the specifications for creating
#     firewall rules
#
# Input:
#     spec: reference to the spec (user spec/testcase spec)
#
# Results:
#    Modified spec with ManagedObject ID of Grouping Objects used in
#    Firewall rules
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
       my $fwRules = $spec->{firewallrules};
       foreach my $rule (@$fwRules) {
        if(exists $rule->{source}){
            if(exists $rule->{source}->{enabled}) {
                $tempRule[$rIndex]->{source}->{enabled} = $rule->{source}->{enabled};
            }
            if(exists $rule->{source}->{ipaddress}) {
                if(ref $rule->{source}->{ipaddress} eq "ARRAY" || ref $rule->{source}->{ipaddress} eq "HASH") {
                    $tempRule[$rIndex]->{source}->{ipaddress} = ResolveMembersArray($self, $rule->{source}->{ipaddress});
                    $spec->{firewallrules}[$rIndex]->{source}->{ipaddress} = $tempRule[$rIndex]->{source}->{ipaddress};
                }
                else{
                    $tempRule[$rIndex]->{source}->{ipaddress} = $rule->{source}->{ipaddress};
                    $spec->{firewallrules}[$rIndex]->{source}->{ipaddress} = $tempRule[$rIndex]->{source}->{ipaddress};
                }
            }

            if(exists $rule->{source}->{groupingobjectid}) {
                $tempRule[$rIndex]->{source}->{groupingobjectid} = ResolveMembersArray($self, $rule->{source}->{groupingobjectid});
                $spec->{firewallrules}[$rIndex]->{source}->{groupingobjectid} = $tempRule[$rIndex]->{source}->{groupingobjectid};
            }
        }
        if(exists $rule->{destination}) {
            if(exists $rule->{destination}->{enabled}) {
                $tempRule[$rIndex]->{destination}->{enabled} = $rule->{destination}->{enabled};
            }
            if(exists $rule->{destination}->{ipaddress}) {
                if(ref $rule->{destination}->{ipaddress} eq "ARRAY" || ref $rule->{destination}->{ipaddress} eq "HASH") {
                    $tempRule[$rIndex]->{destination}->{ipaddress} = ResolveMembersArray($self, $rule->{destination}->{ipaddress});
                    $spec->{firewallrules}[$rIndex]->{destination}->{ipaddress} = $tempRule[$rIndex]->{destination}->{ipaddress};
                }
                else{
                    $tempRule[$rIndex]->{destination}->{ipaddress} = $rule->{destination}->{ipaddress};
                    $spec->{firewallrules}[$rIndex]->{destination}->{ipaddress} = $tempRule[$rIndex]->{destination}->{ipaddress};
                }
            }
            if(exists $rule->{destination}->{groupingobjectid}) {
                $tempRule[$rIndex]->{destination}->{groupingobjectid} = ResolveMembersArray($self, $rule->{destination}->{groupingobjectid});
                $spec->{firewallrules}[$rIndex]->{destination}->{groupingobjectid} = $tempRule[$rIndex]->{destination}->{groupingobjectid};
            }
        }
        if(exists $rule->{application}) {
            if(exists $rule->{application}->{applicationid}) {
                $tempRule[$rIndex]->{application}->{applicationid} = ResolveMembersArray($self, $rule->{application}->{applicationid});
                $spec->{firewallrules}[$rIndex]->{application}->{applicationid} = $tempRule[$rIndex]->{application}->{applicationid};
            }
        }
            $rIndex++;
       }

       push (@newarrayOfSpec, $spec);
       $index++;
   }
   shift @newarrayOfSpec;

   $vdLogger->Info ("FirewallArrayOfSpec".Dumper(\@newarrayOfSpec));

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
          case /(application|securitygroup|servicegroup|service|virtualwire|macset|ipset)/i {
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

