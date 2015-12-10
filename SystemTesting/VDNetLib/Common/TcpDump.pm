package VDNetLib::Common::TcpDump;

use VDNetLib::Common::GlobalConfig;
use strict;
use warnings;
use Carp;

require Exporter;

@TcpDump::ISA    = qw( Exporter );
my $VERSTION     = "1.00";

###################################################################
# USAGE to read sniffed packets:
#	flag       	=> "r",
#	VerboseRead     => "v" (OPTIONAL, displays verbose o/p)
#	LinkLayerRead   => "e" (OPTIONAL, displays link layer o/p)
#       fileName   	=> <pcap file>
#
# USAGE to sniff IPv4 packets and write to a file:
#	flag       	=> "w",
#       targetInterface => <interface>
#			   Linux: ethX, Windows: (Windump -D value)
#       streamType      => <tcp/udp>
#       countPackets    => <count of packets>
#       fileName        => <write to file>
#       vmIP            => <vm IP>
#
# USAGE to sniff IPv6 packets and write to a file:
#	flag       	=> "w",
#       targetInterface => <interface>
#			   Linux: ethX, Windows: (Windump -D value)
#       countPackets    => <count of packets>
#       fileName        => <write to file>
####################################################################
	       
my %dispatch = (
                linux_32   => \&_tcpdump_linux_32,
                linux_64   => \&_tcpdump_linux_64,
                mswin32_32 => \&_tcpdump_mswin32_32,
                mswin32_64 => \&_tcpdump_mswin32_64,
                solaris_32 => \&_tcpdump_solaris_32,
                solaris_64 => \&_tcpdump_solaris_64,
);


sub new {
my $class = shift;                     
my %args  = @_;                        

my $self  = {

	##  Flag to specify read/write operation  ##
    	_flag => $args{flag} || undef,

	##  Interface name  ##
     	 _targetInterface    => $args{targetInterface} || undef,     

	##  Stream type  ##
 	_streamType  => $args{streamType}   || undef,

	##  Count of packets  ##
     	_countPackets  => $args{countPackets}   || undef,

	##  file name  ##
	_fileName => $args{fileName}  || undef,

	##  vmIP  ##
    	_vmIP  => $args{vmIP}  || undef,

	##  IP type: IPv4/Ipv6  ##
    	_IPversion  => $args{IPversion}  || "",

	##  Read parameters  ##
    	_VerboseRead  => $args{VerboseRead}  || undef,
    	_LinkLayerRead  => $args{LinkLayerRead}  || undef,

	##  OS name in lowercase(lc) of the OS on which this obj runs  ##
	_OS        =>  lc $^O ,

	##  Architecture of the Processor 32 | 64  ##
      	_env      => setEnvForBinary(),

	##  Name of the Binary which needs to be executed  ##
     	_binary    => "",

	##  Path to the binary  ##
    	_path2Bin  => "",

	##  Final command being executed for debugging purposes  ##
 	_command   => "", 

	##  Result of executing the binary with specific parameters  ##
	_result    => "",

};
   
bless $self, $class;
my $ref = $dispatch{$self->{_env}};
unless ($ref) {
	croak("This system isn't supported: $self->{_env}\n");
}

$ref->($self);
return $self;
}


# Function to print all the values of the object.
sub debug {
my $self = shift;

if ($self->{_flag} =~ m/r/i) {
	print "[TcpDump Object to read]\n";
	print "  _fileName: $self->{_fileName}\n";

 } elsif ($self->{_flag} =~ m/w/i) {
 	if ($self->{_IPversion} eq "") {

		print "[TcpDump \"v4\" Object]\n";
	
	} else {
		print "[TcpDump \"$self->{_IPversion}\" Object]\n";
	
	}
   	print "  _targetInterface : $self->{_targetInterface}\n";
   	print "  _countPackets    : $self->{_countPackets}\n";
   	print "  _fileName        : $self->{_fileName}\n";
	
	if ($self->{_IPversion} =~ m/v4/i ||
	    $self->{_IPversion} eq "") {
		print "  _streamType      : $self->{_streamType}\n";
		print "  _vmIP            : $self->{_vmIP}\n";
	}
   	
	print "  _OS      	  : $self->{_OS}\n";
   	print "  _env  		  : $self->{_env}\n";
   	print "  _binary          : $self->{_binary}\n";
   	print "  _path2Bin	  : $self->{_path2Bin}\n";
   	print "  _command  	  : $self->{_command}\n";
   	print "  _result 	  : $self->{_result}\n\n";
 }
}

##  To execute  ##
sub run {
my $self = shift;
$self->{_result} = `$self->{_command}`;
return $self->{_result};
}

sub reportResult {
my $self = shift;
print $self->{_result};
}


##  Return a string indicating OS and Arch eg, linux_32  ##
sub setEnvForBinary {
my $self = shift;       # IN: Invocant
my $arch = undef;
my $env = undef;

if (lc $^O eq lc "MSWin32") {
	my $root = "HKLM";
	my $key = "System\\CurrentControlSet\\Control"
		. "\\Session Manager\\Environment";
	my $value = "PROCESSOR_ARCHITECTURE";

	my $list = `reg query "$root\\$key" /v $value`;

	# check for AMD64 or x86
      	if ($list =~ m/x86/i) { 
        	$env = lc $^O . "_" . "32";
      	} else {
        	$env = lc $^O . "_" . "64";
      	}

 } else {
	# check for x86_64 or x86
      	$arch = `uname -m`;
      	if ($arch =~ m/x86_64/i) { 
        	$env = lc $^O . "_" . "64";
      	} else {
        	$env = lc $^O . "_" . "32";
      	}
 }

chomp($env);
return $env;
}

##  OS and arch specific functions called from the dispatch table  ##

##  Function to be called in case of Linux 32 bit  ##
sub _tcpdump_linux_32 {
my $self    = shift;
my $options;
if ($self->{_flag} =~ /w/){
	if ($self->{_IPversion} =~ m/^v4$/i || 
	    $self->{_IPversion} eq "") {
	    #my $tgtIP = `ifconfig $self->{_targetInterface} | grep "inet addr"`;
	    #if ( $tgtIP =~ m/.*inet addr:(\d+\.\d+\.\d+\.\d+)  (.*)/i) {
            #   $tgtIP =  $1;
            #   chomp($tgtIP);
            #}

	$options = " -i " . $self->{_targetInterface}
                         . " " . $self->{_streamType}
             		 . " -vv  -s0"
                	 . " -c " . $self->{_countPackets}
                         . " -w " . $self->{_fileName}
                 	 . " and src host " . $self->{_vmIP};
                 	 #. " and dst host " . $tgtIP;
	} elsif ($self->{_IPversion} =~ m/^v6$/i) {
		$options = " -i " . $self->{_targetInterface}
	                 . " -vv  -s0"
                         . " -c " . $self->{_countPackets}
                         . " -w " . $self->{_fileName}
		         . " ip6 ";
	}
 
 } elsif ($self->{_flag} =~ /r/) {
	
	if ($self->{_VerboseRead} eq "" || 
	$self->{_VerboseRead} =~ m/null/i) {
		
		if ($self->{_LinkLayerRead} eq "" || 
		$self->{_LinkLayerRead} =~ m/null/i) {

			$options = " -r " . $self->{_fileName};

		} elsif ($self->{_LinkLayerRead} =~ m/e/i) {
			
			$options = " -e -r " . $self->{_fileName};
		}
	
	} elsif ($self->{_VerboseRead} =~ m/v/i) {

		if ($self->{_LinkLayerRead} eq "" || 
		$self->{_LinkLayerRead} =~ m/null/i) {
			
			$options = " -v -r " . $self->{_fileName};

		} elsif ($self->{_LinkLayerRead} =~ m/e/i) {
			
			$options = " -v -e -r " . $self->{_fileName};
		}
	}

 }
	$self->{_path2Bin} = "/usr/sbin/";
   	$self->{_binary}   = "tcpdump ";
   	$self->{_command}  = 
	$self->{_path2Bin} . $self->{_binary} . $options;
}

##  Function to be called in case of Linux 64 bit  ##
sub _tcpdump_linux_64 {
my $self    = shift;
my $options;

if ($self->{_flag} =~ /w/){
	my $tgtIP = `ifconfig $self->{_targetInterface} | grep "inet addr"`;
	if ( $tgtIP =~ m/.*inet addr:(\d+\.\d+\.\d+\.\d+)  (.*)/i) {
           $tgtIP =  $1;
           chomp($tgtIP);
        }
	if ($self->{_IPversion} =~ m/^v4$/i || 
	    $self->{_IPversion} eq ""){
		$options = " -i " . $self->{_targetInterface}
                         . " " . $self->{_streamType}
             		 . " -vv  -s0"
                	 . " -c " . $self->{_countPackets}
                         . " -w " . $self->{_fileName}
                 	 . " and src host " . $self->{_vmIP};
                 	 #. " and dst host " . $tgtIP;
	} elsif ($self->{_IPversion} =~ m/^v6$/i) {

		$options = " -i " . $self->{_targetInterface}
	                 . " -vv  -s0"
                         . " -c " . $self->{_countPackets}
                         . " -w " . $self->{_fileName}
		         . " ip6 ";
	}
 
 } elsif ($self->{_flag} =~ /r/) {

	if ($self->{_VerboseRead} eq "" || 
	$self->{_VerboseRead} =~ m/null/i) {
		
		if ($self->{_LinkLayerRead} eq "" || 
		$self->{_LinkLayerRead} =~ m/null/i) {

			$options = " -r " . $self->{_fileName};

		} elsif ($self->{_LinkLayerRead} =~ m/e/i) {
			
			$options = " -e -r " . $self->{_fileName};
		}
	
	} elsif ($self->{_VerboseRead} =~ m/v/i) {

		if ($self->{_LinkLayerRead} eq "" || 
		$self->{_LinkLayerRead} =~ m/null/i) {
			
			$options = " -v -r " . $self->{_fileName};

		} elsif ($self->{_LinkLayerRead} =~ m/e/i) {
			
			$options = " -v -e -r " . $self->{_fileName};
		}
	}

 }
	$self->{_path2Bin} = "/usr/sbin/";
   	$self->{_binary}   = "tcpdump ";
   	$self->{_command}  = 
	$self->{_path2Bin} . $self->{_binary} . $options;
}


# Function to be called in case of windows 32bit.
sub _tcpdump_mswin32_32 {
my $self          = shift;
my $options;
if ($self->{_flag} =~ /w/){
	if ($self->{_IPversion} =~ m/^v4$/i || 
	    $self->{_IPversion} eq ""){
		$options = " -i " . $self->{_targetInterface}
                	 . " -vv  -s 0"
	                 . " -c " . $self->{_countPackets}
        	         . " -w " . $self->{_fileName}
			 . " " . $self->{_streamType}
	                 . " and src host " . $self->{_vmIP};
	} elsif ($self->{_IPversion} =~ m/^v6$/i) {
		$options = " -i " . $self->{_targetInterface}
		         . " -vv  -s 0"
	                 . " -c " . $self->{_countPackets}
	                 . " -w " . $self->{_fileName}
	                 . " ip6 ";

	}
 
 } elsif ($self->{_flag} =~ /r/) {

	if ($self->{_VerboseRead} eq "" || 
	$self->{_VerboseRead} =~ m/null/i) {
		
		if ($self->{_LinkLayerRead} eq "" || 
		$self->{_LinkLayerRead} =~ m/null/i) {

			$options = " -r " . $self->{_fileName};

		} elsif ($self->{_LinkLayerRead} =~ m/e/i) {
			
			$options = " -e -r " . $self->{_fileName};
		}
	
	} elsif ($self->{_VerboseRead} =~ m/v/i) {

		if ($self->{_LinkLayerRead} eq "" || 
		$self->{_LinkLayerRead} =~ m/null/i) {
			
			$options = " -v -r " . $self->{_fileName};

		} elsif ($self->{_LinkLayerRead} =~ m/e/i) {
			
			$options = " -v -e -r " . $self->{_fileName};
		}
	}

 }
   	 my $np             = new VDNetLib::Common::GlobalConfig;
	    my $binpath        = $np->binariespath(2);
	    $self->{_path2Bin} = "$binpath" . "x86_32\\\\windows\\\\";
		$self->{_binary}   = "WinDump.exe ";
   	$self->{_command}  = 
	$self->{_path2Bin} . $self->{_binary} . $options;
}

# Function to be called in case of windows 64bit.
sub _tcpdump_mswin32_64 {
my $self          = shift;
my $options;
if ($self->{_flag} =~ /w/){
	if ($self->{_IPversion} =~ m/^v4$/i || 
	    $self->{_IPversion} eq ""){
		$options = " -i " . $self->{_targetInterface}
                	 . " -vv  -s 0"
	                 . " -c " . $self->{_countPackets}
        	         . " -w " . $self->{_fileName}
			 . " " . $self->{_streamType}
	                 . " and src host " . $self->{_vmIP};
	} elsif ($self->{_IPversion} =~ m/^v6$/i) {
		$options = " -i " . $self->{_targetInterface}
		         . " -vv  -s 0"
	                 . " -c " . $self->{_countPackets}
	                 . " -w " . $self->{_fileName}
	                 . " ip6 ";

	}
 
 } elsif ($self->{_flag} =~ /r/) {

	if ($self->{_VerboseRead} eq "" || 
	$self->{_VerboseRead} =~ m/null/i) {
		
		if ($self->{_LinkLayerRead} eq "" || 
		$self->{_LinkLayerRead} =~ m/null/i) {

			$options = " -r " . $self->{_fileName};

		} elsif ($self->{_LinkLayerRead} =~ m/e/i) {
			
			$options = " -e -r " . $self->{_fileName};
		}
	
	} elsif ($self->{_VerboseRead} =~ m/v/i) {

		if ($self->{_LinkLayerRead} eq "" || 
		$self->{_LinkLayerRead} =~ m/null/i) {
			
			$options = " -v -r " . $self->{_fileName};

		} elsif ($self->{_LinkLayerRead} =~ m/e/i) {
			
			$options = " -v -e -r " . $self->{_fileName};
		}
	}

 }
   	 my $np             = new VDNetLib::Common::GlobalConfig;
	    my $binpath        = $np->binariespath(2);
	    $self->{_path2Bin} = "$binpath" . "x86_64\\\\windows\\\\";
   	$self->{_binary}   = "WinDump.exe ";
   	$self->{_command}  = 
	$self->{_path2Bin} . $self->{_binary} . $options;
}

1;

