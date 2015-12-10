/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvport;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ClusterConfigSpecEx;
import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DVSTrafficShapingPolicy;
import com.vmware.vc.DVSUplinkPortPolicy;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.ResourceConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareDVSPvlanConfigSpec;
import com.vmware.vc.VMwareDVSPvlanMapEntry;
import com.vmware.vc.VMwareUplinkPortOrderPolicy;
import com.vmware.vc.VmwareDistributedVirtualSwitchPvlanSpec;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.ClusterComputeResource;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ResourcePool;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure DVPort. See setTestDescription for detailed description
 */
public class Pos032 extends CreateDVSTestBase
{

   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDVS = null;
   private DistributedVirtualSwitchHelper iVmwDVS = null;
   private VirtualMachine ivm = null;
   private ClusterComputeResource icr = null;
   private HostSystem ihs = null;
   private DVPortConfigSpec[] portConfigSpecs = null;
   private ResourcePool irp = null;
   private NetworkSystem ins = null;
   private ManagedObjectReference nestedResPoolMor = null;
   private ManagedObjectReference nestedFolderMor = null;
   private ManagedObjectReference clusterExMor = null;
   private final int DVS_PORT_NUM = 11;
   private final int PRIMARY_PVLAN_ID = 1;
   private final int SECONDARY_PVLAN_ID_ISOLATED = 2;
   private final int SECONDARY_PVLAN_ID_COMMUNITY = 3;
   private List<Integer> pvlanIdList = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure multiple DVPorts");
   }

   /**
    * Method to setup the environment for the test.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;

      log.info("Test setup Begin:");

         if (super.testSetUp()) {
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.iDVS = new DistributedVirtualSwitch(connectAnchor);
               this.ins = new NetworkSystem(connectAnchor);
               configSpec = new DVSConfigSpec();
               configSpec.setName(this.getClass().getName());
               configSpec.setNumStandalonePorts(DVS_PORT_NUM);
               dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  this.iVmwDVS = new DistributedVirtualSwitchHelper(
                           connectAnchor);
                  reconfigVmwareDVS(dvsMOR);
                  List<String> portKeyList = iDVS.fetchPortKeys(dvsMOR, null);
                  if (portKeyList != null && portKeyList.size() == DVS_PORT_NUM) {
                     ivm = new VirtualMachine(connectAnchor);
                     icr = new ClusterComputeResource(connectAnchor);
                     ihs = new HostSystem(connectAnchor);
                     irp = new ResourcePool(connectAnchor);
                     if (ihs.getAllHost() != null && ivm.getAllVM() != null) {
                        portConfigSpecs = this.createPortConfigSpec(
                                 portKeyList, dvsMOR);
                        status = true;

                     } else {
                        log.error("Can't find host and/or vm in the inventory. "
                                 + "Please check");
                     }
                  } else {
                     log.error("Can't get correct port keys");
                  }
               } else {
                  log.error("Cannot create the distributed virtual "
                           + "switch with the config spec passed");
               }
            } else {
               log.error("Failed to create the network folder");
            }
         }

      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure multiple DVPorts")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;

         status = this.iDVS.reconfigurePort(this.dvsMOR, this.portConfigSpecs);
         assertTrue(status, "Test Failed");

      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;

         status &= super.testCleanUp();

         if (this.nestedFolderMor != null) {
            if (this.iFolder.destroy(nestedFolderMor)) {
               log.info("Destroyed nested folder");
            } else {
               log.error("Couldn't destroy nested folder");
               status = false;
            }
         }

         if (this.clusterExMor != null) {
            if (iFolder.destroy(clusterExMor)) {
               log.info("cluster deleted");
            } else {
               log.error("Can't delete cluster ");
               status = false;
            }
         }

         if (this.nestedResPoolMor != null) {
            if (this.irp.destroy(this.nestedResPoolMor)) {
               log.info("Removed new resource pool");
            } else {
               log.error("Can't remove new resource pool");
               status = false;
            }
         }

      assertTrue(status, "Cleanup failed");
      return status;
   }

   /**
    * reconfig VmwareDVS
    */
   private void reconfigVmwareDVS(ManagedObjectReference dvsMor)
      throws Exception
   {
      this.pvlanIdList = new ArrayList<Integer>();
      VMwareDVSPvlanConfigSpec[] pvlanConfigSpecs = new VMwareDVSPvlanConfigSpec[3];

      pvlanConfigSpecs[0] = new VMwareDVSPvlanConfigSpec();
      pvlanConfigSpecs[0].setOperation(ConfigSpecOperation.ADD.value());
      VMwareDVSPvlanMapEntry pvlanMapEntry = new VMwareDVSPvlanMapEntry();
      pvlanMapEntry.setPrimaryVlanId(PRIMARY_PVLAN_ID);
      pvlanMapEntry.setSecondaryVlanId(PRIMARY_PVLAN_ID);
      pvlanMapEntry.setPvlanType(DVSTestConstants.PVLAN_TYPE_PROMISCUOUS);
      pvlanConfigSpecs[0].setPvlanEntry(pvlanMapEntry);
      pvlanIdList.add(PRIMARY_PVLAN_ID);

      pvlanConfigSpecs[1] = new VMwareDVSPvlanConfigSpec();
      pvlanConfigSpecs[1].setOperation(ConfigSpecOperation.ADD.value());
      pvlanMapEntry = new VMwareDVSPvlanMapEntry();
      pvlanMapEntry.setPrimaryVlanId(PRIMARY_PVLAN_ID);
      pvlanMapEntry.setSecondaryVlanId(SECONDARY_PVLAN_ID_ISOLATED);
      pvlanMapEntry.setPvlanType(DVSTestConstants.PVLAN_TYPE_ISOLATED);
      pvlanConfigSpecs[1].setPvlanEntry(pvlanMapEntry);
      pvlanIdList.add(SECONDARY_PVLAN_ID_ISOLATED);

      pvlanConfigSpecs[2] = new VMwareDVSPvlanConfigSpec();
      pvlanConfigSpecs[2].setOperation(ConfigSpecOperation.ADD.value());
      pvlanMapEntry = new VMwareDVSPvlanMapEntry();
      pvlanMapEntry.setPrimaryVlanId(PRIMARY_PVLAN_ID);
      pvlanMapEntry.setSecondaryVlanId(SECONDARY_PVLAN_ID_COMMUNITY);
      pvlanMapEntry.setPvlanType(DVSTestConstants.PVLAN_TYPE_COMMINITY);
      pvlanConfigSpecs[2].setPvlanEntry(pvlanMapEntry);
      pvlanIdList.add(SECONDARY_PVLAN_ID_COMMUNITY);

      iVmwDVS.reconfigurePvlan(dvsMor, pvlanConfigSpecs);

   }

   /**
    * Create a child resource pool
    *
    * @param parentResPoolMor, parent resource pool of the one to be created
    * @return child resource pool mor
    * @throws Exception
    */
   private ManagedObjectReference createChildResPool(ManagedObjectReference parentResPoolMor)
      throws Exception
   {
      ManagedObjectReference childResPoolMor = null;
      ResourceConfigSpec resConfigSpec = this.irp.createDefaultResourceConfigSpec();

      childResPoolMor = irp.createResourcePool(parentResPoolMor, getTestId()
               + "respool", resConfigSpec);
      return childResPoolMor;
   }

   private ManagedObjectReference[] createScopeList()
      throws Exception
   {
      ManagedObjectReference[] scopeMors = new ManagedObjectReference[11];
      /*
       * 1. set the first element to null
       */
      scopeMors[0] = null;

      /*
       * 2. set VM mor
       */
      scopeMors[1] = ivm.getAllVM().get(0);

      /*
       * 3-5. set vm folder mor and a nested folder mor and host folder mor
       */
      ManagedObjectReference vmFolderMor = ivm.getVMFolder();
      scopeMors[2] = vmFolderMor;
      nestedFolderMor = iFolder.createFolder(vmFolderMor, getTestId());
      scopeMors[3] = nestedFolderMor;
      ManagedObjectReference hostFolderMor = (ManagedObjectReference) iFolder.getAllHostFolders().get(
               0);
      scopeMors[4] = hostFolderMor;

      /*
       * 6-7 set ComputeResource mor and cluster ComputeResource mor
       */
      scopeMors[5] = (ManagedObjectReference) (icr.getAllComputeResources().get(0));
      clusterExMor = iFolder.createClusterEx(hostFolderMor, getTestId(),
               new ClusterConfigSpecEx());
      scopeMors[6] = clusterExMor;

      /*
       * 8. set datacenter mor
       */
      scopeMors[7] = ihs.getDataCenter();

      /*
       * 9. set host mor
       */
      List<ManagedObjectReference> hostList = ihs.getAllHost();
      if (hostList != null) {
         scopeMors[8] = hostList.get(0);
      } else {
         log.error("Can't find host in the inventory");
      }

      /*
       * 10-11. set a valid resourcepool mor and nested resourcepool mor
       */
      ManagedObjectReference rpMor = icr.getResourcePool(ihs.getParentNode(ihs.
               getStandaloneHost()));
      scopeMors[9] = rpMor;
      nestedResPoolMor = this.createChildResPool(rpMor);
      scopeMors[10] = nestedResPoolMor;

      return scopeMors;
   }

   /**
    * Create DVPort configSpec with valid inShapingPolicy and outShapingPolicy
    */
   private VMwareDVSPortSetting[] createPortSettings(ManagedObjectReference dvsMor)
      throws Exception
   {
      VMwareDVSPortSetting[] settings = new VMwareDVSPortSetting[DVS_PORT_NUM];
      VmwareUplinkPortTeamingPolicy uplinkTeamingPolicy = this.createUplinkPortTeamingPolicy(dvsMor);
      for (int i = 0; i < DVS_PORT_NUM; i++) {
         settings[i] = DVSUtil.getDefaultVMwareDVSPortSetting(null);
         settings[i].setBlocked(DVSUtil.getBoolPolicy(false, false));
         settings[i].setUplinkTeamingPolicy(uplinkTeamingPolicy);
      }

      /*
       * Port-1, default inShapingPolicy
       */
      settings[0].setBlocked(DVSUtil.getBoolPolicy(false, false));
      DVSTrafficShapingPolicy inShapingPolicy = DVSUtil.getTrafficShapingPolicy(
               false, true, null, null, null);
      settings[0].setInShapingPolicy(inShapingPolicy);

      /*
       * Port-3, inshapingPolicy
       */
      inShapingPolicy = DVSUtil.getTrafficShapingPolicy(false, true,
               TestConstants.DEFAULT_AVERAGE_BAND_WIDTH,
               TestConstants.DEFAULT_PEAK_BAND_WIDTH,
               TestConstants.DEFAULT_BURST_SIZE);
      settings[2].setInShapingPolicy(inShapingPolicy);
      /*
       * Port-4, outShapingPolicy
       */
      DVSTrafficShapingPolicy outShapingPolicy = DVSUtil.getTrafficShapingPolicy(
               false, true, TestConstants.DEFAULT_AVERAGE_BAND_WIDTH,
               TestConstants.DEFAULT_PEAK_BAND_WIDTH,
               TestConstants.DEFAULT_BURST_SIZE);
      settings[3].setOutShapingPolicy(outShapingPolicy);
      /*
       * Port-5, inShapingPolicy and outShapingPolicy
       */
      inShapingPolicy = DVSUtil.getTrafficShapingPolicy(false, true,
               TestConstants.DEFAULT_AVERAGE_BAND_WIDTH,
               TestConstants.DEFAULT_PEAK_BAND_WIDTH,
               TestConstants.DEFAULT_BURST_SIZE);
      settings[4].setInShapingPolicy(inShapingPolicy);

      outShapingPolicy = DVSUtil.getTrafficShapingPolicy(false, true,
               TestConstants.DEFAULT_AVERAGE_BAND_WIDTH,
               TestConstants.DEFAULT_PEAK_BAND_WIDTH,
               TestConstants.DEFAULT_BURST_SIZE);
      settings[4].setOutShapingPolicy(outShapingPolicy);

      /*
       * Set pvlanIds, from p3 to p5
       */
      VmwareDistributedVirtualSwitchPvlanSpec pvlanSpec = null;
      for (int i = 2; i < 5; i++) {
         pvlanSpec = new VmwareDistributedVirtualSwitchPvlanSpec();
         pvlanSpec.setPvlanId(this.pvlanIdList.get(i - 2));
         settings[i].setVlan(pvlanSpec);

      }

      return settings;

   }

   /**
    * create a valid uplink teaming policy
    */
   private VmwareUplinkPortTeamingPolicy createUplinkPortTeamingPolicy(ManagedObjectReference dvsMor)
      throws Exception
   {
      VmwareUplinkPortTeamingPolicy uplinkTeamingPolicy = null;
      DVSConfigInfo dvsConfigInfo = this.iDVS.getConfig(dvsMor);
      DVSUplinkPortPolicy uplinkPortPolicy = dvsConfigInfo.getUplinkPortPolicy();
      if (uplinkPortPolicy != null
               && uplinkPortPolicy instanceof com.vmware.vc.DVSNameArrayUplinkPortPolicy) {
         VMwareUplinkPortOrderPolicy uplinkOrderPolicy = new VMwareUplinkPortOrderPolicy();
         String[] uplinkPortNames = com.vmware.vcqa.util.TestUtil.vectorToArray(((DVSNameArrayUplinkPortPolicy) uplinkPortPolicy).getUplinkPortName(), java.lang.String.class);
         String[] activePortNames = new String[1];
         activePortNames[0] = uplinkPortNames[0];
         uplinkOrderPolicy.getActiveUplinkPort().clear();
         uplinkOrderPolicy.getActiveUplinkPort().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(activePortNames));
         if (uplinkPortNames.length > 1) {
            String[] standbyPortNames = new String[uplinkPortNames.length - 1];
            for (int i = 0; i < uplinkPortNames.length - 1; i++) {
               standbyPortNames[i] = uplinkPortNames[i + 1];
            }
            uplinkOrderPolicy.getStandbyUplinkPort().clear();
            uplinkOrderPolicy.getStandbyUplinkPort().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(standbyPortNames));
         }
         uplinkTeamingPolicy = new VmwareUplinkPortTeamingPolicy();
         uplinkTeamingPolicy.setUplinkPortOrder(uplinkOrderPolicy);
         uplinkTeamingPolicy.setNotifySwitches(DVSUtil.getBoolPolicy(false,
                  true));
         uplinkTeamingPolicy.setReversePolicy(DVSUtil.getBoolPolicy(false, true));
         uplinkTeamingPolicy.setRollingOrder(DVSUtil.getBoolPolicy(false, true));
         uplinkTeamingPolicy.setFailureCriteria(DVSUtil.getFailureCriteria(
                  false, null, null, null, null, null, null, null));
         uplinkTeamingPolicy.setPolicy(DVSUtil.getStringPolicy(false,
                  "loadbalance_ip"));
      } else {
         log.error("Can't get uplinkPort name array");
      }
      return uplinkTeamingPolicy;
   }

   /**
    * Create DVPort configSpec with valid inShapingPolicy and outShapingPolicy
    */
   private DVPortConfigSpec[] createPortConfigSpec(List<String> portKeyList,
                                                   ManagedObjectReference dvsMor)
      throws Exception
   {
      DVPortConfigSpec[] configSpecs = new DVPortConfigSpec[DVS_PORT_NUM];
      ManagedObjectReference[] scopeMors = this.createScopeList();
      VMwareDVSPortSetting[] settings = this.createPortSettings(dvsMor);
      /*
       * Create port configSpec and set scope(exception the first one)
       */
      for (int i = 0; i < DVS_PORT_NUM; i++) {
         configSpecs[i] = new DVPortConfigSpec();
         configSpecs[i].setKey(portKeyList.get(i));
         configSpecs[i].setOperation(ConfigSpecOperation.EDIT.value());
         if (scopeMors[i] != null) {
            configSpecs[i].getScope().clear();
            configSpecs[i].getScope().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { scopeMors[i] }));
         }
      }

      /*
       * Set settings, from p1 to p5
       */
      for (int i = 0; i < 5; i++) {
         configSpecs[i].setSetting(settings[i]);
      }

      return configSpecs;

   }
}