########################################################################
# Copyright (C) 2010 VMWare, Inc.
# All Rights Reserved
########################################################################

########################################################################
#
# Racetrack.pm --
#
#       Class that is used by a test (bridge) that has Racetrack
#       Results handler enabled. If Racetrack result handler is
#       enabled, then one instance of this class will be instantiated
#       for each test that runs.
#
#       Besides memoizing the server/user information for reporting
#       to Racetrack, this class also memoizes the ID that is
#       associated with this particular test run in the racetrack
#       DB. For tests to be able to utilize the Comment/Verification
#       functionality in Racetrack, the ID of the current test needs
#       to be available, and this class holds that data, as well as
#       provides the implementation for the Racetrack-aware
#       functionality that is available to tests.
#
#       "Racetrack-aware" functionality available to tests includes:
#
#         TestCaseComment      - associate a comment with the current
#                                test
#         TestCaseVerification - upload a verification result for the
#                                current test
#         TestCaseLog          - upload a log to associate with the
#                                current test
#         TestCaseScreenshot   - upload a screenshot to associate with
#                                the current test.
#
#       In addition, this class also has a few static functions that
#       callers can use to access Racetrack functionality that is
#       not associated with any particular test. These include:
#
#         TestSetBegin         - Called from Racetrack result handler
#                                to initialize a new set of tests
#         TestSetEnd           - Called from Racetrack result handler
#                                to finalize a set of tests.
#         SendRequest          - Helper method to do the work of the
#                                http request.
#
########################################################################

package VDNetLib::Common::Racetrack;

eval "use LWP::UserAgent";
eval "use HTTP::Request::Common qw(POST GET)";
use Data::Dumper;

use strict;
use warnings;

use constant HTTP_SUCCESS => 200;

###########################################################################
#
# Racetrack::new --
#
#       Constructor.  Creates a new LWP agent and saves the server,
#       and user passed in.
#
# Results:
#       a new Racetrack object or undef on failure
#
# Side effects:
#          none
#
###########################################################################

sub new
{
   my $class = shift;
   my $server = shift;   # IN: the racetrack server to communicate with
   my $user = shift;     # IN: the user to associate results with
   my $buildId = shift;  # IN: the build number being tested
   my $product = shift;  # IN: the product being tested
   my $hostOs = shift;   # IN: the host Os being tested
   my $desc = shift;     # IN: a short description of the test
   my $buildType = shift;  # IN: the build type being tested
   my $branch = shift;     # IN: the branch being tested

   if ((not defined $server) ||
       (not defined $user) ||
       (not defined $buildId) ||
       (not defined $product) ||
       (not defined $hostOs) ||
       (not defined $desc)) {
      return undef;
   }

   my $agent = LWP::UserAgent->new();
   my $self = {
      server      => $server,
      user        => $user,
      agent       => $agent,
      buildId     => $buildId,
      product     => $product,
      hostOs      => $hostOs,
      buildType   => $buildType,
      branch      => $branch,
      desc        => $desc,
      testCaseId  => undef,
      testSetId   => undef,
   };

   return bless $self, $class;
}


###########################################################################
#
# Racetrack::GetTestCaseId --
#
#       Accessor for the  test case id member in this object.
#
# Results:
#       The 'testCaseId' member
#
# Side effects:
#       None
#
###########################################################################

sub GetTestCaseId
{
   my $self = shift;  # IN: invocant

   return $self->{testCaseId};
}

###########################################################################
#
# Racetrack::GetTestSetId --
#
#       Accessor for the result set id member in this object.
#
# Results:
#       The 'testSetId' member
#
# Side effects:
#       None
#
###########################################################################

sub GetTestSetId
{
   my $self = shift;  # IN: invocant

   return $self->{testSetId};
}

###########################################################################
#
# Racetrack::GetServer --
#
#       Accessor for the server member in this object.
#
# Results:
#       The 'server' member
#
# Side effects:
#       None
#
###########################################################################

sub GetServer
{
   my $self = shift;  # IN: invocant

   return $self->{server};
}

###########################################################################
#
# Racetrack::GetUser --
#
#       Accessor for the user member in this object.
#
# Results:
#       The 'user' member
#
# Side effects:
#       None
#
###########################################################################

sub GetUser
{
   my $self = shift;  # IN: invocant

   return $self->{user};
}

###########################################################################
#
# Racetrack::TestCaseBegin --
#
#       Start this test case.
#
# Results:
#       The test case ID on success undef on failure
#
# Side effects:
#       Initializes a test result in the Racetrack database. Sets the
#       internal 'id' member.
#
###########################################################################

sub TestCaseBegin
{
   my $self = shift;          # IN: invocant
   my $name = shift;     # IN: the 'name' (from feature::type::name)
   my $feature = shift;  # IN: the 'feature' (from feature::type::name)
   my $desc = shift;     # IN: Full TestID (i.e. feature::type::name)
   my $host = shift;     # IN: The host being tested
   my $start = shift;         # IN: time the test was started, in seconds
                              #     since the epoch (i.e. time())

   my @content = [ ResultSetID => $self->{testSetId},
                   Name => $name,
                   Feature => $feature,
                   Description => $desc,
                   MachineName => $host,
                 ];
   my $response = $self->SendRequest("TestCaseBegin.php", @content);
   return undef unless ($response);

   $self->{testCaseId} = $response;
   return $response;
}


###########################################################################
#
# Racetrack::TestCaseEnd --
#
#       Wrap up this test case.
#
# Results:
#       1 on success undef on failure
#
# Side effects:
#       Sets existing test result row in the Racetrack database as
#       PASS or FAIL and sets the end time.
#
###########################################################################

sub TestCaseEnd
{
   my $self       = shift; # IN: invocant
   my $status     = shift; # IN: status of test: PASS or FAIL
   my $testcaseID = shift; # IN: test case id, Optional value
   my @files = @_;         # IN: array of files to upload


   #
   # Upload the logs, then update the test result in Racetrack
   #
   foreach my $entry (@files) {
      $self->TestCaseLog($$entry[0], $$entry[1]);
   }

   $testcaseID = (defined $testcaseID) ? $testcaseID : $self->{testCaseId};
   my @content = [ ID => $testcaseID,
                   Result => $status];
   my $response = $self->SendRequest("TestCaseEnd.php", @content);

   return (defined $response ? 1 : undef);
}


###########################################################################
#
# Racetrack::TestCaseComment --
#
#       Upload a comment to associate with this test.
#
# Results:
#       1 on success undef on failure.
#
# Side effects:
#       A comment has been associated with this test in the Racetrack
#       DB.
#
###########################################################################

sub TestCaseComment
{
   my $self       = shift;  # IN: invocant
   my $comment    = shift;  # IN: the comment to log
   my $testcaseID = shift;  # test case ID, Optional

   $testcaseID = (defined $testcaseID) ? $testcaseID : $self->{testCaseId};
   my @request = [ ResultID => $testcaseID,
                   Description => $comment];
   my $response = $self->SendRequest("TestCaseComment.php", @request);
   return (defined $response ? 1 : undef);
}


###########################################################################
#
# Racetrack::TestCaseVerification --
#
#       Upload a verification result to the Racetrack server.
#
# Results:
#       1 on success undef on failure.
#
# Side effects:
#       A verification has been associated with this test in the
#       Racetrack DB.
#
###########################################################################

sub TestCaseVerification
{
   my $self = shift;       # IN: invocant
   my $desc = shift;       # IN: description of this log
   my $actual = shift;     # IN: actual value
   my $expected = shift;   # IN: expected value
   my $result = shift;     # IN: result of verification
   my $screenshot = shift; # IN: optional screenshot to include with
                           #     verification

   if ($result !~ /PASS|FAIL/) {
      return undef;
   }

   if ($result =~ /PASS/) {
      $result = "TRUE";
   } else {
      $result = "FALSE";
   }

   my @request = [ ResultID => $self->{testCaseId},
                   Description => $desc,
                   Actual => $actual,
                   Expected => $expected,
                   Result => $result];
   if (defined $screenshot) {
      if (!-e $screenshot) {
         return undef;
      }
      push @{$request[0]}, Screenshot => [$screenshot];
   }
   my $response = $self->SendRequest("TestCaseVerification.php", @request);
   return (defined $response ? 1 : undef);
}


###########################################################################
#
# Racetrack::TestCaseLog --
#
#       Upload a log to associate with this test.
#
# Results:
#       1 on success undef on failure.
#
# Side effects:
#       A log has been uploaded to the Racetrack web server
#       and associated with this test.
#
###########################################################################

sub TestCaseLog
{
   my $self = shift;     # IN: invocant
   my $desc = shift;     # IN: description of this log
   my $log = shift;      # IN: the path to the log

   if (!-e $log) {
      return undef;
   }
   my @request = [ ResultID => $self->{testCaseId},
                   Description => $desc,
                   Log => [$log]];
   my $response = $self->SendRequest("TestCaseLog.php", @request);
   return (defined $response ? 1 : undef);
}


###########################################################################
#
# Racetrack::TestCaseScreenshot --
#
#       Upload a screenshot to associate with this test.
#
# Results:
#       1 on success undef on failure.
#
# Side effects:
#       A screenshot file has been uploaded to the Racetrack web server
#       and associated with this test.
#
###########################################################################

sub TestCaseScreenshot
{
   my $self = shift;     # IN: invocant
   my $desc = shift;     # IN: description of this log
   my $file = shift;     # IN: the path to the screenshot

   if (!-e $file) {
      return undef;
   }
   my @request = [ ResultID => $self->{testCaseId},
                   Description => $desc,
                   Screenshot => [$file]];
   my $response = $self->SendRequest("TestCaseScreenshot.php", @request);
   return (defined $response ? 1 : undef);
}


###########################################################################
#
# Racetrack::TestSetBegin --
#
#       Method that initializes a Racetrack run.
#
# Results:
#       The content of the response, if everything went well. Undef
#       otherwise.
#
# Side effects:
#       A new ResultSet has been initialized in the Racetrack DB.
#
###########################################################################

sub TestSetBegin
{
   my $self = shift;

   my @content = [ BuildID => $self->{buildId},
                   User => $self->{user},
                   Product => $self->{product},
                   Description => $self->{desc},
                   HostOS => $self->{hostOs}];

   if (defined $self->{buildType}) {
      push @{$content[0]}, BuildType => $self->{buildType};
   }

   if (defined $self->{branch}) {
      push @{$content[0]}, Branch => $self->{branch};
   }

   my $response = $self->SendRequest("TestSetBegin.php", @content);
   if (not defined $response) {
      return undef;
   }
   # return undef unless ($response);

   $self->{testSetId} = $response;
   return $response;
}

###########################################################################
#
# Racetrack::TestSetData --
#
#       Method to upload a name/value pair associated with a test
#       set.
#
# Results:
#       The content of the response, if everything went well. Undef
#       otherwise.
#
# Side effects:
#       The name/value pair has been uploaded and associated with the
#       test set.
#
###########################################################################

sub TestSetData
{
   my $self = shift;
   my $name = shift;
   my $value = shift;

   my @content = [ ResultSetID => $self->{testSetId},
                   Name => $name,
                   Value => $value];
   my $response = $self->SendRequest("TestSetData.php", @content);
   return $response;
}


###########################################################################
#
# Racetrack::TestSetUpdateBuild --
#
#       Method to update the build number, branch, buildType associated 
#       with a Result Set.
#
# Results:
#       The content of the response, if everything went well. Undef
#       otherwise.
#
# Side effects:
#       The ResultSet has been updated in the Racetrack DB.
#
###########################################################################

sub TestSetUpdateBuild
{
   my $self = shift;      #IN: invocant
   my $buildId = shift;   #IN: build number
   my $branch  = shift;   #IN: product branch
   my $buildType = shift; #IN: build Type


   my $content = {ID => $self->{testSetId},
                  BuildID => $buildId,
                  Branch  => $branch,
                  BuildType =>$buildType};

   my $response = $self->TestSetUpdate($content);
   return (defined $response ? $response : undef);
}


###########################################################################
#
# Racetrack::TestSetUpdate --
#
#       Method to update the test set info.
#
# Results:
#       The content of the response, if everything went well. Undef
#       otherwise.
#
# Side effects:
#       The ResultSet has been updated in the Racetrack DB.
#
###########################################################################

sub TestSetUpdate
{
   my $self = shift;      #IN: invocant
   my $content = shift;
   if (not defined ref($content) || ref($content) ne 'HASH') {
      print "Can only update the test set using a reference to an array" .
            "Got:" . Dumper($content);
      return undef;
   }
   $content->{ID} = $self->{testSetId};
   my @contents_array = [ %$content ];
   my $response = $self->SendRequest("TestSetUpdate.php", @contents_array);
   return (defined $response ? $response : undef);
}


###########################################################################
#
# Racetrack::TestSetUpdateHostOS --
#
#       Method to update the host OS
#       with a Result Set.
#
# Results:
#       The content of the response, if everything went well. Undef
#       otherwise.
#
# Side effects:
#       The ResultSet has been updated in the Racetrack DB.
#
###########################################################################

sub TestSetUpdateHostOS
{
   my $self = shift;      #IN: invocan
   my $hostOS = shift;    #IN: Host OS


   my @content = [ ID => $self->{testSetId},
                   HostOS =>$hostOS];

   my $response = $self->SendRequest("TestSetUpdate.php", @content);
   return (defined $response ? $response : undef);
}


###########################################################################
#
# Racetrack::TestSetEnd --
#
#       Method that finalizes a Racetrack run.
#
# Results:
#       1 if everything went well. Undef otherwise.
#
# Side effects:
#       An existing ResultSet has been finalized in the Racetrack DB.
#
###########################################################################

sub TestSetEnd
{
   my $self = shift;

   my @content = [ ID => $self->{testSetId} ];
   my $result = $self->SendRequest("TestSetEnd.php", @content);
   return (defined $result ? 1 : undef);
}


###########################################################################
#
# Racetrack::SendRequest --
#
#       Method that sends a HTTP POST request to Racetrack via
#       the Racetrack handler's user agent and examines the response.
#
# Results:
#       The response is $self->{server}d for errors and if any are found undef
#       is returned otherwise the content of the response is returned.
#
# Side effects:
#       Can block depending on the contents of the POST request.
#
###########################################################################

sub SendRequest
{
   my $self = shift;
   my $script = shift;  #IN: script to invoke
   my @content = @_;    #IN: The POST content to send
   my $agent = $self->{agent};   #IN: the agent to use
   my $server = $self->{server};  #IN: Invoking instance

   my $url = "http://$server/$script";
   my $request = POST($url,
                      Content_type => 'form-data',
                      Content => @content);
   my $response = $agent->request($request);
   unless ($response) {
      print STDERR 'Got undefined response';
      return undef;
   }

   my $content = $response->content();
   if ($content =~ /Error/ or $response->{_rc} != HTTP_SUCCESS) {
      print STDERR "Request failed, HTTP return code is $response->{_rc}";
      return undef;
   }
   return $content;
}


###########################################################################
#
# Racetrack::GetHandle --
#
#       Return a handle for Racetrack session configuration.
#
###########################################################################

sub GetHandle
{
   my $self = shift;
   my $reportHandle = {
      "_reportType"    => "Racetrack",
      "server"        => $self->GetServer(),
      "user"          => $self->GetUser(),
      "testSetId"     => $self->GetTestSetId(),
      "testCaseId"    => $self->GetTestCaseId(),
   };
   return $reportHandle;
}


1;
