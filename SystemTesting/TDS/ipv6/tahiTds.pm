#!/usr/bin/perl
########################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################
#
# Setup and execute a TAHI (NIST) test run.
#
# Please read the tahi_README before running this TDS.
# The TAHI freeBSD VM is a requirement for running this test.
#
# Run the tests in this order:
# 
# nopwSSH
# setupTahi
# preflight (this step is optional)
# runTahi
#
########################################################################

package TDS::ipv6::tahiTds;

  use FindBin;
  use lib "$FindBin::Bin/..";
  use TDS::Main::VDNetMainTds;
  use Data::Dumper;
  
  @ISA = qw(TDS::Main::VDNetMainTds);
 
  @TESTS = ("nopwSSH", "preflight", "setupTahi", "runTahi");

  %tahi = (
      'nopwSSH'  => {
	Component	=>	"IPv6 RFC Conformance Suites",
	Catagory	=>	"TAHI",
	TestName	=>	"nopwSSH",
	Summary		=>	"Create a no-password SSH between TN and NUT",
	ExpectedResult	=>	"PASS",
	Parameters	=> {
		VM	=> {
			vm => 1, 
		},
	},

	WORKLOADS => {
	Sequence	=> [['nopwSSH']],

	"nopwSSH"	=> {
		Type    => "Command",
		Target	=> "VM",
		Command	=> "/usr/local/v6eval/bin/tahics/nopwSSH",
      		},
 	},
      },	
	
      'preflight'  => {
	Component	=>	"IPv6 RFC Conformance Suites",
	Catagory	=>	"TAHI",
	TestName	=>	"preflight",
	Summary		=>	"verify components and configurations needed by TAHI",
	ExpectedResult	=>	"PASS",
	Parameters	=> {
		VM	=> {
			vm => 1, 
		},
	},

	WORKLOADS => {
	Sequence	=> [['preflight']],

	"preflight"	=> {
		Type    => "Command",
		Target	=> "VM",
		Command	=> "/usr/local/v6eval/bin/tahics/preflightTAHI > /tmp/preflight.log ",
      		},
 	},
      },	
	
      'setupTahi'  => {
	Component	=>	"IPv6 RFC Conformance Suites",
	Catagory	=>	"TAHI",
	TestName	=>	"setupTahi",
	Summary		=>	"setup of NUT and configuration on TN",
	ExpectedResult	=>	"PASS",
	Parameters	=> {
		VM	=> {
			vm => 1, 
		},
	},

	WORKLOADS => {
	Sequence	=> [['setupTahi']],

	"setupTahi"	=> {
		Type    => "Command",
		Target	=> "VM",
		Command	=> "/usr/local/v6eval/bin/tahics/setup_tahi.pl",
      		},
 	},
      },	

      'runTahi'  => {
	Component	=>	"IPv6 RFC Conformance Suites",
	Catagory	=>	"TAHI",
	TestName	=>	"runTahi",
	Summary		=>	"executes the run_tahi.pl script, which executes the TAHI suites",
	ExpectedResult	=>	"PASS",
	Parameters	=> {
		VM	=> {
			vm => 1, 
		},
	},

	WORKLOADS => {
	Sequence	=> [['runTahi']],

	"runTahi"	=> {
		Type    => "Command",
		Target	=> "VM",
		Command	=> "/usr/local/v6eval/bin/tahics/run_tahi.pl",
      		},
 	},
      },	
); 

 # Define the entry point for this package

sub new
{
   my ($proto) = @_;
   # Below way of getting class name is to allow new class as well as
   # $class->new.  In new class, proto itself is class, and $class->new,
   # ref($class) return the class
   my $class = ref($proto) || $proto;
   my $self = $class->SUPER::new(\%tahi);
   return (bless($self, $class));
}

1;
