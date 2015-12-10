use strict;
use warnings;
use VMOperations::VMOperations;

my %test_esx = (
   hostType => "ESX",
   host     => "10.115.152.83",
#   	 vmx => "[Storage1] RHEL-5.2-32/RHEL-5.2-32.vmx" ,	
#   vmx      => "[Storage1] RHEL-5-3-Server-32/RHEL-5-3-Server-32.vmx",
#   vmx      => "[Storage2] win2k3_32_clone/win2k3_32_clone.vmx",
   vmx      => "[Storage2] ft-regress/SLES11GA-64bit/SLES11GA-64bit.vmx",
#   vmx      => "[Storage2] ft-regress/rhel53_esx/rhel53_esx.vmx",
);

my $mytestscriptobj = VMOperations::VMOperations->new( \%test_esx );

my $ret;
$ret = $mytestscriptobj->VMOpsPowerOn();
if ( $ret eq "SUCCESS" ) { print "Power on Passed\n" }
if ( $ret eq "FAILURE" ) { print "Failed \n" }
if ( not defined $ret ) { print "ret variable is undefined \n" }

$ret= $mytestscriptobj->VMOpsSuspend();
if ($ret eq "SUCCESS"){	print "Suspend Passed\n" }
if ($ret eq "FAILURE") { print "Failed \n" }
if (not defined $ret ) { print "ret variable is undefined \n" }


($ret)= $mytestscriptobj->VMOpsResume();
if ($ret eq "SUCCESS"){	print "Resume Passed\n" }
if ($ret eq "FAILURE") { print "Failed \n" }
if (not defined $ret ) { print "ret variable is undefined \n" }
exit 0;
my $mac = "";

#$ret = $mytestscriptobj->VMOpsConnectvNICCable($mac);
#if ($ret eq "SUCCESS"){	print "Connect vNIC Passed\n" }
#if ($ret eq "FAILURE") { print "Failed \n" }
#if (not defined $ret ) { print "ret variable is undefined \n" }
#
#$ret =	$mytestscriptobj->VMOpsDisconnectvNICCable($mac);
#if ($ret eq "SUCCESS"){	print "Disconnect vNIC Passed\n" }
#if ($ret eq "FAILURE") { print "Failed \n" }
#
$ret =$mytestscriptobj->VMOpsTakeSnapshot("testing-snapshot2");
if ($ret eq "SUCCESS"){	print "Take snapshot Passed\n" }
if ($ret eq "FAILURE") { print "Failed \n" }
if (not defined $ret ) { print "ret variable is undefined \n" }

$ret = $mytestscriptobj->VMOpsRevertSnapshot("testing-snapshot2");
if ($ret eq "SUCCESS"){	print "Revert Snapshot Passed\n" }
if ($ret eq "FAILURE") { print "Failed \n" }
if (not defined $ret ) { print "ret variable is undefined \n" }


$ret = $mytestscriptobj->VMOpsDeleteSnapshot("testing-snapshot2");
if ($ret eq "SUCCESS"){	print "delete Passed\n" }
if ($ret eq "FAILURE") { print "Failed \n" }
if (not defined $ret ) { print "ret variable is undefined \n" }

#
$ret = $mytestscriptobj->VMOpsPowerOff();
if ($ret eq "SUCCESS"){	print "Power off Passed\n" }
if ($ret eq "FAILURE") { print "Failed \n" }
if (not defined $ret ) { print "ret variable is undefined \n" }

$ret = $mytestscriptobj->VMOpsReset();
if ($ret eq "SUCCESS"){	print "Reset  Passed\n" }
if ($ret eq "FAILURE") { print "Failed \n" }
if (not defined $ret ) { print "ret variable is undefined \n" }

my $powerState;
( $ret, $powerState ) = $mytestscriptobj->VMOpsGetPowerState();
if ( $ret eq "SUCCESS" ) { print "Power State is: $powerState\n" }
if ( $ret eq "FAILURE" ) { print "Failed \n" }
if ( not defined $ret ) { print "ret variable is undefined \n" }

#( $ret, $mac ) = $mytestscriptobj->VMOpsHotAddvNIC( "e1000", "vdtest" );
#if ( $ret eq "SUCCESS" ) { print "Hot added (passed) NIC with $mac\n" }
#if ( $ret eq "FAILURE" ) { print "Failed \n" }
#if ( not defined $ret ) { print "ret variable is undefined \n" }
#
#$ret = $mytestscriptobj->VMOpsHotRemovevNIC($mac);
#if ( $ret eq "SUCCESS" ) { print "Hot remove (passed) NIC with $mac\n" }
#if ( $ret eq "FAILURE" ) { print "Failed \n" }
#if ( not defined $ret ) { print "ret variable is undefined \n" }

