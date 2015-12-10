########################################################################
# Copyright (C) 2014 VMWare, Inc.
# All Rights Reserved
########################################################################
package VDNetLib::Root::Root;

use strict;
use warnings;

use Data::Dumper;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                    VDCleanErrorStack);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::Common::Utilities;
use VDNetLib::InlinePython::IOUtility;
# LoadInlinePythonModule
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              ConfigureLogger
                                              CallMethodWithKWArgs);
use vars qw{$AUTOLOAD};
#use Inline::Python qw( py_call_method);
use Scalar::Util qw(blessed);
use JSON;
use constant TRUE  => VDNetLib::Common::GlobalConfig::TRUE;
use constant FALSE => VDNetLib::Common::GlobalConfig::FALSE;


#####################################################################
#
# AUTOLOAD --
#     Implements Perl's standard AUTOLOAD method for this class
#     Autoload feature is being used to do passthrough from perl
#     to python layer. With this function, developer dont need to
#     write perl wrappers in Perl layer to call python methods
#
# Input:
#     Perl's default
#
# Results:
#     Refer to the return value of the actual method in Python layer
#
# Side effects:
#     None
#
########################################################################

sub AUTOLOAD
{
   my $self = shift;
   my $args = @_;
   my $result;
   return if $AUTOLOAD =~ /::DESTROY$/;
   my $method = $1 if ($AUTOLOAD =~ /.*::(\w+)/);
   $vdLogger->Debug("Value of AUTOLOAD is $AUTOLOAD");
   $vdLogger->Debug("Autoloading the method $method");
   my $resultObj;
   my $parentPyObj = undef;
   if (exists $self->{parentObj}) {
       my $parentPerlObj = $self->{parentObj};
       $parentPyObj = $parentPerlObj->GetInlinePyObject();
       if ((not defined $parentPyObj) || ($parentPyObj eq FALSE) ||
           ($parentPyObj eq FAILURE)) {
          my $packageName = blessed $parentPerlObj;
          $vdLogger->Error("Failed to get inline python object for " .
                           "parentObj: $packageName");
          VDSetLastError("ENOTDEF");
          return FAILURE;
       }
   }
   my $resultHash;
   my $inlinePyObj =  $self->GetInlinePyObject($parentPyObj);
   if ((not defined $inlinePyObj) || ($inlinePyObj eq FALSE) ||
       ($inlinePyObj eq FAILURE)) {
      my $packageName = blessed $self;
      $vdLogger->Error("Failed to get inline python object for " .
                       "$packageName");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $vdLogger->Debug("Value of parameters is " . Dumper(@_));
   $vdLogger->Debug("Value of parameters is @_");
   $result = $self->SetRuntimeParams($inlinePyObj, $args);
   if ((defined $result) && ($result eq FAILURE)) {
       return FAILURE;
   }
   $resultObj = CallMethodWithKWArgs($inlinePyObj, $method, @_);
   if ((defined $resultObj) && ($resultObj eq FAILURE)) {
      $vdLogger->Error("Exception thrown while calling $method: " .
                       Dumper(VDGetLastError()));
      VDSetLastError("EINLINE");
      return FAILURE;
   }
   if (not ref($resultObj)) {
      # python method return a SCALAR object
      $resultHash = $resultObj;
   } elsif (ref($resultObj) =~ /Boolean/) {
      if($resultObj) {
         $vdLogger->Debug("Return true from python layer.");
         return SUCCESS;
      } else {
         $vdLogger->Debug("Return false from python layer.");
         return FAILURE;
      }
   } elsif (ref($resultObj) =~ m/HASH/ || ref($resultObj) =~ m/ARRAY/ ) {
      # python method no need always return Class object, can also be pydict
      $resultHash = $resultObj;
   } elsif ($resultObj->{__class__} =~ m/.*Schema/) {
      $resultHash = $resultObj->get_py_dict_from_object();
   } elsif ($resultObj->{__class__} =~ m/.*dict/) {
      $resultHash = $resultObj;
   } else {
      $resultHash = $resultObj->{__dict__};
   }

   if (ref($resultHash)) {
      if ((exists $resultHash->{status_code}) &&
          (!$resultHash->{status_code})) {
         $vdLogger->Debug("Return status code is 0, returning response");
         return $resultHash->{response_data};
      }
   }
   $vdLogger->Debug("Returning the hash" . Dumper($resultHash));
   return $resultHash;
}


######################################################################
#
# GetInlinePyObject --
#     Methd to get Python equivalent object of this class
#
# Input:
#     None
#
# Results:
#     Reference to Inline Python object of this class
#
# Side effects:
#     None
#
#######################################################################

sub GetInlinePyObject
{
   my $self = shift;
   my $parentPyObj = shift;
   my $inlinePyObj;

   if (not defined $parentPyObj){
       $parentPyObj = $self->{parentObj}->GetInlinePyObject();
   }
   eval {
       # __init__ in pylib is not standardized. As of now, some constructors take
       # just 1 argument (eg parent), and some take more than one (eg parent, name)
       # Currently, the call to CreateInlinePythonObject is not generic enough to
       # accommodate both these cases. For pylib methods that take just the parent
       # object as an arugment to the constructor, the IF block will execute.
       # For pylib constructors that need both parent and an ID, the ELSE block
       # will execute. This maintains backward compatibility with existing APIs
       #
       # If key-word args are passed as arguments to CreateInlinePythonObject
       # methods, existing APIs that need just a parent object to be passed
       # to the pylib constructor might break
       #
       # (This can be changed if a better solution exists)
       # TODO: (Bug: 1333203)
       if( not defined $self->{$self->{_pyIdName}}){
           $inlinePyObj = CreateInlinePythonObject($self->{_pyclass}, $parentPyObj);
           $vdLogger->Debug("{_pyIdName} not defined, creating inline object without it");
       }
       else{
           $inlinePyObj = CreateInlinePythonObject($self->{_pyclass},
                                                   $parentPyObj,
                                                   $self->{$self->{_pyIdName}});
           $vdLogger->Debug("{_pyIdName} defined, creating inline object with it");
       }
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while creating " .
                       "inline component of $self->{_pyclass}:\n". $@);
      $vdLogger->Error("Check if the pylib constructor signature  is ".
                       "of the form: (parent, id)");
      return FAILURE;
   }
   if (exists $self->{id}) {
      $inlinePyObj->{$self->{_pyIdName}} = $self->{id};
   }
   return $inlinePyObj;
}

########################################################################
#
# new --
#     Contructor to create an instance of this class
#     VDNetLib::Root::Root
#
# Input:
#     ip : ip address of the nvp controller
#
# Results:
#     Blessed hash reference to an instance of
#     VDNetLib::NVP::NVPOperations;
#
# Side effects:
#     None
#
########################################################################

sub new
{
   my $class = shift;
   my $self  = {};
   $self->{_pyIdName} = 'id_';
   bless $self, $class;
   return $self;
}


########################################################################
#
# CreateIOSession
#     Method to create IO Session for python based io tools.
#     It creates and returns python objects
#
# Input:
#     arrayOfSpecs - Specs for each session of the tool
#                    Spec contains toolname, testduration etc
#
# Results:
#     array of IO python objects, in case of SUCCESS
#     E.g. dt tool python object in case user gives tool as dt
#     FAILURE, in case of failure
#
# Side effects:
#     None
#
########################################################################

sub CreateIOSession
{
   my $self = shift;
   my $arrayOfSpecs = shift;
   my (@arrayOfIOSessions);

   foreach my $element (@$arrayOfSpecs) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("IO spec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my %options = %$element;
      # Implmented in AbstractInlinePythonClass
      my $sessionPyObj = VDNetLib::InlinePython::IOUtility::CreatePyIOSession(%options);
      if ($sessionPyObj eq FAILURE) {
         $vdLogger->Error("Not able to CreateIOSession()");
         VDSetLastError("EFAILED");
         return FAILURE;
      }
      push(@arrayOfIOSessions, $sessionPyObj);
   }
   return \@arrayOfIOSessions;
}


########################################################################
#
# CreateInventory--
#     Method that assists in creating inventory items like VM, host,
#     IO tools object etc
#
# Input:
#     result - result of creating the inventory item
#
# Results:
#
# Side effects:
#     None
#
########################################################################

sub CreateInventory
{
   my $self = shift;
   my $result = shift;
   # Creating Inventory from workload required testbed
   # Core API does not have access to testbed
   # so we call Init on testbed in Preprocess itself and just
   # pass the return to this core API.
   # Thus returning the result as it is.
   return $result;
}


########################################################################
#
# DeleteInventory--
#     Method that assists in deleting inventory items like VM, host,
#     IO tools object etc
#
# Input:
#     result - result of deleting the inventory item
#
# Results:
#
# Side effects:
#     None
#
########################################################################

sub DeleteInventory
{
   my $self = shift;
   my $result = shift;
   return $result;
}


#######################################################################
#
# CreateComponent --
#     Method to create components/managed objects/entities and verify
#     components .
#
# Input:
#     componentName: name of the component to be created
#     arrayofSpec : reference to array of hash
#
# Results:
#     Reference to array  of component objects, if successful;
#     TBD, in case of failure
#
# Side effects:
#     None
#
########################################################################

sub CreateComponent
{
   my $self               = shift;
   my $componentName      = shift;
   my $arrayOfSpec        = shift;
   my $className          = shift;
   my $args               = shift;
   my @arrayOfPyObj;
   my $result;

   if ((not defined $className) || (not defined $componentName)) {
      $vdLogger->Error("Either class name or component not given");
      $vdLogger->Debug("Class name:$className, component: $componentName");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   # Step1: Create inline object of Parent
   # Inline python class
   my $parentPyObj;
   my $packageName = blessed $self;

   $parentPyObj = $self->GetInlinePyObject();
   if ($parentPyObj eq "FAILURE") {
      $vdLogger->Error("Failed to get inline python object for $packageName");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $vdLogger->Debug("We got inline parentPyObj, now creating instance of component:" .
                     "$componentName");
   # Step2: Load the Component Perl Class
   eval "require $className";
   if ($@) {
      $vdLogger->Error("Failed to load $className $@");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   foreach my $element (@$arrayOfSpec) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("$componentName spec not in hash form");
         VDSetLastError("EFAIL");
         return FAILURE;
      }

      # Step3: Create instance the Component Perl Class
      my $componentPerlObj = $className->new('parentObj' => $self);

      my $componentPyObj = $componentPerlObj->GetInlinePyObject($parentPyObj);
      if ($componentPyObj eq "FAILURE") {
         $vdLogger->Error("Failed to get inline python object for $componentName");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $result = $self->SetRuntimeParams($componentPyObj, $args);
      if ((defined $result) && ($result eq FAILURE)) {
          return FAILURE;
      }
      #Check for 'map_object' key in the $element
      if (defined $element->{map_object}) {
         if ($element->{map_object} == TRUE){
            #If map_object key is TRUE then use id_ for mapping component
            if (!defined $element->{$componentPerlObj->{_pyIdName}}) {
               $vdLogger->Error("Attribute $componentPerlObj->{_pyIdName} " .
                                "not defined for $componentName");
               VDSetLastError("ENOTDEF");
               return FAILURE;
            }
            $componentPerlObj->{id} = $element->{$componentPerlObj->{_pyIdName}};
         } else {
            $vdLogger->Error("map_object=false not supported for $componentName");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
         #Delete map key from $element
         delete $element->{map_object};
      } else {
         #Check for 'discover' key in the $element
         my $method = 'create';
         if (defined $element->{discover}) {
            if ($element->{discover} =~ /true/i){
                #If discover key is TRUE then use get_id method
                $method = 'get_id_from_schema';
            }
            #Delete discover key from $element
            delete $element->{discover};
         }

         # Step4: Run create() python method under python class
         $args->{schema} = $element;
         $result = CallMethodWithKWArgs($componentPyObj, $method, $args);
         if ((defined $result) && ($result eq FAILURE)) {
            $vdLogger->Error("Create/discover $componentName returned FAILURE: " .
                          Dumper(VDGetLastError()));
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         if (not defined $result->{$componentPerlObj->{_pyIdName}}) {
            $vdLogger->Error("$componentPerlObj->{_pyIdName} is not " .
                          "defined for $className " . Dumper($result));
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
         $componentPerlObj->{id} = $result->{$componentPerlObj->{_pyIdName}};
         $componentPerlObj->{$componentPerlObj->{_pyIdName}} = $result->{$componentPerlObj->{_pyIdName}};
      }
      # Step5: Store each perl object in the array
      push @arrayOfPyObj, $componentPerlObj;
   }
   # Step6: Send the array of objects back
   return \@arrayOfPyObj;
}


#######################################################################
#
# DeleteComponent --
#     Method to delete components/managed objects/entities. This
#     method invokes Py layer's delete method from each class.
#
# Input:
#     arrayOfPerlObjects: reference to array of perl objects on which
#     delete is called
#
# Results:
#     SUCCESS, if the operation succeeds
#     FAILURE, in case of failure
#
# Side effects:
#     None
#
########################################################################

sub DeleteComponent
{
   my $self             = shift;
   my $arrayOfPerlObjects = shift;
   my $args               = shift;

   if (!@$arrayOfPerlObjects) {
      $vdLogger->Error("No component objects given to delete");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $parentPyObj;
   my $packageName = blessed $self;
   $parentPyObj = $self->GetInlinePyObject();
   if ($parentPyObj eq "FAILURE") {
      $vdLogger->Error("Failed to get inline python object for $packageName");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   foreach my $perlObj (@$arrayOfPerlObjects) {
      my ($input, $pyObj, $result);
      $input->{parent_obj} = $parentPyObj;
      my $packageName = blessed $perlObj;
      $pyObj = $perlObj->GetInlinePyObject($parentPyObj);
      if ($pyObj eq "FAILURE") {
         $vdLogger->Error("Failed to get inline python object for $packageName");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      $vdLogger->Debug("We got pyObj, now executing delete method");
      if (not defined $perlObj->{id}) {
         $vdLogger->Error("PerlObj->id is not defined for ". Dumper($perlObj));
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      $args->{"$perlObj->{_pyIdName}"} = $perlObj->{id};
      $result = $self->SetRuntimeParams($pyObj, $args);
      if ((defined $result) && ($result eq FAILURE)) {
          return FAILURE;
      }
      $result = CallMethodWithKWArgs($pyObj, 'delete', $args);
      if ((defined $result) && ($result eq FAILURE)) {
         $vdLogger->Error("Delete component returned FAILURE: " .
                          Dumper(VDGetLastError()));
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $vdLogger->Debug("Return status code is $result->{response_data}{status_code}");
      $vdLogger->Info("Deleted component successfully");
   }
   return SUCCESS;
}


#######################################################################
#
# UpdateComponent --
#     Method to update components/managed objects/entities. This
#     method invokes Py layer's update method from each class.
#
# Input:
#     arrayOfPerlObjects: reference to array of perl objects on which
#     update is called
#
# Results:
#     SUCCESS, if the operation succeeds
#     FAILURE, in case of failure
#
# Side effects:
#     None
#
########################################################################

sub UpdateComponent
{
   my $self          = shift;
   my $userSchema    = shift;
   my $userArgs      = shift;

   my ($payload, $args);
   if ((defined $userSchema->{reconfigure}) &&
       (ref($userSchema->{reconfigure}) =~ /HASH/i)) {
       $payload       = $userSchema->{reconfigure};
       delete $userSchema->{reconfigure};
       $args = $userSchema;
   } else {
       if (defined $userSchema->{reconfigure}) {
          delete $userSchema->{reconfigure};
       }
       $payload = $userSchema;
       $args = $userArgs;
   }

   my ($pyObj, $result);

   # Step1: Create inline object of Parent
   # Inline python class
   my $parentPerlObj = $self->{parentObj};
   my $packageName = blessed $parentPerlObj;
   my $parentPyObj = $parentPerlObj->GetInlinePyObject();
   if ($parentPyObj eq "FAILURE") {
      $vdLogger->Error("Failed to get inline python object for $packageName");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Step2: Create inline object of self
   # Inline python class
   $packageName = blessed $self;
   $pyObj = $self->GetInlinePyObject($parentPyObj);
   if ($pyObj eq "FAILURE") {
      $vdLogger->Error("Failed to get inline python object for $packageName");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $vdLogger->Debug("We got pyObj, now executing update method");

   $args->{"$self->{_pyIdName}"} = $self->{id};
   $args->{"schema"} = $payload;
   $result = $self->SetRuntimeParams($pyObj, $args);
   if ((defined $result) && ($result eq FAILURE)) {
       return FAILURE;
   }
   $result = CallMethodWithKWArgs($pyObj, 'update', $args);
   if ((defined $result) && ($result eq FAILURE)) {
      $vdLogger->Error("Update component returned FAILURE: " .
                        Dumper(VDGetLastError()));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("Return status code is $result->{response_data}{status_code}");
   $vdLogger->Info("Updated component successfully");
   return $self;
}


#######################################################################
#
# ReadComponent --
#     Method to read components/managed objects/entities. This
#     method invokes Py layer's update method from each class.
#
# Input:
#     arrayOfPerlObjects: reference to array of perl objects on which
#     read operation is called
#
# Results:
#     SUCCESS, if the operation succeeds
#     FAILURE, in case of failure
#
# Side effects:
#     None
#
########################################################################

sub ReadComponent
{
   my $self               = shift;
   my $serverForm        = shift;
   my $args               = shift;
   my ($pyObj, $result);

   # Preparing the result hash which will be returned
   my $resultHash = {
      'status'      => undef,
      'response'    => undef,
      'error'       => undef,
      'reason'      => undef,
   };

   # Step1: Create inline object of Parent
   # Inline python class
   my $parentPerlObj = $self->{parentObj};
   my $packageName = blessed $parentPerlObj;
   my $parentPyObj = $parentPerlObj->GetInlinePyObject();
   if ($parentPyObj eq "FAILURE") {
      $vdLogger->Error("Failed to get inline python object for $packageName");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Step2: Create inline object of self
   # Inline python class
   $packageName = blessed $self;
   $pyObj = $self->GetInlinePyObject($parentPyObj);
   if ($pyObj eq "FAILURE") {
      $vdLogger->Error("Failed to get inline python object for $packageName");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $vdLogger->Debug("We got pyObj, now executing read method");
   my $responseData;
   $args->{"$self->{_pyIdName}"} = $self->{id};
   $result = $self->SetRuntimeParams($pyObj, $args);
   if ((defined $result) && ($result eq FAILURE)) {
       return FAILURE;
   }
   $result = CallMethodWithKWArgs($pyObj, 'read', $args);
   if ((defined $result) && ($result eq FAILURE)) {
      $vdLogger->Error("Read component returned FAILURE: " .
                       Dumper(VDGetLastError()));
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   $vdLogger->Debug("Return status code is $result->{response_data}{status_code}");
   $vdLogger->Info("Read component $self->{_pyclass} successfully");
   $resultHash->{status} = "SUCCESS";
   $resultHash->{response} = $result;
   return $resultHash;
}


#######################################################################
#
# CreateMultipleComponents --
#     Method to create multiple components
#
#     In Avalanche NSXManager there are couple of modules like -
#     Certificate and CRL whose single POST API returns multiple
#     objects.
#
#     So, CreateComponent method from Root.pm will not work for these
#     kind of POST APIs.
#
#     Hence, added new CreateMultipleComponents method which will execute
#     singe POST API and handle the multiple objects returned by it.
#
# Input:
#     componentName: name of the component to be created
#     arrayofSpec : reference to array of hash
#
# Results:
#     Reference to array  of component objects, if successful
#
########################################################################

sub CreateMultipleComponents
{
   my $self               = shift;
   my $componentName      = shift;
   my $arrayOfSpec        = shift;
   my $className          = shift;
   my $args               = shift;
   my @arrayOfPyObj;
   my $setParamResult;

   if ((not defined $className) || (not defined $componentName)) {
      $vdLogger->Error("Either class name or component not given");
      $vdLogger->Debug("Class name:$className, component: $componentName");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   # Step1: Create inline object of Parent
   # Inline python class
   my $parentPyObj;
   my $packageName = blessed $self;
   $parentPyObj = $self->GetInlinePyObject();
   if ($parentPyObj eq "FAILURE") {
      $vdLogger->Error("Failed to get inline python object for $packageName");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $vdLogger->Debug("We got inline parentPyObj, now creating instance of component:" .
                     "$componentName");
   # Step2: Load the Component Perl Class
   eval "require $className";
   if ($@) {
      $vdLogger->Error("Failed to load $className $@");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   my $elementCount = 0;
   my $resultObjectName;
   my $result;
   foreach my $element (@$arrayOfSpec) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("$componentName spec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      # Step3: Create instance the Component Perl Class
      my $componentPerlObj = $className->new('parentObj' => $self);

      my $componentPyObj = $componentPerlObj->GetInlinePyObject($parentPyObj);
      if ($componentPyObj eq "FAILURE") {
         $vdLogger->Error("Failed to get inline python object for $componentName");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      $setParamResult = $self->SetRuntimeParams($componentPyObj, $args);
      if ((defined $setParamResult) && ($setParamResult eq FAILURE)) {
          return FAILURE;
      }

      #Call create method only for once
      if($elementCount == 0){
         if (not defined $element->{result_object}) {
            $vdLogger->Error("Attribute result_object not defined for $componentName");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
         $resultObjectName = $element->{result_object};
         #Delete result_object key from $element
         delete $element->{result_object};

         # Step4: Run create() python method under python class
         $args->{schema} = $element;
         $result = CallMethodWithKWArgs($componentPyObj, 'create', $args);
         if ((defined $result) && ($result eq FAILURE)) {
            $vdLogger->Error("Exception thrown while executing create() under " .
                             "$componentPerlObj->{_pyclass}:\n". $@);
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }

      if (not defined
      $result->{$resultObjectName}[$elementCount]->{$componentPerlObj->{_pyIdName}}) {
         $vdLogger->Error("_pyIdName is not defined for $componentName");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      # Step5: Store each perl object in the array
      $componentPerlObj->{id} =
      $result->{$resultObjectName}[$elementCount]->{$componentPerlObj->{_pyIdName}};
      push @arrayOfPyObj, $componentPerlObj;
      $elementCount++;
   }
   # Step6: Send the array of objects back
   return \@arrayOfPyObj;
}


#######################################################################
#
# SetRuntimeParams --
#     Method to set runtime parameters
#
#     this method will set runtime parameters on connection object
#
# Input:
#     object: reference to the Inline Python object
#     args: reference to hash containing named parameters as key value
#           pairs
#
# Results:
#     SUCCESS, if the operation succeeds
#     FAILURE, in case of failure
#
########################################################################

sub SetRuntimeParams
{
   my $self               = shift;
   my $inlinePyObj        = shift;
   my $args               = shift;
   my $result;

   if ((defined $args) && (ref($args) eq "HASH")
                       && (exists $args->{runtime_params})) {
       $result = CallMethodWithKWArgs($inlinePyObj, 'set_runtime_params',
                                      $args->{runtime_params});
       if ((defined $result) && ($result eq FAILURE)) {
           $vdLogger->Error("Failed to set runtime parameters" .
                            Dumper(VDGetLastError()));
           VDSetLastError(VDGetLastError());
           return FAILURE;
       }
       delete $args->{runtime_params};
   }
   return SUCCESS;
}


#######################################################################
#
# StoreTestData --
#     Dummy Method to for the test_data action key
#
# Input:
#     None
#
# Results:
#     SUCCESS
#
########################################################################

sub StoreTestData
{
   $vdLogger->Debug("Entered the dummy method StoreTestData" .
                    "Test Data will be stored while running the postprocess");
   return SUCCESS;
}


#######################################################################
#
# GetObjectParentAttributeName--
#     Returns the Attribute this class is using to store its parent
#
# Input:
#     None
#
# Results:
#     SUCCESS
#
########################################################################

sub GetObjectParentAttributeName
{
   return "parentObj";
}

1;
