/* ************************************************************************
*
* Copyright 2013 VMware, Inc.  All rights reserved. -- VMware Confidential
*
* ************************************************************************
*/
package com.vmware.vcqa.vim.dvs.testframework;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.VM_SPC_CREATE_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_SPC_CREATE_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_CREATE_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_CREATE_PASS;

import java.lang.reflect.*;
import java.util.*;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSCreateSpec;
import com.vmware.vc.DVSFeatureCapability;
import com.vmware.vc.DVSKeyedOpaqueData;
import com.vmware.vc.DVSNetworkResourceManagementCapability;
import com.vmware.vc.DVSNetworkResourcePoolConfigSpec;
import com.vmware.vc.DVSOpaqueDataConfigInfo;
import com.vmware.vc.DVSOpaqueDataConfigSpec;
import com.vmware.vc.DVSVmVnicNetworkResourcePool;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigInfo;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.DvsHostInfrastructureTrafficResource;
import com.vmware.vc.DvsResourceRuntimeInfo;
import com.vmware.vc.DvsVmVnicNetworkResourcePoolRuntimeInfo;
import com.vmware.vc.DvsVmVnicResourcePoolConfigSpec;
import com.vmware.vc.DvsVnicAllocatedResource;
import com.vmware.vc.HostPnicNetworkResourceInfo;
import com.vmware.vc.HostProxySwitchConfig;
import com.vmware.vc.HostRuntimeInfo;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.SelectionSet;
import com.vmware.vc.VirtualDevice;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualDeviceConfigSpecOperation;
import com.vmware.vc.VirtualEthernetCard;
import com.vmware.vc.VirtualEthernetCardDistributedVirtualPortBackingInfo;
import com.vmware.vc.VirtualEthernetCardResourceAllocation;
import com.vmware.vc.VirtualMachineConfigInfo;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.LogUtil;
import com.vmware.vcqa.ServiceInfo;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.i18n.I18NDataProvider;
import com.vmware.vcqa.internal.vim.dvs.InternalDistributedVirtualSwitchManager;
import com.vmware.vcqa.internal.vim.dvs.InternalHostDistributedVirtualSwitchManager;
import com.vmware.vcqa.util.NetworkUtil;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.services.ServiceFactory;
import com.vmware.vcqa.util.services.ServiceFactory.OsType;
import com.vmware.vcqa.util.services.VpxServices;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.ServiceInstance;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;
import com.vmware.vcqa.vim.host.VmotionSystem;
import com.vmware.vim.binding.vim.DistributedVirtualSwitch.NetworkResourceControlVersion;
import com.vmware.vcqa.TestBase;

import org.apache.commons.collections.MultiMap;
import org.apache.commons.collections.map.MultiValueMap;
/**
 * This class represents the subsystem for vds related operations.
 *
 * @author sabesanp
 *
 */
public class VDSTestFramework
{

   private DistributedVirtualSwitch vds = null;
   private Folder folder = null;
   private DistributedVirtualPortgroup vdsPortgroup = null;
   //private ManagedObjectReference vdsMor = null;
   private HostSystem host = null;
   private VirtualMachine virtualMachine = null;
   private final SelectionSet[] selectionSet = null;
   private final DVSOpaqueDataConfigSpec[] opaqueDataSpec = null;
   private InternalDistributedVirtualSwitchManager vdsMgr = null;
   private ServiceInstance serviceInstance = null;
   private ManagedObjectReference vdsMgrMor = null;
   private ManagedObjectReference dcMor = null;
   private DataFactory xmlFactory = null;
   private DVSConfigSpec[] dvsConfigSpecArray = null;
   private final List<ManagedObjectReference> vdsMorList = null;
   private final List<ManagedObjectReference> portgroupMorList = null;
   private List<ManagedObjectReference> hostMorList = null;
   private final ManagedObjectReference hostDVSMgrMor = null;
   private final InternalHostDistributedVirtualSwitchManager internalHostDVSMgr =
      null;
   private List<Step> stepList = null;
   private CustomMap customMap = null;
   private final Map<ManagedObjectReference,List<ManagedObjectReference>>
      vdsPortgroupMorMap = null;
   private final Map<ManagedObjectReference,List<String>>
      vdsPortKeyMap = new HashMap<ManagedObjectReference,List<String>>();
   private final Map<ManagedObjectReference,List<String>>
   vdsPortgroupPortKeyMap = new HashMap<ManagedObjectReference,List<String>>();
   private static final Logger log = LoggerFactory.getLogger(
      VDSTestFramework.class);
   private ConnectAnchor connectAnchor = null;
   private final Boolean isRuntime = null;
   private final List<DVSOpaqueDataConfigInfo> dvsOpaqueDataList = null;
   private I18NDataProvider iDataProvider = null;
   private final List<String> keys = null;
   private final List<String> opaqueData = null;
   private final Map<ManagedObjectReference,VirtualMachineConfigSpec>
      vmMorConfigSpecMap = null;
   private final Map<String, ManagedObjectReference> vdsUuidMorMap = null;
   private HashMap<String, ManagedObjectReference> objectIdVdsMorMap =null;
   private HashMap<String,ManagedObjectReference> objectIdVdsPortgroupMorMap =
            null;
   private HashMap<String,DVSVmVnicNetworkResourcePool>
            objectIdVmVnicResPoolMap = null;
   private List<ManagedObjectReference> vmMorList = null;
   private List<ManagedObjectReference> createdVMsMorList = null;
   private Map<ManagedObjectReference,Map<String,String>>
   vmListEthernetCardMap = null;
   private final Long RUNTIME_REFRESH_INTERVAL = 10000L;
   
   private final MultiMap serviceInfoMap = new MultiValueMap();
   
   /**
    * Constructor
    *
    * @param connectAnchor
    * @param xmlFilePath
    *
    * @throws MethodFault, Exception
    */
   public VDSTestFramework(ConnectAnchor connectAnchor,
                                     String xmlFilePath)
      throws Exception
   {
      folder = new Folder(connectAnchor);
      serviceInstance = new ServiceInstance(connectAnchor);
      vdsMgrMor = serviceInstance.getSC().getDvSwitchManager();
      vdsMgr = new InternalDistributedVirtualSwitchManager(connectAnchor);
      vds = new DistributedVirtualSwitch(connectAnchor);
      host = new HostSystem(connectAnchor);
      vdsPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      dcMor = folder.getDataCenter();
      xmlFactory = new DataFactory(xmlFilePath);
      stepList = new ArrayList<Step>();
      this.connectAnchor = connectAnchor;
      iDataProvider = new I18NDataProvider();
      virtualMachine = new VirtualMachine(connectAnchor);
      vmMorList = virtualMachine.getAllVM();
      vmListEthernetCardMap = new HashMap<ManagedObjectReference,
               Map<String,String>>();
   }

   /**
    * This method sets the list of steps
    *
    * @param stepList
    */
   public void setStepsList(List<Step> stepList)
   {
      this.stepList = stepList;
   }

   /**
    * This method checks if the port key passed is in the list of
    * standalone ports in the vds
    *
    * @param vdsMor
    * @param portKey
    *
    * @return boolean
    *
    * @throws Exception
    */
   public boolean isPortInVds(ManagedObjectReference vdsMor,
                              String portKey)
      throws Exception
   {
      boolean isStandAlone = false;
      boolean found = false;
      DistributedVirtualSwitchPortCriteria criteria = new
         DistributedVirtualSwitchPortCriteria();
      List<String> portgroupKeys = new ArrayList<String>();
      List<ManagedObjectReference> pgList = vds.getPortgroup(vdsMor);
      if(pgList != null && pgList.size() >= 1){
         for(ManagedObjectReference pg : pgList){
            portgroupKeys.add(vdsPortgroup.getKey(pg));
         }
      }
      criteria.setInside(false);
      criteria.getPortgroupKey().clear();
      criteria.getPortgroupKey().addAll(com.vmware.vcqa.util.TestUtil.
               arrayToVector(portgroupKeys.toArray(new
               String[portgroupKeys.size()])));
      List<String> portKeys = vds.fetchPortKeys(vdsMor, criteria);
      if(portKeys != null && portKeys.size() >= 1 ){
         for(String pKey : portKeys){
            if(pKey.equals(portKey)){
               isStandAlone = true;
               break;
            }
         }
      }
      return isStandAlone;
   }

   /**
    * This method returns the vds handler to the calling code
    *
    * @return DistributedVirtualSwitch
    */
   public DistributedVirtualSwitch getVdsHandler(){
      return this.vds;
   }

   /**
    * This method returns an array of data existing which excludes the data
    * present in the inherited list
    *
    * @param existingData
    * @param inheritedOpaqueData
    *
    * @return DVSKeyedOpaqueData[]
    *
    * @throws Exception
    */
   public DVSKeyedOpaqueData[] getExistingData(DVSKeyedOpaqueData[]
                                               existingData,
                                               DVSKeyedOpaqueData[]
                                               inheritedOpaqueData)
      throws Exception
   {
      List<DVSKeyedOpaqueData> existingDataList = new
               ArrayList<DVSKeyedOpaqueData>();
      if(existingData != null && existingData.length > 0){
         for(DVSKeyedOpaqueData keyedOpaqueData : existingData){
            boolean found = false;
            for(DVSKeyedOpaqueData kod : inheritedOpaqueData){
               if(kod.getKey().equals(keyedOpaqueData.getKey())){
                  found = true;
                  break;
               }
            }
            if(!found){
               existingDataList.add(keyedOpaqueData);
            }
         }
      }
      return existingDataList.toArray(new
               DVSKeyedOpaqueData[existingDataList.size()]);
   }

   /**
    * This method creates the vds
    *
    * @throws Exception
    */
   public void createVds()
      throws Exception
   {
      //init("createVds");
      List<String> objIdList = getStep("createVds").getData();
      if(this.objectIdVdsMorMap == null){
         this.objectIdVdsMorMap = new HashMap<String,ManagedObjectReference>();
      }
      if(objIdList == null){
         throw new Exception("There is no data provided for creating the vds");
      } else{
         /*
          * Iterate through the list of objects and build a map of the
          * object id and the mor
          */
         for(String objId : objIdList){
            Object obj = this.xmlFactory.getData(objId);
            ManagedObjectReference dvsMor = null;
            if(obj instanceof String){
               this.dcMor = folder.getDataCenter((String) obj);
            }
            if(obj instanceof DVSConfigSpec){
               DVSConfigSpec spec = (DVSConfigSpec)obj;
               dvsMor = folder.createDistributedVirtualSwitch(folder.
                        getNetworkFolder(dcMor), spec);
               this.objectIdVdsMorMap.put(objId, dvsMor);
            }
            if(obj instanceof DVSCreateSpec){
               DVSCreateSpec createSpec =(DVSCreateSpec)obj;
               //DVSUtil.getProductSpec(dvsMor, connectAnchor);
               createSpec.setProductInfo(DVSUtil.getProductSpec(connectAnchor,
                        createSpec.getProductInfo().getVersion()));
               dvsMor = folder.createDistributedVirtualSwitch(folder.
                        getNetworkFolder(dcMor), createSpec);
               this.objectIdVdsMorMap.put(objId, dvsMor);
            }
         }
      }
      /*
      vdsMorList = new ArrayList<ManagedObjectReference>();
      vdsUuidMorMap = new HashMap<String,ManagedObjectReference>();
      if(dvsConfigSpecArray != null){
         for(DVSConfigSpec dvsConfigSpec : dvsConfigSpecArray){
            vdsMor = folder.createDistributedVirtualSwitch(folder.
               getNetworkFolder(dcMor), dvsConfigSpec);
            assertNotNull(vdsMor, "Failed to create a virtual distributed " +
               "switch");
            vdsMorList.add(this.vdsMor);
            vdsUuidMorMap.put(vds.getConfig(vdsMor).getUuid(),vdsMor);
         }
      }
      if(vdsMorList != null && vdsMorList.size() >=1){
         populateVdsPortKeyMap();
      }*/
   }

   /**
    * This method returns a map of the object id and the vds mor
    *
    * @return Map<String,ManagedObjectReference>
    *
    * @throws Exception
    */
   public Map<String, ManagedObjectReference> getObjectIdVdsMorMap()
      throws Exception
   {
      return this.objectIdVdsMorMap;
   }

   /**
    * This method returns a map of the object id and the vds portgroup mor
    *
    * @return Map<String,ManagedObjectReference>
    *
    * @throws Exception
    */
   public Map<String, ManagedObjectReference> getObjectIdVdsPortgroupMorMap()
      throws Exception
   {
      return this.objectIdVdsPortgroupMorMap;
   }

   /**
    * This method return the vds mor associate to the object id
    *
    * @param objId
    *
    * @return ManagedObjectReference
    */
   public ManagedObjectReference getVdsMor(String objId)
   {
      return this.objectIdVdsMorMap.get(objId);
   }
   /**
    * This method return the vds portgroup mor associate to with the object id
    *
    * @param objId
    *
    * @return ManagedObjectReference
    */
   public ManagedObjectReference getVdsPortgroupMor(String objId)
   {
         return this.objectIdVdsPortgroupMorMap.get(objId);
   }

   /**
    * This method calculates the map between the vds and the port keys
    *
    * @throws Exception
    */
   public void populateVdsPortKeyMap()
      throws Exception
   {
      for(ManagedObjectReference vdsMor : this.vdsMorList){
         if(!this.vdsPortKeyMap.containsKey(vdsMor)){
            this.vdsPortKeyMap.put(vdsMor,  vds.fetchPortKeys(vdsMor,
               vds.getPortCriteria(null, null, null, null, null, null)));
         }
      }
   }

   /**
    * This method calculates the map between the vds and the portgroup keys
    *
    * @throws Exception
    */
   public void populatePortgroupKeyMap()
      throws Exception
   {
      for(ManagedObjectReference pgMor : this.portgroupMorList){
         if(!this.vdsPortgroupPortKeyMap.containsKey(pgMor)){
            this.vdsPortgroupPortKeyMap.put(pgMor,vdsPortgroup.
               getPortKeys(pgMor));
         }
      }
   }

   /**
    * This method reconfigures the vds using the spec provided
    *
    * @throws Exception
    */
   public void reconfigureVds()
      throws Exception
   {
      List<String> objIdList = getStep("reconfigureVds").getData();
      ManagedObjectReference vdsMor = null;
      DVSConfigSpec reconfigSpec = null;
      CustomMap vdsMap = null;
      String objectId = null;
      if(objIdList == null || objIdList.isEmpty() || objIdList.size() < 2){
         throw new Exception("No data provided for reconfigureVds method");
      }
      for(String objId : objIdList){
         Object obj = this.xmlFactory.getData(objId);
         if(obj instanceof DVSConfigSpec){
            reconfigSpec = (DVSConfigSpec)obj;
            objectId = objId;
         }
         if(obj instanceof CustomMap){
            vdsMap = (CustomMap)obj;
         }
      }
      vdsMor = this.objectIdVdsMorMap.get(vdsMap.getObjectIdMap().
                                          get(objectId));
      reconfigSpec.setConfigVersion(vds.getConfigVersion(vdsMor));
      this.vds.reconfigure(vdsMor, reconfigSpec);
   }

   /**
    * This method checks whether the NIOC feature available bandwidth
    * for vm traffic for vds version 6.0
    *
    * @throws Exception
    */
   public void checkAvailableBandwidthForVMTraffic()
      throws Exception
   {
       List<String> objIdList = getStep("checkAvailableBandwidthForVMTraffic").getData();
       if(objIdList == null || objIdList.isEmpty()){
           throw new Exception("No data provided for checkAvailableBandwidthForVMTraffic method");
        }

       long expectBand = 0L;
       DVSConfigSpec reconfigSpec = null;
       for(String objId : objIdList){
          Object obj = this.xmlFactory.getData(objId);
          if(obj instanceof DVSConfigSpec){
             reconfigSpec = (DVSConfigSpec)obj;
          }
       }

       List<DvsHostInfrastructureTrafficResource> infrastructures =
          reconfigSpec.getInfrastructureTrafficResourceConfig();
       for (DvsHostInfrastructureTrafficResource infra : infrastructures) {
           if (infra.getKey().equals("virtualMachine")) {
               expectBand = infra.getAllocationInfo().getReservation();
               break;
           }
       }

       assertTrue(
           (this.hostMorList != null && this.hostMorList.size() >= 1),
           "Found at least one host in the inventory",
           "Failed to find a host in the inventory");
       Thread.sleep(RUNTIME_REFRESH_INTERVAL);
       HostRuntimeInfo info = this.host.getHostRuntime(this.hostMorList.get(0));
       List<HostPnicNetworkResourceInfo> pnicResourceInfo =
          info.getNetworkRuntimeInfo().getNetworkResourceRuntime().
                                 getPnicResourceInfo();
       long actualBand = pnicResourceInfo.get(0).getAvailableBandwidthForVMTraffic();
       assertTrue(expectBand == actualBand, "available bandwidth for vm traffic correct",
           "avaiable bandwidth for vm traffic mismatch");

   }

   /**
    * This method checks whether the NIOC feature capability is set to false
    * for vds version 6.0
    *
    * @throws Exception
    */
   public void checkNoNiocV3Flag()
       throws Exception
   {
       List<String> objIdList = getStep("checkNoNiocv3Flag").getData();
       if(objIdList == null || objIdList.isEmpty()){
          throw new Exception("No data provided for " +
                "checkNiocv3Flag method");
       }
       boolean isNiocv3Flag = isNiocv3Flag(objIdList);
       String version = DVSUtil.getvDsVersion();
       assertTrue(!isNiocv3Flag, "The netioc v3 " +
             "feature is disabled on vds version : " + version +
             " vds","The netioc v3 flag is enabled on vds " +
             "version : " + version + " vds");

   }

   /**
    * This method checks whether the NIOC feature capability is set to true
    * for vds version 6.0
    *
    * @throws Exception
    */
   public void checkNiocv3Flag()
      throws Exception
   {
      List<String> objIdList = getStep("checkNiocv3Flag").getData();
      if(objIdList == null || objIdList.isEmpty()){
         throw new Exception("No data provided for " +
               "checkNiocv3Flag method");
      }
      boolean isNiocv3Flag = isNiocv3Flag(objIdList);
      String version = DVSUtil.getvDsVersion();
      if (DVSUtil.getvDsVersion().compareTo(DVSTestConstants.VDS_VERSION_60) >= 0) {
          assertTrue(isNiocv3Flag, "The netioc v3 " +
                "feature is enabled on vds version : " + version +
                " vds","The netioc v3 flag is not enabled on vds " +
                "version : " + version + " vds");
       } else {
          assertTrue(!isNiocv3Flag, "The netioc v3 flag is not " +
                "supported on " + version + " vds","The netioc v3 " +
                      "flag is supported on " + version + " vds");
       }
   }

   /**
    * This method checks the netioc V3 feature flag
    * @param objIdList
    * @throws Exception
    */
   private boolean isNiocv3Flag(List<String> objIdList)
       throws Exception
   {
       ManagedObjectReference vdsMor = null;
       boolean isNetIocV3Supported = false;
       for(String objId : objIdList){
          if(this.objectIdVdsMorMap.get(objId) != null){
             vdsMor = this.objectIdVdsMorMap.get(objId);
             DVSFeatureCapability featureCapability = vdsMgr.
                      queryDvsFeatureCapability(this.vdsMgrMor,
                      DVSUtil.getProductSpec(vdsMor, connectAnchor));
             DVSNetworkResourceManagementCapability resMgmtCapability =
                      featureCapability.
                      getNetworkResourceManagementCapability();
             LogUtil.printObject(resMgmtCapability);
             assertNotNull(resMgmtCapability.
                      isNetworkResourceControlVersion3Supported(),"The " +
                      "network io version 3 supported flag is not null",
                      "The network io version 3 supported flag is null");
             isNetIocV3Supported = resMgmtCapability.
                      isNetworkResourceControlVersion3Supported();
             return isNetIocV3Supported;

          }
       }
       return isNetIocV3Supported;
   }
   /**
    * This method verifies all the host infrastructure traffic resource
    * configurations as set in the reconfigure spec
    *
    * @throws Exception
    */
   public void verifyHostInfrastructureTrafficResourceConfig()
      throws Exception
   {
      List<String> objIdList =
               getStep("verifyHostInfrastructureTrafficResourceConfig").
               getData();
      if(objIdList == null || objIdList.isEmpty() || objIdList.size() < 2){
         throw new Exception("No data provided for " +
               "verifyHostInfrastructureTrafficResourceConfig method");
      }
      DVSConfigSpec reconfigSpec = null;
      String objectId = null;
      CustomMap vdsMap = null;
      ManagedObjectReference vdsMor = null;
      for(String objId : objIdList){
         if(this.objectIdVdsMorMap.get(objId) != null){
            vdsMor = objectIdVdsMorMap.get(objId);
            continue;
         }
         Object obj = this.xmlFactory.getData(objId);
         if(obj instanceof DVSConfigSpec){
            reconfigSpec = (DVSConfigSpec)obj;
            objectId = objId;
         }
         if(obj instanceof CustomMap){
            vdsMap = (CustomMap)obj;
         }
      }
      vdsMor = this.objectIdVdsMorMap.get(vdsMap.getObjectIdMap().
                                          get(objectId));
      List<DvsHostInfrastructureTrafficResource> actualHostInfTrafficResList =
               vds.getConfig(vdsMor).getInfrastructureTrafficResourceConfig();
      for(DvsHostInfrastructureTrafficResource expectedHostInf : reconfigSpec.
               getInfrastructureTrafficResourceConfig()){
         String key = expectedHostInf.getKey();
         for(DvsHostInfrastructureTrafficResource actualHostInf :
            actualHostInfTrafficResList){
            if(key.equals(actualHostInf.getKey())){
               Vector<String> ignorePropList = TestUtil.
                        getIgnorePropertyList(expectedHostInf, false);
               log.info("Actual reservation : " + actualHostInf.
                        getAllocationInfo().getReservation());
               log.info("Actual shares : " + actualHostInf.
                        getAllocationInfo().getShares().getShares());
               log.info("Actual limit : " + actualHostInf.getAllocationInfo().
                        getLimit());
               assertTrue(TestUtil.compareObject(actualHostInf, expectedHostInf,
                        ignorePropList, true),"Expected and actual dvs " +
                        "host infrastructure pool values for key => " + key +
                        " matches","Expected and actual dvs host " +
                        "infrastructure pool values for key => " + key +
                        " does not match");
            }
         }
      }
   }

   /**
    * This method reconfigures the vmvnic network resource pool on a vds
    *
    * @throws Exception
    */
   public void reconfigureVmVnicNetworkResourcePool()
      throws Exception
   {
      List<String> objIdList = getStep("reconfigureVmVnicNetworkResourcePool").
               getData();
      ManagedObjectReference vdsMor = null;
      ArrayList<DvsVmVnicResourcePoolConfigSpec> resPoolSpecList = new
               ArrayList<DvsVmVnicResourcePoolConfigSpec>();
      for(String objId : objIdList){
         if(this.objectIdVdsMorMap.get(objId) != null){
            vdsMor = objectIdVdsMorMap.get(objId);
         }
         Object obj = this.xmlFactory.getData(objId);
         if(obj instanceof DvsVmVnicResourcePoolConfigSpec){
            resPoolSpecList.add((DvsVmVnicResourcePoolConfigSpec)obj);
         }
         if(obj instanceof CustomMap){
            this.customMap = (CustomMap)obj;
            Map<String,String> objectIdMap = this.customMap.getObjectIdMap();
            /*
             * Get the corresponding objects for the keys in the map
             */
            for(String key : objectIdMap.keySet()){
               Object targetObj = this.xmlFactory.getData(key);
               DvsVmVnicResourcePoolConfigSpec targetSpec =
                        (DvsVmVnicResourcePoolConfigSpec) targetObj;
               Object sourceObj = this.xmlFactory.getData(objectIdMap.get(key));
               DvsVmVnicResourcePoolConfigSpec sourceSpec =
                        (DvsVmVnicResourcePoolConfigSpec)sourceObj;
               DVSVmVnicNetworkResourcePool resPool = vds.
                        getVmVnicNetworkResourcePool(vdsMor,
                        sourceSpec.getName());
               targetSpec.setKey(resPool.getKey());
               targetSpec.setName(resPool.getName());
               targetSpec.setConfigVersion(resPool.getConfigVersion());
               resPoolSpecList.add(targetSpec);
            }
         }
      }
      List<DVSVmVnicNetworkResourcePool> oldNetworkResPoolList = vds.
               getAllVmVnicNetworkResourcePool(vdsMor);
      vds.reconfigureVmVnicNetworkResourcePool(vdsMor, resPoolSpecList);
      int countRemove = countOperations(resPoolSpecList,
               TestConstants.HOSTCONFIG_CHANGEOPERATION_REMOVE);
      int countAdd = countOperations(resPoolSpecList,
               TestConstants.HOSTCONFIG_CHANGEOPERATION_ADD);
      int expectedCount = oldNetworkResPoolList.size() + countAdd -
               countRemove;
      log.info("The expected number of vmvnic resource pools : " +
               expectedCount);
      /*
       * Get all vmvnic resource pools on the vds
       */
      List<DVSVmVnicNetworkResourcePool> networkResPoolList = vds.
               getAllVmVnicNetworkResourcePool(vdsMor);
      assertTrue(expectedCount == networkResPoolList.size(),"The expected " +
            "number of vmvnic resource pools were found on the vds","The " +
            "expected number of vmvnic resource pools were not found on the " +
            "vds");
      /*
       * Verify that the network resource pool values are the same
       */
      boolean isEqual = true;
      for(DvsVmVnicResourcePoolConfigSpec spec : resPoolSpecList){
         DVSVmVnicNetworkResourcePool pool = null;
         String objectId = null;
         objectId = getObjectId(spec, objIdList);
         if(spec.getOperation().equals(TestConstants.
                  HOSTCONFIG_CHANGEOPERATION_ADD)){
            pool = vds.getVmVnicNetworkResourcePool(vdsMor, spec.getName());
            if(this.objectIdVmVnicResPoolMap == null){
               this.objectIdVmVnicResPoolMap = new HashMap<String,
                        DVSVmVnicNetworkResourcePool>();
            }
            if(objectId != null){
               this.objectIdVmVnicResPoolMap.put(objectId, pool);
            }
            assertNotNull(pool, "Successfully found the pool with name : " +
                     spec.getName());
            LogUtil.printObject(pool);
            assertTrue(verifyNetworkResourcePoolParams(spec, pool),
                     "The vmvnic resource pool " + spec.getName() +
                     "has all its properties set","The vmvnic resource pool " +
                     spec.getName() + "does not have all properties set");
         } else {
            pool = vds.getVmVnicNetworkResourcePoolFromKey(vdsMor,
                     spec.getKey());
            if(spec.getOperation().equals(TestConstants.
                     HOSTCONFIG_CHANGEOPERATION_REMOVE)){
               assertNull(pool,"The vmvnic resource pool that was removed" +
                     " was not found on the vds","The vmvnic resource " +
                           "pool that was removed was found on the vds");
            } else if(spec.getOperation().equals(TestConstants.
                     HOSTCONFIG_CHANGEOPERATION_EDIT)){
               LogUtil.printObject(pool);
               if(objectId != null){
                  this.objectIdVmVnicResPoolMap.put(objectId, pool);
               }
               assertNotNull(pool, "Successfully found the pool with name : " +
                        spec.getName());
               assertTrue(verifyNetworkResourcePoolParams(spec, pool),
                        "The vmvnic resource pool " + spec.getName() +
                        "has all its properties set",
                        "The vmvnic resource pool " +
                        spec.getName() + "does not have all properties set");
            }
         }
      }
   }


   /**
    * This method returns VM reservation infrastructure traffic
    * info(DVS runtime capacity) defined
    * in DVSConfigSpec for VDS 6.0.
    *
    * @param reconfigSpec The configuration Spec for reconfgigure option
    * @return long
    * @throws Exception
    */
    private long getDvsResourceRuntimeCapacityConfig(DVSConfigSpec reconfigSpec){
        long capacityConfig = 0L;
        List<DvsHostInfrastructureTrafficResource> infraTrafficResList =
                reconfigSpec.getInfrastructureTrafficResourceConfig();
        for (DvsHostInfrastructureTrafficResource
           infraTrafficRes : infraTrafficResList) {
            if (infraTrafficRes.getKey().equals("virtualMachine")) {
                capacityConfig = infraTrafficRes.getAllocationInfo().getReservation();
            }
        }
        return capacityConfig;
    }

   /**
    * This method returns DVS resource usage info defined
    * in DvsVmVnicResourcePoolConfigSpec for VDS 6.0
    *
    * @param resPoolSpecList List of resource pool config specs
    * @param notAssociatedResPoolPgMorList List of port group Mors
    *        which don't associate to any resource pool.
    * @return List
    * @throws Exception
    */
    private long getDvsResourceRuntimeUsageConfig(
        List<DvsVmVnicResourcePoolConfigSpec> resPoolSpecList,
        List<ManagedObjectReference> notAssociatedResPoolPgMorList) throws Exception{
       /*
        * DvsResource runtime usage include 2 part: 1st part is the resource allocated
        * to resource pool; 2nd part is resource allocated to vmVnic whose port group
        * doesn't associate to any resource pool.
        *
        */
       Long usageConfig = null;
       //Fist get the resource allocated to resource pool
       for(DvsVmVnicResourcePoolConfigSpec spec : resPoolSpecList){
           usageConfig = addNewResToSum(spec.getAllocationInfo().
                            getReservationQuota(), usageConfig);
       }
       //Then get the resource allocated to vmVnic whose port group
       //doesn't associate to any resource pool.
       if(notAssociatedResPoolPgMorList!=null && notAssociatedResPoolPgMorList.size()!=0)
       {
           //handle each port group 1 by 1
           for(ManagedObjectReference pgMor : notAssociatedResPoolPgMorList){
               //get the vmVnic list of port group
               List<VirtualEthernetCard> vCardList = getPortgroupConnectedvCardList(pgMor);
               if(vCardList != null){
                   for(VirtualEthernetCard card : vCardList){
                       usageConfig = addNewResToSum(
                           card.getResourceAllocation().getReservation(), usageConfig);
                   }
               }
           }
       }
       return usageConfig;
    }

 /**
 *
 * This method return the list of virtual ethernet card which
 * connect to specified port group
 *
 * @param pgMor
 * @return List<VirtualEthernetCard>
 * @throws Exception
 */
private List<VirtualEthernetCard> getPortgroupConnectedvCardList(
    ManagedObjectReference pgMor) throws Exception
{
    ArrayList<VirtualEthernetCard> vCardList = new ArrayList<VirtualEthernetCard>();
    VirtualEthernetCard connectedVCard = null;
    List<DistributedVirtualPort> portList = vdsPortgroup.getPorts(pgMor);
    for(DistributedVirtualPort port : portList){
        if(port.getConnectee() != null){
            //Get the vmVnic the port connected to
            connectedVCard = getPortConnectedEthernetCard(port);
            vCardList.add(connectedVCard);
        }
    }
    return vCardList;
}

/**
 *
 * This method return the virtual ethernet card the specified
 * port connected to.
 *
 * @param port
 * @return VirtualEthernetCard
 * @throws Exception
 */
private VirtualEthernetCard getPortConnectedEthernetCard(
    DistributedVirtualPort port) throws Exception
{
    if("vmVnic".equals(port.getConnectee().getType())){
        int nicKey =Integer.parseInt(port.getConnectee().getNicKey());
        ManagedObjectReference vmMor = port.getConnectee().getConnectedEntity();
        //Skip if VM's status is power off
        if (!virtualMachine.getVMState(vmMor).equals(
            VirtualMachinePowerState.POWERED_OFF)){
            VirtualMachineConfigInfo vmConfigInfo = this.virtualMachine.getConfigInfo(vmMor);
            List<VirtualDevice> vdList = vmConfigInfo.getHardware().getDevice();
            if(vdList!=null){
                //Hanlde vnics of the vm one by one
                for (VirtualDevice vd : vdList) {
                    if (vd != null && vd instanceof VirtualEthernetCard) {
                        VirtualEthernetCard vEthernetCard = (VirtualEthernetCard) vd;
                        if(vEthernetCard.getKey() == nicKey){
                            return vEthernetCard;
                        }
                    }
                }

            }
        }
    }
    return null;
}

   /**
    * This method verifies whether the DVS runtime capacity
    * match with the value in configure
    * spec for DVS version 6.0
    *
    * @param reconfigSpec The configuration Spec for reconfgigure option
    * @param resRuntimeInfo Resource runtime info of the DVS to be verified
    * @throws Exception
    */
    private void verifyDvsResourceRuntimeCapacity(DVSConfigSpec reconfigSpec,
                                                  DvsResourceRuntimeInfo resRuntimeInfo){
       long expectedDvsCapacity = getDvsResourceRuntimeCapacityConfig(reconfigSpec);
       long actualDvsCapacity = resRuntimeInfo.getCapacity().longValue();
       assertTrue(expectedDvsCapacity == actualDvsCapacity,
          "DVS Resource Runtime Capacity is correct",
          "DVS Resource Runtime Capacity is not correct");
    }

   /**
    * This method verifies whether the DVS runtime Usage
    * match with the value in configure
    * spec for DVS version 6.0
    * @param resPoolSpecList List of resource pool config specs
    * @param notAssociatedResPoolPgMorList List of port group Mors
    *        which don't associate to any resource pool.
    *
    * @throws Exception
    */
    private void verifyDvsResourceRuntimeUsage(
                    List<DvsVmVnicResourcePoolConfigSpec> resPoolSpecList,
                    List<ManagedObjectReference> notAssociatedResPoolPgMorList,
                    DvsResourceRuntimeInfo resRuntimeInfo) throws Exception{
        long expectedDvsUsage = getDvsResourceRuntimeUsageConfig(
                                   resPoolSpecList, notAssociatedResPoolPgMorList);
        long actualDvsUsage =  resRuntimeInfo.getUsage().longValue();
        assertTrue(expectedDvsUsage == actualDvsUsage, "DVS Resource Runtime Usage is correct",
            "DVS Resource Runtime Usage is not correct");

    }

   /**
    * This method verifies whether the DVS runtime Usage
    * match with the value in configure
    * spec for DVS version 6.0
    *
    * @param resPoolSpecList List of resource pool config specs
    * @param notAssociatedResPoolPgMorList List of port group Mors
    *        which don't associate to any resource pool.
    * @throws Exception
    */
    private void verifyDvsResourceRuntimeAvailable(
                    DVSConfigSpec reconfigSpec,
                    List<DvsVmVnicResourcePoolConfigSpec> resPoolSpecList,
                    List<ManagedObjectReference> notAssociatedResPoolPgMorList,
                    DvsResourceRuntimeInfo resRuntimeInfo) throws Exception{
       long expectedDVSAvailable = getDvsResourceRuntimeCapacityConfig(reconfigSpec) -
           getDvsResourceRuntimeUsageConfig(resPoolSpecList, notAssociatedResPoolPgMorList);
       long actualDVSAvailable =  resRuntimeInfo.getAvailable().longValue();
       assertTrue(expectedDVSAvailable == actualDVSAvailable,
          "DVS Resource Runtime Available is correct",
          "DVS Resource Runtime Available is not correct");
    }

   /**
    * This method verifies whether the Resource Pool Runtime
    * capacity match with the value in configure
    * spec for DVS version 6.0
    *
    * @param resPoolSpecList List of resource pool config specs
    * @param resRuntimeInfo Resource runtime info of the DVS to be verified
    * @throws Exception
    */
    private void verifyResourcePoolRuntimeCapacity(
                    List<DvsVmVnicResourcePoolConfigSpec> resPoolSpecList,
                    DvsResourceRuntimeInfo resRuntimeInfo) throws Exception{
       long expectPoolCapacity = 0L;
       long actualPoolCapacity = 0L;
       List<DvsVmVnicNetworkResourcePoolRuntimeInfo> resPoolRuntimeList =
           resRuntimeInfo.getVmVnicNetworkResourcePoolRuntime();
       if(resPoolSpecList != null){
           for(DvsVmVnicResourcePoolConfigSpec spec : resPoolSpecList){
               expectPoolCapacity = spec.getAllocationInfo().getReservationQuota().longValue();
               for(DvsVmVnicNetworkResourcePoolRuntimeInfo info : resPoolRuntimeList){
                   if( info.getName().equals(spec.getName()) ){
                       actualPoolCapacity = info.getCapacity().longValue();
                       assertTrue(actualPoolCapacity == expectPoolCapacity,
                           "Capacity for resource pool:" + spec.getName() + " is correct",
                           "Capacity for resource pool:" + spec.getName() + " is not correct");
                   }
               }
           }
       } else {
          throw new Exception("No configure specification data provided for " +
                              "verifyResourcePoolRuntimeCapacity method");
       }
    }

   /**
    * This method verifies whether the ResourceRuntimeInfo
    * match with the value in configure
    * spec for DVS version 6.0
    *
    * @throws Exception
    */
   public void verifyResourceRuntimeInfo()
      throws Exception
   {
       List<String> objIdList = getStep("verifyResourceRuntimeInfo").getData();
       if(objIdList == null || objIdList.isEmpty()){
           throw new Exception("No data provided for verifyResourceRuntimeInfo method");
       }
       ManagedObjectReference vdsMor = null;
       DVSConfigSpec reconfigSpec = null;
       ArrayList<DvsVmVnicResourcePoolConfigSpec> resPoolSpecList =
                new ArrayList<DvsVmVnicResourcePoolConfigSpec>();
       ArrayList<VirtualEthernetCardResourceAllocation> vnicResAllocList =
                new ArrayList<VirtualEthernetCardResourceAllocation>();
       /*
        * We need to get the port groups list which were not associated
        * to resource pool in spec to calculate allocated resource and
        * usage later.
        */
       ArrayList<ManagedObjectReference> notConnectDvpgMorList =
           new ArrayList<ManagedObjectReference>();
       ManagedObjectReference pgMor = null;
       String objectId = null;
       String pgName = null;

       for(String objId : objIdList){
           if(this.objectIdVdsMorMap.get(objId) != null){
               vdsMor = objectIdVdsMorMap.get(objId);
           }
           Object obj = this.xmlFactory.getData(objId);
           if(obj instanceof DVSConfigSpec){
               reconfigSpec = (DVSConfigSpec)obj;
               objectId = objId;
            } else if(obj instanceof DvsVmVnicResourcePoolConfigSpec){
               resPoolSpecList.add((DvsVmVnicResourcePoolConfigSpec)obj);
            } else if (obj instanceof VirtualEthernetCardResourceAllocation) {
                vnicResAllocList.add((VirtualEthernetCardResourceAllocation)obj);
            } else if(obj instanceof DVPortgroupConfigSpec){
                DVPortgroupConfigSpec dvpgConfigSpec = (DVPortgroupConfigSpec)obj;
                /*
                 * if the VmVnicNetworkResourcePoolKey is 1, then the port
                 * group doesn't connect to a resource pool.
                 */
                if(dvpgConfigSpec.getVmVnicNetworkResourcePoolKey().
                                  equals("-1".toString())){
                    //Find the portgroup by name
                    for(String pgKey : this.objectIdVdsPortgroupMorMap.keySet()){
                        pgMor = this.objectIdVdsPortgroupMorMap.get(pgKey);
                        pgName = this.vdsPortgroup.getName(pgMor);
                        if(pgName.equals(dvpgConfigSpec.getName()))
                        {
                            notConnectDvpgMorList.add(pgMor);
                        }
                    }
                }
            }
       }

      //If DVSConfigSpec data provided, then verify ResourceRuntimeInfo
      if(reconfigSpec != null){
    	  //Thread.sleep(60000);
          DvsResourceRuntimeInfo resRuntimeInfo = vds.getRuntimeInfo(vdsMor).getResourceRuntimeInfo();
          verifyDvsResourceRuntimeCapacity(reconfigSpec, resRuntimeInfo);
          /* If DvsVmVnicResourcePoolConfigSpec data also provided,
           * then verify DVS Usage and DVS Available info and Pool
           * Capacity info
           */
          if(resPoolSpecList!= null && resPoolSpecList.size() != 0){
              verifyDvsResourceRuntimeUsage(resPoolSpecList,
                  notConnectDvpgMorList,resRuntimeInfo);
              verifyDvsResourceRuntimeAvailable(reconfigSpec, resPoolSpecList,
                  notConnectDvpgMorList, resRuntimeInfo);
              verifyResourcePoolRuntimeCapacity(resPoolSpecList,resRuntimeInfo);
          } else {
              assertTrue(resRuntimeInfo.getVmVnicNetworkResourcePoolRuntime().size() == 0,
                  "VmVnicNetworkResourcePoolRuntime info is correct",
                  "VmVnicNetworkResourcePoolRuntime info is not correct");
          }
          //if VirtualEthernetCardResourceAllocation data provided
          //then verify DvsVnicAllocatedResource info.
          if(createdVMsMorList != null){
              verifyDvsVnicAllocatedResource(notConnectDvpgMorList, resRuntimeInfo);
          } else {
              assertTrue(resRuntimeInfo.getAllocatedResource().size() == 0 ,
                  "VnicAllocatedResource runtime info is correct",
                  "VnicAllocatedResource runtime info is not correct");
          }
      } else {
          throw new Exception("No configure specification data provided for " +
                              "verifyResourceRuntimeInfo method");
     }
  }

   /**
    *
    * This method verifies the AllocatedResource info of sepecified VM.
    * If the vm is connected to a dvpg that is associate to resource pool then that vm
    * will show up in the resource pool runtime info
    * dvs.runtime.resourceRuntimeInfo.VmVnicNetworkResourceRuntime.AllocatedResource.
    * If the dvpg is not connected to a resource pool, then the vm will be found
    * inside dvs.runtime.resourceRuntimeInfo.AllocatedResource
    *
    * @param createdVMsMorList
    * @param vnicResAllocList
    * @param customMap
    * @param resRuntimeInfo
    *
    * @throws Exception
    */

    private void verifyDvsVnicAllocatedResource(
       List<ManagedObjectReference> notConnectDvpgMorList,
       DvsResourceRuntimeInfo resRuntimeInfo) throws Exception
   {
       Long expectedConnectedResPoolRes = null;
       Long expectedNotConnectedResPoolRes = null;
       ArrayList<VirtualEthernetCard> allCardList = new ArrayList<VirtualEthernetCard>();
       ArrayList<VirtualEthernetCard> notConnectedCardList = new ArrayList<VirtualEthernetCard>();
       VirtualMachineConfigInfo vmConfigInfo = null;
       ArrayList<VirtualDevice> vDeviceList = new ArrayList<VirtualDevice>();
       Long vmVnicAllocRes = null;

       //First get all the all the virtual ethernet cards list of created power on VM
       //Handle created vms one by one
       for(ManagedObjectReference vmMor : createdVMsMorList){
       //Skip if vm's status is power off
          if (!VirtualMachinePowerState.POWERED_OFF.equals(
                 virtualMachine.getVMState(vmMor))){
              //Get the vmVnic of power on VM
              vmConfigInfo = this.virtualMachine.getConfigInfo(vmMor);
              vDeviceList = (ArrayList<VirtualDevice>) vmConfigInfo.getHardware().getDevice();
              if(vDeviceList!=null){
                  for (VirtualDevice vd : vDeviceList) {
                      if (vd != null && vd instanceof VirtualEthernetCard) {
                          allCardList.add((VirtualEthernetCard)vd);
                      }
                  }
              }
          }
       }
       //Then get the virtual ethernet cards list whose port group
       //doesn't associate to a resource pool
       if(notConnectDvpgMorList !=  null && notConnectDvpgMorList.size() != 0)
       {
           //handle each port group 1 by 1
           for(ManagedObjectReference pgMor : notConnectDvpgMorList){
               notConnectedCardList.addAll(getPortgroupConnectedvCardList(pgMor));
           }
       }
       if(notConnectedCardList != null && notConnectedCardList.size() != 0){
           for(VirtualEthernetCard vCard : allCardList){
               vmVnicAllocRes = vCard.getResourceAllocation().getReservation();
               if(notConnectedCardList.contains(vCard)){
                   expectedNotConnectedResPoolRes = addNewResToSum(vmVnicAllocRes,
                       expectedNotConnectedResPoolRes);
               } else {
                   expectedConnectedResPoolRes = addNewResToSum(vmVnicAllocRes,
                       expectedConnectedResPoolRes);
               }
           }
       } else {
           for(VirtualEthernetCard vCard : allCardList){
               vmVnicAllocRes = vCard.getResourceAllocation().getReservation();
               expectedConnectedResPoolRes = addNewResToSum(vmVnicAllocRes,
                   expectedConnectedResPoolRes);
           }
       }
       
       Long actualConnectedResPoolRes = null;
       Long actualNotConnectedResPoolRes = null;
       List<DvsVmVnicNetworkResourcePoolRuntimeInfo> resPoolRuntimeList =
               resRuntimeInfo.getVmVnicNetworkResourcePoolRuntime();
       for(DvsVmVnicNetworkResourcePoolRuntimeInfo info : resPoolRuntimeList){
           for(DvsVnicAllocatedResource res : info.getAllocatedResource()){
               actualConnectedResPoolRes = addNewResToSum(res.getReservation(),
                                              actualConnectedResPoolRes);
           }
       }
       for(DvsVnicAllocatedResource res : resRuntimeInfo.getAllocatedResource()){
           actualNotConnectedResPoolRes = addNewResToSum(res.getReservation(),
                                             actualNotConnectedResPoolRes);
       }

       assertTrue(expectedConnectedResPoolRes == actualConnectedResPoolRes &&
          expectedNotConnectedResPoolRes == actualNotConnectedResPoolRes,
          "VM AllocatedResource is correct", "VM AllocatedResource is not correct");
}

/**
 *
 * This method returns the new sum number by adding the new resource
 * number to current sum resource number.
 *
 * @param vmVnicAllocRes
 * @param notConnectedResPoolRes
 * @return Long
 */
private Long addNewResToSum(Long newRes, Long sumRes)
{
    if(newRes == null || newRes.longValue() == 0)
    {
        return sumRes;
    } else if(sumRes == null){
        return newRes;
    } else {
        return sumRes + newRes;
    }
}


/**
 *
 * This method returns the VmVnicNetworkResourcePoolKey for specific
 * portKey. It returns null if the VmVnicNetworkResourcePoolKey not defined
 * in dvpgSpecList.
 *
 * @param dvpgSpecList
 * @param portKey
 * @return String
 */
private String getPortGroupResourcePoolSpec(
    List<DVPortgroupConfigSpec> dvpgSpecList,
        String portKey)
{
    for(DVPortgroupConfigSpec dvpgSpec : dvpgSpecList){
        if(dvpgSpec.getName().equals(portKey)){
            return dvpgSpec.getVmVnicNetworkResourcePoolKey();
        }
    }
    return null;
}

/**
    * This method will be useful for reconfiguring the vm's vnics to
    * the required dvportgroups
    *
    * @throws Exception
    */
   public void reconfigureVMVnicsToVdsPortgroup()
      throws Exception{
      if(this.vmMorList == null){
         throw new Exception("There are no VMs in the inventory");
      }
      Map<String,String> ethernetCardNetworkMap = NetworkUtil.
               getEthernetCardNetworkMap(vmMorList.get(0), connectAnchor);
      // Store the ethernet card network map for the first virtual machine
      this.vmListEthernetCardMap.put(vmMorList.get(0), ethernetCardNetworkMap);
      List<String> objIdList = getStep("reconfigureVMVnicsToVdsPortgroup").
               getData();
      if(objIdList == null){
         throw new Exception("No objects provided for " +
                      "reconfigureVMVnicsToVdsPortgroup method");
      }
      CustomMap customMap = null;
      for(String objId: objIdList){
         Object obj = this.xmlFactory.getData(objId);
         if(obj instanceof CustomMap){
            customMap = (CustomMap)obj;
         }
      }
      List<String> vnicPortMap = customMap.getListIdMap();
      Map<String,Map<String,Boolean>> newEthernetCardMap = new HashMap<String,
               Map<String,Boolean>>();
      List<VirtualDeviceConfigSpec> ethernetCardDeviceSpecList = DVSUtil.
               getAllVirtualEthernetCardDevices(vmMorList.get(0),
               connectAnchor);
      ManagedObjectReference vdsMor = null;
      for(int i=0;i<vnicPortMap.size();i++){
         if(i<ethernetCardDeviceSpecList.size()){
            String pgid = vnicPortMap.get(i);
            ManagedObjectReference pgMor = this.objectIdVdsPortgroupMorMap.
                     get(pgid);
            Map<String,Boolean> vdsPortMap = new HashMap<String,Boolean>();
            vdsPortMap.put(this.vdsPortgroup.getKey(pgMor), true);
            newEthernetCardMap.put(ethernetCardDeviceSpecList.get(i).
                     getDevice().getDeviceInfo().getLabel(),vdsPortMap);
            if(vdsMor == null){
               vdsMor = this.vdsPortgroup.getConfigInfo(pgMor).
               getDistributedVirtualSwitch();
            }
         }
      }
      DVSUtil.reconfigureVMConnectToVdsPort(vmMorList.get(0),
                                            connectAnchor,
                                            newEthernetCardMap,
                                            this.vds.getConfig(vdsMor).
                                            getUuid());
   }

   /**
    * This method reconfigures a vm's vnics to connect to its original
    * network entities
    *
    * @throws Exception
    */
   public void restoreVMNetwork()
      throws Exception
   {
      if(this.vmListEthernetCardMap == null){
         throw new Exception("There is no vm in the inventory whose " +
              "network is to be restored");
      }
      for(ManagedObjectReference vmMor : this.vmListEthernetCardMap.keySet()){
         Map<String,String> ethernetMap = this.vmListEthernetCardMap.get(vmMor);
         NetworkUtil.reconfigureVMConnectToPortgroup(vmMor, connectAnchor,
                  ethernetMap);
      }
   }

   /**
    * This method iterates through a list of object ids and picks
    * the one that is the corresponding id for the object type "T"
    *
    * @param obj
    * @param objIdList
    *
    * @return String
    */
   public <T> String getObjectId(T obj, List<String> objIdList)
   {
      List<Object> oList = this.xmlFactory.getData(objIdList);
      for(String objId : objIdList){
         T srcObj = (T)this.xmlFactory.getData(objId);
         if(srcObj.equals(obj))
            return objId;
      }
      return null;
   }

   /**
    * This method configures netioc version 2 on the vds
    *
    * @throws Exception
    */
   public void enableNetIocV2()
      throws Exception
   {
      List<String> objIdList = getStep("enableNetIocV2").getData();
      for(String objId: objIdList){
         ManagedObjectReference vdsMor = this.objectIdVdsMorMap.get(objId);
         vds.enableNetworkResourceManagement(vdsMor, true);
         vds.setNetworkResourceControlVersion(vdsMor,
                  NetworkResourceControlVersion.version2.name());
      }
   }

   /**
    * This method configures netioc version 3 on the vds
    *
    * @throws Exception
    */
   public void enableNetIocV3()
      throws Exception
   {
      List<String> objIdList = getStep("enableNetIocV3").getData();
      for(String objId: objIdList){
         ManagedObjectReference vdsMor = this.objectIdVdsMorMap.get(objId);
         vds.enableNetworkResourceManagement(vdsMor, true);
         vds.setNetworkResourceControlVersion(vdsMor,
                  NetworkResourceControlVersion.version3.name());
      }
   }

    /**
     * This method enables network resource management on the vds
     *
     * @throws Exception
     */
    public void enableNetworkResourceManagement() throws Exception
    {
        List<String> objIdList =
            getStep("enableNetworkResourceManagement").getData();
        for (String objId : objIdList) {
            ManagedObjectReference vdsMor = this.objectIdVdsMorMap.get(objId);
            vds.enableNetworkResourceManagement(vdsMor, true);
        }
    }

    /**
     * This method adds dvs resource network resource pool on the vds
     *
     * @throws Exception
     */
    public void addDvsNetworkResourcePool() throws Exception
    {
        List<String> objIdList = getStep("addDvsNetworkResourcePool").getData();
        if (objIdList == null) {
            throw new Exception(
                "No objects provided for addDvsNetworkResourcePool " + "method");
        }
        ManagedObjectReference vdsMor = null;
        DVSNetworkResourcePoolConfigSpec[] configSpecArray = null;
        for (String objId : objIdList) {
            Object obj = this.xmlFactory.getData(objId);
            if (obj instanceof DVSConfigSpec) {
                vdsMor = this.objectIdVdsMorMap.get(objId);

            }
            if (obj instanceof java.util.ArrayList) {
                ArrayList<DVSNetworkResourcePoolConfigSpec> tmpArray =
                    (ArrayList<DVSNetworkResourcePoolConfigSpec>) obj;
                configSpecArray =
                    tmpArray
                        .toArray(new DVSNetworkResourcePoolConfigSpec[tmpArray
                            .size()]);
            }
        }
        /*
         * Call DistributedVirtualSwitch.addNetworkResourcePool to add network
         * resource pool on the vds.
         */
        this.vds.addNetworkResourcePool(vdsMor, configSpecArray);
    }

   /**
    * This method creates a default virtual machine with 5 vnics
    *
    * @throws Exception
    */
   public void createDefaultVM()
      throws Exception
   {
        assertTrue(
            (this.hostMorList != null && this.hostMorList.size() >= 1),
            "Found at least one host in the inventory",
            "Failed to find a host in the inventory");
        this.createdVMsMorList =
            DVSUtil.createVms(connectAnchor, this.hostMorList.get(0), 1, 5);
        this.vmMorList = this.createdVMsMorList;
   }

   /**
    * This method creates a VM which has 1 vnic connected to
    * desired Vinic Port Group.
    *
    * @throws Exception
    */
   public void createVmConnectedToVnicPortGroup()
       throws Exception
    {
        List<String> objIdList =
            getStep("createVmConnectedToVnicPortGroup").getData();
        if (objIdList == null) {
            throw new Exception(
                "No objects provided for createVmConnectedToVnicPortGroup "
                    + "method");
        }
        CustomMap customMap1 = null;
        for (String objId : objIdList) {
            Object obj = this.xmlFactory.getData(objId);
            if (obj instanceof CustomMap) {
                customMap1 = (CustomMap) obj;
            }
        }

        List<String> vnicPortMap = customMap1.getListIdMap();
        String pgid = vnicPortMap.get(0);
        ManagedObjectReference pgMor =
            this.objectIdVdsPortgroupMorMap.get(pgid);
        String portGroupKey = this.vdsPortgroup.getKey(pgMor);
        ManagedObjectReference vdsMor =
            this.vdsPortgroup.getConfigInfo(pgMor)
                .getDistributedVirtualSwitch();
        DistributedVirtualSwitchPortConnection dvsPortConn =
            DVSUtil.buildDistributedVirtualSwitchPortConnection(this.vds
                .getConfig(vdsMor).getUuid(), null, portGroupKey);
        assertTrue(
            (this.hostMorList != null && this.hostMorList.size() >= 1),
            "Found at least one host in the inventory",
            "Failed to find a host " + "in the inventory");
        ManagedObjectReference hostMor = this.hostMorList.get(0);
        Vector<ManagedObjectReference> poolList = host.getResourcePool(hostMor);
        assertTrue(
            (poolList != null && poolList.size() >= 1),
            "Found at least one pool in the host",
            "Failed to find a pool in the inventory");
        ManagedObjectReference poolMor = poolList.get(0);
        String vmName = TestUtil.getRandomizedTestId("VM-");
        VirtualMachineConfigSpec origVMConfigSpec =
            this.virtualMachine.createVMConfigSpec(
                poolMor,
                hostMor,
                vmName,
                TestConstants.VM_DEFAULT_GUEST_WINDOWS,
                TestUtil.arrayToVector(new String[] {
                    TestConstants.VM_CREATE_DEFAULT_DEVICE_TYPE
                    }),
                null);
        assertNotNull(origVMConfigSpec, VM_SPC_CREATE_PASS, VM_SPC_CREATE_FAIL);
        /*
         * Create VM connected to desired Vinic Port Group
         */
        VirtualEthernetCard card = null;
        List<VirtualDeviceConfigSpec>  deviceSpecList = origVMConfigSpec.getDeviceChange();
        for(VirtualDeviceConfigSpec spec : deviceSpecList){
            VirtualDevice dev = spec.getDevice();
            if(dev instanceof VirtualEthernetCard){
               card = (VirtualEthernetCard)dev;
            }
         }
         assertNotNull(card,
             "Succeeded to find a VirtualEthernetCard device",
             "Failed to find a VirtualEthernetCard device");
        VirtualEthernetCardDistributedVirtualPortBackingInfo backingInfo =
            new VirtualEthernetCardDistributedVirtualPortBackingInfo();
        backingInfo.setPort(dvsPortConn);
        card.setBacking(backingInfo);
        ManagedObjectReference vmMor =
            this.folder.createVM(
                this.virtualMachine.getVMFolder(),
                origVMConfigSpec,
                poolMor,
                hostMor);
        assertNotNull(vmMor, VM_CREATE_PASS, VM_CREATE_FAIL);
        if (this.createdVMsMorList == null) {
            this.createdVMsMorList = new Vector<ManagedObjectReference>();
        }
        this.createdVMsMorList.add(vmMor);
        this.vmMorList = this.createdVMsMorList;
    }

    /**
     * This method creates a VM which has 1 vnic with desired
     * VirtualEthernetCardResourceAllocation.
     *
     * To Do:
     * Current reconfigureVMVnicsToVdsPortgroup can only handle the
     * first vm in vmMorList. And there is no association relationship
     * between vm and port group provided from xml data. All the vms
     * created are saved in this.createdVMList. Hence the function doesn't
     * have the capability of handling mutiple vms/vnics.
     * Need to add vmConfigSpec data and custom maps for vnic and portgroup
     * association.
     *
     * @throws Exception
     */
    public void createVmWithVnicResourceAllocation()
       throws Exception
    {
        List<String> objIdList =
            getStep("createVmWithVnicResourceAllocation").getData();
        if (objIdList == null) {
            throw new Exception(
                "No objects provided for createVmWithVnicResourceAllocation "
                    + "method");
        }
        CustomMap customMap1 = null;
        VirtualEthernetCardResourceAllocation vnicResAlloc = null;
        String vmName = null;
        for (String objId : objIdList) {
            Object obj = this.xmlFactory.getData(objId);
            if (obj instanceof CustomMap) {
                customMap1 = (CustomMap) obj;
            } else if (obj instanceof VirtualEthernetCardResourceAllocation) {
                vnicResAlloc = (VirtualEthernetCardResourceAllocation) obj;
            } else if(obj instanceof VirtualMachineConfigSpec){
                VirtualMachineConfigSpec spec = (VirtualMachineConfigSpec)obj;
                vmName = spec.getName();
            }
        }
        assertNotNull(
            vnicResAlloc,
            "Successfully got VirtualEthernetCardResourceAllocation obj",
            "VirtualEthernetCardResourceAllocation obj is null");
        List<String> vnicPortMap = customMap1.getListIdMap();
        String pgid = vnicPortMap.get(0);
        ManagedObjectReference pgMor =
            this.objectIdVdsPortgroupMorMap.get(pgid);
        String portGroupKey = this.vdsPortgroup.getKey(pgMor);
        ManagedObjectReference vdsMor =
            this.vdsPortgroup.getConfigInfo(pgMor)
                .getDistributedVirtualSwitch();
        DistributedVirtualSwitchPortConnection dvsPortConn =
            DVSUtil.buildDistributedVirtualSwitchPortConnection(this.vds
                .getConfig(vdsMor).getUuid(), null, portGroupKey);
        assertTrue(
            (this.hostMorList != null && this.hostMorList.size() >= 1),
            "Found at least one host in the inventory",
            "Failed to find a host " + "in the inventory");
        ManagedObjectReference hostMor = this.hostMorList.get(0);
        Vector<ManagedObjectReference> poolList = host.getResourcePool(hostMor);
        assertTrue(
            (poolList != null && poolList.size() >= 1),
            "Found at least one pool in the host",
            "Failed to find a pool in the inventory");
        ManagedObjectReference poolMor = poolList.get(0);
        if( vmName == null){
            vmName = TestUtil.getRandomizedTestId("VM-");
        }
        VirtualMachineConfigSpec origVMConfigSpec =
            this.virtualMachine.createVMConfigSpec(
                poolMor,
                hostMor,
                vmName,
                TestConstants.VM_DEFAULT_GUEST_WINDOWS,
                TestUtil.arrayToVector(new String[] {
                    TestConstants.VM_CREATE_DEFAULT_DEVICE_TYPE
                    }),
                null);
        assertNotNull(origVMConfigSpec, VM_SPC_CREATE_PASS, VM_SPC_CREATE_FAIL);
        /*
         * Create VM with VirtualEthernetCardDistributedVirtualPortBackingInfo
         */
        VirtualEthernetCard card = null;
        List<VirtualDeviceConfigSpec>  deviceSpecList = origVMConfigSpec.getDeviceChange();
        for(VirtualDeviceConfigSpec spec : deviceSpecList){
            VirtualDevice dev = spec.getDevice();
            if(dev instanceof VirtualEthernetCard){
               card = (VirtualEthernetCard)dev;
            }
         }
         assertNotNull(card,
             "Succeeded to find a VirtualEthernetCard device",
             "Failed to find a VirtualEthernetCard device");
        VirtualEthernetCardDistributedVirtualPortBackingInfo backingInfo =
            new VirtualEthernetCardDistributedVirtualPortBackingInfo();
        backingInfo.setPort(dvsPortConn);
        card.setBacking(backingInfo);
        card.setResourceAllocation(vnicResAlloc);
        ManagedObjectReference vmMor =
            this.folder.createVM(
                this.virtualMachine.getVMFolder(),
                origVMConfigSpec,
                poolMor,
                hostMor);
        assertNotNull(vmMor, VM_CREATE_PASS, VM_CREATE_FAIL);
        if (this.createdVMsMorList == null) {
            this.createdVMsMorList = new Vector<ManagedObjectReference>();
        }
        this.createdVMsMorList.add(vmMor);
        this.vmMorList = this.createdVMsMorList;
        assertTrue(
            verifyVnicResourceAllocation(vmMor, vnicResAlloc),
            "vnic resource allocation is equal.",
            "vnic resource allocation is not equal!");
    }

    /**
     * This method creates a virtual machines with
     * soecific names
     *
     * @throws Exception
     */
    public void createVMs()
       throws Exception
    {
       assertTrue(
             (this.hostMorList != null && this.hostMorList.size() >= 1),
             "Found at least one host in the inventory",
             "Failed to find a host in the inventory");
       List<String> objIdList = getStep("createVMs").getData();
       ArrayList<String> vmNameList = new ArrayList<String>();
       if(objIdList == null){
          throw new Exception("There is no data provided for creating the vds");
       } else{
          for(String objId : objIdList){
             Object obj = this.xmlFactory.getData(objId);
             ManagedObjectReference vmMor = null;
             if(obj instanceof VirtualMachineConfigSpec){
                VirtualMachineConfigSpec spec = (VirtualMachineConfigSpec)obj;
                vmNameList.add(spec.getName());
             }
          }
       }
       List<ManagedObjectReference> newVms =
           DVSUtil.createVms(connectAnchor, this.hostMorList.get(0), 1, 5);
       this.createdVMsMorList.addAll(newVms);
       this.vmMorList.addAll(newVms);
    }

    /**
     * This method will be useful for reconfiguring the vm's vnic
     * resource allocation.
     *
     * @throws Exception
     */
    public void reconfigureVMVnicResourceAllocation()
       throws Exception
    {
        List<String> objIdList =
            getStep("reconfigureVMVnicResourceAllocation").getData();
        if (objIdList == null) {
            throw new Exception(
                "No objects provided for reconfigureVMVnicResourceAllocation method");
        }
        VirtualEthernetCardResourceAllocation vnicResAlloc = null;
        for (String objId : objIdList) {
            Object obj = this.xmlFactory.getData(objId);
            if (obj instanceof VirtualEthernetCardResourceAllocation) {
                vnicResAlloc = (VirtualEthernetCardResourceAllocation) obj;
            }
        }
        if (this.vmMorList == null) {
            throw new Exception("There are no VMs in the inventory");
        }
        /* Use the first VM only */
        ManagedObjectReference vmMor = this.vmMorList.get(0);
        assertNotNull(vmMor, "Got valid VM", "There is no VM found");
        VirtualMachineConfigSpec vmConfigSpec = new VirtualMachineConfigSpec();
        List<VirtualDeviceConfigSpec> virtualDeviceConfigSpecs =
            new ArrayList<VirtualDeviceConfigSpec>();
        VirtualDevice[] vDev = null;
        VirtualMachineConfigInfo vmConfigInfo =
            this.virtualMachine.getConfigInfo(vmMor);
        assertNotNull(vmConfigInfo,
            "Successfully got VirtualMachineConfigInfo obj",
            "vm config info is null.");
        assertNotNull(
            vmConfigInfo.getHardware(),
            "Successfully got vm harward",
            "vm getHardware returned null.");
        vDev =
            com.vmware.vcqa.util.TestUtil.vectorToArray(vmConfigInfo
                .getHardware().getDevice(), com.vmware.vc.VirtualDevice.class);
        assertNotNull(vDev,
             "Got valid virtual devices",
             "Returned virtual devices are null.");
        for (VirtualDevice vd : vDev) {
            if (vd != null && vd instanceof VirtualEthernetCard) {
                VirtualDeviceConfigSpec virtualDeviceConfigSpec =
                    new VirtualDeviceConfigSpec();
                VirtualEthernetCard virtualEthernetCard =
                    (VirtualEthernetCard) vd;
                virtualEthernetCard.setResourceAllocation(vnicResAlloc);
                virtualDeviceConfigSpec
                    .setOperation(VirtualDeviceConfigSpecOperation.EDIT);
                virtualDeviceConfigSpec.setDevice(virtualEthernetCard);
                virtualDeviceConfigSpecs.add(virtualDeviceConfigSpec);
            }
        }
        vmConfigSpec.getDeviceChange().clear();
        vmConfigSpec
            .getDeviceChange()
            .addAll(
                com.vmware.vcqa.util.TestUtil.arrayToVector(virtualDeviceConfigSpecs
                    .toArray(new VirtualDeviceConfigSpec[virtualDeviceConfigSpecs
                        .size()])));
        /*
         * Reconfigure the virtual machine with the new settings
         */
        assertTrue(
            this.virtualMachine.reconfigVM(vmMor, vmConfigSpec),
            "Reconfigure the VM successfully",
            "Failed to reconfigure the virtual machine with "
                + "vnic resource allocation");
        assertTrue(
            verifyVnicResourceAllocation(vmMor, vnicResAlloc),
            "vnic resource allocation is equal!",
            "vnic resource allocation is not equal!");
    }

    /**
     * This method verifies the parameters for vm's vnic resource allocation.
     *
     * @param vmMor
     * @param vnicResAlloc
     * @return boolean
     *
     * @throws Exception
     */
    public boolean verifyVnicResourceAllocation(
        ManagedObjectReference vmMor,
            VirtualEthernetCardResourceAllocation vnicResAlloc)
        throws Exception
    {
        assertNotNull(vmMor,
             "Got vmMor successfully",
             "vmMor parameter is null");
        VirtualDevice[] vDev = null;
        VirtualMachineConfigInfo vmConfigInfo =
            this.virtualMachine.getConfigInfo(vmMor);
        assertNotNull(vmConfigInfo,
             "Got vm config info successfully",
             "vm config info is null.");
        assertNotNull(
            vmConfigInfo.getHardware(),
            "Got vm hardware successfully",
            "vm getHardware returned null.");
        vDev =
            com.vmware.vcqa.util.TestUtil.vectorToArray(vmConfigInfo
                .getHardware().getDevice(), com.vmware.vc.VirtualDevice.class);
        assertNotNull(vDev,
            "Got virtual devices successfully",
            "Returned virtual devices are null.");
        for (VirtualDevice vd : vDev) {
            if (vd != null && vd instanceof VirtualEthernetCard) {
                VirtualEthernetCard virtualEthernetCard =
                    (VirtualEthernetCard) vd;
                VirtualEthernetCardResourceAllocation currVnicResAlloc =
                    virtualEthernetCard.getResourceAllocation();
                boolean isEqual = false;
                isEqual =
                    (vnicResAlloc != null) ? vnicResAlloc.getLimit().equals(
                        currVnicResAlloc.getLimit()) : true;
                isEqual &=
                    (vnicResAlloc.getReservation() != null) ? vnicResAlloc
                        .getReservation().equals(
                            currVnicResAlloc.getReservation()) : true;
                isEqual &=
                    (vnicResAlloc.getShare() != null && vnicResAlloc.getShare()
                        .getLevel() != null) ? vnicResAlloc
                        .getShare()
                        .getLevel()
                        .toString()
                        .equals(
                            currVnicResAlloc.getShare().getLevel().toString())
                        : true;
                isEqual &=
                    (vnicResAlloc.getShare() != null) ? (vnicResAlloc
                        .getShare().getShares() == currVnicResAlloc.getShare()
                        .getShares()) : true;
                if (isEqual != true) {
                    return false;
                }
            }
        }
        return true;
    }

    /**
     * This method powers on the default virtual machine created in
     * createDefaultVM()
     *
     * @throws Exception
     */
    public void powerOnDefaultVM()
       throws Exception
    {
        if (createdVMsMorList != null && createdVMsMorList.size() > 0) {
            for (ManagedObjectReference vmMor : createdVMsMorList) {
                if (virtualMachine.getVMState(vmMor).equals(
                    VirtualMachinePowerState.POWERED_OFF)) {
                    assertTrue(
                        virtualMachine.setVMState(
                            vmMor,
                            VirtualMachinePowerState.POWERED_ON,
                            false),
                        "Successfully powered on the virtual machine",
                        "Failed to power on the virtual machine");
                }
            }
        }
    }

    /**
     * This method powers on the virtual machine desired.
     * It also compares the actual method fault with excepted
     * method fault.
     *
     * @throws Exception
     */
    public void powerOnVM()
       throws Exception
    {
        MethodFault expectedMethodFault = null;
        List<String> objIdList = getStep("powerOnVM").getData();
        String vmName = null;
        ManagedObjectReference vmMor = new ManagedObjectReference();
        if(objIdList!=null && objIdList.size()!=0){
            for(String objId : objIdList){
                Object obj = this.xmlFactory.getData(objId);
                if(obj instanceof VirtualMachineConfigSpec){
                    VirtualMachineConfigSpec spec = (VirtualMachineConfigSpec)obj;
                    vmName = spec.getName();
                }
                else if(obj instanceof MethodFault){
                        Class<?> faultClass = Class.forName(objId);
                        Constructor<?> faultCons = faultClass.getConstructor();
                        Object faultObj = faultCons.newInstance();
                        if(faultObj instanceof MethodFault){
                            expectedMethodFault = (MethodFault)faultObj;
                        }
                }
            }
        }
        //if vmName is not specified, then poweron default vm.
        if(vmName == null){
            powerOnDefaultVM();
        } else{
            if (createdVMsMorList != null && createdVMsMorList.size() > 0) {
                for (ManagedObjectReference mor : createdVMsMorList) {
                    if (virtualMachine.getName(mor).equals(vmName) &&
                        virtualMachine.getVMState(mor).equals(
                        VirtualMachinePowerState.POWERED_OFF)) {
                        vmMor = mor;
                    }
                }
            }
            try{
                virtualMachine.setVMState(vmMor,
                    VirtualMachinePowerState.POWERED_ON,false);
                if(expectedMethodFault != null){
                   log.error("There was no exception thrown");
                   throw new Exception("No exception thrown");
                }
             }catch(Exception actualMethodFaultExcep){
                MethodFault actualMethodFault = com.vmware.vcqa.util.
                TestUtil.getFault(actualMethodFaultExcep);
                assertTrue(
                    TestUtil.checkMethodFault(actualMethodFault,
                    expectedMethodFault),"The expected and actual method " +
                    "faults of powerOnVM() match","The expected and actual method" +
                    "faults of powerOnVM() do not match");
             }
         }
    }

    /**
     * This method powers off the virtual machine desired.
     *
     * @throws Exception
     */
    public void powerOffVM()
       throws Exception
    {
        MethodFault expectedMethodFault = null;
        List<String> objIdList = getStep("powerOffVM").getData();
        String vmName = null;
        if(objIdList!=null && objIdList.size()!=0){
            for(String objId : objIdList){
                Object obj = this.xmlFactory.getData(objId);
                if(obj instanceof VirtualMachineConfigSpec){
                    VirtualMachineConfigSpec spec = (VirtualMachineConfigSpec)obj;
                    vmName = spec.getName();
                }
            }
        }
        //if vmName is not specified, then poweron default vm.
        if(vmName == null){
            throw new Exception("No vmName provided for powerOffVM method.");
        } else{
            if (createdVMsMorList != null && createdVMsMorList.size() > 0) {
                for (ManagedObjectReference vmMor : createdVMsMorList) {
                    if (virtualMachine.getName(vmMor).equals(vmName) &&
                        virtualMachine.getVMState(vmMor).equals(
                        VirtualMachinePowerState.POWERED_ON)) {
                        virtualMachine.setVMState(vmMor,
                            VirtualMachinePowerState.POWERED_OFF,false);
                    }
                }
            }
        }
    }

   /**
    * This method verifies the parameters on the vmvnic resource pool and
    * returns true if all parameters are equal, false otherwise
    *
    *
    * @param spec
    * @param pool
    *
    * @return boolean
    */
   public boolean verifyNetworkResourcePoolParams(
                                       DvsVmVnicResourcePoolConfigSpec spec,
                                       DVSVmVnicNetworkResourcePool pool)
   {
      boolean isEqual = false;
      isEqual = spec.getName().equals(pool.getName());
      isEqual &= (spec.getDescription()!=null) ?
               spec.getDescription().equals(pool.getDescription()) :
               true;
      isEqual &= (spec.getAllocationInfo()!=null) ?
                  spec.getAllocationInfo().getReservationQuota().equals(pool.
                  getAllocationInfo().getReservationQuota()) :
                  true;
      return isEqual;
   }

    /**
     * This method verifies the parameters on the vmvnic resource pool with a
     * pool config spec.
     *
     * @throws Exception
     *
    */
    public void verifyNetworkResourcePoolFromSpec()
       throws Exception
    {
        List<String> objIdList =
            getStep("verifyNetworkResourcePoolFromSpec").getData();
        ManagedObjectReference vdsMor = null;
        DvsVmVnicResourcePoolConfigSpec spec = null;
        for (String objId : objIdList) {
            if (this.objectIdVdsMorMap.get(objId) != null) {
                vdsMor = objectIdVdsMorMap.get(objId);
            }
            Object obj = this.xmlFactory.getData(objId);
            if (obj instanceof DvsVmVnicResourcePoolConfigSpec) {
                spec = (DvsVmVnicResourcePoolConfigSpec) obj;
            }
        }
        assertNotNull(
            spec,
            "Successfully got DvsVmVnicResourcePoolConfigSpec object",
            "DvsVmVnicResourcePoolConfigSpec object was null");
        String poolname = spec.getName();
        DVSVmVnicNetworkResourcePool pool =
            vds.getVmVnicNetworkResourcePool(vdsMor, poolname);
        assertNotNull(
            pool,
            "Found a valid DVSVmVnicNetworkResourcePool",
            "Failed to get a DVSVmVnicNetworkResourcePool");
        assertTrue(
            verifyNetworkResourcePoolParams(spec, pool),
            "Passed to verify network resource pool for" + poolname,
            "Failed to verify network resource pool for " + poolname);
    }

   /**
    * This method counts the number of operations in the specified object.
    *
    * @param List<DvsVmVnicResourcePoolConfigSpec>
    *
    * @return int, count of the specified operation type
    *
    * @throws Exception
    */
   public int countOperations(List<DvsVmVnicResourcePoolConfigSpec> specList,
                              String operation)
      throws Exception
   {
      int numOperations = 0;
      for(DvsVmVnicResourcePoolConfigSpec dataSpec : specList){
         if(dataSpec.getOperation().equals(operation)){
            numOperations++;
         }
      }
      return numOperations;
   }

   /**
    * This method initializes the data pertaining to the step as mentioned in
    * the data file.
    *
    * @param stepName
    *
    * @throws Exception
    */
   public void init(String stepName)
      throws Exception
   {
      Step step = getStep(stepName);
      if(step != null){
         List<String> data  = step.getData();
         if(data != null){
            List<Object> objIdList = this.xmlFactory.getData(data);
            if(objIdList != null){
               initData(objIdList);
            }
         }
      }
   }

   /**
    * This method instantiates the data for itself and populates the selection
    * sets.
    *
    * @throws Exception
    */
   public void instData()
      throws Exception
   {
      init("instData");
   }

   /**
    * This method associates the port group to the
    * desired resource pool.
    * @throws Exception
    */
   public void associatePortgroupsFromResPool()
      throws Exception
   {
       List<Object> objList = this.xmlFactory.getData(getStep("associatePortgroupsFromResPool").
           getData());
       if(objList == null || objList.isEmpty()){
          throw new Exception("No data provided for associatePortgroupsFromResPool method");
       }
      CustomMap vdsPortgroupMap = null;
      for(Object obj : objList){
         if(obj instanceof CustomMap){
            vdsPortgroupMap = (CustomMap)obj;
         }
      }
      Map<String,String> portgroupVmVnicNetworkResPoolMap = vdsPortgroupMap.
          getObjectIdMap();
      ManagedObjectReference dvpgMor = new ManagedObjectReference();
      HashMap<String, ManagedObjectReference> dvpgMorMap = this.objectIdVdsPortgroupMorMap;
      DistributedVirtualPortgroup dvPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      String dvsKey = null;
      String poolId = null;
      Iterator<String> it = portgroupVmVnicNetworkResPoolMap.keySet().iterator();
      while(it.hasNext()){
          dvsKey = it.next();
          dvpgMor = dvpgMorMap.get(dvsKey);
          DVPortgroupConfigSpec ConfigSpec = new DVPortgroupConfigSpec();
          ConfigSpec.setConfigVersion(dvPortgroup.getConfigInfo(dvpgMor).getConfigVersion());
          ConfigSpec.setDefaultPortConfig(new DVPortSetting());
          poolId = portgroupVmVnicNetworkResPoolMap.get(dvsKey);
          DVSVmVnicNetworkResourcePool pool = this.
              objectIdVmVnicResPoolMap.get(poolId);
          ConfigSpec.setVmVnicNetworkResourcePoolKey(pool.getKey());
          boolean reconfigured = dvPortgroup.reconfigure(dvpgMor, ConfigSpec);
          assertTrue(reconfigured,
                      "Successfully associate portgroup " + dvpgMor.getValue().toString()
                      + "from network resource pool",
                     "Failed to associate portgroup " + dvpgMor.getValue().toString()
                      + "from network resource pool");
      }
   }

   /**
    * This method disassociates the port group from the
    * resource pool it current associate with.
    * @throws Exception
    */
   public void disassociatePortgroupsFromResPool()
      throws Exception
   {
      List<String> objIdList = getStep("disassociatePortgroupsFromResPool").getData();
      if(objIdList == null || objIdList.isEmpty()){
         throw new Exception("No data provided for disassociatePortgroupsFromResPool method");
      }
      ArrayList<String> vdsPortgroupIdList = new ArrayList<String>();
      for(String objId : objIdList){
          Object obj = this.xmlFactory.getData(objId);
          if(obj instanceof DVPortgroupConfigSpec){
              vdsPortgroupIdList.add(objId);
          }
      }
      //Get the collection of portgroups we want to disconnect from resource pool.
      ArrayList<ManagedObjectReference> dvPortgroupMorList =
         new ArrayList<ManagedObjectReference>();
      HashMap<String, ManagedObjectReference> dvpgMorMap = this.objectIdVdsPortgroupMorMap;
      for(String pgId : vdsPortgroupIdList){
          dvPortgroupMorList.add(dvpgMorMap.get(pgId));
      }

      DistributedVirtualPortgroup dvPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      for(ManagedObjectReference dvpgMor : dvPortgroupMorList){
          DVPortgroupConfigSpec ConfigSpec = new DVPortgroupConfigSpec();
          ConfigSpec.setConfigVersion(dvPortgroup.getConfigInfo(dvpgMor).getConfigVersion());
          ConfigSpec.setDefaultPortConfig(new DVPortSetting());
          ConfigSpec.setVmVnicNetworkResourcePoolKey("-1".toString());
          boolean reconfigured = dvPortgroup.reconfigure(dvpgMor, ConfigSpec);
          assertTrue(reconfigured,
                      "Successfully disassociate portgroup " + dvpgMor.getValue().toString()
                      + "from network resource pool",
                     "Failed to disassociate portgroup " + dvpgMor.getValue().toString()
                      + "from network resource pool");
      }
   }

   /**
    * This method add the port group to the
    * resource pool specified.
    * @throws Exception
    */
   public void connectPortgroupsToResPool()
      throws Exception
   {
      List<Object> objList = this.xmlFactory.getData(getStep("ConnectPortgroupsToResPool").
           getData());
      if(objList == null || objList.isEmpty()){
         throw new Exception("No data provided for ConnectPortgroupsToResPool method");
      }
      CustomMap vdsPortgroupMap = null;
      ArrayList<DVPortgroupConfigSpec> dvPortgroupConfigSpecList = new
               ArrayList<DVPortgroupConfigSpec>();
      for(Object obj : objList){
         if(obj instanceof CustomMap){
            vdsPortgroupMap = (CustomMap)obj;
         }
      }
      Map<String,String> portgroupVmVnicNetworkResPoolMap = vdsPortgroupMap.
               getObjectIdMap();
      ArrayList<String> portgroupIdList =
         (ArrayList<String>) portgroupVmVnicNetworkResPoolMap.values();
      DistributedVirtualPortgroup dvPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      ManagedObjectReference dvpgMor = null;
      String resPoolId = null;
      for(String pgId : portgroupIdList){
          dvpgMor = this.objectIdVdsPortgroupMorMap.get(pgId);
          resPoolId = portgroupVmVnicNetworkResPoolMap.get(pgId);
          DVPortgroupConfigSpec ConfigSpec = new DVPortgroupConfigSpec();
          ConfigSpec.setConfigVersion(dvPortgroup.getConfigInfo(dvpgMor).getConfigVersion());
          ConfigSpec.setDefaultPortConfig(new DVPortSetting());
          DVSVmVnicNetworkResourcePool pool = this.
                   objectIdVmVnicResPoolMap.get(resPoolId);
          ConfigSpec.setVmVnicNetworkResourcePoolKey(pool.getKey());
          boolean reconfigured = dvPortgroup.reconfigure(dvpgMor, ConfigSpec);
          assertTrue(reconfigured,
              "Successfully connect portgroup " + dvpgMor.getValue().toString()
              + "to network resource pool" + pool.getName(),
             "Failed to connect portgroup " + dvpgMor.getValue().toString()
              + "to network resource pool" + pool.getName());
      }
   }

   /**
    * This method adds portgroups to the vds
    *
    *
    * @throws Exception
    */
   public void addPortgroups()
      throws Exception
   {
      List<Object> objList = this.xmlFactory.getData(getStep("addPortgroups").
               getData());
      if(objList == null || objList.isEmpty()){
         throw new Exception("No data provided for addPortgroups method");
      }
      CustomMap vdsPortgroupMap = null;
      for(Object obj : objList){
         if(obj instanceof CustomMap){
            vdsPortgroupMap = (CustomMap)obj;
            Map<String,List<String>> vdsPortgroupObjectMap = vdsPortgroupMap.
                getObjectListIdMap();
            Map<String,String> portgroupVmVnicNetworkResPoolMap = vdsPortgroupMap.
                getObjectIdMap();
            for(String vdsId : vdsPortgroupObjectMap.keySet()){
               ArrayList<DVPortgroupConfigSpec> dvPortgroupConfigSpecList = new
                   ArrayList<DVPortgroupConfigSpec>();
                ManagedObjectReference vdsMor = this.objectIdVdsMorMap.get(vdsId);
                List<String> portgroupIdList = vdsPortgroupObjectMap.get(vdsId);
                for(String portgroupId : portgroupIdList){
                   DVPortgroupConfigSpec spec = (DVPortgroupConfigSpec)
                            this.xmlFactory.getData(portgroupId);
                if (portgroupVmVnicNetworkResPoolMap != null) {
                   if(portgroupVmVnicNetworkResPoolMap.containsKey(portgroupId)){
                      String val = portgroupVmVnicNetworkResPoolMap.get(portgroupId);
                      DVSVmVnicNetworkResourcePool pool = this.
                               objectIdVmVnicResPoolMap.get(val);
                      spec.setVmVnicNetworkResourcePoolKey(pool.getKey());
                   }
                }
                   dvPortgroupConfigSpecList.add(spec);
                }
                List<ManagedObjectReference> pgMorList = vds.addPortGroups(vdsMor,
                       dvPortgroupConfigSpecList.toArray(new
                       DVPortgroupConfigSpec[dvPortgroupConfigSpecList.size()]));
                if(this.objectIdVdsPortgroupMorMap == null){
                    this.objectIdVdsPortgroupMorMap = new HashMap<String,
                          ManagedObjectReference>();
                }
                /*
                * For each portgroup mor, get the name and check if it matches
                * with the portgroup spec's name
                */
                for(ManagedObjectReference pgMor : pgMorList){
                   String name = this.vdsPortgroup.getName(pgMor);
                   for(String pgId : portgroupIdList){
                       DVPortgroupConfigSpec spec = (DVPortgroupConfigSpec)this.
                          xmlFactory.getData(pgId);
                       if(name.equals(spec.getName())){
                           this.objectIdVdsPortgroupMorMap.put(pgId, pgMor);
                           break;
                       }
                   }
                }
             }
         }
      }
   }

   /**
    * This method gets the vds mor from the config spec
    *
    * @param vdsConfigSpec
    *
    * @return ManagedObjectReference
    *
    * @throws Exception
    */
   public ManagedObjectReference getVdsMorForConfigSpec(DVSConfigSpec
                                                        vdsConfigSpec)
      throws Exception
   {
      for(ManagedObjectReference vdsMor : this.vdsMorList){
         if(vds.getConfig(vdsMor).getName().equals(vdsConfigSpec.getName())){
            return vdsMor;
         }
      }
      return null;
   }

   /**
    * This method gets the portgroup mor from the config spec provided
    *
    * @param portgroupConfigSpec
    *
    * @return ManagedObjectReference
    *
    * @throws Exception
    */
   public ManagedObjectReference getPortgroupMorForConfigSpec(
                                                        DVPortgroupConfigSpec
                                                        portgroupConfigSpec)
      throws Exception
   {
      for(ManagedObjectReference pgMor : this.portgroupMorList){
         if(vdsPortgroup.getConfigInfo(pgMor).getName().equals(
            portgroupConfigSpec.getName())){
            return pgMor;
         }
      }
      return null;
   }

   /**
    * This method gets an alternate vds uuid excepting the one provided as
    * input
    *
    * @param vdsUuid
    *
    * @return String
    *
    * @throws Exception
    */
   public String getAlternateVdsUuid(String vdsUuid)
      throws Exception
   {
      for(ManagedObjectReference vdsMor : this.vdsMorList){
         String uuid = vds.getConfig(vdsMor).getUuid();
         if(!uuid.equals(vdsUuid)){
            return uuid;
         }
      }
      return null;
   }

   /**
    * This method gets the step associate to the step name. If the step is
    * not executed, return the step and change executed to true.
    *
    * @param name
    *
    * @return Step
    */
   public Step getStep(String name)
   {
      for(Step step : stepList){
         if(step.getName().equals(name)){
            if(!step.getExecuted()){
               step.setExecuted(true);
               return step;
            }
         }
      }
      return null;
   }

   /**
    * This method adds a step to the list of steps
    *
    * @param step
    */
   public void addStep(Step step)
   {
      this.stepList.add(step);
   }

   /**
    * This method performs the basic test setup needed for the test
    *
    * @throws Exception
    */
   public void testSetup()
      throws Exception
   {
      List<Object> objIdList = this.xmlFactory.getData(getStep("testSetup").
         getData());
      initData(objIdList);
      createVds();
      //populateSelectionSets();
   }

   /**
    * This method gets all the hosts in the inventory.
    *
    * @throws Exception
    */
   public void populateHosts()
      throws Exception
   {
      this.hostMorList = host.getAllHost();
      if(this.hostMorList == null){
         log.info("There are no hosts in the inventory");
      } else {
         log.info("Found " + hostMorList.size() + " host(s) in the inventory");
      }
   }


   /**
    * This method adds hosts to the dvs with the data provided.
    *
    * @throws Exception
    */
   public void addHostsToDvs()
      throws Exception
   {
      List<Object> objList = this.xmlFactory.getData(getStep("addHostsToDvs").
               getData());
      if(objList == null || objList.isEmpty()){
         throw new Exception("No data provided for addHostsToDvs method");
      }
      if(hostMorList == null){
         populateHosts();
      }
      assertTrue((this.hostMorList != null && this.hostMorList.size()>=1),
         "Found atleast one host in the inventory", "Failed to find a host " +
            "in the inventory");
      Integer nicsNumberOfEachDvs = null;
      for(Object obj : objList){
         if(obj instanceof CustomMap){
            this.customMap = (CustomMap)obj;
         } else if(obj instanceof Integer){
             nicsNumberOfEachDvs = (Integer)obj;
         }
      }
      if(this.customMap != null){
         List<List<String>> hostVdsPnicListMap = this.customMap.
                  getHostPnicVdsList();
         assertNotNull(hostVdsPnicListMap, "Found valid dvses to add the " +
            "hosts", "Failed to find valid dvses to add the hosts");
         for(int i=0;i<this.hostMorList.size();i++){
            List<String> hostVdsConfigSpecList =
                     hostVdsPnicListMap.get(i);
            List<ManagedObjectReference> dvsMorList = new
                     ArrayList<ManagedObjectReference>();
            for(int j=0;j<hostVdsConfigSpecList.size();j++){
               ManagedObjectReference dvsMor = this.objectIdVdsMorMap.get(
                        hostVdsConfigSpecList.get(j));
               if(dvsMor == null){
                  continue;
               }
               dvsMorList.add(dvsMor);
            }
            boolean result = false;
            if(nicsNumberOfEachDvs != null){
                result = DVSUtil.addPnicsAndHostToDVS(connectAnchor,
                    hostMorList.get(i), dvsMorList, nicsNumberOfEachDvs);
            } else {
                result = DVSUtil.addFreePnicAndHostToDVS(connectAnchor,
                    hostMorList.get(i), dvsMorList);
            }
            assertTrue(result,"Successfully added " +
                     "the free pnics on " + hostMorList.get(i) +
                     "to the vdses","Failed to add " +
                     "the free pnics on " + hostMorList.get(i) +
                     "to the vdses");
         }
      }
   }

   /**
    * Method to remove specified Physical NIC(s) from desired vDS
    * If the number of pnics to be removed is specified, then removed
    * desired number of pnics. Else, all pincs in the vDS will be
    * removed.
    * @throws Exception
    */
   public void removePNicsFromvDS()
      throws Exception
   {
       List<String> objIdList = getStep("removePNicsFromvDS").getData();
       if (objIdList == null) {
           throw new Exception(
               "No objects provided for removePNicsFromvDS " + "method");
       }
       ManagedObjectReference vdsMor = null;
       Integer pNicsNumberToRemove = null;
       for (String objId : objIdList) {
           Object obj = this.xmlFactory.getData(objId);
           if (obj instanceof DVSConfigSpec) {
               vdsMor = this.objectIdVdsMorMap.get(objId);
           } else if(obj instanceof Integer){
               pNicsNumberToRemove = (Integer)obj;
           }
       }
       DVSConfigInfo dvsConfig = vds.getConfig(vdsMor);
       DistributedVirtualSwitchHostMemberConfigInfo hostMemberConfig =
           dvsConfig.getHost().get(0).getConfig();
       ManagedObjectReference hostMor =  hostMemberConfig.getHost();
       if(pNicsNumberToRemove == null){
           assertTrue(DVSUtil.removeAllUplinks(connectAnchor, hostMor,
               vdsMor), "Successfully removed all vmnics from vDs ",
               "Failed to remove all vmnics from vDs ");
       } else {
           HostProxySwitchConfig hostProxySwitchConfig =
               vds.getDVSVswitchProxyOnHost(vdsMor, hostMor);
           assertTrue(
               (hostProxySwitchConfig.getSpec() != null
                        && hostProxySwitchConfig.getSpec().getBacking() != null
                        && hostProxySwitchConfig.getSpec().getBacking() instanceof
                           DistributedVirtualSwitchHostMemberPnicBacking),
               " Failed to get HostMemberPnicBacking on vDs");
           DistributedVirtualSwitchHostMemberPnicBacking pnicBacking =
               (DistributedVirtualSwitchHostMemberPnicBacking) hostProxySwitchConfig
               .getSpec().getBacking();
           List<String> pNicsToRemove = new ArrayList<String>();
           String pnic = null;
           for(int i=0; i<pNicsNumberToRemove.intValue(); i++){
               pnic = pnicBacking.getPnicSpec().get(i).getPnicDevice();
               pNicsToRemove.add(pnic);
           }
           assertTrue(DVSUtil.removePNicsFromvDS(connectAnchor, hostMor,
               vdsMor, pNicsToRemove), "Successfully removed pnics" +
               "from VDS", "Could not remove pnics from vDS");
       }
   }
   
   
   public List<ServiceInfo> getServiceInfoList(String extensionKey)
   {
      List<ServiceInfo> serviceInfoList = (List<ServiceInfo>) serviceInfoMap.get(extensionKey);
      return serviceInfoList == null ? Collections.EMPTY_LIST
               : Collections.unmodifiableList(serviceInfoList);
   }

   /**
    * This restart vpxd process.
    *
    * @throws Exception
    */
   public void restartVpxd()throws Exception {
       VpxServices vpxService = new VpxServices(this.connectAnchor);
       OsType osType = ServiceFactory.getOsType(connectAnchor.getAboutInfo().getOsType());
       String username = null;
       String password = null;
       if (OsType.WINDOWS.equals(osType)) {
           username = TestConstants.SERVER_WIN_USERNAME;
           password = TestConstants.SERVER_WIN_PASSWORD;
        } else {
           //username = TestConstants.SERVER_LINUX_USERNAME;
           //password = TestConstants.SERVER_LINUX_PASSWORD;
           username = "Administrator@vsphere.local";
           password = "Admin!23";
        	//username = getServiceInfoList(TestConstants.VC_EXTENSION_KEY).get(0).getUserName();
            //password = getServiceInfoList(TestConstants.VC_EXTENSION_KEY).get(0).getPassword();

        }
       assertTrue(vpxService.restart(),
                "Vpxd service was restarted to reflect the changes",
                "Error restarting vpxd service");
       SessionManager.login(connectAnchor, username, password);
       Thread.sleep(RUNTIME_REFRESH_INTERVAL*10);
   }

   /**
    * This method initializes the data for input parameters
    *
    * @param objIdList
    *
    * @throws Exception
    */
   public void initData(List<Object> objIdList)
      throws Exception
   {
      List<DVSConfigSpec> dvsConfigSpecList = new ArrayList<DVSConfigSpec>();
      for(Object object : objIdList){
         if(object instanceof DVSConfigSpec){
            dvsConfigSpecList.add((DVSConfigSpec)object);
         }
      }
      if(dvsConfigSpecList.size() >= 1){
         this.dvsConfigSpecArray = dvsConfigSpecList.toArray(new
            DVSConfigSpec[dvsConfigSpecList.size()]);
      }
   }

   /**
    * This performs the most common cleanup operation of destroying all the
    * created vdses
    *
    * @throws Exception
    */
   public void testCleanup()
      throws Exception
   {
      if (createdVMsMorList != null && createdVMsMorList.size() > 0) {
          for (ManagedObjectReference vmMor : createdVMsMorList) {
              if (virtualMachine.setVMState(
                  vmMor,
                  VirtualMachinePowerState.POWERED_OFF,
                  false)) {
                  virtualMachine.destroy(vmMor);
              }
          }
      }
      if(vmMorConfigSpecMap != null){
         /*
          * Get all the vms in the map
          */
         for(ManagedObjectReference vmMor : vmMorConfigSpecMap.keySet()){
            if(!virtualMachine.getVMState(vmMor).equals(
                     VirtualMachinePowerState.POWERED_OFF)){
               assertTrue(virtualMachine.setVMState(vmMor,
                     VirtualMachinePowerState.POWERED_OFF, false),
                     "Successfully powered off the virtual machine",
                     "Failed to power off the virtual machine");
               assertTrue(virtualMachine.reconfigVM(vmMor,
                  vmMorConfigSpecMap.get(vmMor)),"Successfully reconfigured " +
                     "the vm with its original settings","Failed to " +
                        "reconfigure the vm with its original settings");
            }
         }
      }
      if(this.objectIdVdsMorMap != null){
         for(ManagedObjectReference moId : this.objectIdVdsMorMap.values()){
            assertTrue(this.vds.destroy(moId),"Successfully " +
               "destroyed the vds","Failed to destroy the vds");
         }
      }
   }
}