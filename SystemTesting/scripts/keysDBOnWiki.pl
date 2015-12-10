#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use FindBin;

use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/";
use lib "$FindBin::Bin/../VDNetLib/Workloads/";
use lib "$FindBin::Bin/../VDNetLib/CPAN/5.8.8/";
use YAML qw(Dump Bless);
#use Storable qw(nstore store_fd nstore_fd freeze thaw dclone);
use VDNetLib::Common::Utilities;
use VDNetLib::Common::GlobalConfig;
use YAML qw(Dump Bless);
use Text::Table;
use File::Slurp;
use Storable 'dclone';
use MediaWiki::API;


VDNetLib::Common::GlobalConfig::CreateVDLogObj('logLevel'    => 7,
                                               # use 9 for full scale logging
                                               # use 7 for INFO level logging
                                               # use 4 for no out puts logging
                                               'logToFile'   => 1,
                                               'logFileName' => "/tmp/vdnet/DBonWiki.log");
if (not defined $vdLogger) {
   print STDERR "Failed to create VDNetLib::Common::VDLog object";
   exit -1;
}


# Please fill this form before processding
our $PageName  = 'YourName/Testing';
our $user      = 'ldap-username';
our $passwd    = "ldap-password";
our $hyperlink = "https\:\/\/wiki\.eng\.vmware\.com\/YourName\/Testing";
our $location  = "<>/automation/VDNetLib/Workloads/";
our $CheckWorkload = "YourTestWorkload";

#
# Main Execution
#
our $yamlLocation = $location . "yaml/";
our $keysdatabaseParent = GetKeysDBFromWorkload("ParentWorkload");
my ( $workload, $keysdatabase, $workloadObj, $yamlKeysDatabase);
## Get all packages
#my $arrayOfWorkload = GetAllWorkloadPackages();
#my $dummyHash = {};
#foreach my $workload (@$arrayOfWorkload) {
#   $vdLogger->Info("Loading $workload");
#   my $currentPackage = "VDNetLib::Workloads::" . $workload;
#   eval "require $currentPackage";
#   $keysdatabase = eval "$currentPackage" . "::" . 'KEYSDATABASE';
#   foreach my $key (keys %$keysdatabase) {
#      if ((exists $keysdatabase->{$key}{linkedworkload}) &&
#          (defined $keysdatabase->{$key}{linkedworkload})) {
#           $keysdatabase->{$key}{type} = "component";
#      }
#   }
#   $yamlKeysDatabase = GenerateYamlDescriptor($keysdatabase);
#   my $file = $yamlLocation . $workload . '.yaml';
#   StoreYamlDescriptor($yamlKeysDatabase, $file);
#   next;
#}

my $arrayOfWorkloadPackages = GetAllYamlPackages($yamlLocation);
# Unit Testing
$arrayOfWorkloadPackages = [
          #"HostWorkload",
          #"VMWorkload",
          #"VCWorkload"
          "RootWorkload",
        ];

# First Delete all the old contents from wiki
RemoveContentFromWiki();

# Publish all keys on wiki
my ($masterSchema, $masterPayload) =
    RecurseThroughKeysDB($arrayOfWorkloadPackages);

# Publish Master Schema and Master Payload on wiki
UpdateMasterScehmaAndPayload($masterSchema, $masterPayload);


sub RecurseThroughKeysDB
{
   my $arrayOfWorkloadPackages = shift;
   my $subcomponent            = shift;
   my $parent                  = shift;
   my $allowOnce               = shift || "0";
   my $masterSchema            = shift;
   my $link                    = shift;
   my $masterPayload           = shift;

   my ($masterContent, $masterActionArray, $masterSubCompArray, $workload);
   my $keysdatabase;


   foreach my $workload (@$arrayOfWorkloadPackages) {
      my $keysdatabaseOrig = GetKeysDBFromWorkload($workload);
      $keysdatabase = dclone $keysdatabaseOrig;
      substr ($workload, -8) = "";
      my ($keyUsedForSchema, $masterContentEachKey, $link, $parent) =
         AddHeaderForActionToWiki($workload,
                                  $parent,
                                  $hyperlink,
                                  $link,
                                  $subcomponent);
      $masterContent = $masterContent . $masterContentEachKey;
      my @masterparamArray = ();
      my $indexAction = 0;
      my $refhash = {};
      foreach my $key (keys %$keysdatabase) {
         if ($key =~ "checkifrealized") {
            next;
         }
         if (($keysdatabase->{$key}{type} eq 'action') ||
             ($keysdatabase->{$key}{type} eq 'component') ) {
            #if ($workload ne "NSXWorkload") {
               $vdLogger->Info("Workload: $workload, action: $key");
            #}

            if (not exists $keysdatabase->{$key}{params}) {
               $keysdatabase->{$key}{params} = ["$key"];
               $keysdatabaseOrig->{$key}{params} = ["$key"];
            }
            my $paramsArray = $keysdatabase->{$key}{params};
#            if ($paramsArray->[0] eq $key) {
#               shift @$paramsArray;
#            }
            # Criteria to skip action key
            $parent = lc($parent);
            #All
            if (exists $keysdatabase->{$key}{derived_components}) {
               if ("all" ~~ @{$keysdatabase->{$key}{derived_components}}) {
                  $vdLogger->Info("Processing $key as it is part of derived component");
                  goto CONTINUE;
               } elsif ((defined $subcomponent) &&
                   (!($subcomponent ~~ @{$keysdatabase->{$key}{derived_components}}))) {
                  $vdLogger->Info("Skipping $key not part of subcomponent: $subcomponent" . Dumper($keysdatabase->{$key}{derived_components}));
                  next;
               } elsif ((defined $parent) && (not defined $subcomponent) &&
                   (!($parent ~~ @{$keysdatabase->{$key}{derived_components}}))) {
                  $vdLogger->Info("Skipping $key not part of parent: $parent" . Dumper($keysdatabase->{$key}{derived_components}));
                  next;
               }
            }
            CONTINUE:
            # If Action key doesnot have linked workload
            if (not exists $keysdatabase->{$key}{linkedworkload}) {
               $masterActionArray =  $masterActionArray .
                  AddActionKeyNoLinkedWorkloadToWiki ($keysdatabaseOrig,
                                                      $key,
                                                      $keysdatabase,
                                                      $indexAction,
                                                      $refhash,);
            } else {
                # If Action key has a linked workload, then recurse
                my @arroayOfWorkloads;
                my $workloadName = $workload . "Workload";
                my $format;
                if ((ref($keysdatabase->{$key}{format}) =~ /hash/i) ||
                (ref($keysdatabase->{$key}{format}) =~ /array/i)) {
                   $format = dclone $keysdatabase->{$key}{format};
                   my $payloadNoFormat = RecurseThroughFormat($format,
                                                           $keysdatabase,
                                                           $key);
                   $keysdatabase->{$key}{format} =
                     RecurseThroughFormatAndHyperLink($format,
                                                    $keysdatabase,
                                                    $key);
                } else {
                   $format = $keysdatabase->{$key}{format};
#                   # Iterate through params
#                   my @arrOfParams = $keysdatabase->{$key}{params};
#                   foreach my $param (@arrOfParams) {
#                      $payloadNoFormat->{$param} = $keysdatabase->{$keysdatabase}{sample_value};
#                   }
                }
                my $title = ucfirst($key);
                $link = "\[$hyperlink#$title $key]";
                # Recurse if the linked workload is not the
                # same as parent workload
                my ($masterSchemaReturned, $masterPayloadReturned);
                if ((exists $keysdatabase->{$key}{linkedworkload}) &&
                    (defined $keysdatabase->{$key}{linkedworkload}) &&
                    ($keysdatabase->{$key}{linkedworkload} ne $workloadName)) {
                   push @arroayOfWorkloads, $keysdatabase->{$key}{linkedworkload};
                   ($masterSchemaReturned, $masterPayloadReturned) =
                      RecurseThroughKeysDB(
                                     \@arroayOfWorkloads,
                                     $key,
                                     $workload,
                                     undef,
                                     $masterSchema->{$keyUsedForSchema}{$link},
                                     $link,
                                     $masterPayload->{$keyUsedForSchema}{$key});
                }
                # Recurse if the linked workload is the
                # same as parent workload
                if ((exists $keysdatabase->{$key}{linkedworkload}) &&
                    (defined $keysdatabase->{$key}{linkedworkload}) &&
                    ($keysdatabase->{$key}{linkedworkload} eq $workloadName) &&
                    ($allowOnce eq "0")) {
                   push @arroayOfWorkloads, $keysdatabase->{$key}{linkedworkload};
                   $allowOnce++;
                   ($masterSchemaReturned, $masterPayloadReturned) =
                      RecurseThroughKeysDB(
                                     \@arroayOfWorkloads,
                                     $key,
                                     $subcomponent,
                                     $allowOnce,
                                     $masterSchema->{$keyUsedForSchema}{$link},
                                     $link,
                                     $masterPayload->{$keyUsedForSchema}{$key});
                }
                if (defined $masterPayloadReturned) {
                   ModifyMasterSchema($masterPayloadReturned,
                                      $masterSchema,
                                      $refhash,
                                      $link,
                                      $masterSchemaReturned,
                                      $keyUsedForSchema);
                }
                if ($allowOnce <= 1) {
                   my $title = ucfirst($key);
                   $masterSubCompArray = $masterSubCompArray .
                       "\[$hyperlink#$title $key], ";
                } else {
                   return ($masterSchema, $masterPayload);
                }
            }
            if ($paramsArray->[0] eq $key) {
               shift @$paramsArray;
            }
            push @masterparamArray, @$paramsArray;
         }
      }
      if (keys %$refhash) {
         if ($workload eq "Root") {
            $masterPayload->{$keyUsedForSchema} = $refhash;
         } else {
            $masterPayload->{$keyUsedForSchema}{'[1]'} = $refhash;
         }
         
      }
      $vdLogger->Debug("List of Params" . Dumper(\@masterparamArray));
      foreach my $parameter (@masterparamArray) {
         $masterContent = $masterContent . AddParamtersToWiki($keysdatabaseOrig,
                                                              $keysdatabase,
                                                              $parameter,
                                                              $refhash);
      }
      my $size = @masterparamArray;
      #print "\nArray size1:$size";
      # For those workload which dont have action keys
      my $refHashWhenNoActionKey;
      if ($size <= 2) {
         foreach my $parameter (keys %$keysdatabase) {
            if (($keysdatabase->{$parameter}{type} eq "parameter")
              #&&
             #!(@{$keysdatabase->{$parameter}{derived_components}} ~~  "all")
            ) {
               #print "\nCheck for $parameter" . Dumper($keysdatabaseOrig);
               my $payload;
               my $masterPayloadDup;
               ($masterPayloadDup, $payload) = AddParamtersToWiki($keysdatabaseOrig,
                                                      $keysdatabase,
                                                      $parameter,
                                                      $refhash);
                $masterContent = $masterContent . $masterPayloadDup;
               $refHashWhenNoActionKey->{$parameter} = $payload;
            }
         }
      }
      if (!(keys %$refhash)) {
         $masterPayload->{$keyUsedForSchema}{'[1]'} = $refHashWhenNoActionKey;
      }
      $masterContent = AddActionAndSubComponentToWiki($masterSubCompArray,
                                                      $masterActionArray,
                                                      $masterContent);
      #print Dumper($masterContent);
      EditWiki($masterContent);
   }
   return ($masterSchema, $masterPayload);
}


sub UpdateMasterScehmaAndPayload
{
   my $content = shift;
   my $payload = shift;

   my $mw = MediaWiki::API->new();
   $mw->{config}->{api_url} =
       "https://$user:$passwd\@wiki.eng.vmware.com/wiki/api.php";

   my $ref = $mw->get_page( { title => $PageName} );
   my $title = $PageName;
   $content = PrettyPrint($content);
   $payload = PrettyPrint($payload);

   my $masterContent = '==\'\'\'' . "Master Schema" . '\'\'\'==' . "\n";
   $masterContent = $masterContent . '<pre\>' . $content . '</pre\>' . "\n";
   $masterContent = $masterContent . '==\'\'\'' . "Master Payload" .
                    '\'\'\'==' . "\n";
   $masterContent = $masterContent . '<pre\>' . $payload . '</pre\>' . "\n";
   #print Dumper($masterContent);
   $mw->edit( {
     action => 'edit',
     title => $title,
     text => $masterContent,
     section => '0',
     format => 'jsonfm',
     bot => 1});
}


sub EditWiki
{
   my $content = shift;

   my $mw = MediaWiki::API->new();
   $mw->{config}->{api_url} =
       "https://$user:$passwd\@wiki.eng.vmware.com/wiki/api.php";

   my $ref = $mw->get_page( { title => $PageName} );
   my $title = $PageName;
   $mw->edit( {
     action => 'edit',
     title => $title,
     text => $content,
     section => 'new',
     format => 'jsonfm',
     bot => 1});
}


sub PrettyPrint
{
   my $resolvedFormat = shift;

   my $dumper = new Data::Dumper([$resolvedFormat]);
   $dumper->Indent(1);
   $dumper->Terse(1);
   $dumper->Quotekeys(0);
   my $dumperValue = $dumper->Dump();
   return $dumperValue
}


sub RemoveContentFromWiki
{
   my $content = shift;

   my $mw = MediaWiki::API->new();
   $mw->{config}->{api_url} =
       "https://$user:$passwd\@wiki.eng.vmware.com/wiki/api.php";

   my $ref = $mw->get_page( { title => $PageName} );
   my $title = $PageName;
     $mw->edit( {
       action => 'edit',
       title => $title,
       text => ' ',});
}


sub GetAllYamlPackages
{
   my $yamlLocation = shift;
   my @files = read_dir $yamlLocation;

   my @arrayOfWorkloadPackages;
   foreach my $file (@files)
   {
      if (($file eq 'Utils.yaml') ||
          ($file eq 'Utilities.yaml') ||
          ($file eq 'DVFilterSlowpathWorkload.yaml') ||
          ($file eq 'TrafficWorkload.yaml') ||
          ($file eq 'TrafficWorkload.yaml') ||
          ($file eq 'WorkloadKeys.yaml') ||
          ($file eq 'WorkloadsManager.yaml') ||
          ($file eq 'CommandWorkload.yaml')) {
         next;
      }
      my @array = split ('\.', $file);
      my $workloadName = $array[0];
      push @arrayOfWorkloadPackages, $workloadName;
   }
   return \@arrayOfWorkloadPackages;
}


sub RecurseThroughFormatAndHyperLink
{
   my $format       = shift;
   my $keysdatabase = shift;
   my $actionkey    = shift;

   my $result;
   if (ref($format) =~ /HASH/) {
      $vdLogger->Debug("Start for hashes");
      foreach my $key (keys %$format) {
         if ((ref($format->{$key}) =~ /HASH/) ||
             (ref($format->{$key}) =~ /ARRAY/)) {
            my $result =  RecurseThroughFormatAndHyperLink($format->{$key},
                                                           $keysdatabase,
                                                           $key);
            $format->{$key} = $result;
         } else {
            if ($format->{$key} =~ /ref/i) {
               my $element = $format->{$key};
               $element =~ s/ref\: //;
               $format->{$key} = "\[$hyperlink#$element $element]";
            }
         }
      }
   } elsif (ref($format) =~ /ARRAY/) {
      my @arrayFormat;
      foreach my $element (@$format) {
         my $result;
         $vdLogger->Debug("Start for arrays");

         if ((ref($element) =~ /HASH/) ||
             (ref($element) =~ /ARRAY/)) {
            $result = RecurseThroughFormatAndHyperLink($element,
                                                       $keysdatabase,
                                                       $actionkey);
         } else {
            if ($element =~ /ref/i) {
               $element =~ s/ref\: //;
               $result = "\[$hyperlink#$element $element]";
            } else {
               $result = $element;
            }
         }
         push @arrayFormat, $result;
      }
      return \@arrayFormat;
   } else {
      $vdLogger->Debug("Start for arrays");
      return $keysdatabase->{$actionkey}{format};
   }
   return $format;
}


sub RecurseThroughFormat
{
   my $format       = shift;
   my $keysdatabase = shift;
   my $actionkey    = shift;

   my $result;
   if (ref($format) =~ /HASH/) {
      $vdLogger->Debug("Start for hashes");
      foreach my $key (keys %$format) {
         if ((ref($format->{$key}) =~ /HASH/) ||
             (ref($format->{$key}) =~ /ARRAY/)) {
            my $result =  RecurseThroughFormat($format->{$key},
                                               $keysdatabase,
                                               $key);
            if ((ref($result) =~ /HASH/) ||
             (ref($result) =~ /ARRAY/)) {
                $format->{$key} = dclone $result;
             } else {
                $format->{$key} = $result;
             }
         } else {
            if ($format->{$key} =~ /ref/i) {
               my $element = $format->{$key};
               $element =~ s/ref\: //;
               $format->{$key} = $keysdatabase->{$element}{sample_value};
            }
         }
      }
   } elsif (ref($format) =~ /ARRAY/) {
      my @arrayFormat;
      foreach my $element (@$format) {
         my $result;
         $vdLogger->Debug("Start for arrays");
         if ((ref($element) =~ /HASH/) ||
             (ref($element) =~ /ARRAY/)) {
            $result = RecurseThroughFormat($element,
                                           $keysdatabase,
                                           $actionkey);
            if ((ref($result) =~ /HASH/) ||
             (ref($result) =~ /ARRAY/)) {
                $result = dclone $result;
             }
         } else {
            if ($element =~ /ref/i) {
               $element =~ s/ref\: //;
               $result = $keysdatabase->{$element}{sample_value};
            } else {
               $result = $element;
            }
         }
         push @arrayFormat, $result;
      }
      return \@arrayFormat;
   } else {
      $vdLogger->Debug("Start for arrays");
      return $keysdatabase->{$actionkey}{sample_value};
   }
   return $format;
}


sub GetKeysDBFromWorkload
{
   my $workload = shift;

   $vdLogger->Info("Loading $workload from $location");
   my $path = $location;
   my $file = $path . '/yaml/' . $workload . '.' . 'yaml';
   my $keysdatabaseOrig = VDNetLib::Common::Utilities::ConvertYAMLToHash($file);
   return $keysdatabaseOrig;
}


sub AddParamtersToWiki
{
   my $keysdatabaseOrig = shift;
   my $keysdatabase     = shift;
   my $parameter        = shift;
   my $refHash          = shift;

   my $masterContent;
   $vdLogger->Info("parameter: $parameter");
   $masterContent = $masterContent . '====\'\'\'' . $parameter . '\'\'\'====' . "\n";
   $masterContent = $masterContent . '<pre\>' .
                 "Description: $keysdatabaseOrig->{$parameter}{description}" . "\n";
   my ($format, $payload, $key, $dumperValue, $payloadNoFormat);
   if ((ref($keysdatabaseOrig->{$parameter}{format}) =~ /hash/i) ||
       (ref($keysdatabaseOrig->{$parameter}{format}) =~ /array/i)) {
      $format = dclone $keysdatabaseOrig->{$parameter}{format};
      #$payload = RecurseThroughFormat($keysdatabase->{$parameter}{format},
      #                                   $keysdatabase,
      #                                   $parameter);
      $payload = $keysdatabaseOrig->{$parameter}{sample_value};
      $payloadNoFormat = $keysdatabaseOrig->{$parameter}{sample_value};
      $payload = PrettyPrint($payload);
      # Format
      my $resolvedFormat = RecurseThroughFormatAndHyperLink(
                                                     $keysdatabaseOrig->{$parameter}{format},
                                                     $keysdatabase,
                                                     $parameter);
      $dumperValue = PrettyPrint($resolvedFormat);
   } else {
      $dumperValue = $keysdatabaseOrig->{$parameter}{format};
      $payloadNoFormat = $keysdatabaseOrig->{$parameter}{sample_value};
      $payload = PrettyPrint($dumperValue);
      $payload = $keysdatabaseOrig->{$parameter}{sample_value};
      $payload = PrettyPrint($payload);
   }

   $masterContent = $masterContent ."Format: "  . $dumperValue . "\n";
   my $commaSeparatedDComp;
   if (exists $keysdatabaseOrig->{$parameter}{derived_components}) {
      $commaSeparatedDComp =
                     join ',' , @{$keysdatabaseOrig->{$parameter}{derived_components}};
   }

   $masterContent = $masterContent ."Derived Component: " .
                    $commaSeparatedDComp . "\n";
   $masterContent = $masterContent ."Sample Value: "  .
                    $payload . '</pre\>' . "\n";

   if (!(keys %$refHash)) {
      return ($masterContent, $payloadNoFormat);
   } else {
      return $masterContent;
   }
   
}


sub AddHeaderForActionToWiki
{
   my $workload      = shift;
   my $parent        = shift;
   my $hyperlink     = shift;
   my $link          = shift;
   my $subcomponent  = shift;
   my $masterContent;
  
   my $keyUsedForSchema;
   my $title = undef;
   if ( defined $subcomponent ) {
      $title = ucfirst($subcomponent);
      if ( not defined $link ) {
         $link = "\[$hyperlink#$title $subcomponent]";
       }
       $keyUsedForSchema = $link;
   }
   else {
       $title = ucfirst($workload);
       if ( not defined $link ) {
          $link = "\[$hyperlink#$title $workload]";
       }
       $keyUsedForSchema = $link;
   }
   $masterContent = $masterContent . '==\'\'\'' . $title . '\'\'\'==' . "\n";
   my $subCompomemtType = undef;
   if (not defined $parent) {
      $parent = $workload;
      $subCompomemtType = "Root";
   } else {
      $subCompomemtType = $parent;
   }
   $masterContent = $masterContent .
   "This is sub-component of $subCompomemtType" .
   " \(\[$hyperlink#Master_Schema master schema\]\, " .
   "\[$hyperlink#Master_Payload master payload\]\, \[$hyperlink top\]\)" . "\n";
   $masterContent = $masterContent . '===\'\'\'' .
                    "Properties" . '\'\'\'===' . "\n";
   return ($keyUsedForSchema, $masterContent, $link, $parent);
}


sub AddActionAndSubComponentToWiki
{
   my $masterSubCompArray = shift;
   my $masterActionArray  = shift;
   my $masterContent      = shift;
  
   $masterContent = $masterContent .
                    '===\'\'\'' . "Actions" . '\'\'\'===' . "\n";
   $masterContent = $masterContent . $masterActionArray;
   $masterContent = $masterContent .
                    '===\'\'\'' . "Sub Components" . '\'\'\'===' . "\n";
   substr ($masterSubCompArray, -2) = " ";
   if ($masterSubCompArray eq " ") {
      $masterSubCompArray = "None";
   }
   $masterSubCompArray = $masterSubCompArray . "\n\n";
   $masterContent = $masterContent . $masterSubCompArray;
   return $masterContent;
}


sub AddActionKeyNoLinkedWorkloadToWiki
{
   my $keysdatabaseOrig  = shift;
   my $key               = shift;
   my $keysdatabase      = shift;
   my $indexAction       = shift;
   my $refhash           = shift;
   my $masterActionArray;

   $indexAction++;
   $masterActionArray = $masterActionArray .
                        '\'\'\'' . "$key" . '\'\'\'' ." \n";
   $masterActionArray = $masterActionArray . 
            '<pre\>' . "Description: $keysdatabase->{$key}{description}" . "\n";
   if (exists $keysdatabaseOrig->{$key}{derived_component}) {
      my $commaSeparatedDComp =
          join ',' , @{$keysdatabaseOrig->{$key}{derived_component}};
      $masterActionArray = $masterActionArray .
          "Derived Component: $commaSeparatedDComp" . "\n";
   }

   my @array = @{$keysdatabaseOrig->{$key}{params}};
   @array = grep { $_ != $key } @array;
   my $commaSeparated = join ',' , @{$keysdatabaseOrig->{$key}{params}};
   my $format;
   my ($payloadNoFormat, $payload, $resolvedFormat, $dumperValue, $flag);
   my $payloadNoPrettyPrint = {};
   if ((ref($keysdatabase->{$key}{format}) =~ /hash/i) ||
   (ref($keysdatabase->{$key}{format}) =~ /array/i)) {
      $format = dclone $keysdatabase->{$key}{format};
      my $payloadTemp = RecurseThroughFormat($format, $keysdatabase, $key);
      #$payloadNoFormat = $payloadTemp;
      $payloadNoFormat = $keysdatabase->{$key}{sample_value};
      $payload = PrettyPrint($keysdatabase->{$key}{sample_value});
      $resolvedFormat = RecurseThroughFormatAndHyperLink(
                           $keysdatabase->{$key}{format},
                           $keysdatabase,
                           $key);
      my $dumperTemp = $resolvedFormat;
      $dumperValue = PrettyPrint($dumperTemp);
      $flag = undef;
   } else {
      $format = $keysdatabase->{$key}{format};
      if ($format =~ /not available/i) {
         $vdLogger->Info("Format/sample value not available at this point of time");
         $dumperValue = "not available";
         $payload = "not available";
         $payloadNoFormat = "not available";
      } else {
         $flag = 1;
         # Iterate through params
         my @arrOfParams = @{$keysdatabase->{$key}{params}};
         for my $index (0 .. $#arrOfParams) {
            my $param = $arrOfParams[$index];
            #print "\nFor param = $param\n";
            if (exists $keysdatabase->{$param}) {
               $payload->{$param} = $keysdatabase->{$param}{sample_value};
               $payloadNoFormat->{$param} = "\[$hyperlink#$param $param]";
               $dumperValue = PrettyPrint($payloadNoFormat);
            } elsif (exists $keysdatabaseParent->{$param}) {
               $payload->{$param} = $keysdatabaseParent->{$param}{sample_value};
               $payloadNoFormat->{$param} = "\[$hyperlink#$param $param]";
               $dumperValue = PrettyPrint($payloadNoFormat);
            }
         }
         $payloadNoPrettyPrint = $payload;
         $payload = PrettyPrint($payload);
      }
   }

   $masterActionArray = $masterActionArray .
                        "Additional Parameters:" . $dumperValue . "\n";
   $masterActionArray = $masterActionArray .
                        "Sample Value:" . $payload . '</pre\>' . "\n";

   if (($key =~ /reconfigure/i) && (not defined $flag)) {
      %$refhash = (%$refhash, %$payloadNoFormat);
   } elsif (($key !~ /reconfigure/i) && (not defined $flag)) {
      $refhash->{$key} = $payloadNoFormat;
      #$refhash->{$key} = $payload;
   } else {
      #$refhash->{$key} = $payload;
      %$refhash = (%$refhash, %$payloadNoPrettyPrint);
   }

   if ((exists $keysdatabase->{$key}{dependency}) &&
      (defined $keysdatabase->{$key}{dependency}) &&
      ($keysdatabase->{$key}{dependency} ne "undef")) {
       my $commaSeparated = join ',' , @{$keysdatabaseOrig->{$key}{dependency}};
      $masterActionArray = $masterActionArray . ' ' .
                           "Dependency: $commaSeparated" . " \n";
   }
   $masterActionArray = $masterActionArray . "\n\n";

   return $masterActionArray;
}

sub ModifyMasterSchema
{
   my $masterPayloadReturned = shift;
   my $masterSchema          = shift;
   my $refhash               = shift;
   my $link                  = shift;
   my $masterSchemaReturned  = shift;
   my $keyUsedForSchema      = shift;

   $masterSchema->{$keyUsedForSchema}{$link} = $masterSchemaReturned;
   %$refhash = ( %$refhash, %$masterPayloadReturned );
   if ( not defined $masterSchema->{$keyUsedForSchema}{$link} ) {
    $masterSchema->{$keyUsedForSchema}{$link} = {};
   }
   else {
    $masterSchema->{$keyUsedForSchema}{$link} =
      $masterSchema->{$keyUsedForSchema}{$link}{$link};
    delete $masterSchema->{$keyUsedForSchema}{$link}{$link};
   }
}


sub GetAllWorkloadPackages
{
   my @files = read_dir $location;
   my @arrayOfWorkloadPackages;
   foreach my $file (@files) {
      if (($file eq 'Utils.pm') ||
          ($file eq 'Utilities.pm') ||
          ($file eq 'DVFilterSlowpathWorkload.pm') ||
          ($file eq 'TrafficWorkload.pm') ||
          ($file eq 'TrafficWorkload') ||
          ($file eq 'WorkloadKeys.pm') ||
          ($file eq 'yaml') ||
          ($file eq '') ||
          ($file eq ' ') ||
          ($file eq 'CommandWorkload.pm') ||
          ($file eq 'VerificationWorkloadbkp.pm') ||
          ($file eq 'WorkloadsManager.pm') ||
          ($file eq 'LocalVDRWorkload')) {
         next;
      }
      my @array = split ('\.', $file);
      my $workloadName = $array[0];
      push @arrayOfWorkloadPackages, $workloadName;
   }
   return \@arrayOfWorkloadPackages;
}


sub GenerateYamlDescriptor
{
   my $keysdatabase = shift;
   eval {
      Bless ($keysdatabase);
   };
   if ($@) {
      $vdLogger->Error("Unable to convert hash to yaml : $@");
      VDSetLastError("EOPFAILED");
      return "FAILURE";
   }
   return $keysdatabase;
}


sub StoreYamlDescriptor
{
   my $descriptor = shift;
   my $file       = shift;
   eval {
      my $destTdsHandle;
      open($destTdsHandle, ">", $file);
      $vdLogger->Debug("Storing yaml descriptor at $file");
      print $destTdsHandle Dump $descriptor;
   };
   if ($@) {
      $vdLogger->Error("Unable to store yaml descriptor at $file: $@");
      VDSetLastError("EOPFAILED");
      return "FAILURE";
   }
   return "SUCCESS";
}

__END__
          #'VMWorkload',
          #'VCWorkload',
          $CheckWorkload,
          #'SwitchWorkload',
          #'NSXWorkload',
          #'TestInventoryWorkload',
          #'NetAdapterWorkload',

our @workloadBin = [
          'VMWorkload',
          'VCWorkload',
          'TestInventoryWorkload',
          'HostWorkload',
          'NSXWorkload'
        ];
