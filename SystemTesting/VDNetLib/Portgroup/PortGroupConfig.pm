########################################################################
#  Copyright (C) 2010 VMware, Inc.                                     
#  All Rights Reserved                                                 
########################################################################

package VDNetLib::PortGroupConfig;

#
# This package, PortGroupConfig, allows to retrieve all port group
# related attributes and execute operations on portgroups in a ESX machine.
#                                                                      

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";

use VDNetLib::Utilities;
use VDNetLib::STAFHelper;
use VDNetLib::GlobalConfig qw($vdLogger);
use Getopt::Long;
use VDNetLib::HostOperations;
use VDNetLib::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);

my $debug = 0;


#######################################################################
#
# new --
#      This is entry point for this package to create an object of
#      VDNetLib::PortGroupConfig.
#
# Input:
#      A named parameter list, in other word a hash with following keys:
#      'pgName': name of the portgroup (Required)
#      'hostIP': IP address of the host on which the given portgroup
#                is present (Required)
#      'switch': name of the switch to which the given portgroup belongs
#                (Required)
#      'stafHelper': Reference to an object of VDNetLib::STAFHelper
#                    (Optional)
#      'hostOpsObj': Reference to an object of VDNetLib::HostOperations
#                    (Optional)
#      
# Results:
#      An object of VDNetLib::PortGroupConfig, if successful;
#      "FAILURE", in case of any error.
#
# Side effects:
#      None
#                                                            
#######################################################################

sub new {

    my $class      = shift;
    my %args       = @_;
    my $self;

    $self->{'hostIP'}  = $args{'hostip'};
    $self->{'pgName'} = $args{'pgName'};
    $self->{'pgType'} = $args{'pgType'};
    $self->{'switch'} = $args{'switch'};
    $self->{'stafHelper'} = $args{'stafHelper'};
    $self->{'hostOpsObj'} = $args{'hostOpsObj'};
    my $hostIP        = $args{'hostip'};

   if (not defined $self->{'pgName'} ||
       not defined $self->{'switch'} ||
       not defined $hostIP) {
      $vdLogger->Error("HostIP, portgroup name and/or its switch not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   bless($self);


   #
   # Create a VDNetLib::STAFHelper object with default parameters if it not
   # provided in the input parameters.
   #
   if (not defined $self->{stafHelper}) {
      my $options;
      $options->{logObj} = $vdLogger;
      my $temp = VDNetLib::STAFHelper->new($options);
      if (not defined $temp) {
         $vdLogger->Error("Failed to create VDNetLib::STAFHelper object");
         VDSetLastError("ETAF");
         return FAILURE;
      }
      $self->{stafHelper} = $temp;
   }

   # Find the type of the host i.e whether it is hosted or esx or vmkernel
   $self->{hostType} = VDNetLib::Common::Utilities::GetHostType($hostIP);
   if (not defined $self->{hostType} ||
      ($self->{hostType} !~ /esx/i && $self->{hostType} !~ /vmkernel/i)) {
      $vdLogger->Error("Unknown host type or type not supported");
      VDSetLastError("EOSNOTSUP");
      return FAILURE;
   }

   #
   # Create an object of HostOperations module (if not passed) to obtain
   # vSwitch names and port group names for verification purpose
   #
   if (not defined  $self->{hostOpsObj}) {
      $self->{hostOpsObj} = VDNetLib::HostOperations->new($hostIP);
        
      # Verify for correct Object return value for HostOperations module
      if (ref($self->{hostOpsObj}) ne "VDNetLib::HostOperations") {
         $vdLogger->Error("Invalid object returned from HostOperations Module");
         VDSetLastError(VDGetLastError());
         return FAILURE;
      }
   }

   # Check if portgroup is a valid entry.This step is important
   # to catch error, such as say portgroup object exists, but the
   # port group does not exist.Ex: Some one manually deleting the
   # portgroup while tests are running.
   my $res = $self->CheckPgroupExists("$self->{pgName}");
   if ($res eq "FAILURE" or $res == 0) {
      $vdLogger->Error("Invalid Port group Name supplied");
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }
   return $self;
}


#######################################################################
#
# GetPGProperties --
#      Method to get the properties like VLAN ID, switch name of 
#      portgroup object.
#
# Input:
#      None
#
# Results:
#      Reference to a hash with following key/values:
#      'switch' : name of portgroup object's switch
#      'vlan'   : vlan id configured on the portgroup object
#
# Side effects:
#      None
#
#######################################################################

sub GetPGProperties
{
   my $self = shift;
   my $pg = $self->{'pgName'};

   my $command = "LISTPORTGROUP ANCHOR $self->{hostOpsObj}{stafHostAnchor} " .
                 "HOST $self->{hostIP}";

   my $result = $self->{stafHelper}->STAFSubmitHostCommand("local",
                                                           $command);
   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }

   my $data = $result->{result};

   #
   # An example of format of data returned by above STAF command:
   # "[{VSwitch_Name=vSwitch0, PortGroup_Name=VM Network, vlan=0}, 
   #  {VSwitch_Name=vSwitch0, PortGroup_Name=Management Network, vlan=0},
   #  {VSwitch_Name=vSwitch1, PortGroup_Name=vdtest, vlan=0}]"
   #

   # Remove [, ], { and { with a space before
   $data =~ s/\[|\]|{|\s{//g;
   # Split the data from above with } or },
   my @temp = split(/},|}/,$data);

   my ($switch, $vlan);
   foreach my $set (@temp) {
      if ($set =~ /PortGroup_Name=$pg/) {
         if ($set =~ /VSwitch_Name=(.+),/i) {
            $switch = $1;
         }
         if ($set =~ /vlan=(.+)/i) {
            $vlan = $1;
         }
         last;
      }
   }
   my $properties;
   #
   # Store the properties of the portgroup in a hash and return the
   # reference to this hash.
   #
   $properties->{'switch'} = $switch;
   $properties->{'vlan'} = $vlan;
   return $properties;
}


#######################################################################
#
# SetPortGroupVLANID --
#      Method to configure the given VLAN ID on the portgroup object.
#
# Input:
#      vlanid: a valid VLAN ID to be configured on the portgroup
#              object (Required)
#              
# Results:
#      "SUCCESS", if the given the VLAN ID is configured successfully;
#      "FAILURE", in case of any error.
#
#######################################################################

sub SetPortGroupVLANID {
   my $self = shift;
   my $vlanid = shift;
   my $pgName = $self->{pgName};

   if (not defined $vlanid) {
      $vdLogger->Error("VLAN ID not provided");
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }

   # Execute STAF SDK command to configure VLAN ID
   my $command = "SETVLANID ANCHOR $self->{hostOpsObj}{stafHostAnchor} " .
                 "HOST $self->{hostIP} PORTGROUP \"$pgName\" VLANID $vlanid";
   my $result = $self->{stafHelper}->STAFSubmitHostCommand("local",
                                                           $command);
   if ($result->{rc} != 0) {
      VDSetLastError("ESTAF");
      return FAILURE;
   }
  
   #
   # Get the portgroup properties and verify the configured VLAN ID is
   # effective.
   #
   my $actualValue = $self->GetPGProperties();
   if ($actualValue eq FAILURE) {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($actualValue->{'vlan'} !~ $vlanid) {
      $vdLogger->Error("vSwitch MTU mismatch actual:$actualValue->{'vlan'} " . 
                       "requested:$vlanid");
      VDSetLastError("EMISTMATCH");
      return FAILURE;
   }
   return SUCCESS;
}


###########################################################
# Method Name: UpdateHash                                 #
#                                                         #
# Objective: To update the object hash with portgroup     #
#            parameters                                   #
#                                                         #
# Operation: Updates the object hash using esxcfg-vswitch #
#            -l command. Uses reg-exp and string ops to   #
#            update the hash. Also updates vmnames and    #
#            port group names                             #
#                                                         #
# input arguments: None                                   #
#                                                         #
# Output: None                                            #
#                                                         #
# Export Status: Not Exported                             #
###########################################################
sub UpdateHash {
    my $self = shift;
    my $pgName = "$self->{pgName}";

    # This method obtains all the information regarding the
    # portgroup only.
    if ($self->{hostType} eq "ESX") {

        # Check if portgroup is a valid entry.This step is important
        # to catch error, such as say portgroup object exists, but the
        # port group does not exist.Ex: Some one manually deleting the
        # portgroup while tests are running.
        if ($self->CheckPgroupExists("$pgName") eq "FAILURE" ||
            $self->CheckPgroupExists("$pgName") == 0) {
            print STDERR "Invalid Port group Name supplied\n";
            VDSetLastError("EINVALID");
            return FAILURE;
        }

        # run UpdateHash method from HostOperations module
        # and collect the vswitch info
        my $res = $self->{hostOpsObj}->UpdateHash();
        if (defined $res and $res eq "FAILURE") {
            print "Failed to update the hash for $pgName\n";
            VDSetLastError(VDGetLastError());
            return FAILURE;
        }

        $self->{$pgName}{name}    = $self->{hostOpsObj}->{$pgName}{name};
        $self->{$pgName}{vswitch} = $self->{hostOpsObj}->{$pgName}{vswitch};
        $self->{$pgName}{vlanid}  = $self->{hostOpsObj}->{$pgName}{vlanid};
        $self->{$pgName}{uplink}  = $self->{hostOpsObj}->{$pgName}{uplink};
        $self->{$pgName}{usedports} = $self->{hostOpsObj}->{$pgName}{usedport};

        # update the has with promiscuous status also
        if ($self->GetPortGroupProm()) {
           $self->{$pgName}{prom} = 1;
        } else {
           $self->{$pgName}{prom} = 0;
        }

    } else {
       # returning error for non-esx variant systems
       print STDERR "This operation is not supported on".
                    " non-ESX variant platforms\n";
       VDSetLastError("EINVALID");
       return FAILURE;
    }
}


###########################################################
# Method Name: GetVswitchforPgroup                        #
#                                                         #
# Objective: To get the vSwitch corresponding to the      #
#            port-group                                   #
#                                                         #
# Operation: Gets the vSwitch for a portgroup form the    #
#            object hash. Calls the UpdateHash method for #
#            getting latest info. However we can get the  #
#            vSwitch info without calling UpdateHash also #
#            but the validity of the data can not be      #
#            Gauranteed.                                  #
#                                                         #
# input arguments: None                                   #
#                                                         #
# Output: vSwitch name corresponding to port-group        #
#                                                         #
# Export Status: Not Exported                             #
###########################################################
sub GetVswitchforPgroup {
    my $self = shift;

    # This method is supported on ESX variants only
    if ($self->{hostType} eq "ESX") {

       my $pgName = "$self->{pgName}";

       # Check if portgroup is a valid entry.This step is important
       # to catch error, such as say portgroup object exists, but the
       # port group does not exist.Ex: Some one manually deleting the
       # portgroup while tests are running.
       if ($self->CheckPgroupExists("$pgName") eq "FAILURE" ||
           $self->CheckPgroupExists("$pgName") == 0) {
           print STDERR "Invalid Port group Name supplied\n";
           VDSetLastError("EINVALID");
           return FAILURE;
       }

       # Update the object hash to get the
       # latest parameters. Here vswitch info is
       # obtained for the port group for UpdateHash
       $self->UpdateHash();

       # return the vswitch for the given
       # portgroup name
       if (defined $self->{$pgName}{vswitch}) {
           return $self->{$pgName}{vswitch};
       } else {
           print STDERR "Failed to obtain the vswitch for given portgroup\n";
           VDSetLastError("EFAIL");
           return FAILURE;
       }
    } else {
       # returning error for non-esx variant systems
       print STDERR "This operation is not supported on".
                    " non-ESX variant platforms\n";
       VDSetLastError("EINVALID");
       return FAILURE;
    }
}



###########################################################
# Method Name: PortGroupAddUplink                         #
#                                                         #
# Objective: To add an uplink to port group               #
#                                                         #
# Operation: Adds the uplink given by adapter type to the #
#            Specified port group.Uses esxcfg-vswitch     #
#            command with options such as portgroup name  #
#            and adapter name.                            #
#                                                         #
# input arguments: uplink adapter name                    #
#                                                         #
# Output: 0 for successful operation                      #
#         1 for failure                                   #
#                                                         #
# Export Status: Exported                                 #
###########################################################
sub PortGroupAddUplink {
    my $self          = shift;
    my $uplinkAdapter = shift;
    my ($res, $data);

    # This method is supported on ESX variants only
    if ($self->{hostType} eq "ESX") {
       my $pgName = "'$self->{pgName}'";

       # Check if portgroup is a valid entry.This step is important
       # to catch error, such as say portgroup object exists, but the
       # port group does not exist.Ex: Some one manually deleting the
       # portgroup while tests are running.
       if ($self->CheckPgroupExists("$pgName") eq "FAILURE" ||
           $self->CheckPgroupExists("$pgName") == 0) {
           print STDERR "Invalid Port group Name supplied\n";
           VDSetLastError("EINVALID");
           return FAILURE;
       }

       # Get the vswitch for the given port group
       my $vswitch = $self->GetVswitchforPgroup($pgName);

       # Check for errors
       if ($vswitch eq "FAILURE") {
          print STDERR "Failed to get vSwitch for port group\n";
          VDSetLastError(VDGetLastError());
          return FAILURE;
       }

       # build the command for adding an uplink to the given portgroup
       my $command = "esxcfg-vswitch $vswitch -p $pgName -L $uplinkAdapter";
       $command = "start shell command $command wait".
                  " returnstderr returnstdout";
       ($res,$data) = $self->{stafHelper}->runStafCmd($self->{hostOpsObj}{hostIP},
                                                       "Process",
                                                       "$command");

       if ($res eq "FAILURE") {
          print STDERR "Failure to obtain vSwitch info in".
                       " PortGroupAddUplink\n";
          VDSetLastError("EFAIL");
          return FAILURE;
       }

       print "Result is (add uplink) $data\n" if $debug;

       # check for failure or success of the command
       if ($res eq "SUCCESS") {
          print "Successfully added the uplink to $pgName\n";
          return SUCCESS;
       } elsif ($data =~ m/ Uplink already exists: /i) {
          print STDERR "Failed to add uplink, Uplink".
                       " already exists for $pgName\n";
          VDSetLastError("EFAIL");
          return FAILURE;
       }
    } else {
       # returning error for non-esx variant systems
       print STDERR "This operation is not supported on".
                    " non-ESX variant platforms\n";
       VDSetLastError("EINVALID");
       return FAILURE;
    }
}

###########################################################
# Method Name: PortGroupAddVMKNic                         #
#                                                         #
# Objective: To add an vmknic to port group               #
#                                                         #
# Operation: Adds a vmknic to the port group mentioned    #
#            uses the esxcfg-vmknic command to do the task#
#            If IP address is given as a second argument  #
#            then expects the third argument as subnetmask#
#            and if ipaddress is given as "DHCP", then    #
#            assigns IP addresss to vmknic dynamically    #
#                                                         #
# input arguments: IP address to be assigned to vmknic or #
#                  DHCP                                   #
#                  subnetmask if IPaddress is != DHCP     #
#                                                         #
# Output: 0 for successful operation                      #
#         1 for failure                                   #
#         2 for invalid args                              #
#                                                         #
# Export Status: Exported                                 #
###########################################################
sub PortGroupAddVMKNic {
    my $self       = shift;
    my $ipaddress  = shift;
    my $subnetmask = shift;
    my $pgName     = "'$self->{pgName}'";

    my $command;
    my ($res,$data);

    # This method works on ESX variants only
    if ($self->{hostType} eq "ESX") {

       # Check if portgroup is a valid entry.This step is important
       # to catch error, such as say portgroup object exists, but the
       # port group does not exist.Ex: Some one manually deleting the
       # portgroup while tests are running.
       my $status = $self->CheckPgroupExists("$pgName");

       if ($self->CheckPgroupExists("$pgName") eq "FAILURE" ||
           $self->CheckPgroupExists("$pgName") == 0) {
           print STDERR "Invalid Port group Name supplied\n";
           VDSetLastError("EINVALID");
           return FAILURE;
       }

       # Check if IP address is defined and is a valid one
       if (defined $ipaddress and $ipaddress =~ m/[0-9]+/) {
           my $ret = VDNetLib::Utilities::IsValidIP($ipaddress);
           if ($ret eq "FAILURE") {
              print STDERR "Invalid IP passed as argument\n";
              VDSetLastError("EINVALID");
              return FAILURE;
           }

           # Check if subnetmask is defined and is a valid one
           if (defined $subnetmask) {
              # check for ipv4 subnetmask
              if ($subnetmask =~ m/[0-9.]+/) {
                 $ret = VDNetLib::Utilities::IsValidIP($subnetmask);
                 if ($ret eq "FAILURE") {
                    print STDERR "Invalid subnet mask passed as argument\n";
                    VDSetLastError("EINVALID");
                    return FAILURE;
                 }
              } elsif ($subnetmask !~ /\d+/) {
                 # check if subnetmask is of prepix length format
                 print STDERR "Invalid subnet mask passed as argument\n";
                 VDSetLastError("EINVALID");
                 return FAILURE;
              }

              # build the command
              $command = "-i $ipaddress -n $subnetmask";
           } else {
              print STDERR "INVALID Subnet mask passed\n";
              VDSetLastError("EINVALID");
              return FAILURE;
           }
       } elsif ($ipaddress =~ m/DHCP/i) {
           # check if ipaddress option is a DHCP
           $command = "-i DHCP";
       } else {
           print STDERR "INVALID ARGS\n";
           VDSetLastError("EINVALID");
           return FAILURE;
       }


       #Build a command for adding a vmknic to the portgroup
       $command = "esxcfg-vmknic -a $command $pgName";
       $command = "start shell command $command wait".
                  " returnstderr returnstdout";
       ($res,$data) = $self->{stafHelper}->runStafCmd($self->{hostOpsObj}{hostIP},
                                                       "Process",
                                                       "$command");

       # Check for failure while adding vmknic to portgroup
       if ($res eq "FAILURE") {
          print STDERR "Failure to obtain vSwitch info in PortGroupAddVMKNic\n";
          VDSetLastError("EFAIL");
          return FAILURE;
       }

       print "Command: $command *\n Result: $res *\n Data: $data\n" if $debug;

       # return Success on successful completion of the previous
       # command or else throw an error
       if ($data =~ m/Generated New MAC address/ or $data eq "") {
           print "Successfully added the vmknic to $pgName\n";
           return SUCCESS;
       } elsif ($data =~ m/A vmkernel nic for the connection
                         point already exists /i) {
          print STDERR "Failed to add vmknic, already exists on $pgName\n";
          VDSetLastError("EFAIL");
          return FAILURE;
       } else {
           print STDERR "Unknown error\n";
           VDSetLastError("EUNKNOWN");
           return FAILURE;
       }
    } else {
       # returning error for non-esx variant systems
       print STDERR "This operation is not supported on".
                    " non-ESX variant platforms\n";
       VDSetLastError("EINVALID");
       return FAILURE;
    }
}


###########################################################
# Method Name: PortGroupDeleteVMKNic                      #
#                                                         #
# Objective: To Delete a vmknic to port group             #
#                                                         #
# Operation: Deletes a vmknic from port group mentioned   #
#            uses the esxcfg-vmknic command to do the task#
#            Only accepts port group name to delete vmknic#
#                                                         #
# input arguments: None                                   #
#                                                         #
# Output: 0 for successful operation                      #
#         1 for failure                                   #
#                                                         #
# Export Status: Exported                                 #
###########################################################
sub PortGroupDeleteVMKNic {
    my $self   = shift;
    my $pgName = "'$self->{pgName}'";
    my ($res,$data);
    my $command;

    # This method works only on ESX variants
    if ($self->{hostType} eq "ESX") {

       # Check if portgroup is a valid entry.This step is important
       # to catch error, such as say portgroup object exists, but the
       # port group does not exist.Ex: Some one manually deleting the
       # portgroup while tests are running.
       if ($self->CheckPgroupExists("$pgName") eq "FAILURE" ||
           $self->CheckPgroupExists("$pgName") == 0) {
           print STDERR "Invalid Port group Name supplied\n";
           VDSetLastError("EINVALID");
           return FAILURE;
       }

       # build a command for deleting a vmknic from the portgroup
       $command = "esxcfg-vmknic -d -p $pgName";
       $command = "start shell command $command wait".
                  " returnstderr returnstdout";
       ($res,$data) = $self->{stafHelper}->runStafCmd($self->{hostOpsObj}{hostIP},
                                                       "Process",
                                                       "$command");

       # Check for failure and success of the previous command
       if ($res eq "FAILURE") {
          print STDERR "Failure to obtain vSwitch info in".
                       " PortGroupDeleteVMKNic\n";
          VDSetLastError("EFAIL");
          return FAILURE;
       }

       print "Command : $command *\n Result: $res *\n Data: $data*\n" if $debug;

       # Check if vmknic is successfully deleted
       if ($res eq "SUCCESS") {
           print "Successfully deleted the vmknic from $pgName\n";
           return SUCCESS;
       } elsif ($data =~ m/Error performing operation: There is no VMkernel/i) {
           print STDERR "Failed to delete vmknic, No vmknic connection point".
                        "exists for $pgName\n";
           VDSetLastError("EFAIL");
           return FAILURE;
       } else {
           print STDERR "Unknown error\n";
           VDSetLastError("EUNKNOWN");
           return FAILURE;
       }
    } else {
       # returning error for non-esx variant systems
       print STDERR "This operation is not supported on".
                    " non-ESX variant platforms\n";
       VDSetLastError("EINVALID");
       return FAILURE;
    }
}


###########################################################
# Method Name: PortGroupAddvNIC                           #
#                                                         #
# Objective: To add a vnic from a VM to the port group    #
#                                                         #
# Operation: This method uses the changevirtualnic command#
#            from staf vm service. This method adds a vnic#
#            to the port group, but makes sure that user  #
#            supplied info is correct, before going ahead #
#                                                         #
# Algorithm: 1. GetVMNames                                #
#            2. Get Nics of VMs                           #
#            3. Check if IP of the NIC supplied as arg    #
#               Matches with the vm's nics.If yes collect #
#               the vm name                               #
#            4. use vmstaf service add virtual nic using  #
#               the vmname and the portgroup name supplied#
#                                                         #
# input arguments: Nic name or IP address                 #
#                                                         #
# Output: None                                            #
#         Failure failure                                 #
#                                                         #
# Export Status: Exported                                 #
###########################################################
sub PortGroupAddvNIC {
    my $self      = shift;
    my $Nic_or_ip = shift;
    my $pgName    = "$self->{pgName}";
    my $vmNames;
    my $macaddr;
    my $adapter;
    my $command;
    my @datalines;
    my $vm;
    my @vmids;
    my ($res,$data);

    # This method is supported on ESX variants only
    if ($self->{hostType} eq "ESX") {

       # check if the arguments passed are valid
       if ($Nic_or_ip ne "") {

            # Check if portgroup is a valid entry.This step is important
            # to catch error, such as say portgroup object exists, but the
            # port group does not exist.Ex: Some one manually deleting the
            # portgroup while tests are running.
            if ($self->CheckPgroupExists("$pgName") eq "FAILURE" ||
               $self->CheckPgroupExists("$pgName") == 0) {
               print STDERR "Invalid Port group Name supplied\n";
               VDSetLastError("EINVALID");
               return FAILURE;
            }

            # Get All the VM names in the string format
            $res = $self->{hostOpsObj}->UpdateVMHash();
            # Check for failure of UpdateVMHash of HostOperations
            if ($res eq "FAILURE") {
                print STDERR "Failure to update HostOperations".
                             " hash in PortGroupAddvNIC\n";
                VDSetLastError(VDGetLastError());
                return FAILURE;
            }

            $vmNames = $self->{hostOpsObj}->{VMNames};
            @vmids   = split(/ /,$self->{hostOpsObj}->{VMIDS});
            if ($vmNames eq "FAILURE") {
               print STDERR "Failure to obtain VM names in PortGroupAddvNIC\n";
               VDSetLastError(VDGetLastError());
               return FAILURE;
            }

            # Check if the passed in parameter is a ip or
            # vnic name Ex:Nic_or_ip can have an ip address
            # or a label. The label looks like "Netwrok Adapter 3"
            if ($Nic_or_ip =~ m/[0-9.]+/) {
                # $Nic_or_ip passed is an IP address
                my @vms = split(/ /,$vmNames);
                @vms = grep /\S/, @vms;#remove empty elements
                $vm = "";

                @vmids = grep /\S/, @vmids;#remove empty elements

                # Check if the IP belongs to the VM from the contents
                # of the host operations object hash
                foreach my $vmnm (@vms) {
                   $command = "GETGUESTINFO anchor $self->{agent} vm $vmnm";
                   ($res,$data) = $self->{stafHelper}->runStafCmd("127.0.0.1",
                                                                   "vm",
                                                                   "$command");
                   if (defined $data and $data =~ /$Nic_or_ip/) {
                       $data =~ m/NIC (\d+) IP Address: $Nic_or_ip/g;
                       my $label = $1;
                       $data =~ m/NIC $label MAC Address: (.*)/g;
                       $macaddr = $1;
                       $vm = $vmnm;
                       last;
                   }
                }

                if ($vm eq "" or $macaddr eq "") {
                    print STDERR "Failed to obtain vmname or mac address in ".
                                 "PortGroupAddvNIC as $Nic_or_ip is not".
                                 " connected to any VM\n";
                    VDSetLastError("EFAIL");
                    return FAILURE;
                }


                # This command will provide vmnic info for the given
                # VM. The output of the following command will look like
                # as given below:
                #
                # VM NETWORK 1
                # ADAPTER CLASS: VirtualE1000
                # PortGroup: VM Network
                # NETWORK: VM Network
                # MACADDRESS: 00:0c:29:2a:33:8f
                # Label: Network adapter 1
                #
                # VM NETWORK 2
                # ADAPTER CLASS: VirtualE1000
                # PortGroup: data
                # NETWORK: data
                # MACADDRESS: 00:0c:29:2a:33:99
                # Label: Network adapter 2
                #
                # VM NETWORK 3
                # ADAPTER CLASS: VirtualVmxnet2
                # PortGroup: data
                # NETWORK: data
                # MACADDRESS: 00:0c:29:2a:33:a3
                # Label: Network adapter 3
                #
                # VM NETWORK 4
                # ADAPTER CLASS: VirtualVmxnet3
                # PortGroup: data
                # NETWORK: data
                # MACADDRESS: 00:0c:29:2a:33:ad
                # Label: Network adapter 4
                #
                # And we need the label here to add a vnic to the portgroup
                #
                $command = "vmnicinfo anchor $self->{hostOpsObj}{hostIP} vm $vm";
                ($res,$data) = $self->{stafHelper}->runStafCmd("127.0.0.1",
                                                                "vm",
                                                                "$command");


                # Check for Success or failure of the previous
                # command
                if ($res ne "FAILURE") {
                   my @lines = split(/\n/, $data);
                   my $length = @lines;
                   # if the previous command is successful, get the
                   # label for the adapter
                   for (my $i=0; $i < $length; $i++) {
                      if ($lines[$i] =~ m/$macaddr/) {
                         if ($lines[$i+1] =~ m/Label: (.*)/) {
                            $Nic_or_ip = $1;
                         }
                      }
                   }
                } else {
                   print STDERR "Failed to obtain the guestinfo".
                                " in PortGroupAddvNIC\n";
                   VDSetLastError("EFAIL");
                   return FAILURE;
                }
            } else {
                # Check if the Network adapter label is provided
                # instead of IP. If not throw and invalid input error
                if (not $Nic_or_ip =~ m/Network adapter [0-9]+/) {
                   print STDERR "INVALID Network label supplied".
                                "Ex: Network adapter 3";
                   VDSetLastError("EINVALID");
                   return FAILURE;
                }
            }

            # Build the command for adding the vnic to a portgroup using the
            # network label obtained from the previous step. The Network label
            # is stored in $Nic_or_ip variable
            $command = "changevirtualnic anchor $self->{agent} vm $vm".
                       " virtualnic_name";
            $command = "$command". " \"$Nic_or_ip\" pgname \"$pgName\"";
            ($res,$data) = $self->{stafHelper}->runStafCmd("127.0.0.1",
                                                            "vm",
                                                            "$command");

            # Check for Success or failure of the previous command in
            # adding an vnic to the portgroup
            if ($res ne "FAILURE") {
               print "Successfully added vnic to portgroup\n";
               return SUCCESS;
            } elsif ($res eq "FAILURE" and $data eq "0") {
               print "Successfully added vnic to portgroup\n";
               return SUCCESS;
            } else {
               print STDERR "Failed to add vnic to port group\n";
               VDSetLastError("EFAIL");
               return FAILURE;
            }
       } else {
           print STDERR "Invalid args....returning\n";
           VDSetLastError("EINVALID");
           return FAILURE;
       }
    } else {
       # returning error for non-esx variant systems
       print STDERR "This operation is not supported on".
                    " non-ESX variant platforms\n";
       VDSetLastError("EINVALID");
       return FAILURE;
    }
}


###########################################################
# Method Name: PortGroupDeleteUplink                      #
#                                                         #
# Objective: To delete an uplink to port group            #
#                                                         #
# Operation: Deletes the uplink given by adapter type from#
#            Specified port group.Uses esxcfg-vswitch     #
#            command with options such as portgroup name  #
#            and adapter name.                            #
#                                                         #
# input arguments: Uplink Adapter Name                    #
#                                                         #
# Output: 0 for successful operation                      #
#         1 for failure                                   #
#                                                         #
# Export Status: Exported                                 #
###########################################################
sub PortGroupDeleteUplink {
    my $self          = shift;
    my $uplinkAdapter = shift;
    my $pgName     = "'$self->{pgName}'";
    my $command;
    my ($res, $data);

    # This method works on ESX variants
    if ($self->{hostType} eq "ESX") {

       # Check if portgroup is a valid entry.This step is important
       # to catch error, such as say portgroup object exists, but the
       # port group does not exist.Ex: Some one manually deleting the
       # portgroup while tests are running.
       if ($self->CheckPgroupExists("$pgName") eq "FAILURE" ||
           $self->CheckPgroupExists("$pgName") == 0) {
           print STDERR "Invalid Port group Name supplied\n";
           VDSetLastError("EINVALID");
           return FAILURE;
       }

       my $vswitch = $self->GetVswitchforPgroup($pgName);

       if ($vswitch eq "FAILURE") {
          print STDERR "Failed to get vSwitch for port group\n";
          VDSetLastError(VDGetLastError());
          return FAILURE;
       }

       # Build the command for deleting the Uplink from port group
       $command = "esxcfg-vswitch $vswitch -p $pgName -U $uplinkAdapter";
       $command = "start shell command $command wait returnstderr returnstdout";
       ($res,$data) = $self->{stafHelper}->runStafCmd($self->{hostOpsObj}{hostIP},
                                                       "Process",
                                                       "$command");


       # Check for failures
       if ($res eq "FAILURE") {
          print STDERR "Failure to obtain vSwitch info in".
                       " PortGroupDeleteUplink\n";
          VDSetLastError("EFAIL");
          return FAILURE;
       }

       # Check for successful unlinking of uplink adapter
       # to the portgroup
       if ($data eq "") {
          print "Successfully deleted the uplink from $pgName\n";
          return SUCCESS;
       } elsif ($data =~ m/Removing from config file only/i) {
          print STDERR "Failed to delete uplink from $pgName and $vswitch\n";
          VDSetLastError("EFAIL");
          return FAILURE;
       }
    } else {
       # returning error for non-esx variant systems
       print STDERR "This operation is not supported on".
                    " non-ESX variant platforms\n";
       VDSetLastError("EINVALID");
       return FAILURE;
    }
}



###########################################################
# Method Name: SetPortGroupProm                           #
#                                                         #
# Objective: To enable promiscous mode on a port group    #
#                                                         #
# Operation: uses vim-cmd hostsvc sub command is to set   #
#            the promiscous mode on a port group          #
#                                                         #
# input arguments: None                                   #
#                                                         #
# Output: 0 on Success                                    #
#         1 on Failure                                    #
#                                                         #
# Export Status: Exported                                 #
###########################################################
sub SetPortGroupProm {
    my $self = shift;
    my $pgName = "'$self->{pgName}'";
    my $command;
    my ($res, $data);

    # This method works on ESX variants
    if ($self->{hostType} eq "ESX") {

        # Check if portgroup is a valid entry.This step is important
        # to catch error, such as say portgroup object exists, but the
        # port group does not exist.Ex: Some one manually deleting the
        # portgroup while tests are running.
        if ($self->CheckPgroupExists("$pgName") eq "FAILURE" ||
            $self->CheckPgroupExists("$pgName") == 0) {
            print STDERR "Invalid Port group Name supplied\n";
            VDSetLastError("EINVALID");
            return FAILURE;
        }


        # build the command to set the promiscuous mode of portgroup
        $command = "vsish -e set ".
               "vmkModules/etherswitch/PortCfgs/$pgName/l2secPolicy/options 0";
        $command = "start shell command $command".
                   " wait returnstderr returnstdout";
       ($res,$data) = $self->{stafHelper}->runStafCmd($self->{hostOpsObj}{hostIP},
                                                       "Process",
                                                       "$command");

        # Check for statuts of the command
        if ($res eq "FAILURE") {
           print STDERR "Failure to execute $command on $self->{hostOpsObj}{hostIP}\n";
           VDSetLastError("EFAIL");
           return FAILURE;
       }

       # Cross check the result using GetPortGroupProm method
       $res = $self->GetPortGroupProm();
       if ($self->GetPortGroupProm()) {
          print "Successful to set Portgroup $pgName to promiscous mode\n";
          return SUCCESS;
       } else {
          print STDERR "Failed to set promiscous mode on $pgName\n";
          VDSetLastError("EFAIL");
          return FAILURE;
       }
    } else {
       # returning error for non-esx variant systems
       print STDERR "This operation is not supported on".
                    " non-ESX variant platforms\n";
       VDSetLastError("EINVALID");
       return FAILURE;
    }
}


###########################################################
# Method Name: CheckPgroupExists                          #
#                                                         #
# Objective: To Check if a given portgroup exists         #
#                                                         #
# Operation: uses esxcfg-vswitch command to checl if a    #
#            given portGroup exists                       #
#                                                         #
# input arguments: Port Group Name                        #
#                                                         #
# Output: 1 if portgroup exists                           #
#         0 if portgroup does not exist                   #
#         Failure on failure                              #
###########################################################

sub CheckPgroupExists {
    my $self   = shift;
    my $pgName = shift;
    my $command;
    my ($res,$data);

       if (defined $pgName) {
          # Build the command to check if portGroup Exists
          # The esxcfg-vswitch -C <pgroup-name> returns 1
          # if portgroup exists or 0 if it does not exists
          $command = "esxcfg-vswitch -C '$pgName'";
          $command = "start shell command $command wait".
                     " returnstderr returnstdout";

          ($res,$data) = $self->{stafHelper}->runStafCmd($self->{hostOpsObj}{hostIP},
                                                         "Process",
                                                         "$command");
          # Check for the status of the previous operation
          if ($res eq "FAILURE") {
              print STDERR "Failure to execute $command on".
                           " $self->{hostOpsObj}{hostIP}\n";
              VDSetLastError("EFAIL");
          } else {
              print STDOUT "Portgroup existsance status is $data\n", if $debug;
              return $data;
          }
       } else {
          print STDERR "Please pass Portgroup name to this method\n";
          VDSetLastError("EINVALID");
          return FAILURE;
       }
}

1;
