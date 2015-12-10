#!/usr/bin/perl
#########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::NSX::ServiceInsertion::CommonWorkloads;

use FindBin;
use lib "$FindBin::Bin/..";
use lib "$FindBin::Bin/../..";
use VDNetLib::TestData::TestConstants;

# Export all workloads which are very common across all tests
use base 'Exporter';
our @EXPORT_OK = (
   'PREP_CLUSTER',
   'GET_DATASTORE',
   'CREATE_SERVICE_MANAGER',
   'CREATE_VENDOR_TEMPLATE',
   'REMOVE_BINDING',
   'CHECK_DVFILTER',
   'CREATE_SERVICE',
   'CHECK_SVM_DEPLOYMENT_STATUS',
   'CHECK_SVM_UNDEPLOYMENT_STATUS',
   'GET_SERVICE_PROFILE',
   'DELETE_SERVICE_CLUSTER',
   'DELETE_SERVICE_PROFILE',
   'DELETE_SERVICE_INSTANCE',
   'DELETE_VENDOR_TEMPLATE',
   'DELETE_SERVICE',
   'DELETE_SERVICE_MANAGER',
   'GET_SERVICE_INSTANCE',
);

our %EXPORT_TAGS = (AllConstants => \@EXPORT_OK);

use constant PREP_CLUSTER => {
   Type       => 'NSX',
   TestNSX    => "vsm.[1]",
   VDNCluster => {
      '[1]' => {
         cluster => "vc.[1].datacenter.[1].cluster.[1]",
      },
   },
};

use constant GET_DATASTORE => {
   Type      => "Host",
   TestHost  => "host.[1]",
   datastore => {
      '[1]' => {
         name => "vdnetSharedStorage",
      },
   },
};

use constant CREATE_SERVICE_MANAGER => {
   Type       => 'NSX',
   TestNSX    => "vsm.[1]",
   servicemanager => {
      '[1]' => {
         'name' => "ABC Company Service Manager $$",
         'description' => "ABC Company Service Manager Desc",
         'revision' => "4",
         'objecttypename' => "ServiceManager",
         'vendorname' => "ABC Vendor Name",
         'vendorid' => "ABC Vendor ID",
         'thumbprint' => "",
         'username' => "",
         'password' => "",
         'verifypassword' => "",
         'url' => "",
         'resturl' => "",
         'status' => "IN_SERVICE",
      },
   },
};

use constant CREATE_VENDOR_TEMPLATE => {
   Type       => 'Service',
   TestService    => "vsm.[1].service.[1]",
   vendortemplate => {
      '[1]' => {
         'name' => "ABC Company Vendor Template",
         'description' => 'ABC Company Vendor Template Description',
         'vendorid' => 'ABC Company Vendor Id',
         'vendorattributes' => [
         {
            'key' => 'Key 1',
            'name' => 'Value 1',
            'value' => 'Name 1',
         },
         {
            'key' => 'Key 2',
            'name' => 'Value 2',
            'value' => 'Name 2',
         },
         ],
      },
   },
};

use constant REMOVE_BINDING => {
   Type       => 'ServiceProfile',
   TestServiceProfile    => "vsm.[1].serviceprofile.[1]",
   serviceprofilebinding => {
      'virtualwires' => {
         'virtualwireid' => "",
      },
      'excludedvnics' => '',
      'virtualservers' => '',
      'distributedvirtualportgroups' =>{
         'string' => "",
      },
   },
};

use constant CHECK_DVFILTER => {
   'Type' => 'Command',
   'command' => 'summarize-dvfilter',
   'testhost' => 'host.[1]',
};

use constant CREATE_SERVICE => {
   Type       => 'NSX',
   TestNSX    => "vsm.[1]",
   service => {
      '[1]' => {
         'name' => "ABC Company Service",
         'servicemanager' => {
            'objectid' => "vsm.[1].servicemanager.[1]",
         },
         'implementations' => [
            {
               'type' => 'HOST_BASED_VNIC',
            }
         ],
         'transports' => [
         {
            'type' => 'VMCI',
         },
         ],
         'serviceattributes' => [
         {
            'key' => 'agentName',
            'name' => 'Agent Name',
            'value' => 'My_agent',
         },
         {
            'key' => 'failOpen',
            'name' => 'Fail Open',
            'value' => 'true',
         },
         {
            'key' => 'default-action',
            'name' => 'Default Action',
            'value' => 'ACTION_ACCEPT',
         },
         ],
         'vendortemplates' => '',
         'usedby' => '',
      },
   },
};

use constant CHECK_SVM_DEPLOYMENT_STATUS => {
   Type       => 'Service',
   TestService    => "vsm.[1].service.[1]",
   verifyendpointattributes => {
         'progressstatus[?]equal_to' => "SUCCEEDED",
   },
   noofretries  => "20",
};

use constant CHECK_SVM_UNDEPLOYMENT_STATUS => {
   Type       => 'Service',
   TestService    => "vsm.[1].service.[1]",
   verifyendpointattributes => {
      'progressstatus[?]equal_to' => undef,
   },
   noofretries  => "5",
};

use constant GET_SERVICE_PROFILE => {
   Type       => 'NSX',
   TestNSX    => "vsm.[1]",
   serviceprofile => {
      '[1]' => {
         'getserviceprofileflag' => "true",
         'serviceprofilename' => "ABC Company Service_ABC Company Vendor Template",
      },
   },
};

use constant DELETE_SERVICE_CLUSTER => {
   Type       => 'Service',
   TestService    => "vsm.[1].service.[1]",
   deleteclusterdeploymentconfigs => "vsm.[1].service.[1].clusterdeploymentconfigs.[1]",
};

use constant DELETE_SERVICE_PROFILE => {
   Type       => 'NSX',
   TestNSX    => "vsm.[1]",
   deleteserviceprofile => "vsm.[1].serviceprofile.[1]",
};

use constant DELETE_SERVICE_INSTANCE => {
   Type       => 'NSX',
   TestNSX    => "vsm.[1]",
   deleteserviceinstance => "vsm.[1].serviceinstance.[1]",
};

use constant DELETE_VENDOR_TEMPLATE => {
   Type       => 'Service',
   TestService    => "vsm.[1].service.[1]",
   deletevendortemplate => "vsm.[1].service.[1].vendortemplate.[1]",
};

use constant DELETE_SERVICE => {
   Type       => 'NSX',
   TestNSX    => "vsm.[1]",
   deleteservice => "vsm.[1].service.[1]",
};

use constant DELETE_SERVICE_MANAGER => {
   Type       => 'NSX',
   TestNSX    => "vsm.[1]",
   deleteservicemanager => "vsm.[1].servicemanager.[1]",
};

use constant GET_SERVICE_INSTANCE => {
   Type       => 'NSX',
   TestNSX    => "vsm.[1]",
   serviceinstance => {
      '[1]' => {
         'serviceid' => "vsm.[1].service.[1]",
      },
   },
};

