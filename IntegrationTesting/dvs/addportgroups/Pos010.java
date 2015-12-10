/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

/**
 * Add three portgroups with valid number of ports to a distributed virtual
 * switch
 */
public class Pos010 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private ManagedObjectReference dvPortgroupMor = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpecOne = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpecTwo = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpecThree = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private ManagedObjectReference dcMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Add three portgroups with valid number of ports to a "
               + "distributed virtual switch");
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
      log.info("Test setup Begin:");
     
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.rootFolderMor = this.iFolder.getRootFolder();
         this.dcMor = this.iFolder.getDataCenter();
         if (this.dcMor != null) {
            this.dvsConfigSpec = new DVSConfigSpec();
            this.dvsConfigSpec.setConfigVersion("");
            this.dvsConfigSpec.setName(this.getClass().getName());
            dvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
            if (dvsMor != null) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               this.dvPortgroupConfigSpecOne = new DVPortgroupConfigSpec();
               this.dvPortgroupConfigSpecOne.setConfigVersion("");
               this.dvPortgroupConfigSpecOne.setName(this.getTestId() + "-1");
               this.dvPortgroupConfigSpecOne.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
               this.dvPortgroupConfigSpecOne.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
               this.dvPortgroupConfigSpecOne.setNumPorts(1);
               this.dvPortgroupConfigSpecTwo = new DVPortgroupConfigSpec();
               this.dvPortgroupConfigSpecTwo.setConfigVersion("");
               this.dvPortgroupConfigSpecTwo.setName(this.getTestId() + "-2");
               this.dvPortgroupConfigSpecTwo.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
               this.dvPortgroupConfigSpecTwo.setType(DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING);
               this.dvPortgroupConfigSpecTwo.setNumPorts(2);
               this.dvPortgroupConfigSpecThree = new DVPortgroupConfigSpec();
               this.dvPortgroupConfigSpecThree.setConfigVersion("");
               this.dvPortgroupConfigSpecThree.setName(this.getTestId() + "-3");
               this.dvPortgroupConfigSpecThree.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
               this.dvPortgroupConfigSpecThree.setType(DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL);
               this.dvPortgroupConfigSpecTwo.setNumPorts(3);
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
    * Method that adds two portgroups to the distributed virtual switch
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Add three portgroups with valid number of ports to a "
               + "distributed virtual switch")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         if (dvPortgroupConfigSpecOne != null
                  && dvPortgroupConfigSpecTwo != null
                  && dvPortgroupConfigSpecThree != null) {
            dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[] {
                     dvPortgroupConfigSpecOne, dvPortgroupConfigSpecTwo,
                     dvPortgroupConfigSpecThree };
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
