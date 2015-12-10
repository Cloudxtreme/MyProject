/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigInfo;
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSTrafficShapingPolicy;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Reconfigure an early binding portgroup to an existing distributed virtual
 * switch with settingShapingOverrideAllowed set to true
 */
public class Pos041 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private String portgroupKey = null;
   private String portKey = null;
   private ManagedObjectReference dcMor = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Reconfigure an early binding portgroup to an "
               + "existing distributed virtual switch with "
               + "settingShapingOverrideAllowed set to true");
   }

   /**
    * Method to setup the environment for the test. This method creates a
    * distributed virtual switch.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      final String dvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + getTestId();
      DVPortSetting dvsPortSetting = null;
      DVPortConfigSpec portConfigSpec = null;
      Map<String, Object> settingsMap = null;
      log.info("Test setup Begin:");
      try {
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.dcMor = this.iFolder.getDataCenter();
         if (this.dcMor != null) {
            this.dvsConfigSpec = new DVSConfigSpec();
            this.dvsConfigSpec.setConfigVersion("");
            this.dvsConfigSpec.setName(dvsName);
            this.dvsConfigSpec.setNumStandalonePorts(8);
            settingsMap = new HashMap<String, Object>();
            settingsMap.put(DVSTestConstants.INSHAPING_POLICY_KEY,
                     DVSUtil.getTrafficShapingPolicy(false, true, null, null,
                              null));
            dvsPortSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);

            dvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
            if (dvsMor != null) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               portKey = iDVSwitch.getFreeStandaloneDVPortKey(dvsMor, null);
               portConfigSpec = new DVPortConfigSpec();
               portConfigSpec.setSetting(dvsPortSetting);
               portConfigSpec.setKey(portKey);
               portConfigSpec.setOperation(TestConstants.CONFIG_SPEC_EDIT);
               VMwareDVSPortSetting dvPortSetting = new VMwareDVSPortSetting();
               dvPortSetting.setBlocked(DVSUtil.getBoolPolicy(false,
                        new Boolean(false)));
               DVSTrafficShapingPolicy inShapingPolicy =
               DVSUtil.getTrafficShapingPolicy(false, true, null, null, null);
               dvPortSetting.setInShapingPolicy(inShapingPolicy);
               portConfigSpec.setSetting(dvPortSetting);
               if (this.iDVSwitch.reconfigurePort(dvsMor,
                        new DVPortConfigSpec[] { portConfigSpec })) {
                  log.info("Successfully reconfigured the port");
                  this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
                  this.dvPortgroupConfigSpec.setNumPorts(1);
                  this.dvPortgroupConfigSpec.setName(this.getTestId());
                  this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
                  dvPortgroupMorList = this.iDVSwitch.addPortGroups(
                           dvsMor,
                           new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec });
                  if (dvPortgroupMorList != null
                           && dvPortgroupMorList.get(0) != null) {
                     log.info("Successfully added the portgroup");
                     status = true;
                  } else {
                     log.error("Failed to add the portgroup");
                  }
               } else {
                  log.error("Failed to reconfigure the portgroup");
               }
            } else {
               log.error("Could not create the distributed "
                        + "virtual switch");
            }
         } else {
            log.error("Failed to find a data center");
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * create DVPort ConfigSpec
    */
   private DVPortConfigSpec createPortConfigSpec(String key)
   {
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      DVPortConfigSpec configSpec = new DVPortConfigSpec();
      List<DistributedVirtualPort> dvPorts = null;
      DVPortSetting dvPortSetting = null;
      DVSTrafficShapingPolicy inShapingPolicy = null;
      DVPortConfigInfo dvPortConfigInfo = null;
      try {
         portCriteria = new DistributedVirtualSwitchPortCriteria();
         portCriteria.getPortKey().clear();
         portCriteria.getPortKey().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] { key }));
         dvPorts = this.iDVSwitch.fetchPorts(this.dvsMor, portCriteria);
         if (dvPorts != null && dvPorts.get(0) != null) {
            log.info("Successfully obtained the port");
            dvPortConfigInfo = dvPorts.get(0).getConfig();
            if (dvPortConfigInfo != null) {
               configSpec.setKey(key);
               configSpec.setOperation(ConfigSpecOperation.EDIT.value());
               dvPortSetting = dvPortConfigInfo.getSetting();
               if (dvPortSetting == null) {
                  dvPortSetting = (VMwareDVSPortSetting) DVSUtil.getDefaultVMwareDVSPortSetting(null);
               }
               dvPortSetting.setBlocked(DVSUtil.getBoolPolicy(false,
                        new Boolean(false)));
               inShapingPolicy =

               DVSUtil.getTrafficShapingPolicy(false, true, null, null, null);

               dvPortSetting.setInShapingPolicy(inShapingPolicy);
               configSpec.setSetting(dvPortSetting);
            } else {
               log.error("Failed to obtain the DVPortConfigInfo");
               configSpec = null;
            }
         } else {
            log.error("Failed to obtain the port " + "config spec");
            configSpec = null;
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      return configSpec;
   }

   /**
    * Method that adds an early binding portgroup
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure an early binding portgroup to an "
               + "existing distributed virtual switch with "
               + "settingShapingOverrideAllowed set to true")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      List<DistributedVirtualPort> dvsPort = null;
      DVSTrafficShapingPolicy dvPortgroupInshapingPolicy = null;
      DVPortSetting dvPortgroupSetting = null;
      DVPortgroupPolicy portgroupPolicy = null;
      try {
         this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
         this.dvPortgroupConfigSpec.setConfigVersion(this.iDVPortgroup.getConfigInfo(
                  this.dvPortgroupMorList.get(0)).getConfigVersion());

         portgroupPolicy = new DVPortgroupPolicy();
         portgroupPolicy.setShapingOverrideAllowed(true);
         dvPortgroupSetting = this.iDVSwitch.getConfig(dvsMor).getDefaultPortConfig();
         dvPortgroupInshapingPolicy = dvPortgroupSetting.getInShapingPolicy();
         dvPortgroupInshapingPolicy.setEnabled(DVSUtil.getBoolPolicy(false,
                  false));
         portgroupPolicy.setLivePortMovingAllowed(true);
         portgroupPolicy.setBlockOverrideAllowed(true);
         dvPortgroupSetting.setInShapingPolicy(dvPortgroupInshapingPolicy);
         this.dvPortgroupConfigSpec.setPolicy(portgroupPolicy);
         this.dvPortgroupConfigSpec.setDefaultPortConfig(dvPortgroupSetting);

         this.dvPortgroupConfigSpec.setName(this.getTestId() + "-pg1");
         this.dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
         if (this.iDVPortgroup.reconfigure(dvPortgroupMorList.get(0),
                  this.dvPortgroupConfigSpec)) {
            log.info("Successfully reconfigured the porgroup");
            portgroupKey = this.iDVPortgroup.getKey(dvPortgroupMorList.get(0));
            if (portgroupKey != null) {
               if (this.iDVSwitch.movePort(dvsMor, new String[] { portKey },
                        portgroupKey)) {
                  log.info("Successfully moved the port into "
                           + "the portgroup");
                  portCriteria = new DistributedVirtualSwitchPortCriteria();
                  portCriteria.setConnected(false);
                  portCriteria.getPortKey().clear();
                  portCriteria.getPortKey().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] { portKey }));
                  dvsPort = this.iDVSwitch.fetchPorts(dvsMor, portCriteria);
                  if (dvsPort != null) {
                     log.info("Found the port");
                     if (dvsPort.get(0).getConfig().getSetting().getInShapingPolicy().getEnabled().equals(
                              DVSUtil.getBoolPolicy(false, true))) {
                        log.info("The inshaping policy of "
                                 + "the port was retained");
                        status = true;
                     } else {
                        log.error("The inshaping policy of the"
                                 + " port was not retained");
                     }
                  } else {
                     log.error("Could not find the port");
                  }
               } else {
                  log.error("Failed to move the port into the "
                           + "portgroup");
               }
            } else {
               log.error("Could not get the portgroup key");
            }
         } else {
            log.error("Coud not reconfigure the portgroup");
         }

      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test was started. Restore
    * the original state of the VM.Destroy the portgroup, followed by the
    * distributed virtual switch
    *
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         /*if(this.dvPortgroupMorList != null){
            for(ManagedObjectReference mor: dvPortgroupMorList){
               status &= this.iManagedEntity.destroy(mor);
            }
         }*/
         if (this.dvsMor != null) {
            status &= this.iManagedEntity.destroy(dvsMor);
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
         status = false;
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
