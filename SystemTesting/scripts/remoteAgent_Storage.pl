#!/usr/bin/perl

=head1 NAME

RemoteAgent.pl - Is the generic test to execute  a routine on a remote machine.

=head1 DESCRIPTION

This script does a new of the package on the remote machine and
executes the function passed as argument to the script. This
script does not store the class variables meaning if you have passed
other module's objects as a parameter to the new package, that'll not work.
since it is an object that got created on the other(local) side.

=head1 Return Value:

RemoteAgent.pl  will output  a datastructure(RetRef) if it passes, if it dies
it returns a string in 'DIE' key, and the returncode of the routine in RC key.

  {
    RC => 1;
    DIE =>""   # This will be present if the routine die's
    RetRef => "" #This will be the return value of the routine always expects a reference
  }
=head1 METHODS

=over

=cut

#Use all common libraries to the search path,
use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/Common/";
use lib "$FindBin::Bin/../VDNetLib/CPAN/5.8.8/";
use Data::Dumper;
use Getopt::Long;
use File::Spec::Functions qw(catdir);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
eval "use PLSTAF";
if ($@) {
   use lib "$FindBin::Bin/../VDNetLib/Common";
   use PLSTAF;
}
my ($package, $function, $argString, $pkgArgs);
my %returnHash;
GetOptions( 'p|package=s'=> \$package,
            'n|pkgArgs=s' => \$pkgArgs,
            'f|function=s'=> \$function,
            'a|argString=s'=> \$argString,
            );
_evalError($@) if ($@);

# Set $vdLogger
#
VDNetLib::Common::GlobalConfig::CreateVDLogObj('logLevel' => $ENV{VDNET_LOGLEVEL},
                                           'logToFile' => $ENV{VDNET_LOGTOFILE},
                                           'verbose'  => $ENV{VDNET_VERBOSE});

my $requirePkg;
eval {
   $requirePkg = catdir(split(/::/,$package));
   $requirePkg =~ s/\s*(\S+)\s*/$1/;
   $requirePkg .= ".pm";
   require $requirePkg;
};



_evalError($@) if ($@);

my $opObj;
eval {
   $opObj = new $package(_formArgs($pkgArgs));
};

_evalError($@) if ($@);
if ($@){
   $@ =~ s/\'/\\'/g;
   $returnHash{DIE} =$@;
   $returnHash{RC} = -1;
   exit(_setStafSharedVar(\%returnHash));
}

my @args = _formArgs($argString);
my ($returncode, $ref);
eval {
   ($returncode, $ref) = $opObj->$function(@args);
};

if ($@) {
   _evalError($@);
} else {
   $returnHash{'RC'} = $returncode;
   $returnHash{'RetRef'} = $ref;
   exit(_setStafSharedVar(\%returnHash));
}

exit 0;


=item _formArgs

   Forms arguments for the new package and the subroutine based on the input
   from the remote machine ,passed via Dumper .

=cut


sub _formArgs {
   my ($argString) = @_;
   my ($argRef) = eval($argString);
   $vdLogger->Debug(Dumper($argRef));
   return (@{$argRef});
}

sub _evalError {
   my ($errorStr) = shift;
   $errorStr =~ s/\'/\\'/g;
   $returnHash{DIE} =$errorStr;
   $returnHash{RC} = -1;
   exit(_setStafSharedVar(\%returnHash));
}

sub _setStafSharedVar {
   my ($retHash) = @_;
   my $message = Dumper($retHash);
   my $handle = STAF::STAFHandle->new("RemoteAgent::SetStafSharedVal");

   if ($handle->{rc} != $STAF::kOk) {
      $vdLogger->Error("Error registering with STAF, RC: $handle->{rc}");
      return -1;
   }
   my $parentSharedVar;
   if (!($parentSharedVar = $ENV{PARENT_SHARED_VAR})) {
      $vdLogger->Warn("Parent ENV Shared Variable PARENT_SHARED_VAR Name not set");
      return -1;
   }
   my $writeToSharedVarCmd = "set SHARED var " . $parentSharedVar . "=" . "\"$message\"";
   my $result = $handle->submit('local', "var", $writeToSharedVarCmd);

   if ($result->{rc} != $STAF::kOk) {
      $vdLogger->Error("Expected RC: 0");
      $vdLogger->Error("Received RC: $result->{rc}");
      return -1;
   }

   # Close the STAF handle created in this sub-routine
   $result = $handle->unRegister();

   if ($result != $STAF::kOk) {
      $result = $handle->unRegister();
      $vdLogger->Warn("failed to unregister staf handle, RC:$result");
   }
   return 0;
}
