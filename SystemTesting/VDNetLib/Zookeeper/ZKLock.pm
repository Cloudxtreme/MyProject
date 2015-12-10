########################################################################
# Copyright (C) 2015 VMWare, Inc.
# # All Rights Reserved
########################################################################
# This class is used to implement write locks so that two
# processes/clients don't end up manipulating data in parallel. This
# implementation uses ZooKeeper to achieve its goal.
#
########################################################################
package VDNetLib::Zookeeper::ZKLock;

use strict;
use warnings;
use Data::Dumper;
use Net::ZooKeeper qw(:node_flags :acls :log_levels :events);
use List::Util qw(min first);

use VDNetLib::Common::VDErrorno qw(FAILURE SUCCESS VDSetLastError);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use constant LOCKNODE => "/_locknode_";
use constant WRITE_LOCK_PREFIX => LOCKNODE . "/write-";
use constant DEFAULT_LOCK_ACQUISITION_TIMEOUT => 10;  # Seconds.

########################################################################
#
# new --
#   Creates an instance of lock object that provides API for acquiring
#   a lock and releasing it. This implementation uses zookeeper to
#   provide locking.
#
# Input:
#   name - Name/id of the lock.
#   zkObj - ZooKeeper object that provides access for adding deleting
#     node.
#
# Results:
#   A VDNetLib::Common::Lock object
#
# Side effects:
#   None
#
########################################################################

sub new
{
    my $class = shift;
    my %args = @_;
    if (not defined $args{name}) {
       $vdLogger->Error("Name for the lock object is not provided");
       VDSetLastError("ENODEF");
       return FAILURE;
    }
    if (not defined $args{zkObj}) {
       $vdLogger->Error("zkObj for the lock object is not provided");
       VDSetLastError("ENODEF");
       return FAILURE;
    }
    my $self = {
       'name' => $args{name},
       'zkObj' => $args{zkObj},
       'lockPath' => undef, # This is populated when the zk node is created.
    };
    bless $self, $class;
    return $self;
}


########################################################################
#
# Acquire --
#   Acquires the lock.
#
# Input:
#   None
#
# Output:
#   SUCCESS if the lock is acquired successfully.
#   FAILURE if anything goes wrong.
#
# Side effects:
#   None
#
########################################################################
sub Acquire
{
    # Recipe for lock's implementation is at:
    # http://zookeeper.apache.org/doc/r3.1.2/recipes.html
    my $self = shift;
    if (FAILURE eq $self->{zkObj}->CheckIfNodeExists(LOCKNODE)) {
        my $nodeAddRet = $self->{zkObj}->AddNode(LOCKNODE);
        if (FAILURE eq $nodeAddRet) {
            $vdLogger->Error("Failed to add " . LOCKNODE . "to zookeeper");
            return FAILURE;
        }
    }
    # Create an ephemeral node with a sequence number.
    my $nodePath = WRITE_LOCK_PREFIX . "$self->{name}";
    my $nodeCreate = $self->{zkObj}->AddNode(
        $nodePath, undef, undef, undef, (ZOO_SEQUENCE | ZOO_EPHEMERAL));
    if ($nodeCreate eq FAILURE) {
        $vdLogger->Error("Failed to add the lock node: $nodePath");
        VDSetLastError('ERUNTIME');
        return FAILURE;
    }
    $self->{lockPath} = $nodeCreate;
    $vdLogger->Trace("Lock node $nodeCreate created");
    my @myCreatedPath = split(/$self->{name}/, $nodeCreate);
    my $myCreatedSequence = $myCreatedPath[-1];
    my $minFound = $myCreatedSequence;
    my $starTime = time();
    my $timedOut = 0;
    while (1) {
        # Get children under _locknode_ and determine whether the node created by
        # this session has the lowest sequence or not.
        my $existingLocks = $self->{zkObj}->GetChildren(LOCKNODE);
        if ($existingLocks eq FAILURE) {
            $vdLogger->Error("Failed to get children objects of node: " . LOCKNODE);
            return FAILURE;
        }
        my @relatedLocks = grep {$_ =~ /$self->{name}/} @$existingLocks;
        my @sequenceNumbers = ();
        foreach my $existingNodePath (@relatedLocks) {
            my @splitExistingNodePath = split(/$self->{name}/, $existingNodePath);
            push (@sequenceNumbers, $splitExistingNodePath[-1]);
        }
        my @sortedSequenceNumbers = sort {$a <=> $b} @sequenceNumbers;
        $minFound = min(@sortedSequenceNumbers);
        # If node created by this session has the minimum sequence number then we
        # have acquired the lock.
        if ($minFound == $myCreatedSequence) {
            return SUCCESS;
        }
        # If node created by this session is not the minimum then we will check the
        # next lowest sequence.
        my @sequenceIndices = 0 .. $#sortedSequenceNumbers;
        my $mySequenceIndex = first {
            $sortedSequenceNumbers[$_] eq $myCreatedSequence} @sequenceIndices;
        my $nextLowerSequence = $sortedSequenceNumbers[$mySequenceIndex - 1];
        my $nextNodePath = "$nodePath$nextLowerSequence";
        my $nodeExists = $self->{zkObj}->WatchNodeForExistence(
            $nextNodePath, DEFAULT_LOCK_ACQUISITION_TIMEOUT);
        if ($nodeExists eq FAILURE) {
            # If node doesn't exist then we find other lowest node until our
            # sequence number is the least one.
            next;
        } elsif (not $nodeExists->{event}) {
            # The lower sequence number node is not removed the entire time we
            # waited on it for an update.
            $vdLogger->Error("Failed to acquire lock $self->{name}");
            VDSetLastError('ERUNTIME');
            return FAILURE;
        } elsif ($nodeExists->{event} == ZOO_DELETED_EVENT) {
            # The node that we were watching is now deleted. We need to look
            # for other lower sequence nodes now until our sequence number
            # the smallest one.
            next;
        } else {
            $vdLogger->Trace("Unexpected event $nodeExists->{event} " .
                             "happened on node $nextNodePath");
        }
        if (time() - $starTime > DEFAULT_LOCK_ACQUISITION_TIMEOUT) {
            $timedOut = 1;
            last;
        }
    } continue { last unless $minFound != $myCreatedSequence};
    if ($timedOut) {
       $vdLogger->Error("Failed to acquire lock ($self->{name}) in " .
                        DEFAULT_LOCK_ACQUISITION_TIMEOUT . "seconds");
       VDSetLastError('ETIMEOUT');
       return FAILURE;
    }
    return SUCCESS;
}


########################################################################
#
# Release --
#   Releases the lock.
#
# Input:
#   None
#
# Output:
#   SUCCESS if the lock is released successfully.
#   FAILURE if anything goes wrong.
#
# Side effects:
#   None
#
########################################################################

sub Release
{
    my $self = shift;
    if (not defined $self->{lockPath}) {
        $vdLogger->Error("Lock path is undefined. Can not release lock. " .
                         "Was the lock node created at all?");
        return FAILURE;
    }
    my $deleteRet = $self->{zkObj}->DeleteNode($self->{lockPath});
    if ($deleteRet eq FAILURE) {
        $vdLogger->Error("Failed to delete the lock node $self->{lockPath}");
        return FAILURE;
    }
    return SUCCESS;
}

1;
