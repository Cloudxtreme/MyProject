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

import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareDVSPortgroupPolicy;
import com.vmware.vc.VmwareDistributedVirtualSwitchPvlanSpec;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;

/**
 * Reconfigure an early binding portgroup to an existing distributed virtual
 * switch with settingVlanOverrideAllowed set to true
 */
public class Pos046 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private VMwareDVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitchHelper iDVSwitch = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private String portgroupKey = null;
   private String portKey = null;
   private ManagedObjectReference dcMor = null;
   private VMwareDVSPortSetting dvsPortSetting = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Reconfigure an early binding portgroup to an "
               + "existing  distributed virtual switch with "
               + "settingVlanOverrideAllowed set to true");
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
      final String dvsName = super.getTestId();
      DVPortConfigSpec portConfigSpec = null;
      VmwareDistributedVirtualSwitchPvlanSpec pvlanspec = null;
      Map<String, Object> settingsMap = null;
      log.info("Test setup Begin:");
      try {
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitchHelper(connectAnchor);
         this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.rootFolderMor = this.iFolder.getRootFolder();
         this.dcMor = this.iFolder.getDataCenter();
         if (this.rootFolderMor != null) {
            this.dvsConfigSpec = new VMwareDVSConfigSpec();
            this.dvsConfigSpec.setConfigVersion("");
            this.dvsConfigSpec.setName(dvsName);
            this.dvsConfigSpec.setNumStandalonePorts(1);
            dvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
            if (dvsMor != null) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               if (this.iDVSwitch.addPrimaryPvlan(this.dvsMor, 10)) {
                  log.info("Successfully added the primary pvlan id " + 10);
                  if (this.iDVSwitch.addPrimaryPvlan(this.dvsMor, 20)) {
                     log.info("Successfully added the primary pvlan id " + 20);
                     portKey = iDVSwitch.getFreeStandaloneDVPortKey(dvsMor,
                              null);
                     pvlanspec = new VmwareDistributedVirtualSwitchPvlanSpec();
                     pvlanspec.setPvlanId(20);
                     settingsMap = new HashMap<String, Object>();
                     settingsMap.put(DVSTestConstants.VLAN_KEY, pvlanspec);
                     dvsPortSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);

                     portConfigSpec = new DVPortConfigSpec();
                     portConfigSpec.setOperation(TestConstants.CONFIG_SPEC_EDIT);
                     portConfigSpec.setKey(portKey);
                     portConfigSpec.setSetting(dvsPortSetting);
                     if (this.iDVSwitch.reconfigurePort(dvsMor,
                              new DVPortConfigSpec[] { portConfigSpec })) {
                        log.info("Successfully reconfigured the "
                                 + "port");
                        this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
                        this.dvPortgroupConfigSpec.setConfigVersion("");
                        this.dvPortgroupConfigSpec.setName(getTestId() + "-pg1");
                        this.dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
                        this.dvPortgroupConfigSpec.setNumPorts(1);
                        this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
                        this.dvPortgroupMorList = this.iDVSwitch.addPortGroups(
                                 dvsMor,
                                 new DVPortgroupConfigSpec[] { this.dvPortgroupConfigSpec });
                        if (this.dvPortgroupMorList != null
                                 && this.dvPortgroupMorList.size() == 1) {
                           log.info("Successfully added the "
                                    + "portgroup");
                           status = true;
                        } else {
                           log.error("Failed to add the portgroup");
                        }
                     } else {
                        log.error("Can not add the primary pvlan id " + 20);
                     }
                  } else {
                     log.error("Can not add the primary pvlan id " + 10);
                  }
               } else {
                  log.error("Failed to reconfigure the port");
               }
            } else {
               log.error("Could not create the distributed "
                        + "virtual switch");
            }
         } else {
            log.error("Failed to find a folder");
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that reconfigures an early binding portgroup
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure an early binding portgroup to an "
               + "existing  distributed virtual switch with "
               + "settingVlanOverrideAllowed set to true")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      List<DistributedVirtualPort> dvsPort = null;
      VMwareDVSPortSetting actualPortSetting = null;
      VMwareDVSPortgroupPolicy portgroupPolicy = null;
      VMwareDVSPortSetting dvPortgroupSetting = null;
      VmwareDistributedVirtualSwitchPvlanSpec pvlanspec = null;
      Map<String, Object> settingsMap = null;

      try {
         portgroupPolicy = new VMwareDVSPortgroupPolicy();
         portgroupPolicy.setVlanOverrideAllowed(true);
         pvlanspec = new VmwareDistributedVirtualSwitchPvlanSpec();
         pvlanspec.setPvlanId(10);
         settingsMap = new HashMap<String, Object>();
         settingsMap.put(DVSTestConstants.VLAN_KEY, pvlanspec);
         dvPortgroupSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);

         this.dvPortgroupConfigSpec.setDefaultPortConfig(dvPortgroupSetting);
         this.dvPortgroupConfigSpec.setPolicy(portgroupPolicy);
         this.dvPortgroupConfigSpec.setConfigVersion(this.iDVPortgroup.getConfigInfo(
                  dvPortgroupMorList.get(0)).getConfigVersion());
         if (this.iDVPortgroup.reconfigure(dvPortgroupMorList.get(0),
                  this.dvPortgroupConfigSpec)) {
            log.info("Successfully reconfigured the portgroup");
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
                     if (dvsPort.get(0).getConfig().getSetting() instanceof VMwareDVSPortSetting) {
                        actualPortSetting = (VMwareDVSPortSetting) dvsPort.get(
                                 0).getConfig().getSetting();
                        status = TestUtil.compareObject(
                                 actualPortSetting.getVlan(),
                                 dvsPortSetting.getVlan(), null);
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
            log.error("Failed to reconfigure the portgroup");
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
