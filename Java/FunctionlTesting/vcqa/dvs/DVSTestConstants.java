/* ************************************************************************
 *
 * Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package com.vmware.vcqa.vim.dvs;

import static com.vmware.vc.VmwareDistributedVirtualSwitchPvlanPortType.COMMUNITY;
import static com.vmware.vc.VmwareDistributedVirtualSwitchPvlanPortType.ISOLATED;
import static com.vmware.vc.VmwareDistributedVirtualSwitchPvlanPortType.PROMISCUOUS;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.vc.LinkDiscoveryProtocolConfigOperationType;
import com.vmware.vc.DistributedVirtualPortgroupMetaTagName;
import com.vmware.vc.DistributedVirtualPortgroupPortgroupType;
import com.vmware.vc.DistributedVirtualSwitchProductSpecOperationType;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.LinkDiscoveryProtocolConfigProtocolType;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NoCompatibleHost;
import com.vmware.vc.NotSupported;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.execution.TestDataHandler;

/**
 * DVS Test Constants encapsulates all constants defined for
 * DVS SDK calls and constants in DVS tests.
 */
public class DVSTestConstants
{
   private static final Logger log = LoggerFactory.getLogger(DVSTestConstants.class);
   /*
    * ========= constructor methods should go here ===========================
    */
   private DVSTestConstants()
   {

   }

   /*
    * ========= public static constants should go here =======================
    */
   public static final String DVS_CREATE_NAME_PREFIX = "CreateDVS-";
   public static final String DVS_RECONFIG_NAME_PREFIX = "ReconfigDVS-";
   public static final String DVS_MISC_NAME_PREFIX = "FunctionalDVS-";
   public static final String DVS_NESTED_FOLDER_NAME_SUFFIX = "_NESTED_FOLDER";
   public static final String DVS_DESTINATION_SUFFIX = "_DEST";
   public static final String DVS_SOURCE_SUFFIX  = "_SOURCE";
   public static final String DVS_FOLDER_NAME_SUFFIX = "_FOLDER";
   public static final int DVS_MAX_PORTS_VALUE = 256;
   public static final int DVS_DEFAULT_NUM_UPLINK_PORTS = 4;
   public static final String DV_PORTGROUP_CREATE_NAME_PREFIX =
                                 "CreateDVPortgroup-";
   public static final String DV_PORTGROUP_RECONFIG_NAME_PREFIX =
                                 "ReconfigDVPortgroup-";
   public static final String ALL_NUM_STRING = "0123456789";
   public static final String DVPORTGROUP_KEY_VALUE = "SampleKey";
   public static final String DVPORTGROUP_VALID_NAME_31_CHARS = "abcdefghijklm"
                                                          +"nopqrstuvwxyzabcde";
   public static final String NAME_ALPHA_NUMERIC_SPECIAL_CHARS =
           DVPORTGROUP_VALID_NAME_31_CHARS + TestConstants.SPL_CHAR_NAME.substring(0,
                                           TestConstants.SPL_CHAR_NAME.length()-2) +
           ALL_NUM_STRING;
   public static final String DVPORTGROUP_VALID_DESCRIPTION = "A test " +
                                                              "portgroup";
   public static final String DVPORTGROUP_INVALID_PORTNAMEFORMAT =
                                                             "$@#@@#@#@#@";
   public static final String DVPORTGROUP_CONFIGVERSION =
                                 "DVPortgroupConfigSpec.ConfigVersion";
   public static final String DVPORTGROUP_KEY =
                                 "DVPortgroupConfigSpec.Key";
   public static final String DVPORTGROUP_AUTOEXPAND = "DVPortgroupConfigSpec.AutoExpand";
   public static final String DVS_PORT_STATISTICS = "DVPortState.Stats";

   public static final String DVPORT_CONFIGSPEC_SCOPE =
                                 "DVPortConfigSpec.Scope";
   public static final String DVS_CONFIGVERSION = "DVSConfigSpec.ConfigVersion";
   public static final String VMWARE_DVS_CONFIGVERSION =
                                 "VMwareDVSConfigSpec.ConfigVersion";
   public static final String VMWARE_DVS_CONFIGINFO_CONFIGVERSION =
                                 "VMwareDVSConfigInfo.ConfigVersion";
   public static final String DVS_CONFIG_SPEC_NUM_PORTS =
                                                    "DVSConfigSpec.NumPorts";
   public static final String DVPORT_CONFIG_SPEC_OPERATION =
                                                  "DVPortConfigSpec.Operation";
   public static final String DVPORTGROUP_CONFIG_SPEC_NUM_PORTS =
                                 "DVPortgroupConfigSpec.NumPorts";
   public static final String VMWAREDVSCONFIGINFO_MAXPORTS =
      "VMwareDVSConfigInfo.MaxPorts";
   public static final String DVSOVERLAY_INSTANCE_KEY =
            "DVSOverlayInstanceConfigInfo.Key";
   public static final String DVSOVERLAY_INSTANCE_DVSUUID =
            "DVSOverlayInstance.dvsUuid";
   public static final String DVPORTGROUP_TYPE = "DVPORTGROUP_TYPE";
   public static final String DVPORTGROUP_TYPE_EPHEMERAL =
      DistributedVirtualPortgroupPortgroupType.EPHEMERAL.value();
   public static final String DVPORTGROUP_TYPE_LATE_BINDING =
      DistributedVirtualPortgroupPortgroupType.LATE_BINDING.value();
   public static final String DVPORTGROUP_TYPE_EARLY_BINDING =
      DistributedVirtualPortgroupPortgroupType.EARLY_BINDING.value();
   public static final String DVPORTGROUP_TYPE_STATIC = "static";
   public static final String DVPORTGROUP_TYPE_DYNAMIC = "dynamic";
   public static final String DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX =
      "<" + DistributedVirtualPortgroupMetaTagName.PORT_INDEX.value() + ">";
   public static final String DVPORTGROUP_PORTNAMEFORMAT_DVSNAME =
      "<" + DistributedVirtualPortgroupMetaTagName.DVS_NAME.value() +">";
   public static final String DVPORTGROUP_PORTNAMEFORMAT_PORTGROUPNAME =
      "<" + DistributedVirtualPortgroupMetaTagName.PORTGROUP_NAME.value() + ">";
   public static final String DVPORTGROUP_INVALID_CONFIGVERSION = "myVersion";
   public static final int DVPORTGROUP_INVALID_NUMPORTS = -15;
   public static final String DVPORTGROUP_INVALID_TYPE = "myBinding";
   public static final String INVALID_NAME_260_CHARS = "aaaaaaaaaaaaaaaa"
                           +"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" +
                            "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" +
                             "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"+
                             "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"+
                             "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"+
                             "aaaaaaaaaaaaaaaaaaaa";
   /*
    * Privilege constants for dvswitch and dvportgroup operations
    */
   public static final String DVSWITCH_CREATE_PRIVILEGE = "DVSwitch.Create";
   public static final String DVPORTGROUP_CREATE_PRIVILEGE =
                                                           "DVPortgroup.Create";
   public static final String DVPORTGROUP_MODIFY_PRIVILEGE =
                                                          "DVPortgroup.Modify";
   public static final String DVPORTGROUP_POLICY_PRIVILEGE =
                                                         "DVPortgroup.PolicyOp";
   public static final String DVPORTGROUP_SCOPE_PRIVILEGE =
                                                         "DVPortgroup.ScopeOp";

   /*
    * Link Discovery related constants
    */
   public static final String PROTOCOLTYPE_LLDP =
      LinkDiscoveryProtocolConfigProtocolType.LLDP.value();
   public static final String LINK_DISCOVERY_OPERATION_TYPE_NONE =
      LinkDiscoveryProtocolConfigOperationType.NONE.value();
   public static final String LINK_DISCOVERY_OPERATION_TYPE_ADVERTISE =
      LinkDiscoveryProtocolConfigOperationType.ADVERTISE.value();
   public static final String LINK_DISCOVERY_OPERATION_TYPE_BOTH =
      LinkDiscoveryProtocolConfigOperationType.BOTH.value();
   public static final String LINK_DISCOVERY_OPERATION_TYPE_LISTEN =
      LinkDiscoveryProtocolConfigOperationType.LISTEN.value();

   /*
    * LACP mutipleLag related constants
    */
   public static final String LACP_KEY = "VMwareDvsLacpGroupConfig.Key";
   public static final String LACP_UPLINKNAME = "VMwareDvsLacpGroupConfig.UplinkName";
   public static final String LACP_UPLINKPORTKEY = "VMwareDvsLacpGroupConfig.UplinkPortKey";

   // ** PVLAN Constants ** //
   /** The maximum number which can be used as PVLAN ID */
   public static final int MAX_PVLAN_ID = 4094;
   /** The minimum number which can be used as PVLAN ID */
   public static final int MIN_PVLAN_ID = 1;
   /** Represents the name of promiscuous port */
   public static final String PVLAN_TYPE_PROMISCUOUS = PROMISCUOUS.value();
   /** Represents the name of community port */
   public static final String PVLAN_TYPE_COMMINITY = COMMUNITY.value();
   /** Represents the name of isolated port */
   public static final String PVLAN_TYPE_ISOLATED = ISOLATED.value();

   /*
    * property file to store the alternate service console and vmk nic ipaddress
    */
   public static final String IP_MAP_FILE = "/dvs/ipMap.properties";
   public static final String DVS_PROP_FILE = "/dvs/DVS.properties";
   public static final String DVS_EXECUTION_PROP_FILE =
      "/dvs/dvsexecution.properties";
   public static final String DVS_DESC = "Dvs Description ";
   public static final Integer DVS_NUMPORTS = 100;
   public static final Integer DVS_MAXNUMPORTS = 2000;

   //contact info
   public static final String DVSCONTACTINFO_CONTACT = "DVSContact";
   public static final String DVSCONTACTINFO_NAME = "DVSContactName";
   public static final String CONTACT  =
      "VMwareDVSConfigInfo.Contact";
   public static final String DEFAULTPORTCONFIG  =
      "VMwareDVSConfigInfo.DefaultPortConfig";

   //vlan id range
   public static final Integer DVS_VLANIDSTART = 10;
   public static final Integer DVS_VLANIDEND = 20;

   public static final String DVPortgroupConfigInfo_distributedVirtualSwitch =
   "DVPortgroupConfigInfo.DistributedVirtualSwitch";
   public static final String DVPortgroupConfigInfo_key =
      "DVPortgroupConfigInfo.Key";
   public static final String DVPortgroupConfigInfo_scope =
      "DVPortgroupConfigInfo.Scope";
   public static final String DVPortgroupConfigInfo_effectiveDefaultPortConfig =
      "DVPortgroupConfigInfo.EffectiveDefaultPortConfig";
   public static final String DVPortgroupConfigInfo_numOfPorts =
      "DVPortgroupConfigInfo.NumOfPorts";

   public static final String ERROR_MESSAGE_NO_FREE_UPLINK =
      "Can not find any free uplink port key on the DVS";
   public static final String ERROR_MESSAGE_NO_FREE_PORT =
      "Can not find any free port on the DVS";

   public static boolean CHECK_GUEST = false;
   public static final String PORT_GROUP_CONFIG_KEY = "portgroupConfig";
   public static final String PORT_GROUP_SETTING_KEY = "portgroupSetting";

   /**
    * Constants for the keys used to populate and read from the port settings
    * map.
    */
   public static final String BLOCKED_KEY = "blocked";
   public static final String INSHAPING_POLICY_KEY = "inShapingPolicy";
   public static final String OUT_SHAPING_POLICY_KEY = "outShapingPolicy";
   public static final String VENDOR_SPECIFIC_CONFIG_KEY = "vendorSpecificConfig";
   public static final String IP_FIX_ENABLED_KEY = "ipfixEnabled";
   public static final String IP_FIX_INHERITED_KEY = "ipfixInherited";
   public static final String IPFIXOVERRIDEALLOWED = "IPFIXOVERRIDEALLOWED";
   public static final String QOS_TAG_KEY = "qosTag";
   public static final String SECURITY_POLICY_KEY = "securityPolicy";
   public static final String TX_UPLINK_KEY = "txUplink";
   public static final String UPLINK_TEAMING_POLICY_KEY = "uplinkTeamingPolicy";
   public static final String VLAN_KEY = "vlan";
   public static final String OVERLAYPARAMETER_POLICY_KEY = "overlayParameter";
   public static final String VmDirectPathGen2Allowed_KEY =
            "VMwareDVSPortSetting.VmDirectPathGen2Allowed";


   /*
    * Constants for the privileges
    */
   public static final String PRIVILEGE_HOST_CONFIG_NETWORK = "Host.Config.Network";
   public static final String PRIVILEGE_NETWORK_ASSIGN = "Network.Assign";
   public static final String PRIVILEGE_DVSWITCH_MODIFY = "DVSwitch.Modify";
   public static final String PRIVILEGE_DVSWITCH_HOSTOP = "DVSwitch.HostOp";

   /*
    * Constants for overlays
    */
   public static final String DVSOVERLAY_CLASS_NAME = "fence-overlay";
   public static final String DVSOVERLAY_INVALID_CLASS_NAME =
      "Invalid_Class_Name";

   /*
    * Constants for the DVSEvent classes
    */
   public static final String EVENT_DVSCREATEDEVENT =
                                                "com.vmware.vc.DvsCreatedEvent";
   public static final String EVENT_DVSDESTROYEDEVENT =
                                                "com.vmware.vc.DvsDestroyedEvent";
   public static final String EVENT_DVSHOSTJOINEDEVENT =
                                             "com.vmware.vc.DvsHostJoinedEvent";
   public static final String EVENT_DVSHOSTLEFTEVENT =
                                               "com.vmware.vc.DvsHostLeftEvent";
   public static final String EVENT_DVSMERGEDEVENT =
                                               "com.vmware.vc.DvsMergedEvent";
   public static final String EVENT_DVSPORTCREATEDEVENT =
                                                "com.vmware.vc.DvsPortCreatedEvent";
   public static final String EVENT_DVSPORTDELETEDEVENT =
                                             "com.vmware.vc.DvsPortDeletedEvent";

   public static final String EVENT_DVSPORTCONNECTEDEVENT =
                                             "com.vmware.vc.DvsPortConnectedEvent";

   public static final String EVENT_DVSPORTDISCONNECTEDEVENT =
                                       "com.vmware.vc.DvsPortDisconnectedEvent";
   public static final String EVENT_DVSPORTLINKDOWNEVENT =
                                          "com.vmware.vc.DvsPortLinkDownEvent";
   public static final String EVENT_DVSPORTLINKUPEVENT =
                                             "com.vmware.vc.DvsPortLinkUpEvent";
   public static final String EVENT_DVSRECONFIGUREDEVENT =
                                          "com.vmware.vc.DvsReconfiguredEvent";
   public static final String EVENT_DVSRENAMEDEVENT =
                                          "com.vmware.vc.DvsRenamedEvent";
   public static final String EVENT_DVSPORTRECONFIGUREDEVENT =
                                       "com.vmware.vc.DvsPortReconfiguredEvent";
   public static final String EVENT_DVSPORTBLOCKEDEVENT =
                                             "com.vmware.vc.DvsPortBlockedEvent";
   public static final String EVENT_DVPORTGROUPCREATEDEVENT =
                                             "com.vmware.vc.DVPortgroupCreatedEvent";
   public static final String EVENT_DVPORTGROUPDESTROYEDEVENT =
                                             "com.vmware.vc.DVPortgroupDestroyedEvent";

   public static final String EVENT_DVPORTGROUPRECONFIGUREDEVENT =
                                 "com.vmware.vc.DVPortgroupReconfiguredEvent";
   public static final String EVENT_DVPORTGROUPRENAMEDEVENT =
                                       "com.vmware.vc.DVPortgroupRenamedEvent";


   public static final String EVENT_DVSUPGRADEAVAILABLEEVENT =
            "com.vmware.vc.DvsUpgradeAvailableEvent";


   /*
    * Constants for the DVS HealthCheck Event classes
    */
   public static final String EVENT_UPLINKPORTVLANUNTRUNKEDEVENT =
                                "com.vmware.vc.UplinkPortVlanUntrunkedEvent";
   public static final String EVENT_UPLINKPORTVLANTRUNKEDEVENT =
                                "com.vmware.vc.UplinkPortVlanTrunkedEvent";
   public static final String EVENT_UPLINKPORTMTUNOTSUPPORTEVENT =
                                "com.vmware.vc.UplinkPortMtuNotSupportEvent";
   public static final String EVENT_UPLINKPORTMTUSUPPORTEVENT =
                                "com.vmware.vc.UplinkPortMtuSupportEvent";
   public static final String EVENT_MTUMATCHEVENT =
                                "com.vmware.vc.MtuMatchEvent";
   public static final String EVENT_MTUMISMATCHEVENT =
                                "com.vmware.vc.MtuMismatchEvent";
   public static final String EVENT_TEAMINGMISMATCHEVENT =
                                "com.vmware.vc.TeamingMisMatchEvent";
   public static final String EVENT_TEAMINGMATCHEVENT =
                                "com.vmware.vc.TeamingMatchEvent";

   /*
    * Opaque data key for healthcheck
    */
   public static final String OPAQUE_HEALTHCHECK_VLANCHK_KEY =
                                "com.vmware.vds.vlanmtucheck.param";
   public static final String OPAQUE_HEALTHCHECK_TEAMCHK_KEY =
                                "com.vmware.vds.teamcheck.param";

   /*
    * Constants for the HealthCheck Result classes
    */
   public static final String VMWAREDVSMTUHEALTHCHECKRESULT_CLASS_NAME =
                                "com.vmware.vc.VMwareDVSMtuHealthCheckResult";
   public static final String VMWAREDVSTEAMINGHEALTHCHECKRESULT_CLASS_NAME =
                                "com.vmware.vc.VMwareDVSTeamingHealthCheckResult";
   public static final String VMWAREDVSVLANHEALTHCHECKRESULT_CLASS_NAME =
                                "com.vmware.vc.VMwareDVSVlanHealthCheckResult";

   public static final String DEFAULTHOSTPROXYMAXPORTS =
            "DEFAULTHOSTPROXYMAXPORTS";

   /*
    * Constants for the vDs Version
    */
   public static final String VDS_VERSION_40 = "4.0";
   public static final String VDS_VERSION_41 = "4.1.0";
   public static final String VDS_VERSION_50 = "5.0.0";
   public static final String VDS_VERSION_51 = "5.1.0";
   public static final String VDS_VERSION_55 = "5.5.0";
   public static final String VDS_VERSION_60 = "6.0.0";
   public static final String VDS_VERSION_DEFAULT = DVSTestConstants.
           VDS_VERSION_60;
   /*public static final String VDS_VERSION_DEFAULT = DVSTestConstants.
           VDS_VERSION_55;*/
   public static final String VDS_VERSION = "VDS_VERSION";


   /*
    * Constants for DistributedVirtualSwitchProductSpecOperationType
    */
   public static final String OPERATION_NOTIFYAVAILABLEUPGRADE =  DistributedVirtualSwitchProductSpecOperationType.NOTIFY_AVAILABLE_UPGRADE.value();
   public static final String OPERATION_PREINSTALL =  DistributedVirtualSwitchProductSpecOperationType.PRE_INSTALL.value();
   public static final String OPERATION_PROCEEDWITHUPGRADE = DistributedVirtualSwitchProductSpecOperationType.PROCEED_WITH_UPGRADE.value();
   public static final String OPERATION_UPDATEBUNDLEINFO = DistributedVirtualSwitchProductSpecOperationType.UPDATE_BUNDLE_INFO.value();
   public static final String OPERATION_UPGRADE = DistributedVirtualSwitchProductSpecOperationType.UPGRADE.value();

   /*
    *  Constant for expected exception for checkCompatibility method
    */
   public static final  MethodFault EXPECTED_FAULT_1 = new NotSupported();
   public static final  MethodFault EXPECTED_FAULT_2 = new InvalidArgument();
   public static final  MethodFault EXPECTED_FAULT_3 = new NoCompatibleHost();

   /*
    * Constant for OverlayParameter
    */
   public static final int DEFAULT_OVERLAYPARAMETER_VALUE = 1;

   /*
    * Constant for NetworkResourcePool
    */
   public static final String bnx2_driver = "bnx2";
   public static final String UNSUPPORTED_DRIVERS_NETIORM[] =  new String[]{bnx2_driver};
   public static final String NRP_VM = "virtualMachine";
   public static final String NRP_VMOTION = "vmotion";
   public static final String NRP_ISCSI = "iSCSI";
   public static final String NRP_FT = "faultTolerance";
   public static final String NRP_MGMT = "management";
   public static final String NRP_NFS = "nfs";
   public static final String NRP_VSAN = "vsan";
   public static final String NRP_FCOE = "fcoe";
   public static final String NRP_HBR = "hbr";
   public static final String NRP_KEY = "Net.IOControlPnicOptOut";
   public static final int NRP_NUM_DEFAULT_NETRESPOOLS = 8;

   public static final String AUTOEXPAND_KEY = "config.vpxd.dvs.portgroupAutoExpandSize";

   public static final String NRP_NETDVS_VM = "netsched.pools.persist.vm";
   public static final String NRP_NETDVS_VMOTION = "netsched.pools.persist.vmotion";
   public static final String NRP_NETDVS_ISCSI = "netsched.pools.persist.iscsi";
   public static final String NRP_NETDVS_FT = "netsched.pools.persist.ft";
   public static final String NRP_NETDVS_MGMT = "netsched.pools.persist.mgmt";
   public static final String NRP_NETDVS_NFS = "netsched.pools.persist.nfs";
   public static final String NRP_NETDVS_VSAN = "netsched.pools.persist.vsan";
   public static final String PNICOPTOUT_ADVOPT = "advopt";
   public static final String PNICOPTOUT_HWUNSUPPORTED = "hwUnsupported";
   public static final String VSI_NRP_VM_ID = "netsched.pools.persist.vm";
   public static final String VSI_NRP_VMOTION_ID = "netsched.pools.persist.vmotion";
   public static final String VSI_NRP_ISCSI_ID = "netsched.pools.persist.iscsi";
   public static final String VSI_NRP_FT_ID = "netsched.pools.persist.ft";
   public static final String VSI_NRP_MGMT_ID = "netsched.pools.persist.mgmt";
   public static final String VSI_NRP_NFS_ID = "netsched.pools.persist.nfs";
   public static final String VSI_NRP_VSAN_ID = "netsched.pools.persist.vsan";
   public static final String NRP = "networkResourcePool";
   public static final String NRP_LIMIT_HIGHVAL = "4294967295";
   public static final String NRP_LIMIT_NEGVAL = "-1";
   public static final String NRP_LIMIT = "limit";
   public static final String NRP_SHARESLEVEL_HIGH = "100";
   public static final String NRP_SHARESLEVEL_LOW = "50";
   public static final String NRP_SHARESLEVEL_NORMAL = "10";
   public static final int  NRP_MAX_COUNT = 55;
   public static final String NRP_POOLID = "poolId";
   public static final String NRP_VMKMODULES_DEVS_PATH = "/vmkModules/netsched/hclk/devs/";
   public static final String NRP_VMKMODULES_DEVS_PATH_55 = "/vmkModules/netsched/mclk/devs/";
   public static final String NRP_VMKMODULES_DEVS_PATH_51 = "/vmkModules/netsched/sfq/devs/";
   public static final String NRP_POOLS_PATH = "/qleaves/";
   public static final String NRP_POOLS_PATH_51 = "/pools/";
   public static final String NRP_INVALID_NAME = "!@#$%";
   public static final String NRP_INVALID_KEY = "invalid";
   public static final String NRP_PTAG = "PTag";
   public static final String MAX_NRPS = "MAX_NRPS";
   public static final String NRP_DEFAULT_KEY = "key";
   public static final String NRP_DEFAULT_NAME = "NewNetworkResourcePool";
   public static final String NRP_DEFAULT_DESC = "nrpdesc";
   public static final int NRP_DEFAULT_PTAG = 0;
   public static final long NRP_DEFAULT_LIMIT = -1;
   public static final int NRP_RETURN_VALUE_SIZE_BEFORE_55 = 4;
   public static final int NRP_RETURN_VALUE_SIZE_SINCE_55 = 5;
   public static final int NRP_LIMIT_LOCATION_BEFORE_55 = 2;
   public static final int NRP_LIMIT_LOCATION_SINCE_55 = 3;
   public static final int NRP_SHARESLEVEL_BEFORE_55 = 1;
   public static final int NRP_SHARESLEVEL_SINCE_55 = 2;

   public static final String OLD_VDS_VERSION = "OLD_VDS_VERSION";
   public static final String NEW_VDS_VERSION = "NEW_VDS_VERSION";
   public static final String PRODUCT_SPEC_OPERATION_TYPE = "PRODUCT_SPEC_OPERATION_TYPE";
   public static final String HOST_VERSION = "HOST_VERSION";

   /*
    * Constants for lldp
    */
   public static final String LLDP_OPERATION="operation";
   public static final String LLDP_PROTOCOL="protocol";
   public static final String VDS_NAME="name";
   public static final String LLDP_SRC_OPERATION="srcOperation";
   public static final String LLDP_SRC_PROTOCOL="srcProtocol";

   /*
    * Constants for  IpfixConfig
    */
   public static final String COLLECTORIPADDRESS = "COLLECTORIPADDRESS";
   public static final String ACTIVEFLOWTIMEOUT = "ACTIVEFLOWTIMEOUT";
   public static final String COLLECTORPORT = "COLLECTORPORT";
   public static final String IDLEFLOWTIMEOUT ="IDLEFLOWTIMEOUT";
   public static final String INTERNALFLOWSONLY ="INTERNALFLOWSONLY";
   public static final String SAMPLINGRATE="SAMPLINGRATE";
   public static final String OBSERVATIONDOMAINID="OBSERVATIONDOMAINID";
   public static final String BOOLPOLICY_INHERITED="BoolPolicy.Inherited";

   /*
    * Constants for commands
    */
   public static final String NET_DVS_LIST_COMMAND =
                                               "/usr/lib/vmware/bin/net-dvs -l";

   /*
    * Constant for the name of the file along with the path which stores
    * the host profiles used by the setup and restoration scripts for vds
    */
   public static final String HOST_PROFILES_FILE = "profiles.properties";

   /*
    * Constants for XML tag names in data files related to dvs
    */
   public static final String EXPECTED_METHOD_FAULT="expectedMethodFault";
   public static final String TEST_STEP="step";
   public static final String TEST_FRAMEWORK="testframework";
   public static final String ATTRIB_NAME="name";
   public static final String ATTRIB_GROUP="group";
   public static final String TEST_DATA="data";
   public static final String ATTRIB_TEST_DATA_ID="id";
   public static final String BEAN_DATA="BeanData";
   public static final String TEST_SETUP="testSetup";
   public static final String TEST="test";
   public static final String TEST_CLEANUP="testCleanup";

   public static final String DISABLE_HOST_REBOOT = "DISABLE_HOST_REBOOT";

   public static final long PORT_REFRESH_TIME_PRE_MNHOSTS = 11 * 60 * 1000;
   public static final long PORT_REFRESH_TIME_MNHOSTS = 60 * 1000;
   /*
    * NOTE: STATIC BLOCK SHOULD BE AT THE END OF THIS FILE.
    * ALL TEST CONSTANTS SHOULD BE DEFINED ABOVE THIS STATIC BLOCK
    */

   /*
    * ========= Static Block starts here =============================
    */
   static {
      String checkGuest = System.getProperty("CHECK_GUEST");
      if(checkGuest != null && checkGuest.equalsIgnoreCase("true")) {
         log.info("Enabled checkGuest.");
         CHECK_GUEST = true;
      } else {
         log.info("Disabled checkGuest");
         CHECK_GUEST = false;
      }
   }

      /*
       * ========= Static Block ends here =============================
       */
      /*
       * -------NO TEST CONSTANTS SHOULD BE DEFINED AT THE END OF THIS FILE -------
       */

}


