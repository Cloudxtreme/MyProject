/*
 * Copyright 2005-2014 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package com.vmware.vcqa;

import java.io.File;
import java.net.URL;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.GregorianCalendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.apache.commons.configuration.Configuration;
import org.apache.commons.configuration.ConfigurationException;
import org.apache.commons.configuration.PropertiesConfiguration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.FloppyImageFileQuery;
import com.vmware.vc.FolderFileQuery;
import com.vmware.vc.HostConfigChangeMode;
import com.vmware.vc.HostConfigChangeOperation;
import com.vmware.vc.IsoImageFileQuery;
import com.vmware.vc.ParaVirtualSCSIController;
import com.vmware.vc.ParaVirtualSCSIControllerOption;
import com.vmware.vc.TemplateConfigFileQuery;
import com.vmware.vc.VirtualAHCIController;
import com.vmware.vc.VirtualBusLogicController;
import com.vmware.vc.VirtualBusLogicControllerOption;
import com.vmware.vc.VirtualCdrom;
import com.vmware.vc.VirtualCdromAtapiBackingInfo;
import com.vmware.vc.VirtualCdromPassthroughBackingInfo;
import com.vmware.vc.VirtualDevice;
import com.vmware.vc.VirtualDeviceDeviceBackingInfo;
import com.vmware.vc.VirtualDisk;
import com.vmware.vc.VirtualE1000;
import com.vmware.vc.VirtualE1000E;
import com.vmware.vc.VirtualEnsoniq1371;
import com.vmware.vc.VirtualEnsoniq1371Option;
import com.vmware.vc.VirtualEthernetCardOption;
import com.vmware.vc.VirtualFloppy;
import com.vmware.vc.VirtualFloppyDeviceBackingInfo;
import com.vmware.vc.VirtualFloppyOption;
import com.vmware.vc.VirtualHdAudioCard;
import com.vmware.vc.VirtualHdAudioCardOption;
import com.vmware.vc.VirtualIDEController;
import com.vmware.vc.VirtualIDEControllerOption;
import com.vmware.vc.VirtualKeyboard;
import com.vmware.vc.VirtualLsiLogicController;
import com.vmware.vc.VirtualLsiLogicControllerOption;
import com.vmware.vc.VirtualLsiLogicSASController;
import com.vmware.vc.VirtualLsiLogicSASControllerOption;
import com.vmware.vc.VirtualMachineRelocateDiskMoveOptions;
import com.vmware.vc.VirtualMachineVMCIDevice;
import com.vmware.vc.VirtualMachineVMIROM;
import com.vmware.vc.VirtualMachineVideoCard;
import com.vmware.vc.VirtualPCIController;
import com.vmware.vc.VirtualPCIControllerOption;
import com.vmware.vc.VirtualPCIPassthrough;
import com.vmware.vc.VirtualPCNet32;
import com.vmware.vc.VirtualPS2Controller;
import com.vmware.vc.VirtualPS2ControllerOption;
import com.vmware.vc.VirtualParallelPort;
import com.vmware.vc.VirtualParallelPortDeviceBackingInfo;
import com.vmware.vc.VirtualParallelPortOption;
import com.vmware.vc.VirtualPointingDevice;
import com.vmware.vc.VirtualSCSIController;
import com.vmware.vc.VirtualSCSIControllerOption;
import com.vmware.vc.VirtualSCSIPassthrough;
import com.vmware.vc.VirtualSCSIPassthroughOption;
import com.vmware.vc.VirtualSCSISharing;
import com.vmware.vc.VirtualSIOController;
import com.vmware.vc.VirtualSIOControllerOption;
import com.vmware.vc.VirtualSerialPort;
import com.vmware.vc.VirtualSerialPortDeviceBackingInfo;
import com.vmware.vc.VirtualSerialPortOption;
import com.vmware.vc.VirtualSoundBlaster16;
import com.vmware.vc.VirtualSoundBlaster16Option;
import com.vmware.vc.VirtualSriovEthernetCard;
import com.vmware.vc.VirtualUSB;
import com.vmware.vc.VirtualUSBController;
import com.vmware.vc.VirtualUSBControllerOption;
import com.vmware.vc.VirtualUSBUSBBackingInfo;
import com.vmware.vc.VirtualUSBXHCIController;
import com.vmware.vc.VirtualUSBXHCIControllerOption;
import com.vmware.vc.VirtualVmxnet;
import com.vmware.vc.VirtualVmxnet2;
import com.vmware.vc.VirtualVmxnet3;
import com.vmware.vc.VmConfigFileQuery;
import com.vmware.vc.VmDiskFileQuery;
import com.vmware.vc.VmLogFileQuery;
import com.vmware.vc.VmNvramFileQuery;
import com.vmware.vc.VmSnapshotFileQuery;
import com.vmware.vcqa.execution.TestDataHandler;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.vsan.helpers.VsanDataParser.ProfileSource;

/**
 * Test Constants encapsulates all the generic tests constants.
 */
public class TestConstants
{
   private static final Logger log = LoggerFactory
                                            .getLogger(TestConstants.class);

   private TestConstants()
   {
   }

   /*
    * ========= public static final constants should go here ===================
    */
   public static final String       HYPHEN                            = "-";
   public static final int          ONE_DISK                          = 1;
   public static final int          TWO_DISK                          = 2;

   public static final boolean      SYS_ALERT_ENABLED;
   public static final boolean      LOG_COLLECTION_ENABLED;
   public static final boolean      LOG_COLLECTION_PARALLEL;
   public static final String       LOG_COLLECTION_NFS;
   public static final boolean      RUNLIST_FILTER_ENABLED;
   public static final String       RUNLIST_FILTER_IGNORE_LIST;
   public static final boolean      CHECK_PROPERTIES;
   public static final boolean      CAPTURE_VM_LOGS;
   public static final List<String> OPERATIONS_IGNORED_FOR_OPID_LOGGING;
   public static final boolean      TESTINPUT_DONOT_CHECK_FOR_INFRA_HOSTNAME;

   /*
    * Size Conversions
    */
   public static final int          ONE_GB_IN_MB                      = 1024;
   public static final int          ONE_TB_IN_MB                      = 1048576;
   public static final int          TWO_TB_IN_GB                      = 2048;

   /*
    * ConnectAnchor socket timeout is set to 60 mins.
    */
   public static final int          SOCKET_TIMEOUT;
   public static final int          BAIL_OUT_PERIOD_FOR_EXCEPTION     = 2 * 60 * 1000;
   public static final long         STAF_SERVICE_VIM_SESSION_TIMEOUT  = 26 * 60 * 1000;
   public static final long         NO_OF_KB_PER_MB                   = 1024;
   public static final long         ONE_MB                            = 1024 * 1024;
   public static final int          MAX_SESSION_COUNT                 = 100;
   /*
    * WaitForUpdateEx maxWaitSeconds is set to 30 mins by default.
    */
   public static final int          WAIT_FOR_UPDATE_MAX_SEC;
   public static final int          WAIT_FOR_UPDATE_MAX_TRY           = 3;

   /*
    * TestAnalysis related.
    */
   public static final boolean      TEST_ANALYSIS_ENABLED;
   public static final boolean      VM_LOG_COLLECTION_ENABLED;

   public static final int          NUMBER_OF_CONTROLLER              = 4;
   public static final int          MAX_DISKS_PER_CONTROLLER          = 254;
   public static final int          SNAPSHOT_MAX_DISKS_PER_CONTROLLER = 46;
   public static final int          SNAPSHOT_MAX_DISKS                = SNAPSHOT_MAX_DISKS_PER_CONTROLLER
                                                                               * NUMBER_OF_CONTROLLER;
   public static final int          TOTAL_MAX_DISKS                   = MAX_DISKS_PER_CONTROLLER
                                                                               * NUMBER_OF_CONTROLLER;
   public static final int          DISKS_PER_IDE_CONTROLLER          = 1;
   public static final int          DEFAULT_NUMBER_DISKS              = 15;

   public static final int MAX_SCSI_CONTROLLERS = 4;
   public static final int MAX_SCSI_DISKS_PER_CONTROLLER = 15;
   public static final int MAX_SCSI_DISKS = MAX_SCSI_CONTROLLERS * MAX_SCSI_DISKS_PER_CONTROLLER;
   public static final int MAX_SNAPSHOTS = 31;

   public static final String                     TASK_UPDATE_INTERVAL_IN_SEC                           = "TASK_UPDATE_INTERVAL";
   /**
    * Constants for HPQC
    */
   public static final boolean      QC_RESULTS_POSTING;

   /*
    * constant flag for RM StorageIo Execution
    */
   public static final boolean      VMFS_STORAGEIO_TEST_EXECUTION;

   /*
    * Constants for network address types
    */
   public static enum NETWORK_ADDRESS_TYPE {
      IPV4_ADDRESS, IPV6_ADDRESS
   };

   /*
    * Enum for virtual machine disk type.
    */
   public static enum VmDiskType {
      THIN("thin"), //
      THICK_EAGER("thickEager"), // VirtualDiskType.EAGER_ZEROED_THICK
      THICK_LAZY("thickLazy"), // VirtualDiskType.PREALLOCATED
      RDM("rdm"), //
      SE_SPARSE("seSparse"), //
      ;
      private final String        diskType;
      private static final String validTypes;
      static {
         StringBuffer sb = new StringBuffer();
         for (VmDiskType type : VmDiskType.values()) {
            sb.append(type.diskType).append(" ");
         }
         validTypes = sb.toString();
      }

      private VmDiskType(String diskType)
      {
         this.diskType = diskType;
      }

      public String getDiskType()
      {
         return diskType;
      }

      public static VmDiskType fromValue(String value)
      {
         for (VmDiskType vmDiskType : VmDiskType.values()) {
            if (vmDiskType.diskType.equals(value)) {
               return vmDiskType;
            }
         }
         throw new IllegalArgumentException(value + ". valid values: "
                  + validTypes);
      }
   }

   /**
    * Enum of VC node type used in vasa xml file
    *
    */
   public static enum VC_DEPLOYMENT_TYPE {
      EMBEDDED, MANAGEMENT, INFRASTRUCTURE,
   };

   /*
    * Remove this constant once bug#167031 is fixed
    */

   /*
    * Parallel TestingFramework Constants
    */
   public static final long         GET_INVENTORY_WAIT_TIME                              = 300;
   public static final int          GET_INVENTORY_ATTEMPT                                = 5;
   public static final String       PARALLEL_ENABLED_FIELD                               = "ENABLED";
   public static final String       PARALLEL_DISABLED_FIELD                              = "DISABLED";
   public static final String       INVENTORY_XML                                        = "runlists\\VC\\Java\\vim30\\Inventory.xml";
   public static final long         INVENTORYCLEANUP_SLEEP                               = 5000;
   public static final long         DEFAULT_INVENTORY_CLEANUP_TIME                       = 1800000;

   public static final long         USB_LOCKER_MAX_CAPACITY                              = 2147483548;

   /*
    * Axis properties to allow all certificates
    */
   public static final String       USER_AGENT                                           = "USER-AGENT";
   public static final String       MAX_CONNECTIONS                                      = "maxConnections";
   public static final String       AXIS_SSL_FACTORY_PROPERTY                            = "axis.socketSecureFactory";
   public static final String       FAKE_SSL_SOCKETFACTORY                               = "org.apache.axis.components.net.SunFakeTrustSocketFactory";
   public static final String       AXIS_PROXYHOST                                       = "https.proxyHost";
   public static final String       AXIS_PROXYPORT                                       = "https.proxyPort";
   public static final String       PROXY_PORT                                           = "80";
   public static final String       TUNNEL_PORT                                          = "8089";
   public static final String       KEYSTORE_TYPE                                        = "pkcs12";
   public static final String       KEYSTORE_PASSWORD                                    = "swordfish";

   public static final String       BASE_USER_AGENT                                      = "Others";
   public static final String       CORE_USER_AGENT                                      = "http://www.vmware.com/download/eula/esx_server.html";
   public static final String       FOUNDATION_USER_AGENT                                = "VMware";
   public static final String       VCONLY_USER_AGENT                                    = "VCOnly";

   public static final String       ESXBASIC_STANDALONE_SERIAL                           = "N06RC-N7HEQ-06Y7R-1U1DM-AWCPX";
   public static final String       ESXSERVER_EDITION_BASIC                              = "esxBasic";

   public static final String[]     LICENSE_SERVERS                                      = {
            "license-1.eng.vmware.com", "license-2.eng.vmware.com"                      };
   public static final String[]     HARDWARE_VIRTUALIZATION_GUESTS                       = {
            "OS/2", "IBM OS/2"                                                          };
   public static final String       ALL_USER_AGENT_LIST[]                                = {
            BASE_USER_AGENT, CORE_USER_AGENT, FOUNDATION_USER_AGENT,
            VCONLY_USER_AGENT                                                           };
   public static final String       MGMT_RESTRICTIONS_RESTRICTED_OPERATIONS[]            = {
            "datastores.configure",
            "hostconf.filemanager.*",
            "folder.createvm",
            "folder.moveinto",
            "folder.registervm",
            "folder.unregistervm",
            "folder.destroyvm",
            "hostops.queryconnectinfo",
            "hostops.updatesystemresources",
            "hostops.reconnecthost",
            "hostops.disconnecthost",
            "hostops.entermaintenancemode",
            "hostops.exitmaintenancemode",
            "hostops.reboothost",
            "hostops.shutdownhost",
            "hostops.enterstandbymode",
            "hostops.exitstandbymode",
            "hostops.reocnfiguredas",
            "hostops.updateflags",
            "hostops.sendwakeonlanpacket",
            "hostops.disableadmin",
            "hostops.enableadmin",
            "hostops.updatemanagementserverip",
            "hostops.acqurecimserviceticket",
            "entityops.destroy",
            "entityops.rename",
            "network.destroy",
            "virtualdiskmanager.create",
            "virtualdiskmanager.delete",
            "virtualdiskmanager.queryvirtualdiskdefragmentation",
            "virtualdiskmanager.zerofilled",
            "virtualdiskmanager.queryUuid",
            "virtualdiskmanager.queryvirtualdiskgeometry",
            "vmops.reconfigvm",
            "vmops.upgradevirtualhardware",
            "vmops.poweroff",
            "vmops.poweron",
            "vmops.suspend",
            "vmops.reset",
            "vmops.shutdownguest",
            "vmops.standbyguest",
            "vmops.answervm",
            "vmops.unregistervm",
            "vmops.requestguestinformation",
            "vmops.mounttoolsinstaller",
            "vmops.unmounttoolsinstaller",
            "vmops.upgradetools",
            "vmops.acquiremksticket",
            "vmops.setscreenresolution",
            "hostconf.autostartmanager.reconfigure",
            "hostconf.autostartmanager.autopoweron",
            "hostconf.autostartmanager.autopoweroff",
            "hostconf.bootdevicesystem.updatebootdevice",
            "hostconf.cpuschedulersystem.enablehyperthreading",
            "hostconf.cpuschedulersystem.disablehyperthreading",
            "hostconf.dastorebrowsersystem.deletefile",
            "hostconf.datastoresystem.updatelocalswapdatastore",
            "hostconf.datastoresystem.createvmfsdatastore",
            "hostconf.datastoresystem.extendvmfsdatastore",
            "hostconf.datastoresystem.createnasdatastore",
            "hostconf.datastoresystem.createlocaldatastore",
            "hostconf.datastoresystem.removedatastore",
            "hostconf.datastoresystem.configuredatastoreprincipal",
            "hostconf.diagnosticsystem.selectactivepartition",
            "hostconf.diagnosticsystem.creatediagnosticpartition",
            "hostconf.firewallsystem.updatedefaultpolicy",
            "hostconf.firewallsystem.enableruleset",
            "hostconf.firewallsystem.disableruleset",
            "hostconf.memorymanagersystem.reconfigureserviceconsolereservation",
            "hostconf.memorymanagersystem.reconfigurevirtualmachinereservation",
            "hostconf.networksystem.updatenetworkconfig",
            "hostconf.networksystem.updatednsconfig",
            "hostconf.networksystem.updateiprouteconfig",
            "hostconf.networksystem.addvirtualswitch",
            "hostconf.networksystem.removevirtualswitch",
            "hostconf.networksystem.updatevirtualswitch",
            "hostconf.networksystem.addportgroup",
            "hostconf.networksystem.removeportgroup",
            "hostconf.networksystem.updateportgroup",
            "hostconf.networksystem.updatephysicallinkspeed",
            "hostconf.networksystem.addvirtualnic",
            "hostconf.networksystem.removevirtualnic",
            "hostconf.networksystem.updatevirtualnic",
            "hostconf.networksystem.addserviceconsolevirtualnic",
            "hostconf.networksystem.removeserviceconsolevirtualnic",
            "hostconf.networksystem.updateserviceconsolevirtualnic",
            "hostconf.networksystem.restartserviceconsolevirtualnic",
            "hostconf.servicesystem.updatepolicy",
            "hostconf.servicesystem.start",
            "hostconf.servicesystem.stop",
            "hostconf.servicesystem.restart",
            "hostconf.servicesystem.uninstall",
            "hostconf.snmpsystem.reconfiguresnmpagent",
            "hostconf.storagesystem.computediskpartitioninfo",
            "hostconf.storagesystem.updatediskpartisions",
            "hostconf.storagesystem.formatvmfs",
            "hostconf.storagesystem.rescanvmfs",
            "hostconf.storagesystem.attachvmfsextent",
            "hostconf.storagesystem.upgradevmfs",
            "hostconf.storagesystem.upgradevmlayout",
            "hostconf.storagesystem.rescanhba",
            "hostconf.storagesystem.rescanallhba",
            "hostconf.storagesystem.updatesoftwareinternetscsienabled",
            "hostconf.storagesystem.updateinternetscsidiscoveryproperties",
            "hostconf.storagesystem.updateinternetscsiauthenticationproperties",
            "hostconf.storagesystem.updateinternetscsiproperties",
            "hostconf.storagesystem.updateinternetscsiname",
            "hostconf.storagesystem.updateinternetscsialias",
            "hostconf.storagesystem.addinternetscsisendtargets",
            "hostconf.storagesystem.removeinternetscsisendtargets",
            "hostconf.storagesystem.addinternetscsistatictargets",
            "hostconf.storagesystem.removeinternetscsistatictargets",
            "hostconf.storagesystem.enablemultipathpath",
            "hostconf.storagesystem.disablemultipathpath",
            "hostconf.storagesystem.setmultipathlunpolicy",
            "hostconf.storagesystem.refresh",
            "hostconf.vmotionsystem.updateipconfig",
            "hostconf.vmotionsystem.selectvnic",
            "hostconf.vmotionsystem.deselectvnic",
            "vim.option.optionmanager.updatevalues"                                     };
   public static final String       MGMT_RESTRICTIONS_DENIED_OPERATIONS[]                = {
            "folder.moveinto", "resourcepool.updateconfig",
            "resourcepool.moveinto",
            "resourcepool.updatechildresourceconfiguration",
            "resourcepool.createresourcepool", "resourcepool.destroychildren",
            "virtualdiskmanager.copyvirtualdisk",
            "virtualdiskmanager.degragmentvirtualdisk",
            "virtualdiskmanager.extendvirtualdisk",
            "virtualdiskmanager.inflatevirtualdisk",
            "virtualdiskmanager.movevirutaldisk",
            "virtualdiskmanager.setvirtualdiskuuid",
            "virtualdiskmanager.shrinkvirtualdisk", "vmops.createsnapshot",
            "vmops.defragmentalldisks", "vmops.removeallsnapshots",
            "vmops.reverttocurrentsnapshot", "snapshot.remove",
            "snapshot.rename", "snapshot.revert"                                        };
   public static final String       FOUNDATION_USER_RSTRCT_OPER[]                        = { "" };

   public static final String       VMOPS_POWERON_OPERATION                              = "vmops.poweron";
   public static final String       AUTOSTARTMANAGER_RECONFIGURE_OPERATION               = "hostconf.autostartmanager.reconfigure";
   public static final String       NETWORKSYSTEM_ADDVIRTUALSWITCH_OPERATION             = "hostconf.networksystem.addvirtualswitch";
   public static final String       RESOURCEPOOL_CREATE_OPERATION                        = "resourcepool.createresourcepool";
   public static final String       VMOPS_POWEROFF_OPERATION                             = "vmops.poweroff";
   public static final String       VMOPS_RESET_OPERATION                                = "vmops.reset";
   public static final String       VMOPS_CREATE_SNAPSHOT_OPERATION                      = "vmops.createsnapshot";
   public static final String       VMOPS_REVERT_SNAPSHOT_OPERATION                      = "vmops.reverttocurrentsnapshot";
   public static final String       VMOPS_REMOVEALL_SNAPSHOTS_OPERATION                  = "vmops.removeallsnapshots";
   public static final int          VMOPS_HOT_PLUG_DELAY                                 = 30 * 1000;
   public static final String       HOT_PLUG_VM                                          = "Hot_Plug_VM";
   public static final String       HOT_PLUG_NOT_SUPPORTED_VM                            = "Hot_Plug_NA_VM";
   public static final String       HOST_CONF_DATASTORE_PRINCIPAL_OPERATION              = "hostconf.datastoresystem.configuredatastoreprincipal";

   public static final String       HOST_OS_WINDOWS                                      = "WINDOWS";
   public static final String       HOST_OS_LINUX                                        = "LINUX";

   public static final int          DALI_CFG_VERSION                                     = 8;
   public static final int          NON_DALI_CFG_VERSION                                 = 6;
   public static final String       ESX_USERNAME;
   public static final String       ESX_PASSWORD;
   public static final String       SERVER_WIN_USERNAME                                  = "Administrator";
   public static final String       SERVER_WIN_PASSWORD                                  = "ca$hc0w";
   public static final String       SERVER_LINUX_USERNAME                                = "root";
   public static final String       SERVER_LINUX_PASSWORD                                = "vmware";
   public static final String       DEFAULT_LOCALE                                       = "en";
   public static final String       HARDWARE_64_BIT                                      = "64";
   public static final String       HARDWARE_32_BIT                                      = "32";
   /*
    * The default port to connect to the Server hosted on Windows
    */
   public static final int          SERVER_WIN_DEFAULT_PORT                              = 8333;

   /*
    * Local Directory path
    */
   public static final String       LOCAL_DIR                                            = "localDir";

   /*
    * Timezone constants for Linux
    */
   public static final String       CUSTOMIZATION_LINUX_TIMEZONE                         = "Europe/London";
   public static final String       CUSTOMIZATION_LINUX_DELETED_TIMEZONE                 = "Africa/Abidjan";
   public static final String       CUSTOMIZATION_LINUX_INVALID_TIMEZONE                 = "Invalid/Timezone";
   public static final Boolean      CUSTOMIZATION_LINUX_UTC                              = false;

   /*
    * Constants for vmxconfig filter for the default system rules
    */
   public static final String       ESX_SYSTEM_PASSWD_FILE                               = "/etc/passwd";
   public static final String       ESX_SYSTEM_NETWORK_CONFIG                            = "/sbin/ifconfig";
   public static final String       ESX_DEFAULT_SYSTEM_RULES_PATH                        = "/etc/vmware/";
   public static final String       ESX_DEFAULT_SYSTEM_RULES_FILE                        = "configrules";
   public static final String       ESX_TEMP_PATH                                        = "/etc/";
   public static final String       ESX_SYSTEM_PATH_1                                    = "[]/boot/";
   public static final String       ESX_SYSTEM_PATH_2                                    = "[]/initrd/";
   public static final String       ESX_SYSTEM_PATH_3                                    = "[]/home/";
   public static final String       ESX_SYSTEM_PATH_4                                    = "[]/bin/";
   public static final String       ESX_SYSTEM_PATH_5                                    = "[]/root/";
   public static final String       ESX_SYSTEM_PATH_6                                    = "[]/proc/";
   public static final String       ESX_SYSTEM_PATH_7                                    = "[]/usr/";
   public static final String       ESX_SYSTEM_PATH_8                                    = "[]/var/";
   public static final String       ESX_SYSTEM_PATH_9                                    = "[]/lib/";
   public static final String       ESX_FILE_PATH_1                                      = "/usr/bin/ftp";
   public static final String       ESX_FILE_PATH_2                                      = "/proc/partitions";
   public static final String       ESX_FILE_PATH_3                                      = "[]/boot/kernel.h";
   public static final String       ESX_FILE_PATH_4                                      = "[]/etc/inittab";
   public static final String       ESX_ROOT_DIR                                         = "[]/root";

   public static final String       ESX_LIB_FILE                                         = "[]/lib/testfile.la";
   public static final String       ESX_TMP_FILE                                         = "/tmp/vmkdump.log";
   public static final String       ESX_USR_FILE                                         = "[]/usr/bin/tclsh8.3";

   public static final String       ESXWINDOWS_OPT_DIR                                   = "[]/opt/";
   public static final String       ESXWINDOWS_DEV_DIR                                   = "/dev/";
   public static final String       ESXWINDOWS_BOOT_DIR                                  = "[]/boot/";
   public static final String       ESX_GSXLINUX_PATH_NAME1                              = "[]/tmp/";

   /**
    * Adding the username and password for mapping a network drive
    */

   public static final String       DRMQE_USER_DOMAIN_NAME                               = "VMWAREM";
   public static final String       DRMQE_USER_NAME                                      = "drmqe";
   public static final String       DRMQE_PASSWORD                                       = "Ca$hc0w2";

   /*
    * Constant for checking that roleid is invalid
    */
   public static final int          INVALID_ROLEID                                       = -9999;

   /*
    * Constant for invalid port used while adding host
    */
   public static final int          INVALID_PORT                                         = 1000;

   /*
    * Constant for introducing an invalid vmdk file
    */
   public static final String       INVALID_VMDK_FILE                                    = "mine.vmdk";

   /*
    * Constant for checking the 'level' of the cpuFeature for a 64 bit host
    */
   public static final int          HOST_64BIT_LEVEL_ID                                  = 0x80000001;

   /*
    * Constants for masking Nx flag from guest
    */
   public static final int          CPU_LEVEL_0x80000001                                 = 0x80000001;
   public static final String       EDX_NX_MASK                                          = "----:----:---0:----:----:----:----:----";
   public static final String       EDX_DEFAULT                                          = "----:----:----:----:----:----:----:----";

   /*
    * Constants for Stress Tests
    */
   public static final int          JUSTIFICATION_LENGTH                                 = 5;
   public static final char         JUSTIFICATION_PADDING                                = ' ';

   /*
    * Constants for reliable memory tests
    */
   public static final int          bytesToMb                                            = 1000000;
   public static final int          pageSizeInBytes                                      = 4096;
   public static final double       halfRelMem                                           = 0.5;
   public static final double       fullRelMem                                           = 1;
   public static final int          threadSleepAfterCmd                                  = 1000 * 3;
   public static final int          threadSleepAfterLicense                              = 1000 * 45;
   public static final String       errorType                                            = "error";
   public static final String       errorMessage                                         = "System is made aware of reliable memory, but it was not before.";
   public static final String       mpmSettingCmd                                        = "esxcli system settings kernel set -s fakeReliableMemMPN -v ";
   public static final String       licenseSettingCmd                                    = "vim-cmd vimsvc/license set ";
   public static final String       relMemLicense                                        = "HJ2RP-CF016-688C8-0A42M-AWAJ2";
   public static final String       anotherRelMemLicense                                 = "452R4-EFJ9H-P88J0-0940P-0MH46";
   public static final String       nonRelMemLicense                                     = "HN2T6-GX3E4-K814T-099K0-AW2J6";
   public static final String       anotherNonRelMemLicense                              = "HJ6R4-CXJ86-6894J-0T1H0-2WUJ2";

   /*
    * Constants for Modularity tests
    */
   // MOB TESTS
   public static final String       vcFileName                                           = "vpxd.cfg";
   public static final String       vcParentFilePath                                     = "/etc/vmware-vpx/";
   public static final String       vcFilePath                                           = "/etc/vmware-vpx/vpxd.cfg";
   public static final String       vcXPathToKey                                         = "/config/vpxd/enableDebugBrowse";
   public static final String       vcXPathToParent                                      = "/config/vpxd";
   public static final String       vcKeyName                                            = "enableDebugBrowse";
   public static final String       vcOptionKey                                          = "config.vpxd.enableDebugBrowse";
   public static final String       hostFileName                                         = "config.xml";
   public static final String       hostParentFilePath                                   = "/etc/vmware/hostd/";
   public static final String       hostFilePath                                         = "/etc/vmware/hostd/config.xml";
   public static final String       hostXPathToKey                                       = "/config/plugins/solo/enableMob";
   public static final String       hostXPathToParent                                    = "/config/plugins/solo";
   public static final String       hostKeyName                                          = "enableMob";
   public static final String       hostOptionKey                                        = "Config.HostAgent.plugins.solo.enableMob";
   // LOGIN TESTS
   public static final String       vcIssueOptionKey                                     = "etc.issue";
   public static final String       vcMotdOptionKey                                      = "etc.motd";
   public static final String       hostIssueOptionKey                                   = "Config.Etc.issue";
   public static final String       hostMotdOptionKey                                    = "Config.Etc.motd";
   public static final String       loginFilePath                                        = "/etc/";
   public static final String       issueFileName                                        = "issue";
   public static final String       motdFileName                                         = "motd";
   public static final String       RandomContent                                        = "Random";
   //
   public static final String       sysLogKeyName                                        = "vmsyslogd";

   /*
    * Constants for vMotion Error Recovery tests
    */
   public static final String       linuxVpxdCfgLocation                                 = "/etc/vmware-vpx/";
   public static final String       windowsVpxdCfgLocation                               = "C:\\ProgramData\\VMware\\cis\\cfg\\vmware-vpx\\";
   public static final String       vpxdCfgFileName                                      = "vpxd.cfg";
   // constants for clone stress tests
   public static final String       CLONE                                                = "clone";
   public static final String       CUSTOMIZE                                            = "customize";
   public static final String       CLONE_CUSTOMIZE                                      = "clonecustomize";
   public static final String       DEPLOY_TEMPLATE_CUSTOMIZE                            = "deploytemplatecustomize";

   /*
    * constants for NetworkSystem Related API's
    */
   public static final int          VSWITCH_PORTS                                        = 1;
   public static final int          VIRTUALSWITCH_MAXCOUNT                               = 31;
   public static final int          VIRTUALNIC_MAXCOUNT                                  = 128;
   public static final int          SERVICECONSOLEVIRTUALNIC_MAXCOUNT                    = 128;
   public static final String       YES                                                  = "Y";
   public static final String       NO                                                   = "N";
   public static final String       DISABLE                                              = "D";
   public static final int          NO_B_IN_KB                                           = 1024;
   public static final int          BitsPS_IN_KBitsPS                                    = 1000;
   public static final String       VSWITCH_NAME                                         = "vSwitchName";
   public static final String       VSWITCH_PNICS_KEY                                    = "vSwitchFreePnicKeys";
   public static final String       VSWITCH_PNIC_DEVICES                                 = "vSwitchFreePnicDevices";
   public static final String       DEFAULT_FAILURECRITERIA_CHECKSPEED                   = "minimum";
   public static final int          DEFAULT_FAILURECRITERIA_PERCENTAGE                   = 0;
   public static final int          DEFAULT_FAILURECRITERIA_SPEED                        = 10;
   public static final long         DEFAULT_PEAK_BAND_WIDTH                              = 102400;
   public static final long         DEFAULT_AVERAGE_BAND_WIDTH                           = 102400;
   public static final long         DEFAULT_BURST_SIZE                                   = 102400;
   public static final String       VDS                                                  = "vds";
   public static final String       VSS                                                  = "vss";
   public static final String       VDSPG                                                = "vdspg";
   public static final String       VDSPORT                                              = "vdsport";
   public static final String       VSSPGNAME                                            = "VM Network";
   public static final String       HOST_CONFIG_MEM_COMPRESSION_KEY                      = "Mem.MemZipEnable";
   public static final String       VM_CONFIG_MEM_COMPRESSION_KEY                        = "sched.mem.zip.enable";
   public static final String       HARDWARE_ACCELERATED_INIT                            = "HardwareAcceleratedInit";
   public static final String       HARDWARE_ACCELERATED_MOVE                            = "HardwareAcceleratedMove";
   /*
    * Constants for users and groups based on their roles Generic user or
    * generic group will be used for any other customized role created Common
    * passsword for logging
    */
   public static final String       ADMIN_USER                                           = "adminuser";
   public static final String       READONLY_USER                                        = "readuser";
   public static final String       NOACCESS_USER                                        = "noaccessuser";
   public static final String       VMADMIN_USER                                         = "vmadminuser";
   public static final String       DATACENTERADMIN_USER                                 = "dcadminuser";
   public static final String       VM_USER                                              = "vmuser";
   public static final String       VMPOWER_USER                                         = "vmpoweruser";
   public static final String       VMPROVIDER_USER                                      = "vmprouser";
   public static final String       GENERIC_USER                                         = "genericuser";
   public static final String       DVS_USER                                             = "dvsuser";
   public static final String       TEST_USER_1                                          = "testuser1";
   public static final String       TEST_USER_2                                          = "testuser2";

   public static final String       ADMIN_GROUP                                          = "admingroup";
   public static final String       READONLY_GROUP                                       = "readgroup";
   public static final String       NOACCESS_GROUP                                       = "noaccessgroup";
   public static final String       VMADMIN_GROUP                                        = "vmadmingroup";
   public static final String       DATACENTERADMIN_GROUP                                = "dcadmingroup";
   public static final String       VM_GROUP                                             = "vmgroup";
   public static final String       VMPOWER_GROUP                                        = "vmpowergroup";
   public static final String       VMPROVIDER_GROUP                                     = "vmprogroup";
   public static final String       GENERIC_GROUP                                        = "genericgroup";
   public static final String       DVS_GROUP                                            = "dvsgroup";
   /*
    * Password here should match the password given in scripts under
    * /testware/vc5x-testware/VC/src/tests/java/security/updateauthorizationrole
    */
   public static final String       PASSWORD                                             = "apifvt1$";

   /*
    * Constants pertaining to Platform Hardening feature.
    */
   public static final String       VM_DELEGATE_USER                                     = "vimuser";
   public static final String       VM_ROOT_USER                                         = "root";
   public static final String       TARGET_PRINCIPAL                                     = "vimuser";

   /*
    * Constant for a valid domain name on Windows
    */
   public static final String       WIN_DOMAIN_NAME                                      = "VMWAREM";

   /*
    * Constants for System Role Ids
    */
   public static final int          ROLE_ADMIN_ID                                        = -1;
   public static final int          ROLE_READONLY_ID                                     = -2;
   public static final int          ROLE_VIEW_ID                                         = -3;
   public static final int          ROLE_ANON_ID                                         = -4;
   public static final int          ROLE_NO_PERM_ID                                      = -5;

   /*
    * Constants for System Privileges
    */
   public static final String[]     SYS_PRIVILEGES                                       = {
            "System.Read", "System.Anonymous", "System.View"                            };
   /*
    * Test arguments passed into the test cases
    */
   public static final String       ARG_VM                                               = "-vm";

   /*
    * Constants for DhcpService Specification
    */
   public static final String       DHCPSERVICE_SPEC_LEASEBEGINIP                        = "192.168.0.0";
   public static final String       DHCPSERVICE_SPEC_LEASEENDIP                          = "192.168.254.0";
   public static final String       SPL_CHAR_NAME_CUST                                   = "`~!@#$%^&*()-_=+[]%{}|;':\",.%<>?";
   public static final String       SPL_CHAR_NAME                                        = "`~!@#$%25^&*()-_=+[]%5c{}|;':\",.%2f<>?";
   public static final String       SPL_CHAR_NAME_DS                                     = "`~!@#$%25^&*()-_=+%5c{}|;':\",.%2f<>?";
   public static final String       SPL_CHAR_NAME_VMFS                                   = "!@#$%25^*-_=+[]%5c{}\'";
   public static final String[]     SPL_CHAR_NAMES                                       = {
            "`~!@#$%25^&*()-_=+[", "]%5c{}|;':\",.%2f<>?"                               };
   public static final int          NAME_MAX_LENGTH                                      = 80;

   /*
    * Change Audit ITB- K/L: Change Context Tag
    */
   public static final String       CHANGEAUDIT_SOAP_TAG                                 = "changeContext";
   public static final String       USER_INPUT_FOR_AUDIT_TRAIL                           = "Audit Trail Check";

   /*
    * Audit Trail related constants
    */
   public static final String       MULTIPOWERON_VMS_EVENT_FORMATTED_MSG                 = "Task: Initialize powering On";
   public static final String       DRS_ENABLED_VMOTION_EVENT_FORMATTED_MSG              = "Task: Migrate virtual machine";
   public static final String       VM_POWERON_TASK_DESCP_ID                             = "VirtualMachine.powerOn";
   public static final String       VM_POWERON_EVENT_FORMATTED_MSG                       = "Task: Power On Virtual Machine";
   public static final String       HOST_REBOOT_TASK_DESCP_ID                            = "HostSystem.reboot";
   public static final String       HOST_REBOOT_EVENT_FORMATTED_MSG                      = "Task: Initiate host reboot";
   public static final String       VM_SNAPSHOT_TASK_DESCP_ID                            = "vm.Snapshot.revert";
   public static final String       VM_SNAPSHOT_EVENT_FORMATTED_MSG                      = "Task: Revert Snapshot";

   /*
    * Constants for Vmware Virtual Center Settings
    */
   public static final String       MAIL_SERVER_KEY                                      = "mail.smtp.server";
   public static final String       MAIL_SERVER_VALUE                                    = "pa-smtp.vmware.com";
   public static final String       MAIL_SENDER_KEY                                      = "mail.sender";
   public static final String       MAIL_SENDER_VALUE                                    = "vctests@vmware.com";

   public static final String       SNMP_PRIMARY_RECEIVER_URL_KEY                        = "snmp.receiver.1.name";
   public static final String       SNMP_PRIMARY_RECEIVER_URL_VALUE                      = "localhost";
   public static final String       SNMP_PRIMARY_RECEIVER_PORT_KEY                       = "snmp.receiver.1.port";
   public static final String       SNMP_PRIMARY_RECEIVER_PORT_VALUE                     = "162";
   public static final String       SNMP_PRIMARY_RECEIVER_COMMUNITY_KEY                  = "snmp.receiver.1.community";
   public static final String       SNMP_PRIMARY_RECEIVER_COMMUNITY_VALUE                = "public";
   public static final String       SNMP_INVALID_PRIMARY_RECIEVER_URL                    = "InvalidURL";
   /*
    * Constants for snapshot memory size used for snapshot operations' tests
    */
   public static final int          SNAPSHOT_MEM_MIN                                     = 128;
   public static final int          SNAPSHOT_MEM_GSX3X_OR_ESX2X_MAX                      = 1000;
   /*
    * TODO - Test later with a larger memory machine
    */
   public static final int          SNAPSHOT_MEM_ESX3X_MAX                               = 4000;
   public static final int          SNAPSHOT_MEM_MAX_TEST                                = 3600;

   /*
    * Constants for snapshot disk size used when create VM
    */
   public static final int          SNAPSHOT_DISK                                        = 1024 * 10;
   public static final int          NUM_DISKS_SNAPSHOT                                   = 3;
   public static final int          NUM_CONTROLLERS_SNAPSHOT                             = 1;
   public static final int          MAX_NUMBER_SNAPSHOTS                                 = 2;

   /*
    * Test constants for cowdelta vmops snapshots
    */
   public static final int          MIN_NUM_OF_SNAPSHOTS                                 = 3;
   public static final int          MAX_NUM_OF_SNAPSHOTS                                 = 32;

   /*
    * Constants for delta disks
    */
   public static final String       VM_DELTA_VMDK                                        = "000001";
   public static final String       VM_DELTA_VMDK_FILEEXTN                               = "-delta.vmdk";

   /*
    * Constants for Swap Placement
    */
   public static final String       SWAP_PLACEMENT_HOST_DIR                              = "/root";
   public static final String       SWAP_PLACEMENT_TEMP_SWAP_DIR1                        = "tempSwapDirectory1";
   public static final String       SWAP_PLACEMENT_TEMP_SWAP_DIR2                        = "tempSwapDirectory2";
   public static final String       SWAP_FILE_EXTENSION                                  = "*.vswp";

   /*
    * Constants for Swap Placement Policy values
    */
   public static final int          SWAP_POLICY_INHERIT_INT                              = 0;
   public static final int          SWAP_POLICY_HOSTLOCAL_INT                            = 1;
   public static final int          SWAP_POLICY_VMDIRECTORY_INT                          = 2;
   public static final int          SWAP_POLICY_VMCONFIGURED_INT                         = 3;
   public static final String       SWAP_POLICY_INHERIT                                  = "inherit";
   public static final String       SWAP_POLICY_HOSTLOCAL                                = "hostLocal";
   public static final String       SWAP_POLICY_VMDIRECTORY                              = "vmDirectory";
   public static final String       SWAP_POLICY_VMCONFIGURED                             = "vmConfigured";

   /*
    * Optional value for the VM Config.
    */
   public static final String       VM_CONFIG_SCHED_SWAP_DIR                             = "sched.swap.dir";
   public static final String       VM_CONFIG_SCHED_SWAP_PERSIST                         = "sched.swap.persist";

   /*
    * Constants for VM and ResourcePool quickstats
    */
   public static final String       QUICKSTATS_OVERALL_CPU_USAGE                         = "overallCpuUsage";
   public static final String       QUICKSTATS_OVERALL_CPU_DEMAND                        = "overallCpuDemand";
   public static final String       QUICKSTATS_GUEST_MEM_USAGE                           = "guestMemoryUsage";
   public static final String       QUICKSTATS_HOST_MEM_USAGE                            = "hostMemoryUsage";
   public static final String       QUICKSTATS_DIST_CPU_ENTITLEMENT                      = "distributedCpuEntitlement";
   public static final String       QUICKSTATS_DIST_MEM_ENTITLEMENT                      = "distributedMemoryEntitlement ";
   public static final String       QUICKSTATS_STATIC_CPU_ENTITLEMENT                    = "staticCpuEntitlement";
   public static final String       QUICKSTATS_STATIC_MEM_ENTITLEMENT                    = "staticMemoryEntitlement";
   public static final String       QUICKSTATS_PRIVATE_MEM                               = "privateMemory ";
   public static final String       QUICKSTATS_SHARED_MEM                                = "sharedMemory";
   public static final String       QUICKSTATS_SWAPPED_MEM                               = "swappedMemory";
   public static final String       QUICKSTATS_BALLONED_MEM                              = "balloonedMemory";
   public static final String       QUICKSTATS_CONFIG_MEMORY_MB                          = "configuredMemoryMB";
   public static final String       QUICKSTATS_GUEST_HEARTBEAT_STATUS                    = "guestHeartbeatStatus";
   public static final String       QUICKSTATS_OVERHEAD_MEM                              = "overHeadMemory";
   public static final String       QUICKSTATS_FT_LOG_BANDWIDTH                          = "ftLogBandwidth";
   public static final String       QUICKSTATS_FT_SECONDARY_LATENCY                      = "ftSecondaryLatency";
   public static final String       QUICKSTATS_FT_LATENCY_STATUS                         = "ftLatencyStatus";

   /*
    * Power policy Constants
    */
   public static final String       AVAILABLE_POLICY_PROPNAME                            = "availablePolicy";
   public static final String       CURRENT_POLICY_PROPNAME                              = "currentPolicy";
   public static final String       POWER_POLICY_ADV_OPTION_KEY                          = "Power.CpuPolicy";
   public static final String       POWER_POLICY_ADV_OPTION_CUSTOM_VALUE                 = "custom";
   public static final String       POWER_POLICY_ADV_OPTION_STATIC_VALUE                 = "static";
   public static final String       POWER_POLICY_ADV_OPTION_DYNAMIC_VALUE                = "dynamic";
   public static final String       POWER_POLICY_ADV_OPTION_LOW_VALUE                    = "low";
   public static final String       SIOC_LOG_LEVEL                                       = "Misc.SIOControlLoglevel";

   /*
    * Wait time for a VM for one minute
    */
   public static final int          VM_WAIT_TIME                                         = 60000;

   /*
    * Thread sleep time for unmounting tools installation after failed upgrade
    */
   public static final int          TOOLS_UNMOUNT_THREAD_SLEEP                           = 10000;

   /*
    * Command prefix to change the time on a windows machine using SSH
    */
   public static final String       WIN_DATE_CMD_SSH                                     = "cmd.exe /c date ";

   /*
    * Command prefix to change the time on a Linux machine using SSH
    */
   public static final String       LIN_DATE_CMD_SSH                                     = "date -s ";

   /*
    * Constants for max disk size used when creating VM
    */
   public static final int          MAX_DISKS                                            = 60;
   public static final int          MAX_CONTROLLERS                                      = 4;
   public static final int          MAX_VMXNET_DEVICES                                   = 10;
   public static final int          MAX_CDROM_DEVICES                                    = 4;
   public static final int          MAX_IDE_DISKS                                        = 4;
   public static final int          SMALL_DISK_SIZE                                      = 1024 * 10;
   public static final int          VMX_FILE_SIZE                                        = 1024 * 10;

   /*
    * Constants for ResrouceAllocationInfo
    */
   public static final Long         RESOURCE_ALLOC_MIN                                   = new Long(
                                                                                                  0);
   public static final Long         RESOURCE_ALLOC_UNLIMITED                             = new Long(
                                                                                                  -1);
   public static final String       RESOURCE_CHANGEVERSION                               = "ResourceConfigSpec.ChangeVersion";
   public static final String       RESOURCE_LASTMODIFIED                                = "ResourceConfigSpec.LastModified";

   /*
    * File to which dump would be extracted. Used by
    * ESXDiagnosticSystem.extractDump() API.
    */
   public static final String       ESXDIAGNOSTICSYSTEM_DUMPFILE                         = "[]/root/DumpFile";

   /*
    * ESX RAW DISK MAP CONSTANTS
    */
   public static final String       HOST_RDM_PATH_PREFIX                                 = "[]/vmfs";
   public static final String       HOST_RAWDISK_DEFAULT_LUN                             = "vmhba1:5:0:1";

   /*
    * Minimum allowed cfgBytes for the Service Console
    */
   public static final long         HOST_SERVICE_CONSOLE_MIN_CFGBYTES                    = 256L;
   public static final long         HOST_SERVICE_CONSOLE_MAX_CFGBYTES                    = 800L;
   /*
    * Minimum allowed vmReservation for the Virtual Machine Memory reservation
    */
   public static final long         VIRTUAL_MACHINE_MEMORY_MIN_RESERVATION               = 16L;
   public static final long         VIRTUAL_MACHINE_MEMORY_MAX_RESERVATION               = 384L;
   public static final long         VIRTUAL_MACHINE_MEMORY_NEG_RESERVATION               = -1;
   public static final long         VIRTUAL_MACHINE_MEMORY_INVALID_MIN_RESERVATION       = 15L;
   public static final long         VIRTUAL_MACHINE_MEMORY_INVALID_MAX_RESERVATION       = 385L;
   /*
    * IVMotionSystem Test Constants
    */
   public static final String       VMOTION_HOST_IP_ADDRESS                              = "10.17.133.168";
   public static final String       VMOTION_SUBNETMASK                                   = "255.255.255.0";

   /*
    * PerformanceManager related constants
    */

   /*
    * To let the VMs up and running before querying for stats. Used in Perf
    * Setup.
    */
   public static final int          PERF_STATS_DEFAULT_LEVEL                             = 1;
   public static final int          PERF_STATS_MAX_LEVEL                                 = 4;

   public static final int          PERF_VMS_UPTIME                                      = 30 * 60;
   public static final int          PERF_CPU_PERCENTUSAGE_CTR                            = 2;

   public static final String       PERF_DEVICE_CPU                                      = "cpu";
   public static final String       PERF_DEVICE_MEM                                      = "mem";
   public static final String       PERF_DEVICE_DISK                                     = "disk";
   public static final String       PERF_DEVICE_NET                                      = "net";
   public static final String       PERF_DEVICE_SYS                                      = "sys";
   public static final String       PERF_DEVICE_DRS                                      = "drs";

   public static final String       PERF_DEVICE_RES_CPU                                  = "rescpu";
   public static final String       PERF_DEVICE_VM_ID                                    = "VMID";
   public static final String       PERF_DEVICE_DISK_FILE                                = "DISKFILE";
   public static final String       PERF_DEVICE_DELTA_FILE                               = "DELTAFILE";
   public static final String       PERF_DEVICE_SWAP_FILE                                = "SWAPFILE";
   public static final String       PERF_DEVICE_OTHER_FILE                               = "OTHERFILE";

   public static final int          PERF_DEFAULT_INSTANCE                                = -1;

   public static final String       PERF_FILTERLEVEL_KEY                                 = "config.vpxd.stats.filterLevel";
   public static final String       PERF_FILTERLEVEL_VALUE                               = "4";

   public static final String       PERF_MAXQUERYMETRICS__KEY                            = "config.vpxd.stats.maxQueryMetrics";
   public static final String       PERF_MAXQUERYMETRICS__VALUE                          = "0";
   /*
    * Number of interested intervals to collect the perf data
    */
   public static final int          PERF_INTERESTED_NUMINT                               = 10;
   /*
    * Generic start and endTime for querying the perf stats (with respect to
    * recently collected stats, in secs)
    */
   public static final int          PERF_START_TIME                                      = 45 * 60;
   public static final int          PERF_END_TIME                                        = 15 * 60;

   /*
    * Wait time before removing a datastore. Removing a datastore, immediately
    * after the creation fails now.Bug #184510
    */
   public static final int          DATASTORE_REMOVAL_TIME                               = 60000;
   /*
    * wait for vmkernel internal storageRefresh to complete.
    */
   public static final int          STORAGE_REFRESH_TIME                                 = 10000;
   /*
    * Counter names pertaining to the devices' counters
    */
   public static final String       PERF_COUNTERNAME_USAGE                               = "usage";
   public static final String       PERF_COUNTERNAME_SYSTEM                              = "system";
   public static final String       PERF_COUNTERNAME_ACTIVE                              = "active";
   public static final String       PERF_COUNTERNAME_STATE                               = "state";
   public static final String       PERF_COUNTERNAME_PACKETRX                            = "packetsRx";
   public static final String       PERF_COUNTERNAME_NUMBERREAD                          = "numberRead";
   public static final String       PERF_COUNTERNAME_UPTIME                              = "uptime";
   public static final String       PERF_COUNTERNAME_INTERVAL                            = "interval";
   public static final String       PERF_COUNTERNAME_HEARTBEAT                           = "heartbeat";
   public static final String       PERF_COUNTERNAME_READ                                = "read";
   public static final String       PERF_COUNTERNAME_CAPACITY                            = "capacity";
   public static final String       PERF_COUNTERNAME_USED                                = "used";
   public static final String       PERF_COUNTERNAME_PROVISIONED                         = "provisioned";
   public static final String       PERF_COUNTERNAME_UNSHARED                            = "unshared";

   public static final String[]     PERF_SPACE_COUNTERS                                  = {
            PERF_COUNTERNAME_USED, PERF_COUNTERNAME_PROVISIONED,
            PERF_COUNTERNAME_CAPACITY, PERF_COUNTERNAME_UNSHARED                        };
   /*
    * Perf Historical Interval names
    */
   public static final String       PERF_INTERVAL_PAST_DAY                               = "Past Day";
   public static final String       PERF_INTERVAL_PAST_WEEK                              = "Past Week";
   public static final String       PERF_INTERVAL_PAST_MONTH                             = "Past Month";
   public static final String       PERF_INTERVAL_PAST_YEAR                              = "Past Year";

   /*
    * For space counters.
    */
   public static final String       VM_NVRAM_FILEEXTN                                    = ".nvram";
   public static final String       VM_VMDK_FILEEXTN                                     = ".vmdk";
   public static final String       VM_VMX_FILEEXTN                                      = ".vmx";
   public static final String       VM_VMXF_FILEEXTN                                     = ".vmxf";
   public static final String       VM_VSWP_FILEEXTN                                     = ".vswp";
   public static final String       VM_FLATVMDK_FILEEXTN                                 = "-flat.vmdk";
   public static final String       VM_LOG_FILEEXTN                                      = ".log";
   public static final String       VM_VMSD_FILEEXTN                                     = ".vmsd";
   public static final String       VM_SCREENSHOT_FILEEXTN                               = ".png";
   public static final String       PERF_THINVM_NAME                                     = "ThinVm";
   public static final String       PERF_LINKEDCLONE_VM                                  = "LinkedcloneVm";
   public static final String       PERF_LINKEDCLONE_VM_CLONE                            = "LinkedcloneVm-Clone";
   public static final String       PERF_VM_SNAPSHOT                                     = "PerfSetup-Snapshot";
   public static final int          PERF_SPACE_VMS_UPTIME                                = 30 * 60;

   /*
    * Constants for GuestLib
    */
   public static final String       SHARED_FOLDER                                        = "SHARED";
   public static final String[]     GUEST_LIB_VM_LIBRARY                                 = {
            "GUESTLIB_WIN2KADVSERVER", "GUESTLIB_RHEL_LINUX"                            };
   public static final String[]     GUEST_LIB_DISABLED_VM_LIBRARY                        = {
            "GUESTLIB_DISABLED_WIN2KADVSERVER", "GUESTLIB_DISABLED_RHEL_LINUX"          };
   public static final String       TOOLS_AUTO_UDATE_SCRIPT                              = "vmwaretoolsupgrade.bat";
   public static final String       GUEST_LIB_JNI_JAR                                    = "vmGuestLibJava.jar";
   public static final String       GUEST_LIB_TESTS_JAR                                  = "ewlm.jar";
   public static final String       CLEANUP_SCRIPT_FILE                                  = "cleanup.";
   public static final String       EXEC_JAVA_PROCESS_FILE                               = "exectest.";
   public static final String       RESULTS_FILE                                         = "out.txt";
   public static final String       GUESTLIB_WIN_USER_NAME                               = "root";
   public static final String       GUESTLIB_LNX_USER_NAME                               = "root";

   /*
    * List of VirtualDevices Constants Constant: VM_VIRTUALDEVICE_ALL is used to
    * refer all the virtual devices. These constants were created for
    * create/updated VMConfigSpec which is used in CreateVM/Reconfig VM
    */
   public static final String       VM_VIRTUALDEVICE_ALL                                 = "ALL";
   public static final String       VM_VIRTUALDEVICE                                     = VirtualDevice.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_CDROM                               = VirtualCdrom.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_USBController                       = VirtualUSBController.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_DISK                                = VirtualDisk.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_ETHERNET_PCNET32                    = VirtualPCNet32.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_ETHERNET_VMXNET                     = VirtualVmxnet.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_ETHERNET_VMXNET2                    = VirtualVmxnet2.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_ETHERNET_VMXNET3                    = VirtualVmxnet3.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_ETHERNET_E1000                      = VirtualE1000.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_ETHERNET_E1000E                     = VirtualE1000E.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_ETHERNET_SRIOV                      = VirtualSriovEthernetCard.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_FLOPPY                              = VirtualFloppy.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_KEYBOARD                            = VirtualKeyboard.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_PARALLELPORT                        = VirtualParallelPort.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_VIRTUALSCSIPASS                     = VirtualSCSIPassthrough.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_VIRTUALPCIPASS                      = VirtualPCIPassthrough.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_POINTINGDEVICE                      = VirtualPointingDevice.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_SERIALPORT                          = VirtualSerialPort.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_SOUNDCARD_SOUNDBLASTER16            = VirtualSoundBlaster16.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_SOUNDCARD_ENSONIQ1371               = VirtualEnsoniq1371.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_SOUNDCARD_HDAUDIOCARD               = VirtualHdAudioCard.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_VIDEOCARD                           = VirtualMachineVideoCard.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_USB                                 = VirtualUSB.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_IDE_CONTROLLER                      = VirtualIDEController.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_PCI_CONTROLLER                      = VirtualPCIController.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_PS2_CONTROLLER                      = VirtualPS2Controller.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_SCSI_BUSL_CONTROLLER                = VirtualBusLogicController.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_SCSI_LSI_CONTROLLER                 = VirtualLsiLogicController.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_SCSI_PV_CONTROLLER                  = ParaVirtualSCSIController.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_SCSI_CONTROLLER                     = VirtualSCSIController.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_SIO_CONTROLLER                      = VirtualSIOController.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_USB_CONTROLLER                      = VirtualUSBController.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_USB_XHCICONTROLLER                  = VirtualUSBXHCIController.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_PCI_CONTROLLER_OPTION               = VirtualPCIControllerOption.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_SOUNDBLASTER_OPTION                 = VirtualSoundBlaster16Option.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_ENSONIQ_OPTION                      = VirtualEnsoniq1371Option.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_IDECONTROLLER_OPTION                = VirtualIDEControllerOption.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_PS2CONTROLLER_OPTION                = VirtualPS2ControllerOption.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_SCSIBUSLCONTROLLER_OPTION           = VirtualBusLogicControllerOption.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_SCSILSICONTROLLER_OPTION            = VirtualLsiLogicControllerOption.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_SCSIPVCONTROLLER_OPTION             = ParaVirtualSCSIControllerOption.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_SOUNDCARD_HDAUDIOCARD_OPTION        = VirtualHdAudioCardOption.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_USB_XHCICONTROLLER_OPTION           = VirtualUSBXHCIControllerOption.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_SCSI_LSI_SAS_CONTROLLER_OPTION      = VirtualLsiLogicSASControllerOption.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_SIOCONTROLLER_OPTION                = VirtualSIOControllerOption.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_USBCONTROLLER_OPTION                = VirtualUSBControllerOption.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_SERIALPORT_OPTION                   = VirtualSerialPortOption.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_PARALLELPORT_OPTION                 = VirtualParallelPortOption.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_FLOPPY_OPTION                       = VirtualFloppyOption.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_DEVICEBACKINGINFO                   = VirtualDeviceDeviceBackingInfo.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_CDROM_PASSTHROUGH_DEVICEBACKINGINFO = VirtualCdromPassthroughBackingInfo.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_CDROM_ATAPI_DEVICEBACKINGINFO       = VirtualCdromAtapiBackingInfo.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_FLOPPY_DEVICEBACKINGINFO            = VirtualFloppyDeviceBackingInfo.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_PARALLELPORT_DEVICEBACKINGINFO      = VirtualParallelPortDeviceBackingInfo.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_VMIROM                              = VirtualMachineVMIROM.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_SERIALPORT_DEVICEBACKINGINFO        = VirtualSerialPortDeviceBackingInfo.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_USB_DEVICEBACKINGINFO               = VirtualUSBUSBBackingInfo.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_SCSICONTROLLER_OPTION               = VirtualSCSIControllerOption.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_SCSIPASSTHROUGH_OPTION              = VirtualSCSIPassthroughOption.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_ETHERNET_OPTION                     = VirtualEthernetCardOption.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_LSI_SAS_CONTROLLER                  = VirtualLsiLogicSASController.class
                                                                                                  .getName();
   public static final String       VM_VIRTUALDEVICE_VMCI                                = VirtualMachineVMCIDevice.class
                                                                                                  .getName();
   public static final String       FLOPPYQUERY                                          = FloppyImageFileQuery.class
                                                                                                  .getName();
   public static final String       FOLDERQUERY                                          = FolderFileQuery.class
                                                                                                  .getName();
   public static final String       ISOIMAGEQUERY                                        = IsoImageFileQuery.class
                                                                                                  .getName();
   public static final String       VMCONFIGQUERY                                        = VmConfigFileQuery.class
                                                                                                  .getName();
   public static final String       VMDISKQUERY                                          = VmDiskFileQuery.class
                                                                                                  .getName();
   public static final String       VMLOGQUERY                                           = VmLogFileQuery.class
                                                                                                  .getName();
   public static final String       VMNVRAMQUERY                                         = VmNvramFileQuery.class
                                                                                                  .getName();
   public static final String       VMSNAPSHOTQUERY                                      = VmSnapshotFileQuery.class
                                                                                                  .getName();
   public static final String       TEMPLATECONFIGQUERY                                  = TemplateConfigFileQuery.class
                                                                                                  .getName();
   public static final String       FLOPPYINFO                                           = "FloppyImageFileInfo";
   public static final String       FOLDERINFO                                           = "FolderFileInfo";
   public static final String       ISOIMAGEINFO                                         = "IsoImageFileInfo";
   public static final String       VMCONFIGINFO                                         = "VmConfigFileInfo";
   public static final String       VMDISKINFO                                           = "VmDiskFileInfo";
   public static final String       VMLOGINFO                                            = "VmLogFileInfo";
   public static final String       VMNVRAMINFO                                          = "VmNvramFileInfo";
   public static final String       VMSNAPSHOTINFO                                       = "VmSnapshotFileInfo";
   public static final String       VM_RECOMMENDED_ETHERNET                              = "RecommendedEthernet";
   public static final String       ETHERNET_PCNET32                                     = "VirtualPCNet32";
   public static final String       ETHERNET_VMXNET                                      = "VirtualVmxnet";
   public static final String       ETHERNET_VMXNET2                                     = "VirtualVmxnet2";
   public static final String       ETHERNET_VMXNET3                                     = "VirtualVmxnet3";
   public static final String       ETHERNET_E1000                                       = "VirtualE1000";
   public static final String       ETHERNET_E1000E                                      = "VirtualE1000E";
   public static final String       MAX_ETHERNET_E1000                                   = "MAX_ETHERNET_E1000";
   public static final String       VM_VIRTUALDEVICE_AHCI_CONTROLLER                     = VirtualAHCIController.class
                                                                                                  .getName();
   /*
    * Constants related to multipath policy names
    */
   public static final String       MULTIPATHLUN_POLICY_FIXED                            = "FIXED";
   public static final String       MULTIPATHLUN_POLICY_MRU                              = "MRU";
   public static final String       MULTIPATHLUN_POLICY_RR                               = "RR";
   public static final String       MULTIPATHLUN_POLICY_UNKNOWN                          = "PSP_UNKN";
   public static final String       MULTIPATHLUN_POLICY_PREFIX                           = "VMW_PSP_";
   public static final String       MODEL_LUNZ                                           = "LUNZ";

   /*
    * Default device name
    */
   public static final String       DEFAULT_DEVICE_NAME                                  = "DefaultDeviceName";

   /*
    * Disk backing Type.
    *
    * @deprecated please use enum {@link VmDiskType} for representing different
    * disk types.
    */
   @Deprecated
   public static final String       VM_DISK_THIN_BACKING                                 = "Thin";
   /*
    * Constant for Disk hardware version
    */
   public static final String       VM_DISK_VERSION3                                     = "vmx-03";
   public static final String       VM_DISK_VERSION4                                     = "vmx-04";
   public static final String       VM_DISK_VERSION6                                     = "vmx-06";
   public static final String       VM_DISK_VERSION7                                     = "vmx-07";
   public static final String       VM_DISK_VERSION8                                     = "vmx-08";
   public static final String       VM_DISK_VERSION9                                     = "vmx-09";
   public static final String       VM_DISK_VERSION10                                    = "vmx-10";
   public static final String       VM_DISK_VERSION11                                    = "vmx-11";
   public static final String       HW_VERSION                                           = "HW_VERSION";

   /*
    * Constants for Disk mode
    */
   public static final String       VM_DISKMODE_PERSISTENT                               = "persistent";
   public static final String       VM_DISKMODE_NONPERSISTENT                            = "non_persistent";
   public static final String       VM_DISKMODE_UNDOABLE                                 = "undoable";
   public static final String       VM_DISKMODE_INDEPENDENT_PERSISTENT                   = "independent_persistent";
   public static final String       VM_DISKMODE_INDEPENDENT_NONPERSISTENT                = "independent_nonpersistent";
   public static final String       VM_DISKMODE_APPEND                                   = "append";

   /*
    * Constants for Virtual Disk RawDiskMappingVer1BackingInfo constants
    */
   public static final String       VM_RAW_DISK_MAPPING_COMPATIBILITY_MODE_VIRTUAL       = "virtualMode";
   public static final String       VM_RAW_DISK_MAPPING_COMPATIBILITY_MODE_PHYSICAL      = "physicalMode";

   /*
    * Constants for Disk deviceName
    */
   public static final String       VM_RAW_DISK_DEVICENAME_GSX_WINDOWS                   = "C:\testvmfsMap";
   public static final String       VM_RAW_DISK_DEVICENAME_GSX_LINUX                     = "/root/testvmfsMap";
   public static final String       VM_RAW_DISK_DEVICENAME_ESX                           = "/vmfs/testvmfsMap";

   /*
    * Constants used to set file info object for create vm
    */
   public static final String       GSXWINDOWS_PATH_NAME                                 = "[]c:\\";
   public static final String       ESX_GSXLINUX_PATH_NAME                               = "[]/tmp/";
   // Included the OVF_FILE_PATH_NAME here which is used for
   // provisioning.relocatevm.Pos136.java
   public static final String       OVF_FILE_PATH_NAME                                   = "http://engweb.vmware.com/~mthangar/relocatevm.Pos136/MDSUM-477341.ovf";

   public static final String       GSX31_WINDOWS_CDROMBACKING_FILENAME                  = "[]c://Test.iso";
   public static final String       SERVER_WINDOWS_CDROMBACKING_FILENAME                 = "[]c://Test.iso";
   public static final String       ESX_GSX31_LINUX_CDROMBACKING_FILENAME                = "[]/usr/lib/vmware/isoimages/Test.iso";

   /*
    * Floppy device backing constants
    */
   public static final String       VM_DEFAULT_FLOPPY_SPEC_DEVICENAME                    = "/dev/fd0";
   public static final String       WIN_VM_DEFAULT_FLOPPY_SPEC_DEVICENAME                = "b:";
   //

   /*
    * USB device backing constants
    */
   public static final String       VM_DEFAULT_USB_SPEC_DEVICENAME                       = "/dev/usb";

   /*
    * Parallel port file backing info
    */
   public static final String       VM_DEFAULT_PARALLELPORTBACKING_FILENAME              = "[]/tmp/parallelport";
   public static final String       WINDOWS_VM_DEFAULT_PARALLELPORTBACKING_FILENAME      = "[]c:\\temp\\parallelport";
   public static final String       WINDOWS_VM_DEFAULT_PARALLELPORTBACKING_FILE          = "c:\\temp\\parallelport";
   public static final String       VM_DEFAULT_PARALLELPORTBACKING_FILE                  = "/tmp/parallelport";
   public static final Integer      VM_DEFAULT_PARALLELPORT_UNITNUMBER                   = new Integer(
                                                                                                  0);
   public static final String       PARALLEL_PORT_NAME                                   = "parallelport";

   /*
    * Parallel port device backing info
    */
   public static final String       VM_DEFAULT_PARALLELPORT_SPEC_DEVICENAME              = "[]/usr/ttyP1";
   // dev
   /*
    * Serial port file backing info
    */
   public static final String       VM_DEFAULT_SERIALPORTBACKING_FILENAME                = "[]/tmp/serialport";
   public static final String       WINDOWS_VM_DEFAULT_SERIALPORTBACKING_FILENAME        = "[]c:\\tmp\\serialport";
   public static final String       VM_DEFAULT_SERIALPORTBACKING_FILE                    = "/tmp/serialport";
   public static final String       WINDOWS_VM_DEFAULT_SERIALPORTBACKING_FILE            = "c:\\tmp\\serialport";
   public static final String       VM_DEFAULT_SERIALPORTBACKING_FILE_ANSWERVM           = "/tmp/ansvm_serialport";
   public static final String       WINDOWS_VM_DEFAULT_SERIALPORTBACKING_FILE_ANSWERVM   = "c:\\tmp\\ansvm_serialport";
   public static final String       SERIAL_PORT_NAME                                     = "serialport";
   public static final String       WINDOWS_TMP_PATH                                     = "c:\\tmp\\";

   /*
    * Serial port device backing info
    */
   public static final String       VM_DEFAULT_SERIALPORT_SPEC_DEVICENAME                = "/dev/ttyS1";

   /*
    * Serial port pipe backing info
    */
   public static final String       VM_WINDOWS_SERIALPORT_SPEC_PIPENAME                  = "C:\\tmp\\serialport";

   /*
    * device spec operations
    */
   public static final int          VM_VIRTUALDEVICESPEC_OPER_ADD                        = 1;
   public static final int          VM_VIRTUALDEVICESPEC_OPER_EDIT                       = 2;
   public static final int          VM_VIRTUALDEVICESPEC_OPER_REMOVE                     = 3;
   public static final int          VM_VIRTUALDEVICESPEC_FILEOPER_CREATE                 = 4;
   public static final int          VM_VIRTUALDEVICESPEC_FILEOPER_DESTROY                = 5;
   public static final int          VM_VIRTUALDEVICESPEC_FILEOPER_REPLACE                = 6;
   public static final String       VM_EMULATIONTYPE_PASSTHROUGH                         = "passthrough";
   public static final String       VM_EMULATIONTYPE_LEGACYVMWARE                        = "Legacy VMware";
   /*
    * video card host interface constants
    */
   public static final String       VM_VIRTUALDEVICE_VIDEOCARD_HOSTINTERFACE_DDRAW       = "DirectDraw";
   public static final String       VM_VIRTUALDEVICE_VIDEOCARD_HOSTINTERFACE_GDI         = "GDI";

   /*
    * Constants for polling if the host is rebooted (in seconds)
    */
   public static final int          HOST_REBOOT_DELAY                                    = 60;
   public static final int          HOST_RESTART_TIMEOUT                                 = 1200;
   public static final int          HOST_REBOOT_TIMEOUT                                  = 1500;
   public static final int          HOSTAGENT_STARTUP_DELAY                              = 30;
   public static final int          VPXA_AAM_SYNC_DELAY                                  = 60;
   public static final int          HOST_NETWORK_ISOLATION_DELAY                         = 360;

   /*
    * Test constants to signal when test warnings should be generated
    */
   public static final long         DATASTORE_EXHAUSTED_THRESHOLD                        = (long) .90;

   /*
    * Constants that some of the ImportVM tests will require. One of the
    * importVM parameters is a path, which is the absolute path to a VM config
    * file (in Datastore format). For importing external VMs (VMs not currently
    * in the VC Inventory), this path needs to be accessible to the test client.
    */
   public static final String[]     WINDOWS_CFG_FILE_PATHS                               = { "[]E:\\VMs\\WS4.0\\win2000AdvServ_notools\t.vmx", };
   public static final String[]     LINUX_CFG_FILE_PATHS                                 = { "[]E:\\VMs\\WS4.0\\redhatAS2.1_notools\t.vmx", };
   public static final String       TOOLS_IMAGE_WINDOWS                                  = "/usr/lib/vmware/isoimages/windows.iso";
   public static final String       TOOLS_IMAGE_SIG_WINDOWS                              = "/usr/lib/vmware/isoimages/windows.iso.sig";
   public static final String       TOOLS_IMAGE_LINUX                                    = "/usr/lib/vmware/isoimages/linux.iso";
   public static final String       TOOLS_IMAGE_SIG_LINUX                                = "/usr/lib/vmware/isoimages/linux.iso.sig";
   public static final String       TOOLS_VMIMAGE_WINDOWS                                = "[] /vmimages/tools-isoimages/windows.iso";

   /*
    * Constants specific for IPv6 addresses
    */
   public static final String       DEFAULT_GATEWAY_IPV6                                 = "fe80::214:f602:357f:93f0";
   /*
    * The following characters or arrangement of characters are not permissible
    * as a VM name. These are used by the Provisioning tests.
    */
   public static final String[]     INVALID_VM_NAMES                                     = {
            "\\", "/", " leading space", "trailing space ",                             };
   public static final String[]     VALID_ASCII_VM_NAMES                                 = {
            "! \"#$%'()*+,.0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]",
            "^'abcdefghijklmnopqrstuvwxyz{|}~",                                         };
   /*
    * Constants for VM Customization
    */
   public static final String       VM_GUEST_FAMILY_WINDOWS                              = "win";
   public static final String       VM_GUEST_FAMILY_LINUX                                = "linux";

   /*
    * Constants for update network config
    */
   public static final String       CHANGEMODE_MODIFY                                    = HostConfigChangeMode.MODIFY
                                                                                                  .value();
   public static final String       CHANGEMODE_REPLACE                                   = HostConfigChangeMode.REPLACE
                                                                                                  .value();
   public static final String       NETWORKCFG_OP_ADD                                    = "add";
   public static final String       NETWORKCFG_OP_REMOVE                                 = "remove";
   public static final String       NETWORKCFG_OP_EDIT                                   = "edit";
   public static final String       HOSTCONFIG_CHANGEOPERATION_ADD                       = HostConfigChangeOperation.ADD
                                                                                                  .value();
   public static final String       HOSTCONFIG_CHANGEOPERATION_EDIT                      = HostConfigChangeOperation.EDIT
                                                                                                  .value();
   public static final String       HOSTCONFIG_CHANGEOPERATION_REMOVE                    = HostConfigChangeOperation.REMOVE
                                                                                                  .value();

   public static final String[]     CUSTOMIZATION_WINDOWS_VM_LIBRARY                     = {
            "CUST_WIN2KADVSERVER", "WIN2K3_R2_ENT_X64", "WIN_XP_PROF_X32",
            "WIN_XP_PROF_X64", "WIN_VISTA_X32", "WIN_VISTA_X64",
            "WIN2K3_ENT_X64", "WIN2K3_ENT_X32", "WIN2K8_ADVSERVER_X32",
            "WIN2K8_ADVSERVER_X64", "WINDOWS7_X32"

                                                                                         };
   public static final String       CUSTOMIZATION_GUESTID_SERIALNUMBERS[][]              = {
            { "win2000ServGuest", "VXKC4-2B3YF-W9MFK-QB3DB-9Y7MB" },
            { "win2000AdvServGuest", "VXKC4-2B3YF-W9MFK-QB3DB-9Y7MB" },
            { "winNetEnterprise64Guest", "CJ2B3-CFXPX-JGYBY-GY3TK-TWBQ3" },
            { "winXPProGuest", "DV8QH-FX2F9-62XKH-QXF77-K4GQM" },
            { "winXPPro64Guest", "D8WW3-DP3D7-YHQW7-79YD4-VWW2B" },
            { "winVistaGuest", "YVJ4B-362KH-G2T2Q-7G4VC-RCKV7" },
            { "winVista64Guest", "YVJ4B-362KH-G2T2Q-7G4VC-RCKV7" },
            { "winNetEnterpriseGuest", "B8C2J-XVFK4-TWQTB-6XVJD-KPQHQ" },
            /*
             * We are not able to customize Longhorn Guests with following
             * serial numbers. With SNO "8XQCY-BK3MJ-H2KHK-PJ8GG-97GXV", we run
             * one test to ensure customization works with Valid SNOs. Bug
             * #317513
             */
            // {"winLonghornGuest","92573-082-2500115-76646"},
            // {"winLonghorn64Guest","92573-082-2500115-76746"},
            // {"winLonghornGuest","8XQCY-BK3MJ-H2KHK-PJ8GG-97GXV"},
            // {"winLonghorn64Guest","8XQCY-BK3MJ-H2KHK-PJ8GG-97GXV"},
            { "winLonghornGuest", "" }, { "winLonghorn64Guest", "" },
            { "windows7Guest", "" }, { "windows7_64Guest", "" },
            { "windows8Guest", "" }, { "windows8_64Guest", "" },
            { "windows7Server64Guest", "" }, { "windows7Server64Guest", "" },
            { "win2000ProGuest", "" }, { "windows8Server64Guest", "" }

                                                                                         };
   public static final String[]     CUSTOMIZATION_LINUX_VM_LIBRARY                       = {
            "RHE_LINUX_ENT30_EXT3FS", "RHEL_LINUX_ENT40AS_EXT2FS_X64",
            "RHEL_LINUX_ENT40AS_EXT2FS_LVM", "RHE_LINUX_ENT50_X32",
            "RHE_LINUX_ENT50_X64", "SUSE_LINUX_ENT_X32", "UBUNTU", "DEBIAN",
            "SLES10_X64"

                                                                                         };
   public static final String[]     CUSTOMIZATION_WINDOWS_P2VM_LIBRARY                   = { "CUST_WIN2KADVSERVER"
                                                                                         // "CUST_WIN2003ENTSERVER"
                                                                                         };
   public static final String[]     CUSTOMIZATION_LINUX_P2VM_LIBRARY                     = { "RHE_LINUX_ENT30_EXT3FS",
                                                                                         // "RHE_LINUX_ENT30_REISEFS",
                                                                                         // "SUSE_LINUX_ENT80_EXT3FS",
                                                                                         // "SUSE_LINUX_ENT30_REISEFS"
                                                                                         };
   public static final String       CUSTOMIZATION_GUEST_UNSUPPORTED                      = "winNTGuest";
   public static final String       CUSTOMIZATION_VM_LIBRARY_FOLDERNAME                  = null;
   public static final String       CUSTOMIZATION_ADMIN_PASSWORD                         = "TEST";
   public static final String       CUSTOMIZATION_WIN8_ADMIN_PASSWORD                    = "TEST@PASS1";
   public static final String       CUSTOMIZATION_ADMIN_ENCRYPTED_PASSWORD               = "TEST";
   public static final String       CUSTOMIZATION_ADMIN_BLANK_PASSWORD                   = "";
   public static final String       CUSTOMIZATION_ADMIN_MAXLEN_PASSWORD                  = "TEST";
   public static final String       CUSTOMIZATION_RUNONCE_BATCH_CMD                      = "cmd.exe /c c:\\guirunonce1.bat";
   public static final String       CUSTOMIZATION_RUNONCE_BATCH_CMD2                     = "cmd.exe /c c:\\guirunonce2.bat";
   public static final String       CUSTOMIZATION_VISTA_RUNONCE_BATCH_CMD                = "cmd.exe /c c:\\customization\\custominfo.bat";
   public static final String       CUSTOMIZATION_JOINDOMAIN_NAME                        = "bobd.vmware.com";
   public static final String       CUSTOMIZATION_JOINDOMAIN_ADMINNAME                   = "tuser";
   public static final String       CUSTOMIZATION_JOINDOMAIN_ADMINPASSWORD               = "password";
   public static final String       CUSTOMIZATION_JOINDOMAIN_ENCRYPTED_ADMINPASSWORD     = "testadminpassword";
   public static final String       CUSTOMIZATION_WORKGROUP_NAME                         = "WORKGROUP";
   public static final String       CUSTOMIZATION_WINDOWS_SYSPREPTEXT_DATA               = "\r\n[Unattended]"
                                                                                                  + "\r\nOemSkipEula = Yes"
                                                                                                  + "\r\nInstallFilesPath = \"\\Sysprep\\i386\""
                                                                                                  + "\r\n"
                                                                                                  + "\r\n[GuiUnattended]"
                                                                                                  + "\r\nAdminPassword = "
                                                                                                  + CUSTOMIZATION_ADMIN_PASSWORD
                                                                                                  + "\r\nOemSkipWelcome = 1"
                                                                                                  + "\r\nTimeZone = 25"
                                                                                                  + "\r\nOEMSkipRegional=1"
                                                                                                  + "\r\nAutoLogon = Yes"
                                                                                                  + "\r\nAutoLogonCount = 3"
                                                                                                  + "\r\n "
                                                                                                  + "\r\n[UserData]"
                                                                                                  + "\r\nFullName = \"VMWare\""
                                                                                                  + "\r\nOrgName = \"VMWare Inc\""
                                                                                                  + "\r\nProductID = VXKC4-2B3YF-W9MFK-QB3DB-9Y7MB"
                                                                                                  + "\r\nComputerName = \"customizevmPos016\""
                                                                                                  + "\r\n"
                                                                                                  + "\r\n[Identification]"
                                                                                                  + "\r\nJoinWorkgroup = WORKGROUP"
                                                                                                  + "\r\n "
                                                                                                  + "\r\n[Networking]"
                                                                                                  + "\r\nInstallDefaultComponents=Yes"
                                                                                                  + "\r\n "
                                                                                                  + "\r\n[LicenseFilePrintData]"
                                                                                                  + "\r\nAutoMode = PerServer"
                                                                                                  + "\r\nAutoUsers = 5";
   public static final String[]     CUSTOMIZATION_WINDOWS_SYSPREPTEXT                    = { CUSTOMIZATION_WINDOWS_SYSPREPTEXT_DATA
                                                                                         // CUSTOMIZATION_WINDOWS_SYSPREPTEXT_DATA
                                                                                         };
   public static final String       CUSTOMIZATION_NAMESPEC_FIXEDNAME                     = "customizedvm";
   public static final String       CUSTOMIZATION_STATIC_PRIMARYDNS                      = "10.17.0.36";
   public static final String       CUSTOMIZATION_STATIC_SECONDARYDNS                    = "10.17.0.37";
   public static final String       CUSTOMIZATION_DNS_ENG_SUFFIX                         = "eng.vmware.com";
   public static final String       CUSTOMIZATION_DNS_VMWARE_SUFFIX                      = "vmware.com";
   public static final String       CUSTOMIZATION_MAC_ADDRESS                            = "MAC00";
   public static final String       CUSTOMIZATION_STATIC_IP_ESX20X                       = "10.20.59.191";
   public static final String       CUSTOMIZATION_STATIC_IP_ESX21X                       = "10.20.59.192";
   public static final String       CUSTOMIZATION_STATIC_IP_ESX25X                       = "10.20.59.193";
   public static final String       CUSTOMIZATION_STATIC_IP_ESX301                       = "10.20.59.195";
   public static final String       CUSTOMIZATION_STATIC_IP_ESX31                        = "10.20.59.196";
   public static final String       CUSTOMIZATION_STATIC_IP_EESX1                        = "10.20.58.198";
   public static final String       CUSTOMIZATION_STATIC_IP_ESX40                        = "10.20.59.196";
   public static final String       CUSTOMIZATION_STATIC_IP_EESX40                       = "10.20.58.198";
   public static final String       CUSTOMIZATION_STATIC_IP_EESX50                       = "10.20.58.198";
   public static final String       CUSTOMIZATION_STATIC_IP_SERVER_WINDOWS               = "10.20.58.194";
   public static final String       CUSTOMIZATION_STATIC_IP_SERVER_LINUX                 = "10.20.58.197";
   public static final String       CUSTOMIZATION_STATIC_IP2                             = "10.20.59.197";
   public static final String       CUSTOMIZATION_STATIC_GATEWAY                         = "10.20.59.253";
   public static final String       CUSTOMIZATION_STATIC_GATEWAY2                        = "10.20.59.253";
   public static final String       CUSTOMIZATION_STATIC_SUBNETMASK                      = "255.255.252.0";
   public static final String       CUSTOMIZATION_IPSPEC_SCRIPTNAME                      = "c:\\ip.txt";
   // public static final String CUSTOMIZATION_IPSPEC_SCRIPTNAME =
   // "/root/ip.txt";
   public static final String       CUSTOMIZATION_SPEC_INFO_DESCRIPTION                  = "Test Guest OS spec info";
   public static final String       CUSTOMIZATION_SPEC_INFO_NAME                         = "defaultcustomizationspec";
   public static final String       CUSTOMIZATION_SPEC_INFO_NAME_MAX_CHAR                = "defaultcustomizationspec3456789012345678901";
   public static final String       CUSTOMIZATION_SPEC_INFO_NEW_NAME                     = "defaultnewcustomizationspec";
   public static final String       CUSTOMIZATION_SPEC_INFO_DUP_NAME                     = "defaultdupcustomizationspec";
   public static final String       CUSTOMIZATION_SPEC_FOLDER_NEW_NAME                   = "defaultnewcustomizationspecfolder";
   public static final int          CUSTOMIZATION_SPEC_FOLDER_MAXCOUNT                   = 16;
   public static final String       CUSTOMIZATION_VISTA_GUESTID_PREFIX                   = "winVista";
   public static final String       CUSTOMIZATION_WIN2K8_GUESTID_PREFIX                  = "winLonghorn";
   public static final String       CUSTOMIZATION_WINDOWS7_X64_GUESTID_PREFIX            = "windows7_64Guest";
   public static final String       CUSTOMIZATION_WINDOWS7SERVER_GUESTID_PREFIX          = "windows7Server64Guest";
   public static final String       CUSTOMIZATION_WINDOWS2KPRO_GUESTID_PREFIX            = "win2000ProGuest";
   public static final String       CUSTOMIZATION_WINDOWS7_GUESTID_PREFIX                = "windows7";
   public static final String       CUSTOMIZATION_WINDOWS8_GUESTID_PREFIX                = "windows8";
   public static final String       CUSTOMIZATION_LOCAL_IP_PREFIX                        = "10.20.59";
   public static final String       CUSTOMIZATION_LOCAL_IP_PREFIX_1                      = "10.20.58";
   public static final String       CUSTOMIZATION_OSDC_IP_PREFIX                         = "10.18.45";
   public static final String       CUSTOMIZATION_BLR_KM_IP_PREFIX                       = "10.112.88";
   public static final String       CUSTOMIZATION_BLR_LOCAL_IP_PREFIX                    = "10.112";
   public static final String       MAC_ADDRESSTYPE_MANUAL                               = "manual";
   public static final String       MAC_ADDRESSTYPE_ASSIGNED                             = "assigned";
   public static final String       MAC_ADDRESSTYPE_GENERATED                            = "generated";
   public static final String       MAC_ADDRESS_ASSIGNED                                 = "00:50:56:80:23:12";
   public static final String       MAC_ADDRESS_MANUAL                                   = "00:50:56:03:23:12";
   public static final String       POINTINGDEVICE_AUTODETECT                            = "autodetect";
   public static final String       POINTINGDEVICE_MOUSESYSTEMS                          = "mousesystems";
   public static final String       POINTINGDEVICE_INTELLIMOUSE_EXPLORER_PS2             = "IntelliMouse Explorer PS/2";
   public static final String       POINTINGDEVICE_INTELLIMOUSE_PS2                      = "IntelliMouse PS/2";
   public static final String       POINTINGDEVICE_LOGITECH_MOUSEMAN_PS2                 = "Logitech MouseMan+ PS/2";
   public static final String       POINTINGDEVICE_MICROSOFT_SERIAL                      = "Microsoft Serial";
   public static final String       POINTINGDEVICE_PS2                                   = "PS2";
   public static final String       POINTINGDEVICE_MOUSEMAN_SERIAL                       = "MouseMan Serial";
   public static final String       MIGRATE_TEST_DC_NAME                                 = "migratedc";
   public static final String       MIGRATE_TEST_HOSTFOLDER_NAME                         = "migratehf";
   public static final String       MIGRATE_TEST_CLUSTERCOMPRES_NAME                     = "migratecompres";
   public static final String       MIGRATE_VM_MAXRES_NAME                               = "migratemaxresvm";
   public static final String       MIGRATE_VM_MAXCPU_NAME                               = "migratemaxcpuvm";
   public static final String       PROVISIONING_TEST_DC_NAME                            = "provisioning_dc";
   public static final String       PROVISIONING_TEST_HOSTFOLDER_NAME                    = "provisioning_hf";
   public static final String       PROVISIONING_TEST_CLUSTERCOMPRES_NAME                = "provisioning_cluster";
   public static final int          PROVISIONING_SINGLE_DATASTORE                        = 1;
   public static final int          PROVISIONING_TWO_DATASTORES                          = 2;
   public static final int          PROVISIONING_THREE_DATASTORES                        = 3;
   public static final int          PROVISIONING_FOUR_DATASTORES                         = 4;
   public static final int          PROVISIONING_SINGLE_DISK                             = 1;
   public static final int          PROVISIONING_TWO_DISKS                               = 2;
   public static final int          PROVISIONING_THREE_DISKS                             = 3;
   public static final int          PROVISIONING_FOUR_DISKS                              = 4;
   public static final int          PROVISIONING_SINGLE_CONTROLLER                       = 1;
   public static final int          PROVISIONING_MULTIPLE_CONTROLLER                     = 2;
   /*
    * DatastoreSystem related constants
    */
   public static final String       CREATE_LOCALDATASTORE_WINDOWS_PATH                   = ""
                                                                                                  + "C:\\home\\vmware\\createlocaldatastore";
   public static final String       CREATE_LOCALDATASTORE_LINUX_PATH                     = "/home/vmware/createlocaldatastore";
   public static final String       EMPTY_DATASTORE                                      = "[]/";
   public static final String       EMPTY_DATASTORE_FOR_WINDOWS                          = "[]";
   public static final String       FLP_IMAGEBACKING_PATH                                = "tmp/";
   public static final String       FLP_IMAGEBACKING_DATASTORE                           = TestConstants.EMPTY_DATASTORE
                                                                                                  + TestConstants.FLP_IMAGEBACKING_PATH;
   public static final String       READ_ONLY_DATASTORE                                  = "readOnly";

   /*
    * Security Rules related Constants
    */
   public static final String       VMware_Rules                                         = "VMWARE.rules";
   public static final String       VMware_Rules_BAK                                     = "VMWARE.bak";
   public static final String       Check1_Rules                                         = "check1.rules";

   /*
    * Constants related to regular expressions
    */
   public static final String       REGEX_DIGITS                                         = "\\d+";

   /*
    * StorageSystem related constants
    */
   public static final String       HOST_STORAGE_SCSI_ID_STRING                          = "3";
   public static final String       SCSI_DEVICE_DISK                                     = "disk";
   public static final String       SCSI_VIRTUAL_DISK                                    = "VIRTUAL-DISK";
   public static final String       VMFS_VER3                                            = "VMFS 3.0";
   public static final String       VMFS_VER2                                            = "VMFS 2.0";
   public static final String       HOST_STORAGE_DEFAULT_LUN_NAME                        = "vmhba1:0:1";
   public static final String       HOST_STORAGE_PATH_NAME_FOR_HBA_FO                    = "vmhba2:0:0";
   public static final String       HOST_STORAGE_PATH_NAME_FOR_SP_FO                     = "vmhba1:1:0";
   public static final String       HOST_STORAGE_PREFERRED_PATH_NAME_FOR_FIXED_POLICY    = "vmhba1:0:1";
   public static final int          HOST_STORAGE_DEFAULT_VMFS2_MAJOR_VERSION             = 2;
   public static final int          HOST_STORAGE_DEFAULT_VMFS3_MAJOR_VERSION             = 3;
   public static final int          HOST_STORAGE_DEFAULT_VMFS5_MAJOR_VERSION             = 5;
   public static final String       HOST_STORAGE_DEFAULT_VOLUMENAME                      = "shared1";
   public static final int          HOST_STORAGE_DEFAULT_BLOCKSIZE                       = 1;
   public static final int          HOST_STORAGE_DEFAULT_SCSI_PARTITION                  = 1;
   public static final String       HOST_FILESYSTEM_TYPE_ID_FC                           = "-4";
   public static final String       HOST_FILESYSTEM_TYPE_ID_FB                           = "-5";
   public static final String       HOST_INTERNET_SCSI_HBA_IP_ADDRESS1;
   public static final String       HOST_INTERNET_SCSI_HBA_IP_ADDRESS2;
   public static final String       HOST_INTERNET_SCSI_HBA_IP_ADDRESS3                   = "10.17.246.193";
   public static final String       HOST_INTERNET_SCSI_HOST_IP                           = "10.18.12.207";
   public static final String       HOST_INTERNET_SCSI_PRIMARY_DNS                       = "10.17.0.94";
   public static final String       HOST_INTERNET_SCSI_SECONDARY_DNS                     = "10.17.0.95";
   public static final String       HOST_INTERNET_SCSI_SUBNET_MASK                       = "255.255.254.0";
   public static final String       HOST_INTERNET_SCSI_DEFAULT_GATEWAY                   = "10.18.13.253";
   public static final int          HOST_INTERNET_SCSI_HBA_DEFAULT_PORT                  = 3260;
   public static final String       HOST_INTERNET_SCSI_DEFAULT_NAME;
   public static final String       HOST_INTERNET_SCSI_DEFAULT_NAME2;
   public static final String       HOST_INTERNET_SCSI_DEFAULT_NAME3                     = "iqn.1992-04.com.emc:ax.apm00054207420.b0";
   public static final String       HOST_INTERNET_SCSI_DEFAULT_CHAP_NAME                 = "iqn.2000-04.com.vmware:hard.iscsisdk076";
   public static final String       HOST_INTERNET_SCSI_DEFAULT_CHAP_SECRET_KEY           = "1234567890";
   public static final String       SOFTWARE_MODEL_STRING                                = "Software";
   public static final int          HARDWARE_ACCELERATION_STATE_ON                       = 1;
   public static final int          HARDWARE_ACCELERATION_STATE_OFF                      = 0;
   public static final String       SHARED_LUN_UID                                       = "sharedLunUid";
   public static final String       SHARED_DATASTORE_NAME                                = "sharedDatastoreName";
   public static final String       NUMBER_OF_EXTENDS                                    = "numOfExtends";

   public static final String       VSHARE_ARRAY;

   public static final String       NETAPP_FIBRE_CHANNEL_DISK                            = "NETAPP FIBRE Channel Disk";
   /*
    * iScsi related constants
    */

   /*
    * iScsi adapter types
    */
   public static final String       ADAPTER_TYPE_SOFTWARE                                = "software";
   public static final String       ADAPTER_TYPE_HARDWARE                                = "hardware";
   public static final String       ADAPTER_TYPE_OFFLOAD_ISCSI                           = "offloadiScsi";
   public static final String       ADAPTER_TYPE                                         = "adapterType";
   public static final String       ADAPTER_TYPE_SOFTWARE_FCOE                           = "fcoe";

   /*
    * Advanced Options constants
    */
   public static final String       ADV_OPT_FIRST_BURST_LENGTH                           = "FirstBurstLength";
   public static final String       ADV_OPT_MAX_RECV_DATA_SEG_LEN                        = "MaxRecvDataSegLen";
   public static final String       ADV_OPT_MAX_BURST_LENGTH                             = "MaxBurstLength";
   public static final String       ADV_OPT_MAX_OUTSTANDING_R2T                          = "MaxOutstandingR2T";
   public static final int          ADV_OPT_DATA_OFFLOAD_MIN_VAL1                        = 8192;
   public static final int          ADV_OPT_SWISCSI_MIN_VAL1                             = 512;
   public static final int          ADV_OPT_DATA_OFFLOAD_MAX_VAL1                        = 16777215;
   public static final int          ADV_OPT_MAX_OUTSTANDING_R2T_DATAOFFLOAD_VAL          = 1;
   public static final int          ADV_OPT_MAX_OUTSTANDING_R2T_SWISCSI_MIN_VAL          = 1;
   public static final int          ADV_OPT_MAX_OUTSTANDING_R2T_SWISCSI_MAX_VAL          = 8;
   public static final int          HW_ISCSI_MAX_ALIAS_LENGTH                            = 31;
   public static final int          ISCSI_MAX_NAME_LENGTH                                = 223;
   public static final int          ISCSI_MAX_ALIAS_LENGTH                               = 256;
   /*
    * Constants for DAS
    */
   public static final int          DAS_MIN_NUM_HOSTS                                    = 2;
   public static final int          DAS_MIN_FAILOVER_LEVEL                               = 2;
   public static final String       DAS_CONFIG_TASK_NAME                                 = "DasConfig.ConfigureHost";
   public static final String       DAS_UNCONFIG_TASK_NAME                               = "DasConfig.UnconfigureHost";
   public static final String       DEFAULT_DAS_CLUSTER_NAME                             = "DAS Cluster";
   public static final String       DAS_ENABLED                                          = "enabled";
   public static final String       DAS_VM_VM_ANTI_AFFINITY_RULE_KEY                     = "das.respectVmVmAntiAffinityRules";
   public static final int          DAS_FAILOVER_VM_REG_WAIT_COUNT                       = 60;
   public static final int          DAS_LB_FAILOVER_VM_REG_WAIT_COUNT                    = 75;                                                                                                            // For
   // load-balanced
   // das
   // failover
   public static final int          DAS_FAILOVER_WAIT_TIME                               = 2 * 60 * 1000;
   public static final boolean      DAS_DEFAULT_ADMISS_CONTROL                           = false;
   public static final int          DAS_DEFAULT_FAILOVER_LEVEL                           = 1;
   public static final String       AAMCONFIG_DIR                                        = "/opt/vmware/aam/ha";
   public static final String       AAMCONFIG_PERMS                                      = "0777";
   public static final String       AAMCONFIG_FILENAME                                   = "aam_config_util.pl";
   public static final String       AAMCONFIG_TESTSCRIPT_DIR                             = "/exit14/home/qa/aamtestutils/";
   public static final String       AAMCONFIG_TESTSCRIPT_DIR_EESX                        = "/vmfs/volumes/exit14-home/qa/aamtestutils/";
   public static final String       DAS_VM_FAILOVER_ENABLED                              = "das.vmFailoverEnabled";
   public static final String       DAS_VM_MAX_FAILURES                                  = "das.maxFailures";
   public static final String       DAS_VM_MAX_FAILURE_WINDOW                            = "das.maxFailureWindow";
   public static final String       DAS_VM_FAILURE_INTERVAL                              = "das.failureInterval";
   public static final String       DAS_MIN_UPTIME                                       = "das.minUptime";
   public static final int          DAS_VM_MAX_FAILURES_DEFAULT_VAL                      = 3;
   public static final int          DAS_VM_CRASH_TIMEOUT                                 = 100;
   public static final int          DAS_VM_RESET_MAX_TIMEOUT                             = 180;
   public static final int          DAS_VM_NO_TIMEOUT                                    = 0;
   public static final long         DAS_MIN_UPTIME_DEFAULT_VALUE                         = 120 * 1000;

   /*
    * Constants for ClusterDasVmSettings IsolationResponse
    */
   public static final String       DAS_ISOLATION_RESPONSE_NO_POWEROFF                   = "none";
   public static final String       DAS_ISOLATION_RESPONSE_POWEROFF                      = "powerOff";
   public static final String       DAS_ISOLATION_RESPONSE_NO_SHUTDOWN                   = "none";
   public static final String       DAS_ISOLATION_RESPONSE_SHUTDOWN                      = "shutdown";
   public static final String       DAS_ISOLATION_RESPONSE_CLUSTER                       = "clusterIsolationResponse";
   /*
    * Constants for NetworkFileSystem
    */
   public static final String       DATASTORETYPE;
   public static final String       NFS41_SECURITY_TYPE;
   public static final List<String> REMOTEHOST1_VALID_NFS;
   public static final String       REMOTEHOST1_VALID;
   public static final String       REMOTEPATH1_VALID_FOR_REMOTEHOST1;
   public static final String       REMOTEPATH2_VALID_FOR_REMOTEHOST1;
   public static final String       REMOTEPATH3_VALID_FOR_REMOTEHOST1;
   public static final String       REMOTEPATH4_VALID_FOR_ROOTSQUASHING;
   public static final String       REMOTEPATH5_VALID_FOR_ROOTSQUASHING;
   public static final String       REMOTEHOST2_VALID;
   public static final String       REMOTEPATH1_VALID_FOR_REMOTEHOST2;
   public static final String       REMOTEHOST_INVALID_NO_NFS_RUNNING;
   public static final String       REMOTEHOST_UDP_PROTOCOL;
   public static final String       REMOTEPATH_UDP_PROTOCOL;
   public static final String       REMOTEWINHOST1_VALID                                 = "10.20.59.209";
   public static final String       REMOTEPATH1_VALID_FOR_REMOTEWINHOST1                 = "export\\cifs1";
   public static final String       REMOTEPATH2_VALID_FOR_REMOTEWINHOST1                 = "export\\cifs2";
   public static final String       REMOTEPATH3_VALID_FOR_REMOTEWINHOST1                 = "export\\cifs3";
   public static final String       REMOTEWINHOST2_VALID                                 = "10.20.59.210";
   public static final String       REMOTEPATH1_VALID_FOR_REMOTEWINHOST2                 = "export\\cifs1";

   /*
    * HMS OVF for HMS SDRS Interop
    */
   public static final String       HMS_OVF                                              = " http://pa-dbc1103.eng.vmware.com/drmqe/templates/HMS_OVF/vSphere_Replication_OVF10.ovf";

   /*
    * Constants for testing Handling of Host IP change by VC
    */
   public static final String       STATIC_IP_1                                          = "10.138.56.244";
   public static final String       STATIC_IP_2                                          = "10.138.56.243";
   public static final String       STATIC_IP_3                                          = "10.138.56.245";
   public static final String       STATIC_IP_4                                          = "10.138.56.246";
   /*
    * Constants for RescanHba
    */
   public static final String       HBA_FOR_RESCAN;
   public static final String       VM_CREATE_DEFAULT_DEVICE_TYPE                        = "ALL_DEFAULT_DEVICE";
   public static final String[]     VM_CREATE_DEFAULT_DEVICE_LIST                        = {
            VM_VIRTUALDEVICE_SCSI_BUSL_CONTROLLER, VM_VIRTUALDEVICE_CDROM,
            VM_VIRTUALDEVICE_DISK, VM_RECOMMENDED_ETHERNET,
            VM_VIRTUALDEVICE_FLOPPY                                                     };
   public static final String       VM_CREATE_BUSL_MAX_DISKS                             = "MAX_DISKS";
   public static final String       VM_VIRTUALDEVICE_BUSL_DISK                           = "BUSL_DISKS";
   public static final String       VM_VIRTUALDEVICE_LSI_DISK                            = "LSI_DISKS";
   /*
    * ScheduledTask related constants
    */
   public static final int          MAX_SCHEDULEDTASKS                                   = 100;
   public static final String       SCHEDULEDTASK_DESC                                   = "Schedule Task for Testing";
   public static final String       SCHEDULEDTASK_SCRIPT                                 = "";
   public static final String       SCHEDULEDTASK_EMAIL_BODY                             = "body";
   public static final String       SCHEDULEDTASK_EMAIL_CCLIST                           = "ccList";
   public static final String       SCHEDULEDTASK_EMAIL_SUBJECT                          = "subject";
   public static final String       SCHEDULEDTASK_EMAIL_TOLIST                           = "toList";
   public static final String       STASKSCHEDULER_AFTERSTARTUP                          = "AfterStartup";
   public static final String       STASKSCHEDULER_ONCE                                  = "Once";
   public static final String       STASKSCHEDULER_HOURLY                                = "Hourly";
   public static final String       STASKSCHEDULER_DAILY                                 = "Daily";
   public static final String       STASKSCHEDULER_WEEKLY                                = "Weekly";
   public static final String       STASKSCHEDULER_MONTHLYBYDAY                          = "MonthlyByDay";
   public static final String       STASKSCHEDULER_MONTHLYBYWEEKDAY                      = "MonthlyByWeekday";
   public static final int          STASKSCHEDULER_TOTALNO                               = 7;
   public static final String       ACTION_VM_POWERON                                    = "PowerOnVM_Task";
   public static final String       ACTION_VM_POWEROFF                                   = "PowerOffVM_Task";
   public static final String       ACTION_VM_SUSPEND                                    = "SuspendVM_Task";
   public static final String       ACTION_VM_RESET                                      = "ResetVM_Task";
   public static final String       ACTION_VM_CREATESNAPSHOT                             = "CreateSnapshot_Task";
   public static final String       ACTION_VM_REBOOTGUEST                                = "RebootGuest";
   public static final String       ACTION_VM_CUSTOMIZE                                  = "CustomizeVM_Task";
   public static final String       ACTION_VM_MIGRATE                                    = "MigrateVM_Task";
   public static final String       ACTION_VM_RELOCATE                                   = "RelocateVM_Task";
   public static final String       ACTION_VM_CLONE                                      = "CloneVM_Task";
   public static final String       ACTION_VM_UPGRADETOOLS                               = "UpgradeTools_Task";
   public static final String       ACTION_VM_UPDATERESOURCESETTING                      = "UpdateResourceSetting_TASK";
   public static final String[]     ACTION_VM_ARRAY                                      = {
            ACTION_VM_POWERON, ACTION_VM_POWEROFF, ACTION_VM_SUSPEND,
            ACTION_VM_RESET, ACTION_VM_CREATESNAPSHOT, ACTION_VM_REBOOTGUEST,
            ACTION_VM_CUSTOMIZE, ACTION_VM_MIGRATE, ACTION_VM_RELOCATE,
            ACTION_VM_CLONE, ACTION_VM_UPGRADETOOLS,
            ACTION_VM_UPDATERESOURCESETTING                                             };
   public static final String       ACTION_HOST_ENTER_MAINTENANCE_MODE                   = "EnterMaintenanceMode_Task";
   public static final String       ACTION_HOST_EXIT_MAINTENANCE_MODE                    = "ExitMaintenanceMode_Task";
   public static final String       ACTION_HOST_ENTER_STAND_BY_MODE                      = "PowerDownHostToStandBy_Task";
   public static final String       ACTION_HOST_EXIT_STAND_BY_MODE                       = "PowerUpHostFromStandBy_Task";
   public static final String       ACTION_HOST_REBOOT_HOST                              = "RebootHost_Task";
   public static final String       ACTION_HOST_RECONNECT_HOST                           = "ReconnectHost_Task";
   public static final String       ACTION_HOST_DISCONNECT_HOST                          = "DisconnectHost_Task";
   public static final String[]     ACTION_HOST_ARRAY                                    = {
            ACTION_HOST_ENTER_MAINTENANCE_MODE,
            ACTION_HOST_EXIT_MAINTENANCE_MODE, ACTION_HOST_ENTER_STAND_BY_MODE,
            ACTION_HOST_EXIT_STAND_BY_MODE, ACTION_HOST_REBOOT_HOST,
            ACTION_HOST_RECONNECT_HOST, ACTION_HOST_DISCONNECT_HOST                     };
   public static final String       ACTION_FOLDER_CREATEVM                               = "CreateVM_Task";
   public static final String       ACTION_FOLDER_IMPORTVM                               = "ImportVM";
   public static final String       ACTION_FOLDER_ADDSTANDALONEHOST                      = "AddStandaloneHost_Task";
   public static final String       ACTION_FOLDER_CREATE                                 = "CreateFolder";
   public static final String[]     ACTION_FOLDER_ARRAY                                  = {
            ACTION_FOLDER_CREATEVM, ACTION_FOLDER_IMPORTVM,
            ACTION_FOLDER_ADDSTANDALONEHOST                                             };
   public static final String       ACTION_CLUSTER_RECONFIG                              = "ReconfigureComputeResource_Task";
   public static final String       ACTION_STORAGEPOD_RECONFIG                           = "vim.StorageResourceManager.configureStorageDrsForPod";
   public static final String       ACTION_CONFIG_DATASTORE_IORM                         = "vim.StorageResourceManager.ConfigureDatastoreIORM";
   public static final String[]     ACTION_CLUSTER_ARRAY                                 = { ACTION_CLUSTER_RECONFIG };
   public static final String[]     ACTION_STORAGEPOD_ARRAY                              = { ACTION_STORAGEPOD_RECONFIG };
   public static final String[]     ACTION_DATASTORE_ARRAY                               = { ACTION_CONFIG_DATASTORE_IORM };
   /*
    * Task related constants
    */
   public static final int          MAX_ACTIVE_TASKS                                     = 100;
   public static final int          SCSI_CONTROLLER_UNITNUMBER                           = 7;
   public static final int          CLONEVM_DISK                                         = 1024;
   public static final int          RELOCATEVM_DISK                                      = 1024;
   public static final int          SCSI_MAX_DISKS                                       = 16;
   public static final String       MAX_CDROMS                                           = "MAX_CDROMS";
   public static final String       MAX_KEYBOARDS                                        = "MAX_KEYBOARDS";
   public static final String       MAX_SERIALPORTS                                      = "MAX_SERIALPORTS";
   public static final String       MAX_PARALLELPORTS                                    = "MAX_PARALLELPORTS";
   public static final String       MAX_IDECONTROLLERS                                   = "MAX_IDECONTROLLERS";
   public static final String       MAX_FLOPPY                                           = "MAX_FLOPPY";
   public static final String       MAX_SOUNDBLASTER                                     = "MAX_SOUNDBLASTER";
   public static final String       MAX_ENSONIQ                                          = "MAX_ENSONIQ";
   public static final String       MAX_ETHERNET                                         = "MAX_ETHERNET";
   public static final String       MAX_ETHERNET_PCNET32                                 = "MAX_ETHERNET_PCNET32";
   public static final String       MAX_ETHERNET_VMXNET                                  = "MAX_ETHERNET_VMXNET";
   public static final String       MAX_ETHERNET_VMXNET2                                 = "MAX_ETHERNET_VMXNET2";
   public static final String       MAX_VIDEOCARD                                        = "MAX_VIDEOCARD";
   public static final String       MAX_POINTINGDEVICE                                   = "MAX_POINTINGDEVICE";
   public static final String       MAX_USBDEVICE                                        = "MAX_USBDEVICE";
   public static final String       MAX_LSI_DISKS                                        = "MAX_LSI_DISKS";
   public static final String       MAX_BUSL_DISKS                                       = "MAX_BUSL_DISKS";
   public static final String       MAX_VMWPV_DISKS                                      = "MAX_VMWPV_DISKS";
   public static final String       MAX_BUSL_CONTROLLER                                  = "MAX_BUSLOGIC";
   public static final String       MAX_LSI_CONTROLLER                                   = "MAX_LSI";
   public static final String       MAX_VMWPV_CONTROLLER                                 = "MAX_VMWPV";
   public static final String       MAX_PCICONTROLLER                                    = "MAX_PCICONTROLLER";
   public static final String       MAX_PS2CONTROLLER                                    = "MAX_PS2CONTROLLER";
   public static final String       MAX_SIOCONTROLLER                                    = "MAX_SIOCONTROLLER";
   public static final String       MAX_USBCONTROLLER                                    = "MAX_USBCONTROLLER";
   public static final String       DEVICE_MAX_COUNT                                     = "max";
   public static final String       DEVICE_MIN_COUNT                                     = "min";
   public static final String       DEVICE_DEFAULT_COUNT                                 = "default";
   public static final int          VM_TASKINFO_DELAY                                    = 100;
   public static final String       VM_POWERON_TASK                                      = "ExecuteVmPowerOn";
   public static final String       VM_POWERON_TASK_DESCP                                = "VirtualMachine.powerOn";
   public static final String       VMOTION_TASK                                         = "Drm.ExecuteVMotionLRO";
   public static final String       DRM_POWERON_TASK                                     = "Drm.ExecuteVmPowerOnLRO";
   public static final int          MAX_WAIT_TIME_FIND_TASK                              = 60000;
   public static final int          WAIT_TIME_BETWEEN_FIND                               = 5000;
   public static final int          APPLY_RECOMMENDATIONS_WAIT_SECS                      = 120;
   /*
    * Constants for Alarm
    */
   public static final String       EMAIL_BODY_VALUE                                     = "This is test for Alarm";
   public static final String       EMAIL_CC_VALUE                                       = "vctests@vmware.com";
   public static final String       EMAIL_SUB_VALUE                                      = "Alarm Testing";
   public static final String       EMAIL_TO_VALUE                                       = "vctests@vmware.com";
   public static final int          MAX_ALARM_COUNT                                      = 10;
   public static final int          ALARM_REPORTING_FREQUENCY                            = 60;
   public static final int          ALARM_REPORTING_TOLERANCE                            = 0;
   public static final String       ALARM_RUNSCRIPT                                      = "c:\\WINDOWS\\system32\\cmd.exe /C c:\\alarm_script.bat";
   public static final String       DATASTORE_PATH                                       = "summary.accessible";
   public static final String       DATASTORE_TYPE                                       = "Datastore";
   public static final String       DATASTORE_CLUSTER_TYPE                               = "StoragePod";
   public static final String       HOST_DISCONNECTED                                    = "disconnected";
   public static final String       HOST_CONNECTED                                       = "connected";
   public static final String       HOST_PATH                                            = "runtime.connectionState";
   public static final String       HOST_POWER_PATH                                      = "runtime.powerState";
   public static final String       HOST_TYPE                                            = "HostSystem";
   public static final String       VM_PATH                                              = "runtime.powerState";
   public static final String       VM_TYPE                                              = "VirtualMachine";
   public static final String       VM_POWERED_ON                                        = "poweredOn";
   public static final String       VM_POWERED_OFF                                       = "poweredOff";
   public static final String       VM_SUSPENED                                          = "connected";
   public static final int          ALARM_FREQUENCY_FOR_TRIGGER_IN_SEC                   = 240;
   public static final int          SLEEP_TIME_FOR_TRIGGER_ONE                           = 20000;
   public static final int          SLEEP_TIME_FOR_TRIGGER_TWO                           = 200000;
   public static final int          SLEEP_TIME_FOR_ALARM_EVENT_LATENCY                   = 10000;
   public static final int          EVENT_LATENCY_TIMEOUT                                = 30000;
   public static final int          DEF_SLEEP_TIME_EVENT_LATENCY                         = 8000;
   public static final int          SLEEP_TIME_TEN_SECONDS                               = 10000;
   public static final int          ALARMCOUNTERVMCPU                                    = 0x01000001;
   public static final int          ALARMCOUNTERVMMEMORY                                 = 0x01010001;
   public static final int          ALARMCOUNTERVMNETWORK                                = 0x01030001;
   public static final int          ALARMCOUNTERVMDISK                                   = 0x01020001;
   public static final int          ALARMCOUNTERHOSTCPU                                  = 0x00000001;
   public static final int          ALARMCOUNTERHOSTMEMORY                               = 0x00010001;
   public static final int          ALARMCOUNTERHOSTNETWORK                              = 0x00030001;
   public static final int          ALARMCOUNTERHOSTDISK                                 = 0x00020001;
   public static final String       ALARMMETRICINSTANCE                                  = "";
   public static final String       PERF_NAME_INFO                                       = PERF_COUNTERNAME_USAGE;
   public static final String       PERF_DEVICE_VM_CPU                                   = PERF_DEVICE_CPU;
   public static final String       PERF_DEVICE_VM_MEM                                   = PERF_DEVICE_MEM;
   public static final String       PERF_DEVICE_VM_DISK                                  = PERF_DEVICE_DISK;
   public static final String       PERF_DEVICE_VM_NET                                   = PERF_DEVICE_NET;
   public static final String       PERF_DEVICE_HOST_CPU                                 = PERF_DEVICE_CPU;
   public static final String       PERF_DEVICE_HOST_MEM                                 = PERF_DEVICE_MEM;
   public static final String       PERF_DEVICE_HOST_DISK                                = PERF_DEVICE_DISK;
   public static final String       PERF_DEVICE_HOST_NET                                 = PERF_DEVICE_NET;
   public static final String       PERF_DEVICE_DATASTORE_CPU                            = PERF_DEVICE_CPU;
   public static final String       PERF_DEVICE_DATASTORE_MEM                            = PERF_DEVICE_MEM;
   public static final String       PERF_DEVICE_DATASTORE_DISK                           = "datastore";
   public static final String       PERF_DEVICE_DATASTORE_VIRTUAL_DISK                   = "datastore";
   public static final String       PERF_DEVICE_DATASTORE_NET                            = PERF_DEVICE_NET;
   public static final String       PERF_DEVICE_DATASTORE_SNAPSHOT                       = PERF_DEVICE_DISK;
   public static final String       PERF_DEVICE_DATASTORE_ALLOCATION                     = PERF_DEVICE_DISK;
   public static final String       PERF_DEVICE_DATASTORE_FILE                           = PERF_DEVICE_DISK_FILE;
   public static final String       PERF_DEVICE_DATASTORE_VM                             = PERF_DEVICE_DISK;
   public static final String       CONNECTED_STATE_FOR_DATASTORE_STATE_ALARM            = "True";
   public static final String       DISCONNECTED_STATE_FOR_DATASTORE_STATE_ALARM         = "False";
   
   /*
    * EAM constants related to repository.
    */
   public static String       EAM_OVF_REPOSITORY;
   public static final String       EAM_OVF_IPV4_REPOSITORY;
   public static final String       EAM_OVF_IPV6_REPOSITORY;
   public static final String       EAM_REPOSITORY_DRIVE;

   /*
    * IoFilter constants.
    */
   public static String       IOFILTER_VIB_REPOSITORY;

   /*
    * NIS Server Location
    */
   public static final String       NIS_SERVER_LOCATION;

   /*
    * Constants for Cluster
    */
   public static final String       CLUSTER_DEFAULT_OPTION_KEY                           = "Cluster_Default_Option";
   public static final String       CLUSTER_DEFAULT_OPTION_VALUE                         = "Unknown Value";

   /*
    * Variable for Events
    */
   public static final boolean      STOP_EVENT_MONITOR                                   = false;
   public static final int          EVENT_MSG_MAX_LENGTH                                 = 80;
   public static final int          EVENT_MSG_MIN_LENGTH                                 = 1;
   public static final String       VM_STATE_REVERETED_TO_SNAP_EVENTID                   = "com.vmware.vc.vm.VmStateRevertedToSnapshot";
   public static final String[]     VM_EVENTS                                            = {
            "vim.event.VmCreatedEvent", "vim.event.VmPoweredOnEvent",
            "vim.event.VmRegisteredEvent",                                              };
   public static final String[]     HOST_EVENTS                                          = {
            "vim.event.HostDisconnectedEvent", "vim.event.HostShutdownEvent"            };
   public static final String[]     RESOURCEPOOL_EVENTS                                  = {
            "vim.event.ResourcePoolCreatedEvent",
            "vim.event.ResourcePoolMovedEvent"                                          };
   public static final String       VM_POWERED_ON_EVENT                                  = "vim.event.VmPoweredOnEvent";
   public static final String       PROP_UPDATES_VERSION                                 = "PROP_UPDATES_VERSION";
   public static final String       VIRTUALLSILOGICCONTROLLER_NAME                       = "VirtualLsiLogicController";
   public static final String       VIRTUALBUSLOGICCONTROLLER_NAME                       = "VirtualBusLogicController";
   public static final String       VIRTUALIDELOGICCONTROLLER_NAME                       = "VirtualIDEController";
   public static final String       VIRTUALLSILOGICSASCONTROLLER_NAME                    = "VirtualLsiLogicSASController";
   public static final String       PARAVIRTUALSCSICONTROLLER_NAME                       = "ParaVirtualSCSIController";
   public static final String       VIRTUALCONTROLLERTYPE                                = "VirtualControllerType";

   public static final int          VM_MAXCOUNT                                          = 2;
   public static final int          MULTITHREADED_VMS                                    = 2;
   public static final String       VM_TEMPLATE_CONFIG_FILE_EXTENSION                    = ".vmtx";
   public static final String       FLOPPY_FILEEXTN                                      = "*.flp";
   public static final String       CDROM_FILEEXTN                                       = "*.iso";
   public static final String       VMCONFIG_FILEEXTN                                    = "*.vmx";
   public static final String       VMLOG_FILEEXTN                                       = "*.log";
   public static final String       VMNVRAM_FILEEXTN                                     = "*nvram";
   public static final String       VMDISK_FILEEXTN                                      = "*.vmdk";
   public static final String       VMSNAPSHOT_FILEEXTN                                  = "*.vmsn";
   public static final String       ALLQUERY                                             = "ALLQUERY";
   public static final Integer[]    CONFIGVERSIONS                                       = {
            4, 3                                                                        };
   public static final String[]     DISKTYPES                                            = {
            "VirtualDiskFlatVer1BackingInfo", "VirtualDiskFlatVer2BackingInfo",
            "VirtualDiskRawDiskMappingVer1BackingInfo",
            "VirtualDiskSparseVer1BackingInfo",
            "VirtualDiskSparseVer2BackingInfo",                                         };
   public static final String[]     DISKEXTENSIONS                                       = {
            "*.vmdk", "*.dsk"                                                           };
   public static final String       INVALID_DATASTORE                                    = "[invaliddatastore]";
   public static final String       VM_FOR_DATASTOREBROWSER                              = "VmForDataStoreBrowser";
   public static final String       CDROM_ATAPI_BACKINGNAME                              = "D:";
   public static final String       FLOPPYBACKING_DEVICENAME                             = "A:";
   public static final String       DATASTOREBROWSER_ISOIMAGE                            = "datastorebrowser.iso";
   public static final String       DATASTOREBROWSER_FLOPPY                              = "datastorebrowser.flp";
   public static final String       DATASTOREBROWSER_SERIALPORT                          = "datastorebrowser.flp";
   public static final String       DATASTOREBROWSER_DELETE_FLOPPY                       = "deletefile.flp";
   public static final String       DATASTOREBROWSER_DELETE_ISOIMAGE                     = "deletefile.iso";
   /*
    * Constants for escher and dali volume paths
    */
   public static final String       ESX2X_VOLUME_PATH                                    = "/vmfs/";
   public static final String       ESX30_VOLUME_PATH                                    = "/vmfs/volumes/";
   public static final String       SERVER_VOLUME_PATH                                   = "/var/lib/vmware/Virtual\\ Machines";
   public static final String       SERVER_ON_WINDOWS_VOLUME_PATH                        = "C:\\Virtual Machines";

   /*
    * Constant for datastore type
    */
   public static final String       VMFS_DATASTORE_TYPE                                  = "VMFS";
   public static final String       NAS_DATASTORE_TYPE                                   = "NFS";
   public static final String       VSAN_DATASTORE_TYPE                                  = "VSAN";
   public static final String       VVOL_DATASTORE_TYPE                                  = "VVOL";
   public static final String       ISCSI_DATASTORE_TYPE                                 = "ISCSI";
   public static final String       SERVER_DATASTORE_TYPE                                = "LOCAL";
   public static final String       SERVER_CIFS_DATASTORE_TYPE                           = "CIFS";
   public static final String       DEFAULT_DATASTORE_TYPE                               = VVOL_DATASTORE_TYPE
                                                                                                  + " "
                                                                                                  + VSAN_DATASTORE_TYPE
                                                                                                  + " "
                                                                                                  + VMFS_DATASTORE_TYPE
                                                                                                  + " "
                                                                                                  + SERVER_DATASTORE_TYPE
                                                                                                  + " "
                                                                                                  + SERVER_CIFS_DATASTORE_TYPE
                                                                                                  + " "
                                                                                                  + NAS_DATASTORE_TYPE
                                                                                                  + " "
                                                                                                  + ISCSI_DATASTORE_TYPE;

   /*
    * Constants for specific PE on a VVOL ds
    */
   public static final String       VVOL_BLOCK_DATASTORE_TYPE                            = "VVOL_ISCSI";
   public static final String       VVOL_NAS_DATASTORE_TYPE                              = "VVOL_NFS";
   public static final String       VVOL_PEPSI                                           = "PEPSI";
   public static final String       VVOL_COKE                                            = "COKE";


   /* Enumeration for datastore modes */
   public enum DatastoreMode {
      IN_MAINTENANCE("inMaintenance"), NORMAL("normal");

      String mode;

      public String value()
      {
         return this.mode;
      }

      private DatastoreMode(String mode)
      {
         this.mode = mode;
      }
   };

   /*
    * Constant for vsan datastore name
    */
   public static final String                     VSAN_DATASTORE_NAME                            = "vsanDatastore";
   /*
    * Constant for VM Metadata
    */
   public static final String                     VM_METADATA_OPERATION_UPDATE_VALUE             = "Update";
   public static final String                     VM_METADATA_OPERATION_REMOVE_VALUE             = "Remove";
   public static final String                     VM_METADATA_OWNER                              = "ComVmwareVsphereHA";
   /*
    * Constants for Reconfig Cluster and ReconfigureEx for ComputeResource
    */
   public static final String                     STR_DASCONFIG                                  = "ClusterConfigSpecEx.DasConfig";
   public static final String                     STR_DASVMCONFIG                                = "ClusterConfigSpecEx.DasVmConfigSpec";
   public static final String                     STR_DASCONFIG_DEFAULT_VM_SETTINGS              = "ClusterDasConfigInfo.DefaultVmSettings";
   public static final String                     STR_DASCONFIG_FAILOVER_LEVEL                   = "ClusterDasConfigInfo.FailoverLevel";
   public static final String                     STR_DRSCONFIG                                  = "ClusterConfigSpecEx.DrsConfig";
   public static final String                     STR_DRSVMCONFIG                                = "ClusterConfigSpecEx.DrsVmConfigSpec";
   public static final String                     STR_RULESINFO                                  = "ClusterConfigSpecEx.RulesSpec";
   public static final String                     STR_DASVMCONFIG_OPERATION                      = "ClusterDasVmConfigSpec.Operation";
   public static final String                     STR_AFFINITYRULE_OPERATION                     = "ClusterAffinityRuleSpec.Operation";
   public static final String                     STR_ANTIAFFINITYRULE_OPERATION                 = "ClusterAntiAffinityRuleSpec.Operation";
   public static final String                     STR_AFFINITY_RULE                              = "ClusterAffinityRuleSpec";
   public static final String                     STR_ANTI_AFFINITY_RULE                         = "ClusterAntiAffinityRuleSpec";
   public static final String                     STR_DRSVMCONFIG_OPERATION                      = "ClusterDrsVmConfigSpec.Operation";
   public static final String                     STR_DPMHOSTCONFIG_OPERATION                    = "ClusterDpmHostConfigSpec.Operation";
   public static final String                     STR_VMSWAPPLACEMENT                            = "ClusterConfigSpecEx.VmSwapPlacement";
   public static final String                     STR_DPMCONFIG                                  = "ClusterConfigSpecEx.DpmConfig";
   public static final String                     STR_DPMHOSTCONFIG                              = "ClusterConfigSpecEx.DpmHostConfigSpec";
   public static final String                     DPM_OPTION_HISTORY_SECS_HOST_OFF               = "VmDemandHistorySecsHostOff";
   public static final String                     DPM_OPTION_HISTORY_SECS_HOST_ON                = "VmDemandHistorySecsHostOn";
   public static final String                     AFFINE                                         = "AFFINE";
   public static final String                     ANTI_AFFINE                                    = "ANTI_AFFINE";
   public static final int                        DPM_STANDBY_REC_WAIT_SECS                      = 1200;                                                                                       // 1200=default
   public static final int                        DPM_POWERON_REC_WAIT_SECS                      = 150;                                                                                        // 300=default
   public static final int                        DPM_MIGRATION_WAIT                             = 120;
   public static final int                        DPM_WAIT_SECS_GRACEPERIOD                      = 60 * 2;
   public static final int                        DPM_TEST_TIMEOUT_SECS_LONG                     = 60 * 60;                                                                                    // 1
                                                                                                                                                                                                // hour
                                                                                                                                                                                                // Max.
   public static final int                        DPM_TEST_TIMEOUT_SECS                          = 60 * 40;
   public static final String                     DPM_ENTERSTANDBY_TASK                          = "Drm.EnterStandbyLRO";
   public static final String                     DPM_EXITSTANDBY_TASK                           = "Drm.ExitStandbyLRO";
   public static final String                     EXITSTANDBY_TASK                               = "HostSystem.exitStandbyMode";
   public static final double                     DPM_PCPU_PER_VMOTION_RESERVE                   = .3;
   public static final double                     DPM_DEFAULT_VMS_COUNT_PER_HOST                 = 2;
   public static final int                        DPM_RECOMMENDATION_NO_TIMEOUT                  = 0;
   public static final boolean                    DPM_DAS_DEFAULT_ADMISS_CONTROL                 = true;
   public static final int                        DPM_AGGRESSIVE_POWERACTIONRATE                 = 1;
   public static final int                        DPM_DEFAULT_POWERACTIONRATE                    = 3;
   public static final int                        DPM_CONSERVATIVE_POWERACTIONRATE               = 5;
   public static final String                     DPM_MIN_POWERED_ON_CPU_KEY                     = "MinPoweredOnCpuCapacity";
   public static final String                     DPM_MIN_POWERED_ON_MEM_KEY                     = "MinPoweredOnMemCapacity";
   public static final int                        DPM_INVOCATION_WAIT_SECS                       = 300;                                                                                        // 300=default
   public static final int                        VM_RES_HOG_TOOLS_DELAY                         = 1000 * 60 * 3;
   /*
    * Maintenance mode
    */
   public static final int                        ENTERMAINTENANCEMODE_TIMEOUT;
   public static final int                        ENTERMAINTENANCEMODE_NO_TIMEOUT                = 0;
   public static final int                        DRS_RECOMMENDATION_DELAY                       = 130 * 1000;
   public static final int                        DRS_ALGORITHM_COMPUTE_DELAY                    = 3 * 60 * 1000;
   public static final int                        DRS_MIGRATION_DELAY                            = 90 * 1000;
   public static final int                        DRS_POLLING_INTERVAL                           = 120 * 1000;
   public static final int                        DRS_VMS_CPU_MEMLOAD_DELAY                      = 120 * 1000;
   public static final String                     CUSTOMIZATION_GUEST_TYPE_WINDOWS               = "windowsGuest";
   public static final String                     CUSTOMIZATION_GUEST_TYPE_LINUX                 = "linuxGuest";
   public static final int                        EXIT_MAINTMODE_DEFAULT_TIMEOUT_SECS            = 60;
   public static final String                     START_CPULOAD_SCRIPT                           = "c:\\perftools\\start-cpuperf.bat";
   public static final String                     START_MEMLOAD_SCRIPT                           = "c:\\perftools\\start-memperf.bat";
   public static final String                     START_OVERHEAD_SCRIPT                          = "c:\\perftools\\start-OverheadMem.bat";
   public static final String                     START_IOMETER_SCRIPT                           = "c:\\IOMeter\\startIOMeter.bat";
   public static final String                     STOP_CPULOAD_SCRIPT                            = "c:\\perftools\\stop-cpuperf.bat";
   public static final String                     STOP_MEMLOAD_SCRIPT                            = "c:\\perftools\\stop-memperf.bat";
   public static final String                     STOP_IOMETER_SCRIPT                            = "c:\\IOMeter\\stopIOMeter.bat";
   /*
    * Different DRS automation levels
    */
   public static final String                     DRS_MANUAL_MODE                                = "manual";
   public static final String                     DRS_PARTIALLY_AUTOMATED_MODE                   = "partiallyAutomated";
   public static final String                     DRS_FULLY_AUTOMATED_MODE                       = "fullyAutomated";
   public static final String                     SDRS_FULLY_AUTOMATED_MODE                      = "automated";
   public static final String                     SDRS_MANUAL_MODE                               = "manual";
   public static final String                     STORAGE_PLACEMENT_TYPE_CLONE                   = "clone";
   public static final String                     STORAGE_PLACEMENT_TYPE_CREATE                  = "create";
   public static final String                     STORAGE_PLACEMENT_TYPE_RECONFIGURE             = "reconfigure";
   public static final String                     STORAGE_PLACEMENT_TYPE_RELOCATE                = "relocate";
   /*
    * Different types of recommendations Actions
    */
   public static final String                     DRS_HOST_POWER_ON_OR_OFF_ACTIONTYPE            = "HostPowerV1";
   public static final String                     DRS_VM_POWERON_ACTIONTYPE                      = "VmPowerV1";
   public static final String                     DRS_VM_MIGRATION_ACTIONTYPE                    = "MigrationV1";
   /*
    * Standby mode
    */
   public static final int                        ENTERSTANDBYMODE_TIMEOUT                       = 120;
   public static final int                        ENTERSTANDBYMODE_NO_TIMEOUT                    = 0;
   public static final int                        EXITSTANDBYMODE_TIMEOUT                        = 1800;
   public static final int                        EXITSTANDBYMODE_NO_TIMEOUT                     = 0;
   // public static final int ENTERSTANDBYMODE_RECOMMEND_DELAY = 300*1000;
   // public static final int EXITSTANDBYMODE_RECOMMEND_DELAY = 1800*1000;
   /*
    * SYNC calls -- Period (in seconds) for polling the server for Active Tasks
    */
   public static final int                        SYNC_ACTIVETASKREQUEST_TIMEOUT                 = 300;
   public static final int                        SYNC_ACTIVETASKREQUEST_DELAY                   = 2;
   /*
    * Constant for Remote server /client
    */
   public static final String                     UNIX_SCRIPT_START                              = "#! /bin/sh\n";
   public static final String                     UNIX_SCRIPT_END                                = "#END";
   public static final String                     TEST_FILE_COMPLETED                            = "Done";
   public static final int                        REMOTE_SERVER_PORT                             = 9090;
   public static final String                     OS_UNIX                                        = "unix";
   public static final String                     UNIX_PATH                                      = "/temp/";
   public static final String                     WINDOWS_PATH                                   = "c:\\temp\\";
   public static final int                        NUM_PORT                                       = 32;
   public static final int                        CPU_LOAD                                       = 1;
   public static final int                        MEM_LOAD                                       = 2;
   public static final int                        CPU_MEM_LOAD                                   = 3;
   public static final int                        NO_LOAD                                        = 4;
   public static final int                        VM_LOW_LOAD_PERC                               = 5;
   public static final int                        VM_HIGH_LOAD_PERC                              = 6;
   public static final int                        OVERHEAD_MEM_LOAD                              = 7;
   public static final int                        STORAGE_IO_LOAD                                = 8;
   public static final int                        CPU_MEM_IO_LOAD                                = 9;
   public static final String                     DRS_OPTIONKEY_MEMREBAL                         = "MemRebal";
   public static final String                     SIZE_TYPE_KB                                   = "KB";
   public static final String                     SIZE_TYPE_MB                                   = "MB";
   public static final String                     SIZE_TYPE_GB                                   = "GB";
   public static final String                     SIZE_TYPE_TB                                   = "TB";
   public static final String                     VM_LOADED                                      = "LOADED_VM";
   public static final String                     VM_NOTLOADED                                   = "LOADED_VM";
   public static final int                        DRS_AGGRESSIVE_VMOTIONRATE                     = 1;
   public static final int                        DRS_NORMAL_VMOTIONRATE                         = 3;
   public static final int                        DRS_CONSERVATIVE_VMOTIONRATE                   = 5;
   public static final int                        DRS_DEFAULT_VMOTIONRATE                        = 1;
   public static final int                        DRS_CLUSTER_BALANCE_RETRY                      = 5;
   public static final String                     INVALID_GUEST_IP                               = "0.0.0.0";
   public static final String                     DUMMY_IP                                       = "100.100.100.100";
   public static final String                     DUMMY_IP_ONE                                   = "100.100.100.100";
   public static final String                     BAD_GUEST_IP_START                             = "169.";
   public static final String                     BAD_GUEST_IP2_START                            = "192.";
   public static final String                     BAD_GUEST_IP3_START                            = "172.";
   public static final int                        GUEST_SHUTDOWN_DELAY                           = 90 * 1000;
   public static final int                        GUEST_SHUTDOWN_LOOP_DELAY                      = 5 * 1000;
   /*
    * Constants for SSH Command
    */
   public static final long                       SSHCOMMAND_TIMEOUT                             = 300;
   public static final String                     SSHCOMMAND_KILLVPXA                            = "/etc/init.d/vmware-vpxa stop";
   public static final String                     SSHCOMMAND_KILLVPXA_5X                         = "/etc/init.d/vpxa stop";
   public static final String                     SSHCOMMAND_STARTVPXA                           = "/etc/init.d/vmware-vpxa start";
   public static final String                     SSHCOMMAND_RESTARTVPXA                         = "/etc/init.d/vmware-vpxa restart";
   public static final String                     EESX_SSHCOMMAND_KILLVPXA                       = "/etc/opt/init.d/vmware-vpxa stop";
   public static final String                     EESX_SSHCOMMAND_KILLVPXA_5X                    = "/etc/init.d/vpxa stop";
   public static final String                     EESX_SSHCOMMAND_STARTVPXA                      = "/etc/opt/init.d/vmware-vpxa start";
   public static final String                     EESX_SSHCOMMAND_RESTARTVPXA                    = "/etc/opt/init.d/vmware-vpxa restart";
   public static final String                     EESX5x_SSHCOMMAND_KILLVPXA                     = "/etc/init.d/vpxa stop";
   public static final String                     EESX5x_SSHCOMMAND_STARTVPXA                    = "/etc/init.d/vpxa start";
   public static final String                     EESX_SSHCOMMAND_RESTARTVPXA_5X                 = "/etc/init.d/vpxa restart";
   public static final String                     EESX5x_SSHCOMMAND_VPXA_STATUS                  = "/etc/init.d/vpxa status";
   public static final String                     EESX5x_VPXA_STATUS_STOPPED                     = "vpxa stopped";
   public static final String                     EESX5x_VPXA_STATUS_RUNNING                     = "vpxa is running";
   public static final String                     EESX5x_VPXA_STATUS_NOT_RUNNING                 = "vpxa is not running";
   public static final String                     SSHCOMMAND_RESTART_NETWORK                     = "service network restart";
   public static final String                     SSHCOMMAND_RESTARTHOSTD                        = "service mgmt-vmware restart";
   public static final String                     EESX_SSHCOMMAND_RESTARTHOSTD                   = "nohup /etc/init.d/hostd restart";
   public static final String                     SSHCOMMAND_NTPD_STOP                           = "service ntpd stop";
   public static final String                     SSHCOMMAND_NTPD_START                          = "service ntpd start";
   public static final String                     FIREWALL_SERVICE_NTPCLIENT                     = "ntpClient";
   public static final String                     ESX_SSHCOMMAND_IPTABLES_STOP                   = "service iptables stop";
   public static final String                     SSHCOMMAND_FIREWALL_DEFAULT                    = "esxcfg-firewall -r";
   public static final String                     EESX_SSHCOMMAND_NTPD_STOP                      = "/etc/init.d/ntpd stop";
   public static final String                     EESX_SSHCOMMAND_NTPD_START                     = "/etc/init.d/ntpd start";
   public static final String                     EESX_SSHCOMMAND_VPXADIR                        = "/opt/vmware/vpxa/vpx/vpxa";
   public static final String                     EESX_SSHCOMMAND_VPXADIR_5X                     = "/usr/lib/vmware/vpxa/bin/vpxa";
   public static final String                     SSHCOMMAND_VPXADIR                             = "/usr/lib/vmware/vpx/vpxa";
   public static final String                     SSHCOMMAND_VPXADIR_5X                          = "/usr/lib/vmware/vpxa/bin/vpxa";
   public static final String                     SSHCOMMAND_VPXAQUERY                           = "ps -ef | grep vpxa";
   public static final String                     SSHCOMMAND_VISOR_VPXAQUERY                     = "ps -c | grep vpxa";
   public static final String                     SSHCOMMAND_SET_FIREWALL                        = "esxcli network firewall set --enabled ";
   public static final String                     SSHCOMMAND_GET_FIREWALL                        = "esxcli network firewall get";
   public static final String                     SSH_STARTVPXA_OUTPUT                           = "Starting vmware-vpxa";
   public static final String                     SSH_STARTVPXA_OUTPUT_5X                        = "Begin ";
   public static final String                     SSH_KILLVPXA_OUTPUT                            = "Stopping vmware-vpxa";
   public static final String                     SSH_KILLVPXA_OUTPUT_5X                         = "vpxa stopped";
   public static final String                     SSHCOMMAND_STOP_NFS                            = "/etc/init.d/nfs stop";
   public static final String                     SSHCOMMAND_START_NFS                           = "/etc/init.d/nfs start";
   public static final String                     SSHCOMMAND_CURL                                = "curl -v -k -d ";
   public static String                           SSHCOMMAND_VM_APPMONITORING_SDK_REPOSITORY;
   public static String                           SSHCOMMAND_VM_APPMONITORING_TAR_FILE;
   public static final String                     STORAGE_IO_WINDOWS_VMNAME;
   public static final String                     INVALID_XML_FILE1                              = "MiscNegTest002.xml";
   public static final String                     INVALID_XML_FILE2                              = "MiscNegTest003.xml";
   public static final String                     INVALID_XML_FILE3                              = "MiscNegTest004.xml";
   public static final String                     SSHCOMMAND_CURL_FILE1                          = "\"`cat "
                                                                                                          + INVALID_XML_FILE1
                                                                                                          + "`\"";
   public static final String                     SSHCOMMAND_CURL_FILE2                          = "\"`cat "
                                                                                                          + INVALID_XML_FILE2
                                                                                                          + "`\"";
   public static final String                     SSHCOMMAND_CURL_FILE3                          = "\"`cat "
                                                                                                          + INVALID_XML_FILE3
                                                                                                          + "`\"";
   public static final String                     SSHCOMMAND_CURL_HOST                           = "sdk081.eng.vmware.com";
   public static final String                     SSHCOMMAND_LONGLIST                            = "ls -l ";
   public static final String                     SSHCOMMAND_MAKE_DIR                            = "mkdir";
   public static final String                     SSH_ERROR_STREAM                               = "SSHErrorStream";
   public static final String                     SSH_OUTPUT_STREAM                              = "SSHOutputStream";
   public static final String                     SSH_EXIT_CODE                                  = "SSHExitCode";
   public static final String                     SSHCOMMANDSUPP_CUT_THIRD_FIELD                 = " | awk '{print $3}'";
   public static final String                     SSHCOMMANDSUPP_LINE_COUNT                      = " | wc -l";
   public static final String                     SSHCOMMAND_VMKNIC_ENABLE                       = "esxcfg-vmknic -e ";
   public static final String                     SSHCOMMAND_VMKNIC_DISABLE                      = "esxcfg-vmknic -D ";
   public static final String                     ETC_RESOLV_CONF_FILE                           = "/etc/resolv.conf";
   public static final String                     ETC_RESOLV_CONF_BACKUP_FILE                    = "/etc/resolv.conf.bk";

   /*
    * Constants for misc errors
    */
   public static final int                        ERROR_PID                                      = -1;

   /*
    * Constants for method faults
    */
   public static final String                     INVALID_REQUEST                                = "InvalidRequest";
   public static final String                     BAD_REQUEST                                    = "Bad Request";
   /*
    * Constants for VM remote server command
    */
   public static final String                     VM_BSOD_COMMAND                                = "C:\\perftools\\"
                                                                                                          + "CrashWindowsVM.exe /crash";
   /*
    * Constant for filename 'logs' Utilities.DiagnosticManager
    */
   public static final String                     STR_UTILITIES_LOGFILE                          = "log";

   /*
    * Constant for HostConf restore/backup feature
    */
   public static final String                     HOST_CONFIG_BUNDLE_FILEPATH                    = "/tmp/configBundle.tgz";

   /*
    * Constants for ifcfg-eth0 and ifcfg-vswif0
    */
   public static final String                     IFCFG_ETH0_PATH                                = "/etc/sysconfig/network-scripts/ifcfg-eth0";
   public static final String                     IFCFG_VSWIF0_PATH                              = "/etc/sysconfig/network-scripts/ifcfg-vswif0";
   public static final String                     IPADDR_KEY                                     = "IPADDR=";

   /*
    * Constants related to vpxa.cfg
    */
   public static final String                     VPXA_CFG_PATH                                  = "/etc/opt/vmware/vpxa/vpxa.cfg";
   public static final String                     VPXA_CFG_PATH_5X                               = "/etc/vmware/vpxa/vpxa.cfg";
   public static final String                     VM_INVENORY_XML_PATH                           = "/etc/vmware/hostdvmInventory.xml";
   public static final String                     VPXA_CFG_BACKUP_PATH                           = "/tmp/vpxa.cfg.bak";
   public static final String                     XML_HOSTKEY_TAG                                = "hostKey";
   /*
    * ========= public static final variables should go here
    * ======================
    */
   /*
    * By default, VM_AUTOANSWER is set to true. AnswerVMThread will be invoked
    * if set to true during powerops.
    *
    * AnswerVM Tests will set value to false before calling answerVM method.
    * AnswerVM tests in the testcleanup should reset the boolean value to
    * true(default value).
    */
   // TODO: FIXME: This should really be made into a constant if possible
   public static boolean                          VM_AUTOANSWER                                  = true;
   public static final int                        MAX_CHILD_RESOURCE_POOLS                       = 255;
   public static final int                        MAX_LEVEL_RESOURCE_POOLS                       = 10;
   public static final SimpleDateFormat           MSGLOG_DATE_FORMAT                             = new SimpleDateFormat(
                                                                                                          "yyyy-MM-dd HH:mm:ss");
   public static final String                     VM_CFGVERSION_ESX_2X                           = "vmx-03";
   public static final String                     VM_CFGVERSION_ESX_30                           = "vmx-04";
   public static final String                     VM_CFGVERSION_ESX_40                           = "vmx-07";
   public static final String                     VM_CFGVERSION_ESX_50                           = "vmx-08";
   public static final String                     VPXD_CFG_PATH                                  = "C:/Documents and Settings/All Users/Application Data/VMware/VMware VirtualCenter/vpxd.cfg";
   public static final String                     VPXD_CFG_MAX_SESSION_KEY                       = "config.vmacore.soap.maxSessionCount";
   public static final int                        VPXD_CFG_MAX_SESSION_VALUE                     = 200;
   public static final String                     VPXD_CFG_VC_MANAGEDIP                          = "VirtualCenter.ManagedIP";

   /*
    * Property Collector Constants
    */
   public static final String                     SERVICE_DEFAULT_SERVICE                        = "ntpd";
   public static final String                     GUESTID_PROPETYNAME                            = "guest.guestId";

   /*
    * Property Filter Constants
    */
   public static final int                        UPDATES_TIMEOUT_MAXATTEMPT;
   public static final int                        MAX_WAITFORUPDATES_ATTEMPT                     = 3;
   public static final String                     UNKNOWN_EXPECTED_VALUE                         = "UNKNOWN_EXPECTED_VALUE";

   /*
    * Constants for Ticketing
    */
   public static final String                     NFC_TICKETING_VM_NAME                          = "NFCTicketingVM";
   public static final long                       NFC_TICKETING_VM_DISKSIZE                      = 1024 * 10;
   public static final long                       CREATE_VM_SMALL_DISKSIZE                       = 1024 * 10;

   /*
    * Constants for Invalid IP address
    */
   public static final String                     INVALID_IP_ADDRESS                             = "256.256.256.256";
   public static final int                        CREATEVM_MEM                                   = 1;
   public static final int                        CREATEVM_CPU                                   = 2;
   public static final String                     Flag_Green2Yellow                              = "GREEN2YELLOW";
   public static final String                     SCRIPT_NAME                                    = "batch/script name for testing";
   public static final String                     Email_Body                                     = "BODY";
   public static final String                     Email_Sub                                      = "SUB";
   public static final String                     Email_Cc                                       = "CC";
   public static final String                     Email_To                                       = "TO";
   public static final String                     Flag_Yellow2Green                              = "YELLOW2GREEN";
   public static final String                     Flag_Yellow2Red                                = "YELLOW2RED";
   public static final String                     Flag_Red2Yellow                                = "RED2YELLOW";

   /*
    * Testconstant to enable dumping drm dump in drs advanced options DumpSpace
    * value is in MB.
    */
   public static final String                     DRS_OPTION_DUMPSPACE                           = "DumpSpace";
   public static final String                     DRS_OPTION_DUMPSPACE_VALUE                     = "200";

   /*
    * Constants used during binding/login via http/https
    */

   public static final String                     USE_SSL                                        = "USESSL";
   public static final String                     USE_HTTP_TUNNELING                             = "USE_HTTP_TUNNELING";
   public static final String                     USE_HTTP_TUNNELING_PARAM                       = "useHttpTunneling";
   public static final String                     CLIENT_KEYSTORE                                = "CLIENTKEYSTORE";
   public static final String                     KEYSTORE_FILE                                  = "client.keystore";
   public static final String                     BOOL_TRUE                                      = "true";
   public static final String                     LOCALE_USEN                                    = "enUS";
   public static final String                     MAX_UPDATE_ATTEMPTS                            = "MAX_UPDATE_ATTEMPTS";

   /*
    * Constant to redirect output to file for stress tests
    */
   public static final String                     OUTPUTFILE                                     = "OUTPUTFILE";
   public static final String                     STRESS_CYCLE_ID                                = "STRESS_CYCLE_ID";
   public static final String                     STRESS_OPMGR_ENABLED                           = "OPMGR_ENABLED";
   /*
    * Constant for Credential store
    */
   public static final String                     CREDSTORE_HOST                                 = "credStoreHost";
   public static final String                     CREDSTORE_USER_NAME                            = "credStoreUserName";
   public static final String                     CREDSTORE_PASSWORD                             = "credStorePassword";

   /*
    * Constant for the system-dependent name separator
    */
   public static final String                     FILE_SEPARATOR                                 = java.io.File.separator;

   /*
    * Constants for EVC Clusters
    */
   public static final String                     INTEL                                          = "intel";
   public static final String                     AMD                                            = "amd";
   public static final String                     INTEL_EVCMODKEY                                = "intel-merom";
   public static final String                     AMD_EVCMODKEY                                  = "amd-rev-e";
   public static final String                     INTEL_EVC_PENRYN                               = "intel-penryn";
   public static final String                     INTEL_EVC_NEHALEM                              = "intel-nehalem";
   public static final String                     FILEPATH_TO_CPU_FEATURESET                     = "/clusters/evc/";
   public static final String                     CPU_COMPAT_DATA_LOC                            = "/cpu/compatibility/cpuCompatData/";
   public static final String                     CPU_COMPAT_MASTER_LIST                         = CPU_COMPAT_DATA_LOC
                                                                                                          + "MasterList.txt";
   public static final String                     INTEL_CPUVENDOR                                = "intel";
   public static final String                     AMD_CPUVENDOR                                  = "amd";
   public static final String                     VMCONFIGOPTION_HW7_FILEPATH                    = CPU_COMPAT_DATA_LOC
                                                                                                          + "HW_Versions/vmconfigoption-esx-hw7.xml";
   public static final String                     VMCONFIGOPTION_HW8_FILEPATH                    = CPU_COMPAT_DATA_LOC
                                                                                                          + "HW_Versions/vmconfigoption-esx-hw8.xml";

   /*
    * ========= protected static constants should go here ======================
    */

   public static final String                     SIC_SERVER_TYPE_HA                             = "HostAgent";
   public static final String                     SIC_SERVER_TYPE_VC                             = "VirtualCenter";
   protected final static String                  EXTENSION_LOGIN_CREDENTIALS                    = "login";
   public final static String                     EXTENSION_SUBJECT_NAME                         = "/O=Some Company, Inc./OU=QA/CN=VMware SRM Server";
   public final static String                     EXTENSION_INVALID_SUBJECT_NAME                 = "VMware Invalid Test Extension";
   public final static String                     EXTENSION_CERT1                                = "srmvimfvt.p12";
   public final static String                     EXTENSION_CERT2                                = "srmvimfvt.p12";
   public final static String                     EXTENSION_CERT_BOGUS                           = "extension-bogus.p12";

   public static final int                        FOLDER_MAXCOUNT                                = 2;
   public static final int                        CLUSTER_MAXCOUNT                               = 2;
   public static final int                        HOST_MAXCOUNT                                  = 2;
   /*
    * Checking Tool status by polling the heartbeatstatus Delay,Timeout is in
    * seconds.
    */
   public static final int                        TOOLS_RUNCHECK_DELAY                           = 2;
   public static final int                        TOOLS_RUNCHECK_TIMEOUT;
   public static final int                        TOOLS_INSTALLCHECK_DELAY                       = 5;
   public static final int                        TOOLS_INSTALLCHECK_TIMEOUT                     = 120;
   public static final int                        MESSAGE_PENDING_DELAY                          = 10;
   public static final int                        MESSAGE_PENDING_TIMEOUT                        = 120;
   public static final int                        VMSTATE_CHANGE_DELAY                           = 15;
   public static final int                        VMSTATE_CHANGE_TIMEOUT                         = 300;
   public static final int                        ANSWER_VM_THREAD_SLEEP                         = 5000;
   public static final int                        HOST_SYNC_THREAD_SLEEP                         = 20000;
   /*
    * Constant MODIFIER_PUBLIC_GET & DATE_FORMAT is used by Logger.printObject.
    */
   public static final String                     MODIFIER_PUBLIC_GET                            = "get";
   public static final String                     MODIFIER_PUBLIC_SET                            = "set";
   public static final String                     MODIFIER_PUBLIC_IS                             = "is";
   public static final String                     METHOD_NAME_EQUALS                             = "equals";
   public static final java.text.SimpleDateFormat DATE_FORMAT                                    = new java.text.SimpleDateFormat(
                                                                                                          "yyyy-MM-dd HH:mm:ss");
   /*
    * These constants were created for create/updated VMConfigSpec which is used
    * in CreateVM/Reconfig VM
    */
   protected static final String                  VM_VIRTUALDEVICE_ALL_DEVICE_TYPE               = "ALL_DEVICE";
   public static final String[]                   VM_VIRTUALDEVICE_ALL_DEVICE_LIST               = {
            VM_VIRTUALDEVICE_CDROM, VM_VIRTUALDEVICE_DISK,
            VM_VIRTUALDEVICE_ETHERNET_VMXNET, VM_VIRTUALDEVICE_FLOPPY,
            VM_VIRTUALDEVICE_USB, VM_VIRTUALDEVICE_KEYBOARD,
            VM_VIRTUALDEVICE_PARALLELPORT, VM_VIRTUALDEVICE_VIRTUALSCSIPASS,
            VM_VIRTUALDEVICE_SERIALPORT,
            VM_VIRTUALDEVICE_SOUNDCARD_SOUNDBLASTER16,
            VM_VIRTUALDEVICE_VIDEOCARD, VM_VIRTUALDEVICE_IDE_CONTROLLER,
            VM_VIRTUALDEVICE_PCI_CONTROLLER, VM_VIRTUALDEVICE_PS2_CONTROLLER,
            VM_VIRTUALDEVICE_SCSI_BUSL_CONTROLLER,
            VM_VIRTUALDEVICE_SCSI_LSI_CONTROLLER,
            VM_VIRTUALDEVICE_SIO_CONTROLLER, VM_VIRTUALDEVICE_USB_CONTROLLER,
            VM_VIRTUALDEVICE_POINTINGDEVICE                                                     };

   /*
    * Default Constant defined for VMConfigSpec used in CreateVM/ReconfigVM
    */
   public static final Long                       VM_DEFAULT_MEMORY                              = new Long(
                                                                                                          128);
   public static final String                     VM_OTHER_GUEST_32_BIT                          = "otherGuest";
   public static final String                     VM_DEFAULT_GUEST_WINDOWS                       = "winXPProGuest";
   public static final String                     VM_GUEST_WIN_7_32_BIT                          = "windows7Guest";
   public static final String                     VM_GUEST_WIN_7_64_BIT                          = "windows7_64Guest";
   public static final String                     VM_GUEST_WIN_2000_SERV                         = "Win2000ServGuest";
   public static final String                     VM_GUEST_WIN_2003_SERV                         = "winNetStandardGuest";
   public static final String                     VM_GUEST_WIN_2008_SERV                         = "winLonghorn64Guest";
   public static final String                     VM_GUEST_WIN_2008_SERV_32_BIT                  = "winLonghornGuest";
   public static final String                     VM_WIN_SERVER_2008_32BIT                       = "Win_Server_2008_32bit";
   public static final String                     VM_WIN_SERVER_2008_64BIT                       = "Win_Server_2008_64bit";
   public static final String                     VM_DEFAULT_GUEST_LINUX                         = "otherLinuxGuest";
   public static final String                     VM_WINXPPRO64_GUEST_WINDOWS                    = "winXPPro64Guest";
   public static final String                     VM_GUEST_LINUX_RHEL5_64_BIT                    = "rhel5_64Guest";
   public static final String                     VM_DEFAULT_CDROM_SPEC_HDNAME                   = "/dev/cdrom0";
   public static final String                     VM_DEFAULT_FLOPPY_FILENAME                     = "[]/vmimages/floppies/vmscsi-1.2.0.2.flp";
   public static final String                     VM_DEFAULT_FLOPPY_FILEEXTN                     = ".flp";
   public static final String                     WINDOWS_DEFAULT_DRIVE                          = "c:\\";
   public static final int                        VM_DEFAULT_NUM_CPUS                            = 2;
   public static final int                        VM_RECONFIG_DELAY                              = 2000;
   public static final long                       VM_DEFAULT_MEM_INCR_SIZE                       = 1024;
   public static final String[]                   VM_JF_SUPPORTED_GUESTS                         = {
            "rhel5Guest", "rhel5_64Guest", "winNetEnterpriseGuest",
            "winNetEnterprise64Guest", "sles10Guest", "sles10_64Guest"                          };
   /*
    * Constants for DALI windows and Linux vms. Used in UpgradeTools tests
    */
   public static final String                     DALI_WIN_VM                                    = "DALI_WIN_VM";
   public static final String                     DALI_LINUX_VM                                  = "DALI_LINUX_VM";
   protected static final int                     VM_DEFAULT_CFGVERSION_ESX_2X                   = 6;
   protected static final int                     VM_DEFAULT_CFGVERSION_ESX_30                   = 8;
   protected static final int                     VM_DEFAULT_CFGVERSION_GSX_31                   = 6;
   protected static final int                     VM_DEFAULT_HWVERSION_ESX_2X                    = 3;
   protected static final int                     VM_DEFAULT_HWVERSION_ESX_30                    = 4;
   protected static final int                     VM_DEFAULT_HWVERSION_GSX_31                    = 3;
   public static final Integer                    VM_DEFAULT_CPU                                 = new Integer(
                                                                                                          1);
   /* constant used for reconfigvm where more than one disk is added to a vm */
   public static final long                       VM_DEFAULT_DISKSIZE_IN_KB                      = 1024 * 10;
   /* constant used for creating disk with a invalid size */
   public static final long                       VM_OVER_MAX_DISKSIZE_IN_KB                     = 1024 * 1024 * 200;
   public static final long                       VM_FOR_INSUFFICIENT_DISK_SPACE                 = 1024 * 1024 * 1024 * 1;
   protected static final Integer                 VM_DEFAULT_CDROM_SPEC_UNITNUMBER               = new Integer(
                                                                                                          0);
   protected static final Integer                 VM_DEFAULT_FLOPPY_UNITNUMBER                   = new Integer(
                                                                                                          0);
   public static final int                        VM_DEFAULT_DISK_CAPACITY                       = 1024 * 4;
   protected static final Integer                 VM_DEFAULT_DISK_UNITNUMBER                     = new Integer(
                                                                                                          4);
   public static final String                     VM_DEFAULT_DISK_FILEEXTN                       = ".vmdk";
   protected static final String                  VM_DEFAULT_NIC_SPEC_HDNAME_VIRTUALPCNET32      = "vmnic0";
   protected static final String                  VM_DEFAULT_NIC_SPEC_HDNAME_VMXNET              = "vmnet0";
   protected static final Integer                 VM_DEFAULT_NIC_UNITNUMBER                      = new Integer(
                                                                                                          0);
   protected static final int                     VM_DEFAULT_CTRL_IDE_BUSNUMBER                  = 0;
   protected static final int                     VM_DEFAULT_CTRL_SCSI_LSI_BUSNUMBER             = 3;
   protected static final VirtualSCSISharing      VM_DEFAULT_CTRL_SCSI_LSI_SHAREDBUS             = VirtualSCSISharing.PHYSICAL_SHARING;
   protected static final int                     VM_DEFAULT_CTRL_SCSI_BUSL_BUSNUMBER            = 3;
   public static final VirtualSCSISharing         VM_DEFAULT_CTRL_SCSI_BUSL_SHAREDBUS            = VirtualSCSISharing.NO_SHARING;
   /*
    * These methodname constants are used in ignore these properties while
    * comparing configspec, devices.
    */
   public static final String                     VM_CONFIGSPEC_DEVICELIST_METHODNAME            = "VirtualMachineConfigSpec.DeviceChange";
   public static final String                     VM_CONFIGSPEC_FILES_METHODNAME                 = "VirtualMachineConfigSpec.Files";
   public static final String                     VM_CONFIGSPEC_POWEROPINFO_METHODNAME           = "VirtualMachineConfigSpec.PowerOpInfo";
   public static final String                     VM_CONFIGSPEC_LASTMODIFIED                     = "VirtualMachineConfigSpec.Modified";
   public static final String                     VM_CONFIGSPEC_FILES_CFGPATHNAME_METHODNAME     = "VirtualMachineFileInfo.VmPathName";
   public static final String                     VM_CONFIGSPEC_FLAGINFO                         = "VirtualMachineConfigSpec.FlagInfo";
   public static final String                     VM_CONFIGSPEC_EXTRACONFIG                      = "VirtualMachineConfigSpec.ExtraConfig";
   public static final String                     VM_DEVICESPEC_DEVICE_KEY_METHODNAME            = "Key";
   protected static final String                  VM_DEVICESPEC_DEVICE_CONTROLLERKEY_METHODNAME  = "ControllerKey";
   public static final String                     VM_DEVICESPEC_DEVICE_BACKING_METHODNAME        = "Backing";
   public static final String                     VM_DEVICESPEC_FILE_BACKING_FILENAME_METHODNAME = "FileName";
   public static final String                     VM_DEVICESPEC_ETHERNETCARD_MACADDR_METHODNAME  = "MacAddress";
   protected static final String                  VM_DEVICESPEC_UNITNUMBER_METHODNAME            = "UnitNumber";
   protected static final String                  VM_DEVICESPEC_BUSNUMBER_METHODNAME             = "BusNumber";
   protected static final Integer                 VM_DEFAULT_SOUNDCARD_ENSONIQ_UNITNUMBER        = new Integer(
                                                                                                          0);
   public static final String                     VM_DEFAULT_SOUNDCARD_SPEC_HDNAME_ENSONIQ1371   = "/dev/audio";
   protected static final Integer                 VM_DEFAULT_SOUNDCARD_SOUNDBLASTER_UNITNUMBER   = new Integer(
                                                                                                          0);
   public static final String                     VM_DEFAULT_SOUNDCARD_SPEC_HDNAME_SOUNDBLASTER  = "/dev/audio";
   public static final String                     VM_DEFAULT_SOUNDCARD_SPEC_HDNAME_HDAUDIOCARD   = "/dev/audio";
   public static final String                     SCSI_LUN_DEVICE_TYPE_CD_ROM                    = "cdrom";
   /*
    * Unimplemented code. Used to throw exception with message where code is not
    * implemented.
    */
   public static final String                     MSG_UNIMPLEMENTED_CODE                         = "Code not implemented.";

   /*
    * Protocol prefixes.
    */
   // URL prefix for secure HTTP protocol.
   public static final String                     HTTPS_PROTOCOL_URL_PREFIX                      = "https://";
   // URL prefix for HTTP protocol.
   public static final String                     HTTP_PROTOCOL_URL_PREFIX                       = "http://";
   // URL prefix for FTP protocol.
   public static final String                     FTP_PROTOCOL_URL_PREFIX                        = "ftp://";

   /*
    * Constants for VM customization
    */
   public static final String                     HTTP_PROTOCOL_URL_PATHSEPERATOR                = "/";
   public static final String                     HTTP_CLIENT_PROPERTYNAME                       = "CACHED_HTTP_CLIENT";
   public static final String                     VC_SESSION_COOKIE_NAME                         = "vmware_soap_session";
   public static final String                     LINE_END_CHAR                                  = "\r\n";
   public static final String                     VM_CUSTOMIZATION_COMPLETED_FILE                = "customizationdone.txt";
   public static final String                     VM_CUSTOMIZATION_CUSTOMIZATION_FILE            = "custominfo.txt";
   public static final String                     VM_CUSTOMIZATION_ASP_BATCH_FILE                = "executebatch.asp";
   public static final int                        CUSTOMIZATION_DELAY                            = 3;
   public static final int                        CUSTOMIZATION_TIMEOUT                          = 600;
   public static final String                     GLOBALIPSETTINGS_DNSSERVERS_METHODNAME         = "CustomizationGlobalIPSettings.DnsServers";
   public static final String                     GLOBALIPSETTINGS_DNSUFFIXES_METHODNAME         = "CustomizationGlobalIPSettings.DnsSuffixes";
   public static final String                     CUSTOMIZATION_DOMAIN_NAME                      = "vmware.com";
   public static final int                        CUSTOMIZATION_AUTOLOGON_COUNT                  = 5;
   public static final int                        CUSTOMIZATION_TIMEZONE                         = 4;
   public static final Integer                    CUSTOMIZATION_LICENSE_AUTOUSERS                = new Integer(
                                                                                                          10);
   public static final String                     CUSTOMIZATION_USERDATA_FULLNAME                = "VMWARETEST";
   public static final String                     CUSTOMIZATION_USERDATA_ORGNAME                 = "VMWARE";
   public static final String                     CUSTOMIZATION_USERDATA_PRODUCTID               = "VXKC4-2B3YF-W9MFK-QB3DB-9Y7MB";
   // public static final String ARRAYOF_NAME = "ArrayOf";
   // public static final String ARRAYOF_MOR_NAME =
   // ArrayOfManagedObjectReference.class.getName().substring(0,
   // ArrayOfManagedObjectReference.class.getName().indexOf(ARRAYOF_NAME) +
   // ARRAYOF_NAME.length() + 1);
   public static final String                     GSX_VIMACCOUNTNAME                             = "root";
   public static final String                     GSX_WIN_VIMACCOUNTNAME                         = "Administrator";
   public static final String                     GSX_VIMACCOUNTPASSWORD                         = "ca$hc0w";
   public static final Integer                    HOST_CNX_PORT                                  = null;
   public static final Integer                    QUERY_HOST_CNX_PORT                            = -1;
   /*
    * Constant for task
    */
   public static final int                        HISTORYCOLLECTOR_MAXCOUNT                      = 15;
   public static final String                     CHILDTYPE_COMPRES                              = "ComputeResource";
   public static final String                     CHILDTYPE_VM                                   = "VirtualMachine";
   public static final String                     PWD_SPECIAL_CHARS                              = "c@$hc0w���";
   public static final String                     DUMMY_NAME                                     = "DUMMY";
   public static final String                     ALARM_DESC                                     = "Alarm for Testing";
   public static final boolean                    ENABLED                                        = true;
   public static final String                     ALARM_NAME                                     = "New Alarm";
   /* Constant used to mention network file system path start */
   public static final String                     NFS_PATH_START                                 = "netfs://";
   /*
    * Test Constants to represent strings
    */
   public static final String                     STRING_81_CHARS                                = "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "012345678901234567890";
   public static final String                     STRING_256_CHARS                               = "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "0123456789012345";
   public static final String                     STRING_257_CHARS                               = "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456789"
                                                                                                          + "01234567890123456";
   /*
    * HostConf constants
    */
   public static final String                     HOSTCONF_MANUFACTURER_DELL                     = "dell";
   public static final String                     EXIT14                                         = "exit14.eng.vmware.com";
   public static final String                     PING_ERROR                                     = "0 received";
   public static final String                     PING                                           = "ping";
   public static final String                     PING_ERROR_LINUX                               = "0 packets received";
   public static final String                     PING_ERROR_WINDOWS                             = "Received = 0";
   public static final String                     PING_IPV4_COUNT_THREE_LINUX                    = "ping -c 3 ";
   public static final String                     PING_IPV6_COUNT_THREE_LINUX                    = "ping6 -c 3 ";
   public static final String                     PING_IPV4_COUNT_THREE_WINDOWS                  = "ping -n 3 ";
   public static final String                     PING_IPV6_COUNT_THREE_WINDOWS                  = "ping6 -n 3 ";
   // PING_DELAY is used as timeout interval for verifying IP reachability.
   public static final int                        PING_DELAY                                     = 10000;
   public static final String                     ESX_DEFAULT_PORTGROUP                          = "Service Console";
   public static final String                     EESX_DEFAULT_PORTGROUP                         = "Management Network";
   /*
    * Constants for NFC Service
    */
   public static final String                     NFC_CLIENT;
   public static final String                     NFC_SETUP_VMNAME                               = "nfcsetup_vm";
   public static final String                     BACKWARD_SLASH                                 = "\\";
   public static final String                     DEFAULT_NFC_PORT                               = "902";
   public static final String                     CHECK_SUM                                      = "md5sum ";
   public static final String                     NFC_FLATVMDK_FILEEXTN                          = "-flat.vmdk";
   public static final int                        NFC_LARGE_DISK_SIZE                            = 1024 * 1024 * 1024 * 30;
   public static final String                     NFC_LARGE_FLAT_FILEEXTN                        = "-f016.vmdk";
   public static final String                     VM_LOGFILE                                     = "vmware.log";
   public static final String                     NFC_DONE                                       = "Done with";
   public static final String                     QUOTE                                          = "\"";
   public static final String                     QUOTE_COMMA_QUOTE                              = "\",\"";
   public static final String                     NFC_DEFAULT_AGENT                              = " -a vpxa";
   public static final String                     NFC_DIR                                        = File.separator
                                                                                                          + "nfcservice"
                                                                                                          + File.separator;
   public static final long                       NFC_MAX_FREE_SPACE                             = 1024 * 1024 * 1024 * 35;
   /*
    * Constants for DateTimeSystem tests
    */
   public static final String[]                   NONEMPTY_NTP_SERVERS                           = new String[] {
            "10.20.30.1", "10.20.30.2"                                                          };
   public static final String[]                   EMPTY_NTP_SERVERS                              = new String[] {};
   public static final String                     TIME_ZONE_UTC                                  = "UTC";
   public static final String                     ZONE_TAB                                       = "zone.tab";
   public static final String                     VALID_TIME_ZONE                                = "America/Denver";
   public static final String                     INVALID_TIME_ZONE                              = "InvalidTimeZone";
   public static final String                     HOST_NTP_PATH                                  = "/etc/ntp.conf";
   public static final String                     HOST_BACKUP_NTP_PATH_UPDATECONFIG              = "/etc/ntp.conf.bk.hostconf.updateconfig";
   public static final String                     HOST_BACKUP_NTP_PATH_REFRESH                   = "/etc/ntp.conf.bk.hostconf.refresh";
   public static final String                     DATETIMESYSTEM_MOR                             = "HostDateTimeSystem";
   public static final int                        YEAR_BEFORE_1969                               = 1967;
   public static final int                        YEAR_BACKWARD_LIMIT                            = 1970;
   /*
    * Constants for QueryAvailableTimeZones tests
    */
   public static final String                     ESX3X_ZONE_TAB_PATH                            = "/usr/share/zoneinfo/zone.tab";
   public static final String                     ESX4X_ZONE_TAB_PATH                            = "/usr/share/zoneinfo/posix/";
   public static final String[]                   NORTH_HEM_TZ                                   = new String[] {
            "America/Los_Angeles", "Asia/Jerusalem", "Europe/Lisbon",
            "Europe/Athens", "Europe/Moscow"                                                    };
   public static final String[]                   SOUTH_HEM_TZ                                   = new String[] {
            "Australia/Sydney", "Australia/Melbourne", "Australia/Hobart",
            "Africa/Harare", "Antarctica/South_Pole"                                            };
   /*
    * maximum milliseconds delay in calling host api
    */
   public static final String                     HOST_BACKUP_NTP_PATH                           = "/etc/ntp.conf.bk.hostconf.updateconfig.Pos006.java";
   public static final String                     TEST_NTP_PATH_UPDATECONFIG                     = "/exit14/home/farshidg/tests/hostconf.updateconfig.Pos006.ntp.conf";
   public static final String                     TEST_NTP_PATH_REFRESH                          = "hotsconf.refresh.ntp.conf";

   /*
    * maximum milliseconds delay in calling host api
    */
   public static final long                       MAX_OP_DELAY                                   = 5000;
   /*
    * Test constants for AutoStartManager
    */
   public static final int                        DEFAULT_AUTOSTART_POWERON_DELAY                = 120;
   public static final int                        DEFAULT_AUTOSTART_POWEROFF_DELAY               = 120;

   /*
    * Test Constants for Extensions
    */
   public static final int                        EXTENSION_MAX_LENGTH                           = 80;
   /*
    * TODO Out of bound constants need to be removed.
    */
   public static final int                        EXTENSION_OUT_OF_BOUND                         = 256;
   public static final int                        EXTENSION_SUBJECT_NAME_MAX_LENGTH              = 4096;
   public static final int                        EXTENSION_SUBJECT_NAME_OUT_OF_BOUND            = 4097;
   public static final int                        EXTENSION_URL_MAX_LENGTH                       = 2048;
   public static final int                        EXTENSION_SOLUTIONINFO_MAX_CHAR_LENGTH         = 255;
   public static final String[]                   EXTENSION_TASK_IDS                             = {
            "com.vmware.vim.security.task0", "com.vmware.vim.security.task1",
            "com.vmware.vim.security.anotherTask",
            "com.vmware.vim.security.excitingTask",
            "com.vmware.vim.security.boringTask",
            "com.vmware.vim.security.blahTask"                                                  };

   public static final String[]                   EXTENSION_EVENT_IDS                            = {
            "com.vmware.vim.security.event0", "com.vmware.vim.security.event1",
            "com.vmware.vim.security.anotherEvent",
            "com.vmware.vim.security.excitingEvent",
            "com.vmware.vim.security.boringEvent",
            "com.vmware.vim.security.blahEvent"                                                 };

   public static final String[]                   EXTENSION_PRIVILEGE_IDS                        = {
            "com.vmware.vim.security.priv0", "com.vmware.vim.security.priv1",
            "com.vmware.vim.security.anotherPriv",
            "com.vmware.vim.security.exciting",
            "com.vmware.vim.security.boring", "com.vmware.vim.security.blah"                    };

   public static final String[]                   EXTENSION_FAULT_IDS                            = {
            "com.vmware.vim.fault.fault0", "com.vmware.vim.fault.fault1"                        };
   public static final String                     EXTENSION_DEFAULT_NAME                         = "Default Extension";
   public static final String                     EXTENSION_DEFAULT_VERSION                      = "1.0";
   public static final String                     EXTENSION_DEFAULT_KEY                          = "ExtensionDefaultKey";
   public static final String                     EXTENSION_DESCRIPTION_LABEL                    = "Extension Label";
   public static final String                     EXTENSION_DESCRIPTION_SUMMARY                  = "Default Extension Summary";
   public static final String                     EXTENSION_DEFAULT_URL                          = "http://dummy-url";
   public static final String                     EXTENSION_DEFAULT_URL_IPV6                     = "http://[ffff:ffff:ffff:ffff:ffff:ffff::ffff]:8095";
   public static final String                     EXTENSION_DEFAULT_COMPANY                      = "VmWare";
   public static final int                        EXTENSION_SERVER_DEFAULT_KEY                   = 0;
   public static final String                     EXTENSION_DEFAULT_TYPE                         = "Http";
   public static final String[]                   EXTENSION_SERVER_ADMINEMAIL                    = {
            "adminemail1@vmware.com", "adminemail2@vmware.com"                                  };
   public static final String                     EXTENSION_TAB_LABEL                            = "ExtensionTabLabel";
   public static final String                     EXTENSION_DEFAULT_COMPANY_URL                  = "http://vmware.com";
   public static final String                     EXTENSION_DEFAULT_PRDT_URL                     = "http://vc-prdt";
   public static final String                     PROVISIONING_READCUSTSPECS                     = "VirtualMachine.Provisioning.ReadCustSpecs";
   public static final String                     PROVISIONING_MODIFYCUSTSPECS                   = "VirtualMachine.Provisioning.ModifyCustSpecs";
   public static final String                     PROVISIONING_USETEMPCUSTSPECS                  = "VirtualMachine.Provisioning.UseTempCustSpecs";
   public static final String                     PROVISIONING_CUSTOMIZE                         = "VirtualMachine.Provisioning.Customize";
   /*
    * Constants for Patch Manager
    */
   public static final String                     VALID_PATCH_URL                                = "xxx";
   public static final String                     REBOOT_PATCH_URL                               = "xxx";
   public static final String                     VALID_PATCH_FILE_URL                           = "xxx";
   public static final String                     VALID_PATCH_PROXY                              = "xxx";
   public static final String                     VALID_PATCH_UPDATEID                           = "xxx";
   public static final String                     INVALID_PATCH_URL                              = "http://vmweb.vmware.com";
   public static final String                     BAD_PATCH_URL                                  = "http://wwww.doesnotexist.exist.patch";
   public static final String                     PATCH_BINARIES_NOTFOUND_URL                    = "xxx";
   public static final String                     PATCH_METADATA_NOTFOUND_URL                    = "xxx";
   public static final String                     PATCH_HOST_REBOOT_URL                          = "xxx";
   public static final String                     PATCH_VM_POWEROFF_URL                          = "xxx";
   public static final String                     PATCH_SUPERCEDE_UPDATES_URL                    = "xxx";
   public static final String                     PATCH_PRE_REQ_URL                              = "xxx";

   /*
    * Constants for various extension services
    */
   public static final String                     DR_SOLUTION                                    = "DisasterRecovery";
   public static final String                     INTEGRITY_SOLUTION                             = "VcIntegrity";
   /*
    * Reflection Section
    */
   public static final String                     DR_EXTENSION_KEY                               = "com.vmware.vcDr";
   public static final String                     SM_EXTENSION_KEY                               = "com.vmware.vim.sms";
   public static final String                     VSM_EXTENSION_KEY                              = "com.vmware.vim.vsm";
   public static final String                     XHM_EXTENSION_KEY                              = "com.vmware.xhm";
   public static final String                     VC_PACKAGE_PREFIX                              = "com.vmware.vc.";
   public static final String                     VC_EXTENSION_KEY                               = "VIM_SOLUTION";
   public static final String                     VP_EXTENSION_KEY                               = "vendorprovider";
   public static final String                     EAM_EXTENSION_KEY                              = "com.vmware.vim.eam";
   public static final String                     PBM_EXTENSION_KEY                              = "com.vmware.vim.pbm";
   public static final String                     INTEGRITY_EXTENSION_KEY                        = "com.vmware.vcIntegrity";
   public static final String                     CONVERTER_EXTENSION_KEY                        = "com.vmware.converter";
   public static final String                     INTERNAL_VC_EXTENSION_KEY                      = "com.vmware.internal";
   public static final String                     INTERNAL_VC_URL                                = "/internal";
   public static final String                     VCCONNECTANCHOR_CLASSNAME                      = "com.vmware.vcqa.ConnectAnchor";
   public static final String                     DRCONNECTANCHOR_CLASSNAME                      = "com.vmware.vcqa.dr.DrConnectAnchor";
   public static final String                     INTEGRITYCONNECTANCHOR_CLASSNAME               = "com.vmware.integrity.common.IntgConnectAnchor";
   public static final String                     CONVERTERCONNECTANCHOR_CLASSNAME               = "com.vmware.vcqa.converter.ConverterConnectAnchor";
   public static final String                     INTERNALVCCONNECTANCHOR_CLASSNAME              = "com.vmware.vcqa.internal.InternalConnectAnchor";
   public static final String                     IMAGELIBRARYMANAGER_CLASSNAME                  = "com.vmware.vcqa.internal.ManagedImageLibraryManager";
   public static final String                     SMSCONNECTANCHOR_CLASSNAME                     = "com.vmware.vcqa.sm.SmConnectAnchor";
   public static final String                     VSMCONNECTANCHOR_CLASSNAME                     = "com.vmware.vcqa.vsm.VsmConnectAnchor";
   public static final String                     XHMCONNECTANCHOR_CLASSNAME                     = "com.vmware.xhmqa.XhmConnectAnchor";
   public static final String                     VPCONNECTANCHOR_CLASSNAME                      = "com.vmware.vcqa.vasa.VPConnectAnchor";
   public static final String                     EAMCONNECTANCHOR_CLASSNAME                     = "com.vmware.vcqa.esxagentmanager.EamConnectAnchor";
   public static final String                     PBMCONNECTANCHOR_CLASSNAME                     = "com.vmware.vcqa.pbm.PbmConnectAnchor";
   public static final Class<?>[]                 PRIMITIVE_TYPES                                = {
            int.class, float.class, double.class, long.class, boolean.class,
            byte.class, char.class, short.class                                                 };

   public static final Class<?>[]                 PRIMITIVE_WRAPPER_CLASSES                      = {
            Integer.class, Float.class, Double.class, Long.class,
            Boolean.class, Byte.class, Character.class, Short.class,
            java.util.GregorianCalendar.class, java.math.BigDecimal.class,
            javax.xml.namespace.QName.class, java.math.BigInteger.class                         };

   public static final Map<Class<?>, Class<?>>    MAP_PRIMITIVE_WRAPPERS                         = new HashMap<Class<?>, Class<?>>();
   public static final String                     MOR_STRING                                     = "ManagedObjectReference";
   public static final String                     FROM_VALUE_STRING                              = "fromValue";
   public static final String                     METHOD_FAULT_STRING                            = ".MethodFault";
   public static final String                     MOR_GET_TYPE_STRING                            = "getType";
   public static final String                     MOR_SET_TYPE_STRING                            = "setType";
   public static final String                     GET_PROPERTY_COLLECTOR                         = "getPropertyCollector";

   /*
    * end of Reflection Section
    */
   public static final String                     XML_VIRTUALCENTER_TAG                          = "virtualcenter";
   public static final String                     XML_VENDORPROVIDER_TAG                         = "vendorprovider";
   public static final String                     XML_USERNAME_TAG                               = "username";
   public static final String                     XML_PASSWORD_TAG                               = "password";
   public static final String                     XML_MACHINEUSERNAME_TAG                        = "machineusername";
   public static final String                     XML_MACHINEPASSWORD_TAG                        = "machinepassword";
   public static final String                     XML_DEPLOYMENTTYPE_TAG                         = "deploymenttype";
   public static final String                     XML_INFRANODEHOSTNAME_TAG                      = "infranodehostname";
   public static final String                     XML_HOSTNAME_TAG                               = "hostname";
   public static final String                     XML_PORT_TAG                                   = "port";
   public static final String                     XML_LOCALE_TAG                                 = "locale";
   public static final String                     XML_EXTENSIONS_TAG                             = "extensions";
   public static final String                     XML_EXTENSION_TAG                              = "extension";
   public static final String                     XML_CUSTOMIZATIONS_TAG                         = "customizations";
   public static final String                     XML_KEYSTOREPATH_TAG                           = "keystorepath";
   public static final String                     XML_KEYSTORE_PASSWORD                          = "keystorepassword";
   public static final String                     XML_CERTIFICATE_TYPE                           = "certiticatetype";
   public static final String                     XML_SERVICE_ENDPOINT                           = "serviceendpoint";
   public static final String                     XML_TRUSTSTORE_PATH                            = "truststorepath";
   public static final String                     XML_USESSL                                     = "usessl";
   public static final String                     XML_USEVMCA                                    = "usevmca";
   public static final String                     XML_VERSION                                    = "version";
   public static final String                     XML_ENDPOINT_PROTOCOL                          = "endpointprotocol";
   public static final String                     XML_VIRTUALCENTERS_TAG                         = "virtualcenters";
   public static final String                     XML_ID_ATTRIBUTE                               = "ID";
   public static final String                     XML_DESCRIPTION_ATTRIBUTE                      = "DESCRIPTION";
   public static final String                     XML_VENDORPROVIDER_TYPE_TAG                    = "type";
   public static final String                     XML_SESSION_TIMEOUT_IN_SECONDS                 = "sessiontimeoutinseconds";
   public static final String                     SCHEMA_LANGUAGE                                = "http://java.sun.com/xml/jaxp/properties/schemaLanguage";
   public static final String                     WWW_SCHEMA_URL                                 = "http://www.w3.org/2001/XMLSchema";
   public static final String                     JAXP_SCHEMA_URL                                = "http://java.sun.com/xml/jaxp/properties/schemaSource";
   public static final String                     XML_SERVERCERTIFICATE_ALIAS                    = "servercertificatealias";
   public static final String[]                   MULTI_CONNECT_TESTBASE_REQUIRED_XML_TAGS       = {
            XML_USERNAME_TAG, XML_PASSWORD_TAG, XML_KEYSTOREPATH_TAG,
            XML_HOSTNAME_TAG, XML_PORT_TAG, XML_LOCALE_TAG, XML_EXTENSIONS_TAG,
            XML_CUSTOMIZATIONS_TAG, XML_MACHINEUSERNAME_TAG, XML_MACHINEPASSWORD_TAG,
            XML_DEPLOYMENTTYPE_TAG, XML_INFRANODEHOSTNAME_TAG};
   /*
    * Test Constants for control vpxd service
    */
   // windows
   public static final String                     SERVICE_VPXD                                   = "vpxd";
   public static final String                     SERVICE_VCTOMCAT                               = "vctomcat";
   public static final String                     SERVICE_SSO                                    = "ssotomcat";
   public static final String                     SERVICE_QUERY_SERVICE                          = "vimQueryService";
   public static final String                     SERVICE_PBSM                                   = "vimPBSM";
   public static final String                     SERVICE_CM                                     = "VMwareComponentManager";
   public static final String                     SERVICE_VMCA                                   = "VMWareCertificateService";
   public static final String                     SERVICE_VDCS                                   = "vdcs";
   public static final String                     SERVICE_INVSVC                                 = "invsvc";
   public static final String                     SERVICE_CISLICENSE                             = "licenseService";
   public static final String                     SERVICE_APIPROXY = "vCenterAPIProxy";
   public static final String                     SERVICE_EAM = "EsxAgentManager";
   public static final String                     SERVICE_IDM = "VMwareIdentityMgmtService";
   public static final String                     SERVICE_MBCS = "mbcs";
   public static final String                     SERVICE_NETDUMPER = "vmware-network-coredump";
   public static final String                     SERVICE_PERFCHARTS = "vmware-perfcharts";
   public static final String                     SERVICE_RBD = "vmware-autodeploy-waiter";
   public static final String                     SERVICE_RHTTPPROXY = "rhttpproxy";
   public static final String                     SERVICE_SCA = "VMwareServiceControlAgent";
   public static final String                     SERVICE_STS = "VMwareSTS";
   public static final String                     SERVICE_VAPIENDPOINT = "vapiEndpoint";
   public static final String                     SERVICE_VAPIMETADATA = "vapi-metadata";
   public static final String                     SERVICE_VCOCONFIGURATOR = "vCOConfiguration";
   public static final String                     SERVICE_VMAFDD = "VMWareAfdService";
   public static final String                     SERVICE_VMDIRD = "VMWareDirectoryService";
   public static final String                     SERVICE_VMSYSLOGCOLLECTOR = "vmsyslogcollector";
   public static final String                     SERVICE_VMWARECISCONFIG = "vmware-cis-config";
   public static final String                     SERVICE_VPOSTGRES = "vPostgres";
   public static final String                     SERVICE_WORKFLOW = "vmware-vpx-workflow";
   public static final String                     SERVICE_VSM = "VServiceManager";
   public static final String                     SERVICE_VSPHERECLIENT = "vspherewebclientsvc";
   public static final String                     SERVICE_VWS = "vmwarevws";
   public static final String                     SERVICE_SCAXX = "VMwareServiceControlAgent";

   // linux
   public static final String                     SERVICE_VPXD_LINUX                             = "vmware-vpxd";
   public static final String                     SERVICE_VCTOMCAT_LINUX                         = "tomcat";
   public static final String                     SERVICE_SSO_LINUX                              = "vmware-stsd";
   public static final String                     SERVICE_QUERY_SERVICE_LINUX                    = "vmware-invsvc";
   public static final String                     SERVICE_PBSM_LINUX                             = "vmware-sps";
   public static final String                     SERVICE_CM_LINUX                               = "vmware-cm";
   public static final String                     SERVICE_VMCA_LINUX                             = "vmcad";
   public static final String                     SERVICE_VDCS_LINUX                             = "vmware-vdcs";
   public static final String                     SERVICE_CISLICENSE_LINUX                       = "vmware-cis-license";
   public static final String                     SERVICE_APPLMGMT_LINUX                         = "applmgmt";
   public static final String                     SERVICE_APIPROXY_LINUX = "vmware-apiproxy";
   public static final String                     SERVICE_EAM_LINUX = "vmware-eam";
   public static final String                     SERVICE_IDM_LINUX = "vmware-sts-idmd";
   public static final String                     SERVICE_INVSVC_LINUX = "vmware-invsvc";
   public static final String                     SERVICE_MBCS_LINUX = "vmware-mbcs";
   public static final String                     SERVICE_NETDUMPER_LINUX = "vmware-netdumper";
   public static final String                     SERVICE_PERFCHARTS_LINUX = "vmware-perfcharts";
   public static final String                     SERVICE_RBD_LINUX = "vmware-rbd-watchdog";
   public static final String                     SERVICE_RHTTPPROXY_LINUX = "vmware-rhttpproxy";
   public static final String                     SERVICE_SCA_LINUX = "vmware-sca";
   public static final String                     SERVICE_STS_LINUX = "vmware-stsd";
   public static final String                     SERVICE_SYSLOG_LINUX = "vmware-syslog";
   public static final String                     SERVICE_SYSLOGHEALTH_LINUX = "vmware-syslog-health";
   public static final String                     SERVICE_VAPIENDPOINT_LINUX = "vmware-vapi-endpoint";
   public static final String                     SERVICE_VAPIMETADATA_LINUX = "vmware-vapi-metadata";
   public static final String                     SERVICE_VCOCONFIGURATOR_LINUX = "vco-configurator";
   public static final String                     SERVICE_VMAFDD_LINUX = "vmafdd";
   public static final String                     SERVICE_VMDIRD_LINUX = "vmdird";
   public static final String                     SERVICE_VMWARECISCONFIG_LINUX = "vmware-cis-config";
   public static final String                     SERVICE_VPOSTGRES_LINUX = "vmware-vpostgres";
   public static final String                     SERVICE_WORKFLOW_LINUX = "vmware-vpx-workflow";
   public static final String                     SERVICE_VSM_LINUX = "vmware-vsm";
   public static final String                     SERVICE_VSPHERECLIENT_LINUX = "vsphere-client";
   public static final String                     SERVICE_VWS_LINUX = "vmware-vws";
   public static final String                     SERVICE_SCAXX_LINUX = "vmware-scaxx";


   public static final String                     SERVICE_STATE_RUNNING                          = "RUNNING";
   public static final String                     SERVICE_STATE_NOT_RUNNING                      = "NOT RUNNING";
   public static final String                     SERVICE_STATE_STOPPED                          = "STOPPED";
   public static final String                     SERVICE_STATE_UNUSED                           = "UNUSED";
   public static final long                       SERVICE_TIMEOUT                                = 300;
   public static final long                       SERVICE_CHECK_INTERVAL                         = 10;

   //ESX Service
   public static final String                     SERVICE_ESX_HOSTD                             = "hostd";
   public static final String                     SERVICE_ESX_RHTTPPROXY                        = "rhttpproxy";
   public static final String                     SERVICE_ESX_VPXA                              = "vpxa";



   /*
    * Test Constants for controlling tomcat service
    */
   public static final String                     TOMCAT_USERNAME                                = "tomcat";
   public static final String                     TOMCAT_PASSWORD                                = "tomcat";
   public static final String                     TOMCAT_PORT                                    = "8080";

   /*
    * Test Constants for the flags that has to be specified in the VMConfigSpec.
    */
   public static final class FlagInfo
   {
      public static final int DISABLE_ACCELERATION              = 1;
      public static final int ENABLE_LOGGING                    = 2;
      public static final int USE_TOE                           = 3;
      public static final int RUN_WITH_DEBUG_INFO               = 4;
      public static final int RUN_WITH_STATS_INFO               = 5;
      public static final int HT_SHARING_ANY                    = 6;
      public static final int HT_SHARING_INTERNAL               = 7;
      public static final int HT_SHARING_NONE                   = 8;
      public static final int SNAPSHOT_DISABLED                 = 9;
      public static final int SNAPSHOT_LOCKED                   = 10;
      public static final int SNAPSHOT_POWEROFF_POWEROFF        = 11;
      public static final int SNAPSHOT_POWEROFF_REVERT_SNAPSHOT = 12;
      public static final int SNAPSHOT_POWEROFF_ASKME           = 13;
   }

   /*
    * View managed object types
    */
   public static final String[]     VIEW_TYPE_LIST                                     = {
            "ContainerView", "InventoryView", "ListView"                              };
   /*
    * AXIS SOAP Tracer related test constants go here
    */
   public static final String       TRACESOAP                                          = "TRACESOAP";
   public static final String       TESTID                                             = "TESTID";

   /*
    * Constants for config spec operations
    */
   public static final String       CONFIG_SPEC_ADD                                    = ConfigSpecOperation.ADD
                                                                                                .value();
   public static final String       CONFIG_SPEC_REMOVE                                 = ConfigSpecOperation.REMOVE
                                                                                                .value();
   public static final String       CONFIG_SPEC_EDIT                                   = ConfigSpecOperation.EDIT
                                                                                                .value();

   /*
    * Constants for HashMap keys
    */
   public static final String       VERSION_KEY                                        = "updatesVersion";
   public static final String       UPDATE_SUCCESS_KEY                                 = "updateSuccess";

   /*
    * Constants for the sleep interval
    */
   public static final long         UPDATE_SLEEP_INTERVAL                              = 1 * 1000;
   public static final int          MAX_WAIT_CONNECT_TIMEOUT                           = 120;
   public static final int          BIOS_POWERON_MAX_DELAY                             = 10;
   public static final int          BIOS_START_WAIT                                    = 2;

   /*
    * Constants for the FileManager APIs
    */
   public static final String       FOLDER_NAME                                        = "folder";
   public static final String       PARENT_FOLDER_NAME                                 = "parentFolder";

   /*
    * Constants for Https access of vim.wsdl file.
    */
   public static final int          SSL_PORT                                           = 443;
   public static final String       URL_WITH_HOST                                      = "/host";
   public static final String       URL_WITH_FOLDER                                    = "/folder";
   public static final String       WSDL_PATH                                          = "/sdk/vim.wsdl";
   public static final String       URL_WITH_VPXA                                      = "/vpxa/service";
   public static final int          BLOCK_SIZE                                         = 1024;
   public static final String       URL_WITH_CGI                                       = "/cgi-bin/vm-support.cgi?listmanifests=true";
   public static final String       URL_WITH_SCREEN                                    = "/screen?path=";

   /*
    * Constants for the VirtualDiskManager APIs ---- Starts here
    */
   public static final String       DS_NAME                                            = "dsName=";
   public static final String       PATH                                               = "path=";
   public static final int          PORT                                               = 8085;
   public static final String       QUESTION_MARK                                      = "?";
   public static final String       AMP_SIGN                                           = "&";
   public static final String       COLON                                              = ":";
   public static final String       SPACE                                              = " ";
   public static final String       CLOSING_SQUARE_BRACKET                             = "]";
   public static final String       FORWARD_SLASH                                      = "/";
   // Represents the folder context in URL path.
   public static final String       FOLDER_PATH                                        = "folder?";
   // Represents the Data center path key in query string of URL.
   public static final String       URL_KEY_DC_PATH                                    = "dcPath=";
   // Constant used for invalid disk mode
   public static final String       INVALID_DISK_MODE                                  = "XXXXX";
   // Constant used for invalid datastore path
   public static final String       INVALID_DATASTORE_PATH                             = "<>";
   // Constants used for Virtual disk size
   public static final long         VIRTUAL_DISK_SMALL_SIZE                            = 1024 * 10;
   public static final long         VIRTUAL_DISK_DEFAULT_SIZE                          = 1024 * 1024 * 2;
   /*
    * Active Directory domain names
    */
   public static final String       DOMAINNAME_1                                       = "cam1.vmware.com";
   public static final String       DOMAINNAME_2                                       = "sdkdomain2.com";
   public static final String       INVALID_DOMAIN_NAME                                = "abc.com";
   public static final String       INVALID_HOST_NAME                                  = "invalidHost";
   public static final String       DOMAIN1_DNS_SERVER                                 = "192.168.1.103";
   public static final String       DOMAIN2_DNS_SERVER                                 = "192.168.1.104";
   public static final String       CAMSERVER                                          = "192.168.1.103";
   public static final String       CAMSERVER_PUBLIC                                   = "10.112.88.115";
   public static final String       INVALID_CAMSERVER                                  = "10.256.20.30";
   /*
    * K/L: RelocateSpec. DiskMoveOptions
    */
   public static final String       RELOCATESPEC_CREATENEWCHILDDISKBACKING             = VirtualMachineRelocateDiskMoveOptions.CREATE_NEW_CHILD_DISK_BACKING
                                                                                                .value();
   public static final String       RELOCATESPEC_MOVEALLDISKBACKINGSANDALLOWSHARING    = VirtualMachineRelocateDiskMoveOptions.MOVE_ALL_DISK_BACKINGS_AND_ALLOW_SHARING
                                                                                                .value();
   public static final String       RELOCATESPEC_MOVEALLDISKBACKINGSANDDISALLOWSHARING = VirtualMachineRelocateDiskMoveOptions.MOVE_ALL_DISK_BACKINGS_AND_DISALLOW_SHARING
                                                                                                .value();
   public static final String       RELOCATESPEC_MOVECHILDMOSTDISKBACKING              = VirtualMachineRelocateDiskMoveOptions.MOVE_CHILD_MOST_DISK_BACKING
                                                                                                .value();
   public static final String       RELOCATESPEC_MOVEALLDISKBACKINGSANDCONSOLIDATE     = VirtualMachineRelocateDiskMoveOptions.MOVE_ALL_DISK_BACKINGS_AND_CONSOLIDATE
                                                                                                .value();
   /*
    * Constants for the VirtualDiskManager APIs ---- Ends here
    */

   /*
    * Constants for vmkfstools SSH command diskformat argument
    */
   public static final String       VMKFSTOOLS_DISKFORMAT_THIN                         = "thin";
   public static final String       VMKFSTOOLS_DISKFORMAT_2GBSPARSE                    = "2gbsparse";
   public static final String       VMKFSTOOLS_DISKFORMAT_MONOFLAT                     = "monoflat";
   public static final String       VMKFSTOOLS_DISKFORMAT_MONOSPARSE                   = "monosparse";

   /*
    * Constants for I18N support
    */
   public static final String       ENCODING_UTF8                                      = "UTF-8";

   /*
    * Various ManagedObjectResource object types
    */
   public static final String       RESOURCEPOOL_TYPE                                  = "ResourcePool";
   public static final String       CLUSTER_TYPE                                       = "ClusterComputeResource";
   public static final String       DATACENTER_TYPE                                    = "Datacenter";
   public static final String       DATACENTER_POWER_ON                                = "Datacenter.powerOnVm";

   /*
    * Constants to specify the vnic type to be migrated
    */
   public static final String       SERVICE_CONSOLE                                    = "vswif";
   public static final String       VMKNIC                                             = "vmknic";

   /*
    * Waiting for VM guest to run timeout
    */
   public static final int          VM_GUEST_RUN_TIMEOUT                               = 120;

   /*
    * Command to write to hostd_Strmemory.log file
    */
   public static final String       SSH_SETUPCOMPLETE_ECHOCOMMAND                      = "echo Test setup "
                                                                                                + "completed >> //var//log//vmware//hostd_Strmemory.log";

   /*
    * IPMI Details
    */
   public static final List<String> HOST_IPMI_DETAILS                                  = new ArrayList<String>();
   public static final String       HOST_IPMI_DETAILS_PREFIX                           = "HOST_IPMI_DETAILS_";
   public static final String       HP_HOST_IPMI_PASSWORD                              = "calvin";
   /*
    * Test constant for Screenshot verification event
    */
   public static final String       SCREENSHOT_EVENT                                   = "screenshot";
   /*
    * VMCP reset event Message
    */
   public static final String       VMCPRESETEVENTMESSAGE                              = "datastore accessibility restored after APD timeout";
   /*
    * Test constant for Calendar class
    */
   public static final Calendar     DEFAULT_CALENDAR_VALUE                             = new GregorianCalendar(
                                                                                                2007,
                                                                                                Calendar.JANUARY,
                                                                                                1);
   public static final String       EESX_SSHCOMMAND_STOPHOSTD                          = "/etc/init.d/hostd stop";
   public static final String       EESX_SSHCOMMAND_STARTHOSTD                         = "/etc/init.d/hostd start";
   public static final String       EESX_SSHCOMMAND_HOSTD_STATUS_CHECK                 = "/etc/init.d/hostd status";
   public static final String       EESX_SSHCOMMAND_HOSTD_STATUS_CHECK_OUTPUT          = "hostd is running";
   public static final String       ESX_SSHCOMMAND_STOPHOSTD                           = "service mgmt-vmware stop";
   public static final String       ESX_SSHCOMMAND_STARTHOSTD                          = "service mgmt-vmware start";
   public static final String       ESX_SSHCOMMAND_HOSTD_STATUS_CHECK                  = "service mgmt-vmware status";
   public static final String       ESX_SSHCOMMAND_HOSTD_STATUS_CHECK_OUTPUT           = "running";

   /*
    * Test Constants for RemoteSerialPort and VSPC
    */
   public static final String       PORT_LISTENING                                     = "LISTENING";
   public static final String       VERIFY_PORT                                        = PORT_LISTENING;
   public static final String       PORT_ESTABLISHED                                   = "ESTABLISHED";
   public static final String       VSPC_FILE                                          = "vspc.pl";
   public static final String       TELNET_FILE                                        = "Telnet.pm";
   public static final String       FILE_INPUT                                         = "input.txt";
   public static final String       FILE_OUTPUT                                        = "output.txt";
   public static final String       FILE_ERRORS                                        = "errors.txt";
   public static final String       WINDOWS_SSH_CDRIVE                                 = "C:/";
   public static final int          RANDOM_PORT                                        = 7272;
   public static final int          PORT_ATTEMPTS                                      = 10;
   public static final String       VSPC_HOST_USERNAME;
   public static final String       VSPC_INPUT                                         = "A\nB\nC\nD\nE\n";
   public static final String       VSPC_ASCII_OUTPUT                                  = "4142434445";
   public static final String       VSPC_FILES_PATH;

   // direction constants for URI backing for RemoteSerialPort
   public static final String       SERVER                                             = "server";
   public static final String       CLIENT                                             = "client";
   // disabled method name constants
   public static final String       SHUTDOWN_GUEST_METHOD                              = "ShutdownGuest";
   public static final String       REBOOT_GUEST_METHOD                                = "RebootGuest";

   // protocols for for URI backing for RemoteSerialPort and VSPC
   public static final String       TCP                                                = "tcp://";
   public static final String       TELNET                                             = "telnet://";
   public static final String       PROTOCOL_SERVICEURI                                = TCP;
   public static final String       PROTOCOL_PROXYURI                                  = TELNET;
   public static final String       PORT_VSPC                                          = "12345";
   public static final String       DEFAULT_SERVER_IP                                  = "";
   public static final String       VSPC_HOST_NAME                                     = "RHEL5_32";
   public static final String       INVALID_DIRECTION                                  = "invalid_direction";
   public static final String       VSPC_INVALID_STING                                 = "bogus";
   public static final int          PORT_OUT_OF_RANGE                                  = 65536;
   public static final int          PORT_NEGATIVE                                      = -1;

   // Messages for invalid serviceURI
   public static final String       BAD_FILENAME                                       = "msg.serial.network.badFileName";
   public static final String       BAD_ENDPOINT                                       = "msg.serial.network.badEndpoint";
   public static final String       BAD_INTERNETADDRESS                                = "msg.serial.network.badInternetAddress";
   public static final String       INVALID_ADDRESS                                    = "msg.serial.network.gai.invalidAddress";
   public static final String       PORT_EMPTY                                         = "msg.serial.network.gai.portEmpty";
   public static final String       NO_PORT                                            = "msg.serial.network.gai.noPort";

   // constants for USB Speed
   public static final String       USB_SPEED_HIGH                                     = "high";
   public static final String       USB_SPEED_SUPERSPEED                               = "superSpeed";

   /*
    * Resource type constants.
    */
   public static final int          CPU_RESERVATION                                    = 1;
   public static final int          CPU_LIMIT                                          = 2;
   public static final int          CPU_TYPE                                           = 3;
   public static final int          CPU_SHARES                                         = 4;
   public static final int          MEMORY_RESERVATION                                 = 5;
   public static final int          MEMORY_LIMIT                                       = 6;
   public static final int          MEMORY_TYPE                                        = 7;
   public static final int          MEMORY_SHARES                                      = 8;

   /*
    * Test constants for vmx configuration parameters
    */
   public static final String       VMX_DISABLE_DIRECTEXEC                             = "monitor_control.disable_directexec";

   /*
    * These guest OS need Apple hardware as the host, for vm to be powered on.
    * Also cannot power-on a VM with guestOS = vmKernelGuest when the ESX itself
    * is in a VM (as is the case in Hudson environments)
    */
   public static final String[]     BYPASS_POWEROPS_VM_LIST                            = {
            "darwin64Guest", "darwin10_64Guest", "darwinGuest",
            "darwin10Guest", "darwin11Guest", "darwin11_64Guest",
            "vmkernelGuest", "vmkernel5Guest", "eComStationGuest",
            "eComStation2Guest", "darwin12_64Guest", "darwin13_64Guest"               };
   /*
    * Constant for maximum number of seconds the times between VC and ESX host
    * are allowed to differ. Ensuring time is in sync allows easier debugging
    * through logs.
    */
   public static final long         VC_ESX_MAX_TIME_DIFF_SEC                           = 10;

   /*
    * Constants for VirtualMachineFileLayoutExFileInfo types
    */
   public static final String       VM_FILEINFOTYPE_DISK_DESC                          = "diskDescriptor";
   public static final String       VM_FILEINFOTYPE_DISK_EXTEN                         = "diskExtent";
   public static final String       VM_FILEINFOTYPE_LOG                                = "log";
   public static final String       VM_FILEINFOTYPE_CONFIG                             = "config";
   public static final String       VM_FILEINFOTYPE_EXTENDED_CONFIG                    = "extendedConfig";
   public static final String       VM_FILEINFOTYPE_NVRAM                              = "nvram";
   public static final String       VM_FILEINFOTYPE_SNAPSHOT                           = "snapshotList";
   public static final String       VM_FILEINFOTYPE_SUSPEND                            = "suspend";

   /*
    * Constants for VirtualMachine config.extraConfig
    */
   public static final String       MAX_MEM_CTRL                                       = "sched.mem.maxmemctl";
   public static final String       PSHARE_ENABLED                                     = "sched.mem.pshare.enable";
   public static final String       MEM_COMPRESSION                                    = "sched.mem.zip.enable";
   /*
    * Timeout period for a method to be enabled.
    */
   public static final int          METHOD_ENABLE_TIMEOUT_MS                           = 5000;

   /*
    * Test Input Constants
    */
   public static final String       TESTINPUT_HOSTNAME                                 = "hostname";
   public static final String       TESTINPUT_PREFERRED_IP_TYPE                        = "ipType";
   public static final String       TESTINPUT_PORT                                     = "port";
   public static final String       TESTINPUT_USERNAME                                 = "username";
   public static final String       TESTINPUT_PASSWORD                                 = "password";
   public static final String       TESTINPUT_XML                                      = "xmlFile";
   public static final String       TESTINPUT_XMLSCHEMA                                = "xmlSchema";

   // The next testinput entries are optional inputs.
   public static final String       TESTINPUT_MACHINE_USERNAME                         = "machine.username";
   public static final String       TESTINPUT_MACHINE_PASSWORD                         = "machine.password";
   public static final String       TESTINPUT_COLLECTLOGS                              = "collectLogs";
   public static final String       TESTINPUT_SYSTEMLOGSPATH                           = "systemLogsPath";
   public static final String       TESTINPUT_INFRA_HOSTNAME                           = "infraHostname";
   public static final String       TESTINPUT_INFRA_HOST_ADMIN_USERNAME                = "infraHostAdminUsername";
   public static final String       TESTINPUT_INFRA_HOST_ADMIN_PASSWORD                = "infraHostAdminPassword";
   public static final String       TESTINPUT_INFRA_HOST_MACHINE_USERNAME              = "infrahost.machine.username";
   public static final String       TESTINPUT_INFRA_HOST_MACHINE_PASSWORD              = "infrahost.machine.password";
   public static final String       TESTINPUT_TESTBEDINFOJSONFILE                      = "testbedInfoJsonFile";
   public static final String       TESTINPUT_USE_DNS_HOSTNAME                         = "useDnsHostName";
   public static final String       TESTINPUT_HOSTINDEX                                = "hostIndex";
   public static final String       TESTINPUT_RUN_SUITES_IN_PARALLEL                   = "runSuitesInParallel";

   /*
    * VZSim Constants
    */
   public static final String       VZSIM_OVF_FILE_LINK                                = "vzsimOvfFileLink";
   public static final String       VZSIM_DISK_NAME_TO_EXPAND                          = "hard disk 2";
   public static final String       VZSIM_VM                                           = "vzsimVM";
   public static final String       VZSIM_HOSTD_SIM_RPM                                = "hostdSimRPM";
   public static final String       VZSIM_HOST                                         = "vzsimHost";
   public static final String       VZSIM_DATA_STORE                                   = "vzsimDataStore";
   public static final String       VZSIM_CONTAINER_USERNAME                           = "root";
   public static final String       VZSIM_CONTAINER_PASSWORD                           = "ca$hc0w";
   public static final String       VZSIM_IP                                           = "vzsimIP";
   public static final String       VZSIM_MOCKUP_HOST_CONFIG_ABSOLUTE_PATH             = "/etc/vmware/hostd/mockup-host-config.xml";
   public static final String       VZSIM_CONFIG_FILE_PATH                             = "/etc/vzsim.conf";
   public static final String       VZSIM_CONFIG_FILE_NAME                             = "vzsim.conf";
   public static final String       VZSIM_CONFIG_FILE_LOCATION                         = "/etc";
   public static final String       VZSIM_TEMPLATES_LOCATION                           = "/var/lib/vz/shared/";
   public static final String       VZSIM_MOCKUP_HOST_CONFIG_FILENAME                  = "mockup-host-config.xml";
   public static final String       VZSIM_MOCKUP_HOST_CONFIG_LOCATION                  = "/etc/vmware/hostd";
   public static final String       VZSIM_5_POINT_5_TEMPLATE                           = "sim5.5base";
   public static final String       VZSIM_6_POINT_0_TEMPLATE                           = "sim6.0base";
   public static final String       VZSIM_CONTAINER_VMFS_LOCATION                      = "/vmfs/volumes";
   public static final int          VZSIM_DATASTORE_UUID_FIRST_CHUNK_LENGTH            = 8;
   public static final int          VZSIM_DATASTORE_UUID_MIDDLE_CHUNK_LENGTH           = 12;
   public static final int          VZSIM_DATASTORE_UUID_LAST_CHUNK_LENGTH             = 12;
   public static final String       JAVA_TMPDIR                                        = "java.io.tmpdir";

   /*
    * OVF and OVA Constants
    */
   public static final String       OVA_TEMP_PREFIX                                    = "temp_";
   public static final String       OVA_FILE_EXTENSION                                 = ".ova";

   /*
    * LUN Thinp Constants
    */
   /**
    * @deprecated please use enum {@link VmDiskType} for representing different
    *             disk types.
    */
   @Deprecated
   public static final String       THIN                                               = "thin";
   @Deprecated
   public static final String       THICK                                              = "thick";
   @Deprecated
   public static final String       EAGERZERO                                          = "eagerzero";
   public static final String       BACKING_ONESUFFICIENT                              = "onesufficient";
   public static final String       BACKING_ONE_INSUFFICIENT                           = "oneinsufficient";
   public static final String       BACKING_TWOSUFFICIENT                              = "twosufficient";
   public static final String       BACKING_TWO_INSUFFICIENT                           = "twoinsufficient";
   public static final String       BACKING_BOTH_SUFFANDINSUFF                         = "bothSufficientAndInsufficient";
   public static final String       VM_SIZE_VERIFY                                     = "VM created with expected Disk Size";
   public static final int          BLOCKS_IN_SIZE                                     = 1000;

   /*
    * CBRC Constants
    */
   public static final String       CBRC_ENABLE_ADV_OPTION_KEY                         = "CBRC.Enable";
   public static final String       CBRC_DIGEST_DISK_FILEEXTN                          = "-digest.vmdk";
   public static final String       CBRC_DIGEST_FLATDISK_FILEEXTN                      = "-digest-flat.vmdk";
   public static final String       CBRC_DIGEST_DELTADISK_FILEEXTN                     = "-digest-delta.vmdk";
   public static final String       CBRC_UPDATEONCLOSE_OPTION_KEY                      = "Digest.UpdateOnClose";
   /*
    * sVmotion Constant
    */
   public static String             LATE_SVMOTION                                      = "svmotion.lateCompareDisks";

   public static final class VMX_CONFIG_OPTIONS
   {
      public static final String SVMOTION_LATE_COMPAREDISKS     = "svmotion.lateCompareDisks = \\\"True\\\"";
      public static final String SVMOTION_CRASH_IF_DISKS_DIFFER = "svmotion.crashIfDisksDiffer = \\\"True\\\"";
      public static final String SVMOTION_LEAVE_DEST_DISKS      = "svmotion.leaveDestinationDisks = \\\"True\\\"";
      public static final String SVMOTION_COMPARE_DISKS         = "svmotion.compareDisks = \\\"False\\\"";
      public static final String MIGRATION_CHECKSUM_MEMORY      = "migration.checksumMemory = \\\"False\\\"";
      public static final String SCHED_MEM_PIN                  = "sched_mem_pin = \\\"True\\\"";
      public static final String SCHED_MEM_MIN                  = "sched_mem_min = \\\"1024\\\"";
      public static final String WORKING_DIR                    = "workingDir = \\\"/vmfs/volumes/";
      public static final String CREATE_WORKING_DIR             = "/vmfs/volumes/";
   }

   /**
    * Low Level Provisioning related constants.
    */
   public static final int           LLPM_RETRIEVE_MIGRATIONSTATE_IN_SVMOTION_TASKPROGRESS = 45;
   /*
    * Stress test debug logging
    */
   public static boolean             DISABLE_STRESS_DEBUG_LOGGING                          = false;

   /*
    * VSAN related prop to switch test workflow to accomodate vsan
    */

   public static final boolean       VSAN_MODE;

   /*
    * VSAN related prop to switch between RawData and SPBM policy
    */

   public static final ProfileSource VSAN_PROFILE_MODE;

   public static final boolean       VVOL_MODE;

   /*
    * Constants for Storage APD Handling
    */
   public static final String        APD_TIMEOUT_CONFIG_KEY                                = "Misc.APDTimeout";
   public static final String        APD_HANDLING_CONFIG_KEY                               = "Misc.APDHandlingEnable";
   public static final Long          APD_HANDLING_DISABLED                                 = 0L;
   public static final Long          APD_HANDLING_ENABLED                                  = 1L;
   public static final Long          DEFAULT_APD_TIMEOUT_VAL                               = 140L;

   /*
    * X-VC related property to switch test workflow to use dvs.
    */
   public static Boolean             XVC_DVS_MODE;

   /**
    * I/O Parameters, sample usage in xvmotion.xvm.XvMotionWithPeripherals
    */
   public static final String		NUM_OF_PROCESSES									 	= "numOfProcesses";
   public static final String		LIMIT_IN_MB											 	= "limitInMB";
   public static final String		RUNTIME_IN_MIN											= "runTimeInMin";

   /**
    * storageContainerNameList in config.properties to filter storage container
    * name
    */
   public static List<String>        STORAGE_CONTAINER_NAME_LIST                           = new ArrayList<String>();

   /*
    * NOTE: STATIC BLOCK SHOULD BE AT THE END OF THIS FILE. ALL TEST CONSTANTS
    * SHOULD BE DEFINED ABOVE THIS STATIC BLOCK
    */
   /*
    * ========= Static Block starts here =============================
    */
   static {
      final URL resourceUrl = TestConstants.class
               .getResource("/hostconf/nfcservice/nfcclient/py/nfcTest2.py");
      NFC_CLIENT = null == resourceUrl ? "" : resourceUrl.getFile();
      TOOLS_RUNCHECK_TIMEOUT = Integer.valueOf(TestDataHandler.getValue(
               "tools_runcheck_timeout", "1500"));
      UPDATES_TIMEOUT_MAXATTEMPT = Integer.valueOf(TestDataHandler.getValue(
               "updates_timeout_maxattempt", "3"));
      // Fix for PR-975454, The socket timeout is 60 mins currently. This can be
      // reduced once the vc starts sending more granular updates
      SOCKET_TIMEOUT = Integer.valueOf(TestDataHandler.getValue(
               "sockettimeout", "3600000"));
      WAIT_FOR_UPDATE_MAX_SEC = Integer.valueOf(TestDataHandler.getValue(
               "waitforupdatemaxsec", "1800000"));
      // End of solution for PR-975454
      SYS_ALERT_ENABLED = Boolean.valueOf(TestDataHandler.getValue(
               "checkSysAlert", Boolean.TRUE.toString()));
      LOG_COLLECTION_ENABLED = Boolean.valueOf(TestDataHandler.getValue(
               "collectLogsOnFailure", Boolean.FALSE.toString()));
      LOG_COLLECTION_PARALLEL = Boolean.valueOf(TestDataHandler.getValue(
               "collectLogsOnFailureInParallel", Boolean.TRUE.toString()));
      LOG_COLLECTION_NFS = TestDataHandler.getValue("collectLogsOnFailureNfs",
               null);
      RUNLIST_FILTER_ENABLED = Boolean.valueOf(TestDataHandler.getValue(
               "runlistFilterEnabled", Boolean.FALSE.toString()));
      RUNLIST_FILTER_IGNORE_LIST = TestDataHandler.getValue(
               "runlistFilterIgnoreList", null);
      CHECK_PROPERTIES = Boolean.valueOf(TestDataHandler.getValue(
               "enablePropCollCheck", Boolean.FALSE.toString()));
      CAPTURE_VM_LOGS = Boolean.valueOf(TestDataHandler.getValue(
               "captureVmLogs", Boolean.FALSE.toString()));
      OPERATIONS_IGNORED_FOR_OPID_LOGGING = Arrays.asList(TestDataHandler
               .getValue("operations.ignore.opid.logging", "").split(";"));

      TEST_ANALYSIS_ENABLED = Boolean.valueOf(TestDataHandler.getValue(
               "failureAnalysis", Boolean.FALSE.toString()));
      VM_LOG_COLLECTION_ENABLED = Boolean.valueOf(TestDataHandler.getValue(
               "collectVmLogsAfterTestFailure", Boolean.FALSE.toString()));
      VMFS_STORAGEIO_TEST_EXECUTION = Boolean.valueOf(TestDataHandler.getValue(
               "vmfsStorageIOTestExecution", Boolean.FALSE.toString()));
      TESTINPUT_DONOT_CHECK_FOR_INFRA_HOSTNAME = Boolean.getBoolean(TestDataHandler.getValue(
               "defaultInfraHostname", "true"));
      /*
       * IPMI properties. Put a file named 'ipmi.hosts' on classpath (if needed)
       * or add the IPMI entries into the test properties file.
       */
      Configuration ipmiConfig = null;
      final URL ipmiConfigUrl = TestConstants.class.getClassLoader()
               .getResource("ipmi.hosts");
      if (null != ipmiConfigUrl) {
         try {
            ipmiConfig = new PropertiesConfiguration(ipmiConfigUrl);
         } catch (final ConfigurationException e) {
            log.error("Configuration error while configuring IPMI hosts details");
         }
      } else {
         ipmiConfig = TestDataHandler.getSingleton().getData();
         log.warn("Jar location = "
                  + ipmiConfig.getClass().getProtectionDomain().getCodeSource()
                           .getLocation().toString());
      }
      if (ipmiConfig != null) {
         /*
          * Get custom values for IPMI details for up to 32 hosts. System is
          * inconsistent about returning the property as a String or a String
          * array. So, handle both.
          */
         for (int i = 0; i < 32; i++) {
            String tmpIpmiDetails = null;
            Object objProperty = ipmiConfig
                     .getProperty(HOST_IPMI_DETAILS_PREFIX + i);
            if (objProperty instanceof String) {
               tmpIpmiDetails = (String) objProperty;
            } else if (objProperty instanceof String[]) {
               String[] objStringArray = (String[]) objProperty;
               tmpIpmiDetails = objStringArray[0];
               for (int nIndex = 1; nIndex < objStringArray.length; nIndex++) {
                  tmpIpmiDetails += "," + objStringArray[nIndex];
               }
            }
            if (tmpIpmiDetails != null) {
               HOST_IPMI_DETAILS.add(tmpIpmiDetails);
            }
         }
      } else {
         /*
          * If no test constant properties file, use defaults specified here:
          */
         HOST_IPMI_DETAILS
                  .add("10.112.8.24,root,calvin,10.112.8.73,00:1c:23:d5:70:6d");
         HOST_IPMI_DETAILS
                  .add("10.112.8.25,root,calvin,10.112.8.74,00:1c:23:d5:72:cb");
         HOST_IPMI_DETAILS
                  .add("10.112.8.28,root,calvin,10.112.8.75,00:1c:23:d5:72:ef");
         HOST_IPMI_DETAILS
                  .add("10.112.8.29,root,calvin,10.112.8.76,00:1c:23:d5:72:ed");
      }
      // StorageSystem -- NFS
      //nfs datastore type can be either 'NFS' or 'nfsv41'
      DATASTORETYPE = TestDataHandler.getValue(
              "datastoreType", "NFS");
      //nfs41 security type can be either 'AUTH_SYS' or 'SEC_KRB5'
      NFS41_SECURITY_TYPE = TestDataHandler.getValue(
              "nfs41securityType", "AUTH_SYS");
      REMOTEHOST1_VALID = TestDataHandler.getValue("remotehost1.valid",
               "sdk226.eng.vmware.com");
      List<String> nfsarraylist = new ArrayList<String>();
      nfsarraylist.add("vmc-vnx5500-store02-nfs.eng.vmware.com");
      REMOTEHOST1_VALID_NFS = TestDataHandler.getValues(
               "remotehost1.valid.nfs", nfsarraylist);
      REMOTEPATH1_VALID_FOR_REMOTEHOST1 = TestDataHandler.getValue(
               "remotepath1.valid.for.remotehost1", "/export/nfs1");
      REMOTEPATH2_VALID_FOR_REMOTEHOST1 = TestDataHandler.getValue(
               "remotepath2.valid.for.remotehost1", "/export/nfs2");
      REMOTEPATH3_VALID_FOR_REMOTEHOST1 = TestDataHandler.getValue(
               "remotepath3.valid.for.remotehost1", "/export/nfs3");
      REMOTEPATH4_VALID_FOR_ROOTSQUASHING = TestDataHandler.getValue(
               "remotepath4.valid.for.rootsquashing", "/export/nfs1");
      REMOTEPATH5_VALID_FOR_ROOTSQUASHING = TestDataHandler.getValue(
               "remotepath5.valid.for.rootsquashing", "/export/nfs2");
      REMOTEHOST2_VALID = TestDataHandler.getValue("remotehost2.valid",
               "sdk158.eng.vmware.com");
      REMOTEPATH1_VALID_FOR_REMOTEHOST2 = TestDataHandler.getValue(
               "remotepath1.valid.for.remotehost2", "/export/nfs1");
      REMOTEHOST_INVALID_NO_NFS_RUNNING = TestDataHandler.getValue(
               "remotehost.invalid.no.nfs.running", "10.17.10.55");
      REMOTEHOST_UDP_PROTOCOL = TestDataHandler.getValue(
               "remotehost.udp.protocol", "10.17.10.76");
      REMOTEPATH_UDP_PROTOCOL = TestDataHandler.getValue(
               "remotepath.udp.protocol", "/mynfs");
	  DNS_PRIMARY_SERVER = TestDataHandler.getValue("dns.primary.server",
                           null);
      DNS_ALTERNATIVE_SERVER = TestDataHandler.getValue(
                "dns.alternative.server", null);
      NTP_SERVER = TestDataHandler.getValue(
                "nfs.ntp.server", null);
      NFS_KERBEROS_USERNAME = TestDataHandler.getValue(
                "nfs.kerberos.username", null);
      NFS_KERBEROS_PASSWORD = TestDataHandler.getValue(
                "nfs.kerberos.password", null);
      NFS_AD_DOMAINNAME = TestDataHandler.getValue("nfs.ad.domainname", null);
      NFS_AD_USERNAME = TestDataHandler.getValue("nfs.ad.username",
                 "Administrator");
      NFS_AD_PASSWORD = TestDataHandler.getValue("nfs.ad.password", null);
      IS_DEFAULT_VSWITCH = Boolean.valueOf(TestDataHandler.getValue("nfs.ipv6.switch.default", Boolean.TRUE.toString()));
      NFS_IPV6_TYPE = TestDataHandler.getValue("nfs.ipv6.type", null);
      // EAM Constants
      EAM_OVF_IPV4_REPOSITORY = TestDataHandler.getValue(
               "eam.ovf.ipv4.repository",
               "http://sdkqa-storage.eng.vmware.com:33894/eam/esx60/");
      EAM_OVF_IPV6_REPOSITORY = TestDataHandler.getValue(
               "eam.ovf.ipv6.repository",
               "http://[fc00:10:112:29:250:56ff:fe91:5969]:36245/eam/esx60/");
      if (TestUtil.isIpv6Address(TestDataHandler.getValue(TESTINPUT_HOSTNAME,
               null))) {
         EAM_OVF_REPOSITORY = EAM_OVF_IPV6_REPOSITORY;
      } else {
         EAM_OVF_REPOSITORY = EAM_OVF_IPV4_REPOSITORY;
      }
      EAM_REPOSITORY_DRIVE = TestDataHandler.getValue(
               "eam.ovf.repository.drive", "c");
      IOFILTER_VIB_REPOSITORY = TestDataHandler.getValue(
               "iofilter.vib.repository",
               "http://engweb.eng.vmware.com/~qa/iofilters/");
      // FDM VM ApplicationMonitoring constants
      SSHCOMMAND_VM_APPMONITORING_TAR_FILE = TestDataHandler.getValue(
               "fdm.vmAppMonitoringTarFile", "GuestSDK.tar");
      SSHCOMMAND_VM_APPMONITORING_SDK_REPOSITORY = TestDataHandler.getValue(
               "fdm.vmAppMonitoringSdkRepository",
               "http://sdkqa-storage.eng.vmware.com");
      STORAGE_IO_WINDOWS_VMNAME = TestDataHandler.getValue(
               "fdm.storageIO.windowsVMName", "iormvm");
      // HBA
      HBA_FOR_RESCAN = TestDataHandler.getValue("hba.for.rescan", "vmhba1");
      HOST_INTERNET_SCSI_HBA_IP_ADDRESS1 = TestDataHandler.getValue(
               "host.internet.scsi.hba.ip.address1", "10.18.13.210");
      HOST_INTERNET_SCSI_HBA_IP_ADDRESS2 = TestDataHandler.getValue(
               "host.internet.scsi.hba.ip.address2", "10.18.13.211");
      VSHARE_ARRAY = TestDataHandler.getValue("vshare.array", "10.20.59.183");

      HOST_INTERNET_SCSI_DEFAULT_NAME = TestDataHandler.getValue(
               "host.internet.scsi.default.name",
               "iqn.1992-04.com.emc:cx.apm00071603405.a0");
      HOST_INTERNET_SCSI_DEFAULT_NAME2 = TestDataHandler.getValue(
               "host.internet.scsi.default.name2",
               "iqn.1992-04.com.emc:cx.apm00071603405.b0");

      // ESX login information
      ESX_USERNAME = TestDataHandler.getValue("esx.username", "root");
      ESX_PASSWORD = TestDataHandler.getValue("esx.password", "ca$hc0w");
      VSPC_HOST_USERNAME = ESX_USERNAME;

      // VSPC
      VSPC_FILES_PATH = TestDataHandler
               .getValue("vspc.files.path", "/scratch/");

      /*
       * Nis Server Location
       */
      NIS_SERVER_LOCATION = TestDataHandler.getValue("nis.server.location",
               "nis1-pao5.eng.vmware.com");

      /**
       * Enable QC Result posting
       */
      QC_RESULTS_POSTING = Boolean.valueOf(TestDataHandler.getValue(
               "qc.results.posting", Boolean.FALSE.toString()));

      /*
       * Populate Primitive types used in TestUtil
       */
      MAP_PRIMITIVE_WRAPPERS.put(int.class, Integer.class);
      MAP_PRIMITIVE_WRAPPERS.put(float.class, Float.class);
      MAP_PRIMITIVE_WRAPPERS.put(double.class, Double.class);
      MAP_PRIMITIVE_WRAPPERS.put(long.class, Long.class);
      MAP_PRIMITIVE_WRAPPERS.put(boolean.class, Boolean.class);
      MAP_PRIMITIVE_WRAPPERS.put(byte.class, Byte.class);
      MAP_PRIMITIVE_WRAPPERS.put(char.class, Character.class);
      MAP_PRIMITIVE_WRAPPERS.put(short.class, Short.class);

      /*
       * static block to initialize VSAN related prop
       */
      VSAN_MODE = Boolean.valueOf(TestDataHandler.getValue("vsanMode",
               Boolean.FALSE.toString()));

      VSAN_PROFILE_MODE = ProfileSource.fromValue((TestDataHandler.getValue(
               "vsanProfileMode", ProfileSource.SPBM.getType())));

      /*
       * For a VSAN testbed, the 5 min default timeout is too short. Setting it
       * to 30 minutes for regression tests running in VSAN environment. See
       * http://bugzilla.eng.vmware.com/show_bug.cgi?id=970613#c45
       */
      ENTERMAINTENANCEMODE_TIMEOUT = VSAN_MODE ? 1800 : 300;

      VVOL_MODE = Boolean.valueOf(TestDataHandler.getValue("vvolMode",
               Boolean.FALSE.toString()));

      // X-VC
      XVC_DVS_MODE = Boolean.valueOf(TestDataHandler.getValue("xvc.dvsMode",
               Boolean.FALSE.toString()));

      // storageContainerNameList in config.properties to filter storage
      // container name
      STORAGE_CONTAINER_NAME_LIST = TestDataHandler.getValues(
               "storageContainerNameList", null);
   }

   /*
    * Name of the key in config.properties used to identify the name of the
    * datastore that cpu.compatibility.VmReqCollectorCreateVMs uses to create
    * the new VMs.
    */
   public static final String        DATASTORENAME                                         = "datastorename";
   /*
    * ========= Static Block ends here =============================
    */
   /*
    * -------NO TEST CONSTANTS SHOULD BE DEFINED AT THE END OF THIS FILE -------
    */

   public static final String        WIN_SSL_LOCATION                                      = "C:/Documents\\ and\\ Settings/All\\ Users/Application\\ Data/VMware/VMware\\ VirtualCenter/SSL";
   public static final String        WIN7_SSL_LOCATION                                     = "C:/ProgramData\\VMware\\VMware VirtualCenter\\SSL";
   public static final String        NEW_CERTS_LOCATION                                    = "new_certs";
   public static final String        OLD_CERTS_LOCATION                                    = "old_certs";
   public static String              WIN_CERT_PATH                                         = "C:/";
   public static String              LIN_CERT_PATH                                         = "/tmp/";
   public static final int           VM_OPS_WAIT_TIME                                      = 30;

   /*
    * VMCP storage protocol constants
    */
   public static enum vmcpStorageProtocol {
      FC, NFS, ISCSI, FCOE;
   }

   public static enum objectType {
      OBJECTTYPE_VVOLDS, OBJECTTYPE_VM, OBJECTTYPE_VVOL;
   }
    /**
	 * NFS41 & NFS Constants
	 *
	 **/

	public static final String NAS41_DATASTORE_TYPE = "NFS41";
	public static final String NFSV41_DATASTORE_TYPE = "NFSV41";
	public static final Long NFS41_MAX_VOLUMES = new Long(256);
	public static final Long NFS_MAX_VOLUMES = new Long(256);
	public static final Long NAS_MIN_VOLUMES = new Long(32);
	public static final String NFS_MAX_VOLUMES_LABEL = "NFS.MaxVolumes";
	public static final String NFS41_MAX_VOLUMES_LABEL = "NFS41.MaxVolumes";
	public static final String SUN_RPC_MAX_CONN_PER_IP_LABEL = "SunRPC.MaxConnPerIP";

	public static final Long SUN_RPC_MAX_CONN_PER_IP = new Long(128);
	public static final Long SUN_RPC_MIN_CONN_PER_IP = new Long(4);
	
	public static final String DNS_PRIMARY_SERVER;
    public static final String DNS_ALTERNATIVE_SERVER;
    public static final String NTP_SERVER;
    public static final String NFS_KERBEROS_USERNAME;
    public static final String NFS_KERBEROS_PASSWORD;
    public static final String NFS_AD_DOMAINNAME;
    public static final String NFS_AD_USERNAME;
    public static final String NFS_AD_PASSWORD;
    public static final boolean IS_DEFAULT_VSWITCH;
    public static final String NFS_IPV6_TYPE;
   	public static enum SecurityType {
		AUTH_SYS, SEC_KRB5;
	}
}
