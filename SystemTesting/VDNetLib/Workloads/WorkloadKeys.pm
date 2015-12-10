#!/usr/bin/perl
########################################################################
# Copyright (C) 2011 VMWare, Inc.
# # All Rights Reserved
########################################################################
package VDNetLib::Workloads::WorkloadKeys;

#
# This file contains the key value pairs supported by all the workloads
# In the future, the contents of this file can be accessed through the
# vdNet cmd line.
#

use strict;
use warnings;
use Text::Table;
use Text::Wrap qw(wrap);

$Text::Wrap::columns = 60;
$Text::Wrap::break = '[\s:]';

my $exitVal = new VDNetLib::Common::GlobalConfig;
my $EXIT_SUCCESS = $exitVal->GetExitValue("EXIT_SUCCESS");
my $EXIT_FAILURE = $exitVal->GetExitValue("EXIT_FAILURE");
my $WorkloadKeys;

#
# Constant Hashes Common to all workloads
#
use constant ITERATIONS => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "1",
         valuetype       => "specific",
         supportedvalues => "1 or 2 or N",
         dependentkey    => "",
         notes           => "Number of times the workload should be executed"
};

use constant MAX_TIMEOUT => {
         keytype         => "management",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "3600", # Default workload timeout in GlobalConfig.pm
         valuetype       => "specific",
         supportedvalues => "1 or 2 or N",
         dependentkey    => "",
         notes           => "Time parent will wait for the child to finish execution"
};

use constant VERIFICATION => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "none",
         valuetype       => "string",
         supportedvalues => "",
         valueformat     => "Name_of_verification_hash",
         dependentkey    => "",
         notes           => "To call a verification hash or another workload as verification",
};

use constant SLEEP_BETWEEN_COMBOS => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "none",
         valuetype       => "integer",
         supportedvalues => "1, 2 .. N",
         valueformat     => "",
         dependentkey    => "",
         notes           => "To sleep for the number of seconds specified between each combination. ".
                            "It also sleeps before the first combination",
};

use constant SLEEP_BETWEEN_OPERATIONS => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "none",
         valuetype       => "integer",
         supportedvalues => "1, 2 .. N",
         valueformat     => "",
         dependentkey    => "",
         notes           => "To sleep between each operation for the number of seconds specified. ".
                            "It also sleeps before the first operation",
};


########################################################################
#
# PrintKeys -- Lists all workload Key Value pairs
#
# Input:
#       None
#
# Results:
#      Prints the key/value pair documentation to stdout
#
# Side effects:
#      None
#
########################################################################

sub PrintKeys()
{
   my $packageName  = shift;
   my $workloadName = shift;
   my $tb = Text::Table->new(\" ", "Key ", "Value");

   for my $workload (sort keys %$WorkloadKeys) {
      #
      # If WorkloadName is defined then display keys of that workload only
      #
      if ((defined $workloadName) && ($workloadName !~ /all/i)) {
         next if $workloadName !~ /$workload/i;
      }
      $tb->add(" ");
      $tb->add(" ");
      $tb->add("======== $workload Workload Keys ======= ");
      $tb->add(" ");

      for my $operation (sort keys %{$WorkloadKeys->{$workload}}) {

         $tb->rule('-');
         $tb->add($operation . " (" .
                  $WorkloadKeys->{$workload}->{$operation}->{requirement} . "," .
                  $WorkloadKeys->{$workload}->{$operation}->{valuetype} . ")" ,
                  wrap("", "", "=\>  " .
                       $WorkloadKeys->{$workload}->{$operation}->{supportedvalues}));
         $tb->add(" ", wrap("", "# ", "# " .
                            $WorkloadKeys->{$workload}->{$operation}->{notes}));

         if ("" ne $WorkloadKeys->{$workload}->{$operation}->{dependentkey}){
            $tb->add(" ", "\*\* Depends on key: " .
                     wrap("", "", "",
                          $WorkloadKeys->{$workload}->{$operation}->{dependentkey}));
         }

         if ("yes" eq $WorkloadKeys->{$workload}->{$operation}->{takesdefault}){
            $tb->add(" ", "\*\* Default value: " .
                  $WorkloadKeys->{$workload}->{$operation}->{defaultvalue});
         }
         $tb->add(" ");
      }
      print $tb->body;
      $tb->clear();
   }

   exit $EXIT_SUCCESS;
}

#
#
# Information about the workload key value pairs to be maintained here
#
#

$WorkloadKeys = {

   # VM Workload details
   VM => {
      # Management Keys
      type => {
         keytype         => "management",
         requirement     => "mandatory",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "VM",
         dependentkey    => "",
         notes           => "Indicates the Workload being used",
      },

      target => {
         keytype         => "management",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "SUT",
         valuetype       => "list",
         supportedvalues => "SUT or helperN",
         valueformat     => "Comma separated target names",
         dependentkey    => "",
         notes           => "Point to single VM instance"
      },

      operation => {
         keytype         => "management",
         requirement     => "mandatory",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "list",
         supportedvalues => "validatemac, poweron, poweroff, reset, shutdown, suspend, hibernate, killvm, killallpbyname, resume, createsnap, revertsnap, rmsnap, snapshotname, hotaddvnic, hotremovevnic, addpcipassthruvm, removepcipassthruvm, changeportgroup, netdumperservice, cleanupnetdumperlogs, initiatenetdumpserver, checknetdumpstatus, verifynetdumperconfig, configurenetdumpserver ",
         valueformat     => "Comma separated names of operations",
         dependentkey    => "",
         notes           => "Indicate the operations that need to be executed"
      },

      allocschema => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "no",
         valuetype       => "specific",
         supportedvalues => "oui, prefix, range ",
         dependentkey    => "",
         notes           => "Indicate the MAC Scheme that is set on VC"
      },

      iterations  => ITERATIONS,

      testadapter  => {
         keytype         => "management",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "1",
         valuetype       => "list",
         supportedvalues => "1,2,3,N",
         dependentkey    => "target",
         notes           => "Comma separated values indicating the vnic indices. This key is used to indicate a target vnic for operations like, hotaddvnic, hotremovevnic, addpcipassthruvm, removepcipassthruvm, changeportgroup,set,deletevmknic,verifynetdumpclient,"
      },
      supportadapter  => {
         keytype         => "management",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "list",
         supportedvalues => "SUT:vmknic:<x>,helper<x>:vmknic:<x>",
         dependentkey    => "target",
         notes           => "Comma separated values indicating the vmknic/vnic indices. This key is used to indicate a target vnic for operations like set,verifynetdumpclient,"
      },

      passthrough  => {
         keytype         => "management",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "UPT",
         dependentkey    => "",
         notes           => "A specific VSI node is checked for transition"
      },

      anchor  => {
         keytype         => "management",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "String",
         dependentkey    => "",
         notes           => "Name of Anchor used to setup STAF Session with ESX host."
      },

      snapshotname => {
         keytype         => "management",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "autogen (vdnet-*)",
         valuetype       => "specific",
         supportedvalues => "string",
         dependentkey    => "target",
         notes           => "Can be used to specify the snapshot name for createsnap, revertsnap and rmsnap. If this key isn't used, the name is autogenerated and reused for further operations"
      },

      # Operational Keys

      killallpbyname  => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "list",
         supportedvalues => "name of process",
         dependentkey    => "target",
         notes           => "This can be used to kill processes in the guest"
      },
      netdumpparam {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues =>
		"port,configpat,logpath,datapath,corepath,".
		"logfile,serviceip,debug,maxsize",
         dependentkey    => "setnetdumpserver",
      },
      netdumpvalue {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "string|numeric",
         dependentkey    => "setnetdumpserver",
      },
      netdumpclientip {
         keytype         => "test",
         requirement     => "mandatory",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "ip address (ipv4)",
         dependentkey    => "",
      },
      action {
         keytype         => "test",
         requirement     => "mandatory",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "start,stop",
         dependentkey    => "",
      }
   },

   Switch  => {

      type => {
         keytype         => "management",
         requirement     => "mandatory",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "Switch",
         dependentkey    => "",
         notes           => "Indicates the workload being used"
      },

      Target => {
         keytype         => "management",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "SUT",
         valuetype       => "list",
         supportedvalues => "SUT or helperN",
         valueformat     => "Comma separated target names",
         dependentkey    => "",
         notes           => "Point to single VM/ESX instance"
      },

      switchtype => {
         keytype         => "management",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "vswitch",
         valuetype       => "specific",
         supportedvalues => "vswitch|vds|pswitch",
         dependentkey    => "",
         notes           => "Indicates the type of switch used in the operation"
      },

      switchaddress => {
         keytype         => "management",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "name or ip address",
         dependentkey    => "",
         notes           => "Mandatory for pswitch, optional for VDS/VSS. If the switch is a pswitch, then an IP address is needed. For vds/vswitch a name is required."
      },

      datacenter => {
         keytype         => "management",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "string",
         dependentkey    => "switchtype",
         notes           => "Used to indicate the name of a datacenter, MANDATORY if switchtype is vds"
      },

      inttype => {
         keytype         => "management",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "vnic",
         valuetype       => "specific",
         supportedvalues => "vnic, vmknic",
         dependentkey    => "TestAdapter",
         notes           => "Interface type attached to the switch that is the target of the operation",
      },

      TestAdapter => {
         keytype         => "management",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "1",
         valuetype       => "specific",
         supportedvalues => "1/2/N",
         dependentkey    => "",
         notes           => "Needs to be an index to a network interface (vnic|vmknic), whose portgroup and associated switch will be used for the operation"
      },

      TestPG => {
         keytype         => "management",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "1/2/N",
         dependentkey    => "",
         notes           => "Index number for the portgroup and associated switch that will be used for the operation ",

      },

      TestSwitch => {
         keytype         => "management",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "1",
         valuetype       => "specific",
         supportedvalues => "1/2/N",
         dependentkey    => "",
         notes           => "Index number for the switch that will be used for the operation ",

      },

      Version => {
         keytype         => "management",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "",
         dependentkey    => "Switchtype",
         notes           => "VDS Only. XXX Not Implemented: Indicate version of switch to be used",

      },

     # Operation keys

      VLAN => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "1-4095",
         dependentkey    => "TestAdapter, TestPG",
         notes           => "Indicate a valid VLAN id that can be configured on a portgroup. TestAdapter or TestPG could be used to identify the portgroup.",
      },

      MTU => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "1-9000",
         dependentkey    => "switchname",
         notes           => "This would set the switch mtu to a specific value along with all the pnics connected to the vswitch. Switch name or the index could be used to identify the switch: VDS/VSS",
      },

      CDP => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "listen, advertise, both, none, down",
         dependentkey    => "",
         notes           => "Manipulate CDP status on all the types of switches. Use \"none\" to disable on physical switch",
      },

      LLDP => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "listen, advertise, both, none",
         dependentkey    => "",
         notes           => "Manipulate LLDP status on all the types of switches. VSS doesn't support LLDP. Use \"none\" to disable on physical switch",
      },

      PortStatus => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "enable, disable",
         dependentkey    => "VmnicAdapter",
         notes           => "Can only work on a pswitch on port indicated by vmnicAdapter",
      },

      VmnicAdapter => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "1|2|N",
         dependentkey    => "portstatus, configureunlinks",
         notes           => "Indicate the physical adapter on which the operation needs to be performed",
      },

      createdvportgroup => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "string",
         dependentkey    => "nrp, binding, TestSwitch, switchtype",
         notes           => "Only VDS. Create a DV Portgroup of a particular name on the indicated TestSwitch while indicating the type of binding and resource pool name",
      },

      removedvportgroup => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "string",
         dependentkey    => "TestSwitch, switchtype",
         notes           => "Only VDS. Remove a DV Portgroup on the TestSwitch indicating the name."
      },

      addportodvportgroup => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "1",
         valuetype       => "list",
         supportedvalues => "String: Name of DV Portgroup",
         dependentkey    => "TestSwitch, Ports, switchtype",
         notes           => "Only VDS. Add a DV Portgroup on the TestSwitch indicating the name."
      },

      Ports => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "1",
         valuetype       => "specific",
         supportedvalues => "1/2/N",
         dependentkey    => "testswitch, addporttodvportgroup",
         notes           => "Only VDS. Indicates the number of ports to be added to the DVPG"
      },

      editmaxports => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "1",
         valuetype       => "specific",
         supportedvalues => "1-1024",
         dependentkey    => "TestSwitch, Target",
         notes           => "Now only for VDS. Edit maximum number of ports for host"
      },

      nrp => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "string",
         dependentkey    => "createdvportgroup",
         notes           => "Only VDS. Indicates the name of the network resource pool for the VDS",
      },

      binding => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "early, late, ephemeral",
         dependentkey    => "createdvportgroup",
         notes           => "Only VDS. Indicates the type of binding for a DVPG",
      },


      configureportgroup => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "list",
         supportedvalues => "add, delete",
         dependentkey    => "TestSwitch, switchtype, pgname, pgnumber",
         notes           => "Only VSS. Add/Remove portgroup on a vswitch indicated by TestSwitch with the name."
      },

      pgname => {
         keytype         => "test",
         requirement     => "mandatory",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "string",
         dependentkey    => "TestSwitch, switchtype, configureportgroup",
         notes           => "Only VSS. Name of portgroup Mandatory for add/remove operation of vswitch."
      },

      pgnumber => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "1/2/N",
         dependentkey    => "TestSwitch, switchtype, configureportgroup",
         notes           => "Only VSS. Indicate the nubmer of PGs to add or remove."
      },

      setmacaddresschange => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "list",
         supportedvalues => "enable, disable",
         dependentkey    => "TestSwitch, switchtype, dvportgroup",
         notes           => "Enable/Disable macaddress changes in switches. if the switch is a vds, then the name of the dvportgroup is required."
      },

      dvportgroup => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "string",
         dependentkey    => "TestSwitch, switchtype, setmacaddresschange, setforgedtransmit",
         notes           => "Only VDS. Indicate the name of the DV portgroup for allowing mac address changes, forging transmits and allowing promiscuous mode on ports on switches and migrating management network to VSS"
      },

      setforgedtransmit => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "list",
         supportedvalues => "enable, disable",
         dependentkey    => "TestSwitch, switchtype, dvportgroup",
         notes           => "Enable/Disable ability to forge transmit in switches. if the switch is a vds, then the name of the dvportgroup is required."
      },

      setBeacon => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "list",
         supportedvalues => "enable, disable",
         dependentkey    => "TestSwitch, switchtype, dvportgroup",
         notes           => "VSS only. Enable/Disable ability to probe beacon in switches."
      },

      configureuplinks => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "list",
         supportedvalues => "add, delete",
         dependentkey    => "TestSwitch, switchtype, vmnicadapter",
         notes           => "VSS only. Add/Delete uplink pointed by the key vmnicadapter to switches."

      },

      setnicteaming => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "list",
         supportedvalues => "add, delete",
         dependentkey    => "TestSwitch, switchtype, vmnicadapter, failback, lbpolicy, failuredetection, notifyswitch",
         notes           => "VSS only. Creating a team of vmnics in a switch."
      },

      failback => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "true, false",
         dependentkey    => "TestSwitch, switchtype, setnicteaming",
         notes           => "VSS only. Indicate failback options for the team of nics"
      },

      lbpolicy  => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "portid, iphash, mac, explicit",
         dependentkey    => "TestSwitch, switchtype, vmnicadapter",
         notes           => "VSS only. Indicate the load balancing policy for the team of nics"
      },

      failuredetection => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "list",
         supportedvalues => "link, beacon",
         dependentkey    => "TestSwitch, switchtype, vmnicadapter",
         notes           => "VSS only. Indicate method of failure detection in the team of nics."
      },

      notifyswitch => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "true, false",
         dependentkey    => "TestSwitch, switchtype, vmnicadapter",
         notes           => "VSS only. Enable/Disable notification to the switch."
      },

      quealloc => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "Check",
         dependentkey    => "TestPG, switchtype",
         notes           => "Checks the the vmnic is allocated a queue in a nic supporting HW LRO"
      },

      chkhwswlro  => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "N",
         valuetype       => "specific",
         supportedvalues => "Y|N",
         dependentkey    => "TestPG, switchtype, quealloc",
         notes           => "Check that enabling/disabling HW LRO causes the same behavior in SW LRO."
      },

      setfailoverorder  => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "1+2+3+N",
         dependentkey    => "TestSwitch, switchtype",
         notes           => "VSS only. Set the failover order using the indices of vmcnis"
      },


      avgbandwidth  => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "Number in Bits/Sec",
         dependentkey    => "TestSwitch, switchtype, settrafficshaping",
         notes           => "Average bandwidth in Bits/Sec"
      },

      peakbandwidth  => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "Number in Bits/Sec",
         dependentkey    => "TestSwitch, switchtype, settrafficshaping",
         notes           => "Peak bandwidth in Bits/Sec"
      },

      burstsize  => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "Number in Bytes",
         dependentkey    => "TestSwitch, switchtype, settrafficshaping",
         notes           => "Maximum burst size in Bytes"
      },

      settrafficshaping  => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "list",
         supportedvalues => "enable, disable",
         dependentkey    => "TestSwitch, switchtype, avgbandwidth, peakbandwidth, burstsize",
         notes           => "VSS only. Enable traffic shaping with the indicated values."
      },

      enableinshaping  => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "list",
         supportedvalues => "name of DVPG",
         dependentkey    => "TestSwitch, switchtype, avgbandwidth, peakbandwidth, burstsize",
         notes           => "VDS only. Enable traffic shaping with the indicated values."
      },

      disableinshaping  => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "list",
         supportedvalues => "name of DVPG",
         dependentkey    => "TestSwitch, switchtype, avgbandwidth, peakbandwidth, burstsize",
         notes           => "VDS only. Disable traffic shaping."
      },

      enableoutshaping  => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "list",
         supportedvalues => "name of DVPG",
         dependentkey    => "TestSwitch, switchtype, avgbandwidth, peakbandwidth, burstsize",
         notes           => "VDS only. Enable traffic shaping with the indicated values."
      },

      disableoutshaping  => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "list",
         supportedvalues => "name of DVPG",
         dependentkey    => "TestSwitch, switchtype, avgbandwidth, peakbandwidth, burstsize",
         notes           => "VDS only. Disable traffic shaping."
      },

     portgroup => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "string",
         dependentkey    => "TestSwitch, switchtype, setmacaddresschange, setforgedtransmit",
         notes           => "Only VSS. Indicate the name of the portgroup for allowing mac address changes, forging transmits and allowing promiscuous mode on ports on switches and migrating management network to VDS."
      },

     migratemgmtnettovds => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "string: name of DVPG",
         dependentkey    => "TestSwitch, portgroup",
         notes           => "Migrate the management network from a PG to DVPG. DVPG name is given as parameter. "
      },

     migratemgmtnettovss => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "SUT or Helper1 or Helper2 or HelperN",
         dependentkey    => "TestSwitch, portgroup, dvportgroup",
         notes           => "Migrate the management network from a DVPG to PG. Target is given as parameter. Assumes that the PG & VSS with indicated names have already been created."
      },

     vss => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "string",
         dependentkey    => "TestSwitch, migratemgmtnettovss",
         notes           => "Only VSS. Indicate the name of the portgroup for allowing mac address changes, forging transmits, enabling promiscuous mode on ports on switches and migrating management network to VDS."
      },

     blockport => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "Number | String indicating interface SUT:vnic:1",
         dependentkey    => "TestSwitch, portgroup",
         notes           => "VDS Only. Block port by indicating either a port number or an interface that the port is connected to. The portgroup can be used to indicate either the index of the DVPG or the name"
      },

     unblockport => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "Number | String indicating interface SUT:vnic:1",
         dependentkey    => "TestSwitch, portgroup",
         notes           => "VDS Only. Block port by indicating either a port number or an interface that the port is connected to. The portgroup can be used to indicate either the index of the DVPG or the name"
      },

     enablenetiorm => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "1",
         dependentkey    => "TestSwitch, switchtype",
         notes           => "VDS Only. Enable netiorm on the VDS"
      },

     disablenetiorm => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "1",
         dependentkey    => "TestSwitch, switchtype",
         notes           => "VDS Only. Disable netiorm on the VDS"
      },

     accessvlan => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "Valid VLAN ID",
         dependentkey    => "TestSwitch, portgroup, vmnicadapter",
         notes           => "VDS & pSwitch only. Sets the access vlan id",
      },

     nativevlan => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "list",
         supportedvalues => "[0-4094]",
         dependentkey    => "TestSwitch, trunkrange, vmnicadapter",
         notes           => "VDS & pSwitch Only. Configures the VLANS on the port associated with vmnicadapter ",
      },

     vlanrange => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "list",
         supportedvalues => "[M-N]",
         dependentkey    => "TestSwitch, trunkrange, port",
         notes           => "pSwitch Only. Configures the VLANS on the port associated with vmnicadapter ",
      },

     trunkrange => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "range",
         supportedvalues => "[NNN - NNN]",
         dependentkey    => "TestSwitch, portgroup, vmnicadapter, nativevlan, vlanrange",
         notes           => "VDS & pSwitch only. To set the range on the uplink DVPG, set portgroup to \"Uplink\". nativevlan & vlanrange can be provided for pSwitch" ,
      },

     addpvlanmap => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "community, promiscuous, isolated",
         dependentkey    => "TestSwitch, primaryVLAN, secondaryVLAN",
         notes           => "VDS Only. Add a pvlan map.",
      },

     primaryvlan => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "Valid VLAN ID",
         dependentkey    => "TestSwitch, addpvlanmap, secondaryVLAN",
         notes           => "VDS Only. Indicate the primary VLAN ID.",
      },

     secondaryvlan => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "Valid VLAN ID",
         dependentkey    => "TestSwitch, primaryVLAN, addpvlanmap",
         notes           => "VDS Only. Indicate the secondary VLAN ID.",
      },

     pvlan => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "Valid VLAN ID",
         dependentkey    => "TestSwitch, setpvlantype",
         notes           => "VDS Only. Indicate the PVLAN ID.",
      },

     setpvlantype => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "name of existing DVPG",
         dependentkey    => "TestSwitch, pvlan",
         notes           => "VDS Only. Add PVLAN map to an existing DVPG",
      },

     setlldptransmitport => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "name of existing DVPG",
         dependentkey    => "TestSwitch, vmnicadapter",
         notes           => "pSwitch Only. Enables/Disables the LLDP transmit interface state on a specific pswitch port associated with vmnicadapter",
      },

     setlldpreceiveport => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "name of existing DVPG",
         dependentkey    => "TestSwitch, vmnicadapter",
         notes           => "pSwitch Only. Enables/Disables the LLDP receive interface state on a specific pswitch port associated with vmnicadapter",
      },

     checklldponesx => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "yes",
         valuetype       => "specific",
         supportedvalues => "yes|no",
         dependentkey    => "TestSwitch, vmnicadapter",
         notes           => "YES indicates that LLDP info is expected on a particular vmnic and will be verified. NO indicates that ther would be no lldp info available.",
      },

     checkcdponesx => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "yes",
         valuetype       => "specific",
         supportedvalues => "yes|no",
         dependentkey    => "TestSwitch, vmnicadapter",
         notes           => "YES indicates that CDP info is expected on a particular vmnic and will be verified. NO indicates that ther would be no CDP info available.",
      },

     verifyactivevmnic => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "Index of VMNic to be tested",
         dependentkey    => "TestSwitch",
         notes           => "Verifies that the vmnic indicated by the index is active",
      },

     verifyvnicswitchport => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "Index of pSwitch",
         dependentkey    => "TestSwitch",
         notes           => "pSwitch only. Gets the mac address table of a physical switch ",
      },

     confignetflow => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "IP address of ipfix collector",
         dependentkey    => "TestSwitch, vdsip, internal, idletimeout, collectorport, activetimeout, sampling",
         notes           => "VDS Only. Configures netflow on switch.",
      },

     vdsip => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "IP address(IPv4)",
         dependentkey    => "TestSwitch, confignetflow",
         notes           => "VDS only. IP of VDS switch",
      },

     internal => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "false",
         valuetype       => "specific",
         supportedvalues => "true|false",
         dependentkey    => "TestSwitch, confignetflow",
         notes           => "VDS only. Set to true if traffic analysis should be limited to the internal traffic.",
      },

     idletimeout => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "15 secs",
         valuetype       => "specific",
         supportedvalues => "Number in secs",
         dependentkey    => "TestSwitch, confignetflow",
         notes           => "VDS only. Timeout after which idle flows are exported to ipfix collector.",
      },

     activeTimeout  => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "60 secs",
         valuetype       => "specific",
         supportedvalues => "Number in secs",
         dependentkey    => "TestSwitch, confignetflow",
         notes           => "VDS only. Timeout after which active flows are exported to ipfix collector.",
      },

     collectorport => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "Port Number",
         dependentkey    => "TestSwitch, confignetflow",
         notes           => "VDS only. Port of ipfix collector",
      },

     sampling => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "Ratio",
         dependentkey    => "TestSwitch, confignetflow",
         notes           => "VDS only. Ratio of the total packets to the number of packets analysed.",
      },

     addmirrorsession => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "String",
         dependentkey    => "TestSwitch, srctxport, srcrxport, dstuplink, desc, dstport, stripvlan, enabled, dstpg, length, srcrxpg, srctxpg, normaltraffic, encapvlan, srctxwc, srcrxwc, " .
                            "sessiontype, mirrorversion, samplingrate, erspanip, srcvlan",
         notes           => "VDS only. Create a DV Mirror Session with a name",
      },

     editmirrorsession => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "String",
         dependentkey    => "TestSwitch, srctxport, srcrxport, dstuplink, desc, dstport, stripvlan, enabled, dstpg, length, srcrxpg, srctxpg, normaltraffic, encapvlan, srctxwc, srcrxwc, ".
                            "sessiontype, mirrorversion, samplingrate, erspanip, srcvlan",
         notes           => "VDS only. Edit a DV Mirror Session with a given name",
      },

     removemirrorsession => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "String",
         dependentkey    => "TestSwitch, srctxport, srcrxport, dstuplink, desc, dstport, stripvlan, enabled, dstpg, length, srcrxpg, srctxpg, normaltraffic, encapvlan, srctxwc, srcrxwc",
         notes           => "VDS only. Remove a DV Mirror Session with a given name",
      },
      configurehealthcheck => {
         keytype => "test",
         requiremetnt => "optional",
         takesdefault => "no",
         defaultvalue => "",
         valuetype => "vlanmtu or teaming",
         supportedvalues => "string",
         dependentkey => "TestSwitch, operation, interval",
         notes => "VDS Only, It configures the vlanmtu check or teaming check for the given vds",
      },
   },

   # Traffic workload details
   Traffic => {
      # Management Keys
      type => {
         keytype         => "management",
         requirement     => "mandatory",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "Traffic",
         dependentkey    => "",
         notes           => "Indicates that Traffic Workload is being used",
      },

      iterations  => ITERATIONS,

      maxtimeout  => MAX_TIMEOUT,

      verification => VERIFICATION,

      noofinbound => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "integer",
         supportedvalues => "1, 2 or N",
         valueformat     => "specific",
         dependentkey    => "",
         notes           => "No of RX traffic session to be executed in parallel, ".
                            "TestAdapter key's value(SUT:vnic:1) will be traffic ".
                            "server and SupporteAdapter key's value will be traffic client."
      },

      noofoutbound => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "1",
         valuetype       => "integer",
         supportedvalues => "1, 2 or N",
         valueformat     => "specific",
         dependentkey    => "",
         notes           => "No of TX traffic session to be executed in parallel, ".
                            "TestAdapter key's value(SUT:vnic:1) will be traffic ".
                            "client and SupporteAdapter key's value will be traffic server."
      },

      connectivitytest => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "1",
         valuetype       => "integer",
         supportedvalues => "0 and 1",
         valueformat     => "specific",
         dependentkey    => "",
         notes           => "Indicate if ping connectivity test should be performed ".
                            "before each combination of traffic",
      },

      testadapter => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "SUT:vnic:1",
         valuetype       => "string",
         supportedvalues => "MACHINENAME:ADAPTER_TYPE:ADAPTER_INDEX",
         valueformat     => "specific,list",
         dependentkey    => "",
         notes           => "Points to a specific node on a specific machine which ".
                            "will take part in traffic flow E.g. SUT:vnic:1,SUT:vmknic:1,".
                            "helper1:vnic:1,etc"
      },

      supportadapter => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "helper1:vnic:1",
         valuetype       => "specific,list",
         supportedvalues => "MACHINENAME:ADAPTER_TYPE:ADAPTER_INDEX",
         valueformat     => "Comma separated targets",
         dependentkey    => "",
         notes           => "Points to a specific node on a specific machine which ".
                            "will take part in traffic flow E.g. SUT:vnic:1,".
                            "SUT:vmknic:1,helper1:vnic:1,etc"
      },

      sleepbetweencombos => SLEEP_BETWEEN_COMBOS,

      sleepbetweenoperations => SLEEP_BETWEEN_OPERATIONS,

      parallelsession => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "no",
         valuetype       => "string",
         supportedvalues => "yes and no",
         valueformat     => "",
         dependentkey    => "NoOfInbound and NoOfOutbound should be 1 or more",
         notes           => "By default the inbound and outbound session are ".
                            "executed sequentially. If this flag is set to yes ".
                            "then they are executed parallely. Another way to ".
                            "achieve this is writing two workload hashes for ".
                            "inbound and outbound and running them in parallel.",
      },

      toolname => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "netperf",
         valuetype       => "string",
         supportedvalues => "netperf,iperf,ping",
         valueformat     => "specific,list",
         dependentkey    => "",
         notes           => "Tool that is to be used for generating traffic",
      },

      bursttype => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "stream",
         valuetype       => "string",
         supportedvalues => "stream,rr",
         valueformat     => "specific,list",
         dependentkey    => "",
         notes           => "Tool that is to be used for generating traffic",
      },

      localsendsocketsize => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "integer",
         supportedvalues => "1 2 .. N",
         valueformat     => "specific,list,range",
         dependentkey    => "",
         notes           => "To set the send socket size on local host where ".
                            "traffic client is running",
      },

      remotesendsocketsize => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "integer",
         supportedvalues => "1 2 .. N",
         valueformat     => "specific,list,range",
         dependentkey    => "",
         notes           => "To set the send socket size on remote host where".
                            " traffic server is running",
      },

      localreceivesocketsize => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "integer",
         supportedvalues => "1 2 .. N",
         valueformat     => "specific,list,range",
         dependentkey    => "",
         notes           => "To set the receive socket size on local host ".
                            "where traffic client is running",
      },

      remotereceivesocketsize => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "integer",
         supportedvalues => "1 2 .. N",
         valueformat     => "specific,list,range",
         dependentkey    => "",
         notes           => "To set the send socket size on local host where".
                            " traffic server is running",
      },

      sendmessagesize => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "integer",
         supportedvalues => "1 2 .. N",
         valueformat     => "specific,list,range",
         dependentkey    => "",
         notes           => "To set the send message size on local host ".
                            "where traffic client is running",
      },

      receivemessagesize => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "integer",
         supportedvalues => "1 2 .. N",
         valueformat     => "specific,list,range",
         dependentkey    => "",
         notes           => "To set the receive message size on local host ".
                            "where traffic client is running",
      },

      requestsize => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "integer",
         supportedvalues => "1 2 .. N",
         valueformat     => "specific,list,range",
         dependentkey    => "bursttype => rr",
         notes           => "To set the request size on local host where ".
                            "traffic client is running",
      },

      responsesize => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "integer",
         supportedvalues => "1 2 .. N",
         valueformat     => "specific,list,range",
         dependentkey    => "bursttype => rr",
         notes           => "To set the response size on local host where ".
                            "traffic client is running",
      },

      routingscheme => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "unicast",
         valuetype       => "string",
         supportedvalues => "unicast,multicast,broadcast,flood",
         valueformat     => "specific,list",
         dependentkey    => "toolname => iperf in case of multicast. ".
                            "toolname => ping in case of broadcast and flood",
         notes           => "To set the response size on local host where".
                            " traffic client is running",
      },

      bindingenable => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "integer",
         supportedvalues => "0 1",
         valueformat     => "specific",
         dependentkey    => "toolname => iperf ",
         notes           => "To set the flag to set the host binding enabled on server",
      },

      testduration => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "5",
         valuetype       => "integer",
         supportedvalues => "1 2 .. N",
         valueformat     => "specific",
         dependentkey    => "",
         notes           => "Duration for which we run the test",
      },

      l3protocol => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "ipv4",
         valuetype       => "string",
         supportedvalues => "ipv4,ipv6",
         valueformat     => "specific,list",
         dependentkey    => "",
         notes           => "L3 Protocol type",
      },

      l4protocol => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "yes",
         defaultvalue    => "tcp",
         valuetype       => "string",
         supportedvalues => "tcp,udp",
         valueformat     => "specific,list",
         dependentkey    => "",
         notes           => "L3 Protocol type",
      },

      alterbufferalignment => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "string",
         supportedvalues => "send,recv",
         valueformat     => "specific,list,range",
         dependentkey    => "",
         notes           => "Alter the buffer alignment of send or recv data",
      },

      dataintegritycheck => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "enable",
         defaultvalue    => "enable",
         valuetype       => "string",
         supportedvalues => "enable,disable",
         valueformat     => "specific",
         dependentkey    => "",
         notes           => "VMware's data integrity check in netperf and ".
                            "iperf binaries. Is enabled by default",
      },

      multicasttimetolive => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "integer",
         supportedvalues => "1 2 .. N",
         valueformat     => "specific",
         dependentkey    => "",
         notes           => "Multicast Time to Live value",
      },

      udpbandwidth => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "integer",
         supportedvalues => "1 2 .. N",
         valueformat     => "specific",
         dependentkey    => "",
         notes           => "UDP Bandwidth size in MB",
      },

      pktfragmentation => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "string",
         supportedvalues => "yes,no",
         valueformat     => "specific",
         dependentkey    => "toolname => ping",
         notes           => "Whether to fragment packet or not",
      },

      pingpktsize => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "integer",
         supportedvalues => "1 2 .. N",
         valueformat     => "specific,list,range",
         dependentkey    => "toolname => ping",
         notes           => "Ping packet size",
      },

      tcpmss => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "integer",
         supportedvalues => "1 2 .. N",
         valueformat     => "specific,list,range",
         dependentkey    => "",
         notes           => "TCP MSS Size. This does not work with all traffic tools. ".
                            "User should not give toolname key and it will pick ".
                            "the appropriate tool",
      },

      tcpwindowsize => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "integer",
         supportedvalues => "1 2 .. N",
         valueformat     => "specific,list,range",
         dependentkey    => "",
         notes           => "TCP Window Size. This does not work with all traffic tools. ".
                            "User should not give toolname key and it will pick ".
                            "the appropriate tool",
      },

      iperfthreads => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "integer",
         supportedvalues => "1 2 .. N",
         valueformat     => "specific",
         dependentkey    => "",
         notes           => "Number of iperf threads to create.",
      },

      natedport => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "integer",
         supportedvalues => "1 2 .. N",
         valueformat     => "specific",
         dependentkey    => "",
         notes           => "Port number of the NAT route in between traffic ".
                            "server and client. Client is suppose to talk to ".
                            "NAT router's port in this case as it cannot ".
                            "talk to server port directly",
      },

      disablenagle => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "string",
         supportedvalues => "yes,no",
         valueformat     => "specific",
         dependentkey    => "",
         notes           => "Weather to disable enagle algorithm or not",
      },

      minexpresult => {
         keytype         => "test",
         requirement     => "mandatory",
         takesdefault    => "yes",
         defaultvalue    => "10 Mbps",
         valuetype       => "integer",
         supportedvalues => "1 2 .. N",
         valueformat     => "specific",
         dependentkey    => "",
         notes           => "Minimum expected result in Mbps for traffic ".
                            "tool and % for ping packet loss",
      },

      maxthroughput => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "integer",
         supportedvalues => "1 2 .. N",
         valueformat     => "specific",
         dependentkey    => "",
         notes           => "Maximum traffic throughput in Mbps",
      },
   },

   # VC workload details
   VC => {
      type => {
         keytype         => "management",
         requirement     => "mandatory",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "VC",
         dependentkey    => "",
         notes           => "Indicates the workload being used",
      },

      opt => {
         keytype         => "management",
         requirement     => "mandatory",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "String",
         dependentkey    => "",
         notes           => "Indicates the method being used",
      },

      host => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "SUT or helperN",
         dependentkey    => "",
         notes           => "Point to single VM instance",
      },

      vdsindex => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "1|2|N",
         dependentkey    => "",
         notes           => "Needs to be an index to a vds which will be used".
                            " for the operation",
      },

      pgname => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "String",
         dependentkey    => "",
         notes           => "dvportgroup name which will be used for the operation",
      },

      vdl2id => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "1|2|N",
         dependentkey    => "vdsindex",
         notes           => "vdl2 id which will be used for the operation",
      },

      mcastip => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "ip address (ipv4)",
         dependentkey    => "vdsindex",
         notes           => "multicast ip for a vdl2 network which will be used".
                            " for the operation",
      },

      vlanid => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "1-4095",
         dependentkey    => "",
         notes           => "Indicate a valid VLAN id which will be used for".
                            " the operation.",
      },

      ipaddr => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "ip address (ipv4)",
         dependentkey    => "",
         notes           => "vdl2 vmknic ip address which will be used for".
                            " the operation",
      },

      netmask => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "netmask (ipv4)",
         dependentkey    => "",
         notes           => "vdl2 vmknic netmask which will be used for the operation",
      },

      setdhcp => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "0|1",
         dependentkey    => "",
         notes           => "if or not using dhcp when creating a vdl2 vmknic",
      },

      udpport => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "1025-65535",
         dependentkey    => "",
         notes           => "udp port number for a host in vdl2 network",
      },

      networknum => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "1",
         valuetype       => "specific",
         supportedvalues => "1|2|N",
         dependentkey    => "vdsindex",
         notes           => "Used in vdl2 EsxCLI case. Specify how many vdl2".
                            " networks on the vds",
      },

      peernum => {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "1",
         valuetype       => "specific",
         supportedvalues => "1|2|N",
         dependentkey    => "vdl2id, vdsindex",
         notes           => "Used in vdl2 EsxCLI case. Specify how many vms of".
                            " other hosts in the vdl2 network",
      },

      # Management Keys
      allocschema => {
         keytype         => "management",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "string",
         supportedvalues => "oui, prefix, range",
         valueformat     => "specific",
         dependentkey    => "",
         notes           => "Indicate the MAC Scheme that should be set on VC ".
                            "or it set new scheme if no scheme on VC.",
      },
      macvalues => {
         keytype         => "management",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "string",
         supportedvalues => "XX:XX:XX-24, XX:XX:XX:XX:XX:XX-XX:XX:XX:XX:XX:XX",
         valueformat     => "range",
         dependentkey    => "allocschema",
         notes           => "Indiacate the value that should be set with VC ".
                            " MAC Scheme. Value of X can be 1 to F.",
      },
   },

   # Host workload details
   Host => {
      netdump => {
         keytype         => "test",
         requirement     => "mandatory",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues =>
		"set,configure,panicandreboot,backuphost,".
		"clientverify,netdumpesxclicheck",
         dependentkey    => "Host",
      },

      netdumpsvrip {
         keytype         => "test",
         requirement     => "mandatory",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "ip address (ipv4)",
         dependentkey    => "Host",
      },

      netdumpsvrport {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "1024-65535",
         dependentkey    => "Host",
      },

      paniclevel {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "1",
         valuetype       => "specific",
         supportedvalues => "1|2|N",
         dependentkey    => "panicandreboot",
      },

      panictype {
         keytype         => "test",
         requirement     => "optional",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "Panic",
         dependentkey    => "panicandreboot",
      },

      netdumpstatus {
         keytype         => "test",
         requirement     => "mandatory",
         takesdefault    => "no",
         defaultvalue    => "",
         valuetype       => "specific",
         supportedvalues => "true,false",
         dependentkey    => "verifynetdumpclient,configure",
      },

   },
};


