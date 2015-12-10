########################################################################
# Copyright (C) 2011 VMware, Inc.
# All Rights Reserved.
########################################################################
package VDNetLib::InlineJava::VDNetInterface;

#
# This is interface between Inline::Java and VDNet.
# - This package maintains the list of java classes that needs to be
# imported as perl classes
# - Provides routine to load the Inline::Java module with given
# list of java classes and other Inline Java options like debug,
# address to bind etc
# - Also provides a routine to instantiate Perl object corresponding
# to a Java class
#
# Javadoc for VCQA library is at
# http://vimhudson.eng.vmware.com/view/dist/job/vc5x-dist/javadoc/?
# And Java VI SDK reference at
# http://pubs.vmware.com/vsphere-50/index.jsp?topic=/com.vmware.wssdk.apiref.doc_50/index.html&single=true
#

@VDNetLib::InlineJava::VDNetInterface::ISA = qw(Exporter) ;
# Export the functions CreateInlineObject LoadInlineJava on need
# basis
@EXPORT_OK = qw(CreateInlineObject LoadInlineJava InlineExceptionHandler
                ConfigureLogger NewDataHandler StopInlineJVM NewArrayList
                LoadInlineJavaClass);

use strict;
use warnings;
use Data::Dumper;
use File::Basename;
use Inline::Java qw(cast coerce study_classes);
use FindBin;
use lib "$FindBin::Bin/../../VDNetLib/CPAN/5.8.8/";

#
# Importing only vdLogger for now and nothing else to keep this package
# re-usable for frameworks/tools other than VDNet
#
use VDNetLib::Common::GlobalConfig qw ($vdLogger);
use constant TRUE  => VDNetLib::Common::GlobalConfig::TRUE;
use constant FALSE => VDNetLib::Common::GlobalConfig::FALSE;


########################################################################
#
# CreateInlineObject--
#     This routine will allow to create inline/Perl version of
#     Java objects.
#     Using the returned objects, any methods, public attributes of the
#     given java class can be accessed
#
# Input:
#     className : name of the Java class (Required)
#                 example: com.vmware.vcqa.ConnectAnchor
#
#     classParameters: This is an array (comma separated list) of
#                      parameters that are needed for the Java
#                      class passed above.
#                      Example: constructor of
#                      com.vmware.vcqa.ConnectAnchor classes
#                      need vc address and port number as parameters
#                      In that case, the input would look like:
#                      CreateInlineObject("com.vmware.vcqa.ConnectAnchor",
#                                         "10.x.x.x",
#                                         "443")
#
# Results:
#     Inline Java object for the given class will be returned;
#     exception as documented in the constructor of java class
#     will be thrown in case of any error;
#
# Side effects:
#     None
#
########################################################################


sub CreateInlineObject
{
   my $className = shift;

   #
   # When Inline::Java is loaded, all java classes
   # will be bound a perl package. In this case, it is
   # VDNetLib::InlineJava::VDNetInterface because Inline::Java
   # is loaded in this package.
   #
   # To access any inline java object, we need to prefix the
   # perl class name.
   #

   LoadInlineJavaClass($className);
   $className =~ s/\./::/g;
   my $temp = "VDNetLib::InlineJava::VDNetInterface::$className";
   return $temp->new(@_);
}


########################################################################
#
# LoadInlineJavaClass --
#     Method to load the given Java class
#
# Input:
#     className: Java class name
#
# Results:
#     None
#
# Side effects:
#     None
#
########################################################################

sub LoadInlineJavaClass
{
   my $className = shift;
   study_classes([$className], 'VDNetLib::InlineJava::VDNetInterface');
}

########################################################################
#
# LoadInlineJava--
#     This routine loads Inline Java module, start JVM with the list
#     of classes given under @INLINES array.
#     This routine should be called first before accessing inline java
#     object.
#
# Input:
#     A hash/named  value list of parameters with following keys:
#     DEBUG - valid values 0 - 5 (0 means no debug log,
#                                 5 gives verbose log)
#     HOST  - JVM will create socket and bind to this host address
#             (it is usually the local ip address)
#     J2SDK - J2SDK path, example:/usr/java/jdk1.6.0_23
#     DIRECTORY - directory name to store Inline Java logs
#     CLASSDIR - absolute path where all JAR packages of classes in
#                @INLINE are located
#
# Results:
#     Inline Java module will be loaded and
#     1 will be returned if successful;
#     0 will be returned in case of any error
#
# Side effects:
#     None
#
########################################################################

sub LoadInlineJava
{
   my %opts = @_ ;

   my $debug = (defined $opts{DEBUG}) ? $opts{DEBUG} : 0;
   my $j2sdk = (defined $opts{J2SDK}) ? $opts{J2SDK} : undef;
   my $port = (defined $opts{PORT}) ? $opts{PORT} : undef;
   my $localHost = (defined $opts{HOST}) ? $opts{HOST} : 'localhost';
   my $directory = (defined $opts{DIRECTORY}) ? $opts{DIRECTORY} : '/tmp';

   my $javaClassDir = $opts{CLASSDIR};
   if (defined $javaClassDir) {
      $javaClassDir =~ s/\/$//g;
      my $classPath = "$javaClassDir/lib.jar:$javaClassDir/vcqa.jar:" .
                      "$javaClassDir/vc.jar:" .
                      "$javaClassDir/logback-classic-0.9.18.jar:" .
                      "$FindBin::Bin/../VDNetLib/HPQC/qc-connector.jar:" .
                      "$FindBin::Bin/../VDNetLib/HPQC/:" .
                      "$javaClassDir/slf4j-api-1.5.10.jar";

      $ENV{CLASSPATH} = $classPath; # overwrite any system defined value
                                    # CLASSPATH
   }
   $vdLogger->Debug("Classpath:" . $ENV{CLASSPATH});

   #
   # PERL_INLINE_JAVA_J2SDK environment needs to be set which
   # points to the directory where java is installed
   #
   SetJ2SDKPath();

   $vdLogger->Debug("J2SDK Path:" . $ENV{PERL_INLINE_JAVA_J2SDK});
   #
   # Refer to https://wiki.eng.vmware.com/APIFVT/vimfvt/jax-ws/migration
   # for all JVM options to be used for VCQA library
   #
   my $jvmOptions = "-Xmx2048m -XX:MaxPermSize=256m -XX:PermSize=128m " .
                    "-XX:+UseConcMarkSweepGC -DUSESSL=true";
   eval {
      require Inline::Java;
      #
      # SHARED_JVM mode is recommended to be used with unique port number for each
      # session. Since same machine can be used to load
      # vcqa jars that have different vmodl checksum and also, re-using same
      # Inline JVM would have problems when there are differences
      # in the set of classes being loaded
      #
      import Inline (Java        => 'STUDY',
                     AUTOSTUDY   => 1,
                     DEBUG       => $debug,
                     HOST        => $localHost,
                     BIND        => $localHost,
                     J2SDK       => $j2sdk,
                     PORT        => $port,
                     SHARED_JVM  => 1,
                     DIRECTORY   => $directory,
                     EXTRA_JAVA_ARGS => $jvmOptions,
                     STARTUP_DELAY => 30,
                    );
   };

   if ($@) {
      $vdLogger->Error("Failed to load Inline Java:$@");
      return FALSE;
   }

   return TRUE;
}


########################################################################
#
# SetJ2SDKPath--
#     Routine to get the directory where J2SDK is installed and
#     set PERL_INLINE_JAVA_J2SDK environment variable with that
#     directory name.
#
# Input:
#     None
#
# Results:
#     0 if J2SDK path is determined;
#     1 in case of error;
#
# Side effects:
#     None
#
########################################################################

sub SetJ2SDKPath {
   #
   # if PERL_INLINE_JAVA_J2SDK env variable is already set, then
   # nothing to do, return TRUE
   #
   if (defined $ENV{PERL_INLINE_JAVA_J2SDK}) {
      return TRUE;
   } elsif (defined $ENV{JAVA_HOME}) {
      #
      # J2SDK path is same as JAVA_HOME. So, refer to
      # JAVA_HOME if that en variable is defined
      #
      $ENV{PERL_INLINE_JAVA_J2SDK} = $ENV{JAVA_HOME};
   } else {
      #
      # last option - search for java installation and
      # predict the J2SDK path based on that.
      #
      my $javaBin = `which java`;
      if (not defined $javaBin) {
         $vdLogger->Error("Java not installed on the local machine");
         return FALSE;
      }
      $javaBin = `readlink -f $javaBin`;

      my $javaDir = dirname($javaBin);
      $javaDir =~ s/bin$//;
      $ENV{PERL_INLINE_JAVA_J2SDK} = $javaDir;
      return TRUE;
   }
}


########################################################################
#
# InlineExceptionHandler--
#     Routine to handle java exception thrown. Exceptions are caught
#     in Perl using eval { } block. The exception details are stored
#     in $@
#
# Input:
#     $exception -  exception object stored in $@ after the
#                   eval block in perl
#
# Results:
#     None
#
# Side effects:
#     None
#
########################################################################

sub InlineExceptionHandler
{
   my $exception   = shift;
   my $expectedFault = shift || $exception;

   if ($exception) {
      if (Inline::Java::caught("java.lang.Exception")) {
         my $testUtilObj = CreateInlineObject("com.vmware.vcqa.util.TestUtil");
         $vdLogger->Error("Java exception: " .
                          $testUtilObj->getStackTrace($exception));
         $testUtilObj->handleException($exception);
         $vdLogger->Info("See " . $vdLogger->{logDir} . "vdNetInlineJava.log " .
                         "for more details");
      } else {
         $vdLogger->Error("Not a Java Exception Thrown");
         $vdLogger->Debug("Exception:" . Dumper($exception));
      }
   }
}


########################################################################
#
# ConfigureLogger--
#     Routine to configure logger that gets enabled by default with
#     VCQA package. This routine disables console logging and
#     redirects to a log file.
#
# Input:
#     logDir: log directory where logs should be created (Required)
#     logbackTemplate: xml template that has logger configuration details
#                      (Optional)
#
# Results:
#     1 - if logger is configured successfully;
#     0 - in case of error
#
# Side effects:
#     Default logger options will be overridden
#
########################################################################

sub ConfigureLogger
{
   my $logDir           = shift;
   my $logbackTemplate  = shift;

   if (not defined $logDir) {
      $vdLogger->Error("Log directory for VCQA logs not provided");
      return FALSE;
   }
   my $logbackConfigFile = (defined $logbackTemplate) ? $logbackTemplate :
                           "$FindBin::Bin/../VDNetLib/InlineJava/logback-test.xml";

   eval {
      LoadInlineJavaClass('org.slf4j.LoggerFactory');
      my $loggerContext =
         VDNetLib::InlineJava::VDNetInterface::org::slf4j::LoggerFactory->getILoggerFactory();
      my $jc = CreateInlineObject("ch.qos.logback.classic.joran.JoranConfigurator");
      $jc->setContext($loggerContext);
      $loggerContext->reset();
      $loggerContext->putProperty("INLINEJAVA_LOGDIR", $logDir);
      $jc->doConfigure($logbackConfigFile);
   };

   if ($@) {
      $vdLogger->Error("Failed to configure logger for " .
                       "VDNetlib::InlineJava::VDNetInterface:$@");
      return FALSE;
   }

   return TRUE;
}


########################################################################
#
# NewDataHandler--
#     Creates an instance of DataHandler object
#
# Input:
#     mimeType - mime type of the object
#
# Results:
#     returs FALSE if there is an error else ref to DataHandler
#
# Side effects:
#     None
#
########################################################################

sub NewDataHandler
{
   my $input = shift;
   my $mimeType = shift || 'text/plain';
   my $dh;

   my $obj = coerce("java.lang.Object", $input, "java.lang.String");
   eval {
      $vdLogger->Debug("calling new data handler with mime type " .
                       "$mimeType and the input is $input");
      $dh = CreateInlineObject('javax.activation.DataHandler', $obj, $mimeType);
      return $dh;
   };
   if ($@) {
      $vdLogger->Error("New DataHandler returned exception");
      InlineExceptionHandler($@);
      return FALSE;
   }
}


########################################################################
#
# StopInlineJVM --
#     Routine to stop Inline JVM/server
#
# Input:
#     None
#
# Results:
#     None
#
# Side effects:
#     Any process depending on this Inline JVM instance will not be
#     able to access the JVM.
#
########################################################################

sub StopInlineJVM
{
   Inline::Java::capture_JVM(); # return code is always undef
   Inline::Java::shutdown_JVM();
}


########################################################################
#
# ReconnectJVM --
#     Routine to reconnect to Inline JVM/server
#     Its a known issue that we have to reconnect JVM
#     in the child process or else it won't load the java classes
#     in the forked child process.
#     http://search.cpan.org/dist/Inline-Java/Java.pod
#
# Input:
#     None
#
# Results:
#     None
#
# Side effects:
#
########################################################################

sub ReconnectJVM
{
   Inline::Java::reconnect_JVM();
}
1;
