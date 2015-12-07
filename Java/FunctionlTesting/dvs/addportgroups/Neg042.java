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
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NumericRange;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VmwareDistributedVirtualSwitchTrunkVlanSpec;
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
 * DVPortgroupConfigSpec.DefaultPortConfig.vlan set to reverse borders trunk
 * range
 */
public class Neg042 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private ManagedObjectReference dcMor = null;
   private ManagedObjectReference networkFolderMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Add a portgroup to an existing distributed virtual "
               + "switch with the vlan set to reverse borders vlan "
               + "trunk range");
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
      VMwareDVSPortSetting dvPort = null;
      Map<String, Object> settingsMap = null;
      NumericRange vlanIds = null;
      VmwareDistributedVirtualSwitchTrunkVlanSpec vlanIdSpec = null;
      log.info("Test setup Begin:");
     
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         dcMor = (ManagedObjectReference) this.iFolder.getAllDataCenter().get(0);
         if (this.dcMor != null) {
            networkFolderMor = this.iFolder.getNetworkFolder(dcMor);
            this.dvsConfigSpec = new DVSConfigSpec();
            this.dvsConfigSpec.setConfigVersion("");
            this.dvsConfigSpec.setName(this.getClass().getName());
            dvsMor = this.iFolder.createDistributedVirtualSwitch(
                     networkFolderMor, dvsConfigSpec);
            if (dvsMor != null) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
               this.dvPortgroupConfigSpec.setConfigVersion("");
               this.dvPortgroupConfigSpec.setName(this.getTestId() + "-pg");
               this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
               vlanIds = new NumericRange();
               vlanIds.setStart(4);
               vlanIds.setEnd(1);
               vlanIdSpec = new VmwareDistributedVirtualSwitchTrunkVlanSpec();
               vlanIdSpec.getVlanId().clear();
               vlanIdSpec.getVlanId().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new NumericRange[] { vlanIds }));
               vlanIdSpec.setInherited(false);
               settingsMap = new HashMap<String, Object>();
               settingsMap.put(DVSTestConstants.VLAN_KEY, vlanIdSpec);
               dvPort = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
               this.dvPortgroupConfigSpec.setDefaultPortConfig(dvPort);
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
    * Method that adds a portgroup to the distributed virtual switch with
    * configVersion set to an empty string, name set to a valid string
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Add a portgroup to an existing distributed virtual "
               + "switch with the vlan set to reverse borders vlan "
               + "trunk range")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      try {
         if (dvPortgroupConfigSpec != null) {
            dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec };
            iDVSwitch.addPortGroups(this.dvsMor,
                     this.dvPortgroupConfigSpecArray);
            log.error("Exception not thrown");
         }
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         MethodFault expectedMethodFault = new InvalidArgument();
         status = TestUtil.checkMethodFault(actualMethodFault,
                  expectedMethodFault);
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
     
         if (this.dvsMor != null) {
            status &= this.iManagedEntity.destroy(dvsMor);
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}