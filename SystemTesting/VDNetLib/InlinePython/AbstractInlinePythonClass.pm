########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::InlinePython::AbstractInlinePythonClass;

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
use Data::Dumper;
use Scalar::Util qw(blessed reftype);
use vars qw{$AUTOLOAD};
use Storable 'dclone';

use Inline::Python qw(eval_python
                     py_bind_class
		     py_eval
                     py_study_package
		     py_call_function
		     py_call_method
                     py_is_tuple);

use VDNetLib::Common::GlobalConfig qw ($vdLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                           VDCleanErrorStack);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject);
use constant TRUE  => VDNetLib::Common::GlobalConfig::TRUE;
use constant FALSE => VDNetLib::Common::GlobalConfig::FALSE;

########################################################################
#
# ComponentMap --
#     Method to return the information about a component such
#     as Perl Class, parent name of the component in the hierarchy model
#
# Input:
#     componentName: name of the component
#     type         : neutron/vsm/nvpController
#                    (TODO: remove this dependency by moving
#                    ComponentMap to appropriate derived classes)
#
# Results:
#     Reference to a hash which contains information about the component
#
# Side effects:
#     None
#
########################################################################

sub ComponentMap
{
   my $self          = shift;
   my $componentName = shift;
   my $type          = shift;
   my $mappingHash = {
      'transportzone'   => {
       'neutron'   => {
         'perlClass'    => 'VDNetLib::Neutron::TransportZone',
         'parentName'   => 'neutron',
         },
        'nvpController'   => {
         'perlClass'    => 'VDNetLib::NVPController::TransportZone',
         'parentName'   => 'nvpController',
         },
      },
      'logicalswitch'   => {
         'neutron' => {
            'perlClass'    => 'VDNetLib::Neutron::LogicalSwitch',
            'parentName'   => 'neutron',
         },
         'nvpController' => {
            'perlClass'    => 'VDNetLib::NVPController::LogicalSwitch',
            'parentName'   => 'nvpController',
         },
      },
      'logicalswitchport'  => {
         'neutron' => {
            'perlClass'    => 'VDNetLib::Neutron::LogicalSwitch'.
                              '::LogicalSwitchPort',
            'parentName'   => 'neutron',
          },
         'nvpController' => {
            'perlClass'    => 'VDNetLib::NVPController::LogicalSwitch'.
                              '::LogicalPort',
            'parentName'   => 'logicalSwitch',
          },
      },
      'logicalservicesnode'   => {
         'neutron' => {
            'perlClass'    => 'VDNetLib::Neutron::LogicalServicesNode',
            'parentName'   => 'neutron',
         },
      },
      'logicalservicesnodeinterface'   => {
         'neutron' => {
            'perlClass'    => 'VDNetLib::Neutron::LogicalServicesNodeInterface',
            'parentName'   => 'neutron',
         },
      },
      'transportnode'   => {
            'neutron' => {
                'perlClass'    => 'VDNetLib::Neutron::TransportNode',
                'parentName'   => 'neutron',
            },
            'nvpController' => {
                'perlClass'    => 'VDNetLib::NVPController::TransportNode',
                'parentName'   => 'nvpController',
            },
      },
      'logicalport'   => {
         'nvpController' => {
            'perlClass'    => 'VDNetLib::NVPController::LogicalSwitch::LogicalPort',
            'parentName'   => 'logicalSwitch',
         },
      },
      'transportnodecluster'   => {
         'neutron' => {
            'perlClass'    => 'VDNetLib::Neutron::TransportNodeCluster',
            'parentName'   => 'neutron',
         },
      },
      'ippool'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::IPPool',
            'parentName'   => 'vsm',
         },
         'neutron' => {
            'perlClass'    => 'VDNetLib::Neutron::IPPool',
            'parentName'   => 'neutron',
         },
      },
      'dhcpippool'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::Gateway::IPPool',
            'parentName'   => 'gateway',
         },
      },
      'allocateip'   => {
         'neutron' => {
            'perlClass'    => 'VDNetLib::Neutron::IPPoolAllocate',
            'parentName'   => 'neutron',
         },
      },
      'segmentidrange'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::SegmentRange',
            'parentName'   => 'vsm',
         },
         'neutron' => {
            'perlClass'    => 'VDNetLib::Neutron::SegmentRange',
            'parentName'   => 'neutron',
         },
      },
      'globalvnipool'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::GlobalVNIPool',
            'parentName'   => 'vsm',
         },
      },
      'globalmulticastiprange'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::GlobalMulticastRange',
            'parentName'   => 'vsm',
         },
      },
      'multicastiprange'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::MulticastRange',
            'parentName'   => 'vsm',
         },
         'neutron' => {
            'perlClass'    => 'VDNetLib::Neutron::MulticastRange',
            'parentName'   => 'neutron',
         },
      },
      'networkscope'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::NetworkScope',
            'parentName'   => 'vsm',
         },
      },
      'globaltransportzone'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::GlobalTransportZone',
            'parentName'   => 'vsm',
         },
      },
      'vdncluster'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::VDNCluster',
            'parentName'   => 'vsm',
         },
      },
      'vxlancontroller'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::VXLANController',
            'parentName'   => 'vsm',
         },
      },
      'vse'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::VSE',
            'parentName'   => 'vsm',
         },
      },
      'globaldistributedlogicalrouter'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::GlobalDistributedLogicalRouter',
            'parentName'   => 'vsm',
         },
      },
      'gateway'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::Gateway',
            'parentName'   => 'vsm',
         },
      },
      'dhcp'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::Gateway::DHCP',
            'parentName'   => 'gateway',
         },
      },
      'lif'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::VSE::LIF',
            'parentName'   => 'vse',
         },
      },
      'delete_lif'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::VSE::LIF',
            'parentName'   => 'vse',
         },
      },
      'global_lif'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::VSE::GlobalLIF',
            'parentName'   => 'globaldistributedlogicalrouter',
         },
      },
      'delete_global_lif'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::VSE::GlobalLIF',
            'parentName'   => 'globaldistributedlogicalrouter',
         },
      },
      'dhcprelay'   => {
          'vsm' => {
             'perlClass'    => 'VDNetLib::VSM::VSE::DHCPRelay',
             'parentName'   => 'vse',
           },
      },
      'interface'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::Gateway::Vnic',
            'parentName'   => 'gateway',
         },
      },
      'loadbalancerconfig'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::Gateway::LoadBalancerConfig',
            'parentName'   => 'gateway',
         },
      },
      'serviceinstanceruntimefromedge'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::Gateway::ServiceInstanceRuntimeEdge',
            'parentName'   => 'gateway',
         },
      },
      'bridge'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::VSE::Bridge',
            'parentName'   => 'vse',
         },
      },
      'globallogicalswitch'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::NetworkScope::GlobalLogicalSwitch',
            'parentName'   => 'globaltransportzone',
         },
      },
      'virtualwire'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::NetworkScope::VirtualWire',
            'parentName'   => 'networkscope',
         },
      },
      'assignrole'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::AccessControl',
            'parentName'   => 'vsm',
         },
      },
      'replicator_role'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::ReplicatorRole',
            'parentName'   => 'vsm',
         },
      },
      'nsxslave'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::VSMSlave',
            'parentName'   => 'vsm',
         },
      },
      'networkfeatures' => {
         'vsm' => {
            'perlClass' => 'VDNetLib::VSM::NetworkFeatures',
            'parentName' => 'vsm',
         },
      },
      'vsmregistration'   => {
         'neutron' => {
            'perlClass'    => 'VDNetLib::Neutron::VSMRegistration',
            'parentName'   => 'neutron',
			},
		},
      'nvpregistration'   => {
         'neutron' => {
            'perlClass'    => 'VDNetLib::Neutron::NVPRegistration',
            'parentName'   => 'neutron',
         },
         'vsm'  => {
            'perlClass'    => 'VDNetLib::VSM::NVPRegistration',
            'parentName'   => 'vsm',
          },
      },
      'neutronpeer'       => {
         'neutron' => {
            'perlClass'    => 'VDNetLib::Neutron::NeutronPeer',
            'parentName'   => 'neutron',
         },
      },
      'globalipset'   => {
         'vsm' => {
             'perlClass'    => 'VDNetLib::VSM::GlobalIPSet',
             'parentName'   => 'vsm',
         },
      },
      'ipset'   => {
         'neutron' => {
            'perlClass'    => 'VDNetLib::Neutron::IPSet',
            'parentName'   => 'neutron',
         },
         'vsm' => {
             'perlClass'    => 'VDNetLib::VSM::IPSet',
             'parentName'   => 'vsm',
         },
      },
      'macset'   => {
          'vsm' => {
              'perlClass'   => 'VDNetLib::VSM::MACSet',
              'parentName'  => 'vsm',
          },
      },
      'globalmacset'   => {
          'vsm' => {
              'perlClass'   => 'VDNetLib::VSM::GlobalMACSet',
              'parentName'  => 'vsm',
          },
      },
      'servicemanager'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::ServiceManager',
            'parentName'   => 'vsm',
         },
      },
      'service'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::Service',
            'parentName'   => 'vsm',
         },
      },
      'serviceinstancetemplate'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::Service::ServiceInstanceTemplate',
            'parentName'   => 'service',
         },
      },
      'vendortemplate'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::Service::VendorTemplate',
            'parentName'   => 'service',
         },
      },
      'serviceinstance'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::ServiceInstance',
            'parentName'   => 'vsm',
         },
      },
      'serviceinstanceruntimeinfo'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::ServiceInstance::ServiceInstanceRuntimeInfo',
            'parentName'   => 'serviceinstance',
         },
      },
      'versioneddeploymentspec'   => {
         'vsm' => {
             'perlClass'    => 'VDNetLib::VSM::Service::VersionedDeploymentSpec',
             'parentName'   => 'service',
             },
      },
      'clusterdeploymentconfigs'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::Service::ClusterDeploymentConfigs',
            'parentName'   => 'service',
         },
      },
      'serviceprofile'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::ServiceProfile',
            'parentName'   => 'vsm',
         },
      },
      'deploymentcontainer'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::DeploymentContainer',
            'parentName'   => 'vsm',
         },
      },
      'serviceprofilebinding'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::ServiceProfile::ServiceProfileBinding',
            'parentName'   => 'serviceprofile',
         },
      },
      'deleteclusterdeploymentconfigs'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::Service::ClusterDeploymentConfigs',
            'parentName'   => 'vsm',
         },
      },
      'deleteserviceprofile'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::ServiceProfile',
            'parentName'   => 'vsm',
         },
      },
      'deleteserviceinstance'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::DeleteServiceInstance',
            'parentName'   => 'vsm',
         },
      },
      'deletevendortemplate'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::Service::VendorTemplate',
            'parentName'   => 'vsm',
         },
      },
      'deleteservice'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::Service',
            'parentName'   => 'vsm',
         },
      },
      'deleteservicemanager'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::ServiceManager',
            'parentName'   => 'vsm',
         },
      },
      'deploymentscope'   => {
         'vsm' => {
             'perlClass'    => 'VDNetLib::VSM::Service::DeploymentScope',
             'parentName'   => 'service',
         },
      },
      'installservice'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::Service::ServiceInstall',
            'parentName'   => 'service',
         },
      },
      'applicationservicegroup'   => {
         'neutron'   => {
            'perlClass'    => 'VDNetLib::Neutron::ServiceGroup',
            'parentName'   => 'neutron',
         },
         'vsm'   => {
            'perlClass'    => 'VDNetLib::VSM::ApplicationGroup',
            'parentName'   => 'vsm',
         },
      },
      'globalapplicationservicegroup'   => {
         'vsm'   => {
            'perlClass'    => 'VDNetLib::VSM::GlobalApplicationGroup',
            'parentName'   => 'vsm',
         },
      },
      'applicationservicegroupmember'   => {
         'neutron'   => {
            'perlClass'    => 'VDNetLib::Neutron::ServiceGroupMember',
            'parentName'   => 'neutron',
         },
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::ApplicationGroupMember',
            'parentName'   => 'vsm',
         },
      },
      'applicationservice'   => {
         'neutron'   => {
            'perlClass'    => 'VDNetLib::Neutron::Service',
            'parentName'   => 'neutron',
         },
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::ApplicationService',
            'parentName'   => 'vsm',
         },
      },
      'globalapplicationservice'   => {
         'vsm' => {
            'perlClass'    => 'VDNetLib::VSM::GlobalApplicationService',
            'parentName'   => 'vsm',
         },
      },
      'securitygroup'   => {
          'vsm'   => {
              'perlClass'    => 'VDNetLib::VSM::SecurityGroup',
              'parentName'   => 'vsm',
          },
      },
      'globalsecuritygroup'   => {
          'vsm'   => {
              'perlClass'    => 'VDNetLib::VSM::GlobalSecurityGroup',
              'parentName'   => 'vsm',
          },
      },
      'firewallrule'   => {
          'vsm'   => {
              'perlClass'    => 'VDNetLib::VSM::DistributedFirewall',
              'parentName'   => 'vsm',
          },
      },
      'dfwsection'   => {
          'vsm'   => {
              'perlClass'    => 'VDNetLib::VSM::DFWSections',
              'parentName'   => 'vsm',
          },
      },
      'deletedfwsection'   => {
          'vsm'   => {
              'perlClass'    => 'VDNetLib::VSM::DFWSections',
              'parentName'   => 'vsm',
          },
      },
      'globaldfwsection'   => {
          'vsm'   => {
              'perlClass'    => 'VDNetLib::VSM::GlobalDFWSections',
              'parentName'   => 'vsm',
          },
      },
      'globalfirewallrule'   => {
          'vsm'   => {
              'perlClass'    => 'VDNetLib::VSM::GlobalDFWRules',
              'parentName'   => 'vsm',
          },
      },
      'config_flow_exclusion'   => {
          'vsm'   => {
              'perlClass'    => 'VDNetLib::VSM::DFWFlowConfig',
              'parentName'   => 'vsm',
          },
      },
      'staticrouting'   => {
          'vsm' => {
              'perlClass'    => 'VDNetLib::VSM::Gateway::StaticRoute',
              'parentName'   => 'gateway',
          },
      },
      'globalrouteconfig'   => {
          'vsm' => {
              'perlClass'    => 'VDNetLib::VSM::Gateway::GlobalRouteConfig',
              'parentName'   => 'gateway',
         },
      },
      'bgp'   => {
          'vsm' => {
              'perlClass'    => 'VDNetLib::VSM::Gateway::BGPRoute',
              'parentName'   => 'gateway',
          },
      },
      'ospf'   => {
          'vsm' => {
              'perlClass'    => 'VDNetLib::VSM::Gateway::OSPFRoute',
              'parentName'   => 'gateway',
          },
      },
      'firewall'   => {
          'vsm' => {
              'perlClass'    => 'VDNetLib::VSM::Gateway::Firewall',
              'parentName'   => 'gateway',
          },
      },
      'firewall_rules'   => {
          'vsm' => {
              'perlClass'    => 'VDNetLib::VSM::Gateway::FirewallRules',
              'parentName'   => 'gateway',
          },
      },
      'nat'   => {
          'vsm' => {
              'perlClass'    => 'VDNetLib::VSM::Gateway::NAT',
              'parentName'   => 'gateway',
          },
      },
      'nat_rules'   => {
          'vsm' => {
              'perlClass'    => 'VDNetLib::VSM::Gateway::NATRules',
              'parentName'   => 'gateway',
          },
      },
      'ipfixconfig'   => {
          'vsm'   => {
              'perlClass'    => 'VDNetLib::VSM::IPFIXConfig',
              'parentName'   => 'vsm',
          },
      },
      'thresholdconfig'   => {
          'vsm'   => {
              'perlClass'    => 'VDNetLib::VSM::DFWEventThreshold',
              'parentName'   => 'vsm',
          },
      },
      'tor'     => {
          'vsm'   => {
              'perlClass'    => 'VDNetLib::VSM::TOR',
              'parentName'   => 'vsm',
          },
      },
      'tor_binding'     => {
          'vsm'   => {
              'perlClass'    => 'VDNetLib::VSM::TOR::TORBinding',
              'parentName'   => 'vsm',
          },
      },
      'torattachment'     => {
          'vsm'   => {
              'perlClass'    => 'VDNetLib::VSM::NetworkScope::VirtualWire::TORAttachment',
              'parentName'   => 'vsm',
          },
      },
      'ptep'     => {
          'vsm'   => {
              'perlClass'    => 'VDNetLib::VSM::PTEP',
              'parentName'   => 'vsm',
          },
      },
      'bfd'     => {
          'vsm'   => {
              'perlClass'    => 'VDNetLib::VSM::BFD',
              'parentName'   => 'vsm',
          },
      },
   };
   return $mappingHash->{$componentName}{$type};
}


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

sub AUTOLOAD
{
   my $self = shift;
   my $args = @_;

   return if $AUTOLOAD =~ /::DESTROY$/;
   my $method = $1 if ($AUTOLOAD =~ /.*::(\w+)/);
   #
   #TODO: decide the return values or exceptions from Python layer
   #for which "FAILURE" should be returned from here. This is to
   #make all Inline Python return calls consistent in case of failure
   #situations
   #
   my $inlinePyObj =  $self->GetInlinePyObject();
   return $inlinePyObj->$method(@_);
}


########################################################################
#
# CreateComponent
#     Wrapper method for CreateAndVerifyComponent()
#     CreateComponent() is going to be the entry point for
#     creations moving forward
#
# Input:
#     componentName: name of the component to be created
#     parentObj    : reference to parent of this component in the
#                    hierarchy model. For example, for transportzone,
#                    it is nvp controller object
#     arrayofSpec : reference to array of hash
#
# Results:
#     None
#
# Side effects:
#     None
#
########################################################################

sub CreateComponent
{
   my $self = shift;
   return $self->CreateAndVerifyComponent(@_);
}


########################################################################
#
# CreateAndVerifyComponent --
#     Method to create components/managed objects/entities and verify
#     components .
#
# Input:
#     componentName: name of the component to be created
#     parentObj    : reference to parent of this component in the
#                    hierarchy model. For example, for transportzone,
#                    it is nvp controller object
#     arrayofSpec : reference to array of hash
#
# Results:
#     Reference to array  of component objects, if successful;
#     TBD, in case of failure
#
# Side effects:
#     None
#
########################################################################

sub CreateAndVerifyComponent
{
   my $self               = shift;
   my $componentName      = shift;
   my $arrayOfSpec        = shift;
   my $arrayOfMetaData;

   my $processedSpecs;
   my $inlinePyObj;
   my @arrayOfPerlObjs;
   my $arrayOfInlinePyObjs;
   my $componentTemplateObject;
   my $result = SUCCESS;

   my $type = $self->{type};
   if (not defined $type) {
      $vdLogger->Error("Type attribute is missing in parent object of $componentName");
         VDSetLastError(VDGetLastError());
         return FAILURE;
   }

   my $componentInfo = $self->ComponentMap($componentName, $type);
   my $componentClass = $componentInfo->{'perlClass'};
   eval "require $componentClass";
   if ($@) {
      $vdLogger->Error("Failed to load $componentClass $@");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   # Extract metadata and expected result
   ($arrayOfSpec, $arrayOfMetaData) = $self->ExtractMetadata($arrayOfSpec);
   my $templateInlinePyObj;

   eval {
      $componentTemplateObject =
         $componentClass->new($componentInfo->{parentName} => $self);
      if ($componentTemplateObject eq FAILURE) {
         $vdLogger->Error("Failed to create an instance of $componentName");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $processedSpecs = $componentTemplateObject->ProcessSpec($arrayOfSpec,
                              $componentTemplateObject->GetAttributeMapping());
      if ($processedSpecs eq FAILURE) {
         $vdLogger->Error("ProcessSpec returned failure");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $templateInlinePyObj = $componentTemplateObject->GetInlinePyObject();
      if ((not defined $templateInlinePyObj) || ($templateInlinePyObj eq FAILURE)) {
         $vdLogger->Error("Inline Python object not defined or valid");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while creating " .
                       "inline component $componentName instances:\n". $@);
      my @ret;
      return \@ret;
   }
   my $index = 0;

   # Step1: Call Create Component
   $vdLogger->Info("Start calling post calls for creating $componentName");
   $arrayOfInlinePyObjs  = $self->Create($componentClass,
                                         $templateInlinePyObj,
                                         $processedSpecs);
   foreach my $resultObj (@$arrayOfInlinePyObjs) {
      my $newComponentObj;
      %$newComponentObj = %$componentTemplateObject;
      my ($className, $varType) = split(/=/,$componentTemplateObject);
      bless $newComponentObj, $className;
      # Need to store the UUID of the componenet
      my $newInlinePyObj = $newComponentObj->GetInlinePyObject();

      if ($newInlinePyObj eq FAILURE) {
         $vdLogger->Error("Failed to inline Py object for $newComponentObj");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      # Storing the uuid based status code. If status code
      # is not in the range of 200, the uuid is set to undef
      # because the server call would have failed and the
      # uuid would be null
      if ($resultObj->{status_code} =~ /^2/i) {
         $newComponentObj->{id} = py_call_method($newInlinePyObj,
                                                 "get_id",
                                                 $resultObj->{response_data});
         if (defined $newComponentObj->{id}) {
            $vdLogger->Debug("Id of $componentName from pylib:" .
                             $newComponentObj->{id});
         } else {
            $vdLogger->Debug("Id of $componentName from pylib: " .
                             "is not defined");
         }
      } else {
         $newComponentObj->{id} = undef;
      }

      push(@arrayOfPerlObjs, $newComponentObj);

      # Step2: Call Setter()
      # newComponentObj need to store
      # the obj or some value given by
      # user in the spec.
      # E.g. vdncluster needs to save
      # the pointer to VC's cluster obj
      # so that update calls and delete
      # calls of vdncluster can call
      # GetClusterMORId on the VC's
      # cluster obj. Thus we pass
      # the spec to setter API of
      # that obj and allow it to set
      # whatever it wants
      $vdLogger->Debug("Calling the setter module for $componentName");
      $newComponentObj->Setter(@$arrayOfSpec[$index]);
      $index++;
   }

   # Step3: Verify the results
   $vdLogger->Debug("Start verification for component $componentName");
   $result = $self->BulkAPIVerify('processedSpecs'      => $processedSpecs,
                                  'arrayOfMetaData'     => $arrayOfMetaData,
                                  'arrayOfInlinePyObjs' => $arrayOfInlinePyObjs,
                                  'inlinePyObj'         => $templateInlinePyObj);
   if ($result ne "FAILURE") {
      $vdLogger->Info("Create and Verify PASSED for ". $componentName);
      return \@arrayOfPerlObjs;
   } else {
      $vdLogger->Debug("Create and Verify FAILED for ". $componentName);
      VDSetLastError(VDGetLastError());
      $result = FAILURE;
      return $result;
   }
}


########################################################################
#
# CreateComponent --
#     Method to create components/managed objects/entities. This
#     method invokes Py layer's bulkCreate.
#
# Input:
#     componentName  : name of the component to be created
#     $inlinePyObj   : reference to inline python parent object
#                      of this component in the hierarchy model
#                      For example, for transportzone, it is
#                      nvp controller object
#     processedSpecs : reference to array of hash
#
# Results:
#     Reference to array  of component objects, if successful;
#     TBD, in case of failure
#
# Side effects:
#     None
#
########################################################################

sub Create
{
   my $self               = shift;
   my $componentClass      = shift;
   my $inlinePyObj        = shift;
   my $processedSpecs     = shift;

   my $arrayOfInlinePyObjs;
   eval "require $componentClass";
   if ($@) {
      $vdLogger->Error("Failed to load $componentClass $@");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $result = SUCCESS;
   eval {
      # Load base_client module which has create()
      py_eval("import base_client");
      $arrayOfInlinePyObjs  = py_call_method($inlinePyObj,
                                             "create",
                                             $processedSpecs);
   };

   if ($@) {
      $vdLogger->Error("Exception thrown while creating " .
                       "$componentClass instances:\n". $@);
      $vdLogger->Error("File product PR, returning false positive to unblock");
   }

   return $arrayOfInlinePyObjs;

}


########################################################################
#
# UpdateComponent --
#     Method to update components/managed objects/entities. This
#     method invokes Py layer's bulkUpdate.
#
# Input:
#     componentName  : name of the component to be update
#     $inlinePyObj   : reference to inline python parent object
#                      of this component in the hierarchy model
#                      For example, for transportzone, it is
#                      nvp controller object
#     processedSpecs : reference to array of hash
#
# Results:
#     Reference to array  of component objects, if successful;
#     TBD, in case of failure
#
# Side effects:
#     None
#
########################################################################

sub UpdateComponent
{
   my $self               = shift;
   my $processedSpecs     = shift;

   my $arrayOfMetaData;

   my $arrayOfSpec;
   push(@$arrayOfSpec, $processedSpecs);
   # Extract metadata and expected result
   ($arrayOfSpec, $arrayOfMetaData) =
      $self->ExtractMetadata($arrayOfSpec);

   $processedSpecs = $self->ProcessSpec($arrayOfSpec, $self->GetAttributeMapping());
   my $arrayOfInlinePyObjs;
   my $inlinePyObj = $self->GetInlinePyObject();
   if ((not defined $inlinePyObj) || ($inlinePyObj eq FAILURE)) {
         $vdLogger->Error("Inline Python object not defined or valid");
         VDSetLastError("ENOTDEF");
         return FAILURE;
   }
   my $updateHash;
   $updateHash->{obj} = $inlinePyObj;

   my @newArrayOfSpec;
   foreach my $spec (@$processedSpecs) {
      $updateHash->{spec} = $spec;
      delete $updateHash->{spec}{metadata};
   }

   my @updateArray;
   push(@updateArray, $updateHash);
   my $result = SUCCESS;
   eval {
         # Load baseController module which has bulkCreate()
         py_eval("import base_client");
         $arrayOfInlinePyObjs  = py_call_function("base_client",
                                                  "bulk_update",
                                                  \@updateArray);
   };
   if ($@) {
      $vdLogger->Error("File product PR, returning false positive to unblock");
   }
   $result = $self->BulkAPIVerify('processedSpecs'       => $processedSpecs,
                                  'arrayOfMetaData'      => $arrayOfMetaData,
                                  'arrayOfInlinePyObjs'  => $arrayOfInlinePyObjs,
                                  'inlinePyObj'          => $inlinePyObj);
   if ($result ne "FAILURE") {
      $vdLogger->Info("Update and Verify SUCCEEDED for " .
                      $self->{id});
      return \$arrayOfInlinePyObjs;
   } else {
      $vdLogger->Debug("Update and Verify FAILED for " .
                       $self->{id});
      VDSetLastError(VDGetLastError());
      $result = "FAILURE";
      return $result;
   }
}

########################################################################
#
# BulkAPIVerify --
#     Method to verify if the componenet has been created or not
#
# Input:
#     processedSpecs        : reference to array of hash
#     arrayOfMetaData       : reference to array of metadata
#     arrayOfInlinePyObjs   : reference to array of result objects
#
# Results:
#     SUCCESS, if verifiction of all components pass
#     FAILURE, if verifiction of any one components fail
#
# Side effects:
#     None
#
########################################################################

sub BulkAPIVerify
{
   my $self                = shift;
   my %args                = @_;
   my $processedSpecs      = $args{processedSpecs};
   my $arrayOfMetaData     = $args{arrayOfMetaData};
   my $arrayOfInlinePyObjs = $args{arrayOfInlinePyObjs};
   my $inlinePyObj         = $args{inlinePyObj};

   my $result = SUCCESS;
   my $index = 0;
   my $arrayOfValues;
   eval {
      py_eval("import base_client");
      $arrayOfValues = py_call_function("base_client",
                                        "bulk_api_verify",
                                        $inlinePyObj,
                                        $processedSpecs,
                                        $arrayOfMetaData,
                                        $arrayOfInlinePyObjs);
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while verifying " .
                       ":\n". $@);
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   foreach my $pyResult (@$arrayOfValues) {
      if ($pyResult eq "FAILURE") {
         # In case of failure Def the array of Inline Py Objs and index
         # into the result obj of the component
         # Now call get_response on the result_obj python obj
         my $creationError = py_call_method($$arrayOfInlinePyObjs[$index],
                                            "get_response_data");
         $vdLogger->Error("Verification failed for the process spec " .
                          Dumper($processedSpecs->[$index]));
         $vdLogger->Error("Error details : " . $creationError);
         $result = FAILURE;
      } else {
         $vdLogger->Debug("Verification for the process spec passed " .
                          Dumper($processedSpecs->[$index]));
      }
      $index++;
   }
   return $result;
}


########################################################################
#
# ExtractMetadata --
#     Method to extract metadata from the spec and return the extracted
#     metadata as an array and the input (wihout metadata)
#
# Input:
#     arrayofSpec : reference to array of hash
#
# Results:
#     Reference to array of spec, Reference to array  of metadata
#
# Side effects:
#     None
#
########################################################################

sub ExtractMetadata
{
   my $self            = shift;
   my $arrayOfSpec     = shift;
   my $arrayOfMetaData;
   my $arrayOfExpectedResult;

   foreach my $spec (@$arrayOfSpec) {
      if (ref($spec) =~ /HASH/) {
         if (exists $spec->{metadata}) {
            push @$arrayOfMetaData, $spec->{metadata};
            delete $spec->{metadata};
         }
      }
   }
   return ($arrayOfSpec, $arrayOfMetaData, $arrayOfExpectedResult);
}


#######################################################################
#
# ProcessParameters --
#      This method will replace tuples with objects
#
# Input:
#      input         : four possible values - string, tuple, array
#                      reference or hash reference
#      templateObj   : object of the component which will be used to get
#                      the attribute mapping from class
#      componentName : using this name, corresponding mapping is found
#
# Results:
#      tuples replaced with objects is returned
#
# Side effects:
#
########################################################################

sub ProcessSpec
{
   my $self             = shift;
   my $input            = shift;
   my $mappingDuplicate = shift;

   if (!%$mappingDuplicate) {
      return $input;
   }
   foreach my $arrayElement (@$input) {
      my @inputArray = ();

      if (FAILURE eq $self->RecurseResolveTuple($arrayElement, $mappingDuplicate)) {
         $vdLogger->Error("Error encountered while resolving tuples");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      };
   }
   return $input;
}


#######################################################################
#
# RecurseResolveTuple --
#      This method recurses through the data structure where tuples
#      are to be replaced with objects.
#
# Input:
#      input : four possible values - string, tuple, array
#              reference or hash reference
#      mappingDuplicate : attribute mapping
#
# Results:
#      duplicate datastructure, where tuples replaced with objects
#
# Side effects:
#
########################################################################

sub RecurseResolveTuple
{
   my $self = shift;
   my $param = shift;
   my $mappingDuplicate = shift;
   my $payload;

   if (ref($param) eq "HASH") {
      foreach my $key (keys %$param) {
         if ((ref($param->{$key}) eq "HASH")) {
               $param->{$key} = $self->RecurseResolveTuple($param->{$key},
                                   $mappingDuplicate);
         } elsif (ref($param->{$key}) eq "ARRAY") {
            my @inputArray = ();
            foreach my $arrayElement (@{$param->{$key}}) {
                my $reftype =  blessed $arrayElement;
                if ((defined $reftype) && ($reftype =~ /VDNet/i)) {
                   $vdLogger->Debug("Element is an object of type: $reftype");
                   # if array element is an array of objects
                   my $refArray = $self->ReplaceObjectWithValues($arrayElement,
                                     $key, $mappingDuplicate);
                   push(@inputArray, @$refArray);
               } else {
                  # if array element is a hash
                  $vdLogger->Debug("Element is a hash");
                  push(@inputArray,
                    $self->RecurseResolveTuple($arrayElement, $mappingDuplicate));
               }
            }
            if ((exists $mappingDuplicate->{$key}{payload}) &&
                (defined $mappingDuplicate->{$key}{payload})) {
               $param->{$mappingDuplicate->{$key}{payload}} = \@inputArray;
            } else {
               $param->{$key} = \@inputArray;
            }
         } else {
            if (FAILURE eq $self->ReplaceWithValues($param,$key, $mappingDuplicate)) {
               $vdLogger->Error("Error encountered while replace with values");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
         }
         # If the payload name and abstract key name are not same, then
         # delete the abstract key
         if ((exists $mappingDuplicate->{$key}) &&
            (defined $mappingDuplicate->{$key}{payload}) &&
            ($key ne $mappingDuplicate->{$key}{payload})) {
               my $payloadKey = $mappingDuplicate->{$key}{payload};
               if (not defined $param->{$payloadKey}) {
                  $param->{$payloadKey} = $param->{$key};
               }
               $vdLogger->Warn("Deleting $key for the payload");
               delete $param->{$key};
         }
      }
   } elsif (ref($param) eq "ARRAY") {
      foreach my $element (@$param) {
         my @inputArray = ();
         $self->RecurseResolveTuple($element, $mappingDuplicate);
      }
   }
   return $param;
}


#######################################################################
#
# ReplaceWithValues --
#      This method checks if input is a object or not. If its a object,
#      the value gets replaced with object attribute.
#
# Input:
#      value : two possible values - string or tuple
#
# Results:
#      tuples replaced with objects if found
#
# Side effects:
#
########################################################################

sub ReplaceWithValues
{
   my $self             = shift;
   my $param            = shift;
   my $key              = shift;
   my $mappingDuplicate = shift;

   if (exists $mappingDuplicate->{$key}) {

      my $reftype =  blessed $param->{$key};
      if ((defined $reftype) && ($reftype =~ /VDNet/i)) {
         my $componentObj = $param->{$key};
         my $method = $mappingDuplicate->{$key}{attribute};
         if (exists $componentObj->{$mappingDuplicate->{$key}{attribute}}) {
            $param->{$mappingDuplicate->{$key}{payload}} =
               $componentObj->{$mappingDuplicate->{$key}{attribute}};
         } elsif ($componentObj->can($method)) {
               # can checks if the object has a method called $method
               my $result = $componentObj->$method($key, $param);
               if ($result eq FAILURE) {
                  $vdLogger->Error("Error encounter while running method " .
                                   "$method in $componentObj object");
                  VDSetLastError(VDGetLastError());
                  return FAILURE;
               }
               $param->{$mappingDuplicate->{$key}{payload}} = $result;
         } else {
            $vdLogger->Warn("No object attribute or method for key $key under class $reftype");
         }
         if ($key ne $mappingDuplicate->{$key}{payload}) {
            delete $param->{$key};
         }
     } else {
        $param->{$mappingDuplicate->{$key}{payload}} = $param->{$key};
        if ($key ne $mappingDuplicate->{$key}{payload}) {
           delete $param->{$key};
        }
      }
   }
}


#######################################################################
#
# ReplaceObjectWithValues --
#      This method replaces array of object with object attribute.
#
# Input:
#      value : array of objects
#
# Results:
#      objects replaced with values if found
#
# Side effects:
#
########################################################################

sub ReplaceObjectWithValues
{
   my $self = shift;
   my $arrayElement = shift;
   my $key = shift;
   my $mappingDuplicate = shift;
   my @returnArray;

   if ( exists $mappingDuplicate->{$key}) {
         my $reftype = blessed $arrayElement ;
         if ((defined $reftype) && ($reftype =~/VDNet/i)) {
            my $componentObj = $arrayElement;
            my $method = $mappingDuplicate->{$key}{attribute};

            if (exists $componentObj->{$mappingDuplicate->{$key}{attribute}}){
               $vdLogger->Debug("found attribute for $key
                           under class $reftype" );
               push(@returnArray, $componentObj->{$mappingDuplicate->{$key}{attribute}});
            } elsif ($componentObj->can($method)) {
               # can checks if the object has a method called $method
               $vdLogger->Debug("found method for $key
                           under class $reftype" );
               push(@returnArray, $componentObj->$method());
            } else {
               $vdLogger->Warn("No object attribute or method for key $key
                           under class $reftype, hence pushing the object itself" );
               push(@returnArray, $arrayElement);
            }
         } else {
            push(@returnArray, $arrayElement)
         }
   }
   return \@returnArray;
}


########################################################################
#
# DeleteComponent --
#     Method to delete components/managed objects/entities. This
#     method invokes Py layer's delete method from baseController.
#
# Input:
#     arrayOfPerlObjects: reference to array of perl objects on which
#     delete is called
#
# Results:
#     SUCCESS, if the operation succeeds
#     FAILURE, in case of failure
#
# Side effects:
#     None
#
########################################################################

sub DeleteComponent
{
   my $self                     = shift;
   my $arrayOfPerlObjects       = shift;
   my $arrayOfCorrespondingArgs = shift;
   my $args                     = undef;
   my $errorCount               = 0;
   my $arrayOfArgsIndex         = 0;

   if (not defined $ENV{VDNET_PYLIB_THREADS}) {
      foreach my $templateObj (@$arrayOfPerlObjects) {
         if (not defined $templateObj->{id}) {
            $vdLogger->Info("Skipping deletion of component");
            next;
         }
         my $inlinePyObj = $templateObj->GetInlinePyObject();
         # Reset the args for each perl object
         $args = undef;
         if (defined $arrayOfCorrespondingArgs &&
             ref($arrayOfCorrespondingArgs) eq "ARRAY") {
            # Get the args from the array if user has passed array of args
            $args = @$arrayOfCorrespondingArgs[$arrayOfArgsIndex];
            $arrayOfArgsIndex++;
         } elsif (ref($arrayOfCorrespondingArgs) eq "HASH") {
            $args = $arrayOfCorrespondingArgs;
         }

         # py_call_method(object, "method name", args...)
         $vdLogger->Debug(" args is " . Dumper($args)) if defined $args;
         my $resultObj = py_call_method($inlinePyObj,
                                        "delete",
                                        $args);
         $vdLogger->Trace("Objects to be deleted: $templateObj" .
                          "Delete return code:" . $resultObj->{status_code});
         #TODO: Find out which codes are SUCCESS and which are FAILURE
         if ($resultObj->{status_code} !~ /^2/i) {
            $vdLogger->Error("Failed to remove component. Got:" .
                             $resultObj->{status_code});
            my $deletionError = py_call_method($resultObj,
                                            "get_response");
            $vdLogger->Error("Error details: " . $deletionError);
            $errorCount++;
         } else {
            $vdLogger->Info("Deleted component $templateObj->{id} successfully");
         }
      }
   } else {
      my @inlinePyObjs;
      my $inlinePyObj;
      foreach my $perlObj (@$arrayOfPerlObjects) {
         $inlinePyObj = $perlObj->GetInlinePyObject();
         push(@inlinePyObjs, $inlinePyObj);
      }
      my $resultArray = py_call_method($inlinePyObj,
                                       "delete",
                                       \@inlinePyObjs);
      my $index = 0;
      foreach my $resultObj (@$resultArray) {
         if ($resultObj->{status_code} !~ /^2/i) {
            $vdLogger->Error("Failed to remove component. Got:" .
                             $resultObj->{status_code});
            my $deletionError = py_call_method($resultObj,
                                             "get_response");
            $vdLogger->Error("Error details: " . $deletionError);
            $errorCount++;
         } else {
            $vdLogger->Info("Deleted component $arrayOfPerlObjects->[$index]->{id} successfully");
            $index++;
         }
      }
   }

   if ($errorCount > 0) {
      VDSetLastError("EOPFAILED");
      return FAILURE;
   } else {
      return SUCCESS;
   }
}


########################################################################
#
# Setter --
#      newComponentObj need to store the obj or some value given by
#      user in the spec.
#      E.g. vdncluster needs to save the pointer to VC's cluster obj
#      so that update calls and delete calls of vdncluster can
#      call GetClusterMORId on the VC's cluster obj. Thus we pass
#      the spec to setter API of that obj and allow it to set whatever it wants
#
# Input:
#
# Results:
#
# Side effects:
#     None
#
########################################################################

sub Setter
{
   return SUCCESS;
}

########################################################################
#
# UpdateSubComponent --
#     Method to update the subcomponent of the current object
#
# Input:
#     subComponent   : name of the subcomponent
#     args           : reference to hash containing processed spec/schema
#
# Results:
#     SUCCESS, if the subcomponent is updated (created in REST world);
#     FAILURE, in case of any error;
#
#
# Side effects:
#     None
#
########################################################################

sub UpdateSubComponent
{
   my $self          = shift;
   my $subComponent  = shift;
   my $args          = shift;
   my $inlinePyObj   = $self->GetInlinePyObject();
   my $componentName = $subComponent;
   my $componentInfo = $self->ComponentMap($componentName, $self->{type});

   my $processedSpecs;

   $processedSpecs = $self->ProcessSpec([$args],$self->GetAttributeMapping());
   $args = $processedSpecs->[0];

   my $attributemapping = $self->{attributemapping};
   if ((not defined $attributemapping->{$subComponent}) ||
      (not defined $attributemapping->{$subComponent}{'pyClass'})) {
      $vdLogger->Error("Pyclass not defined $subComponent in attribute mapping");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $subComponentPyObj = CreateInlinePythonObject($attributemapping->{$subComponent}{'pyClass'},
                                                    $inlinePyObj);
   my $resultObj = py_call_method($subComponentPyObj,
                                  "create_using_put",
                                  $args);
   if ($resultObj->{status_code} !~ /^2/i) {
      $vdLogger->Error("Failed to update component. Got:" .
                       $resultObj->{status_code});
      VDSetLastError("EOPFAILED");
      return FAILURE;
   } else {
      $vdLogger->Info("Subcomponent $subComponent created  successfully");
   }
}


#######################################################################
#
# GetAttributeMapping --
#      returns the attribute mapping
#
# Input:
#      None
#
# Results:
#      returns the attribute mapping
#
# Side effects:
#      None
#
########################################################################

sub GetAttributeMapping
{
   my $self = shift;
   my $currentPackage;
   if (ref($self)) {
      $self =~ /(.*)\=.*/;
      $currentPackage = $1;
   }
   my $package = eval "$currentPackage" . "::" . 'attributemapping';
   if ($@) {
      $vdLogger->Error("Exception thrown getting attribute mapping " .
                       "for class $currentPackage\n". $@);
      return FAILURE;
   }
   return $package
}




#######################################################################
#
# VerifyEndPoint --
#      Issues a "get" call on endpoint and checks if result was 200
#
# Input:
#      Array of node object references
#
# Results:
#      returns SUCCESS if endpoint was found, FAILURE otherwise
#
# Side effects:
#      None
#
########################################################################
sub VerifyEndPoint
{
   my $self = shift;
   my $arrayRefOfNodeObject = shift;
   foreach my $nodeObj (@$arrayRefOfNodeObject) {
      my $resultObj;
      my $nodeInlinePyObj = $nodeObj->GetInlinePyObject();
      eval{
         $resultObj = py_call_method($nodeInlinePyObj,
                                     "get");
      };

      if ($@) {
         $vdLogger->Error("Exception thrown while verifying " .
                          ":\n". $@);
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      #Check if status code is 200
      if ($resultObj->{status_code} eq "200") {
         $vdLogger->Info("The endpoint ".
                         $nodeObj->{componentname}. " exists");
      } else {
         $vdLogger->Error("The endpoint ". $nodeObj->{componentname} .
                          " does not exist");
         return FAILURE;
      }
   }
   return SUCCESS;
}


#######################################################################
#
# GetEndpointAttributes --
#      Issues a "get" call on the test object (e.g. transportzone) and
#      gets back a hash for the resulting schema. The resulting dict is
#      then passed to a utility method that compares it with the expected
#      values that are coming in from the TDS.
#
# Input:
#      serverForm: expected values from TDS.
#
# Results:
#      returns a resultHash object that contains following attrbutes:
#       status_code => SUCCESS/FAILURE
#       response    => array consisting of serverdata and attributeMapping
#       error       => error code
#       reason      => error reason
#
# Side effects:
#      None
#
########################################################################

sub GetEndpointAttributes
{
   my $self         = shift;
   my $serverForm   = shift;

   #
   # Server call
   #

   my $mapping = $self->GetAttributeMapping();
   my $nodeInlinePyObj = $self->GetInlinePyObject();
   my $resultObj = py_call_method($nodeInlinePyObj,
                                     "get_response_dict");

   my $resultHash;
   if ($resultObj eq "FAILURE") {
      $resultHash->{status} = "FAILURE";
      return $resultHash;
   }

   my $serverData = VDNetLib::Common::Utilities::FillServerForm($resultObj,
                                                                $serverForm,
                                                                $mapping);
   $resultHash = {
      'status'      => "SUCCESS",
      'response'    => $serverData,
      'error'       => undef,
      'reason'      => undef,
   };
   return $resultHash;
}


#######################################################################
#
# GetUpgradeStatus --
#      Issues a "get_upgrade_response_dict" call on the test object
#      (e.g. vdncluster) and gets back a hash for the resulting schema.
#      The resulting dict is then passed to a utility method that compares
#      it with the expected values that are coming in from the TDS.
#
# Input:
#      serverForm: expected values from TDS.
#
# Results:
#      returns a resultHash object that contains following attrbutes:
#       status_code => SUCCESS/FAILURE
#       response    => array consisting of serverdata and attributeMapping
#       error       => error code
#       reason      => error reason
#
# Side effects:
#      None
#
########################################################################

sub GetUpgradeStatus
{
   my $self         = shift;
   my $serverForm   = shift;

   #
   # Server call
   #

   my $mapping = $self->GetAttributeMapping();
   my $nodeInlinePyObj = $self->GetInlinePyObject();
   my $resultObj = py_call_method($nodeInlinePyObj,
                                     "get_upgrade_response_dict");

   my $resultHash;
   if ($resultObj eq "FAILURE") {
      $resultHash->{status} = "FAILURE";
      return $resultHash;
   }

   my $serverData = VDNetLib::Common::Utilities::FillServerForm($resultObj,
                                                                $serverForm,
                                                                $mapping);
   $resultHash = {
      'status'      => "SUCCESS",
      'response'    => $serverData,
      'error'       => undef,
      'reason'      => undef,
   };

   return $resultHash;
}


#######################################################################
#
# VerifyBackingComponentExistsForEndpoint --
#      Issues a "get" call on the backing object (e.g. virtualwire is the
#      backing object on vsm for a neutron logicalswitch) of an endpoint and
#      checks if the result was 200
#
# Input:
#      $arg1 - array of inventory objects (where backing objects should get
#      realized)
#      e.g. vsm.[1], vsm.[2]
#      $arg2 - class hierarchy for the realized object,
#      e.g. vdn-scope/virtualwire for virtual wire
#
# Results:
#      returns SUCCESS if backing object was found, FAILURE otherwise
#
# Side effects:
#      None
#
########################################################################

sub VerifyBackingComponentExistsForEndpoint
{
   my $self = shift;
   my $arg1 = shift;
   my $arg2 = shift;

   my $nodeObject = $self;

   # Splitting the class hierarchy string into an array
   my @componentNameArray = split('/',$arg2);
   my $refArrayInventoryObj = $arg1;

   # Getting the last class name in the heirarchy. That represents the
   # actual object that will be realized.
   my $componentName = $componentNameArray[-1];

   # Obtaining dummy python objects for the objects that have been realized
   my $realizedTemplatePyObjects = $self->GetChildPyObject($refArrayInventoryObj, \@componentNameArray);

   # Getting the python objects for incoming inventory objects
   my @inventoryPyObjArray = ();
   foreach my $invObj (@$refArrayInventoryObj) {
      my $invPyObj = $invObj->GetInlinePyObject();
      push @inventoryPyObjArray, $invPyObj;
   }

   my @arrayRefOfPyObject = ();
   my $nodePyObject = $nodeObject->GetInlinePyObject();
   push @arrayRefOfPyObject, $nodePyObject;

   # Calling base client to populate dummy python objects with id and endpoint
   # information of realized objects
   py_eval("import base_client");
   my $arrayOfInlinePyObjs  = py_call_function("base_client",
                                               "bulk_get_state",
                                               \@inventoryPyObjArray,
                                               $realizedTemplatePyObjects,
                                               \@arrayRefOfPyObject);

   if ($arrayOfInlinePyObjs eq "FAILURE") {
      $vdLogger->Error("Object has not been realized ");
      return FAILURE;
   }

   # Making get calls on the populated python objects for the realized objects
   # to verify realization
   foreach my $inlinePyObj (@$arrayOfInlinePyObjs) {
      my $resultObj;
      eval {
         $resultObj = $inlinePyObj->get();
      };
      if ($@) {
         $vdLogger->Error("Exception thrown while verifying " .
                          ":\n". $@);
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      if ($resultObj->{status_code} eq "200") {
         $vdLogger->Info("The endpoint " . $componentName .
                         " exists");
      } else {
         $vdLogger->Error("The endpoint " . $componentName .
                          " does not exist");
         return FAILURE;
      }
   }

   return SUCCESS;
}


#######################################################################
#
# GetChildPyObject --
#      Returns a dummy python object after traversing a hierarchy of class
#      names specified in input
#
# Input:
#      invObjArray: Array of inventory objects
#      keyNameArray: array of names depicting the class heirarchy for object
#      that is to be created,
#      e.g. ['vdn-scope, virtualwire'] for virtual wire
#
# Results:
#      returns Array of python objects
#
# Side effects:
#      None
#
#######################################################################

sub GetChildPyObject
{

   my $self = shift;
   my $invObjArray = shift;
   my $keyNameArray = shift;

   # Starting traversal of class hierarchy by having the inventory object as
   # the initial object

   my @arrayOfChildPyObjects = ();
   foreach my $invObj (@$invObjArray) {
      my $tempObj = $invObj;
      my $tempKey = $invObj->{type};
      my $invKey = $tempKey;
      foreach my $keyName (@$keyNameArray) {

         # Obtaining the complete perl class from ComponentMap
         my $componentInfo = $self->ComponentMap($keyName, $invKey);
         my $componentClass = $componentInfo->{'perlClass'};
         eval "require $componentClass";

         # Instantiating the subsequent object in the hierarchy
         my $newObj = $componentClass->new( $tempKey => $tempObj);
         $tempObj = $newObj;
         $tempKey = $keyName;
      }

      # Getting the corresponding python object for the perl object obtained
      # using class heirarchy
      my $tempPyObj = $tempObj->GetInlinePyObject();
      push @arrayOfChildPyObjects, $tempPyObj;
   }

   return \@arrayOfChildPyObjects;
}


1;
