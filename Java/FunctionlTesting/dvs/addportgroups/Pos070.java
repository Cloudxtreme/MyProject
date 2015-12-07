/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.addportgroups;

import static com.vmware.vcqa.util.Assert.assertTrue;

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
import com.vmware.vc.VmwareDistributedVirtualSwitchVlanIdSpec;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Add a portgroup to an existing distributed virtual switch with the following
 * parameters set: DVPortgroupConfigSpec.ConfigVersion is set to an empty string
 * DVPortgroupConfigSpec.PortSetting.Vlan set to 1
 */
public class Pos070 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private ManagedObjectReference dcMor = null;
   private VMwareDVSPortSetting dvPort = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Add a portgroup to an existing distributed virtual "
               + "switch with the vlan id set to 1 in the default "
               + "port setting");
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
      Map<String, Object> settingsMap = null;
      VmwareDistributedVirtualSwitchVlanIdSpec vlanIDSpec = null;
      log.info("Test setup Begin:");
     
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.dcMor = this.iFolder.getDataCenter();
         if (this.dcMor != null) {
            this.dvsConfigSpec = new DVSConfigSpec();
            this.dvsConfigSpec.setConfigVersion("");
            this.dvsConfigSpec.setName(this.getTestId());
            dvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
            if (dvsMor != null) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
               this.dvPortgroupConfigSpec.setConfigVersion("");
               this.dvPortgroupConfigSpec.setName(this.getTestId() + "-epg");
               this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
               this.dvPort = new VMwareDVSPortSetting();
               settingsMap = new HashMap<String, Object>();
               vlanIDSpec = new VmwareDistributedVirtualSwitchVlanIdSpec();
               vlanIDSpec.setInherited(false);
               vlanIDSpec.setVlanId(1);
               settingsMap.put(DVSTestConstants.VLAN_KEY, vlanIDSpec);
               this.dvPort = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
               this.dvPortgroupConfigSpec.setDefaultPortConfig(this.dvPort);
               status = true;
            } else {
               log.error("Failed to create the distributed "
                        + "virtual switch");
            }
         } else {
            log.error("Failed to find a folder");
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test Method.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Add a portgroup to an existing distributed virtual "
               + "switch with the vlan id set to 1 in the default "
               + "port setting")
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
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
     
         if (this.dvPortgroupMorList != null) {
            for (ManagedObjectReference mor : dvPortgroupMorList) {
               status &= this.iManagedEntity.destroy(mor);
            }
         }
         if (this.dvsMor != null) {
            status &= this.iManagedEntity.destroy(dvsMor);
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}