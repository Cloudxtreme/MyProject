/* ************************************************************************
 *
 * Copyright 2006-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package com.vmware.vcqa;
/**
 * Property Constants encapsulates all the constants defined for
 * ManagedObjectReference object properties.
 */
public class PropertyConstants
{
   /*
    * ========= constructor methods should go here =============================
    */
   private
   PropertyConstants()
   {
   }

   /*
    * ========= public static constants should go here ===========================
    */
   public static final String ALARM_NAME                    = "info.name";
   public static final String VM_NAME_PROPERTYNAME          = "name";
   public static final String VM_CONFIG_PROPERTYNAME        = "config";
   public static final String VM_HARDWARE                   = "config.hardware";
   public static final String VM_HARDWARE_NUMCPU            = "config.hardware.numCPU";
   public static final String VM_HARDWARE_MEMORY_MB         = "config.hardware.memoryMB";
   public static final String VM_CONFIG_CPUALLOCATION_LIMIT = "config.cpuAllocation.limit";

   public static final String VM_CONFIG_CPUALLOCATION_SHARES =
      "config.cpuAllocation.shares.shares";
   public static final String VM_CONFIG_CPUALLOCATION_RESERVATION =
      "config.cpuAllocation.reservation";
   public static final String VM_CONFIG_MEMORYALLOCATION_LIMIT =
      "config.memoryAllocation.limit";
   public static final String VM_CONFIG_MEMORYALLOCATION_SHARES =
      "config.memoryAllocation.shares.shares";
   public static final String VM_CONFIG_MEMORYALLOCATION_RESERVATION =
      "config.memoryAllocation.reservation";

   public static final String VM_TOOLS_CONFIG               = "config.tools";
   public static final String VM_UUID                       = "config.uuid";
   public static final String VM_VERSION                    = "config.version";
   public static final String VM_TEMPLATE                   = "config.template";
   public static final String VM_PATH                       = "config.files.vmPathName";
   public static final String VM_FAULTTOLERANCE_ROLE        = "config.ftInfo.role";
   public static final String VM_RUNTIME_PROPERTYNAME       = "runtime";
   public static final String VM_POWER_STATE                = "runtime.powerState";
   public static final String VM_CONNECTION_STATE           = "runtime.connectionState";
   public static final String VM_HOST                       = "runtime.host";
   public static final String VM_STORAGE_PROPERTYNAME       = "storage";
   public static final String VM_SUMMARY_PROPERTYNAME       = "summary";
   public static final String VM_SUMMARY_CONFIG_NUMETHERNET_CARDS =
      "summary.config.numEthernetCards";

   public static final String VM_RESOURCEPOOL_PROPERTYNAME  = "resourcePool";
   public static final String VM_GUEST_PROPERTYNAME         = "guest";
   public static final String VM_GUEST_DISK                 = "guest.disk";
   public static final String VM_TOOLS_STATUS               = "guest.toolsStatus";
   public static final String VM_TOOLS_VERSION_STATUS       = "guest.toolsVersionStatus";
   public static final String VM_TOOLS_RUNNING_STATUS       = "guest.toolsRunningStatus";
   public static final String VM_GUEST_STATE                = "guest.guestState";
   public static final String VM_GUEST_ID                   = "config.guestId";
   public static final String VM_HEARTBEATSTATUS_PROPERTYNAME  =
      "guestHeartbeatStatus";
   public static final String VM_ENVIRONMENTBROWSWER_PROPERTYNAME  =
      "environmentBrowser";
   public static final String VM_APP_HEARTBEAT_STATUS = "guest.appHeartbeatStatus";
   public static final String VM_CAPABILITY_PROPERTYNAME = "capability";
   public static final String TASK_INFO_PROPERTYNAME        = "info";
   public static final String TASK_INFO_STATE        = "info.state";
   public static final String TASK_INFO_RESULT       = "info.result";
   public static final String TASK_INFO_ERROR        = "info.error";
   public static final String TASK_INFO_ENTITYNAME   = "info.entityName";
   public static final String TASK_INFO_CANCELLED    = "info.cancelled";
   public static final String TASK_INFO_STARTTIME    = "info.startTime";
   public static final String TASK_INFO_COMPTIME     = "info.completeTime";
   public static final String TASK_INFO_KEY          = "info.key";
   public static final String HOST_NAME_PROPERTYNAME="name";
   public static final String HOST_SUMMARY_PROPERTYNAME = "summary";
   public static final String HOST_AUTHENTICATION_MANAGERINFO_PROPERTYNAME = "info";
   public static final String HOST_SUPPORTED_STORE_PROPERTYNAME = "supportedStore";
   public static final String HOST_AUTHENTICATION_STOREINFO_PROPERTYNAME = "info";
   public static final String HOST_AUTHENTICATION__INFO = "host.authenticationmanager.info";
   public static final String HOST_VERSION_PROPERTYNAME="config.product.version";
   public static final String HOST_PRODUCTID_PROPERTYNAME="config.product.productLineId";
   public static final String HOST_OSTYPE_PROPERTYNAME="config.product.osType";
   public static final String HOST_SYSTEMRESOURCES_PROPERTYNAME =
                                    "systemResources";
   public static final String HOST_CAPABILITY_PROPERTYNAME = "capability";
   public static final String HOST_CONFIG_PROPERTYNAME = "config";
   public static final String HOST_CACHECONFIGINFO_PROPERTYNAME = "cacheConfigurationInfo";
   public static final String HOST_CONFIG_FILSYSTEMVOL_MOUNTINFO = "config.fileSystemVolume.mountInfo";
   public static final String HOST_CONFIG_HYPERTHREAD_AVAIL_PROPERTYNAME = "config.hyperThread.available";
   public static final String HOST_IPMI_PROPERTYNAME = "config.ipmi";
   public static final String HOST_CONFIGMANAGER_PROPERTYNAME = "configManager";
   public static final String HOST_NETWORKSYSTEM_PROPERTYNAME = "configManager.networkSystem";
   public static final String HOST_STORAGESYSTEM_PROPERTYNAME = "configManager.storageSystem";
   public static final String HOST_DATASTORESYSTEM_PROPERTYNAME = "configManager.datastoreSystem";
   public static final String HOST_DATASTORE_PROPERTYNAME = "datastore";
   public static final String HOST_NETWORK_PROPERTYNAME = "network";
   public static final String HOST_VM_PROPERTYNAME = "vm";
   public static final String HOST_HYPERTHREAD_PROPERTYNAME = "hyperthreadInfo";
   public static final String HOST_CONSOLE_RESERVATION_PROPERTYNAME =
                                    "consoleReservationInfo";
   public static final String HOST_VIRTUAL_MACHINE_MEMORY_RESERVATION_PROPERTYNAME =
                              "virtualMachineReservationInfo";
   public static final String HOST_HARDWARE_INFO_PROPERTYNAME = "hardware";
   public static final String HOST_CPU_INFO_PROPERTYNAME = "hardware.cpuInfo";
   public static final String HOST_NUM_CPUCORES_PROPERTYNAME = "hardware.cpuInfo.numCpuCores";
   public static final String HOST_CPU_HERTZ_PROPERTYNAME = "hardware.cpuInfo.hz";
   public static final String HOST_MEM_SIZE_PROPERTYNAME = "hardware.memorySize";
   public static final String HOST_PNIC_PROPERTYNAME = "config.network.pnic";

   public static final String HOST_PRODUCT_LINE_PROPERTYNAME = "config.product.productLineId";
   public static final String HOST_PRODUCT_VERSION_PROPERTYNAME = "config.product.version";
   public static final String HOST_RUNTIME_PROPERTYNAME = "runtime";
   public static final String HOST_HEALTHSYSTEM_PROPERTYNAME = "runtime.healthSystemRuntime";
   public static final String HOST_CONNECTSTATE_PROPERTYNAME = "runtime.connectionState";
   public static final String HOST_POWERSTATE_PROPERTYNAME = "runtime.powerState";
   public static final String HOST_MAINTAINENCE_PROPERTYNAME="runtime.inMaintenanceMode";
   public static final String DATASTORE_MAINTENANCE_PROPERTYNAME="summary.maintenanceMode";
   public static final String HOST_DAS_FDM_STATE_PROPERTYNAME="runtime.dasHostState.state";

   public static final String HOST_HOSTACCESSMANAGER_LOCKDOWNMODE="lockdownMode";

   public static final String MANAGEDENTITY_PARENT_PROPERTYNAME =
                                    "parent";
   public static final String MANAGEDENTITY_NAME_PROPERTYNAME = "name";
   public static final String MANAGEDENTITY_CHILDENTITY_PROPERTYNAME =
                                    "childEntity";
   public static final String MANAGEDENTITY_CHILDTYPE_PROPERTYNAME =
                                    "childType";
   public static final String MANAGEDENTITY_OVERALLSTATUS_PROPERTYNAME =
                                    "overallStatus";
   public static final String MANAGEDENTITY_CUSTOMVALUES_PROPERTYNAME =
                                    "customValue";
   public static final String EXTMANAGEDOBJECT_CUSTOMVALUES_PROPERTYNAME =
                                    "value";
   public static final String EXTMANAGEDOBJECT_CUSTOMFIELDDEF_PROPERTYNAME =
                                    "availableField";
   public static final String DATACENTER_DATASTORE_PROPERTYNAME = "datastore";
   public static final String DATACENTER_NETWORK_PROPERTYNAME = "network";
   public static final String DATACENTER_VMFOLDER_PROPERTYNAME = "vmFolder";
   public static final String DATACENTER_HOSTFOLDER_PROPERTYNAME = "hostFolder";
   public static final String DATACENTER_DATASTOREFOLDER_PROPERTYNAME =
                              "datastoreFolder";
   public static final String DATACENTER_NETWORKFOLDER_PROPERTYNAME =
                              "networkFolder";

   public static final String DATACENTER_CUSTOMIZATIONSPECFOLDER_PROPERTYNAME =
                              "customizationSpecRoot";
   public static final String DATASTORE_PROPERTYNAME = "datastore";
   public static final String DATASTORE_SUMMARY_PROPERTYNAME     = "summary";
   public static final String DATASTORE_INFO_PROPERTYNAME        = "info";
   public static final String DATASTORE_CAPABILITY_PROPERTYNAME  = "capability";

   public static final String DSBROWSER_HOST_ENVBROWSER_PROPERTYNAME =
                                    "datastoreBrowser";
   public static final String DSBROWSER_DATASTORE_PROPERTYNAME =
                                    "browser";
   public static final String DATASTORE_VM_PROPERTYNAME          = "vm";
   public static final String DATASTORE_HOST_PROPERTYNAME        = "host";
   public static final String DATASTORE_ACCESSIBLE_PROPERTY      = "summary.accessible";
   public static final String DATASTORE_FREESPACE_PROPERTY       = "summary.freeSpace";
   public static final String DATASTORE_TYPE_PROPERTY            = "summary.type";
   public static final String POD_FREESPACE_PROPERTY             = "summary.freeSpace";
   public static final String RESPOOL_SPECIFICATIONC_PROPERTYNAME= "config";
   public static final String RESPOOL_SUMMARY_PROPERTYNAME       = "summary";
   public static final String STMGR_SCHEDULEDTASK = "scheduledTask";
   public static final String SCHEDULEDTASK_INFO = "info";

   public static final String NETWORK_PROPERTYNAME = "network";
   public static final String NETWORK_VM_PROPERTYNAME = "vm";
   public static final String NETWORK_HOST_PROPERTYNAME = "host";
   public static final String NETWORK_IPCONFIG_PROPERTYNAME = "ipConfig";
   public static final String NETWORK_SUMMARY_PROPERTYNAME = "summary";

   public static final String NWSYSTEM_NWCONFIG = "networkConfig";
   public static final String NWSYSTEM_NWINFO = "networkInfo";
   public static final String NWSYSTEM_DNSCONFIG = "dnsConfig";
   public static final String STORAGESYSTEM_STCONFIG = "storageDeviceInfo";
   public static final String STORAGESYSTEM_MPCONFIG = "multipathStateInfo";
   public static final String DATASTORESYSTEM_DATASTORE = "datastore";

   public static final String VM_SNAPSHOTINFO = "snapshot";

   public static final String COMPRES_RESOURCEPOOL_PROPERTYNAME = "resourcePool";
   public static final String COMPRES_HOST_PROPERTYNAME         = "host";
   public static final String COMPRES_CLUSTER_SPEC              = "configuration";
   public static final String COMPRES_DASCONFIG_ENABLED         = "configuration.dasConfig.enabled";
   public static final String COMPRES_DASCONFIG_FAILOVER_LEVEL  = "configuration.dasConfig.failoverLevel";
   public static final String COMPRES_DASCONFIG_ADM_CTRL_ENABLED = "configuration.dasConfig.admissionControlEnabled";
   public static final String COMPRES_DRSCONFIG_ENABLED         = "configuration.drsConfig.enabled";
   public static final String COMPRES_SPEC                      = "configurationEx";
   public static final String COMPRES_SUMMARY_PROPERTYNAME      = "summary";
   public static final String RESPOOL_OWNER_PROPERTYNAME        = "owner";
   public static final String RESPOOL_CHILDRESSPEC_PROPERTYNAME =
                                                          "childConfiguration";
   public static final String RESPOOL_RESOURCEPOOL_PROPERTYNAME = "resourcePool";
   public static final String RESPOOL_VM_PROPERTYNAME = "vm";
   public static final String VM_SNAPSHOT_CONFIG                = "config";

   public static final String AUTHMGR_ROLES_PROPERTYNAME        = "roleList";
   public static final String AUTHMGR_PRIVILEGES_PROPERTYNAME   = "privilegeList";
   public static final String MANAGEDENTITY_EFFECTIVEROLES_PROPERTYNAME =
                                             "effectiveRole";

   public static final String CUSTOMFIELDMGR_FIELD_PROPERTYNAME = "field";
   public static final String OPTIONMGR_SETTING_PROPERTYNAME = "setting";
   public static final String OPTIONMGR_SUPPORTEDOPTION_PROPERTYNAME =
                                                               "supportedOption";

   public static final String HOSTSNMPSYSTEM_CONFIGURATION_PROPERTYNAME = "configuration";
   public static final String HOSTSNMPSYSTEM_LIMIT_PROPERTYNAME = "limits";

   public static final String COMPRES_ENVIRONMENT   = "environmentBrowser";

   public static final String PERF_HISTINTERVAL        = "historicalInterval";
   public static final String PERF_PERFCOUNTER         = "perfCounter";

   public static final String ALARM_INFO_PROPERTYNAME  = "info";
   public static final String ALARM_DECLARED_STATE     = "declaredAlarmState";

   public static final String DRS_RECOMMENDATION  = "drsRecommendation";
   public static final String RECOMMENDATION  = "recommendation";
   public static final String NETWORK_CAPABILITIES = "capabilities";
   public static final String IORM_CONFIG_INFO  = "iormConfiguration";

   public static final String EVENTMGR_DESCRIPTION = "description";
   public static final String EVENTMGR_LATESTEVENT = "latestEvent";
   public static final String EVENTMGR_MAXCOLLECTOR = "maxCollector";
   public static final String HISTCOL_LATESTPAGE = "latestPage";

   public static final String TASKMGR_DESCRIPTION = "description";

   public static final String MANAGEDENTITY_RECENTTASK = "recentTask";
   public static final String MANAGEDENTITY_PERMISSION = "permission";

   public static final String NETWORK_CONSOLEIPROUTECONFIG =
                                                         "consoleIpRouteConfig";
   public static final String NETWORK_HOSTIPROUTECONFIG = "ipRouteConfig";
   public static final String NETWORK_HOSTIPROUTETABLEINFO =
	   													"networkInfo.routeTableInfo";

   public static final String ACTIVE_USERSESSIONS = "sessionList";
   public static final String SYSTEM_GLOBAL_MESSAGE = "message";
   public static final String VM_RESOURCECONFIG = "resourceConfig";
   public static final String SUPPORTED_LOCALE_LIST = "supportedLocaleList";
   public static final String FOLDER_CHILDTYPE = "childType";

   public static final String CUSTSPECMGR_ENCRYPTIONKEY = "encryptionKey";
   public static final String CUSTSPECMGR_INFO = "info";
   public static final String CUSTOMIZATIONSPEC_INFO = "info";
   public static final String CUSTOMIZATIONSPEC_ITEM = "item";
   public static final String CUSTOMIZATIONSPEC_SPEC = "spec";


   public static final String ENV_BROWSER_DATASTOREBROWSWER = "datastoreBrowser";
   public static final String ENV_BROWSER_QUERY_CFG_OPTION_DESC = "queryConfigOptionDescriptor";

   public static final String VMOTIONSYSTEM_NETCONFIG = "netConfig";
   public static final String VMOTIONSYSTEM_IPCONFIG = "ipConfig";

   public static final String VIRTUALNICMANAGER_INFO = "info";

   public static final String VM_LAYOUT = "layout";
   public static final String VM_LAYOUT_EX = "layoutEx";

   public static final String POD_STORAGE_DRS_ENTRY = "podStorageDrsEntry";
   public static final String ACTIVEPARTITION = "activePartition";
   public static final String STORAGE_FILESYSVOLINFO = "fileSystemVolumeInfo";
   public static final String HOST_SERVICESYSTEM_INFO_PROPERTYNAME = "serviceInfo";
   public static final String HOST_SYSTEM_RESOURCE_INFO ="HostSystemResourceInfo";
   public static final String VIEWMGR_VIEWLIST_PROPERTYNAME = "viewList";
   public static final String VIEW_ENTITYLIST_PROPERTYNAME = "view";
   public static final String EXTENSIONMANAGER_EXTENSION_PROPERTYNAME =
      "extensionList";
   public static final String SESSIONMANAGER_CURRENTTSESSION_PROPERTYNAME =
      "currentSession";
   public static final String DATETIMESYSTEM_DATETIMEINFO="dateTimeInfo";
   public static final String DATETIMESYSTEM_DATETIMEINFO_NTPCONFIG="dateTimeInfo.ntpConfig";
   public static final String DATETIMESYSTEM_DATETIMEINFO_TIMEZONE="dateTimeInfo.timeZone";

   public final static String COMPAT_CHECKMANAGER_NAME="compatManager";
   public final static String DEBUG_MANAGER_NAME="debugManager";
   public final static String FAULTMANAGER_NAME="faultManager";

   public final static String PROP_FILTER_ENTER = "enter";
   public final static String PROP_FILTER_MODIFY = "modify";
   public final static String PROP_FILTER_LEAVE = "leave";

   public static final String DVS_CONFIG_PROPERTY_NAME = "config";
   public static final String DVS_PORTGROUP_PROPERTY_NAME = "portgroup";
   public static final String DVPG_CONFIG_POLICY = "config.policy";
   public static final String DVS_UPLINKPORTGROUP_PROPERTY_NAME =
                                                              "uplinkPortgroup";
   public static final String DVS_CAPABILITY_PROPERTY_NAME = "capability";
   public static final String DVS_IMPLEMENTATION_PROPERTY_NAME =
                                 "implementation";
   public static final String DV_DEFAULT_CONFIG = "config.defaultPortConfig";
   public static final String DV_CONFIG_VERSION = "config.configVersion";
   public static final String DVS_SUMMARY_PROPERTY_NAME = "summary";
   public static final String DVS_VLANID_PROPERTY_NAME = "vlanid";
   public static final String DVS_PORTGROUP_KEY_PROPERTY_NAME = "key";
   public static final String DVS_PORTGROUP_CONFIG__PROPERTY_NAME = "config";
   public static final String DVS_NETWORK_PROPERTY = "network";
   public static final String DVS_PORTGROUP_PORT_KEYS_PROPERTY_NAME = "portKeys";
   public static final String VMWARE_DVS_PVLAN_CONFIG = "pvlanConfig";
   public static final String DVS_PORTGROUP_EFFECTIVE_SETTING_PROPERTY_NAME =
                              "effectiveDefaultPortConfig";
   public static final String MANAGEDENTITY_DISABLED_METHOD_PROPERTYNAME = "disabledMethod";
   public static final String DVS_UPLINKPG_TAG = "SYSTEM/DVS.UPLINKPG";
   public static final String DVS_RUNTIMEINFO_NAME = "runtime";

   public static final String VAPP_CONFIG_PROPERTYNAME = "vAppConfig";
   public static final String VAPP_DATASTORE_PROPERTYNAME = "datastore";
   public static final String VAPP_NETWORK_PROPERTYNAME = "network";
   public static final String FOLDER_IMPORTLEASE_INFO = "info";
   public static final String HTTP_NFC_LEASE_INFO = "info";
   public static final String HTTP_NFC_LEASE_STATE = "state";
   public static final String HTTP_NFC_LEASE_ERROR = "error";

   public static final String VAPP_VIRTUALAPP_PROPERTYNAME = "resourcePool";
   public static final String VAPP_VM_PROPERTYNAME = "vm";

   public static final String VAPP_CHILD_LINK_PROPERTYNAME = "childLink";
   public static final String VAPP_PARENT_VAPP_PROPERTYNAME = "parentVApp";
   public static final String VAPP_PARENT_FOLDER_PROPERTYNAME = "parentFolder";

   public static final String TAG_PROPERTYNAME = "tag";
   public static final String TRIGGEREDALARMSTATE = "triggeredAlarmState";
   public static final String LICENSE_ASSIGNMENT_MGR_PROPERTYNAME = "licenseAssignmentManager";

   public static final String MANAGEDENTITY_CONFIG_STATUS_PROPERTYNAME = "configStatus";
   public static final String MANAGEDENTITY_CONFIG_ISSUE_PROPERTYNAME = "configIssue";

   public static final String PCIPASSTHRUSYSTEM_PASSTHRUINFO = "pciPassthruInfo";
   public static final String ESXAGENTCONFIGINFO_PROPERTYNAME = "configInfo";

   public static final String LOCALIZATIONMANAGER_CATALOG_PROPERTYNAME = "catalog";
   
   public static final String VFLASH_CONFIG_INFO = "vFlashConfigInfo";
   public static final String VSAN_HOST_CONFIGINFO_PROPERTYNAME = "config";
   
   public static final String APP_STATE = "guest.appState";

}
