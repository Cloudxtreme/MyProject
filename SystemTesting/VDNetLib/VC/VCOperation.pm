# Copyright (C) 2012 VMware, Inc.
# All Rights Reserved
###############################################################################

###############################################################################
#
# Package VDNetLib::VC::VCOperation
#
#   This package allows to perform various operations on VC server through STAF
#   command and retrieve status related to these operations.
#   New object of this call will be created in VCWorkload class and has a
#   1-on-1 relationship with VCWorkload object.
#
###############################################################################

package VDNetLib::VC::VCOperation;

use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject);
use strict;
use warnings;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../";
use lib "$FindBin::Bin/../VDNetLib/";
use lib "$FindBin::Bin/../VDNetLib/CPAN/5.8.8/";
use Net::IP;
use VDNetLib::Common::STAFHelper;
use VDNetLib::Common::Utilities;
use VDNetLib::Common::EsxUtils;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS
                                   VDCleanErrorStack);
use VDNetLib::InlineJava::VDNetInterface qw(LoadInlineJava CreateInlineObject
                                         InlineExceptionHandler NewDataHandler
                                         LoadInlineJavaClass);
use VDNetLib::InlinePython::VDNetInterface qw(CreateInlinePythonObject
                                              ConfigureLogger
                                              CallMethodWithKWArgs);
use VDNetLib::Common::GlobalConfig qw($vdLogger);
use VDNetLib::InlineJava::OptionManager;
use VDNetLib::InlineJava::SessionManager;
use VDNetLib::InlineJava::Folder;
# autodeploy server command
use constant CMD_VMWARE_RBD_WATCHDOG_STOP => '/etc/rc.d/vmware-rbd-watchdog stop';
use constant CMD_VMWARE_RBD_WATCHDOG_START => '/etc/rc.d/vmware-rbd-watchdog start';
# tftpd server command
use constant CMD_ATFTPD_START => '/etc/rc.d/atftpd start';
# TRUE and FALSE will be used by some InlineJava functions as return
use constant TRUE  => 1;
use constant FALSE => 0;

###############################################################################
#
# new --
#      Constructor/entry point to create an object of this package
#      (VDNetLib::VC::VCOperation).
#
# Input:
#
#
# Results:
#      An object of VDNetLib::VCOperation package.
#
# Side effects:
#      None
#
###############################################################################

sub new {
   # Class and Argument defaults
   my ( $class, $vcaddr, $username, $passwd, @params ) = @_;
   my $self = {};
   my $options;
   my $helper;

   bless( $self, $class );
   if (not defined $vcaddr) {
      $vdLogger->Error("VC IP not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $options->{logObj}  = $vdLogger;
   $helper = VDNetLib::Common::STAFHelper->new($options);
   $self->{stafHelper} = $helper;
   $self->{esxutils}   = VDNetLib::Common::EsxUtils->new($vdLogger);
   $self->{vcaddr} = $vcaddr;
   $self->{proxy}  = VDNetLib::Common::GlobalConfig::DEFAULT_STAF_SERVER;
   $self->{user}   = $username;
   $self->{passwd} = $passwd;
   $self->{switchtype}   = VDNetLib::Common::GlobalConfig::DEFAULT_SWITCH_TYPE;
   $self->{netmask}      = VDNetLib::Common::GlobalConfig::DEFAULT_NETMASK;
   $self->{globalConfig} = new VDNetLib::Common::GlobalConfig();
   $self->{setupAnchor}  = undef;
   $self->{hostAnchor}   = undef;
   $self->{vmAnchor}     = undef;
   $self->{VDS}          = undef;
   $self->{datacenter}   = undef;
   $self->{_pyclass}     = "vmware.vsphere.vc.vc_facade.VCFacade", # python path
   #
   # Create VC Anchor's to Host, VM and VC
   my $result = $self->ConnectVC();
   if ($result eq FAILURE) {
      $vdLogger->Error("Connection to VC Failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   #
   # Create InlineJavaVC object corresponding to each object of this class
   #
   my $inlineVCSession = $self->GetInlineVCSession();

   if (!$inlineVCSession) {
      $vdLogger->Error("Failed to create VDNetLib::InlineJava::SessionManager " .
                       "object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   return $self;
}


####################################################################
#
# GetInlinePyObject --
#     Methd to get Python equivalent object of this class
#
# Input:
#     None
#
# Results:
##     Reference to Inline Python object of this class
#
# Side effects:
#     None
#
#######################################################################

sub GetInlinePyObject
{
   my $self = shift;
   my $inlinePyObj;
   eval {
      $inlinePyObj = CreateInlinePythonObject($self->{_pyclass},
                                              $self->{vcaddr},
                                              $self->{user},
                                              $self->{passwd});
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while creating " .
                       "inline component of $self->{_pyclass}:\n". $@);
      return FAILURE;
   }
   if (exists $self->{id}) {
      $inlinePyObj->{id} = $self->{id};
   }
   return $inlinePyObj;
}


####################################################################
#
# GetInlineFolderObject --
#     Method to get Python equivalent object for
#     pylib.vmware.vsphere.vc.folder.folder_facade.FolderFacade
#
# Input:
#     None
#
# Results:
#     Reference to Inline Python object for
#     pylib.vmware.vsphere.vc.folder.folder_facade.FolderFacade
#
# Side effects:
#     None
#
#######################################################################

sub GetInlineFolderObject
{
   my $self = shift;
   my $folder = shift;
   my $inlinePyObj;
   my $pyclass = "vmware.vsphere.vc.folder.folder_facade.FolderFacade";
   my $vcPyObj = $self->GetInlinePyObject();
   eval {
      $inlinePyObj = CreateInlinePythonObject($pyclass,
                                              $vcPyObj,
                                              $folder);
   };
   if ($@) {
      $vdLogger->Error("Exception thrown while creating " .
                       "inline component of $self->{_pyclass}:\n". $@);
      return FAILURE;
   }
   if (exists $self->{id}) {
      $inlinePyObj->{id} = $self->{id};
   }
   return $inlinePyObj;
}


###############################################################################
#
# Attach --
#      This method attaches a vds object to the vc object.
#
# Input:
#    key: A string identifying the object, eg vds-switch.
#    value: A reference to the object to be added
#
# Results:
#      Returns "SUCCESS",on success.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub Attach
{
   # deprecate this API
   my $self = shift;
   my %arg = @_;
   my $key = $arg{key};
   my $value = $arg{value} || undef;

   if (not defined $key) {
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (defined $value) {
      if ($value =~ m/VDNetLib::Switch::VDSwitch/) {
         ${ $self->{ VDS }}{ $key } = $value;
         $vdLogger->Debug("vDS attached to the VC");
         return SUCCESS;
      } else {
        #
        # do nothing,return FAILURE since at this point only
        # vDS can be attached to VC. Modify this
        # if more objects need to attached.
        #
        return FAILURE;
     }
   }

   # check for the value and return.
   if ( exists ${ $self->{ VDS } }{ $key } ) {
      return ${ $self->{ VDS } }{ $key };
   } else {
      $vdLogger->Error("Key Not Found ($key)");
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}


###############################################################################
#
# Detach --
#      This method detaches a vds object from the vc object.
#
# Input:
#    key: A string identifying the object, eg vds-switch.
#    value: A reference to the object to be removed.
#
# Results:
#      Returns "SUCCESS",on success.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub Detach
{
   my $self = shift;
   my %args = @_;
   my $key = $args{key};
   my $value = $args{value} || undef;

   if (not defined $key) {
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (defined $value) {
      #
      # Detach it from the object.
      #
      if($value =~ m/VDNetLib::Switch::VDSwitch/) {
         delete ${ $self->{ VDS } }{ $key };
         if ( ! exists ${ $self->{ VDS } }{ $key } ) {
            return SUCCESS;
         }
      }
  } else {
      # if only $key is specified.
      if ( exists ${ $self->{ VDS } }{ $key } ) {
         delete ${ $self->{ VDS } }{ $key };
         if ( ! exists ${ $self->{ VDS } }{ $key } ) {
            return SUCCESS;
         }
      }
  }
  return FAILURE;
}

###############################################################################
#
# ConnectVC --
#      This method connect VC server.
#      Create anchor in STAF server ( localhost or specified STAF SERVER )
#
#
# Input:
#      vc     - VC IP adderss.
#      user   - VC use name
#      passwd - VC password
#      proxy  - STAF Server IP address
#
# Results:
#      Returns "SUCCESS", if connected and 3 anchors created
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub ConnectVC
{
   my $self    = shift;
   my $proxy   = $self->{proxy};
   my $user    = $self->{user};
   my $passwd  = $self->{passwd};
   my $vc      = $self->{vcaddr};

   # command to connect VC, creat new anchor for VM.jar
   my $command = " connect agent ".$vc." userid \"".$user."\" password \"".
                 $passwd."\" ssl ";
   my $result = $self->{stafHelper}->STAFSubmitVMCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to connect VC failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Debug("VM jar anchor is : $result->{result}");
   $self->{vmAnchor} = $result->{result};

   # command to connect VC, creat new anchor for host.jar
   $command = " connect agent ".$vc." userid \"".$user."\" password \"".
              $passwd."\" ssl ";
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to connect VC failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $self->{hostAnchor} = $result->{result};
   $vdLogger->Debug("Host jar anchor is : $result->{result}");

   # command to connect VC, creat new anchor for setup.jar
   $command = " connect agent ".$vc." userid \"".$user."\" password \"".
              $passwd."\" ssl ";
   $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to connect VC failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Debug("Setup jar anchor is : $result->{result}");
   $self->{setupAnchor} = $result->{result};

   $vdLogger->Trace("Connected with VC ($vc) with u/p = $user/$passwd.");
   return SUCCESS;
}


###############################################################################
#
# CreateDCWithHosts --
#      This method creates a datacenter on VC server and adds specified hosts
#      TODOver2: Need to be depricated in future
#
# Input:
#      dcname     - Datacenter Name.
#      hostObjs   - reference to array of hostObj.
#
# Results:
#      Returns "SUCCESS", if datacenter created
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub CreateDCWithHosts
{
   my $self         = shift;
   my $dcname       = shift; # mandatory
   my $hostObjs     = shift; # mandatory
   my $proxy        = $self->{proxy};
   my @hostList;

   my $result = $self->CreateDC($dcname);
   if ($result eq "FAILURE") {
      $vdLogger->Error("STAF command to create dc failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   # Add host into dc
   if (not defined $hostObjs) {
      $vdLogger->Error("Reference to array of Host object not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   } else {
      # Remove duplicate host.
      foreach my $hostObj (@$hostObjs) {
         my $hostIP = $hostObj->{hostIP};
         #
         # Check if the host is already in the list of hosts added to
         # the given datacenter. PR766461
         #
         my $i = grep{/^$hostIP$/} @hostList;
         if ($i != 0) {
            $vdLogger->Debug("$hostIP is already added to $dcname");
            next;
         }

         my $esx_root = $hostObj->{userid};
         if (not defined $esx_root) {
            $esx_root = VDNetLib::Common::GlobalConfig::DEFAULT_ESX_USER;
         }

         # use sshPassword which doesn't have any extra escape \
         my $esx_passwd = $hostObj->{sshPassword};
         if (not defined $esx_passwd) {
            $esx_passwd = VDNetLib::Common::GlobalConfig::DEFAULT_ESX_PASSWD;
         }
         $vdLogger->Info("Adding host $hostIP into DC ($dcname).........");
         my $command = " addhost anchor ". $self->{hostAnchor}.
                    " host ". $hostIP . " login " . $esx_root.
                    " password " . $esx_passwd . " hostfolder " . $dcname ;
         $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
         if ($result->{rc} != 0) {
            $vdLogger->Error("Failure to add host($hostIP) to ".
                             "datacenter($dcname)" . Dumper($result));
            VDSetLastError("ESTAF");
            return FAILURE;
         }
         push(@hostList, $hostIP);
      }
   }
   $vdLogger->Info("New DataCenter ($dcname) created.");
   return SUCCESS;
}


###############################################################################
#
# AddDCWithHosts --
#      This method creates a datacenter on VC server and adds specified hosts
#
# Input:
#      arrayOfSpecs     - array of dc specs
#
# Results:
#      Returns ref to dc objects, if datacenter created
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub AddDCWithHosts
{
   my $self = shift;
   my $arrayOfSpecs = shift;
   my (@arrayOfDCObjects);
   my $result;
   foreach my $element (@$arrayOfSpecs) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("DC spec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my %options = %$element;
      my $datacenter   = $options{name};
      my $folder       = $options{foldername};
      my $hostObjArray = $options{host};

      if ((not defined $datacenter) || $datacenter =~ /auto/i) {
         $datacenter = VDNetLib::Common::Utilities::GenerateName("datacenter","1");
         $folder     = (defined $folder) ? $folder :
            VDNetLib::Common::Utilities::GenerateName("folder","1");
      } else {
         $folder     = (defined $folder) ? $folder : "folder"."-".$datacenter;
      }

      #create a folder.
      $result = $self->AddFolder($folder);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to create the folder");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      # create a datacenter.
      my $hostFolder = "/".$folder."/".$datacenter;
      $result = $self->CreateDC($hostFolder);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to create datacenter");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      my $dcObj = VDNetLib::VC::Datacenter->new(vcObj           => $self,
                                                datacenter      => $datacenter,
                                                folder          => $folder,
                                                stafHelper      => $self->{stafHelper});
      if ($dcObj eq FAILURE) {
            $vdLogger->Error("Failed to create Datacenter object for ".
                             "datacenter: $datacenter");
            VDSetLastError(VDGetLastError());
            return FAILURE;
      }
      push @arrayOfDCObjects, $dcObj;
      $result = $dcObj->AddHostsToDC($hostObjArray, $hostFolder);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to add required hosts to datacenter: ".
                          "$dcObj->{datacentername}");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return \@arrayOfDCObjects;
}


###############################################################################
#
# CreateDC --
#      This method creates a datacenter on VC server
#
# Input:
#      dcname     - Datacenter Name.
#      hostObjs   - reference to array of hostObj.
#
# Results:
#      Returns "SUCCESS", if datacenter created
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub CreateDC
{
   my $self         = shift;
   my $dcname       = shift; # mandatory

   if (not defined $dcname) {
      $vdLogger->Error("DataCenter name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my @temp = split(/\//, $dcname);
   my $folder = $temp[-2];
   $dcname = $temp[-1];
   my $dcObj = VDNetLib::VC::Datacenter->new(vcObj           => $self,
                                             datacenter      => $dcname,
                                             folder          => $folder,
                                             stafHelper      => $self->{stafHelper});
   my $dcPyObj = $dcObj->GetInlinePyObject();
   my $result = CallMethodWithKWArgs($dcPyObj, 'create', {'folder' => $folder});
   if (defined $result && $result eq FAILURE){
       $vdLogger->Error("Failed to create datacenter ($dcname) on VC");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
   $vdLogger->Info("New DataCenter ($dcname) created.");
   return SUCCESS;
}


###############################################################################
#
# AddUplink --
#      This method add one or more uplink into VDS
#
# Input:
#      VDS name          -   VDS name
#      netObjs           -   reference to array of netadapter objs
#                            (These are free nics netadapter objs)
# Results:
#      Returns "SUCCESS", if success.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub AddUplink
{
   my $self         = shift;
   my $vdsname      = shift; # mandatory
   my $netObjs      = shift; # mandatory
   my $proxy        = $self->{proxy};
   my $result;
   my $command;

   if (not defined $vdsname) {
      $vdLogger->Error("VDS name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $netObjs ) {
      $vdLogger->Error("Reference to array of NetAdapter object not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   foreach my $netObj (@$netObjs) {
      my $vmnic  = $netObj->{interface};
      my $hostIP = $netObj->{hostObj}->{hostIP};
      my $driver = $netObj->{driver} || undef;
      if ((not defined $hostIP) && (not defined $vmnic)) {
         $vdLogger->Error("Reference to array of NetAdapter object not provided");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $vdLogger->Info("Add pNIC($vmnic) on ESX host ($hostIP) ".
                      "into  VDS ($vdsname)");
      $command = " BINDPNICSTODVS  anchor $self->{hostAnchor} dvsname \"$vdsname\" ".
                 "host $hostIP  pnics $vmnic";
      $vdLogger->Debug("STAF command: $command");
      $result = $self->{stafHelper}->
                          STAFSubmitHostCommand($proxy,$command);
      if ($result->{rc} != 0) {
         $vdLogger->Error("Fail to add pnic($vmnic) ".
                          "into vds($vdsname):" . Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   return SUCCESS;
}


###############################################################################
#
# RemoveUplink --
#      This method remove one uplink from VDS according specified ESXHost
#
# Input:
#      VDS name          -   VDS name
#      hostObj           -   reference to test hostObj
#      Uplink            -   comma separated list
#                            of uplinks
#
# Results:
#      Returns "SUCCESS", if success.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################


sub RemoveUplink
{
   my $self         = shift;
   my $vdsname      = shift; # mandatory
   my $hostIP      = shift; # mandatory
   my $uplink       = shift;
   my $proxy        = $self->{proxy};
   my @pnics;
   my ($i,$result,$ret,$found,$arrayref);
   if (not defined $vdsname) {
      $vdLogger->Error("VDS name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $tmpip = $hostIP;
   if (defined $uplink) {
      $uplink =~ s/\s//g; # remove any space
      @pnics = split(/,/,$uplink);
      $found = "true";
   } else {
      # Get VDS's uplink on ESX host
      ($arrayref,$ret,$found) = $self->getNRPUplinks($vdsname,$tmpip);
      @pnics = @$arrayref;
      if ($ret eq FAILURE) {
         $vdLogger->Error("Failed to find uplinks on $tmpip");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   if ($found eq "false"){
      $vdLogger->Warn("VDS($vdsname) didn't have uplinks..");
      return SUCCESS;
   }
   # Just remove one pNIC - $pnics[0]
   my $command = " UNBINDPNICSFROMDVS  anchor $self->{hostAnchor} dvsname \"$vdsname\" ".
                      "host $tmpip  pnics $pnics[0]";
   $vdLogger->Info("STAF command: $command");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Fail to delete pnic($pnics[0]) ".
                             "from vds($vdsname):" . Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   return SUCCESS;
}


###############################################################################
#
# RemoveDC --
#      This method remove specified DC from VC server.
#
# Input:
#      vc         - VC IP adderss.
#      dcname     - Datacenter Name.
#
# Results:
#      Returns "SUCCESS", if datacenter created
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub RemoveDC
{
   my $self         = shift;
   my $dcname       = shift; # mandatory

   if (not defined $dcname) {
      $vdLogger->Error("DataCenter name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my @temp = split(/\//, $dcname);
   my $folder = $temp[-2];
   $dcname = $temp[-1];
   my $dcObj = VDNetLib::VC::Datacenter->new(vcObj           => $self,
                                             datacenter      => $dcname,
                                             folder          => $folder,
                                             stafHelper      => $self->{stafHelper});
   my $dcPyObj = $dcObj->GetInlinePyObject();
   my $result = CallMethodWithKWArgs($dcPyObj, 'delete', {});
   if (defined $result && $result eq FAILURE){
       $vdLogger->Error("Failed to remove datacenter ($dcname) from VC ".
                        "$self->{vcaddr}");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
   $vdLogger->Info("Specified DataCenter ($dcname) removed from VC ".
                   "$self->{vcaddr}");
   return SUCCESS;
}


########################################################################
#
# DeleteDatacenter --
#      To Delete a list of data center from a vc
#
# Input:
#      arrayOfDCObjects: array of dc objects to be deleted
#
# Results:
#     Returns "SUCCESS" if the given dc is deleted successfully
#     Returns "FAILURE" in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub DeleteDatacenter
{
   my $self              = shift;
   my $arrayOfDCObjects  = shift; # mandatory

   foreach my $dcObject (@$arrayOfDCObjects) {
      my $dcname  = $dcObject->{'datacentername'};
      my $folder = $dcObject->{foldername};
      if (not defined $dcname) {
         $vdLogger->Error("DataCenter name not provided");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      my $dcObj = VDNetLib::VC::Datacenter->new(vcObj           => $self,
                                                datacenter      => $dcname,
                                                folder          => $folder,
                                                stafHelper      => $self->{stafHelper});
      my $dcPyObj = $dcObj->GetInlinePyObject();
      my $result = CallMethodWithKWArgs($dcPyObj, 'delete', {});
      if (defined $result && $result eq FAILURE){
          $vdLogger->Error("Failed to remove datacenter ($dcname) from VC ".
                           "$self->{vcaddr}");
          VDSetLastError(VDGetLastError());
          return FAILURE;
      }
      $vdLogger->Info("Specified DataCenter ($dcname) removed from VC ".
                      "$self->{vcaddr}" );
   }
   return SUCCESS;
}


########################################################################
#
# DeleteVDS --
#      To Delete a vds from a vc
#
# Input:
#      arrayOfVDSObjects: array of vds objects to be deleted
#
# Results:
#     Returns "SUCCESS" if the given vds is deleted successfully
#     Returns "FAILURE" in case of any error;
#
# Side effects:
#     None
#
########################################################################

sub DeleteVDS
{
   my $self              = shift;
   my $arrayOfVDSObjects = shift; # mandatory
   my $proxy             = $self->{proxy};
   my $vc                = $self->{vcaddr};

   foreach my $vdsObject (@$arrayOfVDSObjects) {
      my $vdsname  = $vdsObject->{'name'} || $vdsObject->{'switch'};
      if (not defined $vdsname) {
         $vdLogger->Error("$vdsname name not provided");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $vdLogger->Info("Begin to remove VDS($vdsname)..");
      my $cmd = " RMDVS anchor $self->{setupAnchor}".
             " DVSNAME \"".$vdsname."\"";
      $vdLogger->Debug("Run command : $cmd");
      my $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy,$cmd);
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failure to remove VDS ($vdsname)".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $vdLogger->Info("Remove VDS($vdsname)successfully.");
   }
   return SUCCESS;
}


###############################################################################
#
# AddFolder --
#      This method creates a generic folder on VC server.
#
# Input:
#      vc             - VC IP adderss.
#      foldername     - Folder Name.
#
# Results:
#      Returns "SUCCESS", if datacenter created
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub AddFolder
{
   my $self         = shift;
   my $foldername   = shift; # mandatory
   my $vc           = $self->{vcaddr};

   if (not defined $vc) {
      $vdLogger->Error("VC IP not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $foldername) {
      $vdLogger->Error("Folder name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $folderPyObj = $self->GetInlineFolderObject($foldername);
   my $result = CallMethodWithKWArgs($folderPyObj, 'create', {});
   if (defined $result && $result eq FAILURE){
       $vdLogger->Error("Failed to create Folder ($foldername) on ".
                        "VC $vc");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
   $vdLogger->Info("New Folder ($foldername) created on VC $vc");
   return SUCCESS;
}


###############################################################################
#
# RemoveFolder --
#      This method remove a specified generic folder on VC server.
#
# Input:
#      vc             - VC IP adderss.
#      foldername     - Folder Name.
#
# Results:
#      Returns "SUCCESS", if datacenter created
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub RemoveFolder
{
   my $self         = shift;
   my $foldername   = shift; # mandatory
   my $vc           = $self->{vcaddr};

   if (not defined $foldername) {
      $vdLogger->Error("Folder name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $folderPyObj = $self->GetInlineFolderObject($foldername);
   my $result = CallMethodWithKWArgs($folderPyObj, 'delete', {});
   if (defined $result && $result eq FAILURE){
       $vdLogger->Error("Could not remove Folder ($foldername) from ".
                        "VC $vc");
       VDSetLastError(VDGetLastError());
       return FAILURE;
   }
   $vdLogger->Info("Specified Folder ($foldername) removed from VC $vc");
   return SUCCESS;
}


###############################################################################
#
# CreateVDS --
#      This method add a new VDS on VC server.
#
# Input:
#      dcname         - Datacenter Name.
#      vdsname        - VDS Name
#      netAdapters    - reference to array of netadapter objs
#                       (These are free nics netadapter objs)
#      hostObjs       - reference to array of hostObj(if VDS without uplink)
#
# Results:
#      Returns "SUCCESS", if datacenter created
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub CreateVDS
{
   my $self         = shift;
   my $dcname       = shift; # mandatory
   my $vdsname      = shift; # mandatory
   my $netObjs      = shift;
   my $hostObjs     = shift;
   my $proxy        = $self->{proxy};
   my $result;
   my $command;

   if (not defined $dcname) {
      $vdLogger->Error("Datacenter name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $vdsname) {
      $vdLogger->Error("VDS name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # create a stand alone VDS On VC.
   $result = $self->CreateVDSOnVC($dcname, $vdsname);
   if ($result eq FAILURE) {
      $vdLogger->Error("Failed to create VDS On VC");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Info("New VDS ($vdsname) was created under DC ($dcname).");

   # Add specified uplink to VDS
   if (not defined $netObjs ) {
      foreach my $hostObj (@$hostObjs) {
         my $tmpip = $hostObj->{hostIP};
         $vdLogger->Info("Add ESX host ($tmpip) to VDS ($vdsname) without an uplink.");
         $command = " addhosttodvs  anchor ".$self->{hostAnchor}. " dvsname \"".$vdsname.
                 "\" host ".$tmpip." dcname \"".$dcname."\" nopnics ";
         $vdLogger->Info("STAF command: $command");
         $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
         if ($result->{rc} != 0) {
            $vdLogger->Error("Fail to add ESX host ($tmpip) ".
                           "to vds($vdsname):" . Dumper($result));
            VDSetLastError("ESTAF");
            return FAILURE;
         }
      }
   } else {
      foreach my $netObj (@$netObjs) {
         my $vmnic  = $netObj->{interface};
         my $hostIP = $netObj->{hostObj}->{hostIP};
         my $driver = $netObj->{driver} || undef;
         $vdLogger->Info("Add pNIC($vmnic) on ESX host ($hostIP) ".
                        "into  VDS ($vdsname)");
         $command = " addhosttodvs  anchor ".$self->{hostAnchor}. " dvsname \"".$vdsname.
                         "\" host ".$hostIP." dcname \"".$dcname."\" pnics ".
                         $vmnic;
         $vdLogger->Info("STAF command: $command");
         $result = $self->{stafHelper}->
                        STAFSubmitHostCommand($proxy,$command);
         if ($result->{rc} != 0) {
            $vdLogger->Error("Fail to add pnic($vmnic) ".
                             "into vds($vdsname):" . Dumper($result));
            VDSetLastError("ESTAF");
            return FAILURE;
         }
      }
   }
   $vdLogger->Info("Sleep 2 seconds, waiting for VC sync up...");
   sleep 2;
   return SUCCESS;
}


###############################################################################
#
# AddVDS --
#      This method adds a new VDS on VC server using the latest vdnetver2 spec
#
# Input:
#      arrayOfSpecs         - array of vds spec
#
# Results:
#      Returns ref to array of vds object, if vds is created
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub AddVDS
{
   my $self = shift;
   my $arrayOfSpecs = shift;
   my (@arrayOfVDSObjects);
   my $count = "1";

   foreach my $element (@$arrayOfSpecs) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("VDS spec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my %options = %$element;
      my $dcObjects  = $options{datacenter};
      my $dcname     = $dcObjects->{datacentername}; # mandatory
      my $netObjs    = $options{vmnicadapter};
      my $hostObjs   = $options{host};
      my $proxy      = $self->{proxy};
      my $vdsVersion = $self->{version};
      my $vdsname    = $options{name};

      if (not defined $vdsname) {
         $vdsname = VDNetLib::Common::Utilities::GenerateName("vds", $count);
      }

      my $result;
      my $command;

      if (not defined $dcname) {
         $vdLogger->Error("Datacenter name not provided");
         VDSetLastError("EINVALID");
         return FAILURE;
      }

      # create a stand alone VDS On VC.
      $result = $self->CreateVDSOnVC($dcname, $vdsname, $vdsVersion);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to create VDS On VC");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      $vdLogger->Info("New VDS ($vdsname) was created under DC ($dcname).");

      # Add specified uplink to VDS
      if (not defined $netObjs ) {
         foreach my $hostObj (@$hostObjs) {
            my $tmpip = $hostObj->{hostIP};
            $vdLogger->Info("Add ESX host ($tmpip) to VDS ($vdsname) without an uplink.");
            $command = " addhosttodvs  anchor ".$self->{hostAnchor}. " dvsname \"".$vdsname.
                    "\" host ".$tmpip." dcname \"".$dcname."\" nopnics ";
            $vdLogger->Debug("Running staf to add uplink command: $command");
            $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
            if ($result->{rc} != 0) {
               $vdLogger->Error("Fail to add ESX host ($tmpip) ".
                              "to vds($vdsname):" . Dumper($result));
               VDSetLastError("ESTAF");
               return FAILURE;
            }
         }
      } else {
         foreach my $netObj (@$netObjs) {
            my $vmnic  = $netObj->{interface};
            my $hostIP = $netObj->{hostObj}->{hostIP};
            my $driver = $netObj->{driver} || undef;
            $vdLogger->Info("Add pNIC($vmnic) on ESX host ($hostIP) ".
                           "into  VDS ($vdsname)");
            $command = " addhosttodvs  anchor ".$self->{hostAnchor}. " dvsname \"".$vdsname.
                            "\" host ".$hostIP." dcname \"".$dcname."\" pnics ".
                            $vmnic;
            $vdLogger->Debug("STAF command: $command");
            $result = $self->{stafHelper}->
                           STAFSubmitHostCommand($proxy,$command);
            if ($result->{rc} != 0) {
               $vdLogger->Error("Fail to add pnic($vmnic) ".
                                "into vds($vdsname):" . Dumper($result));
               VDSetLastError("ESTAF");
               return FAILURE;
            }
         }
      }
       my $vdsObj = VDNetLib::Switch::Switch->new('switch'     => $vdsname,
                                                  'switchType' => "vdswitch",
                                                  'datacenter' => $dcname,
                                                  'vcObj'      => $self,
                                                  'stafHelper' => $self->{stafHelper});
      if ($vdsObj eq FAILURE) {
         $vdLogger->Error("Failed to create VDSwitch object for $vdsname: ".
                          Dumper(%options));
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      push @arrayOfVDSObjects, $vdsObj;
      $vdLogger->Info("Sleep 2 seconds, waiting for VC sync up...");
      sleep 2;
      $count++;
   }
   return \@arrayOfVDSObjects;
}


###############################################################################
#
# CreateVDSOnVC --
#      This method add a new VDS on VC server.
#
# Input:
#      dcname         - Datacenter Name.
#      vdsname        - VDS Name
#
# Results:
#      Returns "SUCCESS", if vds gets created in vc.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub CreateVDSOnVC
{
   my $self = shift;
   my $dcname = shift;
   my $vdsname = shift;
   my $version = shift;
   my $inlineFolder = $self->GetInlineFolder();
   my $result;
   my $inlineVCSession = $self->GetInlineVCSession();
   if (!$inlineVCSession) {
      $vdLogger->Error("Failed to create VDNetLib::InlineJava::SessionManager " .
                       "object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   $result = $inlineVCSession->LoginVC();
   if (!$result) {
      $vdLogger->Error("Failed to login VC $self->{vcaddr}");
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   if ($version) {
      $result = $inlineFolder->CreateDistributedVirtualSwitch(
         dvsName    => $vdsname,
         datacenter => $dcname,
         version    => $version);
   } else {
      $result = $inlineFolder->CreateDistributedVirtualSwitch(
         dvsName    => $vdsname,
         datacenter => $dcname);
   }

   if ($result == FALSE) {
      $vdLogger->Error("Fail to create VDS ($vdsname) under DC ($dcname).");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   $vdLogger->Info("New VDS ($vdsname) was created under DC ($dcname).");
   return SUCCESS;
}

###############################################################################
#
# DCExists --
#      This method checks whether datacenter exists on vc or not.
#
# Input:
#      dcname         - Datacenter Name,
#
# Results:
#      Returns "SUCCESS", if datacenter exists.
#      Returns "FAILURE", in case datacenter doesn't exists.
#
# Side effects:
#      None.
#
###############################################################################

sub DCExists
{
   my $self = shift;
   my $dcname = shift;
   my $proxy = $self->{proxy};
   my $vc = $self->{vcaddr};
   my $expectedRC = 8000;
   my $match = "Datacenter found";
   my $command;
   my $result;

   # command to create vds
   $command = " dcexists $dcname anchor  $self->{setupAnchor}";
   $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy,$command,
                                                         $expectedRC);
   if ($result->{rc} != 0 && $result->{rc} == $expectedRC) {
      return FAILURE;
   } else {
      if (defined $result->{result}) {
         if ($result->{result} =~ m/$match/i) {
            return SUCCESS;
         }
      }
   }
   return FAILURE;
}


###########################################################################
# VDSExists --
#      This method checks whether the VDS Exists in VC or not.
#
# Input:
#      vdsname         - VDS Name
#      dcname          - dcname
#
# Results:
#      Returns "SUCCESS", if vds exists on vc.
#      Returns "FAILURE", in case vds doesn't exists.
#
# Side effects:
#      None.
#
###############################################################################

sub VDSExists
{
   my $self = shift;
   my $vdsname = shift;
   my $dcname = shift;
   my $proxy = $self->{proxy};
   my $vc = $self->{vcaddr};
   my $expectedRC = 8013; # it's ok if it doesn't find vds.
   my $command;
   my $result;

   # command to list the dvs.
   $command = " listdvs anchor  $self->{setupAnchor} datacenter $dcname devicename $vdsname ";
   $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy,
                                                         $command,
                                                         $expectedRC
                                                         );
   if ($result->{rc} != 0 && $result->{rc} == $expectedRC) {
      # vds doesn't exist, return FAILURE
      return FAILURE;
   } elsif ((defined $result->{result}) &&
            ($result->{result}[0]->{'DVS Name'} =~ m/$vdsname/i)) {
      return SUCCESS;
   } else {
      return FAILURE;
   }
}


###############################################################################
#
# SetupVC --
#      This method would do all the required setup for vds on the vc, it will
#      do the create datacenter, add host, and creation of vds. This method
#      is called from the Testbed during initialization.
#
# Input:
#      folder           - Name of the folder
#      datacenter       - Name of the datacenter
#      hostObjs         - reference to array of hostObj
#      VDSName          - VDS name
#      Version          - VDS version
#
# Results:
#    Returns SUCCESS if creation of datacenter and vds is successfull.
#
# Side effects:
#      None.
#
###############################################################################

sub SetupVC
{
   my $self       = shift;
   my $folder     = shift;
   my $datacenter = shift;
   my $hostObjs   = shift;
   my $vds        = shift;
   my $version    = shift;
   my $tag        = "VCOperation : SetupVC : ";
   my $hostFolder = "/"."$folder"."/"."$datacenter";
   my $result;

   # check the values.
   if(not defined $folder) {
      $vdLogger->Error("$tag name of the folder not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $datacenter) {
      $vdLogger->Error("$tag name of the datacenter not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $hostObjs) {
      $vdLogger->Error("$tag list of esx hosts to be added is not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $vds) {
      $vdLogger->Error("$tag name of the vds not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # first, connect to vc with the username and password
   $result = $self->ConnectVC();
   if ($result eq FAILURE) {
      $vdLogger->Error("$tag Connection to VC Failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # check if datacenter already exists, if yes return success.
   $result = $self->DCExists($hostFolder);
   if ($result eq SUCCESS) {
      $vdLogger->Debug("$tag The datacenter already exists");
      # check if VDS alredy exists, if not create it.
      $result = $self->VDSExists($vds, $datacenter);
      if ($result eq FAILURE) {
         # create a VDS.
         $result = $self->CreateVDSOnVC($datacenter, $vds, $version);
         if ($result eq FAILURE) {
            $vdLogger->Error("$tag Failed to create VDS");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
      }
      if (not defined $self->{datacenter}) {
         $self->{datacenter} = $datacenter;
      }
      return SUCCESS;
   }

   #create a folder.
   $result = $self->AddFolder($folder);
   if ($result eq FAILURE) {
      $vdLogger->Error("$tag Failed to create the folder");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # create a datacenter and add hosts to it.
   $hostFolder = "/".$folder."/".$datacenter;
   $vdLogger->Debug("hostObj = " . Dumper($hostObjs));
   $result = $self->CreateDCWithHosts($hostFolder,
                                      $hostObjs);
   if ($result eq FAILURE) {
      $vdLogger->Error("$tag Failed to create datacenter");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # create a VDS.
   $result = $self->CreateVDSOnVC($datacenter, $vds, $version);
   if ($result eq FAILURE) {
      $vdLogger->Error("$tag Failed to create VDS");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   if (not defined $self->{datacenter}) {
      $self->{datacenter} = $datacenter;
   }

   $vdLogger->Info("$tag VC Setup is successfull");
}

###############################################################################
#
# CleanupVC --
#      This method would do all the required cleanup on the vc, it will
#      remove the datacenter and remove the floders. This method
#      is called from the Testbed during cleanup.
#
# Input:
#      datacenter       - Name of the datacenter.
#      folder           - Name of the folder.
#
#
# Results:
#    Returns SUCCESS if removal of datacenter and folder is successfull.
#
# Side effects:
#      None.
#
###############################################################################

sub CleanupVC
{
   my $self = shift;
   my $datacenter = shift;
   my $folder = shift;
   my $tag = "VCOperation : CleanupVC : ";
   my $dcName = "/".$folder."/".$datacenter;
   my $result;

   $result = $self->RemoveDC($dcName);
   if ($result eq FAILURE) {
      $vdLogger->Error("$tag Failed to remove the datacenter");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $result = $self->RemoveFolder($folder);
   if ($result eq FAILURE) {
      $vdLogger->Error("$tag Failed to remove the folder");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Info("$tag Cleanup VC Successfull");
   return SUCCESS;
}


###############################################################################
#
# AddHostToVDS--
#      This method would add esx host to the VDS.
#
# Input:
#      datacenter       - Name of the datacenter
#      host             - Name of the host.
#      VDSName          - VDS name.
#      PNICS            - List of the pnics.
#
#
# Results:
#    Returns SUCCESS if adding host to vds is successfull.
#
# Side effects:
#      None.
#
###############################################################################

sub AddHostToVDS
{
   my $self = shift;
   my $dcname = shift;
   my $host = shift;
   my $vdsname = shift;
   my $pnics = shift;
   my $version = shift;
   my $tag = "VCOperation : AddHostToVDS : ";
   my $proxy = $self->{proxy};
   my $vc = $self->{vcaddr};
   my $command;
   my $result;

   # check the values passed.
   if (not defined $dcname) {
      $vdLogger->Error("$tag Name of the datacenter not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $host) {
      $vdLogger->Error("$tag Name of the host to be added not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $vdsname) {
      $vdLogger->Error("$tag VDS Name not defined");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # check if VDS alredy exists, if not create it.
   $result = $self->VDSExists($vdsname, $dcname);
   if ($result eq FAILURE) {
      $result = $self->CreateVDSOnVC($dcname, $vdsname, $version);
      if ($result eq FAILURE) {
         $vdLogger->Error("$tag failed to create vds on VC");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
   }

   # command to add host to vds.
   $command = " addhosttodvs anchor ".$self->{hostAnchor}. " host ".$host. " dvsname ".$vdsname;
   if (not defined $pnics) {
      $command = " $command nopnics MAXPROXYSWITCHPORTS 128 ";
   } else {
      $command = " $command pnics $pnics MAXPROXYSWITCHPORTS 128 ";
   }
   $command = " $command dcname $dcname ";
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to add host to vds failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Host ($host) added to ($vdsname) in DC ($dcname).");
   return SUCCESS;
}


###############################################################################
#
# getNRPUplinks --
#      This method get pNICs which are used by VDS on ESX host.
#
# Input:
#      VDSName          - VDS name
#      host             - ESX host IP adderss.
#
#
# Results:
#      Returns "@uplinks,SUCCESS,$found",
#                 @uplinks  -  the array of all the pnics used by this VDS
#                 SUCCESS   -  Success to run this command.
#                 $found    -  whether found uplinks on this VDS
#
# Side effects:
#      None.
#
###############################################################################

sub getNRPUplinks
{
   my $self      = shift;
   my $vdsname   = shift;
   my $host      = shift;
   my $proxy     = $self->{proxy};
   my $vc        = $self->{vcaddr};
   my $found     = "false";
   my @uplinks;
   my @tmp;
   my $waittime = 10;
   # Get the VDS's pNICs on specified ESX host.
   my $cmd;
   my $ret;
   my $echo;
   $cmd = "esxcfg-vswitch -l";
   $ret = $self->{stafHelper}->STAFSyncProcess($host,$cmd,$waittime);
   $echo = $ret ->{stdout};
   if ($ret->{rc} != 0) {
      $vdLogger->Error("Failed to execute $cmd on $host");
      VDSetLastError(VDGetLastError());
      return (@uplinks,FAILURE,$found);
   }
   # Get all uplinks
   @tmp = split /\n/, $echo;
   $vdLogger->Debug("VDS($vdsname) info".Dumper($echo));
   foreach my $line (@tmp) {
      if ($line =~ m/.*$vdsname.*\d+\s+(vmnic.*)/){
         $vdLogger->Debug("uplink info".Dumper($1));
         @tmp = split /,/, $1;
         foreach my $line (@tmp){
            if ($line =~ m/.*(vmnic\d+).*/i){
               push(@uplinks, $1);
               $vdLogger->Info("VDS($vdsname) use uplinks ($1) on ESX host($host)");
               $found = "true";
            }
         }
      }
   }
   return (\@uplinks,SUCCESS,$found);
}

###############################################################################
#
# CheckPools --
#      This method will check vsi nodes that NetIORM resource pools
#      are configured in the given host.
#
# Input:
#      host             - ESX host IP adderss.
#
# Results:
#      Returns "SUCCESS",
#               - For System NRP, 8 resource pools should exist there.
#               - For User-defined NRP, if exist option is "yes",
#                 then will check whether NRP existed. if exist option is "no"
#                 then will check whether the NRP has been removed.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub CheckPools
{
   my $self     = shift;
   my $host     = shift;
   my $nrpname  = shift;
   my $exist    = shift;
   my $found    = "no";
   my $ret;
   my $echo;
   my $cmd;
   my @tmp;
   my @leaf = ();
   my %pools = ();
   my $waittime = 10;
   my @poolarray = ("netsched.pools.persist.vm",
                    "netsched.pools.persist.vmotion",
                    "netsched.pools.persist.iscsi",
                    "netsched.pools.persist.nfs",
                    "netsched.pools.persist.ft",
                    "netsched.pools.persist.mgmt",
                    "netsched.pools.persist.default",
                    "netsched.pools.persist.hol",
                    "netsched.pools.persist.hbr");

   if (not defined $host) {
      $vdLogger->Error("Must specify a ESX host for resource pool check");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # Sleep 3 seconds for VC sync up status with ESX host.
   sleep 3;
   # For MN.Next, system pools and user defined pools are separated:
   # System pools can be found under:
   # /net/netsched/respools/persistent/tags
   # User defined pools can be found as below:
   # /net/netsched/respools/DvsPortset-1/tags
   # /net/netsched/respools/DvsPortset-2/tags
   # List VSI node dir for both system pools and user defined pools
   # Get all VSISH NODES under /net/netsched/respools
   $echo = VDNetLib::Common::Utilities::VsiNodeWalker($host, '/net/sched/pools',
      \@leaf, $self->{stafHelper});
   unless(defined $echo){
      $vdLogger->Error("Failed to get all vsi nodes under " .
      "/net/sched/pools on $host");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   # Get all pool IDs and their VSI NODE for future use
   foreach my $node (@leaf){
       $cmd = "vsish -pe get $node";
       $ret = $self->{stafHelper}->STAFSyncProcess($host, $cmd, $waittime);
       $echo = VDNetLib::Common::Utilities::ProcessVSISHOutput(
           RESULT => $ret->{stdout});
       if($ret->{rc} != 0){
          $vdLogger->Error("Failed to execute $cmd on $host");
          VDSetLastError(VDGetLastError());
          return FAILURE;
       }
       $pools{$echo->{id}} = $node;
       $vdLogger->Info("Found pool $echo->{id} at $node");
   }

   # Check pool ID
   if (!defined $nrpname) {
      # Check system pools
      $vdLogger->Info("Begin to check system resource pool on $host.");
      foreach my $id (@poolarray) {
         unless (exists $pools{$id}) {
            $vdLogger->Error("Cannot find pool $id");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
      }
   } else {
      # Check User-defined pool
      $vdLogger->Info("Begin to check user-defined resource pool on $host.");
      my @allpoolid = keys (%pools);
      foreach my $id (@allpoolid) {
         if ($id =~ /.*$nrpname.*/){
            $vdLogger->Info("User-defined pool has been found: $id");
            $found = "yes";
            last;
         }
      }
   }
   if (defined $nrpname and $exist eq "yes"){
      if ( $found eq "no" ){
         $vdLogger->Error("The NRP didn't be added.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } elsif (defined $nrpname and $exist eq "no"){
      if ($found eq "yes"){
         $vdLogger->Error("The NRP didn't be removed.");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   return SUCCESS;
}


###############################################################################
#
# AddNRP --
#      This method will add a user-defined NRP (network resource pool).
#
# Input:
#      VDS name             -   VDS name
#      NRP name             -   network resource pool name
#      Limit                -   TX output limitation (optional)
#      Tag                  -   802.1p tag, 0-7
#      Share                -   Shares levels for Resource Pool
#      NRP number           -   The number of NRP you want to create
#
# Results:
#      Returns "SUCCESS", if add a new network resource pool
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub AddNRP
{
   my $self      = shift;
   my $vdsname   = shift;
   my $nrpname   = shift;
   my $limit     = shift;
   my $tag       = shift;
   my $share     = shift;
   my $nrpnumber = shift;

   my $proxy   = $self->{proxy};
   my $vc           = $self->{vcaddr};
   my $command;
   my $result;
   # staf command to create a user-defined resource pool.

   $nrpnumber = (defined $nrpnumber) ? $nrpnumber : 1;
   for (my $index=1; $index<=$nrpnumber; $index++) {
      my $tmpname = ($nrpnumber == 1) ? $nrpname : ($nrpname . $index);
      $command = " ADDNETWORKRESPOOL ANCHOR ".$self->{setupAnchor}." DVSNAME \"".$vdsname.
                 "\" NETWORKRSPOOL \"".$tmpname."\"";
      if (defined $limit) {
         $command = $command . " limit $limit ";
      }
      if (defined $tag){
         $command = $command . " PRIORITYTAG $tag ";
      }
      if (defined $share){
         if ($share =~ m/normal|high|low/i){
            $command = $command . " SHARESLEVEL $share";
         } elsif ($share =~ m/(\d+)/){
            $command = $command . " SHARES $1 SHARESLEVEL custom";
         } else {
            $vdLogger->Error("NRP: share value error -- $share");
            VDSetLastError("ESTAF");
            return FAILURE;
         }
      }
      $vdLogger->Info("Run STAF command :$command");
      $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy,$command);
      if ($result->{rc} != 0) {
         $vdLogger->Error("Fail to add new user-defined network resource pool:" .
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $vdLogger->Info("User-defined network resource pool ($tmpname)".
                   " was added on VDS ($vdsname)");
   }
   return SUCCESS;
}


###############################################################################
#
# UpdateNRP --
#      This method will update a user-defined NRP (network resource pool) with
#      new config value.
#
# Input:
#      VDS name             -   VDS name
#      NRP name             -   network resource pool name
#      Limit                -   TX output limitation (optional)
#      Tag                  -   802.1p tag, 0-7
#      Share                -   Shares levels for Resource Pool
#
# Results:
#      Returns "SUCCESS", if add a new network resource pool
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub UpdateNRP
{
   my $self      = shift;
   my $vdsname   = shift;
   my $nrpname   = shift;
   my $limit     = shift;
   my $tag       = shift;
   my $share     = shift;

   my $proxy   = $self->{proxy};
   my $vc           = $self->{vcaddr};
   my $command;
   my $result;
   # staf command to update a user-defined resource pool.
   $command = " UPDATENETWORKIORM ANCHOR ".$self->{setupAnchor}." DVSNAME \"".$vdsname.
              "\" NETWORKRSPOOL \"".$nrpname."\"";
   if (defined $limit) {
      $command = $command . " limit $limit ";
   }
   if (defined $tag){
      $command = $command . " PRIORITYTAG $tag ";
   }
   if (defined $share){
      if ($share =~ m/normal|high|low/i){
         $command = $command . "SHARESLEVEL $share";
      } elsif ($share =~ m/(\d+)/){
         $command = $command . "SHARES $1 SHARESLEVEL custom";
      } else {
         $vdLogger->Error("NRP: share value error -- $share");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   $vdLogger->Info("Run STAF command :$command");
   $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Fail to add new user-defined network resource pool:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("User-defined network resource pool ($nrpname)".
                   " was added on VDS ($vdsname)");
   return SUCCESS;
}

###############################################################################
#
# DelNRP --
#      This method will delete a user-defined NRP (network resource pool).
#
# Input:
#      VDS name             -   VDS name
#      NRP name             -   network resource pool name
#
# Results:
#      Returns "SUCCESS", if delete a new network resource pool
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub DelNRP
{
   my $self      = shift;
   my $vdsname   = shift;
   my $nrpname   = shift;
   my $proxy   = $self->{proxy};
   my $vc           = $self->{vcaddr};
   my $command;
   my $result;
   # staf command to create a user-defined resource pool.
   $command = " REMOVENETWORKRESPOOL ANCHOR ".$self->{setupAnchor}." DVSNAME \"".$vdsname.
              "\" NETWORKRSPOOL \"".$nrpname."\"";
   $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Fail to delete user-defined network resource pool:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("User-defined network resource pool ($nrpname)".
                   " was deleted on VDS ($vdsname)");
   return SUCCESS;

}


###############################################################################
#
# DelSystemNRP --
#      This method will delete a system NRP (network resource pool).
#      It is a negative test case, expect STAF RC is 8073
#
# Input:
#      VDS name             -   VDS name
#
# Results:
#      Returns "SUCCESS", if got the RC 8073.
#      Returns "FAILURE", if got the system NRP was deleted.
#
# Side effects:
#      None.
#
###############################################################################

sub DelSystemNRP
{
   my $self      = shift;
   my $vdsname   = shift;
   my $proxy     = $self->{proxy};
   my $vc        = $self->{vcaddr};
   my @expectedRC1 = (8069,8073);
   my @pools = ("FT Traffic",
                "HBR Traffic",
                "iSCSI Traffic",
                "Management Traffic",
                "NFS Traffic",
                "Virtual Machine Traffic",
                "vMotion Traffic");
   my $command;
   my $result;
   foreach my $pool (@pools) {
      # staf command to delete a system resource pool.
      $command = " REMOVENETWORKRESPOOL ANCHOR ".$self->{setupAnchor}." DVSNAME \"".$vdsname.
              "\" NETWORKRSPOOL \"".$pool."\"";
      $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy,$command);
      if ($result->{rc} == 0) {
         $vdLogger->Error("Fail to test delete system network resource pool:" .
                       Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $vdLogger->Info("System network resource pool ($pool)".
                   " wasn't deleted on VDS ($vdsname)");
   }
   return SUCCESS;
}


###############################################################################
#
# ResetNetIORMCounter --
#      This method will use vsish node to reset the uplink's counter.
#
# Input:
#      VDS name             -   VDS name
#      Host name            -   ESX host name
#
# Results:
#      Returns "SUCCESS", if all the uplink counter reset.
#      Returns "FAILURE", any uplink counter is larger than threshold.
#
# Side effects:
#      None.
#
###############################################################################

sub ResetNetIORMCounter
{
   my $self      = shift;
   my $vdsname   = shift;
   my $host      = shift;
   my $check     = shift;
   my $proxy     = $self->{proxy};
   my $vc        = $self->{vcaddr};
   my @uplinks;
   my @pools;
   my @tmp;
   my $OutPackets;
   my $found     = "false";
   my $threshold = 30; # some packets will be sent out after reset,like ARP.
   my $waittime = 10;
   # Get the VDS's pNICs on specified ESX host.
   my $cmd;
   my $ret;
   my $arrayref;
   my $echo;

   # Get all uplinks
   ($arrayref,$ret,$found) = $self->getNRPUplinks($vdsname,$host);
   @uplinks = @$arrayref;
   if ($ret eq FAILURE) {
      $vdLogger->Error("Failed to find uplinks on $host");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if ($found eq "false"){
      $vdLogger->Warn("VDS($vdsname) didn't have uplinks..");
      return SUCCESS;
   }
   my $nrphash = $self->getNRPHash($vdsname, $host, \@uplinks);
      if ((not defined $nrphash) || ($nrphash eq FAILURE)) {
         $vdLogger->Error("Can't get NRP hash, failed");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }

   $vdLogger->Debug("List of hash" . Dumper($nrphash->{vc}));
   foreach my $uplink (@uplinks){
      # Reset Counter
      $ret = $self->resetNRPCounter($host,$uplink);
      if ($ret eq FAILURE) {
         $vdLogger->Error("Failed to execute $cmd on $host");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      if (defined $check){
         my @pools = split(/,/, $check);
         # Get pool number and counter value, check.
         $vdLogger->Info("List of pools" . Dumper(@pools));
         foreach my $nrp (@pools) {
            #Get counter
            $nrp  = $nrphash->{vc}->{$nrp}->{poolId};
            $OutPackets = $self->GetNRPTXBytes($host, $uplink, $nrp);
            if (defined $OutPackets and $OutPackets < $threshold){
                $vdLogger->Info("ESX host($host) Pool $nrp TX".
                        " counter has been reset to $OutPackets");
            } else {
               $vdLogger->Error("Failed to get out packets number");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
         }
      }
   }
   return SUCCESS;
}


###############################################################################
#
# resetNRPCounter --
#      This method will reset NetIORM counter in vsish.
#
# Input:
#      Host                -    host name,like "SUT/helper1/helper2",
#      Uplink              -    uplink name, like "vmnic1/vmnic2"
#
# Results:
#      Returns "SUCCESS", if success.
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub resetNRPCounter
{
   my $self      = shift;
   my $host      = shift;
   my $uplink    = shift;
   my $proxy     = $self->{proxy};
   my $vc        = $self->{vcaddr};
   my $cmd;
   my $waittime = 10;
   my $ret;

   $cmd = "vsish -e set /vmkModules/netsched/mclk/devs/$uplink/cmd reset-stats";
   $vdLogger->Info("Reset NetIOROM Counter on $uplink ...");
   $vdLogger->Info("Run command : $cmd");
   $ret = $self->{stafHelper}->STAFSyncProcess($host,$cmd,$waittime);
   if ($ret->{rc} != 0) {
      $vdLogger->Error("Failed to execute $cmd on $host");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


###############################################################################
#
# GetNRPTXBytes --
#      This method will get uplink tx bytes number in vsish.
#
# Input:
#      Host                -    host name,like "SUT/helper1/helper2",
#      Uplink              -    uplink name, like "vmnic1/vmnic2"
#      PoolNum             -    pool number
#
# Results:
#      Returns TX bytes number, if success.
#      Returns undef, if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub GetNRPTXBytes
{
   my $self      = shift;
   my $host      = shift;
   my $uplink    = shift;
   my $poolnum   = shift;
   my $proxy     = $self->{proxy};
   my $vc        = $self->{vcaddr};
   my $cmd;
   my $waittime = 10;
   my $ret;
   my $echo;
   my $OutPackets = undef;
   $cmd = "vsish -e get /vmkModules/netsched/mclk/devs/$uplink/qleaves/" .
          "$poolnum/info";
   $vdLogger->Info("Run command : $cmd on $host");
   $ret = $self->{stafHelper}->STAFSyncProcess($host,$cmd,$waittime);
   $echo = $ret ->{stdout};
   if ($ret->{rc} != 0) {
      $vdLogger->Error("Failed to execute $cmd on $host");
      VDSetLastError(VDGetLastError());
      return undef;
   }
   $vdLogger->Debug("Get $host uplink($uplink) pool".
                    "($poolnum) TX info : Dumper($echo)");
   # nBytesOut:0
   my @tmp = split /\n/, $echo;
   foreach my $line (@tmp){
      if ($line =~ m/.*bytesOut:(\d+).*/i){
         $OutPackets = $1;
         last;
      }
   }
   return $OutPackets;
}

###############################################################################
#
# RemoveHostFromVDS --
#      This method will remove hosts from VDS
#
# Input:
#      VDS name             -   VDS name
#      hostObjs             -   reference to array of hostObj
#
# Results:
#      Returns "SUCCESS", if removed.
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub RemoveHostFromVDS
{
   my $self         = shift;
   my $vdsname      = shift; # mandatory
   my $hostObjs     = shift; # mandatory
   my $proxy        = $self->{proxy};
   my $cmd;
   my $result;


   if (not defined $vdsname) {
      $vdLogger->Error("VDS name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $hostObjs) {
      $vdLogger->Error("Host object not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   foreach my $hostObj (@$hostObjs) {
      my $tmpip = $hostObj->{hostIP};
      $vdLogger->Info("Begin to remove host($tmpip) from VDS($vdsname)..");
      $cmd = " RMHOSTFROMDVS anchor ".$self->{hostAnchor}." HOST ".$tmpip.
             " DVSNAME \"".$vdsname."\"";
      $vdLogger->Info("Run command : $cmd");
      $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$cmd);
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failure to remove host($tmpip) from ".
                          "VDS ($vdsname)" . Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   return SUCCESS;
}



###############################################################################
#
# RemoveHostFromDC --
#      This method will remove hosts from DC
#
# Input:
#      hostObjs         - reference to array of hostObj
#
# Results:
#      Returns "SUCCESS", if removed.
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub RemoveHostFromDC
{
   my $self         = shift;
   my $hostObjs     = shift; # mandatory
   my $proxy        = $self->{proxy};
   my $cmd;
   my $result;

   if (not defined $hostObjs) {
      $vdLogger->Error("host object hash not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   foreach my $hostObj (@$hostObjs) {
      my $tmpip = $hostObj->{hostIP};
      $vdLogger->Info("Begin to remove host($tmpip) from DC..");
      $cmd = " HOSTREMOVE anchor ".$self->{hostAnchor}." HOST ".$tmpip;
      $vdLogger->Info("Run command : $cmd");
      $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$cmd);
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failure to remove host($tmpip) from ".
                          "DC " . Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   return SUCCESS;
}


###############################################################################
#
# NetIORMVerify --
#      This method will verify uplinks's TX throughput ratio and limitation.
#
# Input:
#      Host                 -   host name
#      VDSName              -   VDS name
#
# Results:
#      Returns "SUCCESS", if the ratio and limit value is around the
#      pre-defined parameters.
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub NetIORMVerify
{
   my $self       = shift;
   my $vdsname    = shift;
   my $host       = shift;
   my $sharecheck = shift;
   my $limitcheck = shift;
   my $limitduration = shift;
   my $optout        = shift;
   my $lbt           = shift;
   my $rotate        = shift;
   my $precedence    = shift;
   my $map8021p      = shift;
   my $proxy      = $self->{proxy};
   my $vc         = $self->{vcaddr};
   my $found      = "false";
   my @uplinks;
   my $nrphash;
   my @temp;
   my @tmphosts;
   my @hostip;
   my @nrps;
   my $node;
   my $cmd;
   my $arrayref;
   my $ret;
   my $result;
   # For share verification, the result is not accurate enough.
   my $offset = 0.5;
   my $limitoffset = 50;
   my $mintx  = 100;

   if (not defined $host) {
      $vdLogger->Error("ESX host not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $vdsname) {
      $vdLogger->Error("VDS not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   # Get VDS's uplink on ESX host
   ($arrayref,$ret,$found) = $self->getNRPUplinks($vdsname,$host);
   @uplinks = @$arrayref;
   if ($ret eq FAILURE) {
      $vdLogger->Error("Failed to find uplinks on $host");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if ($found eq "false"){
      $vdLogger->Warn("VDS($vdsname) didn't have uplinks..");
      return SUCCESS;
   }
   # Get nrp hash
   # If optout is enabled, below if block can be skipped directly since the verification
   # of optout does not need to use nrphash at all, furthermore, below block will fail if
   # optout is enabled.
   if(scalar @uplinks and not defined $optout){
      $nrphash = $self->getNRPHash($vdsname,$host, \@uplinks);
      if ((not defined $nrphash) || ($nrphash eq FAILURE)) {
         $vdLogger->Error("Can't get NRP hash, failed");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }
   # check 802.1p mapping
   if (defined $map8021p){
      $cmd = "cat  /var/log/vmkernel.log  | grep priority| grep $map8021p";
      # Submit STAF command
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to execute $cmd on $host".Dumper($result));
         VDSetLastError(VDGetLastError());
         return "FAILURE";
      }
      my $output = $result ->{stdout};
      @temp = split(/(\n)/, $output);
      $vdLogger->Debug("LinNet info :".Dumper($output));
      for $node (@temp){
         $vdLogger->Debug("Link Net info : $node");
         if ($node =~ m/vlan/g ){
            $vdLogger->Info("802.1p tags are inserted into the header ...");
            return SUCCESS;
         }
      }
   }
   # check precedence behavior ( vmknic connect to other nrp )
   if (defined $precedence){
      my $vmotionpool = $nrphash->{vc}->{vmotion}->{poolId};
      my $nrppool     = $nrphash->{vc}->{$precedence}->{poolId};
      foreach my $tmpuplink (@uplinks){
         my $vmotiontx = $self->GetNRPTXBytes($host, $tmpuplink, $vmotionpool);
         my $nrptx = $self->GetNRPTXBytes($host, $tmpuplink, $nrppool);
         if ($nrptx > $vmotiontx){
            $vdLogger->Info("Precedence verify success, the vMotion ".
                        "pool tx is $vmotiontx,$precedence tx is $nrptx");
            return SUCCESS;
         }
      }
      $vdLogger->Error("Traffic go through vMotion pool,failed.");
      return FAILURE;
   }
   # check MultipleInterfaceLBT behavior (loadbalance based on load).
   if (defined $lbt) {
      my $used_pnic = 0;
      $vdLogger->Info("LBT Checking NRP: $lbt");
      foreach my $tmpuplink (@uplinks){
         my $tmppool = $nrphash->{vc}->{$lbt}->{poolId};
         my $tmptx = $self->GetNRPTXBytes($host, $tmpuplink, $tmppool);
         $vdLogger->Info("$host: uplink ($tmpuplink), "
                        ."pool($tmppool),TX number is $tmptx.");
         if ($tmptx > $mintx){
            $used_pnic = $used_pnic +1;
         }
      }
      if ($used_pnic > 1){
        $vdLogger->Info("Traffic balance to $used_pnic pNICs.");
        return SUCCESS;
      } else {
        $vdLogger->Error("Traffic didn't balance to other pNICs.");
        return FAILURE;
      }
   }
   # check the optout behavior.
   if (defined $optout) {
      $vdLogger->Info("OptOut Checking uplinks: $uplinks[0]");
      my $tmpuplink = $uplinks[0];

      #
      # In MN, if optout is enabled on a vmnic, its VSI node still can be
      # found under /vmkModules/netsched/mclk/devs/ , but tx will be zero
      # in /vmkModules/netsched/mclk/devs/vmnicX/qleaves/$poolNum/info;
      # Since MN.Next, once optout is enabled on a vmnic, the vmnic will
      # disappear from dir /vmkModules/netsched/mclk/devs
      #
      $cmd = "vsish -pe dir /vmkModules/netsched/mclk/devs/";
      $vdLogger->Debug("Run command : $cmd on $host");
      $ret = $self->{stafHelper}->STAFSyncProcess($host,$cmd);
      if ($ret->{rc} != 0 or $ret->{exitCode} != 0) {
         $vdLogger->Error("Failed to execute $cmd on $host");
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $result = $ret->{stdout};
      my @tmp = split /\n/, $result;
      foreach my $line (@tmp){
         if ($line =~ m/$tmpuplink/i){
            $vdLogger->Error("Fail the Opt out verification.");
            VDSetLastError("EOPFAILED");
         }
      }
      $vdLogger->Info("Pass the Opt out verification.");
      return SUCCESS;
   }
   # check the limit bandwidth.
   if (defined $limitcheck) {
      if (!defined $limitduration) {
         $vdLogger->Error("Test duration isn't provided.");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }
      $vdLogger->Info("Checking uplinks: Dumper(@uplinks)");
      foreach my $tmpuplink (@uplinks){
         my $txpackets = 0;
         my $tmppool = $nrphash->{vc}->{$limitcheck}->{poolId};
         my $tmptx = $self->GetNRPTXBytes($host, $tmpuplink, $tmppool);
         $vdLogger->Info("$host: uplink ($tmpuplink), "
                        ."pool($tmppool),TX number is $tmptx.");
         my $throughput = ($tmptx * 8/1048576)/$limitduration;
         my $definelimit = $nrphash->{vc}->{$limitcheck}->{'RESOURCEPOOL LIMIT'};
         $vdLogger->Info("$host: uplink ($tmpuplink), "
                        ."pool($tmppool), real throughput is $throughput Mb/s."
                        .",defined is $definelimit Mb/s");
         if ((int($throughput) - $limitoffset) > $definelimit){
             $vdLogger->Error("Fail to check limit value");
             VDSetLastError("EOPFAILED");
             return FAILURE;
         }
      }
      $vdLogger->Info("Pass the limit verification.");
      return SUCCESS;
   }

   # check the share ratio
   my $rotetetime = 0;
   my $tmp;
   my @rotates = ();
   if (defined $sharecheck) {
      if (defined $rotate) {
         @rotates = split(/,/,$rotate);
      }
ROTATEONFAIL:
      @nrps = split(/,/,$sharecheck);
      my @sharevalue;
      my @txpacket;
      $vdLogger->Info("Checking uplinks: Dumper(@uplinks)");
      foreach my $tmpuplink (@uplinks){
         @txpacket = ();
         foreach my $tmpnrp (@nrps){
            my $tmppool = $nrphash->{vc}->{$tmpnrp}->{poolId};
            my $tmptx = $self->GetNRPTXBytes($host, $tmpuplink, $tmppool);
            $vdLogger->Info("$host: uplink ($tmpuplink), "
                        ."pool($tmppool),TX number is $tmptx.");
            push(@sharevalue,$nrphash->{vc}->{$tmpnrp}->{'RESOURCEPOOL SHARES VALUE'});
            push(@txpacket,$tmptx);
         }
         #Only compare 2 NRPs.
         my $shareratio = 0;
         my $txratio    = 0;
         if ($sharevalue[0] > $sharevalue[1]){
            if ($txpacket[1] < $mintx){
               $vdLogger->Info("Search next uplink($txpacket[1]) ... ");
               next;
            }
            if ( $txpacket[0] < $mintx ){
               $vdLogger->Info(" Search next uplink(denominator is 0 ) ... ");
               next;
            }
            $shareratio = $sharevalue[1]/$sharevalue[0];
            $txratio = $txpacket[1]/$txpacket[0];
         } else {
            if ($txpacket[0] < $mintx){
               $vdLogger->Info("Search next uplink($txpacket[0]) ... ");
               next;
            }
            if ( $txpacket[1] < $mintx ){
               $vdLogger->Info(" Search next uplink(denominator is 0) ... ");
               next;
            }
            $shareratio = $sharevalue[0]/$sharevalue[1];
            $txratio = $txpacket[0]/$txpacket[1];
         }
         $vdLogger->Info("Defined share ratio is $shareratio");
         $vdLogger->Info("TX packets ratio is $txratio");
         if ( abs($shareratio-$txratio) < $offset){
            $vdLogger->Info("Pass the share verification.");
            return SUCCESS;
         }
      }
      if (defined $rotate) {
         $tmp = $rotates[$rotetetime];
         $rotetetime = $rotetetime +1;
         $vdLogger->Debug("Rotate array is".Dumper(@rotates)."current is".$rotetetime);
         if (!defined $tmp){
            $vdLogger->Error("After rotation, still failed... ");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
         my @actions = split(/:/,$tmp);
         foreach my $act (@actions){
            $vdLogger->Info("Running IPC workload : $act");
            $vdLogger->Debug("Action array is".Dumper(@actions));;
         }
         goto ROTATEONFAIL;
      }
   }
   # Reach here means failed.
   $vdLogger->Error("Fail to check limit and share option.");
   VDSetLastError("EOPFAILED");
   return FAILURE;
}

###############################################################################
#
# getNRPHash --
#      This method will return a hash variable which contain all the NRPs' info
#
# Input:
#      VDSName              -   VDS name
#      Host                 -   host name
#      Uplink               -   VDS uplink
#
# Results:
#      Returns a hash variable, if success.
#      Returns udnef, if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub getNRPHash
{
   my $self      = shift;
   my $vdsname   = shift;
   my $host      = shift;
   my $uplink    = shift;
   my $proxy     = $self->{proxy};
   my $vc        = $self->{vcaddr};

   my $info;
   my $cmd;
   my $result;
   my @tmp;
   my @leaf = ();
   my @vcpools;
   my @esxpools;
   my $nrphash;
   my $waittime = 10;

   # command to list all the NRPs from VC side.
   $cmd = " LISTNETWORKRSPOOLINFO anchor $self->{setupAnchor} dvsname $vdsname ";
   $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy,$cmd);
   $vdLogger->Info("Run STAF command: $cmd.");
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to list NRPs failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return undef;
   }
   @vcpools = @{$result->{result}};
   $vdLogger->Debug("NRP info from VC :".Dumper($result->{result}));

   # Get all VSISH NODES under /net/sched/pools
   $result = VDNetLib::Common::Utilities::VsiNodeWalker($host, '/net/sched/pools',
      \@leaf, $self->{stafHelper});
   unless(defined $result){
      $vdLogger->Error("Failed to get all vsi nodes under " .
      "/net/sched/pools on $host");
      VDSetLastError(VDGetLastError());
      return undef;
   }
   foreach my $node (@leaf){
      $cmd = "vsish -pe get $node";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd, $waittime);
      if($result->{rc} != 0){
         $vdLogger->Error("Failed to execute $cmd on $host");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $info = VDNetLib::Common::Utilities::ProcessVSISHOutput(
         RESULT => $result->{stdout});
      $nrphash->{esx}->{$info->{id}} = $node;
      $vdLogger->Info("Found pool $info->{id} at $node with tag $info->{dpTag}");
   }

   # For MN.Next, resources pools at VC side are reorged as below:
   # /net/netsched/respools/persistent/tags/0 - 8: system predefined pools
   # /net/netsched/respools/persistent/tags/9 - N: user defined pools
   # For user defined pools, pool num from below two places are different:
   # /net/netsched/respools/<user defined pools group name>/tags
   # /vmkModules/netsched/sfq/devs/vmnic2/pools/
   # To deal with above changes, script need to read the info value for a pool
   # to decide the pool num, below is a example:
   # get /vmkModules/netsched/sfq/devs/vmnic2/pools/9/info
   # sfq pool info {
   #   poolId:NRP_22573_dvs-15
   #   shares:50
   #   ...
   # }
   # The corresponding vsi node is:
   # /net/netsched/respools/DvsPortset-0/tags/> get 73
   # netsched resource pool {
   #   pool id:NRP_22573_dvs-15
   #   packet tag:73
   #   ...
   # }
   # Build a hash for user defined pools
   my %udPools = ();

   #
   # To find user pools we need to discover how many system pools are defined.
   # Users pools start from system pool+1
   #
   my $userPool = $self->GetNumSystemPools($host);
   if ($userPool eq FAILURE) {
      VDSetLastError("EFAILED");
      return undef;
   }
   $userPool = int($userPool) + 1;
      $cmd = "vsish -pe get " .
             "/vmkModules/netsched/mclk/".
             "devs/" . $uplink->[0] . "/qleaves";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd, $waittime);
      if($result->{rc} != 0){
         $vdLogger->Error("Failed to execute $cmd on $host");
         VDSetLastError(VDGetLastError());
         return undef;
      }
      my $poolsList = $result->{stdout};
      my @tempArray = split(/\n/, $poolsList);

      foreach my $pool (@tempArray) {
         if ($pool =~ /persist/i) {
            next;
         } else {
            $cmd = $cmd . "/$pool/info";
            $result = $self->{stafHelper}->STAFSyncProcess($host,
                                                           $cmd,
                                                           $waittime);
            if($result->{rc} != 0){
               $vdLogger->Error("Failed to execute $cmd on $host");
               VDSetLastError(VDGetLastError());
               return undef;
            }
            if ($result->{stdout} =~ /:Get failed:/i ||
                $result->{stderr} =~ /:Get failed:/i){
               $vdLogger->Error("$cmd failed on $host :" . Dumper($result));
               VDSetLastError("EFAILED");
               return undef;
            }

            $info = VDNetLib::Common::Utilities::ProcessVSISHOutput(
                                                   RESULT => $result->{stdout}
                                                   );
            if (not defined $info->{poolId}) {
               $vdLogger->Error("Failed to get poolID from:" . Dumper($result));
               VDSetLastError("EFAILED");
               return undef;
            }
            $udPools{$info->{poolId}} = $userPool;
         }
      }

   $vdLogger->Debug("Userdefined pools and their tags under " .
                    "/vmkModules/netsched/sfq/devs/vmnicN/pools:" .
                    Dumper(%udPools));

   # VC side and ESX side pool name doesn't match, correct in this loop.
   # FT Traffic              => netsched.pools.persist.ft => '6'
   # iSCSI Traffic           => netsched.pools.persist.iscsi => '4'
   # HBR Traffic             => netsched.pools.persist.hbr => '8'
   # vMotion Traffic         => netsched.pools.persist.vmotion => '3'
   # Management Traffic      => netsched.pools.persist.mgmt => '7'
   # NFS Traffic             => netsched.pools.persist.nfs => '5'
   # Virtual Machine Traffic => netsched.pools.persist.vm => '2'
   # Build %{$nrphash->{VC}}
   foreach my $item (@vcpools){
      if ($item->{'NAME'} =~ m/Fault Tolerance/){
         $nrphash->{vc}->{ft} = $item;
         $nrphash->{vc}->{ft}->{poolId}= "netsched.pools.persist.ft";
      }elsif($item->{'NAME'} =~ m/iSCSI Traffic/){
         $nrphash->{vc}->{iscsi} = $item;
         $nrphash->{vc}->{iscsi}->{poolId}= "netsched.pools.persist.iscsi";
      }elsif($item->{'NAME'} =~ m/vSphere Replication/){
         $nrphash->{vc}->{hbr} = $item;
         $nrphash->{vc}->{hbr}->{poolId}= "netsched.pools.persist.hbr";
      }elsif($item->{'NAME'} =~ m/vMotion Traffic/){
         $nrphash->{vc}->{vmotion} = $item;
         $nrphash->{vc}->{vmotion}->{poolId}= "netsched.pools.persist.vmotion";
      }elsif($item->{'NAME'} =~ m/Management Traffic/){
         $nrphash->{vc}->{mgmt} = $item;
         $nrphash->{vc}->{mgmt}->{poolId}= "netsched.pools.persist.mgmt";
      }elsif($item->{'NAME'} =~ m/NFS Traffic/){
         $nrphash->{vc}->{nfs} = $item;
         $nrphash->{vc}->{nfs}->{poolId}= "netsched.pools.persist.nfs";
      }elsif($item->{'NAME'} =~ m/Virtual Machine Traffic/){
         $nrphash->{vc}->{vm} = $item;
         $nrphash->{vc}->{vm}->{poolId}= "netsched.pools.persist.vm";
      }else{
         $nrphash->{vc}->{$item->{'NAME'}} = $item;
         $nrphash->{vc}->{$item->{'NAME'}}->{poolId} =
            $item->{'RESOURCEPOOL KEY'};
      }
   }
   $vdLogger->Debug("NRP info from ESX host side :".Dumper($nrphash));
   return $nrphash;
}


###############################################################################
#
# OptOut --
#      This method will opt out one uplink from NRP or vice versa.
#
# Input:
#      Host                 -   host name
#      VDSName              -   VDS name
#      Value                -   0 means opt out, 1 means add into NRP
#
# Results:
#      Returns "SUCCESS", if operation success
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub OptOut
{
   my $self       = shift;
   my $vdsname    = shift;
   my $host       = shift;
   my $value      = shift;
   my $proxy      = $self->{proxy};
   my $vc         = $self->{vcaddr};
   my $waittime   = 10;
   my $arrayref;
   my $ret;
   my $found;
   my @pnics;
   my $result;
   if (not defined $host) {
      $vdLogger->Error("ESX host not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $vdsname) {
      $vdLogger->Error("VDS not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $value) {
      $vdLogger->Error("Opt out value not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   # Get vds uplinks.
   ($arrayref,$ret,$found) = $self->getNRPUplinks($vdsname,$host);
   @pnics = @$arrayref;
   if ($ret eq FAILURE) {
      $vdLogger->Error("Failed to find uplinks on $host");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if ($found eq "false"){
      $vdLogger->Error("VDS($vdsname) didn't have uplinks..");
      return FAILURE;
   }
   # Only use one uplink $pnics[0]
   my $cmd = "vsish -e set  /net/pNics/$pnics[0]/sched/allowResPoolsSched $value";
   $result = $self->{stafHelper}->STAFSyncProcess($host,$cmd,$waittime);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to execute $cmd on $host");
      VDSetLastError(VDGetLastError());
      return FAILURE;;
   }
   $vdLogger->Info("Optout operation on $pnics[0] with $cmd");
   return SUCCESS;
}

###############################################################################
#
# CreateChfInstanec --
#      This method create a new Chf instance for VDS on VC server.
#
# Input:
#      vdsName        - VDS Name
#
# Results:
#      Returns "SUCCESS", if datacenter created
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################
sub CreateChfInstance
{
   my $self         = shift;
   my $vdsName      = shift; # mandatory
   my $vc           = $self->{vcaddr};
   my $vcUser      = $self->{user};
   my $vcPasswd       = $self->{passwd};
  my $cfgToolsDir  = $self->{globalConfig}->GetVDL2ConfigToolPath();

   if (not defined $vdsName) {
      $vdLogger->Error("VDS name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # command to create chf instance
   my $command = "java -jar $cfgToolsDir/lib/vdl2.jar -H $vc -s " .
       "-d $vdsName -u $vcUser -p \'$vcPasswd\'";
   $vdLogger->Info(" STAF command to call java program : command=$command \n");
   my $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);

   if ($result->{stdout} =~ /success/i ){
      return SUCCESS;
   }else{
      $vdLogger->Error("STAF command to call java program failed: dvSwitch is not exist or CHF instance has already exist. command=$command \n" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   sleep 1; # waiting for VC sync up...
   $command = "java -jar $cfgToolsDir/lib/vdl2.jar -H $vc -l " .
         "-d $vdsName -u $vcUser -p \'$vcPasswd\'";
   $vdLogger->Info(" STAF command to call java program : command=$command \n");
   $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);
   if ($result->{stdout} =~ m/instance/i) {
      return SUCCESS;
   }else{
      $vdLogger->Error("STAF command to call java program failed: command=$command \n" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
}

###############################################################################
#
# RemoveChfInstanec --
#      This method remove a new Chf instance for VDS on VC server.
#
# Input:
#      vdsName        - VDS Name
#
# Results:
#      Returns "SUCCESS", if datacenter created
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub RemoveChfInstance
{
   my $self         = shift;
   my $vdsName      = shift; # mandatory
   my $vc           = $self->{vcaddr};
   my $vcUser      = $self->{user};
   my $vcPasswd       = $self->{passwd};
   my $cfgToolsDir  = $self->{globalConfig}->GetVDL2ConfigToolPath();

   if (not defined $vdsName) {
      $vdLogger->Error("VDS name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # command to create chf instance
   my $command = "java -jar $cfgToolsDir/lib/vdl2.jar -H $vc -c " .
                 "-d $vdsName -u $vcUser -p \'$vcPasswd\'";
   $vdLogger->Info(" STAF command to call java program : command=$command \n");
   my $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);

   if ($result->{stdout} =~ /success/i ){
      return SUCCESS;
   }else{
      $vdLogger->Error("STAF command to call java program failed: command=$command \n" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   sleep 1; # waiting for VC sync up...
   $command = "java -jar $cfgToolsDir/lib/vdl2.jar -H $vc -l " .
              "-d $vdsName -u $vcUser -p \'$vcPasswd\'";
   $vdLogger->Info(" STAF command to call java program : command=$command \n");
   $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);
   if ($result->{stdout} =~ m/instance/i) {
      $vdLogger->Error("STAF command to call java program failed: command=$command \n" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }else{
      return SUCCESS;
   }
}

###############################################################################
#
# AddFenceId --
#      This method add a new Fence Id from VDS on VC server.
#
# Input:
#      vdsName        - VDS Name
#      portGroupName  - VDS Portgroup Name
#      fenceId        - Fence ID
#
# Results:
#      Returns "SUCCESS", if datacenter created
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################
sub AddFenceId
{
   my $self           = shift;
   my $vdsName        = shift; # mandatory
   my $portGroupName  = shift; # mandatory
   my $fenceId        = shift; # mandatory
   my $vc             = $self->{vcaddr};
   my $vcUser        = $self->{user};
   my $vcPasswd         = $self->{passwd};
   my $cfgToolsDir    = $self->{globalConfig}->GetVDL2ConfigToolPath();

   if (not defined $vdsName) {
      $vdLogger->Error("VDS name is not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $portGroupName) {
      $vdLogger->Error("Portgroup name is not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $fenceId) {
      $vdLogger->Error("Fence id is not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # command to add fence id
   my $command = "java -jar $cfgToolsDir/lib/vdl2.jar -H $vc -s -g $portGroupName -f $fenceId " .
                 "-d $vdsName -u $vcUser -p \'$vcPasswd\'";
   $vdLogger->Info(" STAF command to call java program : command=$command \n");
   my $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);

   if ($result->{stdout} =~ /success/i ){
      # Get expect result
   }else{
      $vdLogger->Error(" STAF command to call java program failed: command=$command \n" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   sleep 1; # waiting for VC sync up...
   $command = "java -jar $cfgToolsDir/lib/vdl2.jar -H $vc -l -g $portGroupName " .
              "-d $vdsName -u $vcUser -p \'$vcPasswd\'";
   $vdLogger->Info(" STAF command to call java program : command=$command \n");
   $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);
   if ($result->{stdout} =~ m/id:$fenceId/i) {
      return SUCCESS;
   }else{
      $vdLogger->Error("STAF command to call java program failed: command=$command \n" .
                        Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
}

###############################################################################
#
# DeleteFenceId --
#      This method delete Fence Id from VDS on VC server.
#
# Input:
#      vdsName        - VDS Name
#      portGroupName  - VDS Portgroup Name
#
# Results:
#      Returns "SUCCESS", if datacenter created
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################
sub DeleteFenceId
{
   my $self           = shift;
   my $vdsName        = shift; # mandatory
   my $portGroupName  = shift; # mandatory
   my $vc             = $self->{vcaddr};
   my $vcUser        = $self->{user};
   my $vcPasswd         = $self->{passwd};
   my $cfgToolsDir    = $self->{globalConfig}->GetVDL2ConfigToolPath();

   if (not defined $vdsName) {
      $vdLogger->Error("VDS name is not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $portGroupName) {
      $vdLogger->Error("Portgroup name is not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # command to delete fence id
   my $command = "java -jar $cfgToolsDir/lib/vdl2.jar -H $vc -g $portGroupName -c " .
                 "-d $vdsName -u $vcUser -p \'$vcPasswd\'";
   $vdLogger->Debug("STAF command to call java program : command=$command \n");
   my $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);
   if ($result->{stdout} =~ /success/i ){
      # Get expect result
   }else{
      $vdLogger->Error("STAF command to call java program failed: command=$command \n" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   sleep 1; # waiting for VC sync up...
   $command = "java -jar $cfgToolsDir/lib/vdl2.jar -H $vc -l -g $portGroupName " .
              "-d $vdsName -u $vcUser -p \'$vcPasswd\'";
   $vdLogger->Debug("STAF command to call java program : command=$command \n");
   $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);
   if ($result->{stdout} =~ m/id:/i) {
      $vdLogger->Error("STAF command to call java program failed: command=$command \n" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }else{
      return SUCCESS;
   }
}

###############################################################################
#
# ChangeFenceId --
#      Change Fence Id on VDS + portgroup on VC server.
#
# Input:
#      vdsName        - VDS Name
#      portGroupName  - VDS Portgroup Name
#      changeTimes    - change times
#
# Results:
#      Returns "SUCCESS", if datacenter created
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################
sub ChangeFenceId
{
   my $self           = shift;
   my $vdsName        = shift; # mandatory
   my $portGroupName  = shift; # mandatory
   my $changeTimes    = shift; # mandatory
   my $vc             = $self->{vcaddr};
   my $vcUser        = $self->{user};
   my $vcPasswd         = $self->{passwd};
   my $cfgToolsDir    = $self->{globalConfig}->GetVDL2ConfigToolPath();
   my $i = 0;
   my $j = 0;
   my $command = "";
   my $result = "";

   if (not defined $vdsName) {
      $vdLogger->Error("VDS name is not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $portGroupName) {
      $vdLogger->Error("Portgroup name is not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $changeTimes) {
      $vdLogger->Error("changeTimes is not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # fence id is an integer multiple of 256.
   for($i=1; $i <= $changeTimes ; $i++){
      $j = $i*256;
      $vdLogger->Debug(" \$i=$i, \$j=$j; \$changeTimes=$changeTimes ");
      # set fence id command
      $command = "java -jar $cfgToolsDir/lib/vdl2.jar -H $vc -s -g $portGroupName -f $j " .
                 "-d $vdsName -u $vcUser -p \'$vcPasswd\'";
      $vdLogger->Debug("STAF command to call java program : command=$command \n");
      $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);

      if ($result->{stdout} =~ /success/i ){
         # Get expect result
      }else{
         $vdLogger->Error("STAF command to call java program failed: command=$command \n" .
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      # Note: It will take at least 20 seconds running fence.jar
   }

}

###############################################################################
#
# EnableBC --
#      This method is to enable broadcast containment on a vds portgroup for
#      fence network.
#
# Input:
#      vdsName        - VDS Name
#      portGroupName  - VDS Portgroup Name
#
# Results:
#      Returns "SUCCESS", if datacenter created
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################
sub EnableBC
{
   my $self           = shift;
   my $vdsName        = shift; # mandatory
   my $portGroupName  = shift; # mandatory
   my $vc             = $self->{vcaddr};
   my $vcUser        = $self->{user};
   my $vcPasswd         = $self->{passwd};
   my $cfgToolsDir    = $self->{globalConfig}->GetVDL2ConfigToolPath();

   if (not defined $vdsName) {
      $vdLogger->Error("VDS name is not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $portGroupName) {
      $vdLogger->Error("Portgroup name is not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # command to enable broadcast containment
   my $command = "java -jar $cfgToolsDir/lib/vdl2.jar -H $vc -s -g $portGroupName " .
                 "-d $vdsName -u $vcUser -p \'$vcPasswd\'";
   $vdLogger->Debug("STAF command to call java program : command=$command \n");
   my $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);

   if ($result->{stdout} =~ /success/i ){
      # Get expect result
   }else{
      $vdLogger->Error("STAF command to call java program failed: command=$command \n" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   sleep 1; # waiting for VC sync up...
   $command = "java -jar $cfgToolsDir/lib/vdl2.jar -H $vc -l -g $portGroupName " .
                 "-d $vdsName -u $vcUser -p \'$vcPasswd\'";
   $vdLogger->Debug("STAF command to call java program : command=$command \n");
   $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);
   if ($result->{stdout} =~ m/bcast enabled:true/i) {
      return SUCCESS;
   }else{
      $vdLogger->Error("STAF command to call java program failed: command=$command , \n" .
                        Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
}

###############################################################################
#
# DisableBC --
#      This method is to disable broadcast containment on a vds portgroup for
#      fence network.
#
# Input:
#      vdsName        - VDS Name
#      portGroupName  - VDS Portgroup Name
#
# Results:
#      Returns "SUCCESS", if datacenter created
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub DisableBC
{
   my $self           = shift;
   my $vdsName        = shift; # mandatory
   my $portGroupName  = shift; # mandatory
   my $vc             = $self->{vcaddr};
   my $vcUser        = $self->{user};
   my $vcPasswd         = $self->{passwd};
   my $cfgToolsDir    = $self->{globalConfig}->GetVDL2ConfigToolPath();

   if (not defined $vdsName) {
      $vdLogger->Error("VDS name is not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $portGroupName) {
      $vdLogger->Error("Portgroup name is not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   # command to disable broadcast containment
   my $command = "java -jar $cfgToolsDir/lib/vdl2.jar -H $vc -s -b -g $portGroupName " .
                 "-d $vdsName -u $vcUser -p \'$vcPasswd\'";
   $vdLogger->Debug("STAF command to call java program : command=$command \n");
   my $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);

   if ($result->{stdout} =~ /success/i ){
      # Get expect result
   }else{
      $vdLogger->Error("STAF command to call java program failed: cmd=$command \n" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   sleep 1; # waiting for VC sync up...
   $command = "java -jar $cfgToolsDir/lib/vdl2.jar -H $vc -l -g $portGroupName " .
              "-d $vdsName -u $vcUser -p \'$vcPasswd\'";
   $vdLogger->Debug("STAF command to call java program : command=$command \n");
   $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);
   if ($result->{stdout} =~ m/bcast enabled:false/i) {
      return SUCCESS;
   }else{
      $vdLogger->Error("STAF command to call java program failed: cmd=$command \n" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
}

###############################################################################
#
# TSAMPointToPointCheckVDS --
#      This method is used for VXLAN TSAM point to point connection between VDSs.
#
# Input:
#      VdsName1               -   Vds Name 1
#      VdsName2               -   Vds Name 2
#      HostIp1                -   Host1 IP
#      HostIp2                -   Host2 IP
#      VlanId                 -   VLAN ID
#      MtuSize                -   MTU Size
#
# Results:
#      Returns "SUCCESS", if success.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub TSAMPointToPointCheckVDS
{
   my $self           = shift;
   my $args           = shift;
   my $vdsName1       = $args->{vdsName1};
   my $vdsName2       = $args->{vdsName2};
   my $hostIp1        = $args->{hostIp1};
   my $hostIp2        = $args->{hostIp2};
   my $vlanId         = $args->{vlanId};
   my $mtuSize        = $args->{mtuSize};
   my $vc             = $self->{vcaddr};
   my $vcUser        = $self->{user};
   my $vcPasswd         = $self->{passwd};
   my $cfgToolsDir    = $self->{globalConfig}->GetVDL2ConfigToolPath();
   my $command = "";
   my $result = "";

   if ( (not defined $vdsName1) || (not defined $vdsName2) ) {
      $vdLogger->Error("vds name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ( (not defined $hostIp1) || (not defined $hostIp2) ) {
      $vdLogger->Error("Host ip not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $vlanId) {
      $vdLogger->Error("VLAN id not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $mtuSize) {
      $vdLogger->Error("MTU size not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $command = "java -jar $cfgToolsDir/lib/vdl2.jar connCheckP2P ".
                 " $vdsName1 $vlanId $hostIp1 $vdsName2 $vlanId $hostIp2 " .
                 " $mtuSize $vc $vcUser \'$vcPasswd\'";
   $vdLogger->Debug("STAF command to call java program : command=$command \n");
   $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to run command: $command on MC. ".
                       Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   if ( $result->{stdout} !~ /packetLost=0/is ){
      $vdLogger->Debug("STAF command to call java program failed: cmd=$command \n".
      Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

###############################################################################
#
# TSAMPointToPointCheckVDSVmknic --
#      This method is used for VXLAN TSAM point to point connection between VDS with Vmknic.
#
# Input:
#      VdsName1               -   Vds Name 1
#      VdsName2               -   Vds Name 2
#      HostIp1                -   Host1 IP
#      HostIp2                -   Host2 IP
#      VlanId                 -   VLAN ID
#      MtuSize                -   MTU Size
#
# Results:
#      Returns "SUCCESS", if success.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub TSAMPointToPointCheckVDSVmknic
{
   my $self           = shift;
   my $args           = shift;
   my $vdsName1       = $args->{vdsName1};
   my $vdsName2       = $args->{vdsName2};
   my $hostIp1        = $args->{hostIp1};
   my $hostIp2        = $args->{hostIp2};
   my $vlanId         = $args->{vlanId};
   my $mtuSize        = $args->{mtuSize};
   my $vc             = $self->{vcaddr};
   my $vcUser        = $self->{user};
   my $vcPasswd         = $self->{passwd};
   my $cfgToolsDir    = $self->{globalConfig}->GetVDL2ConfigToolPath();
   my $command = "";
   my $result = "";

   if ( (not defined $vdsName1) || (not defined $vdsName2) ) {
      $vdLogger->Error("vds name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ( (not defined $hostIp1) || (not defined $hostIp2) ) {
      $vdLogger->Error("Host ip not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $vlanId) {
      $vdLogger->Error("VLAN id not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $mtuSize) {
      $vdLogger->Error("MTU size not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $vmknicName = VDNetLib::Switch::VDSwitch::VDSwitch::GetVDSVmknicName($self,
                         $hostIp2,$vdsName2,$vlanId);
   if ( $vmknicName eq FAILURE ){
      $vdLogger->Error("Call VDNetLib::Switch::VDSwitch::VDSwitch::".
                         "GetVDSVmknicName return FAILURE. \n".Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   my $vmknicIp = VDNetLib::Switch::VDSwitch::VDSwitch::GetVmknicPort($self,
                         $hostIp2,$vdsName2,$vmknicName);
   if ( $vmknicIp eq FAILURE ){
      $vdLogger->Error("Call VDNetLib::Switch::VDSwitch::VDSwitch::".
         "GetVDSVmknicIp return FAILURE. \n".Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   $command = "java -jar $cfgToolsDir/lib/vdl2.jar connCheckP2P ".
                 " $vdsName1 $vlanId $hostIp1 $vmknicIp " .
                 " $mtuSize $vc $vcUser \'$vcPasswd\'";
   $vdLogger->Debug("STAF command to call java program : command=$command \n");
   $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to run command: $command on MC. ".
                       Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   if ( $result->{stdout} !~ /packetLost=0/is ){
      $vdLogger->Debug("STAF command to call java program failed: cmd=$command \n".
      Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
   return SUCCESS;
}

###############################################################################
#
# VXLANTSAMMulticastDomainCheck --
#      This method is VXLAN TSAM multicast domain check.
#
# Input:
#      vdsName1, vdsName2, vdsName3, hostIp1, hostIp2, multicastIp,expectedstring
#
# Results:
#      Returns "SUCCESS", if success.
#      Returns "FAILURE", in case of any error.
#
# Side effects:
#      None.
#
###############################################################################

sub VXLANTSAMMulticastDomainCheck
{
   my $self           = shift;
   my $args           = shift;
   my $vdsName1       = $args->{vdsName1};
   my $vdsName2       = $args->{vdsName2};
   my $hostIp1        = $args->{hostIp1};
   my $hostIp2        = $args->{hostIp2};
   my $vlanId         = $args->{vlanId};
   my $mtuSize        = $args->{mtuSize};
   my $multicastIp    = $args->{multicastIp};
   my $expectedstring = $args->{expectedstring};
   my $vc             = $self->{vcaddr};
   my $vcUser        = $self->{user};
   my $vcPasswd         = $self->{passwd};
   my $cfgToolsDir    = $self->{globalConfig}->GetVDL2ConfigToolPath();
   my $command = "";
   my $result = "";

   if ( (not defined $vdsName1) || (not defined $vdsName2) ) {
      $vdLogger->Error("vds name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ( (not defined $hostIp1) || (not defined $hostIp2) ) {
      $vdLogger->Error("Host ip not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $vlanId) {
      $vdLogger->Error("Vlan id not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $multicastIp) {
      $vdLogger->Error("Multicast ip not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $expectedstring) {
      $vdLogger->Error("Expect response number is not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $mtuSize) {
      $vdLogger->Error("MTU size not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   # command for running VXLAN TSAM multicast domain check
   # Multicast domain check
   $command = "java -jar $cfgToolsDir/lib/vdl2.jar connCheckMCast ".
                 " $vdsName1 $vlanId $hostIp1 $multicastIp $expectedstring " .
                 " $mtuSize $vc $vcUser \'$vcPasswd\'";
   $vdLogger->Debug("STAF command to call java program : command=$command \n");
   $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to run command: $command on MC. ".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ( $result->{stdout} !~ /Response number: $expectedstring/is ){
      $vdLogger->Error("STAF command to call java program failed: cmd=$command \n" .
      Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   return SUCCESS;
}


###############################################################################
#
# CreateProfile --
#      This method will create a hostprofile
#
# Input:
#  profile           -  (profile | srcprofile | serializedprofile)
#  refSrcHostObj     -  reference to Source Host object (optional)
#  targetprofile     -  hostprofile name (Required)
#  refRefhostObj     -  reference RefHost object(optional)
#  srcprofile        -  Parameter to specify the source profile name(optional)
#  serializedprofile -  Parameter to specify a serialized host profile (.vpf file)
#                                                                     (optional)
# Results:
#      Returns success if create successfully.
#      Returns failure, if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub CreateProfile
{
   my $self               = shift;
   my %args               = @_;
   my $profile            = $args{createprofile}; # mandatory
   my $refSrcHostObj      = $args{srchost};
   my $targetprofile      = $args{targetprofile}; # mandatory
   my $refRefHostObj      = $args{dsthost};
   my $srcprofile         = $args{srcprofile};
   my $serializedprofile  = $args{serializedprofile};
   my $proxy              = $self->{proxy};
   my $result;
   my $command;
   my $refhostip;

   if (not defined $targetprofile) {
      $vdLogger->Error("target profile name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $srcHostObj = $refSrcHostObj->[0];
   my $refHostObj = $refRefHostObj->[0];

   if ((defined $srcHostObj) && ($profile eq "profile")){
      my $srchostip = $srcHostObj->{hostIP};
      if (defined $refHostObj) {
         my $refhostip = $refHostObj->{hostIP};
         $command = " CREATEPROFILE  anchor $self->{hostAnchor} TARGETPROFILE \"$targetprofile\" ".
                      "srchost $srchostip  REFERENCEHOST $refhostip";
      } else {
         $command = " CREATEPROFILE  anchor $self->{hostAnchor} TARGETPROFILE \"$targetprofile\" ".
                   "srchost $srchostip";
      }
   }

   if (defined $refHostObj){
      $refhostip = $refHostObj->{hostIP};
   }
   if ( (defined $srcprofile) && ($profile eq "srcprofile") ) {
      if (not defined $refHostObj) {
         $vdLogger->Error("Reference host is required when SRCPROFILE or SERIALIZEDPROFILE".
                          "parameter is specified");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $command = " CREATEPROFILE  anchor $self->{hostAnchor} TARGETPROFILE \"$targetprofile\" ".
                   "SRCPROFILE \"$srcprofile\"  REFERENCEHOST $refhostip";
   }
   if ( (defined $serializedprofile) &&($profile eq "serializedprofile") ) {
      if (not defined $refHostObj) {
         $vdLogger->Error("Reference host is required when SRCPROFILE or SERIALIZEDPROFILE".
                          "parameter is specified");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
      $command = " CREATEPROFILE  anchor $self->{hostAnchor} TARGETPROFILE \"$targetprofile\" ".
                   "SERIALIZEDPROFILE \"$serializedprofile\"  REFERENCEHOST $refhostip";
   }

   $vdLogger->Debug("STAF command: $command");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Fail to create host profile".  Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Create host profile $targetprofile sucessfully.");
   return SUCCESS;
}


###############################################################################
#
# CheckCompliance --
#      This method will check a hostprofile compliance
#
# Input:
#      refHostObj        -   reference to test hostObj
#      targetprofile     -   hostprofile name
#      expectedstatus    -   expected status
# Results:
#      Returns SUCCESS if check host profile compliance successfully.
#      Returns failure, if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub CheckCompliance
{
   my $self            = shift;
   my $refHostObj      = shift; # mandatory
   my $targetprofile   = shift; # mandatory
   my $expectedstatus  = shift; # mandatory
   my $proxy           = $self->{proxy};
   my $result;
   my $command;

   my $hostObj = $refHostObj->[0];
   if (not defined $hostObj) {
      $vdLogger->Error("source host object not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $targetprofile) {
      $vdLogger->Error("target profile name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined  $expectedstatus) {
      $vdLogger->Error("espected status not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $tmpip = $hostObj->{hostIP};
   $command = " CHECKCOMPLIANCE  anchor $self->{hostAnchor} host $tmpip  ".
                      "PROFILE \"$targetprofile\"";
   $vdLogger->Debug("STAF command: $command");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Fail to check host profile".  Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Debug("Compliance Check $result:\n".  Dumper($result));
   my $status = $result->{result}->{ComplianceStatus};
   if($status  =~ m/$expectedstatus/i ) {
      if ($status eq "nonCompliant") {
         $vdLogger->Info("Compliance Status => ".  $result->{result}->{ComplianceStatus});
         $vdLogger->Info("FailureType => ". $result->{result}->{Failure}->[0]->{FailureType});
         $vdLogger->Info("Message =>". $result->{result}->{Failure}->[0]->{Message}->{Message});
      }
      $vdLogger->Debug("Compliance check passed ". $status . " expected ". $expectedstatus);
      return SUCCESS;
   } else {
      $vdLogger->Debug("Compliance check failed ". $status . " expected ". $expectedstatus);
      return FAILURE;
   }
}


###############################################################################
#
# AssociateProfile --
#      This method will attach a hostprofile to a host
#
# Input:
#      refHostObj        -   reference to test hostObj
#      targetprofile     -   hostprofile name
# Results:
#      Returns success if attach host profile to host successfully.
#      Returns failure, if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub AssociateProfile
{
   my $self            = shift;
   my $refHostObj      = shift; # mandatory
   my $targetprofile   = shift; # mandatory
   my $proxy           = $self->{proxy};
   my $result;
   my $command;

   my $hostObj = $refHostObj->[0];
   if (not defined $hostObj) {
      $vdLogger->Error("source host object not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $targetprofile) {
      $vdLogger->Error("target profile name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $tmpip = $hostObj->{hostIP};

   $command = " ASSOCIATEPROFILE  anchor $self->{hostAnchor} profile \"$targetprofile\" host $tmpip";
   $vdLogger->Debug("STAF command: $command");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Fail to associate host profile".  Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Associate host profile sucessfully.hostprofile name is $targetprofile.");
   return SUCCESS;
}


###############################################################################
#
# DisAssociateClusterProfile --
#      This method will associate/disassociate hostprofile with the cluster
#
# Input:
#      targetprofile     -   hostprofile name
#      clusterPath       -   absolute path to cluster
# Results:
#      Returns success if attach host profile to cluster successfully.
#      Returns failure, if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub DisAssociateClusterProfile
{
   my $self            = shift;
   my $targetprofile   = shift;
   my $clusterpath     = shift;
   my $proxy           = $self->{proxy};
   my $result;
   my $command;

   $command = " DISASSOCIATEPROFILES  anchor $self->{hostAnchor} " .
         " CLUSTERPATH \"$clusterpath\" " .  "PROFILE \"$targetprofile\" ";

   $vdLogger->Debug("STAF command: $command");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Fail to disassociate profile to cluster".
                                                     Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Disassociate profile $targetprofile to cluster.");
   return SUCCESS;
}


###############################################################################
#
# AssociateClusterProfile --
#      This method will associate/disassociate hostprofile with the cluster
#
# Input:
#      targetprofile     -   hostprofile name
#      clusterPath       -   absolute path to cluster
# Results:
#      Returns success if attach host profile to cluster successfully.
#      Returns failure, if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub AssociateClusterProfile
{
   my $self            = shift;
   my $targetprofile   = shift;
   my $clusterpath     = shift;
   my $proxy           = $self->{proxy};
   my $result;
   my $command;

   $command = " ASSOCIATEPROFILE  anchor $self->{hostAnchor} " .
                "PROFILE  \"$targetprofile\" CLUSTERPATH \"$clusterpath\" ";

   $vdLogger->Debug("STAF command: $command");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Fail to associate profile to cluster".
                                                     Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Associate profile $targetprofile to cluster.");
   return SUCCESS;
}


###############################################################################
#
# ClusterProfile --
#      This method will associate/disassociate hostprofile with the cluster
#
# Input:
#      clusterprofile    -   associate/disassocaite
#      clusterPath       -   absolute path to cluster
#      targetprofile     -   hostprofile name
# Results:
#      Returns success if attach host profile to cluster successfully.
#      Returns failure, if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub ClusterProfile
{
   my $self            = shift;
   my %args            = @_;
   my $clusterprofile  = $args{clusterprofile};
   my $clusterpath     = $args{clusterpath};
   my $targetprofile   = $args{targetprofile};
   my $proxy           = $self->{proxy};
   my $result;
   my $command;

   if (not defined $clusterprofile) {
      $vdLogger->Error("cluster type assoicate/disassociate not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $clusterpath) {
      $vdLogger->Error("absolute cluster path not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $targetprofile) {
      $vdLogger->Error("target profile name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if ($clusterprofile eq "associate") {
      $result = $self->AssociateClusterProfile($targetprofile,$clusterpath);
   } elsif ($clusterprofile eq "disassociate") {
      $result = $self->DisAssociateClusterProfile($targetprofile,$clusterpath);
   } else {
      $vdLogger->Error("assoicate/disassociate not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if ($result eq "FAILURE" ) {
      $vdLogger->Error("Fail to $clusterprofile profile to cluster");
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("$clusterprofile profile $targetprofile to cluster.");
   return SUCCESS;
}


###############################################################################
#
# DisAssociateProfiles--
#      This method will detach a hostprofile from a host
#
# Input:
#      refHostObj        -   reference to test hostObj
#      targetprofile     -   hostprofile name
# Results:
#      Returns success if detach host profile to host successfully.
#      Returns failure, if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub DisAssociateProfiles
{
   my $self            = shift;
   my $refHostObj      = shift; # mandatory
   my $targetprofile   = shift; # mandatory
   my $proxy           = $self->{proxy};
   my $result;
   my $command;

   my $hostObj = $refHostObj->[0];
   if (not defined $hostObj) {
      $vdLogger->Error("source host object not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $targetprofile) {
      $vdLogger->Error("target profile name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $tmpip = $hostObj->{hostIP};

   $command = " DISASSOCIATEPROFILES  anchor $self->{hostAnchor} " .
           "profile \"$targetprofile\" host $tmpip";
   $vdLogger->Debug("STAF command: $command");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Fail to disassociate host profile".  Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Successfully disassociated host profile $targetprofile.");
   return SUCCESS;
}


###############################################################################
#
# ApplyProfile --
#      This method will apply a hostprofile to a host
#
# Input:
#      refHostObj        -   reference to test hostObj
#      targetprofile     -   hostprofile name
# Results:
#      Returns success if apply host profile successfully.
#      Returns failure, if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub ApplyProfile
{
   my $self          = shift;
   my $refHostObj    = shift; # mandatory
   my $targetprofile = shift; # mandatory
   my $proxy         = $self->{proxy};
   my $result;
   my $command;

   my $hostObj = $refHostObj->[0];
   if (not defined $hostObj) {
      $vdLogger->Error("source host object not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $targetprofile) {
      $vdLogger->Error("target profile name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $tmpip = $hostObj->{hostIP};
   $command = " APPLYPROFILE  anchor $self->{hostAnchor} host $tmpip profile \"$targetprofile\" ";
   $vdLogger->Debug("STAF command: $command");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Fail to apply host profile".  Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Apply host profile sucessfully.hostprofile name is $targetprofile.");
   return SUCCESS;
}


###############################################################################
#
# DestroyProfile --
#      This method will delete a hostprofile
#
# Input:
#      targetprofile     -   hostprofile name
# Results:
#      Returns success if delete host profile successfully.
#      Returns failure, if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub DestroyProfile
{
   my $self         = shift;
   my $targetprofile= shift; # mandatory
   my $proxy        = $self->{proxy};
   my $vc           = $self->{vcaddr};
   my $result;
   my $command;

   if (not defined $targetprofile) {
      $vdLogger->Error("target profile name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $command = " DESTROYPROFILE  anchor $self->{hostAnchor} profile \"$targetprofile\" ";
   $vdLogger->Debug("STAF command: $command");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Fail to destroy host profile".  Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Destroy host profile sucessfully.hostprofile name is $targetprofile.");
   return SUCCESS;
}


###############################################################################
#
# EditPolicyOpt --
#      This method will edit a network hostprofile policy
#
# Input:
#      applyprofile - NetworkProfile(Fixed for network profile)(required)
#      profile - Parameter to specify the profile name(required)
#      profiledevice - Parameter to specify the device name in the profile(required)
#      profilecategory - Parameter to specify category in the host profile(required)
#      policyid - Parameter to specify the policy id for a profile(required)
#      policyoption - Parameter to specify the policy option for a policy id(required)
#      policyparams - Parameter to specify the parameters of policy option.
#                     This is a comma-separated list of key:value pairs(required)
#      subcategory - Parameter to specify subcategory in the
#                    network profile policies(optional)
# Results:
#      Returns success if edit network host profile policy successfully.
#      Returns failure, if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub EditPolicyOpt
{
   my $self            = shift;
   my $applyprofile    = shift;
   my $profile         = shift;
   my $profiledevice   = shift;
   my $profilecategory = shift;
   my $policyid        = shift;
   my $policyoption    = shift;
   my $policyparams    = shift;
   my $subcategory     = shift;
   my $proxy           = $self->{proxy};
   my $vc              = $self->{vcaddr};
   my $result;
   my $command;

   if (not defined $applyprofile) {
      $vdLogger->Error("apply profile parameter not provided.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $profile) {
      $vdLogger->Error("profile name not provided.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $profiledevice) {
      $vdLogger->Error("profile device not provided.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $profilecategory) {
      $vdLogger->Error("profile category not provided.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $policyid) {
      $vdLogger->Error("policy id not provided.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $policyoption) {
      $vdLogger->Error("policy option not provided.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $policyparams) {
      $vdLogger->Error("policy params not provided.");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $command = " EDITPOLICYOPT anchor $self->{hostAnchor} APPLYPROFILE $applyprofile "
              ." profile \"$profile\" PROFILECATEGORY \"$profilecategory\" "
              ." POLICYID \"$policyid\" POLICYOPTION \"$policyoption\" "
              ."POLICYPARAMS \"$policyparams\" PROFILEDEVICE \"$profiledevice\" ";
   if (defined $subcategory) {
      $command = $command . "SUBCATEGORY \"$subcategory\"";
   }
   $vdLogger->Debug("STAF command: $command");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Fail to edit network host profile policy".  Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Edit network host profile policy sucessfully.hostprofile name is $profile.");
   return SUCCESS;
}


###############################################################################
#
# SetVDSUplink --
#      This method will set all the VDS uplinks attribute in physical switch.
#            - trunk mode, native vlan, allowed vlan
#            - access mode, vlan id.
#
# Input:
#      hostObj      -   reference to test hostObj
#      VDSName      -   VDS Name (optional)
#      PortMode     -   trunk/access
#      vlanid       -   access vlan id (optional)
#      native vlan  -   native vlan id (optional)
#      allowed vlan -   allowed vlan id range (optional)
#
# Results:
#      Returns SUCCESS or FAILURE if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub SetVDSUplink
{
   my $self         = shift;
   my $hostObj      = shift; # mandatory
   my $vdsname      = shift;
   my $portmode     = shift; # mandatory
   my $vlanid       = shift;
   my $nativevlan   = shift;
   my $vlanrange    = shift;
   my $count        = shift;
   my $result       = undef;
   my $arrayref;
   my $ret;
   my $found;
   my @pnics;
   my $switchip;
   my $portnumber;
   my $pswitchObj;

   if (not defined $hostObj) {
      $vdLogger->Error("No ESX host object provide");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $portmode) {
      $vdLogger->Error("The Physical switch port mode no provide");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   # get the VDS uplinks on specified host and each used pnics's CDP info( switch  port ).
   my $tmpip = $hostObj->{hostIP};
   # Get VDS's uplink on ESX host
   if (defined $vdsname){
      # if define vds, get vds uplinks
      ($arrayref,$ret,$found) = $self->getNRPUplinks($vdsname,$tmpip);
      if ($ret eq FAILURE) {
         $vdLogger->Error("Failed to find uplinks on $tmpip");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      if ($found eq "false"){
         $vdLogger->Warn("VDS($vdsname) didn't have uplinks..");
         return SUCCESS;
      }
      @pnics = @$arrayref;
   }else{
      # if not define vds, get host's uplinks except management uplinks on vSwitch0.
      $result = $self-> getTestUplink($tmpip);
      if ( $result eq FAILURE ) {
         return FAILURE;
      } else {
         @pnics = @{$result};
      }
   }
   # set uplink to specified mode,$count mean how many uplink will be set
   if (!defined $count){
      $count = @pnics;
   }
   for my $node (@pnics) {
      if ($count > 0){
         ($switchip,$portnumber) = $self->getUplinkInfo($tmpip,$node);
         if (defined $switchip and defined $portnumber){
            $vdLogger->Info("$node connect to switch($switchip),port$portnumber");
         }else{
            $vdLogger->Error("Failed to find uplink info on host $tmpip.");
            VDSetLastError(VDGetLastError());
            return FAILURE;
         }
         $vdLogger->Info("Connected with physical switch : $switchip .");
         $pswitchObj = VDNetLib::Switch::PSwitch::PSwitch->new(NAME => $switchip,
                        TYPE => $self->{switchtype});
         if ($portmode eq "access"){
            $result = $pswitchObj->{setPortAccessMode}(
                     PORT => $portnumber,SWITCH => $pswitchObj,VLANID =>$vlanid);
            if ($result eq FAILURE) {
               $vdLogger->Error("Failed to set port $portnumber ".
                          "to access mode on switch $switchip");
                VDSetLastError(VDGetLastError());
                return FAILURE;
            }
         }
         if ($portmode eq "trunk"){
            $result = $pswitchObj->{setPortTrunkMode}(PORT => $portnumber,
               SWITCH => $pswitchObj,NATIVEVLAN =>$nativevlan,VLANRANGE =>$vlanrange);
            if ($result eq FAILURE) {
               $vdLogger->Error("Failed to set port $portnumber ".
                          "to trunk mode on switch $switchip");
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }
         }
         $count = $count -1;
      }
   }
   return SUCCESS;
}


################################################################################
# getUplinkInfo --
#      Method to retrieve the physical switch information to which this pnic
#      is connected, It currently uses CDP(Cisco Discovery protocol).
#
# Input:
#    vminic - vminic0 or vmnicX
#    host   - host ip address
#
# Results:
#      (switchip,portnumber) - switch ip address and port number
#      (undef,undef)         - any error occured.
#
# Side effects:
#      none
#
################################################################################

sub getUplinkInfo
{
   my $self = shift;
   my $host = shift;
   my $vmnic = shift;
   my $result;
   my $reg;
   my $cdpInfo;
   my $command;
   my $switch   = undef;
   my $portinfo = undef;

   # command to retrive the port id of the switch.
   $command = "vim-cmd hostsvc/net/query_networkhint --pnic-names=$vmnic";
   # Submit STAF command
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if (defined $result->{stdout}) {
      $cdpInfo = $result->{stdout};
      $vdLogger->Debug("CDP:".Dumper($cdpInfo));
   } else {
      $vdLogger->Debug("no stdout");
      return (undef,undef);
   }
   # first get the switchport.
   $reg = 'portId\s*=\s*.*Ethernet([^"]+)';
   if ($cdpInfo =~ /$reg/i) {
      $portinfo = $1;
   } else {
      $vdLogger->Debug("Failed to get switch port for $vmnic");
      return (undef,undef);
   }
   #
   # Check for the switch Address.
   #
   $reg = 'address\s*=\s*"([^"]+)"';
   if ($cdpInfo =~ /$reg/i) {
      $switch = $1;
   } else {
      $vdLogger->Debug("Failed to get physical switch address for $vmnic");
      return (undef,undef);
   }
   return ($switch,$portinfo);
}


###############################################################################
#
# RemoveVDS --
#      This method will remove VDS
#
# Input:
#      VDS name             -   VDS name
#
# Results:
#      Returns "SUCCESS", if removed.
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub RemoveVDS
{
   my $self         = shift;
   my $vdsname      = shift; # mandatory
   my $proxy        = $self->{proxy};
   my $cmd;
   my $result;


   if (not defined $vdsname) {
      $vdLogger->Error("VDS name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $vdLogger->Info("Begin to remove VDS($vdsname)..");
   $cmd = " RMDVS anchor $self->{setupAnchor}".
          " DVSNAME \"".$vdsname."\"";
   $vdLogger->Debug("Run command : $cmd");
   $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy,$cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failure to remove VDS ($vdsname)".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Remove VDS($vdsname)successfully.");
   return SUCCESS;
}


################################################################################
# getTestUplink --
#      Method to retrieve all the test uplinks on a ESX host
#      except management uplink(s).
#
# Input:
#    host   - host ip address
#
# Results:
#      (@pnic)       - all the vmnic on that ESX host
#      FAILURE       - any error occured.
#
# Side effects:
#      none
#
################################################################################

sub getTestUplink
{
   my $self = shift;
   my $host = shift;
   my $result;
   my $command;
   my $data;
   my @tmp;
   my $node;
   my @allnics;
   my @used;
   my $k;
   my @tmp1;
   my @testpnics;
   my $uplinks = undef;

   # command to retrive the port id of the switch.
   $command = "esxcli network nic list|grep -i vmnic|grep -i up";
   # Submit STAF command
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   $data = $result ->{stdout};
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to execute $command on $host");
      VDSetLastError(VDGetLastError());
      return "FAILURE";
   }
   @tmp = split(/(\n+)/, $data);
   for $node (@tmp){
      if ( $node =~ /^(vmnic\d+).*/ ){
         push(@allnics,$1);
         $vdLogger->Debug("$1 is on the - $host.");
      }
   }
   $command = "esxcli network vswitch standard list";
   # Submit STAF command
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);
   $data = $result ->{stdout};
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to execute $command on $host");
      VDSetLastError(VDGetLastError());
      return "FAILURE";
   }
   # only find vSwitch0 uplinks
   @tmp = split(/(Portgroups)/, $data);
   for $node (@tmp){
      $vdLogger->Debug("vSwith info : $node");
      if ($node =~ m/.*vSwitch0.*/g ){
         @tmp1 = split (/\n/,$node);
         for $k ( @tmp1){
            if ( $k =~ m/Uplinks:\s*(vmnic.*)/){
              $vdLogger->Debug("ESX host $host uses $1 as management uplink.");
              $uplinks = $1;
           }
         }
         if (defined $uplinks){
            @tmp1 = split(/\,/, $uplinks);
         }
         for $k (@tmp1) {
            if ($k =~ /(vmnic\d+)/i){
               push(@used,$1);
               $vdLogger->Debug("$1 is management uplink");
            }
         }
      }
   }
   for $node ( @allnics ){
      if ( ! grep(/^$node$/,@used)){
         push(@testpnics, $node);
         $vdLogger->Debug("$node is testing pnic");
      }
   }
   return \@testpnics;
}


##############################################################################
#
# GetVCBuild --
#      This method gets VC build information from VC server.
#
# Input:
#      None
#
# Results:
#      Returns  VC Build if SUCCESS.
#      Returns  FAILURE, if any error occurred.
#
# Side effects:
#      None.
#
###############################################################################

sub GetVCBuild
{
   my $self = shift;
   my $proxy = $self->{proxy};
   my $command;
   my $result;
   my $buildInfo = undef;

   # first, connect to vc with the username and password
   $result = $self->ConnectVC();
   if ($result eq FAILURE) {
      $vdLogger->Error("Connection to VC Failed");
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }

   # command to get VC Build information
   $command = "getviminfo  anchor  $self->{setupAnchor}";
   $result = $self->{stafHelper}->STAFSubmitSetupCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("STAF command to get vc build info failed:" .
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $hash_ref = $result->{result};
   foreach my $key (keys %$hash_ref) {
     if ($key =~ m/Build/) {
        $buildInfo = $hash_ref->{$key};
        last;
     }
   }
   return $buildInfo;
}

###############################################################################
#
# AddVMKNIC --
#      This method will add a vmknic on specified DVPG
#
# Input:
#      Host                 -   ESX host, like SUT or helper2
#      VDS name             -   VDS name
#      DC name              -   Datacenter name
#      DVPG                 -   DVPG name
#      IPadd                -   IPv4 address for this vmknic
#
# Results:
#      Returns "SUCCESS", if added.
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#      vMotion option will be enabled.
#
###############################################################################

sub AddVMKNIC
{
   my $self         = shift;
   my $host         = shift; # mandatory
   my $vdsname      = shift; # mandatory
   my $dcname       = shift; # mandatory
   my $dvpg         = shift; # mandatory
   my $ipadd        = shift; # mandatory
   my $prefix       = shift;
   my $proxy        = $self->{proxy};
   my $cmd;
   my $data;
   my $vmknicid = undef;
   my $result;
   my @tmp;
   my $node;

   if (not defined $host) {
      $vdLogger->Error("host not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $vdsname) {
      $vdLogger->Error("VDS name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $dcname) {
      $vdLogger->Error("Datacenter not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $dvpg) {
      $vdLogger->Error("DVPG not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $ipadd) {
      $vdLogger->Error("IP address not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   $vdLogger->Info("Begin to add vmknic on VDS($vdsname),DVPG($dvpg)..");
   $cmd = " ADDVMKNICTODVS ANCHOR $self->{setupAnchor} HOST $host ".
          " DVSNAME \"".$vdsname."\" DVPORTGROUPNAME $dvpg IP $ipadd ";
   if (defined $prefix){
      $cmd = $cmd . " PREFIXLEN $prefix ENABLEIPV6";
   }else{
      $cmd = $cmd . " NETMASK $self->{netmask}";
   }
   $vdLogger->Info("Run command : $cmd");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failure to add vmknic".Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   sleep 3; # waiting for data sync up from VC side to ESX host side.
   # Get VNICID like vmk0 or vmk3
   if (defined $prefix){
      $cmd = "esxcli network ip interface ipv6 address list |grep $ipadd";
   }else{
      $cmd = "esxcli network ip interface ipv4 get |grep $ipadd";
   }
   # Submit STAF command
   $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);
   $data = $result ->{stdout};
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to execute $cmd on $host".Dumper($result));
      VDSetLastError(VDGetLastError());
      return "FAILURE";
   }
   @tmp = split(/(\n)/, $data);
   for $node (@tmp){
      $vdLogger->Debug("vmknic info : $node");
      if ($node =~ m/(vmk\d+)\s.*/g ){
         $vmknicid = $1;
      }
   }
   if (!defined $vmknicid) {
      $vdLogger->Error("Failed to get vmknic id.");
      VDSetLastError("ESTAF");
      return "FAILURE";
   }
   # Enable vMotion option.
   $cmd = " VMOTION ANCHOR $self->{setupAnchor} HOST $host ".
          " ENABLE VNICID $vmknicid";
   $vdLogger->Info("Run command : $cmd");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failure to enable vMotion on $vmknicid".Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Add vmknic successfully.");
   return SUCCESS;
}


###############################################################################
#
# RemoveVMKNIC --
#      This method will remove a vmknic with specified IP address.
#
# Input:
#      Host                 -   ESX host, like SUT or helper2
#      IPAdd                -   IPv4 address for this vmknic
#      IPv6Add              -   IPv6 address for this vmknic
#
# Results:
#      Returns "SUCCESS", if removed.
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#
###############################################################################

sub RemoveVMKNIC
{
   my $self         = shift;
   my $host         = shift; # mandatory
   my $ipadd        = shift; # optional
   my $ipv6add      = shift; # optional
   my $proxy        = $self->{proxy};
   my $cmd;
   my $data;
   my $vmknicid = undef;
   my $result;
   my @tmp;
   my $node;

   if (not defined $host) {
      $vdLogger->Error("host not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   # Get VNICID like vmk0 or vmk3
   if (defined $ipadd){
      $cmd = "esxcli network ip interface ipv4 get |grep $ipadd";
      # Submit STAF command
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);
      $data = $result ->{stdout};
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to execute $cmd on $host".Dumper($result));
         VDSetLastError(VDGetLastError());
         return "FAILURE";
      }
      @tmp = split(/(\n)/, $data);
      for $node (@tmp){
         $vdLogger->Debug("vmknic info : $node");
         if ($node =~ m/(vmk\d+)\s.*/g ){
            $vmknicid = $1;
         }
      }
   } elsif (defined $ipv6add) {
      $cmd = "esxcli network ip interface ipv6 address list |grep $ipv6add";
      # Submit STAF command
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);
      $data = $result ->{stdout};
      $vdLogger->Debug("all vmknic info :".Dumper($data));
      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to execute $cmd on $host".Dumper($result));
         VDSetLastError(VDGetLastError());
         return "FAILURE";
      }
      @tmp = split(/(\n)/, $data);
      for $node (@tmp){
         $vdLogger->Debug("vmknic info : $node");
         if ($node =~ m/(vmk\d+)\s.*/g ){
            $vmknicid = $1;
         }
      }
   }
   if (!defined $vmknicid) {
      $vdLogger->Error("Failed to get vmknic id.");
      VDSetLastError("ESTAF");
      return "FAILURE";
   }
   $vdLogger->Info("Begin to remove vmknic - $vmknicid");
   $cmd = " RMVMKNIC ANCHOR $self->{setupAnchor} HOST $host ".
          " DEVICEID $vmknicid";
   $vdLogger->Info("Run command : $cmd");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failure to remove $vmknicid".Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Remove vmknic successfully.");
   return SUCCESS;
}


###############################################################################
#
# SetLinNet --
#      This method will set a vsi node value to enable/disable 802.1p
#      log on ESX host.
#
# Input:
#      Host                 -   ESX host, like SUT or helper2
#      Level                -   log level
#
# Results:
#      Returns "SUCCESS", if success.
#      Returns "FAILURE", if any error occured.
#
# Side effects:
#
###############################################################################

sub SetLinNet
{
   my $self         = shift;
   my $host         = shift; # mandatory
   my $level        = shift; # mandatory
   my $proxy        = $self->{proxy};
   my $cmd;
   my $result;

   if (not defined $host) {
      $vdLogger->Error("host not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $level) {
      # use the default value -> 0
      $level = 2;
   }
   $cmd = "vsish -e set /system/modules/vmklinux_9/loglevels/LinNet $level";
   $vdLogger->Debug("Run command $cmd on host $host");
   $vdLogger->Info("Set VSI node log value to $level on host($host) ...");
   # Submit STAF command
   $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to execute $cmd on $host".Dumper($result));
      VDSetLastError(VDGetLastError());
      return "FAILURE";
   }
   return SUCCESS;
}


###############################################################################
#
# ImportAnswer --
#      This method will import answer file to a host
#
# Input:
#      refHostObj        -   reference to test hostObj
#      answerfile        -   answer file location(on MC)
# Results:
#      Returns success if import answer successfully.
#      Returns failure, if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub ImportAnswer
{
   my $self         = shift;
   my $refHostObj   = shift; # mandatory
   my $answerfile   = shift; # mandatory
   my $proxy        = $self->{proxy};
   my $result;
   my $command;

   my $hostObj = $refHostObj->[0];
   if (not defined $hostObj) {
      $vdLogger->Error("target host not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $hostIp = $hostObj->{hostIP};
   if (not defined $answerfile) {
      $vdLogger->Error("answer file not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $logDir = VDNetLib::Common::GlobalConfig::GetLogsDir();
   my $logFile = $logDir . $answerfile;

   $vdLogger->Debug("logFile: $logDir  $logFile");
   $command = " UPDATEANSWERFILE  anchor $self->{hostAnchor} host $hostIp " .
              " SERIALIZEDANSWERFILE \"$logFile\" ";
   $vdLogger->Debug("STAF command: $command");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Fail to import answer file".  Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Import answer file to $hostIp sucessfully." . "
                        answer file name is $answerfile.");
   return SUCCESS;
}


###############################################################################
#
# UpdateAnswerFile --
#      This method will update host's  answer file to a host
#
# Input:
#      refHostObj        -   reference to test hostObj
#      ANSWERFILEOPTIONS -   as key/value pair for a given profile path
#      PROFILEPATH       -   Parameter to specify the profile path
#      policyid          -   parameter to specify the policy id for answerfile option
#      pgObj             -   portgroup object
#
# Results:
#      Returns success if import answer successfully.
#      Returns failure, if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub UpdateAnswerFile
{
   my $self         = shift;
   my %args         = @_;

   my $refHostObj    = $args{srchost};
   my $answerfileoption   = $args{answerfileoption};
   my $profilepath   = $args{profilepath};
   my $policyid      = $args{policyid};
   my $pgObj         = $args{portgroup};

   my $proxy         = $self->{proxy};
   my $result;
   my $command;

   my $hostObj = $refHostObj->[0];
   if (not defined $hostObj) {
      $vdLogger->Error("target host not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $hostIp = $hostObj->{hostIP};

   if (not defined $answerfileoption) {
      $vdLogger->Error("answer file options not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $policyid) {
      $vdLogger->Error("policyid $policyid  not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (not defined $pgObj) {
      $vdLogger->Error("portgroup obj not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $pgName = $pgObj->{pgName};
   if (not defined  $profilepath) {
      $profilepath = VDNetLib::TestData::TestConstants::HOSTPORTGROUP_PROFILE.$pgName."\"].ipConfig";
      $vdLogger->Debug("profilepath: $profilepath");
   }

   $command = " UPDATEANSWERFILE  anchor $self->{hostAnchor} host $hostIp " .
              " ANSWERFILEOPTIONS  \"$answerfileoption\" " .
              " PROFILEPATH " . STAF::WrapData($profilepath) . " POLICYID  \"$policyid\" ";

   $vdLogger->Debug("STAF command: $command");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Fail to update answer file".  Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Update answerfile to $hostIp sucessfully.");
   return SUCCESS;
}


###############################################################################
#
# UpdateIpAddressOption --
#      This method will update host's IpAddress, subnetnetamk in  answer file
#
# Input:
#      refHostObj        -   reference to test hostObj
#      deviceid          -   vmkX
#      PROFILEPATH       -   Parameter to specify the profile path
#      policyid          -   parameter to specify the policy id for answerfile option
#
# Results:
#      Returns success if import answer successfully.
#      Returns failure, if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub UpdateIpAddressOption
{
   my $self         = shift;
   my %args         = @_;

   my $refHostObj    = $args{srchost};
   my $deviceid      = $args{ipaddressoption};
   my $profilepath   = $args{profilepath};
   my $policyid      = $args{policyid};

   my $proxy         = $self->{proxy};
   my $result;
   my $command;
   my $vmknicHash;
   my $answerfileoption;
   my $pgName;
   my $subnetmask;

   my $hostObj = $refHostObj->[0];
   if (not defined $hostObj) {
      $vdLogger->Error("target host not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $hostIp = $hostObj->{hostIP};

   if (not defined $policyid) {
      $vdLogger->Error("policyid $policyid  not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if ($deviceid =~ /vmk/i)  {
      $vmknicHash = $hostObj->GetAdapterInfo(deviceId => $deviceid);
      if ($vmknicHash eq FAILURE) {
         $vdLogger->Error("Failed to get info of deviceId on host $hostIp");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
      $subnetmask = $vmknicHash->{netmask};
      $answerfileoption = "address=".$hostIp.","."subnetmask=$subnetmask";
      $vdLogger->Info("answerfileoption update: $answerfileoption");
   } else {
      $vdLogger->Error("vmknic: $deviceid is not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (not defined $profilepath) {
     $pgName = "ManagementNetwork";
     $profilepath = VDNetLib::TestData::TestConstants::HOSTPORTGROUP_PROFILE.$pgName."\"].ipConfig";
   }

   $command = " UPDATEANSWERFILE  anchor $self->{hostAnchor} host $hostIp " .
              " ANSWERFILEOPTIONS  \"$answerfileoption\" " .
              " PROFILEPATH " . STAF::WrapData($profilepath) . " POLICYID  \"$policyid\" ";

   $vdLogger->Debug("STAF command: $command");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Fail to update answer file".  Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Update answerfile to $hostIp sucessfully.");
   return SUCCESS;
}


###############################################################################
#
# ExportAnswerFile --
#      This method will import export file of a host
#
# Input:
#      refHostObj  -   reference to test hostObj
#      answerfile  -   exported answer file location(on MC)
# Results:
#      Returns success if export answer successfully. and answer file write to
#      file specified by answerfile
#      Returns failure, if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub ExportAnswerFile
{
   my $self         = shift;
   my $refHostObj   = shift; # mandatory
   my $answerfile   = shift; # mandatory
   my $proxy        = $self->{proxy};
   my $result;
   my $command;

   my $hostObj = $refHostObj->[0];
   if (not defined $hostObj) {
      $vdLogger->Error("target host not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $hostIp = $hostObj->{hostIP};
   if (not defined $answerfile) {
      $vdLogger->Error("answer file not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   my $logDir = VDNetLib::Common::GlobalConfig::GetLogsDir();
   my $logFile = $logDir . $answerfile;

   $vdLogger->Debug("lofFile: $logDir  $logFile");
   $command = " EXPORTANSWERFILE  anchor $self->{hostAnchor} host $hostIp ";
   $vdLogger->Debug("STAF command: $command");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
   $vdLogger->Debug("export answer file".  Dumper($result));
   if ($result->{rc} != 0) {
      $vdLogger->Error("Fail to export answer file".  Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   my $export = $result->{result};

   my $fileHandle = undef;
   if (not defined open($fileHandle, "+>$logFile")) {
      $fileHandle = undef;
      $vdLogger->Error("Unable to open answer file $answerfile for writing:"
                       ."$!");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   print $fileHandle $export;
   $vdLogger->Info("Export answer file from $hostIp " . "
                      sucessfully.answer file name is $answerfile.");
   close $fileHandle;
   return SUCCESS;
}


###############################################################################
#
# GetAnswerFile --
#      This method will get answer file to a host
#
# Input:
#      refHostObj  -   reference to test hostObj
#      location    -   out to screen (optional)
#
# Results:
#      Returns success if import answer successfully.
#      Returns failure, if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub GetAnswerFile
{
   my $self         = shift;
   my $refHostObj   = shift; # mandatory
   my $location     = shift; # optional
   my $proxy        = $self->{proxy};
   my $result;
   my $command;

   my $hostObj = $refHostObj->[0];
   if (not defined $hostObj) {
      $vdLogger->Error("target host not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   if (not defined $location) {
      $location = "screen";
   }
   my $hostIp = $hostObj->{hostIP};
   $command = " GETANSWERFILE  anchor $self->{hostAnchor} host $hostIp ";
   $vdLogger->Debug("STAF command: $command");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Fail to get answer file".  Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   if ($location =~ /screen/i) {
      $vdLogger->Info("result" . Dumper($result) );
   }
   $vdLogger->Info("Get answer file from $hostIp sucessfully.");
   return SUCCESS;
}


#######################################################################
#
# MigrateManamgementNetToVDS--
#      This method migrates the managment network to vDS.
#
#
# Input:
#  A name parameter hash having the following keys.
#    host : Name of the ESX host whose management net has to
#           be migrated to vSS.
#    vdsname : Name of the VDS.
#    dcname  : Name of the data center.
#    dvpgname: of the DVPortgroup
#    pgname  : Name of the portgroup.
#
#
#
# Results:
#      "SUCCESS", if managment network gets migrated to vDS,
#      "FAILURE", in case of any error,
#
# Side effects:
#      None.
######################################################################

sub MigrateManamgementNetToVDS {
   my $self         = shift;
   my $host         = shift; # mandatory
   my $vdsname      = shift; # mandatory
   my $dcname       = shift; # mandatory
   my $dvpgname     = shift; # mandatory
   my $pgname       = shift; # mandatory
   my $proxy        = $self->{proxy};
   my $result;
   my $command;

   if (not defined $host) {
      $vdLogger->Error("host not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $vdsname) {
      $vdLogger->Error("vds not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $dcname) {
      $vdLogger->Error("dc not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $dvpgname) {
      $vdLogger->Error("dvportgroup not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $pgname) {
      $vdLogger->Error("portgroup not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $command = " MIGRATEMGMTNETWORKTODVS  anchor $self->{hostAnchor} PGHOST $host ".
              " DVSNAME \"$vdsname\" DCNAME \"$dcname\" DVPORTGROUPNAME \"$dvpgname\" ".
              " PORTGROUP \"$pgname\"";
   $vdLogger->Debug("STAF command: $command");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Fail to migrate management net to vDS".  Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Info("Migrate management net to vDS sucessfully.");
   return SUCCESS;
}

###############################################################################
#
# SyncupVDL2ConfigTool --
#      Sync up VDL2 configuration tool.
#
# Input:
#      None
#
# Results:
#      "SUCCESS", if sync up VDL2 configuration tool,
#      "FAILURE", in case of any error,
#
# Side effects:
#      None.
#
###############################################################################

sub SyncVDL2ConfigTool
{
   my $self          = shift;
   my $gConfig       = new VDNetLib::Common::GlobalConfig();
   my $cfgToolsDir   = $gConfig->GetVDL2ConfigToolPath();
   my $vcBuild       = $self->GetVCBuild();
   my $cfgToolFile;
   my $vdl2FilePath  = "$cfgToolsDir/lib/vdl2.jar";
   my $command;
   my $result;
   my $buildInfo;
   my $url;

   # Download vdl2 configuration tools if there is no the lastest file
   # Check whether the directory exists
   if ( -e $cfgToolsDir and -e $vdl2FilePath ) {
     # the directory and jar file exist, do nothing
     $vdLogger->Info("VDL2 configuration tool directory $cfgToolsDir exists.");
   } else {
      # the directory does not exist..., mkdir and download file
      $command = "mkdir -p $cfgToolsDir";
      $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);
      if (($result->{rc} != 0) or ($result->{exitCode} != 0)) {
         $vdLogger->Error("STAF command to mkdir failed" . Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      $cfgToolFile = "$cfgToolsDir/cfgTools.tgz";
      $buildInfo = VDNetLib::Common::FindBuildInfo::getOfficialBuildInfo($vcBuild);

      if ((! defined $buildInfo->{'buildtree'}) or
          ($buildInfo->{'buildtree'} eq "")) {
         $vdLogger->Debug("No offcial build found, try sandbox buildtree...");
         $buildInfo = VDNetLib::Common::FindBuildInfo::getSandboxBuildInfo($vcBuild);

         if ((! defined $buildInfo->{'buildtree'}) or
             ($buildInfo->{'buildtree'} eq "")) {
            $vdLogger->Debug("No sandbox build found, please check if the" .
                            " build is too old and no longer on disk.");
            VDSetLastError("ENOTDEF");
            return FAILURE;
         }
      }

      $url = VDNetLib::Common::GlobalConfig::VXLAN_TOOL_URL;
      $vdLogger->Info("Downloading VMware VXLAN configration tools from $url " .
                   "to $cfgToolFile ...");
      if(HTTP::Status::is_error(LWP::Simple::getstore($url, "$cfgToolFile"))) {
         $vdLogger->Error("Failed to get the VXLAN configuration file from " .
                          "\$url = $url ");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      };

      # uncompress file and get vdl2 configuration tools path
      $command = "tar -C $cfgToolsDir -zxvf $cfgToolFile";
      $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);
      if (($result->{rc} != 0) or ($result->{exitCode} != 0)) {
         $vdLogger->Error("STAF command to unzip tool failed" .
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      # check vdl2.jar file exist
      if ( -e $vdl2FilePath ) {
         # vdl2.jar does exists, do nothing
      } else {
         # vdl2.jar file is inexistence
         $vdLogger->Error("There is no vdl2.jar file in $cfgToolsDir/lib/");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }

      # remove the zip file
      $command = "rm -r $cfgToolFile";
      $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);
      if (($result->{rc} != 0) or ($result->{exitCode} != 0)) {
         $vdLogger->Error("STAF command to remove zip file failed" .
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
   }
   $vdLogger->Info("Sync up VDL2 configuration tool sucessfully.");
   return SUCCESS;
}

###############################################################################
#
# EnableVDL2 --
#      This method will enable vdl2 on a dedicated virtual switch.
#
# Input:
#      VDS name              -   VDS name
# Results:
#      Returns SUCCESS, if enabled.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub EnableVDL2
{
   my $self          = shift;
   my $vdsname       = shift; # mandatory
   my $vcaddr        = $self->{vcaddr};
   my $vcuser        = $self->{user};
   my $vcpass        = $self->{passwd};
   my $gConfig       = new VDNetLib::Common::GlobalConfig();
   my $cfgToolsDir   = $gConfig->GetVDL2ConfigToolPath();
   my $result;
   my $command;

   $vcpass =~ s/\$/\\\$/;

   if (not defined $vdsname) {
      $vdLogger->Error("vds name not provided.");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # sync up VDL2 configuration tool
   $result = $self->SyncVDL2ConfigTool();
   if ($result eq "FAILURE") {
      $vdLogger->Error("Sync up VDL2 config tool failed");
      VDSetLastError("EFAIL");
      return FAILURE;
   }

   # command to enable vdl2
   my @name = split (/,/, $vdsname);
   for my $tmpname (@name) {
      $command = "java -jar $cfgToolsDir/lib/vdl2.jar".
              " enableVdl2 $tmpname $vcaddr $vcuser $vcpass";
      $vdLogger->Debug(" Call java program : command = $command");
      $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);
      if ( ($result->{rc} != 0) or ($result->{exitCode} != 0) or
           ($result->{stdout} =~ /error|fail|can't/i) ) {
         $vdLogger->Error("STAF command to call java program failed".
                       Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      } elsif ($result->{stdout} =~ /success/i) {
         $vdLogger->Info("VDL2 Enabled on $tmpname");
         $vdLogger->Trace("VDL2 Enable result : " . $result->{stdout});
      } else {
         $vdLogger->Error("Invalid VDL2 configuration result ".
                       Dumper($result));
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }
   return SUCCESS;
}


###############################################################################
#
# DisableVDL2 --
#      This method will disable vdl2 on a dedicated virtual switch.
#
# Input:
#      VDS name              -   VDS name
# Results:
#      Returns SUCCESS, if enabled.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub DisableVDL2
{
   my $self          = shift;
   my $vdsname       = shift; # mandatory
   my $vcaddr        = $self->{vcaddr};
   my $vcuser        = $self->{user};
   my $vcpass        = $self->{passwd};
   my $cfgToolsDir   = $self->{globalConfig}->GetVDL2ConfigToolPath();
   my $result;
   my $command;

   $vcpass =~ s/\$/\\\$/;

   if (not defined $vdsname) {
      $vdLogger->Error("vds name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my @name = split (/,/, $vdsname);
   for my $tmpname (@name) {
      # command to enable vdl2
      $command = "java -jar $cfgToolsDir/lib/vdl2.jar".
                 " disableVdl2 $tmpname $vcaddr $vcuser $vcpass";
      $vdLogger->Debug(" Call java program : command = $command");
      $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);

      if ( ($result->{rc} != 0) or ($result->{exitCode} != 0) or
           ($result->{stdout} =~ /error|fail|can't/i) ) {
         $vdLogger->Error("STAF command to call java program failed".
                           Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      } elsif ($result->{stdout} =~ /success/i) {
         $vdLogger->Info("VDL2 Disabled on $vdsname");
         $vdLogger->Trace("VDL2 Disable result : ".$result->{stdout});
      } else {
         $vdLogger->Error("Invalid VDL2 configuration result ". Dumper($result));
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }
   return SUCCESS;
}


###############################################################################
#
# CreateVDL2VMKNIC --
#      This method will create vmknic for given (vdsName,vlanID),
#      defalut vlanID = 0,assign [hostname ipaddress] pair if you want to
#      specify IP on each host statically, or else IP will be allocated in DHCP
#
# Input:
#      VDS name              -   VDS name (mandatory)
#      VLAN ID               -   VDL2 VMKNIC's vlan, default is 0.(optional)
#      VMKNICIP              -   VDL2 VMKNIC's IP, default is DHCP.(optional)
#
# Results:
#      Returns SUCCESS, if created.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub CreateVDL2VMKNIC
{
   my $self          = shift;
   my $vdsname       = shift; # mandatory
   my $vlanid        = shift;
   my $vmknicip      = shift;
   my $vcaddr        = $self->{vcaddr};
   my $vcuser        = $self->{user};
   my $vcpass        = $self->{passwd};
   my $cfgToolsDir   = $self->{globalConfig}->GetVDL2ConfigToolPath();
   my $result;
   my $command;

   $vcpass =~ s/\$/\\\$/;

   if (not defined $vdsname) {
      $vdLogger->Error("vds name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my @name = split (/,/, $vdsname);
   for my $tmpname (@name) {
      # command to enable vdl2
      $command = "java -jar $cfgToolsDir/lib/vdl2.jar ".
                 "createVmknic $tmpname ";
      if (defined $vlanid){
         $command = $command ." $vlanid ";
      }
      $command = $command . " $vcaddr $vcuser $vcpass ";
      $vdLogger->Debug(" Call java program : command = $command");
      $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);

      if ( ($result->{rc} != 0) or ($result->{exitCode} != 0) or
           ($result->{stdout} =~ /error|fail|can't/i) ) {
         $vdLogger->Error("STAF command to call java program failed".
                           Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      } elsif ($result->{stdout} =~ /success/i) {
         $vdLogger->Info("VDL2 vmknic created : ".$result->{stdout});

      } else {
         $vdLogger->Error("Invalid VDL2 configuration result ". Dumper($result));
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }
   return SUCCESS;
}


###############################################################################
#
# ChangeVDL2VMKNIC --
#      This method will change vmknic ip for given (vdsName,vlanID),
#      defalut vlanID = 0.
#
# Input:
#      VDSNAME     -   VDS name (mandatory)
#      HOST        -   Which host is the vmknic on (host ip) (mandatory)
#      VLANID      -   VDL2 VMKNIC's vlan, default is 0.(optional)
#      IPADDR      -   VDL2 VMKNIC's IP, default is DHCP.(optional)
#      NETMASK     -   VDL2 VMKNIC's netmask.(optional)
#      SETDHCP     -   Enable or disable dhcp.(optional)
#
# Results:
#      Returns SUCCESS, if created.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub ChangeVDL2VMKNIC
{
   my $self          = shift;
   my $args          = shift;
   my $vdsname       = $args->{vdsname};
   my $host          = $args->{host};
   my $vlanid        = $args->{vlanid};
   my $ipaddr        = $args->{ipaddr};
   my $netmask       = $args->{netmask};
   my $setdhcp       = $args->{setdhcp};
   my $proxy         = $self->{proxy};
   my $vmknicid;
   my $result;
   my $command;
   my %paramhash;

   if (not defined $vdsname) {
      $vdLogger->Error("vds name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $host) {
      $vdLogger->Error("Host not provided, please specify STU/helper1/...");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $vlanid) {
      $vlanid = 0;
   }

   $paramhash{vdsname} = $vdsname;
   $paramhash{host} = $host;
   $paramhash{vlanid} = $vlanid;
   $vmknicid = $self->GetVDL2VMKNICID(\%paramhash);

   $command = "CHANGEVMKNICOFDVS ANCHOR $self->{setupAnchor} HOST $host " .
              "VNICID $vmknicid ";

   if (defined $ipaddr) {
      if (not defined $netmask) {
         $netmask = "255.255.0.0";
         $vdLogger->Warn("Vmknic netmask not provided. Use 255.255.0.0.");
      }
      $command = $command . "NEWIP $ipaddr NEWNETMASK $netmask ";
   }

   if (defined $setdhcp) {
      $command = $command . "SETDHCP $setdhcp ";
   }

   $vdLogger->Debug("Run command : $command");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);

   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to change vmknic $vmknicid on $host".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $vdLogger->Info("Change vmknic $vmknicid on $host successfully.");
   return SUCCESS;
}


###############################################################################
#
# GetVDL2VMKNICID --
#      This method will get vmknic id (vmk1/2/N) with given (vdsName,host,vlanID),
#      defalut vlanID = 0.
#
# Input:
#      VDSNAME     -   VDS name (mandatory)
#      HOST        -   Host ip ((mandatory)
#      VLANID      -   VDL2 VMKNIC's vlan, default is 0.(optional)
#
# Results:
#      Returns vmknic id, if succeeded.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub GetVDL2VMKNICID
{
   my $self          = shift;
   my $args          = shift;
   my $vdsname       = $args->{vdsname};
   my $host          = $args->{host};
   my $vlanid        = $args->{vlanid};
   my $result;
   my $command;

   if (not defined $vdsname) {
      $vdLogger->Error("vds name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $host) {
      $vdLogger->Error("Host not provided, please specify STU/helper1/...");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $vlanid) {
      $vlanid = 0;
   }
# The OP doesn't support the -V option, so we remove it
   $command = "net-vdl2 -l -s $vdsname";
   $vdLogger->Debug(" Call net-vdl2 : command = $command");
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);

   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to run command: $command".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($result->{stdout} =~ m/VXLAN vmknic:\s+(vmk\d+)/is) {
      return $1;
   } else {
      $vdLogger->Error("No vmknic found on $host, $vdsname, vlan $vlanid".
                        Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}


###############################################################################
#
# GetVDL2VMKNICIP --
#      This method will get vmknic ip with given (vdsName,host,vlanID),
#      defalut vlanID = 0.
#
# Input:
#      VDSNAME     -   VDS name (mandatory)
#      HOST        -   Host ip ((mandatory)
#      VLANID      -   VDL2 VMKNIC's vlan, default is 0.(optional)
#
# Results:
#      Returns vmknic ip, if succeeded.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub GetVDL2VMKNICIP
{
   my $self          = shift;
   my $args          = shift;

   my $vdsname       = $args->{vdsname};
   my $host          = $args->{host};
   my $vlanid        = $args->{vlanid};
   my $result;
   my $command;

   if (not defined $vdsname) {
      $vdLogger->Error("vds name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $host) {
      $vdLogger->Error("Host not provided, please specify STU/helper1/...");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $vlanid) {
      $vlanid = 0;
   }

#   $command = "net-vdl2 -l -s $vdsname -V $vlanid";
# The OP doesn't support the -V option, so we remove it
   $command = "net-vdl2 -l -s $vdsname";

   $vdLogger->Debug(" Call net-vdl2 : command = $command");
   $result = $self->{stafHelper}->STAFSyncProcess($host, $command);

   if ($result->{rc} != 0) {
      $vdLogger->Error("Failed to run command: $command".
                       Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   if ($result->{stdout} =~ m/VXLAN IP:\s+(\d+\.\d+\.\d+\.\d+)/is) {
      return $1;
   } else {
      $vdLogger->Error("No vmknic found on $host, $vdsname, vlan $vlanid".
                        Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}


###############################################################################
#
# RemoveVDL2VMKNIC --
#      This method will remove vmknic for given (vdsName,vlanID),
#      defalut vlanID = 0
#
# Input:
#      VDS name              -   VDS name (mandatory)
#      VLAN ID               -   VDL2 VMKNIC's vlan, default is 0.(optional)
#
# Results:
#      Returns SUCCESS, if created.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub RemoveVDL2VMKNIC
{
   my $self          = shift;
   my $vdsname       = shift; # mandatory
   my $vlanid        = shift;
   my $vmknicip      = shift;
   my $vcaddr        = $self->{vcaddr};
   my $vcuser        = $self->{user};
   my $vcpass        = $self->{passwd};
   my $cfgToolsDir   = $self->{globalConfig}->GetVDL2ConfigToolPath();
   my $result;
   my $command;

   $vcpass =~ s/\$/\\\$/;

   if (not defined $vdsname) {
      $vdLogger->Error("vds name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my @name = split (/,/, $vdsname);
   for my $tmpname (@name) {
      # command to enable vdl2
      $command = "java -jar $cfgToolsDir/lib/vdl2.jar ".
                 "removeVmknic $tmpname ";
      if (defined $vlanid){
         $command = $command ." $vlanid ";
      }
      if (defined $vmknicip){
      # TODO :  deal with static IP address.
      }

      # Sleep to make sure vdl2 vmknic has finished its task and can be removed.
      $vdLogger->Debug("Sleep 5 sec to make sure vmknic is in idle state");
      sleep (5);

      $command = $command . " $vcaddr $vcuser $vcpass ";
      $vdLogger->Debug(" Call java program : command = $command");
      $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);

      if ( ($result->{rc} != 0) or ($result->{exitCode} != 0) or
           ($result->{stdout} =~ /error|fail|can't/i) ) {
         $vdLogger->Error("STAF command to call java program failed".
                           Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      } elsif ($result->{stdout} =~ /success/i) {
         $vdLogger->Info("VDL2 vmknic removed : ".$result->{stdout});
      } else {
         $vdLogger->Error("Invalid VDL2 configuration result ". Dumper($result));
         VDSetLastError("EFAIL");
         return FAILURE;
      }
   }
   return SUCCESS;
}


###############################################################################
#
# AttachVDL2 --
#      This method will attach a DVPG to VDL2 with specified VDL2ID and
#      multicast ip address.
#
# Input:
#      VDS name              -   VDS name (mandatory)
#      PG name               -   DVPG name, can be a single one or a group,
#                                like pg1-100  (mandatory)
#      VDL2 id               -   the id of VDL2, can be a single number or a
#                                range, like 100-200  (mandatory)
#      MCASTIP               -   multicast ip address, can be a single ip or
#                                a range, like 239.0.0.1-239.0.1.23 (mandatory)
#
#      E.g. PG name: pg1-3, VDL2 id: 100-101, MCASTIP: 239.0.0.1-239.0.0.2
#      Then pg1->100/239.0.0.1; pg2->101/239.0.0.2; pg3->100/239.0.0.1
#
# Results:
#      Returns SUCCESS, if attached.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub AttachVDL2
{
   my $self          = shift;
   my $vdsname       = shift; # mandatory
   my $pgname        = shift; # mandatory
   my $vdl2id        = shift; # mandatory
   my $mcastip       = shift; # mandatory
   my $vcaddr        = $self->{vcaddr};
   my $vcuser        = $self->{user};
   my $vcpass        = $self->{passwd};
   my $cfgToolsDir   = $self->{globalConfig}->GetVDL2ConfigToolPath();
   my $result;
   my $command;
   my @pgs;
   my @ids;
   my @ips;

   $vcpass =~ s/\$/\\\$/;

   if (not defined $vdsname) {
      $vdLogger->Error("vds name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $pgname) {
      $vdLogger->Error("DVPG name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $vdl2id) {
      $vdLogger->Error("VDL2 ID not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $mcastip) {
      $vdLogger->Error("Multicast IP address not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # In case the portgroup name was given as "pg1-100"
   if ($pgname =~ m/^([^\-]+[a-zA-Z])(\d+)-(\d+)$/) {
      for (my $i = $2; $i<= $3; $i++) {
         push(@pgs,$1.$i);
      }
   } else {
      push(@pgs,$pgname);
   }

   # In case the vdl2 id was given as "100-200"
   if ($vdl2id =~ m/(\d+)-(\d+)/) {
      for (my $i = $1; $i<= $2; $i++) {
         push(@ids,$i);
      }
   } else {
      push(@ids,$vdl2id);
   }

   # In case the multicast ip was given as "239.0.0.1-239.0.1.23"
   if ($mcastip =~ m/\d+.\d+.\d+.\d+-\d+.\d+.\d+.\d+/) {
      my $ip = new Net::IP ($mcastip) || die;

      do {
         push(@ips,$ip->ip());
      } while (++$ip);
   } else {
      push(@ips,$mcastip);
   }

   #
   # In case there are more than 1 dvportgroup need to be done
   # E.g. portgroup: pg1-3, vdl2id: 100-101, mcastip: 239.0.0.1-239.0.0.2
   # Then pg1->100/239.0.0.1; pg2->101/239.0.0.2; pg3->100/239.0.0.1
   #

   if (scalar(@pgs) == 1) {
      #
      # Use java tool command attachVdl2 as before because attachVdl2BatchAll
      # has some problems which will not be fixed in vSphere5X branch.
      #
      $command = "java -jar $cfgToolsDir/lib/vdl2.jar ".
                 "attachVdl2 $vdsname $pgs[0] $ids[0] $ips[0] ";
   } else {
      $command = "java -jar $cfgToolsDir/lib/vdl2.jar attachVdl2BatchAll $vdsname ";

      foreach my $pg (@pgs){
         $command = $command . "$pg ";
      }

      for (my $i = 0; $i < scalar(@pgs); $i++) {
         my $index = $i % scalar(@ids);
         $command = $command . "$ids[$index] ";
      }

      for (my $i = 0; $i < scalar(@pgs); $i++) {
         my $index = $i % scalar(@ips);
         $command = $command . "$ips[$index] ";
      }
   }

   $command = $command . " $vcaddr $vcuser $vcpass ";
   $vdLogger->Debug(" Call java program : command = $command");
   $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);

   if ( ($result->{rc} != 0) or ($result->{exitCode} != 0) or
        ($result->{stdout} =~ /error|fail|can't/i) ) {
      $vdLogger->Error("STAF command to call java program failed".
                        Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   } elsif ($result->{stdout} =~ /success/i) {
      # Sleep to wait for multicast routing ready.
      $vdLogger->Debug("Sleep 5 sec to wait for multicast routing ready");
      sleep (5);
      $vdLogger->Info("VDL2 attached : ".$result->{stdout});
      return SUCCESS;
   } else {
      $vdLogger->Error("Invalid VDL2 configuration result ". Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}


###############################################################################
#
# DetachVDL2 --
#      This method will detach a DVPG from VDL2.
#
# Input:
#      VDS name              -   VDS name (mandatory)
#      PG name               -   DVPG name, can be a single one or a group,
#                                like pg1-100  (mandatory)
#
# Results:
#      Returns SUCCESS, if detached.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub DetachVDL2
{
   my $self          = shift;
   my $vdsname       = shift; # mandatory
   my $pgname        = shift; # mandatory
   my $vcaddr        = $self->{vcaddr};
   my $vcuser        = $self->{user};
   my $vcpass        = $self->{passwd};
   my $cfgToolsDir   = $self->{globalConfig}->GetVDL2ConfigToolPath();
   my $result;
   my $command;
   my @pgs;

   $vcpass =~ s/\$/\\\$/;

   if (not defined $vdsname) {
      $vdLogger->Error("vds name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $pgname) {
      $vdLogger->Error("DVPG name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # In case the portgroup name was given as "pg1-100"
   if ($pgname =~ m/^([^\-]+[a-zA-Z])(\d+)-(\d+)$/) {
      for (my $i = $2; $i<= $3; $i++) {
         push(@pgs,$1.$i);
      }
   } else {
      push(@pgs,$pgname);
   }

   #
   # Detach vdl2 to dvportgroups in a loop because DEV didn't provides a batch
   # command as Attach.
   #
   foreach my $pg (@pgs) {
      # command to detach vdl2 for a single dvportgroup.
      $command = "java -jar $cfgToolsDir/lib/vdl2.jar ".
                 "detachVdl2 $vdsname $pg $vcaddr $vcuser $vcpass ";

      $vdLogger->Debug(" Call java program : command = $command");
      $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);

      if ( ($result->{rc} != 0) or ($result->{exitCode} != 0) or
           ($result->{stdout} =~ /error|fail|can't/i) ) {
         $vdLogger->Error("STAF command to call java program failed".
                           Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      } else {
         $vdLogger->Info("VDL2 detached : ".$result->{stdout});
      }
   }

   return SUCCESS;
}


###############################################################################
#
# AttachVDL2ID --
#      This method will attach a DVPG to VDL2 with specified VDL2ID.
#
# Input:
#      VDS name              -   VDS name (mandatory)
#      PG name               -   DVPG name (mandatory)
#      VDL2 id               -   the id in VDL2 (mandatory)
#
# Results:
#      Returns SUCCESS, if attached.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub AttachVDL2ID
{
   my $self          = shift;
   my $vdsname       = shift; # mandatory
   my $pgname        = shift; # mandatory
   my $vdl2id        = shift; # mandatory
   my $vcaddr        = $self->{vcaddr};
   my $vcuser        = $self->{user};
   my $vcpass        = $self->{passwd};
   my $cfgToolsDir   = $self->{globalConfig}->GetVDL2ConfigToolPath();
   my $result;
   my $command;

   $vcpass =~ s/\$/\\\$/;

   if (not defined $vdsname) {
      $vdLogger->Error("vds name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $pgname) {
      $vdLogger->Error("DVPG name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $vdl2id) {
      $vdLogger->Error("VDL2 ID not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   # command to enable vdl2
   $command = "java -jar $cfgToolsDir/lib/vdl2.jar ".
              "attachVdl2Id $vdsname $pgname $vdl2id ".
              " $vcaddr $vcuser $vcpass ";
   $vdLogger->Debug(" Call java program : command = $command");
   $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);

   if ( ($result->{rc} != 0) or ($result->{exitCode} != 0) or
        ($result->{stdout} =~ /error|fail|can't/i) ) {
      $vdLogger->Error("STAF command to call java program failed".
                        Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   } elsif ($result->{stdout} =~ /success/i) {
      $vdLogger->Info("VDL2 attachedID : ".$result->{stdout});
      return SUCCESS;
   } else {
      $vdLogger->Error("Invalid VDL2 configuration result ". Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}


###############################################################################
#
# AttachVDL2MCIP --
#      This method will attach a DVPG to VDL2 with specified
#      multicast ip address.
#
# Input:
#      VDS name              -   VDS name (mandatory)
#      PG name               -   DVPG name (mandatory)
#      MCASTIP               -   multicast ip address (mandatory)
#
# Results:
#      Returns SUCCESS, if attached.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub AttachVDL2MCIP
{
   my $self          = shift;
   my $vdsname       = shift; # mandatory
   my $pgname        = shift; # mandatory
   my $mcastip       = shift; # mandatory
   my $vcaddr        = $self->{vcaddr};
   my $vcuser        = $self->{user};
   my $vcpass        = $self->{passwd};
   my $cfgToolsDir   = $self->{globalConfig}->GetVDL2ConfigToolPath();
   my $result;
   my $command;

   $vcpass =~ s/\$/\\\$/;

   if (not defined $vdsname) {
      $vdLogger->Error("vds name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $pgname) {
      $vdLogger->Error("DVPG name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   if (not defined $mcastip) {
      $vdLogger->Error("Multicast IP address not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   # command to enable vdl2
   $command = "java -jar $cfgToolsDir/lib/vdl2.jar ".
              "attachVdl2Mcastip $vdsname $pgname $mcastip ".
              " $vcaddr $vcuser $vcpass ";
   $vdLogger->Debug(" Call java program : command = $command");
   $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);

   if ( ($result->{rc} != 0) or ($result->{exitCode} != 0) or
        ($result->{stdout} =~ /error|fail|can't/i) ) {
      $vdLogger->Error("STAF command to call java program failed".
                        Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   } elsif ($result->{stdout} =~ /success/i) {
      $vdLogger->Info("VDL2 attached multicast : ".$result->{stdout});
      return SUCCESS;
   } else {
      $vdLogger->Error("Invalid VDL2 configuration result ". Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}


###############################################################################
#
# SetVDL2UDPPort --
#      This method will Configure UDP port on host member
#      multicast ip address.
#
# Input:
#      VDSNAME     -   VDS name (mandatory)
#      HOST        -   Which host is to use the specified udp port (mandatory)
#      UDPPORT     -   udp port number (mandatory)
#
# Results:
#      Returns SUCCESS, if attached.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub SetVDL2UDPPort
{
   my $self          = shift;
   my $args          = shift;
   my $vdsname       = $args->{vdsname};
   my $host          = $args->{host};
   my $udpport       = $args->{udpport};
   my $vcaddr        = $self->{vcaddr};
   my $vcuser        = $self->{user};
   my $vcpass        = $self->{passwd};
   my $gConfig       = new VDNetLib::Common::GlobalConfig();
   my $cfgToolsDir   = $gConfig->GetVDL2ConfigToolPath();
   my $result;
   my $command;

   $vcpass =~ s/\$/\\\$/;

   if (not defined $vdsname) {
      $vdLogger->Error("vds name not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $host) {
      $vdLogger->Error("Host not provided, please specify STU/helper1/...");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $udpport) {
      $vdLogger->Error("udp port not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $command = "java -jar $cfgToolsDir/lib/vdl2.jar ".
              "setUdpPort $vdsname $host $udpport".
              " $vcaddr $vcuser $vcpass ";
   $vdLogger->Debug(" Call java program : command = $command");
   $result = $self->{stafHelper}->STAFSyncProcess("localhost", $command);

   if ( ($result->{rc} != 0) or ($result->{exitCode} != 0) or
        ($result->{stdout} =~ /error|fail|can't/i) ) {
      $vdLogger->Error("STAF command to call java program failed".
                        Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   } elsif ($result->{stdout} =~ /success/i) {
      $vdLogger->Info("VDL2 attached : ".$result->{stdout});
      return SUCCESS;
   } else {
      $vdLogger->Error("Invalid VDL2 configuration result ". Dumper($result));
      VDSetLastError("EFAIL");
      return FAILURE;
   }
}


###############################################################################
#
# GetNumSystemPools --
#      This method will get the num of system pools defined.
#
# Input:
#      host               -   host on which to find pools (mandatory)
#      timeout            -   (optional)
#
# Results:
#      Returns num of pools if SUCCESS
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub GetNumSystemPools
{
   my $self = shift;
   my $host = shift;
   my $waittime = shift || 10;
   my ($cmd, $result);

   if (not defined $host) {
      $vdLogger->Error("Paramter host missing in GetNumSystemPools()");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   $cmd = "vsish -pe ls "
      . "/net/sched/pools/persistent/ids";
   $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd, $waittime);
   if($result->{rc} != 0){
      $vdLogger->Error("Failed to execute $cmd on $host");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   if ($result->{stdout} =~ /VSISHPath_Form/i ||
       $result->{stderr} =~ /VSISHPath_Form/i){
      $vdLogger->Error("$cmd failed on $host :" . Dumper($result));
      VDSetLastError("EFAILED");
      return FAILURE;
   }
   $result->{stdout} =~ /(\d$)/;
   my $numSystemPools = $1;
   if (not defined $numSystemPools) {
      $vdLogger->Error("Not able to find number of system pools");
      VDSetLastError("EFAILED");
      return FAILURE;
   }
   return $numSystemPools

}


###############################################################################
#
# CheckVDL2EsxCLI --
#      This method will check the output of vdl2 esxcli commands.
#
# Input:
#      VDSNAME     -   VDS name (mandatory)
#      HOST        -   Which host is to run the commands (mandatory)
#      ESXCLICMD   -   esxcli command (optional)
#      VDL2ID      -   vdl2 id (mandatory)
#      VLANID      -   vdl2 vmknic vlan id (optional)
#      MCASTIP     -   Multicast ip (mandatory)
#
# Results:
#      Returns SUCCESS, if succeeded.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub CheckVDL2EsxCLI
{
   my $self          = shift;
   my $args          = shift;
   my $vdsname       = $args->{vdsname};
   my $host          = $args->{host};
   my $vdl2id        = $args->{vdl2id};
   my $vlanid        = $args->{vlanid};
   my $mcastip       = $args->{mcastip};
   my $esxclicmd     = $args->{esxclicmd};
   my $networknum    = $args->{networknum};
   my $vmknicnum     = $args->{vmknicnum};
   my $peernum       = $args->{peernum};
   my $peermac       = $args->{peermac};
   my $peerhost      = $args->{peerhost};
   my $expectedresult  = $args->{expectedresult};
   my $peervmkip;
   my $vmkip;
   my $vmkid;
   my $checkall      = 0; # default is checking what user defined
   my $err           = 0;
   my %paramhash;
   my $result;
   my $cmd;

   if (not defined $host) {
      $vdLogger->Error("Host not provided, please specify STU/helper1/...");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # if this is a negative case, just use user-specified input

   if (defined $expectedresult and $expectedresult =~ m/fail/is) {
      if (not defined $esxclicmd) {
         $vdLogger->Error("esxcli command not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      $result = $self->{stafHelper}->STAFSyncProcess($host, $esxclicmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/Error|Usage|Unable/is) {
         $vdLogger->Debug("Invalid esxcli input: $result->{stdout}");
         VDSetLastError("EFAIL");
         return FAILURE;
      } else {
         $vdLogger->Error("There is a valid esxcli input for a negative case, " .
                          "please check your esxclicmd");
         return SUCCESS;  # expected result is fail
      }
   }

   # below is for positive check

   if (not defined $peerhost) {
      $vdLogger->Error("Peer host not provided, please specify SUT/helper1/...");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $vdsname) {
      $vdLogger->Error("vds index not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $vdl2id) {
      $vdLogger->Error("vdl2 id not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $mcastip) {
      $vdLogger->Error("multicast ip not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $peermac) {
      $vdLogger->Error("peer mac not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $vlanid) {
      $vlanid = 0;
   }

   if (not defined $esxclicmd or $esxclicmd =~ m/all/is) {
      $checkall = 1;
   }

   if (not defined $networknum) {
      $networknum = 1;
   }

   if (not defined $vmknicnum) {
      $vmknicnum = 1;
   }

   if (not defined $peernum) {
      $peernum = 1;
   }

   $paramhash{vdsname} = $vdsname;
   $paramhash{host} = $peerhost;
   $paramhash{vlanid} = $vlanid;
   $peervmkip = $self->GetVDL2VMKNICIP(\%paramhash);

   $paramhash{host} = $host;
   $vmkip = $self->GetVDL2VMKNICIP(\%paramhash);
   $vmkid = $self->GetVDL2VMKNICID(\%paramhash);

   #
   # Run command and check result. If no specific command was defined,
   # check all available commands one by one.
   #

   # 1. esxcli network vswitch dvs vmware vxlan list

   if ($checkall == 1 or $esxclicmd =~ m/vxlan\s+list/is) {
      $cmd = "esxcli network vswitch dvs vmware vxlan list";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/$vdsname\s+\d+\s+$networknum\s+$vmknicnum/is) {
         $vdLogger->Debug("Esxcli output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
         $err++;
      }
   }

   # 2. esxcli network vswitch dvs vmware vxlan network list [param]

   if ($checkall == 1 or $esxclicmd =~ m/network\s+list/is) {
      $cmd = "esxcli network vswitch dvs vmware vxlan network list " .
             "--vds-name=$vdsname --vxlan-id=$vdl2id";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/$vdl2id\s+$mcastip+\s+$peernum\s+$peernum/is) {
         $vdLogger->Debug("Esxcli output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
         $err++;
      }
   }

   # 3. esxcli network vswitch dvs vmware vxlan network port list [param]
   # 4. -----------------------------------------------------stats list [param]
   # 5. -----------------------------------------------------stats reset [param]

   if ($checkall == 1 or $esxclicmd =~ m/network\s+port/is) {
      # port list
      $cmd = "esxcli network vswitch dvs vmware vxlan network port list " .
             "--vds-name=$vdsname --vxlan-id=$vdl2id";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/\d+\s+(\d+)+\s+$vlanid/is) {
         my $dvportid = $1;
         $cmd = "esxcfg-vswitch -l";
         my $tmpresult = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

         if ($tmpresult->{stdout} =~ m/$dvportid\s+1\s+rhel/is) {
            $vdLogger->Debug("Esxcli output correct: $result->{stdout}");

            # port stats list
            $cmd = "esxcli network vswitch dvs vmware vxlan network port stats list " .
                   "--vds-name=$vdsname --vxlan-id=$vdl2id --vdsport-id=$dvportid";
            $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

            if ($result->{rc} != 0) {
               $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
               VDSetLastError("ESTAF");
               return FAILURE;
            }

            if ($result->{stdout} =~ m/tx\.total\s+\d+.*tx\.drop\.setOpi\s+\d+.*rx\.total\s+\d+/is) {
               $vdLogger->Debug("Esxcli output correct: $result->{stdout}");
            } else {
               $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
               $err++;
            }

            # port stats reset
            $cmd = "esxcli network vswitch dvs vmware vxlan network port stats reset " .
                   "--vds-name=$vdsname --vxlan-id=$vdl2id --vdsport-id=$dvportid";
            $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

            if ($result->{rc} != 0) {
               $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
               VDSetLastError("ESTAF");
               return FAILURE;
            }

            if ($result->{stdout} eq "") {
               $vdLogger->Debug("Esxcli output correct: no output");
            } else {
               $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
               $err++;
            }

            # port stats list
            $cmd = "esxcli network vswitch dvs vmware vxlan network port stats list " .
                   "--vds-name=$vdsname --vxlan-id=$vdl2id --vdsport-id=$dvportid";
            $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

            if ($result->{rc} != 0) {
               $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
               VDSetLastError("ESTAF");
               return FAILURE;
            }

            if ($result->{stdout} =~ m/tx\.total\s+0.*tx\.drop\.setOpi\s+0.*rx\.total\s+0/is) {
               $vdLogger->Debug("Esxcli output correct: $result->{stdout}");
            } else {
               $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
               $err++;
            }

         } else {
            $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
         }
      } else {
         $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
         $err++;
      }
   }

   # 6. esxcli network vswitch dvs vmware vxlan network mapping list [param]

   if ($checkall == 1 or $esxclicmd =~ m/network\s+mapping\s+list/is) {
      $cmd = "esxcli network vswitch dvs vmware vxlan network mapping list " .
             "--vds-name=$vdsname --vxlan-id=$vdl2id";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/$peermac.*$peervmkip\s+$vlanid/is) {
         $vdLogger->Debug("Esxcli output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
         $err++;
      }
   }

   # 7. esxcli network vswitch dvs vmware vxlan network mapping reset [param]

   if ($checkall == 1 or $esxclicmd =~ m/network\s+mapping\s+reset/is) {
      $cmd = "esxcli network vswitch dvs vmware vxlan network mapping reset " .
             "--vds-name=$vdsname --vxlan-id=$vdl2id";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} eq "") {
         $vdLogger->Debug("Esxcli output correct: no output");
      } else {
         $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
         $err++;
      }

      $cmd = "esxcli network vswitch dvs vmware vxlan network mapping list " .
             "--vds-name=$vdsname --vxlan-id=$vdl2id";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/\d/is) {
         $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
         $err++;
      } else {
         $vdLogger->Debug("Esxcli output correct: $result->{stdout}");
      }
   }

   # 8. esxcli network vswitch dvs vmware vxlan network stats list [param]

   if ($checkall == 1 or $esxclicmd =~ m/network\s+stats\s+list/is) {
      $cmd = "esxcli network vswitch dvs vmware vxlan network stats list " .
             "--vds-name=$vdsname --vxlan-id=$vdl2id";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/tx\.total\s+[1-9].*rx\.total\s+[1-9]/is) {
         $vdLogger->Debug("Esxcli output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
         $err++;
      }
   }

   # 9. esxcli network vswitch dvs vmware vxlan network stats reset [param]

   if ($checkall == 1 or $esxclicmd =~ m/network\s+stats\s+reset/is) {
      $cmd = "esxcli network vswitch dvs vmware vxlan network stats reset " .
             "--vds-name=$vdsname --vxlan-id=$vdl2id";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} eq "") {
         $vdLogger->Debug("Esxcli output correct: no output");
      } else {
         $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
         $err++;
      }

      $cmd = "esxcli network vswitch dvs vmware vxlan network stats list " .
             "--vds-name=$vdsname --vxlan-id=$vdl2id";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/tx\.total\s+0.*rx\.total\s+0/is) {
         $vdLogger->Debug("Esxcli output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
         $err++;
      }
   }

   # 10. esxcli network vswitch dvs vmware vxlan vmknic list [param]

   if ($checkall == 1 or $esxclicmd =~ m/vmknic\s+list/is) {
      $cmd = "esxcli network vswitch dvs vmware vxlan vmknic list " .
             "--vds-name=$vdsname";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/$vmkid.*$vlanid\s+$vmkip/is) {
         $vdLogger->Debug("Esxcli output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
         $err++;
      }
   }

   # 11. esxcli network vswitch dvs vmware vxlan vmknic multicastgroup list [param]

   if ($checkall == 1 or $esxclicmd =~ m/multicastgroup\s+list/is) {
      $cmd = "esxcli network vswitch dvs vmware vxlan vmknic multicastgroup list " .
             "--vds-name=$vdsname --vlan-id=$vlanid";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/$vmkid\s+$vmkip\s+$vlanid\s+$mcastip\s+YES/is) {
         $vdLogger->Debug("Esxcli output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
         $err++;
      }
   }

   # 12. esxcli network vswitch dvs vmware vxlan vmknic stats list [param]

   if ($checkall == 1 or $esxclicmd =~ m/vmknic\s+stats\s+list/is) {
      $cmd = "esxcli network vswitch dvs vmware vxlan vmknic stats list " .
             "--vds-name=$vdsname --vlan-id=$vlanid";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/tx.total\s+[1-9].*rx.total\s+[1-9]/is) {
         $vdLogger->Debug("Esxcli output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
         $err++;
      }
   }

   # 13. esxcli network vswitch dvs vmware vxlan vmknic stats reset [param]

   if ($checkall == 1 or $esxclicmd =~ m/vmknic\s+stats\s+reset/is) {
      $cmd = "esxcli network vswitch dvs vmware vxlan vmknic stats reset " .
             "--vds-name=$vdsname --vlan-id=$vlanid";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} eq "") {
         $vdLogger->Debug("Esxcli output correct: no output");
      } else {
         $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
         $err++;
      }

      # stats list
      $cmd = "esxcli network vswitch dvs vmware vxlan vmknic stats list " .
             "--vds-name=$vdsname --vlan-id=$vlanid";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/tx\.total\s+0.*rx\.total\s+0/is) {
         $vdLogger->Debug("Esxcli output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
         $err++;
      }
   }

   # 14. esxcli network vswitch dvs vmware vxlan stats list [param]

   if ($checkall == 1 or $esxclicmd =~ m/vxlan\s+stats\s+list/is) {
      $cmd = "esxcli network vswitch dvs vmware vxlan stats list " .
             "--vds-name=$vdsname";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/tx\.vxlanTotal\s+[1-9].*forward\.pass\s+[1-9]/is) {
         $vdLogger->Debug("Esxcli output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
         $err++;
      }
   }

   # 15. esxcli network vswitch dvs vmware vxlan stats reset [param]

   if ($checkall == 1 or $esxclicmd =~ m/vxlan\s+stats\s+reset/is) {
      $cmd = "esxcli network vswitch dvs vmware vxlan stats reset " .
             "--vds-name=$vdsname";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} eq "") {
         $vdLogger->Debug("Esxcli output correct: no output");
      } else {
         $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
         $err++;
      }

      $cmd = "esxcli network vswitch dvs vmware vxlan stats list " .
             "--vds-name=$vdsname";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/tx\.vxlanTotal\s+0/is) {
         $vdLogger->Debug("Esxcli output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Esxcli output incorrect: $result->{stdout}");
         $err++;
      }
   }

   if ($err == 0) {
      $vdLogger->Debug("VDL2 Esxcli testing passed!");
      return SUCCESS;
   } else {
      return FAILURE;
   }

}

###############################################################################
#
# CheckNetVDL2 --
#      This method will check the output of net-vdl2 commands.
#
# Input:
#      VDSNAME     -   VDS name (mandatory)
#      HOST        -   Which host is to run the commands (mandatory)
#      NetVDL2CMD  -   net-vdl2 command (optional)
#      VDL2ID      -   vdl2 id (mandatory)
#      VLANID      -   vdl2 vmknic vlan id (optional)
#      MCASTIP     -   Multicast ip (mandatory)
#
# Results:
#      Returns SUCCESS, if succeeded.
#      Returns FAILURE, if failed.
#
# Side effects:
#      None.
#
###############################################################################

sub CheckNetVDL2
{
   my $self          = shift;
   my $args          = shift;
   my $vdsname       = $args->{vdsname};
   my $host          = $args->{host};
   my $vdl2id        = $args->{vdl2id};
   my $vlanid        = $args->{vlanid};
   my $mcastip       = $args->{mcastip};
   my $netvdl2cmd    = $args->{netvdl2cmd};
   my $networknum    = $args->{networknum};
   my $vmknicnum     = $args->{vmknicnum};
   my $peernum       = $args->{peernum};
   my $peermac       = $args->{peermac};
   my $peerhost      = $args->{peerhost};
   my $expectedstring  = $args->{expectedstring};
   my $expectedresult  = $args->{expectedresult};
   my $peervmkip;
   my $vmkip;
   my $vmkid;
   my $checkall      = 0; # default is checking what user defined
   my $err           = 0;
   my %paramhash;
   my $result;
   my $cmd;

   if (not defined $host) {
      $vdLogger->Error("Host not provided, please specify STU/helper1/...");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # if this is a negative case, just use user-specified input

   if (defined $expectedresult and $expectedresult =~ m/fail/is) {
      if (not defined $netvdl2cmd) {
         $vdLogger->Error("net-vdl2 command not defined");
         VDSetLastError("ENOTDEF");
         return FAILURE;
      }

      $result = $self->{stafHelper}->STAFSyncProcess($host, $netvdl2cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/not specified|Usage|No such file|Invalid/is) {
         $vdLogger->Debug("Invalid input: $result->{stdout}");
         VDSetLastError("EFAIL");
         return FAILURE;
      } elsif ($result->{stderr} =~ m/not specified|Usage|No such file|Invalid/is) {
         $vdLogger->Debug("Invalid input: $result->{stderr}");
         VDSetLastError("EFAIL");
         return FAILURE;
      } else {
         $vdLogger->Error("Unexpected output: $result->{stdout}");
         return SUCCESS;  # expected result is fail
      }
   }

   # below is for positive check

   if (not defined $peerhost) {
      $vdLogger->Error("Peer host not provided, please specify SUT/helper1/...");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $vdsname) {
      $vdLogger->Error("vds index not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $vdl2id) {
      $vdLogger->Error("vdl2 id not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $mcastip) {
      $vdLogger->Error("multicast ip not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $peermac) {
      $vdLogger->Error("peer mac not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   if (not defined $vlanid) {
      $vlanid = 0;
   }

   if (not defined $netvdl2cmd or $netvdl2cmd =~ m/all/is) {
      $checkall = 1;
   }

   if (not defined $networknum) {
      $networknum = 1;
   }

   if (not defined $vmknicnum) {
      $vmknicnum = 1;
   }

   if (not defined $peernum) {
      $peernum = 1;
   }

   $paramhash{vdsname} = $vdsname;
   $paramhash{host} = $peerhost;
   $paramhash{vlanid} = $vlanid;
   $peervmkip = $self->GetVDL2VMKNICIP(\%paramhash);

   $paramhash{host} = $host;
   $vmkip = $self->GetVDL2VMKNICIP(\%paramhash);
   $vmkid = $self->GetVDL2VMKNICID(\%paramhash);

   #
   # Run command and check result. If no specific command was defined,
   # check all available commands one by one.
   #

   # 1. net-vdl2 -L log Level

   if ($checkall == 1 or $netvdl2cmd =~ m/-L\s+log\s+(\d+)/is) {
      my $loglevel = $1? $1 :3;
      $cmd = "net-vdl2 -L log $loglevel";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} eq "") {
         $vdLogger->Debug("Output correct: no output");
      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }

      $cmd = "net-vdl2 -L log";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/Log level:\s+$loglevel/is) {
         $vdLogger->Debug("Output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }
   }

   # 2. net-vdl2 -L log

   if ($checkall == 1 or $netvdl2cmd =~ m/-L\s+log\s*$/s) {
      $cmd = "net-vdl2 -L log";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/Log level:\s+\d+/is) {
         $vdLogger->Debug("Output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }

      if ($checkall == 0 && defined $expectedstring) {
         if ($result->{stdout} =~ m/$expectedstring/is) {
             $vdLogger->Debug("Output matches $expectedstring");
         } else {
            $vdLogger->Error("Output doesn't match $expectedstring");
            $err++;
         }
      }
   }

   # 3. net-vdl2 -l

   if ($checkall == 1 or $netvdl2cmd =~ m/-l\s*$/s) {
      $cmd = "net-vdl2 -l";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~
          m/$vdsname.*count:\s+$vmknicnum.*$vmkid.*Network count:\s+$networknum.*$vdl2id.*$mcastip/is) {
         $vdLogger->Debug("Output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }

      if ($checkall == 0 && defined $expectedstring) {
         if ($result->{stdout} =~ m/$expectedstring/is) {
             $vdLogger->Debug("Output matches $expectedstring");
         } else {
            $vdLogger->Error("Output doesn't match $expectedstring");
            $err++;
         }
      }
   }

   # 4. net-vdl2 -l [-s vds [-n vxlanID [-p port]]]

   if ($checkall == 1 or $netvdl2cmd =~ m/-l.*-s/is) {
      $cmd = "net-vdl2 -l -s $vdsname -n $vdl2id";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~
          m/VXLAN network:\s+$vdl2id.*$mcastip.*VXLAN port:\s+(\d+)/is) {
         $vdLogger->Debug("Output correct: $result->{stdout}");

         $cmd = "net-vdl2 -l -s $vdsname -n $vdl2id -p $1";
         $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

         if ($result->{rc} != 0) {
            $vdLogger->Error("Failed to run command: $cmd".
                             Dumper($result));
            VDSetLastError("ESTAF");
            return FAILURE;
         }
         if ($result->{stdout} =~ m/VXLAN port:\s+$1/is ) {
            $vdLogger->Debug("Output correct: $result->{stdout}");
         } else {
            $vdLogger->Error("Output incorrect: $result->{stdout}");
            $err++;
         }

         if ($checkall == 0 && defined $expectedstring) {
            if ($result->{stdout} =~ m/$expectedstring/is) {
                $vdLogger->Debug("Output matches $expectedstring");
            } else {
               $vdLogger->Error("Output doesn't match $expectedstring");
               $err++;
            }
         }

      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }
   }

   # 5. net-vdl2 -l -s vds -I IP

   if ($checkall == 1 or $netvdl2cmd =~ m/-l.*-i/is) {
      $cmd = "net-vdl2 -l -s $vdsname -i $vmkip";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/$vmkid.*$vmkip.*$mcastip/is) {
         $vdLogger->Debug("Output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }

      if ($checkall == 0 && defined $expectedstring) {
         if ($result->{stdout} =~ m/$expectedstring/is) {
             $vdLogger->Debug("Output matches $expectedstring");
         } else {
            $vdLogger->Error("Output doesn't match $expectedstring");
            $err++;
         }
      }
   }

   # 6. net-vdl2 -l -s vds -k vmknicName

   if ($checkall == 1 or $netvdl2cmd =~ m/-l.*-k/is) {
      $cmd = "net-vdl2 -l -s $vdsname -k $vmkid";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/$vmkid.*$vmkip.*$mcastip/is) {
         $vdLogger->Debug("Output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }

      if ($checkall == 0 && defined $expectedstring) {
         if ($result->{stdout} =~ m/$expectedstring/is) {
             $vdLogger->Debug("Output matches $expectedstring");
         } else {
            $vdLogger->Error("Output doesn't match $expectedstring");
            $err++;
         }
      }
   }

   # 7. net-vdl2 -l -s vds -V vlanID

   if ($checkall == 1 or $netvdl2cmd =~ m/-l.*-V/is) {
#     In OP it doesn't support -V
      $cmd = "net-vdl2 -l -s $vdsname";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/$vmkid.*$vmkip.*$mcastip/is) {
         $vdLogger->Debug("Output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }

      if ($checkall == 0 && defined $expectedstring) {
         if ($result->{stdout} =~ m/$expectedstring/is) {
             $vdLogger->Debug("Output matches $expectedstring");
         } else {
            $vdLogger->Error("Output doesn't match $expectedstring");
            $err++;
         }
      }
   }

   # 8. net-vdl2 -m -s vds -n vxlanID

   if ($checkall == 1 or $netvdl2cmd =~ m/-M/is) {
      $cmd = "net-vdl2 -M mapping -s $vdsname -n $vdl2id";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/Inner MAC:\s+$peermac.*Outer IP:\s+$peervmkip/is) {
         $vdLogger->Debug("Output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }

      if ($checkall == 0 && defined $expectedstring) {
         if ($result->{stdout} =~ m/$expectedstring/is) {
             $vdLogger->Debug("Output matches $expectedstring");
         } else {
            $vdLogger->Error("Output doesn't match $expectedstring");
            $err++;
         }
      }
   }

   # 9. net-vdl2 -r mapping -s vds -n vxlanID

   if ($checkall == 1 or $netvdl2cmd =~ m/-M.*mapping.*-r/is) {
      $cmd = "net-vdl2 -M mapping -r -s $vdsname -n $vdl2id";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} eq "") {
         $vdLogger->Debug("Output correct: no output");
      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }

      $cmd = "net-vdl2 -M mapping -s $vdsname -n $vdl2id";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/Mapping entry count:\s+0/is) {
         $vdLogger->Debug("Mapping reset succeeded: $result->{stdout}");
      } else {
         $vdLogger->Error("Mapping reset failed: $result->{stdout}");
         $err++;
      }
   }

   #10. net-vdl2 -S -s vds [-n vxlanID [-p port]]

   if ($checkall == 1 or $netvdl2cmd =~ m/-S/is) {
      $cmd = "net-vdl2 -S -s $vdsname";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/tx.vxlanTotal:\s+[1-9].*rx.vxlanTotal:\s+[1-9]/is) {
         $vdLogger->Debug("Output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }

      $cmd = "net-vdl2 -S -s $vdsname -n $vdl2id";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/tx.total:\s+[1-9].*rx.total:\s+[1-9].*/is) {
         $vdLogger->Debug("Output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }

      $cmd = "net-vdl2 -l -s $vdsname -n $vdl2id";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/VXLAN port:\s+(\d+)/is) {
         $cmd = "net-vdl2 -S -s $vdsname -n $vdl2id -p $1";
         $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

         if ($result->{rc} != 0) {
            $vdLogger->Error("Failed to run command: $cmd".
                             Dumper($result));
            VDSetLastError("ESTAF");
            return FAILURE;
         }

         if ($result->{stdout} =~ m/tx.total:\s+[1-9].*rx.total:\s+[1-9]/is) {
            $vdLogger->Debug("Output correct: $result->{stdout}");
         } else {
            $vdLogger->Error("Output incorrect: $result->{stdout}");
            $err++;
         }

      } else {
         $vdLogger->Error("Couldn't get an active port id: $result->{stdout}");
         $err++;
      }
   }

   #11. net-vdl2 -S -s vds -I IP

   if ($checkall == 1 or $netvdl2cmd =~ m/-S.*-i/is) {
      $cmd = "net-vdl2 -S -s $vdsname -i $vmkip";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/tx.total:\s+[1-9].*rx.total:\s+[1-9]/is) {
         $vdLogger->Debug("Output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }
   }

   #12. net-vdl2 -S -s vds -k vmknicName

   if ($checkall == 1 or $netvdl2cmd =~ m/-S.*-k/is) {
      $cmd = "net-vdl2 -S -s $vdsname -k $vmkid";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/tx.total:\s+[1-9].*rx.total:\s+[1-9]/is) {
         $vdLogger->Debug("Output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }
   }

   #13. net-vdl2 -S -s vds -V vlanID

   if ($checkall == 1 or $netvdl2cmd =~ m/-S.*-V/is) {
      $cmd = "net-vdl2 -S -s $vdsname";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/tx.vxlanTotal:\s+[1-9].*rx.vxlanTotal:\s+[1-9]/is) {
         $vdLogger->Debug("Output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }
   }

   #14. net-vdl2 -r stats -s vds [-n vxlanID [-p port]]

   if ($checkall == 1 or $netvdl2cmd =~ m/-S.*-r/is) {
      $cmd = "net-vdl2 -S -r -s $vdsname";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} eq "") {
         $vdLogger->Debug("Output correct: no output");
      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }

      $cmd = "net-vdl2 -S -s $vdsname";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/tx.vxlanTotal:\s+0.*rx.vxlanTotal:\s+0/is) {
         $vdLogger->Debug("Reset succeeded: $result->{stdout}");
      } else {
         $vdLogger->Error("Reset failed: $result->{stdout}");
         $err++;
      }


      $cmd = "net-vdl2 -S -r -s $vdsname -n $vdl2id";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} eq "") {
         $vdLogger->Debug("Output correct: no output");
      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }

      $cmd = "net-vdl2 -S -s $vdsname -n $vdl2id";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/tx.total:\s+0.*rx.total:\s+0/is) {
         $vdLogger->Debug("Reset succeeded: $result->{stdout}");
      } else {
         $vdLogger->Error("Reset failed: $result->{stdout}");
         $err++;
      }


      $cmd = "net-vdl2 -l -s $vdsname -n $vdl2id";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/VXLAN port:\s+(\d+)/is) {
         $cmd = "net-vdl2 -S -r -s $vdsname -n $vdl2id -p $1";
         $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

         if ($result->{rc} != 0) {
            $vdLogger->Error("Failed to run command: $cmd".
                             Dumper($result));
            VDSetLastError("ESTAF");
            return FAILURE;
         }

         if ($result->{stdout} eq "") {
            $vdLogger->Debug("Output correct: no output");
         } else {
            $vdLogger->Error("Output incorrect: $result->{stdout}");
            $err++;
         }

         $cmd = "net-vdl2 -S -s $vdsname -n $vdl2id -p $1";
         $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

         if ($result->{rc} != 0) {
            $vdLogger->Error("Failed to run command: $cmd".
                             Dumper($result));
            VDSetLastError("ESTAF");
            return FAILURE;
         }

         if ($result->{stdout} =~ m/tx.total:\s+0.*rx.total:\s+0/is) {
            $vdLogger->Debug("Output correct: no output");
         } else {
            $vdLogger->Error("Output incorrect: $result->{stdout}");
            $err++;
         }

      } else {
         $vdLogger->Error("Couldn't get an active port id: $result->{stdout}");
         $err++;
      }

   }

   #15. net-vdl2 -r stats -s vds -I IP

   if ($checkall == 1 or $netvdl2cmd =~ m/-S.*-r.*-i/is) {
      $cmd = "net-vdl2 -S -r -s $vdsname -i $vmkip";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} eq "") {
         $vdLogger->Debug("Output correct: no output");
      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }

      $cmd = "net-vdl2 -S -s $vdsname -i $vmkip";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/tx.total:\s+0.*rx.total:\s+0/is) {
         $vdLogger->Debug("Reset succeeded: $result->{stdout}");
      } else {
         $vdLogger->Error("Reset failed: $result->{stdout}");
         $err++;
      }
   }

   #16. net-vdl2 -r stats -s vds -k vmknicName

   if ($checkall == 1 or $netvdl2cmd =~ m/-S.*-r.*-k/is) {
      $cmd = "net-vdl2 -S -r -s $vdsname -k $vmkid";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} eq "") {
         $vdLogger->Debug("Output correct: no output");
      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }

      $cmd = "net-vdl2 -S -s $vdsname -k $vmkid";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/tx.total:\s+0.*rx.total:\s+0/is) {
         $vdLogger->Debug("Reset succeeded: $result->{stdout}");
      } else {
         $vdLogger->Error("Reset failed: $result->{stdout}");
         $err++;
      }
   }

   #17. net-vdl2 -r stats -s vds -V vlanID

   if ($checkall == 1 or $netvdl2cmd =~ m/-S.*-r.*-V/is) {
      $cmd = "net-vdl2 -S -r -s $vdsname";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} eq "") {
         $vdLogger->Debug("Output correct: no output");
      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }

      $cmd = "net-vdl2 -S -s $vdsname";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/tx.vxlanTotal:\s+0.*rx.vxlanTotal:\s+0/is) {
         $vdLogger->Debug("Reset succeeded: $result->{stdout}");
      } else {
         $vdLogger->Error("Reset failed: $result->{stdout}");
         $err++;
      }
   }

   #18. net-vdl2 -h

   if ($checkall == 1 or $netvdl2cmd =~ m/-h/is) {
      $cmd = "net-vdl2 -h";
      $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);

      if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }

      if ($result->{stdout} =~ m/Usage:\s+net-vdl2/is) {
         $vdLogger->Debug("Output correct: $result->{stdout}");
      } else {
         $vdLogger->Error("Output incorrect: $result->{stdout}");
         $err++;
      }
   }

   if ($err == 0) {
      $vdLogger->Debug("net-vdl2 testing passed!");
      return SUCCESS;
   } else {
      VDSetLastError("EFAIL");
      return FAILURE;
   }

}


########################################################################
#
# SetVpxdMACScheme --
#     Method to configure the MAC schema in VC Option Manager
#                                              -> Advance settings.
#
# Input:
#      mac_allocschema  - possible MAC address schemas i.e. prefix,range.
#      mac_range   - values of MAC address information with '-' seperator.
#
# Results:
#     "SUCCESS", if the  successfully
#     "FAILURE", in case of any error.
#
# Side effects:
#     None.
#
########################################################################

sub SetVpxdMACScheme
{
   my $self        = shift;
   my $options     = shift;
   my $allocschema = $options->{'mac_allocschema'};
   my $parameters  = $options->{mac_range};
   my $inlineOptionMgr = $self->GetInlineOptionManager();

   if (not defined $allocschema || not defined $parameters) {
        $vdLogger->Error("Schema or Parameters is not defined");
        VDSetLastError("ENOTDEF");
   }

   my @keys;
   my @values;
   # Putting keys as per the scheme in array.
   if ($allocschema eq 'prefix') {
      @values=split("-",$parameters);
      push(@keys,"config.vpxd.macAllocScheme.prefixScheme.prefix");
      push(@keys,"config.vpxd.macAllocScheme.prefixScheme.prefixLength");
   } elsif ($allocschema eq 'range') {
      my $i=0;
      @values=split("-",$parameters);
      while(defined $values[$i]) {
         push(@keys,
            "config.vpxd.macAllocScheme.rangeScheme.range[". $i/2 ."].begin");
         push(@keys,
            "config.vpxd.macAllocScheme.rangeScheme.range[". $i/2 ."].end");
         $i=$i+2;
      }
   } else {
      $vdLogger->Warn("MAC Scheme is not supported in VC. Supported Schemes are ".
                      "prefix and range.");
      VDSetLastError("ENOTSUP");
      return FAILURE;
   }

   # Updating the keys on VC one by one.
   my $i=0;
   while(defined $keys[$i]){
      $values[$i] = join("",split(":",$values[$i]));

      $vdLogger->Info("Updating key $keys[$i] with value $values[$i] on VC");
      if (0 == $inlineOptionMgr->UpdateVPXDConfigValue($keys[$i], $values[$i])){
        VDSetLastError("EINVALIDERR");
        return FAILURE;
      }
      $vdLogger->Info("Validating updated Key Value pair on VC.");
      if ($values[$i] ne $inlineOptionMgr->GetVPXDConfigValue($keys[$i])) {
        $vdLogger->Error("Validation of key $keys[$i] with value $values[$i] ".
                         "is failed");
        VDSetLastError("EMISMATCH");
        return FAILURE;
      }

      $i++;
   }

   $vdLogger->Info("Successfully set the MAC Address Scheme on VC.");
   return SUCCESS;
}


########################################################################
#
# EnableRollback --
#     Method to enable the mgmt. n/w rollback feature in VC.
#
#
# Input:
#      None.
#
#
# Results:
#     "SUCCESS", if the  successfully
#     "FAILURE", in case of any error.
#
# Side effects:
#     None.
#
########################################################################

sub EnableRollback
{
   my $self = shift;
   my $inlineOptionMgr = $self->GetInlineOptionManager();
   my $result;

   $result = $inlineOptionMgr->GetVPXDConfigValue('config.vpxd.network.rollback');
   if ($result =~ m/true/i) {
     return SUCCESS;
   } else {
      $result = $inlineOptionMgr->UpdateVPXDConfigValue('config.vpxd.network.rollback', 'true');
      if (0 == $result) {
        VDSetLastError("EINVALIDERR");
        return FAILURE;
      }
   }

   $vdLogger->Info("Successfully enabled the mgmt. n/w rollback on VC.");
   return SUCCESS;
}


########################################################################
#
# SetVDL2StatsLevel --
#     Method to set vdl2 statistic level
#
# Input:
#      host  - Traget host.
#      cmdtype   - command type: esxcli or netvdl2.
#      statslevel - stats level value
#
# Results:
#     "SUCCESS", if the  successfully
#     "FAILURE", in case of any error.
#
# Side effects:
#     None.
#
########################################################################

sub SetVDL2StatsLevel
{
   my $self          = shift;
   my $args          = shift;
   my $host          = $args->{host};
   my $cmdtype       = $args->{cmdtype};
   my $statslevel    = $args->{statslevel};
   my $cmd;
   my $result;

   if ($cmdtype =~ /esxcli/i) {
     $cmd = "esxcli network vswitch dvs vmware vxlan config stats set --level=$statslevel";
     $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);
     if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
     }

     #Check the esxcli command set statistic level
     $cmd = "esxcli network vswitch dvs vmware vxlan config stats get";
     $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);
     if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
     }
     if ($result->{stdout} !~ /Level: $statslevel/is) {
         $vdLogger->Error("Output Error: $result->{stdout}");
         return FAILURE;
     }
   }
   if ($cmdtype =~ /netvdl2/i) {
     $cmd = "net-vdl2 -L stats $statslevel";
     $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);
     if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
     }

     #Check the net-vdl2 command set statistic level
     $cmd = "net-vdl2 -L stats";
     $result = $self->{stafHelper}->STAFSyncProcess($host, $cmd);
     if ($result->{rc} != 0) {
         $vdLogger->Error("Failed to run command: $cmd".
                          Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
     }
     if ($result->{stdout} !~ /Statistics level: $statslevel/is) {
         $vdLogger->Error("Output Error: $result->{stdout}");
         return FAILURE;
     }
   }
   return SUCCESS;
}


###############################################################################
#
# GetProfileInfo --
#      This method to get all information about a host subprofile as an object
#
# Input:
#      profile           -   hostprofile name
#      subprofile        -   Parameter to specify a subprofile.
#                            Allowed values are: NetworkProfile
#                                                |StorageProfile
#                                                |ServiceProfile
#                                                |FirewallProfile
#                                                |DateTime
#                                                |UserProfile
#                                                |SecurityProfile
#                                                |License
#                                                |HostMemoryProfile
#                                                |UserGroupProfile
#                                                |OptionProfile
#                                                |SystemCacheProfile
# Results:
#      Returns subprofile info if success.
#      Returns failure, if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub GetProfileInfo
{
   my $self         = shift;
   my $profile      = shift; # mandatory
   my $subprofile   = shift; # mandatory
   my $proxy        = $self->{proxy};
   my $result;
   my $command;

   if (not defined $profile) {
      $vdLogger->Error("host profile name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $subprofile) {
      $vdLogger->Error("subprofile name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   $command = " GETPROFILEINFO  anchor $self->{hostAnchor} profile " .
              " \"$profile\" subprofile \"$subprofile\" ";
   $vdLogger->Debug("STAF command: $command");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy,$command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Fail to associate host profile" .  Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }
   $vdLogger->Debug("Return result" . Dumper($result->{result}));
   return $result->{result};
}


###############################################################################
#
# GetNetworkPolicyInfo --
#      This method to get network profile policies information
#
# Input:
#      profile           -   hostprofile name
#      networkcategory   -   Parameter to specify network profile category
#      subcategory       -   Parameter to specify subcategory in the network
#                            profile policies
#      networkpolicy     -   Parameter to specify network policy name
#      networkdevicename -   Parameter to specify network device name such
#                            as vSwitch0, VM Network
# Results:
#      Returns network policy info if success.
#      Returns failure, if any error occured.
#
# Side effects:
#      None.
#
###############################################################################

sub GetNetworkPolicyInfo
{
   my $self              = shift;
   my %opts              = @_;
   my $profile           = $opts{'profile'};          # mandatory
   my $networkcategory   = $opts{'networkcategory'};  # mandatory
   my $subcategory       = $opts{'subcategory'};      # optional
   my $networkpolicy     = $opts{'networkpolicy'};    # optional
   my $networkdevicename = $opts{'networkdevicename'};# optional
   my $proxy             = $self->{proxy};
   my $result;
   my $command;

   if (not defined $profile) {
      $vdLogger->Error("host profile name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   if (not defined $networkcategory) {
      $vdLogger->Error("networkcategory name not provided");
      VDSetLastError("EINVALID");
      return FAILURE;
   }
   $command = " GETNETWORKPOLICYINFO  anchor $self->{hostAnchor} profile ".
              " \"$profile\" networkcategory \"$networkcategory\" ";

   if (defined $subcategory) {
      $command = $command . " subcategory \"$subcategory\" ";
   }
   if (defined $networkpolicy) {
      $command = $command . " networkpolicy  \"$networkpolicy\" ";
   }
   if (defined $networkdevicename) {
      $command = $command . " networkdevicename \"$networkdevicename\" ";
   }
   $vdLogger->Debug("STAF command: $command");
   $result = $self->{stafHelper}->STAFSubmitHostCommand($proxy, $command);
   if ($result->{rc} != 0) {
      $vdLogger->Error("Fail to getnetworkpolicyinfo " .  Dumper($result));
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   $vdLogger->Debug("Return result" . Dumper($result));
   return $result->{result};
}

###############################################################################
#
# CheckVXLANInnerMAC --
#      This method will check the VXLAN Inner MAC.
#
# Input:
#      VLXNAID           : VNI number
#      refArrayObjVnic   : reference to an array of vnic objects
#      refArrayObjSwitch : reference to an array of switch objects
#      refArrayObjHost   : reference to an array of host objects
#
# Results:
#      "SUCCESS", if the check MAC address is successfull.
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#
###############################################################################

sub CheckVXLANInnerMAC
{
   my $self              = shift;
   my $vxlanid           = shift;
   my $refArrayObjVnic   = shift;
   my $refArrayObjSwitch = shift;
   my $refArrayObjHost   = shift;
   my $result;
   my $output;
   my $finalMatch;

   if ((not defined $vxlanid) || (not defined $refArrayObjVnic)
      || (not defined $refArrayObjSwitch) || (not defined $refArrayObjHost)) {
      $vdLogger->Error("Either vxlanid or refArrayObjVnic/refArrayObjSwitch/"
                       . " refArrayObjHost is not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
   my $vdsname;
   my $switchObj = $refArrayObjSwitch->[0];
   my $hostObj = $refArrayObjHost->[0];
   if (defined $switchObj->{'switch'}) {
      $vdsname = $switchObj->{'switch'};
   } elsif (defined $switchObj->{'name'}) {
      $vdsname = $switchObj->{'name'};
   }
   my $hostIP = $hostObj->{hostIP};
   foreach my $vnicObj (@$refArrayObjVnic) {
      $finalMatch = "false";
      my $matchCount = 0;
      my $macAddress = $vnicObj->{macAddress};
      my $command = "esxcli --formatter=csv --format-param=show-header=false "
                ."--format-param=fields=InnerMAC network vswitch dvs vmware "
                ."vxlan network mapping list --vds-name $vdsname --vxlan-id $vxlanid";

      $result = $self->{stafHelper}->STAFSyncProcess($hostIP,$command);
      if (($result->{rc} != 0) || ($result->{exitCode} != 0)){
         $vdLogger->Error("STAF command failed: \$command=$command " .
                       Dumper($result));
         VDSetLastError("ESTAF");
         return FAILURE;
      }
      $output = $result->{stdout};
      #
      #The command list output show as below:
      #esxcli --formatter=csv --format-param=show-header=false
      # --format-param=fields=InnerMAC network vswitch dvs
      # vmware vxlan network mapping list --vds-name dvs1 --vxlan-id 1
      #00:50:56:b9:98:47,
      #00:0c:29:37:9f:25,
      #
      my @macArray = split(/\n/,$output);
      foreach my $addr (@macArray) {
         #remove ',' for each mac address
         $addr =~s/,//;
         if ($macAddress =~ m/$addr/is) {
            $matchCount++;
         }
      }
      if ($matchCount == 1) {
         $vdLogger->Info("Find test VNIC MAC address in VXLAN MAC mapping table");
         $finalMatch = "true";
      }
   }
   if ($finalMatch =~ m/false/is) {
      $vdLogger->Error("Maybe some one test VNIC MAC address Not in VXLAN MAC mapping table");
      VDSetLastError("EMISMATCH");
      return FAILURE;
   }
   $vdLogger->Info("All of test VNIC MAC address can be found in VXLAN MAC mapping table");
   return SUCCESS;
}


########################################################################
#
# GetInlineVCSession --
#     Method to create an instance of
#     VDNetLib::InlineJava::SessionManager based on VC parameters
#
# Input:
#     None
#
# Results:
#     return value of new() in VDNetLib::InlineJava::SessionManager
#
# Side effects:
#     None
#
########################################################################

sub GetInlineVCSession
{
   my $self = shift;
   return VDNetLib::InlineJava::SessionManager->new($self->{vcaddr},
                                                    $self->{user},
                                                    $self->{passwd}
                                                   );
}


########################################################################
#
# GetInlineOptionManager --
#     Method to get an instance of VDNetLib::InlineJava::OptionManager
#     based on the this VC object
#
# Input:
#     inlineVCSession : reference to an object of
#                       VDNetLib::InlineJava::SessionManager (Optional)
#
# Results:
#     return value of new() in VDNetLib::InlineJava::SessionManager
#
# Side effects:
#     None
#
########################################################################

sub GetInlineOptionManager
{
   my $self = shift;
   my $inlineVCSession = shift || $self->GetInlineVCSession();
   return VDNetLib::InlineJava::OptionManager->new(
                                       'sessionObj' => $inlineVCSession);

}


########################################################################
#
# GetInlineFolder --
#     Method to create an instance of VDNetLib::InlineJava::Folder
#
# Input:
#     inlineVCSession : reference to an object of
#                       VDNetLib::InlineJava::SessionManager (Optional)
#
# Results:
#     return value of new() in VDNetLib::InlineJava::Folder
#
# Side effects:
#     None
#
########################################################################

sub GetInlineFolder
{
   my $self = shift;
   my $inlineVCSession = shift || $self->GetInlineVCSession();
   return VDNetLib::InlineJava::Folder->new(
      'anchor' => $inlineVCSession->{'anchor'});

}


########################################################################
#
# CreateDVPortgroup
#      This method creates the dv portgroup for the vds.
#
#
# Input:
#      DVPORTGROUP : Name of the dvportgroup.if specifies pg11-15 it would
#                    create 5 dvportgroups - pg11,pg12, pg13, pg14, pg15.
#
# Results:
#      "SUCCESS", if switch port gets disabled
#      "FAILURE", in case of any error,
#
# Side effects:
#      the dv portgroup gets created for the vds.
#########################################################################

sub CreateDVPortgroup
{
   my $self = shift;
   my $arrayOfSpecs = shift;
   my (@arrayOfPGObjects);
   my $count = "1";
   foreach my $element (@$arrayOfSpecs) {
      if (ref($element) !~ /HASH/) {
         $vdLogger->Error("DVPortgroup spec not in hash form");
         VDSetLastError("EOPFAILED");
         return FAILURE;
      }
      my %options = %$element;
      my $dvportgroup = $options{name};
      my $nrp         = $options{nrp};
      my $ports       = $options{ports};
      my $switchObj   = $options{vds};
      $switchObj      = $switchObj->{'switchObj'};
      my $pgType      = $options{binding} || "earlyBinding";
      my $autoExpand  = $options{autoExpand} || "true";

      $vdLogger->Debug("Dump of Args" . Dumper(%options));

      my $tag = "VDSwitch : CreateDVPortgroup :";
      my $anchor = undef;
      my $cmd = undef;
      my $proxy = $self->{proxy};
      my $dvPortgroupObj;
      my $result;
      my @dvpgs;

      if (not defined $dvportgroup) {
         $dvportgroup = VDNetLib::Common::Utilities::GenerateName("dvpg",$count);
      }

      # Get the anchor
      $anchor = $switchObj->GetAnchor(SERVICE => "setup");
      if ($anchor eq FAILURE) {
         return FAILURE;
      }

      #
      # In case the dvportgroup name was given as "pg23-100"
      # Add support for creating a bunch of dvpgs in a single workload.
      #

      if ($dvportgroup =~ m/^([^\-]+[a-zA-Z])(\d+)-(\d+)$/) {
         for (my $i=$2; $i<=$3; $i++) {
            push(@dvpgs,$1.$i);
         }
      } else {
         push(@dvpgs,$dvportgroup);
      }

      my $inlineVCSession = $self->GetInlineVCSession();
      $result = $inlineVCSession->LoginVC();
      if (!$result) {
         $vdLogger->Error("Failed to login VC $self->{vcaddr}");
         VDSetLastError("EINLINE");
         return FAILURE;
      }

      my $inlineDVS  = $switchObj->GetInlineDVS();
      $result = $inlineDVS->AddPG(
                            DVPGTYPE   => $pgType,
                            DVPGNAMES  => \@dvpgs,
                            PORTS      => $ports,
                            AUTOEXPAND => $autoExpand);

      if (!$result) {
         $vdLogger->Error("Failed to create dvportgroup for vDS $switchObj->{switch}");
         VDSetLastError("EINLINE");
         return FAILURE;
      }
      $vdLogger->Info("Created dvportgroup for vDS $switchObj->{switch}");

      # create dvportgroup object.
      for (my $i = 0; $i < scalar(@dvpgs); $i++) {
         my $dvpg = $dvpgs[$i];
         $dvPortgroupObj = new VDNetLib::Switch::VDSwitch::DVPortGroup(
                                                           DVPGName => $dvpg,
                                                           switchObj => $switchObj,
                                                           stafHelper => $switchObj->{stafHelper}
                                                           #TODO: Pass inline PGObj/pgMor
                                                           );
         if ($dvPortgroupObj eq FAILURE) {
            $vdLogger->Error("$tag Failed to create dv portgroup object");
            VDSetLastError("EOPFAILED");
            return FAILURE;
         }
         if (defined $nrp){
            $cmd = "editdvportgroup anchor $anchor dvportgroupname $dvpg".
                   " dvsname $switchObj->{switch} setnwrespool $nrp";
            $vdLogger->Info("Run STAF command : $cmd");
            $result = $switchObj->{stafHelper}->STAFSubmitSetupCommand($proxy, $cmd);
            if ($result->{rc} != 0) {
               $vdLogger->Error("$tag Failed to attach portgroup $dvpg ".
                             "with nrp $nrp");
               $vdLogger->Error(Dumper($result));
               VDSetLastError("EOPFAILED");
               return FAILURE;
            }
            $vdLogger->Info("Attached DVPG($dvpg) with NRP ($nrp)");
         }
         push (@arrayOfPGObjects,$dvPortgroupObj)
      }
      $count++;
   }
   return \@arrayOfPGObjects;
}


########################################################################
#
# RegisterAutodeployInVC --
#     To register AutoDeploy with the vCenter
#
# Input:
#     vcvaIP: vcva IP address
#
# Results:
#
# Side effects:
#     None
#
########################################################################

sub RegisterAutodeployInVC
{
   my $self = shift;

   my $vcvaIP = $self->{vcaddr};
   my $output;

   if (not defined $vcvaIP) {
      $vdLogger->Error("vcva IP not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $sshVCVA = VDNetLib::Common::SshHost->new($vcvaIP, "root", "vmware");
   unless ($sshVCVA) {
       $vdLogger->Error("Failed to establish a SSH session with " . $vcvaIP );
       VDSetLastError("EOPFAILED");
       return FAILURE;
   }
   my $CMD_REGISTER_VC = "/usr/bin/autodeploy-register -R -f -p 80 " .
                         "-u root -w vmware -a $vcvaIP";
   # issue command to run at vcva
   my $cmd = join (";", (CMD_VMWARE_RBD_WATCHDOG_STOP,
                         $CMD_REGISTER_VC,
                         CMD_VMWARE_RBD_WATCHDOG_START,
                         CMD_ATFTPD_START) );

   (undef, $output) = $sshVCVA->SshCommand($cmd);
   $vdLogger->Debug("Register AutoDeploy with vCenter output " . join ("\n", @$output));
   return SUCCESS;
}


########################################################################
#
# UpdateAutoDeployServer --
#     To update AutoDeploy server IP address
#
# Input:
#      tramp: tramp path for autodeploy
#      username: user name
#      password: password
#
# Results:
#
#     Returns "SUCCESS", if success.
#     Returns "FAILURE", in case of any error.
#
# Side effects:
#     None
#
########################################################################

sub UpdateAutoDeployServer
{
   my $self = shift;
   my %args = @_;

   my $tramp    = $args{configurenextserver};
   my $username = $args{username};
   my $password = $args{password};

   if( (not defined $tramp) || (not defined $username) ||
                               (not defined $password) ) {
     $vdLogger->Error("tramp path, username or password  not provided");
     VDSetLastError("ENOTDEF");
     return FAILURE;
   }
   my $nextserver = $self->{vcaddr};
   my $server = VDNetLib::Common::GlobalConfig::NIMBUS_GATEWAY;
   my $output;
   my $rc;

   if (not defined $nextserver) {
      $vdLogger->Error("Next Server not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   my $sshVCVA = VDNetLib::Common::SshHost->new($server,
       $username,$password);
   unless ($sshVCVA) {
       $vdLogger->Error("Failed to establish a SSH session with " . $server );
       VDSetLastError("EOPFAILED");
       return FAILURE;
   }

   my $CMD_IPXE = '/bin/echo ' . "\"#!ipxe\"" . " > " . $tramp;
   my $CMD_FILENAME = '/bin/echo ' .
      "\"set filename https://$nextserver:6502/vmw/rbd/tramp\"" . " >> " . $tramp;
   my $CMD_CHAIN = '/bin/echo ' .
      "\"chain https://$nextserver:6502/vmw/rbd/tramp\"" . " >> " . $tramp;

   $vdLogger->Info("1: $CMD_IPXE");
   $vdLogger->Info("2: $CMD_FILENAME");
   $vdLogger->Info("3: $CMD_CHAIN");
   # issue command to run at nimbus-gateway
   my $cmd = join (";", ($CMD_IPXE,
                         $CMD_FILENAME,
                         $CMD_CHAIN) );

   ($rc, $output) = $sshVCVA->SshCommand($cmd);
   if ($rc ne "0") {
      $vdLogger->Error("Failed to update AutoDeploy Server  " .
                       " in $nextserver");
      $vdLogger->Debug("ERROR:$rc " . Dumper($output));
      VDSetLastError("EOPFAILED");
      return FAILURE;
   }
   $vdLogger->Debug("Updated AutoDeploy Server $nextserver " . join ("\n", @$output));
   return SUCCESS;
}

########################################################################
#
# GetUUID --
#      Get UUID of VC
#
# Input:
#      None
#
# Results:
#      Returns UUID of the VC.
#
# Side effects:
#      None.
#
########################################################################

sub GetUUID
{
   my $self = shift;
   my $inlineVCSession = $self->GetInlineVCSession();
   return $inlineVCSession->GetUUID();
}


########################################################################
#
# Services --
#     Method to restart/stop/start specified VC services;
#
# Input:
#     operation - A value of restart/stop/start operation;
#                currently only 'restart' is supported.(required)
#     service   - A value of vpxd, datastore and other services type
#                currently only 'vpxd' is supported.(required)
#
# Results:
#     "SUCCESS", if the VC was successfully operated.
#     "FAILURE", in case of any error
#
# Side effects:
#     None.
#
########################################################################

sub Services
{
   my $self = shift;
   my %args      = @_;
   my $service   = $args{services};
   my $operation = $args{operation};

   my $supportOperation = {
      'restart'  => 'VCServiceRestart',
   };

   my $method = $supportOperation->{$operation};
   if (defined $method) {
      my $result = $self->$method($service);
      if ($result eq FAILURE) {
         $vdLogger->Error("Failed to $operation vc $service services");
         VDSetLastError("EINVALID");
         return FAILURE;
      }
   } else {
      $vdLogger->Error("$operation is not a legal state we can support now");
      VDSetLastError("EINVALID");
      return FAILURE;
   };

   return SUCCESS;
}


#############################################################################
#
# VCServiceRestart --
#     Restart the specified VC services.
#
# Input:
#     Service -  one type of vc services, like vpxd, datastore and so on,
#                currently only vpxd is supported (required)
#
# Results:
#     "SUCCESS", if the VC services was successfully restarted;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub VCServiceRestart
{
   my $self = shift;
   my $service = shift;

   if ($service eq "vpxd") {
      #
      # Create InlineJavaVC object corresponding to each object of this class
      #
      my $inlineVCSession = $self->GetInlineVCSession();

      if (!$inlineVCSession) {
         $vdLogger->Error("Failed to create VDNetLib::InlineJava::SessionManager " .
                          "object");
         VDSetLastError("EINLINE");
         return FAILURE;
      }

      if (!$inlineVCSession->RestartVpxdServices()) {
         $vdLogger->Error("Failed to restart vc vpx services");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $vdLogger->Error("restart $service services is not support yet");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return SUCCESS;
}


#############################################################################
#
# ConfigureLicense --
#     All license key based operations in VC for any product/feature/entity
#
# Input:
#     license: operation to be performed on VC Inventory
#
# Results:
#     "SUCCESS", if the license operation is successful;
#     "FAILURE", in case of any error
#
# Side effects:
#     None
#
#############################################################################

sub ConfigureLicense
{
   my $self = shift;
   my %args      = @_;
   my $operation = $args{license};

   my $supportOperation = {
      'add'       => 'AddLicenseKey',
      'assign'    => 'AssignLicenseToEntity',
   };

   #
   # Create InlineJavaVC object corresponding to each object of this class
   #
   my $inlineVCSession = $self->GetInlineVCSession();
   if (!$inlineVCSession) {
      $vdLogger->Error("Failed to create VDNetLib::InlineJava::SessionManager " .
                       "object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   my $method = $supportOperation->{$operation};
   if (defined $method) {
      my $result = $inlineVCSession->$method(%args);
      if (!$result) {
         $vdLogger->Error("Failed to $operation license to VC");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   } else {
      $vdLogger->Error("$operation is not support");
      VDSetLastError("EINVALID");
      return FAILURE;
   };

   $vdLogger->Info("Successfully $operation"."ed license in VC");
   return SUCCESS;
}


#############################################################################
#
# GetThumbprint --
#     Get VC thumbprint.
#
# Input:
#     None
#
# Results:
#     Returns VC thumbprint
#
# Side effects:
#     None
#
#############################################################################

sub GetThumbprint
{
   my $self = shift;
   my $inlineVCSession = $self->GetInlineVCSession();

   if (!$inlineVCSession) {
      $vdLogger->Error("Failed to create VDNetLib::InlineJava::SessionManager " .
                       "object");
      VDSetLastError("EINLINE");
      return FAILURE;
   }

   my $result = $inlineVCSession->GetThumbprint();
   if (!$result) {
      $vdLogger->Error("Failed to get VC thumbprint");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $result;
}

1;
