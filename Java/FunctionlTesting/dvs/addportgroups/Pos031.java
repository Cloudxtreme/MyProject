/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import static com.vmware.vcqa.util.Assert.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VmwareDistributedVirtualSwitchPvlanSpec;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;

/**
 * Add a portgroup to an existing distributed virtual switch with a valid
 * pvlanid
 */
public class Pos031 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitchHelper iDVSwitch = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private VMwareDVSPortSetting dvPortSetting = null;
   private ManagedObjectReference dcMor = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a portgroup to an existing"
               + "distributed virtual switch with a valid " + "pvlanid");
   }

   /**
    * Method to setup the environment for the test. This method creates a
    * distributed virtual switch.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      VmwareDistributedVirtualSwitchPvlanSpec pvlanspec = null;
      Map<String, Object> settingsMap = null;
      log.info("Test setup Begin:");
      iFolder = new Folder(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitchHelper(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
      rootFolderMor = iFolder.getRootFolder();
      dcMor = iFolder.getDataCenter();
      if (rootFolderMor != null) {
         dvsConfigSpec = new DVSConfigSpec();
         dvsConfigSpec.setConfigVersion("");
         dvsConfigSpec.setName(this.getClass().getName());
         dvsMor = iFolder.createDistributedVirtualSwitch(
                  iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
         if (dvsMor != null) {
            status = iDVSwitch.addPvlan(dvsMor,
                     DVSTestConstants.PVLAN_TYPE_PROMISCUOUS, 10, 10);
            if (status) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
               dvPortgroupConfigSpec.setConfigVersion("");
               dvPortgroupConfigSpec.setName(getTestId());
               dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
               dvPortgroupConfigSpec.setNumPorts(1);
               dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
               pvlanspec = new VmwareDistributedVirtualSwitchPvlanSpec();
               pvlanspec.setPvlanId(10);
               settingsMap = new HashMap<String, Object>();
               settingsMap.put(DVSTestConstants.VLAN_KEY, pvlanspec);
               dvPortSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
               dvPortgroupConfigSpec.setDefaultPortConfig(dvPortSetting);
            } else {
               log.error("Can not add the pvlan to the DVS");
            }
         } else {
            log.error("Failed to create the distributed " + "virtual switch");
         }
      } else {
         log.error("Failed to find a folder");
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that adds a portgroup to the distributed virtual switch with
    * configVersion set to an empty string
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "Add a portgroup to an existing"
            + "distributed virtual switch with a valid " + "pvlanid")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      if (dvPortgroupConfigSpec != null) {
         dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec };
         dvPortgroupMorList = iDVSwitch.addPortGroups(dvsMor,
                  dvPortgroupConfigSpecArray);
         if (dvPortgroupMorList != null) {
            if (dvPortgroupMorList.size() == dvPortgroupConfigSpecArray.length) {
               log.info("Successfully added all the portgroups");
               status = true;
            } else {
               log.error("Could not add all the portgroups");
            }
         } else {
            log.error("No portgroups were added");
         }
      }
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started. Destroy
    * the portgroup, followed by the distributed virtual switch
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      if (dvsMor != null) {
         status &= iManagedEntity.destroy(dvsMor);
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
