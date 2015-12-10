/* ************************************************************************
*
* Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
*
* ************************************************************************
*/
package com.vmware.vcqa.vim.dvs.testframework;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.io.ByteArrayInputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Map.Entry;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.vc.DVPortSelection;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupSelection;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSKeyedOpaqueData;
import com.vmware.vc.DVSKeyedOpaqueDataList;
import com.vmware.vc.DVSOpaqueDataConfigInfo;
import com.vmware.vc.DVSOpaqueDataConfigSpec;
import com.vmware.vc.DVSSelection;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.HostDVSPortData;
import com.vmware.vc.HostMemberSelection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.SelectionSet;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.i18n.I18NDataProvider;
import com.vmware.vcqa.i18n.I18NDataProviderConstants;
import com.vmware.vcqa.internal.vim.InternalServiceInstance;
import com.vmware.vcqa.internal.vim.dvs.InternalDistributedVirtualSwitchManager;
import com.vmware.vcqa.internal.vim.dvs.InternalHostDistributedVirtualSwitchManager;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ServiceInstance;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * This class represents the subsystem for opaque channel data operations.It
 * encompasses all possible states and transitions in any scenario (positive/
 * negative/I18n) with respect to opaque channel
 *
 * @author sabesanp
 *
 */
public class OpaqueChannelTestFramework
{

   private DistributedVirtualSwitch vds = null;
   private Folder folder = null;
   private DistributedVirtualPortgroup vdsPortgroup = null;
   private ManagedObjectReference vdsMor = null;
   private HostSystem host = null;
   private VirtualMachine virtualMachine = null;
   private SelectionSet[] selectionSet = null;
   private DVSOpaqueDataConfigSpec[] opaqueDataSpec = null;
   private InternalDistributedVirtualSwitchManager vdsMgr = null;
   private ServiceInstance serviceInstance = null;
   private ManagedObjectReference vdsMgrMor = null;
   private ManagedObjectReference dcMor = null;
   private DataFactory xmlFactory = null;
   private DVSConfigSpec[] dvsConfigSpecArray = null;
   private List<ManagedObjectReference> vdsMorList = null;
   private List<ManagedObjectReference> portgroupMorList = null;
   private List<ManagedObjectReference> hostMorList = null;
   private ManagedObjectReference hostDVSMgrMor = null;
   private InternalHostDistributedVirtualSwitchManager internalHostDVSMgr =
      null;
   private List<Step> stepList = null;
   private CustomMap customMap = null;
   private Map<ManagedObjectReference,List<ManagedObjectReference>>
      vdsPortgroupMorMap = null;
   private Map<ManagedObjectReference,List<String>>
      vdsPortKeyMap = new HashMap<ManagedObjectReference,List<String>>();
   private Map<ManagedObjectReference,List<String>>
   vdsPortgroupPortKeyMap = new HashMap<ManagedObjectReference,List<String>>();
   private static final Logger log = LoggerFactory.getLogger(
      OpaqueChannelTestFramework.class);
   private ConnectAnchor connectAnchor = null;
   private Boolean isRuntime = null;
   private List<DVSOpaqueDataConfigInfo> dvsOpaqueDataList = null;
   private I18NDataProvider iDataProvider = null;
   private List<String> keys = null;
   private List<String> opaqueData = null;
   private Map<ManagedObjectReference,VirtualMachineConfigSpec>
      vmMorConfigSpecMap = null;
   private Map<String, ManagedObjectReference> vdsUuidMorMap = null;

   /**
    * Constructor
    *
    * @param connectAnchor
    * @param xmlFilePath
    *
    * @throws MethodFault, Exception
    */
   public OpaqueChannelTestFramework(ConnectAnchor connectAnchor,
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
    * This method invokes the update opaque channel api after retrieving the
    * data for this operation from the list of steps
    *
    * @throws Exception
    */
   public void updateOpaqueChannel()
      throws Exception
   {
      /*
       * Initialize data if explicitly passed from the data file. If not,
       * use the data that was already populated.
       */
      init("updateOpaqueChannel");
      if(this.isRuntime == null){
         this.isRuntime = false;
      }
      assertTrue(vdsMgr.updateOpaqueData(vdsMgrMor, selectionSet,
         opaqueDataSpec,isRuntime),"Successfully updated the opaque data",
            "Failed to update the opaque data and the task did not complete " +
               "successfully");
   }


   /**
    * This method fetches the opaque data on the selection sets as computed
    * from the data file
    *
    * @throws Exception
    */
   public void fetchOpaqueData()
      throws Exception
   {
      init("fetchOpaqueData");
      if(isRuntime == null){
         isRuntime = false;
      }
      dvsOpaqueDataList = vdsMgr.fetchOpaqueData(this.vdsMgrMor, selectionSet,
         isRuntime);
   }

   /**
    * This method encompasses the verification for the "updateOpaqueChannel"
    * api.
    *
    * @param selectionSet, an array of selection sets
    * @param opaqueDataSpec, the config spec for the opaque data
    *
    * @return boolean true if the opaque channel data returned from server
    *                 matched the data sent from the client, false otherwise
    *
    * @throws Exception
    */
   public void verifyUpdateOpaqueChannel()
      throws Exception
   {
      boolean verifyOpaqueChannel = true;
      /*
       * Fetch the opaque data from the vc server
       */
      fetchOpaqueData();
      for(SelectionSet sel : selectionSet){
         List<DVSOpaqueDataConfigInfo> opaqueDataConfigInfoList =
            getOpaqueDataFromSelectionSet(sel, dvsOpaqueDataList);
         for(DVSOpaqueDataConfigInfo dvsOpaqueDataConfigInfo :
            opaqueDataConfigInfoList){
            DVSKeyedOpaqueData[] actualkeyedOpaqueData =
               com.vmware.vcqa.util.TestUtil.vectorToArray(dvsOpaqueDataConfigInfo.getKeyedOpaqueData(), com.vmware.vc.DVSKeyedOpaqueData.class);
            List<DVSKeyedOpaqueData> inheritedOpaqueData =
               getInheritedOpaqueData(Arrays.asList(actualkeyedOpaqueData));
            //int expectedSize = opaqueDataSpec.length - countOperations(
               //opaqueDataSpec, TestConstants.HOSTCONFIG_CHANGEOPERATION_REMOVE)
                  //+ inheritedOpaqueData.size() -
                     //countInheritedFlagsInSpec(this.opaqueDataSpec);
            int expectedSize = computeEffectiveExpectedSize(
                     inheritedOpaqueData,null);
            /*
             * If the size of the actual opaque data is not equal to expected
             * size, it is a sure case of a defect. Assert here so that the
             * clients will be notified of this error. The objective of this
             * method is to verify whether the updated opaque data is found
             * on the server.
             */
            assertTrue(actualkeyedOpaqueData.length == expectedSize,"The " +
               "expected and actual sizes are equal","The actual and " +
               "expected sizes are not equal");
            /*
             * Verify that the key and opaque data match
             */
            boolean found;
            for(DVSOpaqueDataConfigSpec opaqueData : opaqueDataSpec){
               found = false;
               if(opaqueData.getOperation().equals(TestConstants.
                  HOSTCONFIG_CHANGEOPERATION_REMOVE)){
                  continue;
               }
               if(opaqueData.getKeyedOpaqueData().isInherited() == true){
                  continue;
               }
               for(DVSKeyedOpaqueData keyOpaqueData : actualkeyedOpaqueData){
                  found = compareOpaqueDataSpec(opaqueData.getKeyedOpaqueData(),
                           keyOpaqueData);
                  if(found){
                     break;
                  }
               }
               verifyOpaqueChannel &= found;
            }
         }
      }
      verifyOpaqueChannel &= verifyOpaqueChannelOnHost();
      assertTrue(verifyOpaqueChannel,"Successfully verified the existence " +
         "of opaque channel data", "The opaque channel data returned from " +
            "the server is not as expected");
   }


   /**
    * This method returns a list of keyed opaque data that are inherited from
    * the parent. Examples, port inherits opaque data from the parent dvs.
    * Portgroup inherits opaque data from the parent dvs.
    *
    * @param opaqueDataConfigInfo
    *
    * @return List<DVSKeyedOpaqueData>
    *
    * @throws Exception
    */
   public List<DVSKeyedOpaqueData> getInheritedOpaqueData(
      List<DVSKeyedOpaqueData> opaqueData)
      throws Exception
   {
      List<DVSKeyedOpaqueData> inheritedKeyedOpaqueDataList = new
         ArrayList<DVSKeyedOpaqueData>();
      for(DVSKeyedOpaqueData keyedOpaqueData : opaqueData){
         if(keyedOpaqueData.isInherited() == true){
            inheritedKeyedOpaqueDataList.add(keyedOpaqueData);
         }
      }
      return inheritedKeyedOpaqueDataList;
   }

   /**
    * This method verifies the opaque channel properties on the host
    *
    * @return boolean
    *
    * @throws Exception
    */
   public boolean verifyOpaqueChannelOnHost()
      throws Exception
   {
      if(this.hostMorList == null){
         populateHosts();
      }
      /*
       * If there are no hosts throw an exception
       */
      assertNotNull(this.hostMorList, "Found hosts in the inventory",
         "Failed to find a host in the inventory");
      List<ManagedObjectReference> vmMorList = host.getVMs(this.hostMorList.
            get(0), VirtualMachinePowerState.POWERED_OFF);
      assertTrue(vmMorList != null && vmMorList.size()>=1,"Found atleast " +
         "one virtual machine in the inventory","Failed to find a virtual " +
            "machine in the inventory");
      vmMorConfigSpecMap = new HashMap<ManagedObjectReference,
         VirtualMachineConfigSpec>();
      ManagedObjectReference vmMor = vmMorList.get(0);
      ConnectAnchor hostConnectAnchor = DVSUtil.
         getHostConnectAnchor(connectAnchor, this.hostMorList.get(0));
      assertNotNull(hostConnectAnchor,"Obtained the connect anchor to hostd",
         "Failed to obtain a connect anchor to hostd");
      InternalServiceInstance msi = new
         InternalServiceInstance(hostConnectAnchor);
      this.hostDVSMgrMor = msi.getInternalServiceInstanceContent().
         getHostDistributedVirtualSwitchManager();
      this.internalHostDVSMgr = new
         InternalHostDistributedVirtualSwitchManager(hostConnectAnchor);
      assertNotNull(this.hostDVSMgrMor,"Successfully retrieved the host dvs" +
         "manager mor" ,"Failed to retrieve the host dvs manager");
      DVPortSelection portSelection = null;
      List<String> portKeys = null;
      String portKey = null;
      String portgroupKey = null;
      int existingSize = 0;
      /*
       * Get the list of all the ports before this step and pass it here
       * instead of null
       */
      boolean verifyOpaqueChannel = true;
      for(SelectionSet sel : this.selectionSet){
         /*
          * If selection set is a port selection, collect all the port keys
          */
         if(!(sel instanceof HostMemberSelection)){
            String uuid = null;
            ManagedObjectReference currVdsMor = null;
            if(sel instanceof DVPortgroupSelection){
               DVPortgroupSelection pgSelection = (DVPortgroupSelection)sel;
               portgroupKey = com.vmware.vcqa.util.TestUtil.vectorToArray(pgSelection.getPortgroupKey(), java.lang.String.class)[0];
               uuid = pgSelection.getDvsUuid();
               currVdsMor = vdsUuidMorMap.get(uuid);
               ManagedObjectReference portgroupMor = vdsPortgroup.
                  getPortgroupMor(currVdsMor,portgroupKey);
               List<DistributedVirtualPort> ports = vdsPortgroup.
                  getPorts(portgroupMor);
               assertTrue(ports != null && ports.size()>=1,"Could not " +
                  "find any ports inside the portgroup");
               portKey = ports.get(0).getKey();
            }else if(sel instanceof DVPortSelection){
               DVPortSelection portSel = (DVPortSelection)sel;
               uuid = portSel.getDvsUuid();
               currVdsMor = vdsUuidMorMap.get(uuid);
               portKey = com.vmware.vcqa.util.TestUtil.vectorToArray(portSel.getPortKey(), java.lang.String.class)[0];
               portgroupKey = null;
               if(!isPortInVds(currVdsMor, portKey)){
                  if(this.vdsPortgroupPortKeyMap != null){
                     for(Entry<ManagedObjectReference,List<String>> e :
                        vdsPortgroupPortKeyMap.entrySet()){
                        for(String s : e.getValue()){
                           if(s.equals(portKey)){
                              portgroupKey = vdsPortgroup.getKey(e.getKey());
                              break;
                           }
                        }
                     }
                  }
               }
            }else{
               DVSSelection vdsSel = (DVSSelection)sel;
               uuid = vdsSel.getDvsUuid();
               currVdsMor = vdsUuidMorMap.get(uuid);
               portKey = vds.getFreeStandaloneDVPortKey(currVdsMor, null);
            }
            List<DVSOpaqueDataConfigInfo> opaqueDataConfigInfoList =
               getOpaqueDataFromSelectionSet(sel, dvsOpaqueDataList);
            List<DVSKeyedOpaqueData> inheritedOpaqueData = new
               ArrayList<DVSKeyedOpaqueData>();
            for(DVSOpaqueDataConfigInfo opaqueDataConfigInfo :
               opaqueDataConfigInfoList){
               DVSKeyedOpaqueData[] actualkeyedOpaqueData =
                  com.vmware.vcqa.util.TestUtil.vectorToArray(opaqueDataConfigInfo.getKeyedOpaqueData(), com.vmware.vc.DVSKeyedOpaqueData.class);
               inheritedOpaqueData.addAll(getInheritedOpaqueData(Arrays.
                  asList(actualkeyedOpaqueData)));
            }
            DVSKeyedOpaqueData[] existingData = getOpaqueDataOnPort(uuid,
                     portKey);
            VirtualMachineConfigSpec orig = DVSUtil.reconfigVM(vmMor,
               currVdsMor,connectAnchor, portKey, portgroupKey);
            if(!vmMorConfigSpecMap.containsKey(vmMor)){
               vmMorConfigSpecMap.put(vmMor, orig);
            }
            assertTrue(virtualMachine.powerOnVM(vmMor,hostMorList.get(0),
               false),"Successfully powered on the vm","Failed to power " +
                  "on the vm");
            HostDVSPortData[] portData = this.internalHostDVSMgr.
               fetchPortState(hostDVSMgrMor,uuid, new String[]{portKey}, null);
            assertTrue(portData != null && portData.length == 1,
               "Could not find any port data on the host with port key : "
                  + portKey);
            DVSKeyedOpaqueDataList keyedOpaqueDataList = portData[0].
               getKeyedOpaqueDataList();
            DVSKeyedOpaqueData[] actualkeyedOpaqueData = null;
            if(keyedOpaqueDataList != null){
               actualkeyedOpaqueData = com.vmware.vcqa.util.TestUtil.
                  vectorToArray(portData[0].getKeyedOpaqueDataList().getKeyedOpaqueData(), com.vmware.vc.DVSKeyedOpaqueData.class);
               for(DVSKeyedOpaqueData opData : actualkeyedOpaqueData){
                  log.info("Key :  " + opData.getKey());
                  log.info("Data : " + opData.getOpaqueData());
               }
            }
            int expectedSize = computeEffectiveExpectedSize(
                     inheritedOpaqueData,existingData);
            /*
            if(existingData != null && existingData.length > 0){
               DVSKeyedOpaqueData[] data = getExistingData(existingData,
                                    inheritedOpaqueData.toArray(new
                                    DVSKeyedOpaqueData[
                                    inheritedOpaqueData.size()]));
               expectedSize += data.length;
            }*/
            if(this.isRuntime){
               expectedSize = 0;
            }
            /*
             * If the size of the actual opaque data is not equal to
             * expected size, it is a sure case of a defect. Assert here
             * so that the clients will be notified of this error. The
             * objective of this method is to verify whether the updated
             * opaque data is found on the server.
             */
            if(expectedSize == 0){
               assertTrue(actualkeyedOpaqueData == null ||
                  actualkeyedOpaqueData.length == existingSize,"There was " +
                     "no keyed opaque data found on the entity","There " +
                        "was keyed opaque data found on the entity");
            } else {
               if(actualkeyedOpaqueData != null){
                  assertTrue(actualkeyedOpaqueData.length == expectedSize,
                     "The expected and actual sizes are equal","The actual " +
                        "and expected sizes are not equal");
               }
            }
            /*
             * Verify that the key and opaque data match
             */
            boolean found;
            for(DVSOpaqueDataConfigSpec opaqueData : opaqueDataSpec){
               found = false;
               if(opaqueData.getOperation().equals(TestConstants.
                  HOSTCONFIG_CHANGEOPERATION_REMOVE)){
                  continue;
               }
               if(opaqueData.getKeyedOpaqueData().isInherited() == true){
                  continue;
               }
               if(actualkeyedOpaqueData != null && !this.isRuntime){
                  for(DVSKeyedOpaqueData keyOpaqueData :
                     actualkeyedOpaqueData){
                     found = compareOpaqueDataSpec(opaqueData.
                              getKeyedOpaqueData(),keyOpaqueData);
                     if(found){
                        break;
                     }
                  }
               }else{
                  found = true;
                  break;
               }
               verifyOpaqueChannel &= found;
            }
            assertTrue(virtualMachine.powerOffVM(vmMor),"Successfully " +
               "powered off the vm","Failed to power off the vm");
            assertTrue(virtualMachine.reconfigVM(vmMor, orig),
               "Successfully reconfigured the vm to connect to the " +
               "port","Failed to reconfigure the vm to connect to " +
               "the port");
         }
      }
      return verifyOpaqueChannel;
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
      criteria.getPortgroupKey().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(portgroupKeys.toArray(new
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
    * This method fetches the opaque data on a port
    *
    * @param vdsUuid
    * @param portKey
    *
    * @return DVSKeyedOpaqueData[]
    *
    * @throws Exception
    */
   public DVSKeyedOpaqueData[] getOpaqueDataOnPort(String vdsUuid,
                                                 String portKey)
      throws Exception
   {
      HostDVSPortData[] portData = this.internalHostDVSMgr.
      fetchPortState(hostDVSMgrMor,vdsUuid, new String[]{portKey}, null);
      DVSKeyedOpaqueData[] actualkeyedOpaqueData = null;
      if(portData != null){
         DVSKeyedOpaqueDataList keyedOpaqueDataList = portData[0].
                  getKeyedOpaqueDataList();
         if(keyedOpaqueDataList != null){
            actualkeyedOpaqueData = com.vmware.vcqa.util.TestUtil.
                     vectorToArray(portData[0].getKeyedOpaqueDataList().getKeyedOpaqueData(), com.vmware.vc.DVSKeyedOpaqueData.class);
         }
      }
      return actualkeyedOpaqueData;
   }


   /**
    * This method computes the effective expected size for opaque data
    *
    *
    * @param List<DVSKeyedOpaqueData> list of inherited opaque data
    *
    * @return int, the effective expected size
    */
   public int computeEffectiveExpectedSize(List<DVSKeyedOpaqueData>
                                           inheritedOpaqueDataList,
                                           DVSKeyedOpaqueData[]
                                           existingData)
      throws Exception
   {
      int count = 0;
      Map<String,Integer> countMap = new HashMap<String,Integer>();
      if(existingData != null && existingData.length > 0 ){
         for(DVSKeyedOpaqueData data : existingData){
            countMap.put(data.getKey(), 1);
         }
      }
      for(DVSOpaqueDataConfigSpec opaqueConfigSpec : opaqueDataSpec){
         DVSKeyedOpaqueData opaqueData = opaqueConfigSpec.getKeyedOpaqueData();
         if(opaqueConfigSpec.getOperation().equals(TestConstants.
                  HOSTCONFIG_CHANGEOPERATION_REMOVE)){
            countMap.put(opaqueData.getKey(),0);
         } else {
            countMap.put(opaqueData.getKey(),1);
         }
      }
      for(DVSKeyedOpaqueData inheritedkeyOpaqueData :
         inheritedOpaqueDataList){
         countMap.put(inheritedkeyOpaqueData.getKey(),1);
      }
      /*
       * Compute the total count of all the entities
       */
      for(Map.Entry<String, Integer> entry : countMap.entrySet()){
         count += entry.getValue();
      }
      return count;
   }

   /**
    * This method counts the number of true inherited flags in the opaque
    * data config spec array
    *
    * @param dvsOpaqueDataConfigSpecArray
    *
    * @return int
    *
    * @throws Exception
    */
   public int countInheritedFlagsInSpec(DVSOpaqueDataConfigSpec[]
                                        dvsOpaqueDataConfigSpecArray)
      throws Exception
   {
      int numInheritedFlags = 0;
      for(DVSOpaqueDataConfigSpec opaqueDataConfigSpec :
          dvsOpaqueDataConfigSpecArray){
         if(opaqueDataConfigSpec.getKeyedOpaqueData().isInherited() == true){
            numInheritedFlags++;
         }
      }
      return numInheritedFlags;
   }


   /**
    * This method counts the number of operations in the specified object.
    *
    * @param opaqueDataSpec, array of opaque data config spec
    *
    * @return int, count of the specified operation type
    *
    * @throws Exception
    */
   public int countOperations(DVSOpaqueDataConfigSpec[] opaqueDataSpec,
                              String operation)
      throws Exception
   {
      int numOperations = 0;
      for(DVSOpaqueDataConfigSpec data : opaqueDataSpec){
         if(data.getOperation().equals(operation)){
            numOperations++;
         }
      }
      return numOperations;
   }

   /**
    * This method gets the opaque data for the mentioned keys
    *
    * @param keys
    * @param dvsOpaqueData
    *
    * @return List<DVSOpaqueDataConfigInfo>
    *
    * @throws Exception
    */
   public List<DVSOpaqueDataConfigInfo> getOpaqueDataForKeys(String[] keys,
                                List<DVSOpaqueDataConfigInfo> dvsOpaqueData)
      throws Exception
   {
      List<DVSOpaqueDataConfigInfo> opaqueDataConfigInfoList = new
         ArrayList<DVSOpaqueDataConfigInfo>();
      List<DVSOpaqueDataConfigInfo> dvsOpaqueDataList = dvsOpaqueData;
      for(DVSOpaqueDataConfigInfo opaqueDataConfigInfo : dvsOpaqueData){
         for(String key : keys){
            if(key.equals(opaqueDataConfigInfo.getPortgroupKey()) ||
               key.equals(opaqueDataConfigInfo.getPortKey())){
               opaqueDataConfigInfoList.add(opaqueDataConfigInfo);
               //dvsOpaqueData.remove(opaqueDataConfigInfo);
               break;
            }
         }
      }
      return opaqueDataConfigInfoList;
   }

   /**
    * This method fetches the opaque data for the selection set provided as
    * input
    *
    * @param selectionSet
    * @param dvsOpaqueDataList
    *
    * @return List<DVSOpaqueDataConfigInfo>
    *
    * @throws Exception
    */
   public List<DVSOpaqueDataConfigInfo> getOpaqueDataFromSelectionSet(
                                SelectionSet selectionSet,
                                List<DVSOpaqueDataConfigInfo> dvsOpaqueDataList)
      throws Exception
   {
      List<DVSOpaqueDataConfigInfo> opaqueDataConfigInfoList = new
         ArrayList<DVSOpaqueDataConfigInfo>();
      DVSSelection dvsSet = selectionSet instanceof DVSSelection ?
         (DVSSelection) selectionSet : null;
      DVPortgroupSelection portgroupSet = selectionSet instanceof
         DVPortgroupSelection ? (DVPortgroupSelection) selectionSet : null;
      DVPortSelection portSet = selectionSet instanceof
         DVPortSelection ? (DVPortSelection) selectionSet : null;
      HostMemberSelection hostSet = selectionSet instanceof
         HostMemberSelection ? (HostMemberSelection) selectionSet : null;
      if(portgroupSet != null){
         opaqueDataConfigInfoList.addAll(getOpaqueDataForKeys(com.vmware.vcqa.util.TestUtil.
            vectorToArray(portgroupSet.getPortgroupKey(), java.lang.String.class),dvsOpaqueDataList));
      } else if(portSet != null){
         opaqueDataConfigInfoList.addAll(getOpaqueDataForKeys(com.vmware.vcqa.util.TestUtil.
            vectorToArray(portSet.getPortKey(), java.lang.String.class),dvsOpaqueDataList));
      } else {
         for(DVSOpaqueDataConfigInfo opaqueDataConfigInfo : dvsOpaqueDataList){
            if(dvsSet != null){
               if(opaqueDataConfigInfo.getDvsUuid().
                  equals(dvsSet.getDvsUuid())){
                  opaqueDataConfigInfoList.add(opaqueDataConfigInfo);
                  break;
               }
            }
            if(hostSet != null){
               if(opaqueDataConfigInfo.getHost().equals(hostSet.getHost())){
                  opaqueDataConfigInfoList.add(opaqueDataConfigInfo);
                  break;
               }
            }
         }
      }
      return opaqueDataConfigInfoList;
   }

   /**
    * This method compares the expected opaque data and the actual opaque
    * data returned from the server.
    *
    * @param expectedOpaqueData
    * @param actualOpaqueData
    *
    * @return boolean, true if the key and the opaque data value are identical,
    *                  false otherwise
    *
    * @throws Exception
    */
   public boolean compareOpaqueDataSpec(DVSKeyedOpaqueData expectedOpaqueData,
                                        DVSKeyedOpaqueData actualOpaqueData)
      throws Exception
   {
      boolean isEqual = false;
      isEqual = expectedOpaqueData.getKey().equals(actualOpaqueData.getKey());
      if(expectedOpaqueData.getOpaqueData() != null){
    	  // kiri FIXME Aug 22, 2011 we shall compare byte arrays directly.
//        String expectedContent = (String)expectedOpaqueData.getOpaqueData().
//           getContent();
   	  byte[] expectedByteArray = expectedOpaqueData.getOpaqueData();
//        byte[] expectedByteArray = expectedContent.getBytes();
        log.info("Length of expected byte array is: {}", expectedByteArray.length);
//        ByteArrayInputStream actualContentStream = (ByteArrayInputStream)
//                 actualOpaqueData.getOpaqueData().getContent();
        byte[] actual = actualOpaqueData.getOpaqueData();
//        int length = actualOpaqueData.getOpaqueData().available();
        log.info("Length of actual byte array is: {}", actual.length);
        
//        actualContentStream.read(buff);
//        String actualContent = new String(buff);
        log.info("The expected content = " + Arrays.toString(expectedByteArray));
        log.info("The actual content   = " + Arrays.toString(actual));
        isEqual &= Arrays.equals(expectedByteArray, actual);
      } else {
         isEqual &= (actualOpaqueData.getOpaqueData() == null);
      }
      return isEqual;
   }

   /**
    * This method creates the vds
    *
    * @throws Exception
    */
   public void createVds()
      throws Exception
   {
      init("createVds");
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
      }
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
    * This method executes the I18N test
    *
    * @throws Exception
    */
   public void executeI18NTest()
      throws Exception
   {
      this.keys = iDataProvider.getData(
         I18NDataProviderConstants.MULTI_LANG_KEY,
            I18NDataProviderConstants.MAX_STRING_LENGTH);
      this.opaqueData  = iDataProvider.getData(
         I18NDataProviderConstants.MULTI_LANG_KEY,
            I18NDataProviderConstants.MAX_STRING_LENGTH);
      this.opaqueDataSpec = new DVSOpaqueDataConfigSpec[1];
      /*
       * Populate all the selection sets prior to this method call
       */
      for(String key : keys){
         this.opaqueDataSpec[0] = new DVSOpaqueDataConfigSpec();
         this.opaqueDataSpec[0].setOperation(TestConstants.CONFIG_SPEC_ADD);
         DVSKeyedOpaqueData keyedOpaqueData = new DVSKeyedOpaqueData();
         keyedOpaqueData.setKey(key);
         keyedOpaqueData.setOpaqueData(null);
         this.opaqueDataSpec[0].setKeyedOpaqueData(keyedOpaqueData);
         this.updateOpaqueChannel();
         this.verifyUpdateOpaqueChannel();
         this.opaqueDataSpec[0].setOperation(TestConstants.
            CONFIG_SPEC_REMOVE);
         this.updateOpaqueChannel();
      }
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
      populateSelectionSets();
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
      init("addPortgroups");
      this.vdsPortgroupMorMap = new HashMap<ManagedObjectReference,
         List<ManagedObjectReference>>();
      this.portgroupMorList = new ArrayList<ManagedObjectReference>();
      List<ManagedObjectReference> pgMorList = null;
      if(this.customMap != null){
         for(DVSConfigSpec vdsConfigSpec : this.customMap.getVdsPortgroupMap().
            keySet()){
            ManagedObjectReference currentVdsMor = null;
            /*
             * Pick the mor in the list which matches the config spec
             */
            for(ManagedObjectReference vdsMor : this.vdsMorList){
               if(vds.getConfig(vdsMor).getName().equals(
                  vdsConfigSpec.getName())){
                  currentVdsMor = vdsMor;
                  break;
               }
            }
            if(currentVdsMor != null){
               List<DVPortgroupConfigSpec> portgroupConfigSpecList = this.
                  customMap.getVdsPortgroupMap().get(vdsConfigSpec);
               pgMorList = vds.addPortGroups(currentVdsMor,
                  portgroupConfigSpecList.toArray(new
                     DVPortgroupConfigSpec[portgroupConfigSpecList.size()]));
               if(pgMorList != null && pgMorList.size() >=1 ){
                  this.portgroupMorList.addAll(pgMorList);
                  this.vdsPortgroupMorMap.put(currentVdsMor, pgMorList);
               }
            }
         }
         if(this.portgroupMorList != null){
            populatePortgroupKeyMap();
         }
      } else {
         log.error("There is no input provided for adding the portgroups");
      }
   }

   /**
    * This method populates all the different selection sets
    *
    * @throws Exception
    */
   public void populateSelectionSets()
      throws Exception
   {
      List<DVSSelection> dvsSelectionSetList =  new ArrayList<DVSSelection>();
      List<HostMemberSelection> hostMemberSelectionSetList = new
         ArrayList<HostMemberSelection>();
      List<DVPortgroupSelection> portgroupSelectionSetList = new
         ArrayList<DVPortgroupSelection>();
      List<DVPortSelection> portSelectionSetList = new
         ArrayList<DVPortSelection>();
      List<SelectionSet> finalSelectionSet = new ArrayList<SelectionSet>();
      /*
       * Collect all the different types of selection sets in the data
       */
      for(SelectionSet selSet : selectionSet){
         if(selSet instanceof DVSSelection){
            dvsSelectionSetList.add((DVSSelection)selSet);
         }
         if(selSet instanceof HostMemberSelection){
            hostMemberSelectionSetList.add((HostMemberSelection)selSet);
         }
         if(selSet instanceof DVPortgroupSelection){
            portgroupSelectionSetList.add((DVPortgroupSelection)selSet);
         }
         if(selSet instanceof DVPortSelection){
            portSelectionSetList.add((DVPortSelection)selSet);
         }
      }
      /*
       * Populate these selection sets based on the data provided
       */
      populateVdsSelectionSet(dvsSelectionSetList);
      /*
       * Tear down the selection set array and rebuild it
       */
      populateHostMemberSelectionSet(hostMemberSelectionSetList);
      populatePortgroupSelectionSet(portgroupSelectionSetList);
      if(portSelectionSetList.size() >=1){
         populatePortSelectionSet(portSelectionSetList);
      }
      finalSelectionSet.addAll(dvsSelectionSetList);
      finalSelectionSet.addAll(hostMemberSelectionSetList);
      finalSelectionSet.addAll(portgroupSelectionSetList);
      finalSelectionSet.addAll(portSelectionSetList);
      selectionSet = finalSelectionSet.toArray(new
         SelectionSet[finalSelectionSet.size()]);
   }

   /**
    * This method populated the host member selection set from the data
    * provided
    *
    * @param hostMemberSelectionList
    *
    * @throws Exception
    */
   public void populateHostMemberSelectionSet(List<HostMemberSelection>
                                              hostMemberSelectionList)
      throws Exception
   {
      if(hostMemberSelectionList.size() >= 1){
         int i=0;
         if(this.hostMorList == null){
            populateHosts();
         }
         if(this.customMap != null){
            List<DVSConfigSpec> vdsConfigSpec = this.customMap.
               getHostVdsConfigSpec();
            HostMemberSelection hostMemberSelection = null;
            if(vdsConfigSpec != null && vdsConfigSpec.size()>=1){
               for(int k=0;k<hostMorList.size();k++){
                  for(int j=0;j<vdsConfigSpec.size();j++){
                     ManagedObjectReference vdsMor =
                        getVdsMorForConfigSpec(vdsConfigSpec.get(j));
                     if(vds.getHostMemberConnectedToDVSwitch(vdsMor,
                        this.hostMorList.get(k)) != null){
                        String vdsUuid = vds.getConfig(vdsMor).getUuid();
                        if(i == hostMemberSelectionList.size()){
                           break;
                        }
                        hostMemberSelection =
                           hostMemberSelectionList.get(i);
                        if(this.customMap.getHostMemberOutVds() != null &&
                           this.customMap.getHostMemberOutVds() == true){
                           vdsUuid = getAlternateVdsUuid(vdsUuid);
                        }
                        hostMemberSelection.setDvsUuid(vdsUuid);
                        hostMemberSelection.setHost(this.hostMorList.get(k));
                        i++;
                     }
                  }
               }
            }
         }else {
            /*
             * The vds config spec is not specified, there is a possibility
             * that the negative test data contains some invalid mors /
             * invalid vds uuids
             */
            for(HostMemberSelection hostMember : hostMemberSelectionList){
               if(hostMember.getDvsUuid() == null){
                  /*
                   * Fill in some valid vds uuid
                   */
                  hostMember.setDvsUuid(vds.getConfig(this.vdsMorList.
                     get(0)).getUuid());
               }
               if(hostMember.getHost() == null){
                  hostMember.setHost(this.hostMorList.get(0));
               }
            }
         }
      }
   }

   /**
    * This method populate the dvs selection set based on the data provided
    *
    * @param dvsSelectionList
    *
    * @throws Exception
    */
   public void populateVdsSelectionSet(List<DVSSelection> dvsSelectionList)
      throws Exception
   {
      if(dvsSelectionList.size() >= 1){
         for(int i=0;i<dvsSelectionList.size();i++){
            DVSSelection dvsSelection = dvsSelectionList.get(i);
            if(this.vdsMorList != null && i<this.vdsMorList.size()){
               String vdsUuid = vds.getConfig(this.vdsMorList.get(i)).getUuid();
               /*
                * Set the vds uuid only if it was unset. If it was already set,
                * it might have come from the data file directly.
                */
               if(dvsSelection.getDvsUuid() == null){
                  dvsSelection.setDvsUuid(vdsUuid);
               }
            } else {
               log.info("There are not enough number of vdses to " +
                  "populate the dvs selection set");
               break;
            }
         }
      }
   }

   /**
    * This method populates the portgroup selection set based on the
    * data provided.
    *
    * @param vdsPortgroupSelectionList
    *
    * @throws Exception
    */
   public void populatePortgroupSelectionSet(List<DVPortgroupSelection>
                                             vdsPortgroupSelectionList)
      throws Exception
   {
      /*
       * Get the list of all portgroup selections. The size of this list must
       * be equal to the number of selection sets mentioned in the data file.
       */
      if(this.customMap != null){
         List<List<DVPortgroupConfigSpec>> portgroupConfigSpecSelectionList =
            this.customMap.getDvPortgroupSelectionSet();
         if(portgroupConfigSpecSelectionList != null &&
            portgroupConfigSpecSelectionList.size() ==
            vdsPortgroupSelectionList.size()){
            /*
             * This is a positive case. Handle it
             */
            int i=0;
            for(List<DVPortgroupConfigSpec> dvPortgroupConfigSpecList :
               portgroupConfigSpecSelectionList){
               DVPortgroupSelection pgSelection = vdsPortgroupSelectionList.
                  get(i);
               /*
                * All the portgroups need to be a part of the same vds. If
                * they are part of the same vds, the name will be unique.
                */
               List<String> keys = new ArrayList<String>();
               String vdsUuid = null;
               for(DVPortgroupConfigSpec pgConfigSpec :
                  dvPortgroupConfigSpecList){
                  ManagedObjectReference pgMor = getPortgroupMorForConfigSpec(
                     pgConfigSpec);
                  vdsUuid = vds.getConfig(vdsPortgroup.getConfigInfo(pgMor).
                     getDistributedVirtualSwitch()).getUuid();
                  keys.add(vdsPortgroup.getKey(pgMor));
               }
               if(com.vmware.vcqa.util.TestUtil.vectorToArray(pgSelection.getPortgroupKey(), java.lang.String.class) == null){
                  pgSelection.getPortgroupKey().clear();
                  pgSelection.getPortgroupKey().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(keys.toArray(new
                     String[keys.size()])));
               }
               if(vdsUuid != null && pgSelection.getDvsUuid()== null){
                  if(this.customMap.getPortgroupKeysOutVds() != null &&
                     this.customMap.getPortgroupKeysOutVds() == true){
                     pgSelection.setDvsUuid(getAlternateVdsUuid(vdsUuid));
                  } else {
                     pgSelection.setDvsUuid(vdsUuid);
                  }
               }
               i++;
            }
         }
      } else {
         /*
          * There is a possibility that the selection set might contain negative
          * values.
          */
         for(DVPortgroupSelection portgroupSelection :
            vdsPortgroupSelectionList){
            if(portgroupSelection.getDvsUuid() == null){
               portgroupSelection.setDvsUuid(vds.getConfig(
                  this.vdsMorList.get(0)).getUuid());
            }
            if(com.vmware.vcqa.util.TestUtil.vectorToArray(portgroupSelection.getPortgroupKey(), java.lang.String.class) == null){
               /*
                * Fill in with valid portgroup keys
                */
               List<ManagedObjectReference> pgMorList = vds.getPortgroup(
                  vdsMorList.get(0));
               List<String> portgroupKeys = new ArrayList<String>();
               for(ManagedObjectReference pgMor : pgMorList){

               }
               if(portgroupKeys != null && portgroupKeys.size() >= 1){
                  portgroupSelection.getPortgroupKey().clear();
                  portgroupSelection.getPortgroupKey().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(portgroupKeys.toArray(new
                     String[portgroupKeys.size()])));
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
    * This method populates the port selection set from the data provided.
    *
    * @param portSelectionList
    *
    * @throws Exception
    */
   public void populatePortSelectionSet(List<DVPortSelection> portSelectionList)
      throws Exception
   {
      if(this.customMap != null && this.customMap.getPortSelectionMap()
         != null){
         Map<Object,List<Integer>> portSelectionMap = this.customMap.
         getPortSelectionMap();
         Set<Object> portSelectionKeys = portSelectionMap.keySet();
         List<String> portKeys = null;
         List<String> selectedKeys = new ArrayList<String>();
         if(portSelectionKeys != null && portSelectionList.size() >= 1){
            int i=0;
            for(Object obj : portSelectionKeys){
               List<Integer> numPortsList = portSelectionMap.get(obj);
               for(Integer numPorts : numPortsList){
                  DVPortSelection dvPortSelection = portSelectionList.get(i);
                  if(obj instanceof DVSConfigSpec){
                     DVSConfigSpec vdsConfigSpec = (DVSConfigSpec)obj;
                     /*
                      * Pick the specified number of ports from the
                      * corresponding vds
                      */
                     ManagedObjectReference dvsMor =
                        getVdsMorForConfigSpec(vdsConfigSpec);
                     List<String> portKeyList = this.vdsPortKeyMap.get(dvsMor);
                     if(portKeyList != null){
                        portKeys = new ArrayList<String>(portKeyList);
                     }
                     for(int j=0;j<numPorts;j++){
                        if(portKeys != null && j<portKeys.size()){
                           selectedKeys.add(portKeys.get(j));
                           portKeys.remove(j);
                           this.vdsPortKeyMap.put(dvsMor,portKeys);
                        }
                     }
                     String vdsUuid = this.vds.getConfig(dvsMor).getUuid();
                     if(this.customMap.getPortKeysOutVds() != null &&
                        this.customMap.getPortKeysOutVds() == true){
                        vdsUuid = getAlternateVdsUuid(vdsUuid);
                     }
                     dvPortSelection.setDvsUuid(vdsUuid);
                  } else if(obj instanceof DVPortgroupConfigSpec){
                     /*
                      * Pick ports from the corresponding portgroup
                      */
                     DVPortgroupConfigSpec portgroupConfigSpec =
                        (DVPortgroupConfigSpec)obj;
                     /*
                      * Pick the specified number of ports from the
                      * corresponding vds
                      */
                     ManagedObjectReference pgMor =
                        getPortgroupMorForConfigSpec(portgroupConfigSpec);
                     portKeys = new ArrayList<String>(this.
                        vdsPortgroupPortKeyMap.get(pgMor));
                     for(int j=0;j<numPorts;j++){
                        selectedKeys.add(portKeys.get(j));
                        //portKeys.remove(j);
                        //this.vdsPortgroupPortKeyMap.put(pgMor,portKeys);
                     }
                     dvPortSelection.setDvsUuid(this.vds.getConfig(this.
                        vdsPortgroup.getConfigInfo(pgMor).
                           getDistributedVirtualSwitch()).getUuid());
                  }
                  if(selectedKeys != null && !selectedKeys.isEmpty()){
                     dvPortSelection.getPortKey().clear();
                     dvPortSelection.getPortKey().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(selectedKeys.toArray(new
                              String[selectedKeys.size()])));
                  }
                  i++;
               }
            }
         }
      } else {
         /*
          * There is a possibility that the selection set might contain negative
          * values.
          */
         for(DVPortSelection portSelection : portSelectionList){
            if(portSelection.getDvsUuid() == null){
               portSelection.setDvsUuid(vds.getConfig(this.vdsMorList.get(0)).
                  getUuid());
            }
            if(com.vmware.vcqa.util.TestUtil.vectorToArray(portSelection.getPortKey(), java.lang.String.class) == null){
               /*
                * Fill in with valid port keys
                */
               List<String> portKeys = vds.fetchPortKeys(vdsMorList.get(0),
                  vds.getPortCriteria(null, null, null, null, null, null));
               if(portKeys != null && portKeys.size() >= 1){
                  portSelection.getPortKey().clear();
                  portSelection.getPortKey().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(portKeys.toArray(new
                     String[portKeys.size()])));
               }
            }
         }
      }
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
    * This method gets the step associated with the step name. If the step is
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
      populateSelectionSets();
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
      init("addHostsToDvs");
      populateHosts();
      assertTrue((this.hostMorList != null && this.hostMorList.size()>=1),
         "Found atleast one host in the inventory", "Failed to find a host " +
            "in the inventory");
      if(this.customMap != null){
         List<DVSConfigSpec> hostVdsConfigSpec = this.customMap.
            getHostVdsConfigSpec();
         assertNotNull(hostVdsConfigSpec, "Found valid dvses to add the " +
            "hosts", "Failed to find valid dvses to add the hosts");
         for(int i=0;i<this.hostMorList.size();i++){
            for(int j=0;j<hostVdsConfigSpec.size();j++){
               ManagedObjectReference dvsMor = getVdsMorForConfigSpec(
                  hostVdsConfigSpec.get(j));
               if(dvsMor == null){
                  continue;
               }
               assertTrue(DVSUtil.addHostsUsingReconfigureDVS(dvsMor,
                  Collections.singletonList(hostMorList.get(i)),
                     connectAnchor),"Added the host to the vds","Failed " +
                        "to add the hosts to the vds");
            }
         }
      }
   }

   /**
    * This method initializes the data for input parameters like selection sets
    * and runtime.
    *
    * @param objIdList
    *
    * @throws Exception
    */
   public void initData(List<Object> objIdList)
      throws Exception
   {
      List<DVSConfigSpec> dvsConfigSpecList = new ArrayList<DVSConfigSpec>();
      List<DVSOpaqueDataConfigSpec> dvsOpaqueDataConfigSpecList = new
         ArrayList<DVSOpaqueDataConfigSpec>();
      List<SelectionSet> selectionSetList = new ArrayList<SelectionSet>();
      for(Object object : objIdList){
         if(object instanceof DVSConfigSpec){
            dvsConfigSpecList.add((DVSConfigSpec)object);
         }
         if(object instanceof DVSOpaqueDataConfigSpec){
            dvsOpaqueDataConfigSpecList.add((DVSOpaqueDataConfigSpec)object);
         }
         if(object instanceof SelectionSet){
            selectionSetList.add((SelectionSet)object);
         }
         if(object instanceof CustomMap){
            this.customMap = (CustomMap)object;
         }
         if(object instanceof Boolean){
            this.isRuntime = (Boolean)object;
         }
      }
      if(dvsConfigSpecList.size() >= 1){
         this.dvsConfigSpecArray = dvsConfigSpecList.toArray(new
            DVSConfigSpec[dvsConfigSpecList.size()]);
      }
      if(dvsOpaqueDataConfigSpecList.size() >= 1){
         this.opaqueDataSpec = dvsOpaqueDataConfigSpecList.toArray(new
            DVSOpaqueDataConfigSpec[dvsOpaqueDataConfigSpecList.size()]);
      }
      if(selectionSetList.size()>=1){
         this.selectionSet = selectionSetList.toArray(new
            SelectionSet[selectionSetList.size()]);
      }
      /*if(dvPortgroupConfigSpecList.size() >= 1){
         this.portgroupConfigSpecArray = dvPortgroupConfigSpecList.
            toArray(new DVPortgroupConfigSpec[dvPortgroupConfigSpecList.
               size()]);
      }*/
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
      if(vmMorConfigSpecMap != null){
         /*
          * Get all the vms in the map
          */
         for(ManagedObjectReference vmMor : vmMorConfigSpecMap.keySet()){
            if(!virtualMachine.getVMState(vmMor).equals(
                     VirtualMachinePowerState.POWERED_OFF)){
               assertTrue(virtualMachine.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false),"Successfully " +
                     "powered off the virtual machine","Failed to power off " +
                        "the virtual machine");
               assertTrue(virtualMachine.reconfigVM(vmMor,
                  vmMorConfigSpecMap.get(vmMor)),"Successfully reconfigured " +
                     "the vm with its original settings","Failed to " +
                        "reconfigure the vm with its original settings");
            }
         }
      }
      if(this.vdsMorList != null){
         for(ManagedObjectReference dvs : vdsMorList){
            assertTrue(this.vds.destroy(dvs),"Successfully " +
               "destroyed the vds","Failed to destroy the vds");
         }
      }
   }
}
