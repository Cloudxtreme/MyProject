##############################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
##############################################################################
package VDNetLib::Common::Iterator;

#
# VDNetLib::Common::Iterator  Module: Generates a combination using
# keys and values of a any Hash.
#
# APIs:Public Methods(inputs)
#
# new             (Reference of any Hash,
#                  Reference of Priority Array,
#                  String which acts as flag)
# NextCombination (None)
#

use strict;
use warnings;

use Data::Dumper;
use Storable 'dclone';
# TODO: Switch to GetUniqueName when pid is integrated to it.
use Time::HiRes qw(gettimeofday);

use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::Utilities;

# TODO: Ask User if they want to pass 1 or 0. But it seems "IncludeSingleton" &
# "IgnoreSingleton is more intuitive"
use constant COMBINATION_TYPE => "IgnoreSingleton";
use constant COMBINATION_FILE_DIR => "/tmp/";

###############################################################################
#
# New -
#       Construcutor of Iterator package.
#       Takes required parameters from user, generates combination and writes
#       these combinations to a file.
#       Users can then call NextCombination method on its object to fetch
#       the next available combination in the list.
#       It creates an unique filename based on timestamp to store combinations
#
# Input:
#       Hash Ref(required) - E.g. A traffic Workload which has keys and
#                            corresponding values
#                            E.g. SocketSize(key)=> "54"(value)
#       priorityArray Ref(optional) - You can mention if a key in hash should
#                                     have
#       flag (optional) - Possible values are "IgnoreSingleton" or
#                         "IncludeSingleton". If two keys are considered sets
#                         then it will generate combinations of
#                         IgnoreSingleton or IncludeSingleton type.
#                         default is IgnoreSingleton.
#
# Results:
#       object of Iterator class.
#       FAILURE in case the hash is not in appropriate format
#
# Side effects:
#       None
#
# Example:
# my $myObj = VDNetLib::Common::Iterator->new(
#                       workloadHash => $var->{'WORKLOADS'}->{'TRAFFIC'},
#                       priority => \@Priority,
#                       flag => "IncludeSingleton"
#                       );
# where  'TRAFFIC' => {
#              'ToolName' => "netperf,iperf,ping", # A list of CSV
#              'NoOfInbound' => "2 ", # Single Value
#              'MessageSize' => "54-52,1", # Start to end range with step size
#               }
###############################################################################

sub new
{
   my $class    = shift;
   my %opts  = @_;
   my $workloadHash      = $opts{'workloadHash'};
   my $orderofKeys       = $opts{'priority'};
   my $constraintHash    = $opts{'constraintHash'};

   my $flag = $opts{'flag'};
   # Directory where the logs for this workload are stored. E.g. if traffic logs
   # are stored in some dir then he can pass the dir name so that iterator combo
   # file is also store at same location.
   my $logDir = $opts{'logdir'};
   my $combinationFile;
   my $fileHandle = undef;

   if (not defined $workloadHash) {
      $vdLogger->Error("Workload Hash not provided to new");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (not defined $flag) {
      $vdLogger->Debug("Setting the Combination flag to ". COMBINATION_TYPE);
      $flag = COMBINATION_TYPE;
   }

   # If logDir is not defined then use the default location.
   if (not defined $logDir) {
      $logDir = COMBINATION_FILE_DIR;
   } else {
      if ($logDir !~ /\/$/) {
         $logDir = $logDir . "/";
      }
   }

   unless(-d $logDir){
      my $ret = `mkdir -p $logDir`;
      if($ret ne "") {
         $vdLogger->Error("Failed to create iterator logs dir:".
                          "$logDir");
      }
   }

   $combinationFile = VDNetLib::Common::Utilities::GetTimeStamp();
   # Attaching the pid of the process to file Name
   $combinationFile = $logDir . "IteratorCombo-".
                      $combinationFile . "-$$";
   if (-f $combinationFile) {
      if (!unlink($combinationFile)) {
         $vdLogger->Warn("Unable to delete the file: $combinationFile, ".
                         "reason: $!");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }
   if (not defined open($fileHandle, "+>$combinationFile")) {
      $fileHandle = undef;
      $vdLogger->Error("Unable to open log file $combinationFile for writing:"
                       ."$!");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   $vdLogger->Trace("Combination file created:$combinationFile");
   my $self  = {
      fileHandle => $fileHandle,
      fileName => $combinationFile,
   };



   bless $self, $class;
   my $ret = $self->FormatHash(workloadHash  => $workloadHash,
                               priority      => $orderofKeys,
                               flag          => $flag,
                               constraintHash => $constraintHash);
   if ($ret ne SUCCESS) {
      $vdLogger->Error("Formatting hash failed");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return $self;
}


###############################################################################
#
# FormatHash -
#       A private method.
#       Converts any Hash into a format which is easy to generate Combinations.
#       The hash should be strictly one level (flat), meaning, this module
#       will not understand hash of hash or any complicated structure.
#       E.g. MessageSize => "54-51,1" is converted to hash where key is
#            MessageSize pointing to array of 54,53,52,51.
#            Another E.g. BurstType => "tcp_stream,tcp_rr,udp_stream" will be
#            converted to hash where key is BurstType pointing to array of
#            tcp_stream,tcp_rr,udp_stream.
#       After formatting the Hash it calls Iterator for generating
#       combinations.
#
# Input:
#       workloadHash Ref(required) - E.g. A traffic Workload which has keys and
#                                      corresponding values
#       priority (optional) - You can mention if a key in hash should have
#                             priority over same key in TDD. E.g.
#                             my @Priority = qw(
#                             BurstType
#                             MessageSize
#                             TDD
#                             ProtocolType);
#                             In this case, ProtocolType from hash will have
#                             priority over ProtocolType from TDD while
#                             BurstType, MessageSize from TDD will have priority
#       flag (required) - Values are "IgnoreSingleton" or "IncludeSingleton"
#                         If two keys are considered sets then it will generate
#                         combinations of IgnoreSingleton or IncludeSingleton
#                         type. Default is IgnoreSingleton.
#
# Results:
#       SUCCESS - in case everything goes well
#       FAILURE - in case of some error
#
# Side effects:
#       None
#
###############################################################################

sub FormatHash
{
   if(caller ne __PACKAGE__){
      $vdLogger->Error("Private method should only be called by its package");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $self = shift;
   my %opts = @_;
   my $hashRef       = $opts{'workloadHash'};
   my $OrderofKeys   = $opts{'priority'};
   my $constraintHash = $opts{'constraintHash'};
   my $flag = $opts{'flag'};

   # Copy it so that you dont mess with other's hash as they
   # have passed Hash reference.
   my %workloadHash = %$hashRef;

   if (!%workloadHash || not defined $flag) {
      $vdLogger->Error("Either WorkloadHash or flag not provided for".
                       "formatting");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my %formattedWorkloadHash;

   # Check for API testing. We do that by
   # first locating which keys have "magic".
   foreach my $key (keys %workloadHash) {
      my $result = $self->FindMagicKey($workloadHash{$key});
      if (@$result) {
         $vdLogger->Info("ignoring ExpectedResultCode, generating new " .
                         "ExpectedResultCode for each payload");
         delete $workloadHash{$key}{ExpectedResultCode};
         foreach my $index (keys %{$workloadHash{$key}}) {
            $vdLogger->Info("Magic keyword found for $key, creating combos");
            $vdLogger->Debug("Keys having magic keyword are " . Dumper($result));
            my $combos =
               $self->GenerateCombo('KeysBeTested' => $result,
                                    'inputHash'    => $workloadHash{$key}{$index},
                                    'constraintHash'=> $constraintHash);
           $formattedWorkloadHash{$key} = $combos;
           $vdLogger->Info("Combo generated" . Dumper(\%formattedWorkloadHash));
           delete $workloadHash{$key};
         }
      }
   }

   while(scalar keys %workloadHash){
      # First iterate on Keys according to order of Preference
      my %formattedKeyValue;
      my %tempHash;
      # 1) Call OrderOfPreference which will return the order in which keys
      #    should be read for preference. Refer method: OrderOfPreference.
      #    The key popped first from @Priority array will have precedence over
      #    keys popped last.
      my $orderedWorkloadKey = $self->OrderOfPreference(
                                                workloadhash =>\%workloadHash,
                                                priority=> $OrderofKeys
                                                );
      if(defined $orderedWorkloadKey){
         # 2) Call ConvertWorkloadHash which will contain logic of reading
         #    different types of keys, what each keys means and return
         #    formatted Workload Hash which is easier for creation of
         #    session Objects.
         %formattedKeyValue = $self->ConvertHash($orderedWorkloadKey,
            \%workloadHash);
         if(!%formattedKeyValue){
            $vdLogger->Error("Converting workload hash to array of ".
                             "array failed");
            VDSetLastError("EINVALID");
            return FAILURE;
         }
         %tempHash = (%formattedWorkloadHash, %formattedKeyValue);
         %formattedWorkloadHash = %tempHash;
         delete $workloadHash{$orderedWorkloadKey};
      } else {
         # Now iterate on the remaining keys which were not given in
         # Priority Array
         foreach my $unOrderedWorkloadKey (keys %workloadHash){
            %formattedKeyValue = $self->ConvertHash($unOrderedWorkloadKey,
            \%workloadHash);
            if(!%formattedKeyValue){
               $vdLogger->Error("Converting workload hash to array of ".
                                "array failed");
               VDSetLastError("EINVALID");
               return FAILURE;
            }
            %formattedWorkloadHash = (%formattedWorkloadHash, %formattedKeyValue);
            delete $workloadHash{$unOrderedWorkloadKey};
         }
      }
   }
   # Now that the formatted  Hash is ready call the Iterator
   # method which will generate combinations depending on the flag
   my $ret = $self->CombinationsIterator(
                             formattedWorkload => \%formattedWorkloadHash,
                             flag => $flag
                             );
   if ($ret ne SUCCESS) {
      $vdLogger->Error("Iterator returned failure");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}


###############################################################################
#
# CombinationsIterator -
#       A private method. Can be called only by Iterator package.
#       Generates combinations of IncludeSingleton or IgnoreSingleton types
#       given two or more sets. These combinations represent a test data.
#       More algorithmic explanation inside the method.
#       Calls the WriteToFile method which writes all these combinations to
#       a file to reduce memory requirement.
#
# Input:
#       Formatted Hash Ref(required) - E.g. A traffic Workload which
#                                      has keys & corresponding values
#       flag (required) - Values are "IgnoreSingleton"(default) or
#                         "IncludeSingleton"
#                         E.g.
#                         MessageSize = 54,53
#                         BurstType   = stream, rr
#                         A IncludeSingleton set would look like
#                         {54} {53} {54,stream} {53,stream} {54,rr} {53,rr}
#                         {stream} {rr}
#                         IgnoreSingleton set would look like
#                         {54,stream} {53,stream} {54,rr} {53,rr}
#
# Results:
#       SUCCESS - in case everything goes well
#       FAILURE - in case of some error
#
# Side effects:
#       None
#
###############################################################################

sub CombinationsIterator
{
   if(caller ne __PACKAGE__){
      $vdLogger->Error("Private method should only be called by its package");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $self = shift;
   my %opts = @_;
   my $workloadHash = $opts{'formattedWorkload'};
   my $flag = $opts{'flag'};
   $vdLogger->Trace("Input to iterator are flag:$flag and:".
                     Dumper($workloadHash));

   if (!%$workloadHash || not defined $flag) {
      $vdLogger->Error("Either WorkloadHash or flag not provided for".
                       "iteration");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Array which will contain all the combinations
   my $comboContainer = {};
   my $comboPointer;
   my ($workloadKey, $workloadValue, $workloadValues, $objKey);
   my $tempContainer = {};
   my $comboCounter = 0;

   # For each key in  hash(e.g. BurstType), copy all its values
   # (stream, rr) in array. Then for each element of array create a temp hash
   # Copy this temp hash(tempContainer) in Permanent hash(comboContainer).
   # For IgnoreSingleton: In next iteration pick all elements of permanent hash
   #                   combine it with all keys of this iteration, store it in
   #                   temp hash and delete the permanent hash. Now copy the
   #                   temp hash to permanent hash
   # For IncludeSingleton: In next iteration, store the keys of current
   #                   key(nested hash) in temp hash then pick all elements of
   #                   permanent hash and combine it with all keys of this
   #                   iteration, store it in temp hash.
   #                   Now merge both temp hash and permanent hash.
   foreach $workloadKey (keys %$workloadHash){
      $workloadValues = $workloadHash->{$workloadKey};
      my $counter = scalar @$workloadValues;
      my @copyWV = @$workloadValues;
      my $i=0;
      my $attachID = undef;
      while($counter--){
         $workloadValue = $copyWV[$i];
         $i++;
         $attachID = $self->ReturnID($comboCounter);
         if($flag =~ m/IncludeSingleton/i || !%$comboContainer){
            $tempContainer->{"combo-id-".$attachID}->{$workloadKey} = $workloadValue;
            $comboCounter++;
         }
         # Now take all combinations from comboContainer hash
         # create their duplicates(tempContainer) and add the
         # new key=value to this duplicate.
         foreach $comboPointer (sort keys %$comboContainer){
            my $hashRef = $comboContainer->{$comboPointer};
            $attachID = $self->ReturnID($comboCounter);
            foreach $objKey (sort keys %$hashRef ){
               $tempContainer->{"combo-id-".$attachID}->{$objKey}
                          = $comboContainer->{$comboPointer}->{$objKey};
            }
            $tempContainer->{"combo-id-".$attachID}->
                          {$workloadKey} = $workloadValue;
            $comboCounter++;
         }
      }
      if($flag =~ m/IgnoreSingleton/i){
         $comboContainer = {};
      }
      %$comboContainer = (%$tempContainer, %$comboContainer);
      $tempContainer = {};
   }

   # Carrying the combination hash can be huge memory hog
   # Dump the combinations in a file and read a combination as
   # requested by the user

   my $ret = $self->WriteToFile($comboContainer);
   if ($ret ne SUCCESS) {
      $vdLogger->Error("Writing Combinations to the file failed");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;

}


###############################################################################
#
# WriteToFile --
#       A private method to write the combinations into a file.
#
#
# Input:
#       Combination Container Ref - (required) A datastructure which contains
#                                   all combinations to be written to file.
#
# Results:
#       SUCCESS - in case everything goes well
#       FAILURE - in case of some error
#
#
# Side effects:
#       None.
#
###############################################################################

sub WriteToFile
{
   if(caller ne __PACKAGE__){
      $vdLogger->Error("Private method should only be called by its package");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my ($self, $comboContainer) = @_;
   my ($comboObject, $objKey, $combinationFile);
   my $fileHandle = undef;
   $fileHandle =  $self->{fileHandle};

   # Check if the hash is empty
   if (!%$comboContainer) {
      $vdLogger->Error("Combinations not provided for writting in file");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # Forces a flush right away and after every write.
   $fileHandle->autoflush(1);

   # Write all the combinations in the file.
   foreach $comboObject (sort keys %$comboContainer){
      my $hashRef = $comboContainer->{$comboObject};
         foreach $objKey (keys %$hashRef ){
            # Write in a format such as
            # messagesize=54, bursttype=stream
            my $value = $comboContainer->{$comboObject}->{$objKey};
            my $dumper = new Data::Dumper([$value]);
            $dumper->Terse(1);
            $dumper->Indent(0);
            $value = $dumper->Dump();
            print $fileHandle $objKey . '===' .
                              $value .
                              ';;;';
         }
      print $fileHandle "\n";
   }

   $vdLogger->Trace("Set the seek to 0 for reading".
                    " the file from byte 0");
   seek($fileHandle,0,0);
   return SUCCESS;
}


###############################################################################
#
# NextCombination --
#       Just open the file, read the file, Call the LineToHash method which
#       will generate hash from the line pointed by seekPointer.
#       Return the hash, which is a combination of key,value pairs.
#
# Input:
#       None. It refers to the fileName in object and return the next
#       combination line.
#
# Results:
#       combination hash (value) - A combination of workload key-value pair.
#       undef   - in case there are no more combinations to iterate on.
#       FAILURE - in case of error.
#
# Side effects:
#       None.
#
###############################################################################

sub NextCombination
{
   my ($self) = @_;
   my ($combination);
   my $fileHandle;
   my %comboHash = ();

   $fileHandle =  $self->{fileHandle};
   while($combination = <$fileHandle>){
      chomp($combination);
      $vdLogger->Trace("Read string:$combination from file:".
                       "$self->{fileName}");
      %comboHash = $self->LineToHash($combination);
      if (!%comboHash) {
         $vdLogger->Error("Combination retuned by LineToHash is empty");
         VDSetLastError("EFAIL");
         return FAILURE;
      }
      $vdLogger->Debug("Returning next combination as ".
                       Dumper(\%comboHash));
      return %comboHash;
   }

   $vdLogger->Debug("No more combinations to iterate on. ".
                     "Returning ". Dumper(\%comboHash));
   return %comboHash;
}


###############################################################################
#
# LineToHash --
#       A private method which converts string to hash.
#
# Input:
#       CombinationLine- A string for converting it into hash of combination.
#
# Results:
#       combination hash - A combination of  key-value pair.
#       undef   - in case the combination string is empty.
#
# Side effects:
#       None.
#
###############################################################################

sub LineToHash
{
   if(caller ne __PACKAGE__){
      $vdLogger->Error("Private method should only be called by its package");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my ($self, $comboLine) = @_;
   $vdLogger->Trace("Converting string to Hash");

   my %hash =();
   my @workloadParams = [];

   if (not defined $comboLine) {
      $vdLogger->Warn("Combination string not provided for parsing.
                       Returning undef...");
      return %hash;
   }

   chomp($comboLine);
   # For a line like messagesize=54, bursttype=stream,
   # generaate a hash out of this line.

   @workloadParams = split(';;;',$comboLine);
   my $paramCount = scalar @workloadParams;
   $paramCount--;
   while($paramCount--){
      $workloadParams[$paramCount] =~ s/^\s+//; #remove leading space
      $workloadParams[$paramCount] =~ s/\s+$//; #remove trailing space
   }

   $paramCount = scalar @workloadParams;
   while($paramCount--){
      # To support hash values which are passed as string we now use
      # regex instead of split. E.g.
      # stressoptions={NetCopyToLowSG => 150}
      my @singleParams = $workloadParams[$paramCount] =~ /^(.*?)===(.*)/;
       my $value = eval($singleParams[1]);
      if ($@) {
         $vdLogger->Error("Failed to resolve $singleParams[1] : $@");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $hash{$singleParams[0]} = $value;
   }
   return %hash;
}


###############################################################################
#
# ConvertHash -
#       A private method.
#       Converts the Hash into a format which Session & module
#       understands.
#       E.g. TrafficKey => TrafficValue
#            MessageSize => "54-51,1" is converted to hash where key is
#            MessageSize pointing to array of 54,53,52,51.
#       Another E.g. BurstType => "tcp_stream,tcp_rr,udp_stream" will be
#       converted to hash where key is BurstType pointing to array of
#       tcp_stream,tcp_rr,udp_stream.
#       Session module only understands the later format and thus it is
#       easier for Session module to pick each array value and create
#       a unique session out of it.
#       This will also prevent changing Sessions.pm if in future, the traffic
#       hash changes.
#
#
# Input:
#       trafficKey to be converted into a formattedHash (required)
#       trafficHash in which this key is present        (required)
#
# Results:
#       a hash containing key as one of the Key and value as
#       array of all the values of that Key.
#       undef in case of FAILURE.
#
# Side effects:
#       None
#
###############################################################################

sub ConvertHash
{
   if(caller ne __PACKAGE__){
      $vdLogger->Error("Private method should only be called by its package");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my ($self, $workloadKey, $workloadHashRef) = @_;
   my $rangeFlag = 0;
   my %sessionParams = ();
   my @sessionValues;
   my ($numberOfBound, @workloadParams,
       @firstParam, $paramCount, $step, $i) = undef;

   if (ref($workloadHashRef->{$workloadKey})){
      push(@sessionValues, $workloadHashRef->{$workloadKey});
      $sessionParams{$workloadKey} = [@sessionValues];
   } else {
      # Split on "]," if component notation i.e. "[.*]" is present. Otherwise
      # split on "," to support the scenario where the provided value does not
      # contain components. Note that a value which contains both components
      # and some other non component values will not be separated properly.
      my $compFollowedByNonComp = '^.*\[.*\]\s*,.*[^\[\]]$';
      my $nonCompFollwedByComp = '^[^\[\]]+\s*,.*\[.*\]$';
      my $val = $workloadHashRef->{$workloadKey};
      if (($val =~ /$compFollowedByNonComp/ || $val =~
           /$nonCompFollwedByComp/)) {
          $vdLogger->Error("Can not mix component (e.g. x.[1].y.[2]) " .
                           "and non-component (e.g. tcp) notations: $val");
          return undef;
      }
      my $splitKey = ($workloadHashRef->{$workloadKey} =~ /\[.*\]/) ? '(?<=\]),' : ',';
      @workloadParams = split(/$splitKey/,$workloadHashRef->{$workloadKey});
      $paramCount = scalar @workloadParams;
      while($paramCount--){
         $workloadParams[$paramCount] =~ s/^\s+//; #remove leading space
         $workloadParams[$paramCount] =~ s/\s+$//; #remove trailing space
      }
      $paramCount = scalar @workloadParams;

      # Now if the value has '-' in it then it is range e.g. 54-51,1
      if(($workloadHashRef->{$workloadKey}  =~ m/-/) &&
         ($workloadHashRef->{$workloadKey} !~ m/\[.*\]/)){

         @firstParam = split('-',$workloadParams[0]);
         # Checking if both the parameters are digit. e.g both 54, 51 should
         # be digits.
         if( ($firstParam[0] =~ /^[+-]?\d+$/) &&
             ($firstParam[1] =~ /^[+-]?\d+$/) ){
            $rangeFlag=1;
            if(defined $workloadParams[1] && (1*$workloadParams[1])){
               $step = $workloadParams[1];
            } else {
               # If step size is not defined use default step size as 1
               $vdLogger->Debug("Step size is not defined. Setting the default ".
                          "step size as 1 ");
               $step = 1;
            }
            if($firstParam[0]<= $firstParam[1]){
               for($i=$firstParam[0]; $i <= $firstParam[1]; $i=$i+$step){
                  push(@sessionValues,$i);
               }
            } else {
               for($i=$firstParam[0]; $i >= $firstParam[1]; $i=$i-$step){
                  push(@sessionValues,$i);
               }
            }
          }
       } else {
            $rangeFlag=0;
       }

       if($rangeFlag==0) { # This code block handles list of
          # values e.g. stream,rr AND it can handle -ve value
          while($paramCount--){
             $sessionValues[$paramCount] = $workloadParams[$paramCount];
          }
       }
      $sessionParams{$workloadKey} = [@sessionValues];
   }

   return %sessionParams;
}


##############################################################################
#
# OrderOfPreference -
#       A private method.
#       Pops keyword, checks if it is in hash and returns that
#       key, thus maintaining order in which hash keys will be
#       given preference according to that array.
#       Example.
#         'MessageSize' => "1,2",
#         'VMOps' => "suspend,resume           gives
#          suspend 1, resume 1, suspend 2, resume 2.    Now if you want
#          1 suspend, 2 suspend, 1 resume, 2 resume.    you will have to give
#         'VMOps' => "suspend,resume
#         'MessageSize' => "1,2",
#       Thus instead of giving two different hash, just pass the Priority
#       array with altered order.
#
# Input:
#       Hash (required)
#       Priority     (optional) - Can be null, in which case, no order will
#                                 be followed.
#
# Results:
#       keyword of Hash, if it is in @OrderofKeys also
#       undef if keyword is not in @OrderofKeys
#
# Side effects:
#       None
#
##############################################################################

sub OrderOfPreference
{

   if(caller ne __PACKAGE__){
      $vdLogger->Error("Private method should only be called by its package");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $self= shift;
   my %opts = @_;
   my $workloadHashRef = $opts{'workloadhash'};
   my $OrderofKeys = $opts{'priority'};

   if (!%$workloadHashRef) {
      $vdLogger->Error("WorkloadHash not provided for Ordering");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (not defined $OrderofKeys) {
      $vdLogger->Debug("No array is provided for ordering preference");
      return undef;
   }

   my $keyOfPreference;
   my $keyInWorkloadHash;
   my $keyInWorkloadHashLC;

   $vdLogger->Trace("Priority array:". Dumper($OrderofKeys));
   while(@$OrderofKeys){
      $keyOfPreference = lc(pop(@$OrderofKeys));
      foreach $keyInWorkloadHash (sort keys %$workloadHashRef){
         $keyInWorkloadHashLC = lc($keyInWorkloadHash);
         if($keyInWorkloadHashLC eq $keyOfPreference){
            $vdLogger->Debug("returning priority key:$keyInWorkloadHash");
            return $keyInWorkloadHash;
         }
      }
   }
}

##############################################################################
#
# ReturnID --
#       A private utility function for appending id as key in a hash
#       depending on the counter value. This helps in keeping the hash
#       formatted, thus sort keys on the hash can be used to read keys
#       in an order.
#
#
# Input:
#       counter - An integer number.
#
# Results:
#       ID - A string that can be used as keys in an array.
#
# Side effects:
#       None
#
##############################################################################

sub ReturnID
{
   if(caller ne __PACKAGE__){
      $vdLogger->Error("Private method should only be called by its package");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $self = shift;
   my $counter = shift;
   my $attachID = undef;

   if(0 <= $counter && $counter < 10){
      $attachID = "00000" . $counter;
   }
   if(10 <= $counter && $counter < 100){
      $attachID = "0000" . $counter;
   }
   if(100 <= $counter && $counter < 1000){
      $attachID = "000" . $counter;
   }
   if(1000 <= $counter && $counter < 10000){
      $attachID = "00" . $counter;
   }
   if(10000 <= $counter && $counter < 100000){
      $attachID = "0" . $counter;
   }

   return $attachID;
}


##############################################################################
#
# DESTROY --
#       Destructor of the package. Kicks in when the object goes out of scope
#       Deletes the file which stores the iterations, as part of cleanup
#
# Input:
#       None
#
# Results:
#       None
#
# Side effects:
#       None
#
##############################################################################

sub DESTROY
{
   my $self = shift;
   my $combinationFile = $self->{fileName};

   my $fileHandle;
   $fileHandle =  $self->{fileHandle};
   close $fileHandle;
   $vdLogger->Trace("Closed file handle of $combinationFile".
                    ". Now deleting it...");

   if (-f $combinationFile) {
      if (!unlink($combinationFile)) {
         $vdLogger->Warn("Unable to delete the file: $combinationFile, ".
                         "reason: $!");
         return undef;
      }
   }
   $vdLogger->Debug("Deleted Iterator's combination file: $combinationFile");
}


##############################################################################
#
# FindMagicKey --
#       This method tries to go through the nested hash and finds out which key
#       hash the value set to "magic". If a key is found having "magic" value,
#       the api puts the key in an array and returns array refrence.
#
# Input:
#       hashWithMagicKeys - Nested hash which might have values equal to "magic"
#
# Results:
#       SUCCESS - An array reference containing list of keys
#       FAILURE - An empty array reference
#
# Side effects:
#       None
#
##############################################################################

sub FindMagicKey
{
   my $self = shift;
   my $hashWithMagicKeys = shift;
   my @arrayOfKeysSetToMagic;
   if (ref($hashWithMagicKeys) ne "HASH") {
      return \@arrayOfKeysSetToMagic;
   }
   foreach my $keys (keys %$hashWithMagicKeys) {
      if (defined($hashWithMagicKeys->{$keys})) {
         if (ref($hashWithMagicKeys->{$keys}) eq "HASH") {
            my $arrayOfKeysSetToMagicTemp = $self->FindMagicKey($hashWithMagicKeys->{$keys});
            push @arrayOfKeysSetToMagic, @$arrayOfKeysSetToMagicTemp;
         } elsif (ref($hashWithMagicKeys->{$keys}) eq "ARRAY") {
            foreach my $arrayElement (@{$hashWithMagicKeys->{$keys}}) {
               my $arrayOfKeysSetToMagicTemp = $self->FindMagicKey($arrayElement);
               push @arrayOfKeysSetToMagic, @$arrayOfKeysSetToMagicTemp;
            }
         } elsif ($hashWithMagicKeys->{$keys} eq "magic") {
            push @arrayOfKeysSetToMagic, $keys;
         }
      } else {
         $vdLogger->Info("The value for $keys is not defined in hash");
      }
   }
   return \@arrayOfKeysSetToMagic;
}


##############################################################################
#
# GenerateCombo --
#       This method creates array of hashes, where each hash is a payload which
#       is fed to the core apis. These hashes also have a key called Expected
#       return code
#
# Input:
#       inputHash      - Nested hash which have values equal to "magic"
#                            {
#                             'name' => "magic",
#                             'tags' => [
#                                {
#                                 'Tag' =>
#                                   {
#                                    'tag' => 'TAG123456789123456789',
#                                    'scope' => 'magic'
#                                   }
#                                }
#                              ],
#                            },
#       KeysBeTested   - Array reference, having keys which will be assigned good
#                        and bad values.
#       constraintHash - Constrant database sent from the Workload scope
#
# Results:
#       SUCCESS - An array reference containing Hashes
#        [
#            {
#             '[1]' => {
#                'name' => 'TZ1',
#                'tags' => [
#                   {
#                      'Tag' => {
#                         'tag' => 'TAG123456789123456789',
#                         'scope' => 'TAG12345678912345678'
#                      },
#                   },
#                ]
#             },
#             'ExpectedReturnCode' => "201",
#            },
#            {
#             '[1]' => {
#                'name' => 'TZ1456789',
#                'tags' => [
#                   {
#                      'Tag' => {
#                         'tag' => 'TAG123456789123456789',
#                         'scope' => 'TAG12345678912345678'
#                      },
#                   },
#                ]
#             },
#             'ExpectedReturnCode' => "201",
#            },
#        ]
#       FAILURE - Not done error check
#
# Side effects:
#       None
#
##############################################################################

sub GenerateCombo
{
   my $self = shift;
   my %args         = @_;
   my $KeysBeTested = $args{KeysBeTested};
   my $inputHash    = $args{inputHash};
   my @returnArray;
   my $copyConstrainthash = $args{constraintHash};
   my $Constrainthash = dclone $copyConstrainthash;

   foreach my $keyToBeTestbed (@$KeysBeTested) {
      my $ComboHash = dclone $inputHash;

      # Step1: Normalize the input hash, replace the the all keys which
      # have the value "magic" with the first good value under Constraint
      # Database, and leave the key under test as is.
      my $NormalizedHash = $self->NormalizeMagic($ComboHash, $copyConstrainthash);

      # Step2: Replace the key-under-test's value
      # from magic to tuple <key>.good/badValue[index]
      my $ResolvedTupleInstanceHash =
         $self->RecursiveResolveInstanceTuple($NormalizedHash, $Constrainthash, $copyConstrainthash);
         foreach my $ValueHash (@{$Constrainthash->{$keyToBeTestbed}{goodValue}}) {
         my $FinalPayload = {};
         my $goodValue = $ValueHash->{value};
         my $CopyResolvedTupleInstanceHash = dclone $ResolvedTupleInstanceHash;

         # Step3: Replace the tuple <key>.good/badValue[index] with
         # the value goodValue[index] or badValue[index] based on the
         # Constraint database (copyConstrainthash). But there will
         # be cases where the values provided by InjectValue will
         # inturn have tuples. To resolve those tuples, we call
         # RecursiveResolveInstanceTuple() again to replace the tuples
         # with values from Constraint Database.
         my $payloadNeedsToBeDereferenced =
                             $self->InjectValue($goodValue,
                                                $keyToBeTestbed,
                                                $CopyResolvedTupleInstanceHash,
                                                $copyConstrainthash);

         # Step4: To resolve those tuples, we call
         # RecursiveResolveInstanceTuple() again to
         # replace the tuples with values from
         #  Constraint Database.
         my $ResolvedTupleInstanceHash =
            $self->RecursiveResolveInstanceTuple($payloadNeedsToBeDereferenced,
                                                 $copyConstrainthash);
         $FinalPayload->{'[1]'} = $payloadNeedsToBeDereferenced;
         if ($ValueHash->{metadata}) {
            # Step5: Adding the expected result code and metadata
            $FinalPayload->{'[1]'}{metadata} = $ValueHash->{metadata};
            if (!($ValueHash->{metadata}{skipstorage})){
               $FinalPayload->{'[1]'}{metadata}{skipstorage} = "yes";
            }
         }
         push @returnArray, $FinalPayload;
      }
      # Repeat the same for bad value.
      # We can merge this in future
      foreach my $ValueHash (@{$Constrainthash->{$keyToBeTestbed}{badValue}}) {
         my $FinalPayload = {};
         my $badValue = $ValueHash->{value};
         my $CopyResolvedTupleInstanceHash = dclone $ResolvedTupleInstanceHash;
         my $payloadNeedsToBeDereferenced =
                             $self->InjectValue($badValue,
                                                $keyToBeTestbed,
                                                $CopyResolvedTupleInstanceHash,
                                                $copyConstrainthash);
         my $ResolvedTupleInstanceHash =
            $self->RecursiveResolveInstanceTuple($payloadNeedsToBeDereferenced,
                                                 $copyConstrainthash);
         $FinalPayload->{'[1]'} = $payloadNeedsToBeDereferenced;
         if ($ValueHash->{metadata}) {
            $FinalPayload->{'[1]'}{metadata} = $ValueHash->{metadata};
            if (!($ValueHash->{metadata}{skipstorage})){
               $FinalPayload->{'[1]'}{metadata}{skipstorage} = "yes";
            }
         }
         push @returnArray, $FinalPayload;
      }
   }
   return \@returnArray;
}


##############################################################################
#
# RecursiveResolveInstanceTuple --
#       This method tries find out if a key has the value "magic". If yes,
#       it tries to replace the value with the tuple <key>.good/badValue[index].
#
# Input:
#       $inputHash - Nested hash having magic values
#                    {
#                       'transportzone' => {
#                          'name' => "TZ",
#                          'tags' => [
#                             {
#                             'Tag' => "magic",
#                             },
#                          ]
#                       },
#                    }
#       constraintHash - Constrant database sent from the Workload scope
#
# Results:
#       SUCCESS - Hash ref where the tuple is resolved with good or bad value
#                    {
#                       'transportzone' => {
#                          'name' => "TZ",
#                          'tags' => [
#                             {
#                             'Tag' => "Tag.goodValue[0]",
#                             },
#                          ]
#                       },
#                    }
#       FAILURE - Not returning any failures
#
# Side effects:
#       None
#
##############################################################################

sub RecursiveResolveInstanceTuple
{
   my $self = shift;
   my $inputHash = shift;
   my $copyConstrainthash = shift;
   my $Constrainthash = dclone $copyConstrainthash;
   my @KeysOfInputHash = keys %$inputHash;

   foreach my $KeyOfInputHash (@KeysOfInputHash) {
       if (not defined $Constrainthash->{$KeyOfInputHash}) {
          next;
       }
       # 1. Check Type
       # 1.1 If type is Attribute, then get the first good value
       if ($Constrainthash->{$KeyOfInputHash}{type} eq "attribute") {
          $inputHash->{$KeyOfInputHash} =
                     $self->ResolveInstanceTuple($inputHash->{$KeyOfInputHash},
                     $copyConstrainthash);
       }
       # 1.2 If type is Array, then look at instance type,
       # Replace with the array of goodValue[0]
       if ($Constrainthash->{$KeyOfInputHash}{type} eq "array") {
          my $arrayOfObjects =
                     $self->ResolveInstanceTuple($inputHash->{$KeyOfInputHash},
                                                 $copyConstrainthash);
          my @inputArray = ();
          foreach my $instance (@$arrayOfObjects) {
             my $arrayHash = {};
             my $instanceKey = $Constrainthash->{$KeyOfInputHash}{instanceType};
             $arrayHash->{$instanceKey} = $instance;
             my $storeHash->{$instanceKey} =
                               $self->RecursiveResolveInstanceTuple(
                                                 $arrayHash,
                                                 $copyConstrainthash);
             push @inputArray, $storeHash;
          }
          $inputHash->{$KeyOfInputHash} = \@inputArray;
       }
       # 1.3 if type is Object, then look at attributes
       # Replace with the array of goodValue[0]
       if ($Constrainthash->{$KeyOfInputHash}{type} eq "object") {
          if (ref($inputHash->{$KeyOfInputHash}) eq "HASH") {
             $inputHash = $self->RecursiveResolveInstanceTuple(
                                                 $inputHash->{$KeyOfInputHash},
                                                 $copyConstrainthash);
          } else {
             my $ObjectHash = $self->ResolveInstanceTuple(
                                                 $inputHash->{$KeyOfInputHash},
                                                 $copyConstrainthash);
             $inputHash = $self->RecursiveResolveInstanceTuple(
                                                 $ObjectHash,
                                                 $copyConstrainthash);
          }
       }
    }
    return $inputHash;
}


##############################################################################
#
# InjectValue --
#       This method tries find out if a key has the value <key>.goodValue[index]
#       or <key>.badValue[index]. If yes, it tries to replace the tuples with
#       the value goodValue[index] or badValue[index] based on the Constraint
#       database (copyConstrainthash) supplied from the Workload scope.
#
# Input:
#       comboValue - good/bad values for keyTobeReplacedWithComboValue under
#                       Constrant database
#       keyTobeReplacedWithComboValue - key under test
#       copyinputHash - Nested hash having tuples in for
#                       <key>.good/badValue[index]
#                    {
#                       'transportzone' => {
#                          'name' => "TZ",
#                          'tags' => [
#                             {
#                             'Tag' => "Tag.goodValue[0]",
#                             },
#                          ]
#                       },
#                    }
#       copyConstrainthash - Constrant database sent from the Workload scope
#
# Results:
#       SUCCESS - Hash ref where the tuple is resolved with good or bad value
#                 {
#                  'transportzone' => {
#                     'name' => "magic",
#                     'tags' => [
#                        {
#                        'Tag' => {
#                           'tag' => "TAG1234567891234567891234567891234567890",
#                           'scope' => "TAG12345678912345678",
#                           },
#                        },
#                     ]
#                  },
#                }
#       FAILURE - Not returning any failures
#
# Side effects:
#       None
#
##############################################################################

sub InjectValue
{
   my $self = shift;
   my $comboValue = shift;
   my $keyTobeReplacedWithComboValue = shift;
   my $CopyinputHash = shift;
   my $inputHash = dclone $CopyinputHash;
   my $copyConstrainthash = shift;

   my $Constrainthash = dclone $copyConstrainthash;
   my @KeysOfInputHash = keys %$inputHash;
   foreach my $KeyOfInputHash (@KeysOfInputHash) {
       if (not defined $Constrainthash->{$KeyOfInputHash}) {
          next;
       }
       # 1. Check Type
       # 1.1 If type is Attribute, then get the first good value
       if ($Constrainthash->{$KeyOfInputHash}{type} eq "attribute") {
         if ($KeyOfInputHash eq $keyTobeReplacedWithComboValue) {
            $inputHash->{$KeyOfInputHash} = $comboValue;
         }
       }
       # 1.2 If type is Array, then look at instance type,
       # Look for that instance type and call InjectValue()
       if ($Constrainthash->{$KeyOfInputHash}{type} eq "array") {
          if ($KeyOfInputHash eq $keyTobeReplacedWithComboValue) {
             $inputHash->{$KeyOfInputHash} = $comboValue;
          } else {
             my @inputArray = ();
             foreach my $instance (@{$inputHash->{$KeyOfInputHash}}) {
               push @inputArray, $self->InjectValue(
                                                 $comboValue,
                                                 $keyTobeReplacedWithComboValue,
                                                 $instance,
                                                 $copyConstrainthash);
             }
             $inputHash->{$KeyOfInputHash} = \@inputArray;
          }
       }
       # 1.3 if type is Object, then look at attributes
       # Call InjectValue()
       if ($Constrainthash->{$KeyOfInputHash}{type} eq "object") {
         if ($KeyOfInputHash eq $keyTobeReplacedWithComboValue) {
             $inputHash->{$KeyOfInputHash} = $comboValue;
         } else {
            foreach my $attributeKey (keys %{$inputHash->{$KeyOfInputHash}}) {
               $inputHash->{$KeyOfInputHash} = $self->InjectValue(
                                                 $comboValue,
                                                 $keyTobeReplacedWithComboValue,
                                                 $inputHash->{$KeyOfInputHash},
                                                 $copyConstrainthash);
            }
         }
       }
    }
    return $inputHash;
}


##############################################################################
#
# NormalizeMagic --
#       This method tries to go through the nested hash and finds out which key
#       hash the value set to "magic". If any key is found having "magic" value,
#       replace the the key with the first good value under Constraint
#       Database.
#
# Input:
#       inputHash - Nested hash which have values equal to "magic"
#       copyConstrainthash - Constraint keysdatabase
#
# Results:
#       SUCCESS - A hash reference
#       FAILURE - Not tested failure result
#
# Side effects:
#       None
#
##############################################################################

sub NormalizeMagic
{
   my $self = shift;
   my $inputHash  = shift;
   my $copyConstrainthash = shift;

   my $Constrainthash = dclone $copyConstrainthash;

   my @KeysOfInputHash = keys %$inputHash;
   foreach my $KeyOfInputHash (@KeysOfInputHash) {
       if (not defined $Constrainthash->{$KeyOfInputHash}) {
          next;
       }
       # 1. Check Type
       # 1.1 If type is Attribute, then get the first good value
       if ($Constrainthash->{$KeyOfInputHash}{type} eq "attribute") {
         if ($inputHash->{$KeyOfInputHash} eq "magic") {
            $inputHash->{$KeyOfInputHash} = $Constrainthash->{$KeyOfInputHash}{goodValue}[0]{value};
         }
       }
       # 1.2 If type is Array, then look at instance type,
       # Look for that instance type and call NormalizeMagic()
       if ($Constrainthash->{$KeyOfInputHash}{type} eq "array") {
          if ($inputHash->{$KeyOfInputHash} eq "magic") {
             $inputHash->{$KeyOfInputHash} = "$KeyOfInputHash.goodValue[0]";
          } else {
             my @inputArray = ();
             foreach my $instance (@{$inputHash->{$KeyOfInputHash}}) {
               push @inputArray, $self->NormalizeMagic($instance,
                                                       $copyConstrainthash);
             }
             $inputHash->{$KeyOfInputHash} = \@inputArray;
          }
       }
       # 1.3 if type is Object, then look at attributes
       # Call NormalizeMagic()
       if ($Constrainthash->{$KeyOfInputHash}{type} eq "object") {
         if ($inputHash->{$KeyOfInputHash} eq "magic") {
             $inputHash->{$KeyOfInputHash} = "$KeyOfInputHash.goodValue[0]";
         } else {
            $inputHash->{$KeyOfInputHash} = $self->NormalizeMagic(
                                               $inputHash->{$KeyOfInputHash},
                                               $copyConstrainthash);
         }
       }
    }
    return $inputHash;
}


##############################################################################
#
# ResolveInstanceTuple --
#       This method tries to return good or bad value from Constraint
#       Database based on the the input tuple <key>.goodValue[index]
#
# Input:
#       tuple - tuple in the form <key>.goodValue[index]
#       copyConstrainthash - Constraint keysdatabase
#
# Results:
#       SUCCESS - A hash reference
#       FAILURE - Not tested failure result
#
# Side effects:
#       None
#
##############################################################################

sub ResolveInstanceTuple
{
   my $self = shift;
   my $tuple = shift;
   my $Constrainthash = shift;
   my $valueType;
   if (not defined $tuple) {
      $vdLogger->Error("Tuple is not defined");
      VDSetLastError("EINVALID");
      return undef;
   }
   if ($tuple !~ /\./) {
      return $tuple;
   }

   if ($tuple =~ /goodValue\[/) {
      $valueType = "goodValue";
   } elsif ($tuple =~ /badValue\[/i) {
      $valueType = "badValue";
   } else {
      return $tuple;
   }
   my $copyConstrainthash = dclone $Constrainthash;
   my ($key, $index) = split ('\.', $tuple);

   $index =~ s/\D//g; # get the index for which we want to generate spec
   return $copyConstrainthash->{$key}{$valueType}[$index]{value};
}



1;
