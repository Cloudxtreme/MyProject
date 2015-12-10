#!/usr/bin/perl
#########################################################################
# Copyright (C) 2014 VMWare, Inc.
# # All Rights Reserved
#########################################################################
package TDS::EsxServer::VDS::CommonWorkloads;

use FindBin;

# Export all workloads which are very common across all tests
use base 'Exporter';
our @EXPORT_OK = (
   'POWERON_VM',
   'POWEROFF_VM',
   'POWERON_VM1',
   'POWERON_VM2',
   'POWERON_VM3',
   'POWERON_VM4',
   'POWERON_VM5',
   'POWERON_VM6',
   'POWEROFF_VM1',
   'POWEROFF_VM2',
   'POWEROFF_VM3',
   'POWEROFF_VM4',
   'POWEROFF_VM5',
   'POWEROFF_VM6',
);
our %EXPORT_TAGS = (AllConstants => \@EXPORT_OK);
use constant POWERON_VM => {
   Type => "VM",
   TestVM => "vm.[-1]",
   vmstate  => "poweron",
};
use constant POWERON_VM1 => {
   Type => "VM",
   TestVM => "vm.[1]",
   vmstate  => "poweron",
};
use constant POWERON_VM2 => {
   Type => "VM",
   TestVM => "vm.[2]",
   vmstate  => "poweron",
};
use constant POWERON_VM3 => {
   Type => "VM",
   TestVM => "vm.[3]",
   vmstate  => "poweron",
};
use constant POWERON_VM4 => {
   Type => "VM",
   TestVM => "vm.[4]",
   vmstate  => "poweron",
};
use constant POWERON_VM5 => {
   Type => "VM",
   TestVM => "vm.[5]",
   vmstate  => "poweron",
};
use constant POWERON_VM6 => {
   Type => "VM",
   TestVM => "vm.[6]",
   vmstate  => "poweron",
};
use constant POWEROFF_VM => {
   Type => "VM",
   TestVM => "vm.[-1]",
   vmstate  => "poweroff",
};
use constant POWEROFF_VM1 => {
   Type => "VM",
   TestVM => "vm.[1]",
   vmstate  => "poweroff",
};
use constant POWEROFF_VM2 => {
   Type => "VM",
   TestVM => "vm.[2]",
   vmstate  => "poweroff",
};
use constant POWEROFF_VM3 => {
   Type => "VM",
   TestVM => "vm.[3]",
   vmstate  => "poweroff",
};
use constant POWEROFF_VM4 => {
   Type => "VM",
   TestVM => "vm.[4]",
   vmstate  => "poweroff",
};
use constant POWEROFF_VM5 => {
   Type => "VM",
   TestVM => "vm.[5]",
   vmstate  => "poweroff",
};
use constant POWEROFF_VM6 => {
   Type => "VM",
   TestVM => "vm.[6]",
   vmstate  => "poweroff",
};

1;
