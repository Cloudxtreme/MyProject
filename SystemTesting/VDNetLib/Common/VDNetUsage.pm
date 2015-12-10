package VDNetLib::Common::VDNetUsage;

use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../../VDNetLib/CPAN/5.8.8/";
use Text::Table;

# Disclaimer:
# Old Usage format. Preserving them if a tester wants to use these flags
# during manual testing. 
# Please use them at your own risk. They might not be supported anymore
#
# $usage = "vdNet.pl [-s] -sut \"<ip|vmx>:<hostip>[,cache=<cacheDir>]" .
#           "[,sync=<0|1>][,prefixDir=<prefixDirectory>]".
#           "[,tools=<server>:<share>]\" " .
#           "-helper \"<ip|vmx>:<hostip>[,cache=<cacheDir>][,sync=<0|1>]" .
#           "[,prefixDir=<prefixDirectory>]".
#           "[,tools=<server>:<share>]\" -t <tdsID>:" .
#           "[-resultfile <filename>]\n\n";

$usage = "\nAbout:\n\tVDNet - Framework/Tool to provision, configure and verify networking ".
         "components & features in Software Defined Datacenter.\n\t\t Includes " .
         "multi-hypervisor, interop with VSAN & Physical Switches\n";
$usage = $usage . "Usage:\n";

my $helpInfo= Text::Table->new();
$helpInfo->load(
#    [ "-vc", "--vc", "Virtual Center address\n", ""],
#     [ "-sut", "--sut", "SUT VM details\n" ],
#     [ "-helper", "--helper", "Helper VM details\n" ],
#     [ "-r", "--resultfile", "result file name, optional\n" ],
#     [ "-lk", "--listkeys", "list workload keys for writing test case. " .
#                         "Supported value: all, traffic, switch, netadapter\n" ],
#     [ "-hosts", "--hosts", "separated host list which will be used based on test" .
#                         "case requirements automatically\n" ],
#     [ "-vms", "--vms", "This indicates VMs to be used in test case." .
#                         "value should be of format \n" .
#                         "\"sut=<templateName>,helper=<templateName>\"\n" ],
#     [ "-s", "--skipsetup", "do not verfiy the setup or perform setup\n" ],
#     [ "-src", "--src", "vdNet source hostname/ip (default scm-trees.eng." .
#                         "vmware.com)\n" ],
#     [ "-c", "--chksetup", "verify the setup and perform setup only\n" ],
#     [ "-loglevel", "--loglevel", "log level 0 to 9 for console-9 provides " .
#                                  "detailed information on console\n" ],
#     [ "-vmrepos", "--vmrepos", "VM repository to use. value format: <server>" .
#                                 ":<shareName>\n" ],
#     [ "-shared", "--shared", "shared storage to be used for test cases like " .
#                                 "vmotion (optional)\nformat <server>:/<share>\n" ],
#     [ "-nocleanup", "--nocleanup", "Option to skip cleanup on failure. " .
#                                 "Takes no value\n" ],
#     [ "-options", "--options", "Comma separated string with list of vdnet " .
#                                 "options to apply\nsupported values:\n" .
#                                 "disablearp - need for UPT to disable arp inspection\n" .
#                                 "usevix - to use VIX APIs for VM operations\n" .
#                                 "notools - do not upgrade VMware Tools\n" .
#                                 "collectLogs - collect log for all finished workloads\n" ],
#     [ "-v", "--vmtf", "Run vdNet via VMTF harness \n" ],
#     [ "-ignorefail", "--ignorefail", "Continue to run the remain workloads " .
#                                 "even hit error(s)\n" ],
    [ "\t-c", "--config", "\tPath to YAML Config file \n"],
    [ "\t-t", "--tdsID", "\tTest case ID\n" ],
    [ "\t-h", "--help", "\tThis help message\n" ],
     [ "\t-l", "--list", "\tList test case IDs, give \"all\" to list all tests\n" ],
     [ "\t-listvms", "--listvms", "\tList all VMs available in the given VM repository " .
                                 "(default is prme-bheemboy:/nfs/vdtest)\n" ],
     [ "\t-tags", "--tags", "\tPick tests which match given tags"] ,
     [ "\t-logs", "--logs", "\tLogs directory\n" ],
     [ "\t-i", "--interactive", "\tEnables interactive mode ('onfailure' or <workload name>)\n" ],
     [ "\t-ct", "--cachetestbed", "\tEnable testbed cache function which will be useful for multiple cases with the same topology\n" ],
     [ "\t-optionsyaml", "--optionsyaml", "\tPath to custom YAML file that will override options from the config YAML\n" ],
     [ "\t-testset", "--testset", "\tText to be used as description for the reported logs to racetrack\n" ],
     [ "\t-skiptests", "--skiptests", "\tSkip the list of tests from the set of tests given using the -t option\n" ],
);
$usage = $usage . $helpInfo->stringify();
$helpInfo->clear();
my $example = "Example:\n\t" . "vdnet " .  "--config userConfig.yaml -t EsxServer.VDR.VDR.VXLANTrafficDifferentHost -t EsxServer.VDR.*.* --tags sanity\n";
$usage = $usage . $example;
my $advanceOptions = "Advanced options:\n\t" . "refer to userConfig.yaml for all the nobs, flags and VDNet-Snapshot feature\n\n";
$usage = $usage . $advanceOptions;
1;
