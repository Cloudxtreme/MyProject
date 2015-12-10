use strict;
use warnings;
use VDNetLib::VMOperations::VMOperations;

my %test_localworkstation = (
   hostType => "windows",        # or linux
   host     => "10.20.82.11",    # Uses Remote Agent and then HostedVMOperations

   #   		     host =>     "localhost",    # Directly uses HostedVMOperations
   vmx => "F://MyVirtualMachines//MasterC//MasterC.vmx",
);

my $mytestscriptobj =
   VDNetLib::VMOperations::VMOperations->new( \%test_localworkstation );

my $ret;
$ret = $mytestscriptobj->VMOpsPowerOn();
if ( $ret eq "SUCCESS" ) { print "Power on Passed\n" }
if ( $ret eq "FAILURE" ) { print "Failed \n" }
if ( not defined $ret ) { print "ret variable is undefined \n" }

$ret = $mytestscriptobj->VMOpsSuspend();
if ( $ret eq "SUCCESS" ) { print "Suspend Passed\n" }
if ( $ret eq "FAILURE" ) { print "Failed \n" }
if ( not defined $ret ) { print "ret variable is undefined \n" }

($ret) = $mytestscriptobj->VMOpsResume();
if ( $ret eq "SUCCESS" ) { print "Resume Passed\n" }
if ( $ret eq "FAILURE" ) { print "Failed \n" }
if ( not defined $ret ) { print "ret variable is undefined \n" }

#my $mac = "";
#$ret = $mytestscriptobj->VMOpsConnectvNICCable($mac);
#if ($ret eq "SUCCESS"){	print "Connect vNIC Passed\n" }
#if ($ret eq "FAILURE") { print "Failed \n" }
#if (not defined $ret ) { print "ret variable is undefined \n" }
#
#$ret =	$mytestscriptobj->VMOpsDisconnectvNICCable($mac);
#if ($ret eq "SUCCESS"){	print "Disconnect vNIC Passed\n" }
#if ($ret eq "FAILURE") { print "Failed \n" }

$ret = $mytestscriptobj->VMOpsTakeSnapshot("testing-snapshot2");
if ( $ret eq "SUCCESS" ) { print "Take snapshot Passed\n" }
if ( $ret eq "FAILURE" ) { print "Failed \n" }
if ( not defined $ret ) { print "ret variable is undefined \n" }

$ret = $mytestscriptobj->VMOpsRevertSnapshot("testing-snapshot2");
if ( $ret eq "SUCCESS" ) { print "Revert Snapshot Passed\n" }
if ( $ret eq "FAILURE" ) { print "Failed \n" }
if ( not defined $ret ) { print "ret variable is undefined \n" }

$ret = $mytestscriptobj->VMOpsDeleteSnapshot("testing-snapshot2");
if ( $ret eq "SUCCESS" ) { print "delete Passed\n" }
if ( $ret eq "FAILURE" ) { print "Failed \n" }
if ( not defined $ret ) { print "ret variable is undefined \n" }

$ret = $mytestscriptobj->VMOpsPowerOff();
if ( $ret eq "SUCCESS" ) { print "Power off Passed\n" }
if ( $ret eq "FAILURE" ) { print "Failed \n" }
if ( not defined $ret ) { print "ret variable is undefined \n" }

$ret = $mytestscriptobj->VMOpsReset();
if ( $ret eq "SUCCESS" ) { print "Reset  Passed\n" }
if ( $ret eq "FAILURE" ) { print "Failed \n" }
if ( not defined $ret ) { print "ret variable is undefined \n" }

my $powerState;
( $ret, $powerState ) = $mytestscriptobj->VMOpsGetPowerState();
if ( $ret eq "SUCCESS" ) { print "Power State is: $powerState\n" }
if ( $ret eq "FAILURE" ) { print "Failed \n" }
if ( not defined $ret ) { print "ret variable is undefined \n" }

## Just for ESX
###for (my $count = 10; $count >= 1; $count--) {
#					my ($ret, $mac) = $mytestscriptobj->VMOpsHotAddvNIC("e1000", "vdtest");
#					if ($ret eq "SUCCESS"){
#
##					$mytestscriptobj->VMOpsConnectvNICCable($mac);
##					$mytestscriptobj->VMOpsDisconnectvNICCable($mac);
#					$mytestscriptobj->VMOpsHotRemovevNIC($mac);
#					}
##
##
#					($ret, $mac) = $mytestscriptobj->VMOpsHotAddvNIC("vmxnet2", "vdtest");
#					if ($ret eq "SUCCESS"){
##					$mytestscriptobj->VMOpsConnectvNICCable($mac);
##					$mytestscriptobj->VMOpsDisconnectvNICCable($mac);
##					$mytestscriptobj->VMOpsHotRemovevNIC($mac);
#					}
##					#$mytestscriptobj->VMOpsSuspend();
##					#$mytestscriptobj->VMOpsResume();
#		                   $mytestscriptobj->VMOpsReset();
##
#					($ret, $mac) = $mytestscriptobj->VMOpsHotAddvNIC("vmxnet3", "vdtest");
#					if ($ret eq "SUCCESS"){
##					$mytestscriptobj->VMOpsConnectvNICCable($mac);
##					$mytestscriptobj->VMOpsDisconnectvNICCable($mac);
##					$mytestscriptobj->VMOpsHotRemovevNIC($mac);
#					}
##
##
#					($ret, $mac) = $mytestscriptobj->VMOpsHotAddvNIC("vmxnet", "vdtest");
#					if ($ret eq "SUCCESS"){
##					$mytestscriptobj->VMOpsConnectvNICCable($mac);
##					$mytestscriptobj->VMOpsDisconnectvNICCable($mac);
#					$mytestscriptobj->VMOpsHotRemovevNIC($mac);
#					}
#print "$count ";
#}

