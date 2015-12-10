########################################################################
# Copyright (C) 2008 VMware, Inc.
# All Rights Reserved
#
########################################################################
# SshHost.pm --
#    Class to issues ssh related commands on a remote host.
#
# Author: Nathan Prziborowski
########################################################################

package VDNetLib::Common::SshHost;

use Data::Dumper;
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::VDErrorno qw(VDSetLastError FAILURE SUCCESS);
use VDNetLib::Common::Utilities;
use constant {

   FILE_KNOWNHOSTS => "$ENV{'HOME'}/.ssh/known_hosts",
   FILE_IDDSA => "$ENV{'HOME'}/.ssh/id_dsa",
   FILE_IDDSAPUB => "$ENV{'HOME'}/.ssh/id_dsa.pub",

   TRUE => 1,
   FALSE => 0,
   CMD_EXPECT => '/usr/bin/expect',
   CMD_SSH => '/usr/bin/ssh',
   CMD_CAT => '/bin/cat',
   CMD_RM => '/bin/rm',
   CMD_TOUCH => '/bin/touch',
   CMD_SCP => '/usr/bin/scp',
   CMD_UNAME => 'uname',

   #EXPECT => '/build/toolchain/lin32/expect-5.43.0/bin/expect',
   #ESTABLISH_CONNECTION => '/usr/local/atlas/DTDLIB/Launchers/ESX/'.
   #                        'InstallationLicense/establishConnection.exp',
};

use Fcntl ':flock';
use Net::OpenSSH;
$SIG{HUP} = 'IGNORE'; # if this causes problems, remove, else it quiets OpenSSH
#$Net::OpenSSH::debug = 1;
########################################################################
#
# new
#
#    Provided host, username, password, a ssh connection attempt
#    will be made. If the handshake fails, undef will be return instead
#    of the class.
#
########################################################################

sub new
{
   my $class = shift;   #IN : Invoking instance or class name
   my $host = shift;
   my $username = shift;
   my $password = shift;

   my $self = {
      host => $host,
      username => $username,
      password => $password
   };

   bless $self => $class;

   return undef if $self->Initialize();

   return $self;
}

########################################################################
#
# SshCommand
#
#    Issues a command to the host.
# Input: command
# Return value: array of rc and output. output is in array ref format.
#
########################################################################

sub SshCommand
{
   my $self = shift;
   my $cmd = shift;
   my $timeout = shift || VDNetLib::Common::GlobalConfig::STAF_CALL_TIMEOUT;
   my $opts = shift || undef;
   $opts->{stderr_to_stdout} = 1;
   $opts->{timeout} = $timeout;
   my @out = $self->{ssh}->capture($opts, $cmd);

   # 1169427: if can not allocate memory, collect memory info
   my $errString = $self->{ssh}->error;
   if ((defined $errString) &&
     ($errString =~ /unable to fork new ssh slave: Cannot allocate memory/i)) {
      $vdLogger->Error("Cannot allocate memory when running ssh command $cmd");
      VDNetLib::Common::Utilities::CollectMemoryInfo();
   }
   return ($self->{ssh}->error, \@out);
}


########################################################################
#
# ScpToCommand
#
#    Copies a file to the host.
# Input: from location, to location
# Return value: array of rc and output. output is in array ref format.
#
########################################################################

sub ScpToCommand
{
   my $self = shift;
   my $src = shift;
   my $dst = shift;
   $self->{ssh}->scp_put($src, \\$dst);
   my $exit = $self->{ssh}->error;
   my @out = ('');
   return ($exit, \@out);
}

########################################################################
#
# ScpFromCommand
#
# Copies a file or directory from the host.
# Input: from location, to location
# Return value: array of rc and output. output is in array ref format.
#
########################################################################

sub ScpFromCommand
{
   my $self = shift;
   my $src = shift;
   my $dst = shift;
   my $isDirectoryCopy = shift;
   if ((not defined $isDirectoryCopy) || ($isDirectoryCopy == 0)) {
      $self->{ssh}->scp_get($src, $dst);
   } else {
      $self->{ssh}->scp_get({recursive => 1, glob => 1}, $src, $dst);
   }
   my $exit = $self->{ssh}->error;
   my @out = ('');
   return ($exit, \@out);
}

########################################################################
#
# Initialize
#
# Attempts to connect to the host with the username/password that is stored.
# Handles creating keys and removing known host entries.
#
# Return 1 on error, 0 on pass
#
########################################################################

sub Initialize
{
   my $self = shift;
   my $host = $self->{host};
   my $username = $self->{username};
   my $password = $self->{password};
   my $timeout = "120";

   $self->{ssh} = Net::OpenSSH->new($host,
      user => $username,
      passwd => $password,
      timeout => $timeout,
      default_stderr_discard => 1,
      kill_ssh_on_timeout => 1,
      master_opts => [-o => "UserKnownHostsFile=/dev/null",
                      -o => "StrictHostKeyChecking=no"]);
   if ( $self->{ssh}->error ) {
     $vdLogger->Error("[$0]Couldn't establish SSH connection to $host " .
             "with username=$username, password=$password, timeout=$timeout\n" .
             "error=" . $self->{ssh}->error);

     return 1;
   }
   delete $self->{ssh}->{_timeout};
   return 0;
}


########################################################################
#
# GetPID --
#     Method to get ssh process ID
#
# Input:
#     None
#
# Results:
#     process ID, if exists
#     -1, in case of any error
#
# Side effects:
#     None
#
########################################################################

sub GetPID
{
   my $self = shift;
   my $pid = $self->{ssh}->{_pid};
   if (defined $pid) {
      return $pid;
   }
   return -1;
}


###############################################################################
#
# CopyDirectory
#      This method will check if there is file under one directory,
#      If yes, copy them to dest directory. This function is implementation
#      with SSH
#
# Input:
#      srcDir : source directory on host (mandatory). This is absolute path.
#      dstDir : destination directory name on MC (mandatory) This is not absolute
#               path, just directory name under vdnet log directory
#      srcIP : IP address of directory source (mandatory)
#      isRemoveNeeded : after copy finished, if we need remove files from source
#                       (optional) By default it is 0, means not remove
#
# Results:
#      SUCCESS: file copy successful
#      FAILURE: in case any error
#
# Side effects:
#      None.
#
###############################################################################

sub CopyDirectory
{
   my $self = shift;
   my %args = @_;
   my $srcDir = $args{srcDir};
   my $dstDir = $args{dstDir};
   my $srcIP = $args{srcIP};
   my $isRemoveNeeded = $args{isRemoveNeeded};

   my $result;
   my $output;

   if ((not defined $srcDir) || (not defined $dstDir)) {
      $vdLogger->Error("Directory names not defined for copy operation");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $isRemoveNeeded) {
      $isRemoveNeeded = 0;
   }
   if (substr($srcDir, -1) ne "/") {
      $srcDir .= "/";
   }
   my ($rc, $out) = $self->ScpFromCommand($srcDir . "*",
                          $dstDir, 1);
   if ($rc ne "0") {
      $vdLogger->Error("Failed to copy $srcDir file " .
                     " to $dstDir");
      $vdLogger->Debug("ERROR:$rc " . Dumper($out));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   if ($isRemoveNeeded eq "0") {
      return SUCCESS;
   }

   $cmd = "rm -rf $srcDir*";
   ($result, $output) = $self->SshCommand($cmd);
   if ($result ne "0") {
      $vdLogger->Error("Command $cmd failed on machine $srcIP with ERROR $result " . Dumper($output));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}
1;
