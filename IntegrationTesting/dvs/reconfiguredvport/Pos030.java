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

import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigInfo;
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareDVSPvlanConfigSpec;
import com.vmware.vc.VMwareDVSPvlanMapEntry;
import com.vmware.vc.DVPortSetting;
import com.vmware.vc.VmwareDistributedVirtualSwitchPvlanSpec;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure DVPort. See setTestDescription for detailed description
 */
public class Pos030 extends CreateDVSTestBase
{

   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDVS = null;
   private DistributedVirtualSwitchHelper iVmwDVS = null;
   private DVPortConfigSpec[] portConfigSpecs = null;
   private final int PRIMARY_PVLAN_ID = 1;
   private final int SECONDARY_PVLAN_ID_ISOLATED = 2;
   private final int SECONDARY_PVLAN_ID_COMMUNITY = 3;
   private final int DVS_PORT_NUM = 3;
   private List<Integer> pvlanIdList = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure DVPort and set pvlanid to secondary "
               + "pvlan id belongs to the pvlanMapEntry community type");
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
               configSpec = createVmwareDVSConfigSpec();

               dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  this.iVmwDVS = new DistributedVirtualSwitchHelper(
                           connectAnchor);
                  reconfigVmwareDVS(dvsMOR);
                  List<String> portKeyList = iDVS.fetchPortKeys(dvsMOR, null);
                  if (portKeyList != null && portKeyList.size() == DVS_PORT_NUM) {
                     portConfigSpecs = this.createPortConfigSpec(portKeyList);
                     status = true;
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
   @Test(description = "Reconfigure DVPort and set pvlanid to secondary "
               + "pvlan id belongs to the pvlanMapEntry community type")
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

      assertTrue(status, "Cleanup failed");
      return status;
   }

   /**
    * create VmwareDVS configSpec
    */
   private VMwareDVSConfigSpec createVmwareDVSConfigSpec()
   {
      VMwareDVSConfigSpec configSpec = new VMwareDVSConfigSpec();
      configSpec.setName(this.getClass().getName());
      configSpec.setNumStandalonePorts(DVS_PORT_NUM);
      return configSpec;

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
    * create DVPort ConfigSpec
    */
   private DVPortConfigSpec[] createPortConfigSpec(List<String> portKeyList)
   {
      DVPortConfigSpec[] configSpecs = new DVPortConfigSpec[3];
      for (int i = 0; i < this.DVS_PORT_NUM; i++) {
         configSpecs[i] = createPortConfigSpec(portKeyList.get(i),
                  this.pvlanIdList.get(i));
         DVPortSetting dvPortSetting = configSpecs[i].getSetting();
         if (dvPortSetting instanceof VMwareDVSPortSetting) {
            VMwareDVSPortSetting VMwareDVSPort =
                    (VMwareDVSPortSetting) dvPortSetting;
            VMwareDVSPort.setLacpPolicy(null);
            configSpecs[i].setSetting(VMwareDVSPort);
         }
      }
      return configSpecs;
   }

   /**
    * create DVPort ConfigSpec
    */
   private DVPortConfigSpec createPortConfigSpec(String key,
                                                 int pvlanId)
   {
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      DVPortConfigSpec configSpec = new DVPortConfigSpec();
      List<DistributedVirtualPort> dvPorts = null;
      VMwareDVSPortSetting setting = null;
      DVPortConfigInfo dvPortConfigInfo = null;
      VmwareDistributedVirtualSwitchPvlanSpec pvlanSpec = null;
      try {
         portCriteria = new DistributedVirtualSwitchPortCriteria();
         portCriteria.getPortKey().clear();
         portCriteria.getPortKey().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] { key }));
         dvPorts = this.iDVS.fetchPorts(this.dvsMOR, portCriteria);
         if (dvPorts != null && dvPorts.get(0) != null) {
            log.info("Successfully obtained the port");
            dvPortConfigInfo = dvPorts.get(0).getConfig();
            if (dvPortConfigInfo != null) {
               configSpec.setKey(key);
               configSpec.setOperation(ConfigSpecOperation.EDIT.value());
               setting = (VMwareDVSPortSetting) dvPortConfigInfo.getSetting();
               if (setting == null) {
                  setting = (VMwareDVSPortSetting) DVSUtil.getDefaultVMwareDVSPortSetting(null);
               }
               pvlanSpec = new VmwareDistributedVirtualSwitchPvlanSpec();
               pvlanSpec.setInherited(false);
               pvlanSpec.setPvlanId(pvlanId);
               setting.setVlan(pvlanSpec);
               setting.setBlocked(DVSUtil.getBoolPolicy(false, new Boolean(
                        false)));
               configSpec.setSetting(setting);
            } else {
               log.error("Failed to obtain the DVPortConfigInfo");
               configSpec = null;
            }
         } else {
            log.error("Failed to obtain the port config spec");
            configSpec = null;
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      return configSpec;
   }
}
