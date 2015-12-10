########################################################################
# Copyright (C) 2012 VMWare, Inc.
# # All Rights Reserved
########################################################################
package VDNetLib::Common::ZooKeeper;

#
# VDNetLib::Common::ZooKeeper Module
#
# Methods:
# 1. new() - constructor
# 2. CreateZkHandle()
# 2. AddNode()
# 3. DeleteNode()
# 4. GetChildren()
# 5. CheckIfNodeExists()
# 6. SetNodeValue()
# 7. GetNodeValue()
#

#
# Copying the error code for reference
#
# enum ZOO_ERRORS {
  # ZOK = 0, /*!< Everything is OK */
  # /** System and server-side errors.
   # * This is never thrown by the server, it shouldn't be used other than
   # * to indicate a range. Specifically error codes greater than this
   # * value, but lesser than {@link #ZAPIERROR}, are system errors. */
  # ZSYSTEMERROR = -1,
  # ZRUNTIMEINCONSISTENCY = -2, /*!< A runtime inconsistency was found */
  # ZDATAINCONSISTENCY = -3, /*!< A data inconsistency was found */
  # ZCONNECTIONLOSS = -4, /*!< Connection to the server has been lost */
  # ZMARSHALLINGERROR = -5, /*!< Error while marshalling or unmarshalling data */
  # ZUNIMPLEMENTED = -6, /*!< Operation is unimplemented */
  # ZOPERATIONTIMEOUT = -7, /*!< Operation timeout */
  # ZBADARGUMENTS = -8, /*!< Invalid arguments */
  # ZINVALIDSTATE = -9, /*!< Invliad zhandle state */
  # /** API errors.
   # * This is never thrown by the server, it shouldn't be used other than
   # * to indicate a range. Specifically error codes greater than this
   # * value are API errors (while values less than this indicate a
   # * {@link #ZSYSTEMERROR}).
   # */
  # ZAPIERROR = -100,
  # ZNONODE = -101, /*!< Node does not exist */
  # ZNOAUTH = -102, /*!< Not authenticated */
  # ZBADVERSION = -103, /*!< Version conflict */
  # ZNOCHILDRENFOREPHEMERALS = -108, /*!< Ephemeral nodes may not have children */
  # ZNODEEXISTS = -110, /*!< The node already exists */
  # ZNOTEMPTY = -111, /*!< The node has children */
  # ZSESSIONEXPIRED = -112, /*!< The session has been expired by the server */
  # ZINVALIDCALLBACK = -113, /*!< Invalid callback specified */
  # ZINVALIDACL = -114, /*!< Invalid ACL specified */
  # ZAUTHFAILED = -115, /*!< Client authentication failed */
  # ZCLOSING = -116, /*!< ZooKeeper is closing */
  # ZNOTHING = -117, /*!< (not error) no server responses to process */
  # ZSESSIONMOVED = -118 /*!<session moved to another server, so operation is ignored */
# };

use strict;
use warnings;
use Data::Dumper;
use Net::ZooKeeper qw(:node_flags :acls :log_levels);
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);
use VDNetLib::Common::VDLog;
use VDNetLib::Common::GlobalConfig qw($vdLogger $STAF_DEFAULT_PORT
                                      $sessionSTAFPort);

#
# Every node in Zookeeper has a limitation of 1MB. The following constant
# limits it to 0.5MB. If there is any data that is more than 0.5MB needs
# a relook to see if it can be reduced, since this value directly affects
# the memory usage.
#
# NOTE: This value has been changed to 750000 due to PR 972974, until a
#       more robust solution is in place
#
use constant DEFAULT_WATCH_TIME => 20000;  # Milliseconds.
use constant READDATALENGTH => 500000;
use constant ZNODEEXISTS => -110;
use constant ZNONODE => -101;
use constant ZINVALIDSTATE => -9;
use constant ZAPIERROR => -100;
use constant ZNONODE => -101;

########################################################################
#
# new --
#     Entry to VDNetLib::Common::ZooKeeper. Creates an instance of
#     VDNetLib::Common::ZooKeeper object.
#
# Input:
#      server: IP of the server
#      port:   Port number
#
# Results:
#      A VDNetLib::Common::ZooKeeper object
#
# Side effects:
#      None
#
########################################################################

sub new
{
    my $class = shift;      # IN: Invoking instance or class name.
    my %args = @_;

    if ((not defined $args{server}) || (not defined $args{port})) {
       $vdLogger->Error("One or more parameters are missing");
       VDSetLastError("ENOTDEF");
       return FAILURE;
    }

    my $self = {
       'server'      => $args{server},
       'port'        => $args{port},
       'runtimeDir'  => $args{runtimeDir},
       'zkHandle' => undef,
       'pid'      => $args{pid},
    };

    bless $self => $class;
    return $self;
}


########################################################################
#
# CreateZkHandle --
#     Creates and returns a ZooKeeper handle.
#
# Input:
#      timeout: timeout value in milliseconds
#
# Results:
#     ZooKeeper handle if success, undef otherwise
#
# Side effects:
#      None
#
########################################################################

sub CreateZkHandle
{
   my $self   = shift;
   my $timeout = shift;
   my $server = $self->{server};;
   my $port   = $self->{port};

   $timeout = (defined $timeout) ?  $timeout : 40000;
   my $zkh = Net::ZooKeeper->new("$server:$port",
                                 'session_timeout' => $timeout);
   if (not defined $zkh) {
      $vdLogger->Error("Failed to create ZooKeeper handle");
      VDSetLastError("ENOTDEF");
      return undef;
   }
   $vdLogger->Debug("Zookeeper handle created:" . Dumper($zkh));

   return $zkh;
}


########################################################################
#
# AddNode --
#     Adds the specified node in the ZooKeeper database.
#
# Input:
#      node:    path to the node (if you want to create a node C under
#               /A/B/, you should pass /A/B/C. The path is always
#               absolute path)
#      value:   value of the node
#      aclType: ACL type
#      zkh: ZooKeeper handle to provide API access to zookeeper
#           operations.
#      flags: Flags for node creation. Can have following values:
#           - ZOO_EPHEMERAL: Causes the node to be marked as ephemeral,
#               meaning it will be automatically deleted if it still
#               exists when the client's session ends.
#           - ZOO_SEQUENCE: Causes a unique integer to be appended to
#               the node's final path component
#           If both flags need to be set then they should be bitwise
#           OR'ed.
#
# Results:
#     Node path if the node is added, FAILURE otherwise
#
# Side effects:
#      A new node is added
#
########################################################################

sub AddNode
{
   my $self    = shift;
   my $node    = shift;
   my $value   = shift || " ";
   my $aclType = shift || ZOO_OPEN_ACL_UNSAFE;
   my $zkh     = shift || $self->{zkHandle};
   my $flags   = shift || 0;

   if (not defined $node) {
      $vdLogger->Error("One or more parameters are missing");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ($self->CheckHandleState($zkh) eq FAILURE) {
      $vdLogger->Error("Zookeeper handle not defined or invalid");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   my $createdNodePath = undef;
   $createdNodePath = $zkh->create($node, $value, 'flags'=> $flags,
                                   'acl' => $aclType);
   my $ret = $zkh->get_error();
   if ($ret != 0) {
      if ($ret == ZNODEEXISTS) {
          $vdLogger->Warn("ZK node already exists, create failed: $node");
          return $node;
      }
      $vdLogger->Error("Failed to add a node: $ret");
      $vdLogger->Error("node: $node value:$value");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return $createdNodePath;
}


########################################################################
#
# DeleteNode --
#     Deletes the specified node.
#
# Input:
#      node:    path to the node
# Results:
#     SUCCESS if the node is deleted, FAILURE otherwise
#
# Side effects:
#      A node will be deleted
#
########################################################################

sub DeleteNode
{
   my $self = shift;
   my $node = shift;
   my $zkh  = shift || $self->{zkHandle};

   if (not defined $node) {
      $vdLogger->Error("Node to delete not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $children = $self->GetChildren($node, $zkh);
   if (scalar(@$children)) {
      for (my $item = 0; $item < scalar(@$children); $item++) {
         my $tempNode = $node . '/' . $children->[$item];
         $self->DeleteNode($tempNode, $zkh);
      }
   }
   $vdLogger->Debug("Deleting node: $node");
   $zkh->delete($node);
   my $ret = $zkh->get_error();
   if ($ret != 0) {
      $vdLogger->Error("Failed to delete a node: $ret");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# GetChildren --
#     Get the children for the specified node.
#
# Input:
#      node:    path to the node
# Results:
#     Returns the list of children, FAILURE otherwise
#
# Side effects:
#      None
#
########################################################################

sub GetChildren
{
   my $self = shift;
   my $node = shift;
   my $zkh  = shift || $self->{zkHandle};
   my @children;

   if (not defined $node) {
      $vdLogger->Error("Node information missing");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($self->CheckHandleState($zkh) eq FAILURE) {
      $vdLogger->Error("Zookeeper handle not defined or invalid");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   @children = $zkh->get_children($node);
   my $result = $zkh->get_error();
   if ($result) {
      $vdLogger->Debug("Unable to get child nodes of $node, return " .
                       "value: $result");
   }
   return \@children;
}


########################################################################
#
# CheckIfNodeExists --
#     Check if the given node exists.
#
# Input:
#     node: path to the node
#     zkh: Zookeeper handle.
# Results:
#     SUCCESS if the node exists, FAILURE otherwise
#
# Side effects:
#     None
#
########################################################################

sub CheckIfNodeExists
{
  my $self = shift;
  my $node = shift;
  my $zkh  = shift || $self->{zkHandle};

  if (not defined $node) {
     $vdLogger->Error("Node information missing");
     VDSetLastError("ENOTDEF");
     return FAILURE;
  }

  if ($self->CheckHandleState($zkh) eq FAILURE) {
      $vdLogger->Error("Zookeeper handle not defined or invalid");
      VDSetLastError(VDGetLastError());
      return FAILURE;
  }
  if($zkh->exists($node)) {
     return SUCCESS;
  } else {
     return FAILURE;
  }
}

########################################################################
#
# WatchNodeForExistence --
#     Check if the given node exists.
#
# Input:
#        node: path to the node
#        watchTime: Time (in ms) to watch the node before returning.
#        zkh: ZooKeeper handle.
# Results:
#     If watchTime is not passed:
#       SUCCESS if the node exists, FAILURE otherwise
#     else:
#       Returns the Net::ZooKeeper::watch hash that contains keys
#       for 'event', 'state' and 'timeout' and corresponding values.
#       Watch hash can return any of the following events:
#           NODE_CREATED - Watched node is created.
#           NODE_DELETED - watched node is deleted.
#           NODE_DATA_CHANGED - Data of watched node is changed.
#           NODE_CHILDREN_CHANGED - Children of watched node is changed.
#
# Side effects:
#      None
#
########################################################################

sub WatchNodeForExistence
{
  my $self = shift;
  my $node = shift;
  my $watchTime = shift || DEFAULT_WATCH_TIME;
  my $zkh  = shift || $self->{zkHandle};
  if (not defined $node) {
     $vdLogger->Error("Node not passed");
     return FAILURE;
  }
  if ($self->CheckHandleState($zkh) eq FAILURE) {
      $vdLogger->Error("ZooKeeper handle not defined or invalid");
      VDSetLastError(VDGetLastError());
      return FAILURE;
  }
  my $watch = $zkh->watch('timeout' => $watchTime);
  my $existsResult = $zkh->exists($node, 'watch' => $watch);
  my $ret = $zkh->get_error();
  if ($ret == ZNONODE) {
      $vdLogger->Trace("Following zk node does not exist: " . $node);
  } elsif ($ret != 0) {
      $vdLogger->Error("Got unexpected zookeper return code: $ret, " .
                       "while checking for $node existence");
      return FAILURE;
  }
  $vdLogger->Trace("Monitoring activity on $node ...");
  if ($watch->wait()) {
    $vdLogger->Trace("Event detected on node $node:");
    $vdLogger->Trace("  event: $watch->{event}");
    $vdLogger->Trace("  state: $watch->{state}");
    return $watch;
  }
  else {
    $vdLogger->Trace("Watch timed out after $watchTime ms");
    return $watch;
  }
}

########################################################################
#
# SetNodeValue --
#     Set the specified value to the given node.
#
# Input:
#        node:    path to the node
#        value:   value to set
# Results:
#     New value will be set, FAILURE otherwise
#
# Side effects:
#      Node will have the new value
#
########################################################################

sub SetNodeValue
{
  my $self  = shift;
  my $node  = shift;
  my $value = shift;
  my $zkh   = shift || $self->{zkHandle};

  if (not defined $zkh || not defined $node || not defined $value) {
     $vdLogger->Error("One or more parameters are missing");
     VDSetLastError("ENOTDEF");
     return FAILURE;
  }

  $zkh->set($node, $value);
  my $ret = $zkh->get_error();
  if ($ret != 0) {
     $vdLogger->Error("Failed to set the new value: $ret");
     VDSetLastError("EOPFAILED");
     return FAILURE;
  }
  return SUCCESS;
}


########################################################################
#
# GetNodeValue --
#     Get the given node's value.
#
# Input:
#        node:    path to the node
# Results:
#     Returns the value, FAILURE otherwise
#
# Side effects:
#      None
#
########################################################################

sub GetNodeValue
{
  my $self  = shift;
  my $node  = shift;
  my $zkh   = shift || $self->{zkHandle};

  my $value = undef;

  if (not defined $zkh || not defined $node) {
     $vdLogger->Error("One or more parameters are missing");
     VDSetLastError("ENOTDEF");
     return FAILURE;
  }
  if (FAILURE eq $self->CheckIfNodeExists($node, $zkh)) {
     $vdLogger->Error("Node $node does not exist");
     VDSetLastError("ENOTDEF");
     return FAILURE;
  }
  #
  # extend the limit on read data length.
  #
  $value = $zkh->get($node, 'data_read_len' => READDATALENGTH);
  if (not defined $value) {
     $vdLogger->Error("Failed to get the node's value");
     VDSetLastError("EOPFAILED");
     return FAILURE;
  }
  return $value;
}


########################################################################
#
# RefreshHandle --
#     Method to refresh zookeeper handle in case session expired
#
# Input:
#     zkh : zookeeper handle (optional)
#     node: test node to create (optional)
#
# Results:
#     undef, if there is no need to refresh handle
#     reference to new handle, if given handle is invalid
#     FAILURE, in case of any unexpected error;
#
# Side effects:
#     None
#
########################################################################

sub RefreshHandle
{
   my $self    = shift;
   my $zkh     = shift || $self->{zkHandle};
   my $node    = shift || "/testbed";

   my $handle = undef;
   if ($self->CheckHandleState($zkh) eq FAILURE) {
      $vdLogger->Trace("Zookeeper handle is lost, re-creating handle");
      $handle = $self->CreateZkHandle();
      if (not defined $handle) {
        $vdLogger->Error("Failed to re-create new handle");
        VDSetLastError(VDGetLastError());
        return undef;
      }
   } else {
      $handle = $zkh;
   }
   return $handle;
}


########################################################################
#
# CloseSession --
#     Method to close zookeeper session and release handle
#
# Input:
#     zkh   : zookeeper handle (Optional)
#
# Results:
#     FAILURE, if error happens
#     undef, if successful or zookeeper handle invalid or undefined
#
# Side effects:
#     The attribute 'zkHandle' will no longer be useful
#
########################################################################

sub CloseSession
{
   my $self    = shift;
   my $zkh     = shift || $self->{zkHandle};

   if ($self->CheckHandleState($zkh) eq FAILURE) {
      $vdLogger->Debug("Zookeeper handle not defined or invalid");
      return undef;
   }
   $vdLogger->Debug("StackTrace:\n" .
                    VDNetLib::Common::Utilities::StackTrace());
   $vdLogger->Debug("Zookeeper handle destroyed:" . Dumper($zkh));
   eval {
      $zkh->DESTROY();
   };
   if ($@) {
      $vdLogger->Debug("Exception thrown while destroy zookeeper handle:$@");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return undef;
}


########################################################################
#
# CheckHandleState --
#     Method to check given zookeeper handle state
#
# Input:
#     zkh   : zookeeper handle
#
# Results:
#     SUCCESS, if the handle is in good state;
#     FAILURE, if the handle is not in usable state;
#
# Side effects:
#     None
#
########################################################################

sub CheckHandleState
{
   my $self = shift;
   my $zkh  = shift;

   if (not defined $zkh) {
      $vdLogger->Debug("Parameter invalid for zookeeper handler");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   eval {
      my $ret = $zkh->get_error();
      if (($ret != 0) && ($ret > ZAPIERROR)) {
         $vdLogger->Debug("ZAPIERROR returned");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   };
   if ($@) {
      $vdLogger->Debug("Exception thrown while checking handle status:$@");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   return SUCCESS;
}


########################################################################
#
# BackupInventoryToFile --
#     Method to backup zookeeper inventory to a file. It makes use of
#     zktreeutil through the commandline.
#
# Input:
#     nodeToBackup   : zookeeper node whose hierarchy is to be backed up
#                      Example: /testbed/testsession/neutron/1
#     backupFile     : file where will backup will be stored in xml format
#                      Example: /tmp/vdnet/config-snapshot
#
# Results:
#     SUCCESS, if the backup file was created;
#     FAILURE, if the backup file was not created;
#
# Side effects:
#     None
#
########################################################################

sub BackupInventoryToFile
{

   my $self = shift;
   my $nodeToBackup = shift;
   my $backupFile = shift;

   my $server = $self->{server};
   my $port = $self->{port};

   # Making sure that another file of the same name doesn't get
   # used as a backup file incase backup step fails.
   my $cmd = "rm -f $backupFile > /dev/null";
   my $result;

   $result = `$cmd`;

   $cmd = "zktreeutil -E -p " . $nodeToBackup . " -z " . $server .
             ":" . $port . " -d > " . $backupFile;
   $result = `$cmd`;

   # Throwing error in case the backup file was not created
   if (-e $backupFile) {
      return SUCCESS;
   } else {
       $vdLogger->Error("zktreeutil export fails, no file created");
       return FAILURE;
   }
}


########################################################################
#
# RestoreInventoryFromFile --
#     Method to restore zookeeper inventory from a file. It makes use of
#     zktreeutil through the commandline.
#
# Input:
#     nodeToRestore   : zookeeper node whose contents are to be restored
#     backupFile      : xml file from where the restore data will be coming
#                       from
#
# Results:
#     SUCCESS, if zktreeutil Import is successfull;
#     FAILURE, if zktreeutil Import is not successfull;
#
# Side effects:
#     zktreeutil import has been known to fail intermittently. This method
#     does 3 retries before it gives up and returns FAILURE.
#
########################################################################

sub RestoreInventoryFromFile
{
   my $self = shift;
   my $nodeToRestore = shift;
   my $restoreFile = shift;

   my $server = $self->{server};
   my $port = $self->{port};

   my $retryCount = 3;
   my $cmd = "zktreeutil -I -p " . $nodeToRestore . " -z " . $server .
             ":" . $port . " -x " . $restoreFile;
   my $result;
   while ($retryCount > 0) {
      $result = `$cmd`;
      if ($result ne "[zktreeutil] import successful!\n") {
         $vdLogger->Debug("zktreeutil import fails. Retrying...");
      } else {
         $vdLogger->Debug("zktreeutil import succeeds");
         last;
      }
      $retryCount--;
   }
   if ($result ne "[zktreeutil] import successful!\n") {
      $vdLogger->Error("zktreeutil import fails with: $result");
      return FAILURE;
   }
   return SUCCESS;
}

1;
